# Go-Back-N · Selective Repeat 개념과 코드 해설

> 강의: CSC4021 데이터통신입문 L11(기본 데이터링크 프로토콜), L12(GBN과 SR). 교재 Tanenbaum 프로토콜 5·6을 Python으로 옮겨 재구성했습니다.
> 실행 방법은 [README.md](./README.md)를 보세요.

## 1. 왜 필요한가: 윈도우 1의 한계
Stop-and-Wait 계열(PAR, 1비트 슬라이딩 윈도우)은 왕복 시간(RTT)마다 프레임을 **하나만** 보냅니다.

$$U = \min\left(1, \frac{W}{1+2a}\right),\qquad a = \frac{T_p}{T_f}$$

`utilization.py` 실행 결과 (강의 예제: R = 1 Mbps, L = 1,000 bit, RTT = 20 ms → a = 10)

| W | 공식 U | 시뮬레이션 U |
|---|---|---|
| 1 | 4.8% | 4.8% |
| 15 | 71.4% | 71.4% |
| 21 | 100% | 100% |

W ≥ 1 + 2a = 21이면 첫 ACK가 돌아오기 전에 윈도우가 바닥나지 않아 회선이 쉬지 않습니다.
그래서 ACK를 기다리지 않고 여러 프레임을 보내는 **파이프라이닝**이 필요하고, 이때 오류가 나면 어떻게 하느냐에 따라 두 방식으로 갈립니다.

| | Go-Back-N | Selective Repeat |
|---|---|---|
| 송신 윈도우 최대 | 2^m − 1 | 2^(m−1) |
| 수신 윈도우 | 1 | 2^(m−1) |
| 순서 어긋난 프레임 | 버림 | 버퍼에 저장 |
| 재전송 범위 | 잃은 프레임부터 보낸 것 전부 | 잃은 프레임만 |
| 피드백 | 누적 ACK (중복 ACK) | 누적 ACK + NAK |
| 수신자 | 변수 하나, 단순 | 버퍼·표시 비트, 복잡 |

## 2. 공통 부품 해설

### 2-1. 순서 번호는 원형 (`frame.py`)
m비트 순서 번호는 0 ~ MAX_SEQ(= 2^m − 1)를 돌아가며 씁니다.
```python
def inc(k, max_seq):
    return k + 1 if k < max_seq else 0          # 3 다음은 0 (m = 2)

def between(a, b, c):                            # 원형에서 a <= b < c ?
    return (a <= b < c) or (c < a <= b) or (b < c < a)
```
- `between(6, 0, 1)`은 True: 구간 {6, 7, 0}에 0이 들어 있음 (MAX_SEQ = 7에서 넘어감)
- 수신 윈도우 검사(`between(frame_expected, seq, too_far)`)에 그대로 씁니다.
- 송신 쪽은 `in_window(lower, x, count)` = `(x − lower) mod 2^m < count`를 씁니다. `between(ack_expected, x, next_frame_to_send)`와 뜻이 같지만, 윈도우가 2^m를 꽉 채운 경우(아래 5절 실험)에도 동작합니다.

### 2-2. 누적 ACK 처리 루프 (GBN, SR 송신자 공통)
```python
while self.nbuffered > 0 and in_window(self.ack_expected, frame.ack, self.nbuffered, self.MAX_SEQ):
    self.timers[self.ack_expected].stop()   # 확인된 프레임 타이머 정지
    self.nbuffered -= 1                     # 사본 버림
    self.ack_expected = inc(self.ack_expected, self.MAX_SEQ)   # 윈도우 아래 끝 전진
```
- ACK k = "k까지 모두 받았다". 그래서 ACK 하나로 여러 칸이 한꺼번에 밀릴 수 있습니다.
- `frame.ack`가 미확인 구간 밖이면(이미 확인된 옛 번호) 루프가 한 번도 안 돌고 무시됩니다 → **중복 ACK**.
- 윈도우가 밀리면 `fill_window()`가 빈자리만큼 새 패킷을 보냅니다 (강의 코드의 `enable_network_layer`).

