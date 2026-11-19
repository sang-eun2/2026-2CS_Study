# 03: Go-Back-N과 Selective Repeat (데이터링크 계층, L11·L12)

슬라이딩 윈도우 프로토콜 두 가지를 **손실·손상이 일어나는 채널** 위에서 실제로 돌려 보는 Python 시뮬레이션입니다.
외부 라이브러리 없이 Python 3.8 이상이면 실행됩니다. 개념과 코드 해설은 [NOTES.md](./NOTES.md)에 있습니다.

## 파일 구성 (기능별 분리)
| 파일 | 데이터링크 계층에서 맡는 기능 |
|---|---|
| `frame.py` | 프레임 형식(data / ack / nak), 순서 번호 연산 `inc`, `between` |
| `event_sim.py` | 사건 처리 루프(`wait_for_event` 역할)와 타이머(`start_timer` / `stop_timer`) |
| `channel.py` | 물리 회선: 전송 시간 T_f, 전파 지연 T_p, 손실·손상 확률, 재현용 각본 |
| `network_layer.py` | 위 계층: 보낼 패킷 공급, 받은 패킷이 순서대로·중복 없이 왔는지 검사 |
| `go_back_n.py` | **GBN** 송신자·수신자 + 강의 예제 시나리오 |
| `selective_repeat.py` | **SR** 송신자·수신자(NAK 포함) + 강의 예제 시나리오 |
| `runner.py` | 위 부품을 연결해 한 번 실행하고 통계를 돌려줌 |
| `window_limit_demo.py` | 윈도우 제한(GBN ≤ 2^m−1, SR ≤ 2^(m−1))을 어기면 생기는 중복 전달 재현 |
| `utilization.py` | 이용률 U = min(1, W/(1+2a)) 공식 값과 시뮬레이션 값 비교 |
| `compare.py` | 손실률별 GBN vs SR 재전송 수·완료 시간 비교 |
| `test_protocols.py` | 자동 검증 (단위 테스트 10개) |

## 실행
```bash
python3 go_back_n.py                      # 정상 / 프레임 분실 / ACK 분실 / 프레임 손상
python3 go_back_n.py --scenario lost-frame
python3 go_back_n.py --loss 0.2 --packets 20 --seed 3   # 무작위 손실 20%

python3 selective_repeat.py               # 정상 / 프레임 분실(NAK) / NAK 분실 / ACK 분실 / 짧은 타임아웃
python3 selective_repeat.py --loss 0.2 --packets 20

python3 window_limit_demo.py              # 윈도우를 규칙보다 크게 하면 무엇이 깨지나
python3 utilization.py                    # 강의 예제 a = 10 의 W별 이용률
python3 compare.py                        # 손실률별 GBN vs SR
python3 -m unittest test_protocols.py     # 자동 검증
```
Windows에서는 `python3` 대신 `python` 또는 `py`를 쓰면 됩니다.

## 출력 읽는 법
```
[t=   8.0]     수신 | DATA(seq=2, P2) 기대 번호(1)와 다름, 수신 윈도우 {1,2,3,4}
[t=   8.0]     수신 | 첫 빈칸 1번에 대해 NAK 전송
[t=  13.0] 송신  | NAK 1 수신
[t=  13.0] 송신  | 재전송 DATA(seq=1, P1) ← NAK로 빠른 재전송
```
- `t`는 시간(데이터 프레임 하나를 내보내는 시간 T_f = 1 단위). 기본값 T_p = 5
- `seq`는 순서 번호(모듈로 2^m), `P2`는 실제 패킷 이름. 번호는 돌아서 재사용되지만 패킷 이름은 유일해서 중복 전달을 잡아낼 수 있습니다.
- `채널 A→B | ✗ ... 분실`은 채널이 그 프레임을 잃어버린 시점입니다.

## 시뮬레이션 모델의 단순화
- 데이터는 A→B 한 방향, ACK·NAK는 B→A 별도 채널 (피기백 없음)
- ACK·NAK 전송 시간은 0, 전파 지연만 있음 (강의의 이용률 계산과 같은 가정)
- 타이머는 프레임 전송이 **끝난 시각**부터 잼