### 2-3. 타이머 (`event_sim.py`)
- 프레임마다 논리 타이머 하나. `start`를 다시 부르면 이전 예약은 **세대 번호**가 달라져 무시됩니다.
- 타이머는 프레임이 회선에 다 실린 시각부터 잽니다. 큐에서 기다리는 시간 때문에 너무 이른 타임아웃이 나지 않게 하려는 것입니다.
- 타임아웃은 RTT(= T_f + 2T_p)보다 길어야 합니다. 짧으면 L11의 "너무 이른 타임아웃" 문제로 불필요한 재전송이 생깁니다.

### 2-4. 손실 채널 (`channel.py`)
- **분실**: 프레임이 사라짐 → 수신자는 아무 사건도 받지 못함
- **손상**: 도착은 하지만 `ok = False` → 수신자는 체크섬 오류(cksum_err)로 처리
- `drop_script={("data", 2, 1)}` = "데이터 2번의 **첫 번째** 전송을 잃는다". 강의 그림의 상황을 정확히 재현할 때 씁니다.
- `network_layer.Sink`는 패킷 이름(P0, P1 …)으로 "빠짐없이, 중복 없이, 순서대로"를 검사합니다. 순서 번호는 돌아서 재사용되지만 패킷 이름은 유일하므로, 옛 프레임을 새 것으로 착각하면 바로 잡힙니다.

## 3. Go-Back-N 코드 해설 (`go_back_n.py`)

### 송신자
| 변수 | 강의 기호 | 뜻 |
|---|---|---|
| `ack_expected` | S_f | 아직 ACK 못 받은 가장 오래된 프레임 |
| `next_frame_to_send` | S_n | 다음에 보낼 새 프레임 번호 |
| `nbuffered` | | 보냈지만 ACK 못 받은 개수 (≤ 윈도우) |
| `buffer[seq]` | | 재전송용 사본 |

핵심은 타임아웃 처리입니다.
```python
def on_timeout(self, seq):
    seq = self.ack_expected                 # 가장 오래된 미확인 프레임으로 '되돌아가서'
    for _ in range(self.nbuffered):         # 보낸 것 전부 다시
        self.send_data(seq, resend=True)
        seq = inc(seq, self.MAX_SEQ)
```
수신자가 순서 어긋난 프레임을 모두 버리므로, 잃은 프레임 뒤의 것도 어차피 다시 보내야 합니다.

### 수신자
```python
if frame.seq == self.frame_expected:        # 기대한 번호만 받는다 (수신 윈도우 = 1)
    self.sink.deliver(frame.info)
    self.frame_expected = inc(self.frame_expected, self.MAX_SEQ)
# 받았든 버렸든 '마지막으로 순서대로 받은 번호'로 ACK
last_in_order = (self.frame_expected + self.MAX_SEQ) % (self.MAX_SEQ + 1)
self.ch.send(Frame(ACK, ack=last_in_order))
```
- `frame_expected − 1`을 원형으로 계산하려고 `+ MAX_SEQ`를 한 뒤 나머지를 구합니다 (0 − 1 → MAX_SEQ).
- 순서 어긋난 프레임을 받으면 같은 번호의 ACK가 다시 나갑니다 = 중복 ACK. 송신자는 이것을 무시합니다.
- 손상 프레임은 조용히 버립니다. 수신자에게는 타이머가 없습니다.

### 실행 추적: 프레임 2 분실 (m = 2, 윈도우 3)
```
[t=   0.0]   채널 A→B | ✗ DATA(seq=2, P2) 분실
[t=   6.0]     수신 | DATA(seq=0, P0) 순서 맞음 → 네트워크 계층에 전달
[t=   7.0]     수신 | DATA(seq=1, P1) 순서 맞음 → 네트워크 계층에 전달
[t=  11.0] 송신  | ACK 0 수신 → 0번 확인, 윈도우 [S_f=1, S_n=3) 미확인 2개
[t=  11.0] 송신  | 전송 DATA(seq=3, P3)
[t=  12.0] 송신  | ACK 1 수신 → 1번 확인, 윈도우 [S_f=2, S_n=0) 미확인 2개
[t=  12.0] 송신  | 전송 DATA(seq=0, P4)
[t=  15.0] 송신  | ⏰ 프레임 2 타임아웃 → 2번부터 3개 전부 재전송
[t=  17.0]     수신 | DATA(seq=3, P3) 기대 번호는 2 → 버림
[t=  18.0]     수신 | DATA(seq=0, P4) 기대 번호는 2 → 버림
[t=  21.0]     수신 | DATA(seq=2, P2) 순서 맞음 → 네트워크 계층에 전달
```
- 프레임 3(P3)과 0(P4)은 제대로 도착했지만 **기대 번호가 2라서 버려집니다**. 그래서 2, 3, 0을 모두 다시 보냅니다 = 오류 하나의 비용이 "잃은 프레임 + 그 뒤 전부".
- 강의 그림은 그 시점에 미확인 프레임이 2, 3 두 개라 "2와 3 재전송"이고, 여기서는 0(P4)까지 나가 있어 세 개를 다시 보낸 것입니다. 원리는 같습니다.

### 실행 추적: ACK 2 분실 (`--scenario lost-ack`, 타임아웃 20)
```
[t=   8.0]   채널 B→A | ✗ ACK 2 분실
[t=  22.0] 송신  | ACK 3 수신 → 2~3번 2개 확인, 윈도우 [S_f=0, S_n=1) 미확인 1개
→ 성공 | ... 데이터 전송 6회(재전송 0)
```
ACK 3이 "3까지 다 받았다"는 뜻이라 사라진 ACK 2를 덮습니다 (**누적 ACK**). 타임아웃(프레임 2의 경우 t = 23) 전에 ACK 3이 왔으므로 재전송이 없습니다. 기본 타임아웃(12)으로 돌리면 ACK 3이 오기 전에 타임아웃이 나서 재전송이 생깁니다. 타임아웃 길이가 결과를 바꾼다는 점도 같이 보세요.

## 4. Selective Repeat 코드 해설 (`selective_repeat.py`)

### 수신자: 수락 ≠ 전달
| 변수 | 뜻 |
|---|---|
| `frame_expected` (R_n) | 수신 윈도우 아래 끝 = 다음에 전달할 번호 |
| `too_far` | 수신 윈도우 위 끝 + 1 (윈도우 = [frame_expected, too_far)) |
| `arrived[seq]` | 받아 둔 프레임 표시 비트 |
| `in_buf[seq]` | 받아 둔 패킷 |
| `no_nak` | 아직 NAK를 안 보냈으면 True (NAK는 한 번에 하나) |

```python
if frame.seq != self.frame_expected and self.no_nak:
    self.send_nak()                                   # ① 첫 빈칸에 대해 NAK 한 번
if between(self.frame_expected, frame.seq, self.too_far) and not self.arrived[frame.seq]:
    self.arrived[frame.seq] = True                    # ② 수락: 윈도우 안이면 순서 무관하게 저장
    self.in_buf[frame.seq] = frame.info
    while self.arrived[self.frame_expected]:          # ③ 전달: 윈도우 앞부분부터 연속인 만큼
        self.sink.deliver(self.in_buf[self.frame_expected])
        self.arrived[self.frame_expected] = False
        self.no_nak = True                            #    빈칸이 메워졌으니 다음 NAK 허용
        self.frame_expected = inc(...); self.too_far = inc(...)   # 윈도우 이동
    if delivered: 누적 ACK 전송
else:
    버림 (+ 방금 NAK를 안 보냈으면 ACK 재전송)          # ④
```
- ① NAK의 ack 필드 = `frame_expected − 1` (= k − 1). 받는 쪽은 k = ack + 1을 다시 보냅니다. `no_nak` 덕분에 같은 빈칸에 NAK가 여러 번 나가지 않습니다.
- ② 수락은 "받아 두었다"는 표시일 뿐, 위 계층에 넘기는 것은 ③입니다. 그래서 순서가 지켜집니다.
- ③ 빠진 프레임이 도착하는 순간 그 뒤에 쌓여 있던 프레임이 **한꺼번에** 전달되고 ACK 하나로 확인됩니다.
- ④ 윈도우 아래쪽 옛 프레임이 또 왔다면 송신자가 ACK를 못 받았다는 뜻이라 ACK를 다시 보냅니다. 강의 코드에서는 ack 타이머가 이 일을 하는데, 여기서는 단순화했습니다. 이 줄을 지우면 ACK와 NAK가 모두 사라진 경우 송신자가 영원히 재전송만 반복합니다 (무작위 손실 시험에서 실제로 멈춤을 확인하고 넣은 줄입니다).

### 송신자: 그 프레임만 다시
```python
if frame.kind == NAK:
    k = inc(frame.ack, self.MAX_SEQ)            # NAK k 는 ack = k-1 로 실려 옴
    if self.outstanding(k):
        self.send_data(k, why=" ← NAK로 빠른 재전송")
# ACK와 NAK 모두 ack 필드를 누적 ACK로 처리 (2-2의 루프)

def on_timeout(self, seq):
    self.send_data(seq, why=" ← 타임아웃, 이 프레임만")
```

### 실행 추적: 프레임 1 분실 + NAK (m = 3, 윈도우 4)
```
[t=   0.0]   채널 A→B | ✗ DATA(seq=1, P1) 분실
[t=   6.0]     수신 | P0 네트워크 계층에 전달 → ACK 0
[t=   8.0]     수신 | DATA(seq=2, P2) 기대 번호(1)와 다름, 수신 윈도우 {1,2,3,4}
[t=   8.0]     수신 | 첫 빈칸 1번에 대해 NAK 전송
[t=   8.0]     수신 | DATA(seq=2, P2) 수락(버퍼 저장) 수신 윈도우 {1,2,3,4}
[t=   9.0]     수신 | DATA(seq=3, P3) 수락(버퍼 저장) 수신 윈도우 {1,2,3,4}
[t=  13.0] 송신  | NAK 1 수신
[t=  13.0] 송신  | 재전송 DATA(seq=1, P1) ← NAK로 빠른 재전송
[t=  19.0]     수신 | P1, P2, P3 네트워크 계층에 전달 → ACK 3
→ 성공 | 끝난 시각 24.0 | 데이터 전송 5회(재전송 1) | ACK 2 | NAK 1
```
강의 그림과 같은 흐름입니다: **ACK 0 → NAK 1 → 프레임 1만 재전송 → ACK 3으로 1~3 한꺼번에 전달**. 재전송은 1번뿐입니다.

### 주의: SR도 타임아웃이 짧으면 재전송이 늘어난다
`--scenario short-timeout`(타임아웃 12)은 같은 상황인데 데이터 전송이 7회(재전송 3)입니다. ACK가 누적 방식이라 프레임 2, 3은 버퍼에 잘 저장되어 있어도 빈칸 1이 메워질 때까지 ACK를 받지 못하고, 그동안 타이머가 끝나 버리기 때문입니다. 그래서 SR에서는 **NAK로 빈칸을 빨리 메우는 것**과 **넉넉한 타임아웃**이 중요합니다.

## 5. 윈도우 크기 제한은 왜? (`window_limit_demo.py`)
m = 2(번호 0~3). 첫 윈도우의 데이터는 모두 도착했는데 ACK가 전부 사라지는 각본입니다.

| 경우 | 결과 | 이유 |
|---|---|---|
| GBN 윈도우 3 (= 2^m − 1) | 성공 | 수신자는 3을 기다리는 중 → 재전송된 0, 1, 2는 버려짐 |
| GBN 윈도우 4 (= 2^m) | **실패**: P0 P1 P2 P3 **P0** | 0~3을 다 받은 수신자는 다음 0을 기다림 → 옛 0을 새 0으로 받아들임 |
| SR 윈도우 2 (= 2^(m−1)) | 성공 | 새 수신 윈도우 {2,3}과 옛 번호 {0,1}이 겹치지 않음 |
| SR 윈도우 3 | **실패**: P0 P1 P2 P3 **P0 P1** | 새 수신 윈도우 {3,0,1}에 옛 0, 1이 들어가 새 프레임으로 저장됨 |

정리하면 "옛 윈도우와 새 수신 윈도우가 순서 번호 공간에서 **겹치면** 안 된다"는 조건입니다.
- GBN: 수신 윈도우가 1칸이라 송신 윈도우 W와 수신 위치 1칸이 겹치지 않으려면 W + 1 ≤ 2^m → **W ≤ 2^m − 1**
- SR: 송신 윈도우 W와 수신 윈도우 W가 겹치지 않으려면 W + W ≤ 2^m → **W ≤ 2^(m−1)**

## 6. 손실률별 비교 (`compare.py`)
패킷 200개, 같은 윈도우 7, T_p = 5, 데이터·ACK 채널 모두 같은 손실률, 시드 30개 평균

| 손실률 | 이론 최소 N/(1−p) | GBN 전송 | GBN 효율 | SR 전송 | SR 효율 |
|---|---|---|---|---|---|
| 0% | 200 | 200 | 100% | 200 | 100% |
| 5% | 211 | 277 | 72.2% | 246 | 81.5% |
| 10% | 222 | 360 | 55.5% | 279 | 71.6% |
| 20% | 250 | 547 | 36.6% | 362 | 55.3% |
| 30% | 286 | 796 | 25.1% | 457 | 43.8% |

- 오류가 없으면 둘은 똑같습니다. 차이는 **오류가 났을 때의 비용**입니다.
- 손실이 늘수록 GBN은 "잃은 것 + 뒤 전부"를 다시 보내 급격히 나빠집니다. 오류가 드물거나 수신자 메모리가 부족할 때 GBN, 오류가 잦거나 대역폭이 귀할 때 SR이라는 강의 결론과 일치합니다.
- SR이 이론 최소보다 많은 이유는 4절의 주의 사항(누적 ACK 대기 중 타임아웃)과 ACK 분실 때문입니다.

## 7. 강의 코드(Tanenbaum)와 다른 점
| 항목 | 강의 코드 | 이 구현 | 이유 |
|---|---|---|---|
| 방향 | 양방향, ACK 피기백 | 단방향 데이터 + 별도 ACK 채널 | 흐름을 읽기 쉽게 |
| ACK 시점 | ack 타이머 만료 또는 피기백 | 전달 즉시 ACK, 옛 프레임 재수신 시 ACK 재전송 | ack 타이머 역할을 단순화 |
| SR 버퍼 | `out_buf[seq % NR_BUFS]` | 순서 번호마다 한 칸 | 이해하기 쉽게 (메모리만 더 씀) |
| 송신 윈도우 검사 | `between(ack_expected, x, next_frame_to_send)` | `in_window(ack_expected, x, nbuffered)` | 뜻은 같음. 윈도우 위반 실험에서도 동작 |
| 사건 대기 | `wait_for_event()` | 이산 사건 시뮬레이터의 콜백 | 실제 시간 없이 재현 가능 |

## 8. 시험 대비 포인트
- m비트 순서 번호 → **GBN 송신 윈도우 최대 2^m − 1, SR 최대 2^(m−1)**. 예: m = 3 → GBN 7, SR 4
- GBN 수신 윈도우는 **항상 1**, 수신자는 타이머 없음
- GBN 타임아웃 → **가장 오래된 미확인 프레임부터 보낸 것 전부** 재전송
- 누적 ACK k = **k까지 모두** 받음 → ACK 하나가 사라져도 다음 ACK가 덮는다
- SR NAK k는 헤더에 **ack = k − 1**로 실린다. NAK는 **첫 빈칸에 대해 한 번만** (no_nak)
- SR 수신자: **수락(저장) ≠ 전달**. 윈도우 시작부터 연속일 때만 전달, ACK 번호는 마지막으로 전달한 프레임
- 이용률 U = min(1, W/(1+2a)), W ≥ 1 + 2a면 100%

### 연습 (직접 돌려서 확인)
1. `python3 go_back_n.py --scenario damaged`: 프레임 1이 손상된 뒤 프레임 2가 도착하면 수신자가 보내는 ACK 번호는? (답: 0, 중복 ACK. 손상된 1 자체에는 ACK를 보내지 않음)
2. `python3 selective_repeat.py --scenario lost-nak`: NAK가 사라지면 무엇이 빈칸을 메우나? (답: 프레임 1의 타이머)
3. `utilization.py`에서 a를 바꿔 보고 U가 100%가 되는 최소 W를 예측해 보세요. (답: W ≥ 1 + 2a)
