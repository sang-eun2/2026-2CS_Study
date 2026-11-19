# 03: Go-Back-N과 Selective Repeat (데이터링크 계층, L11·L12)

강의 슬라이드의 Tanenbaum 프로토콜 코드(protocol 5·6)와 같은 **C 언어**로 슬라이딩 윈도우 프로토콜 두 가지를 구현하고, **손실·손상이 일어나는 채널** 위에서 실제로 돌려 봅니다.
표준 C99만 써서 gcc나 clang만 있으면 빌드됩니다. 개념과 코드 해설은 [NOTES.md](./NOTES.md)에 있습니다.

## 파일 구성 (기능별 분리)
| 파일 | 데이터링크 계층에서 맡는 기능 |
|---|---|
| `protocol.h` | 강의 코드의 protocol.h: `frame`·`packet`·`seq_nr`·`event_type`, `inc`, 계층 간 인터페이스 함수 선언 |
| `go_back_n.c` | **GBN** (protocol 5): 송신 측·수신 측 사건 처리 |
| `selective_repeat.c` | **SR** (protocol 6): 송신 측·수신 측 사건 처리, NAK |
| `channel.c` | 물리 계층: 전송 시간 T_f, 전파 지연 T_p, 손실·손상, 재현용 각본 |
| `sim.c`, `sim.h` | 사건 처리 루프(`wait_for_event` 역할), 타이머, `between`, 네트워크 계층 흉내와 전달 검사 |
| `experiments.c` | 윈도우 제한 위반 실험, 이용률 U = min(1, W/(1+2a)), 손실률별 GBN vs SR |
| `main.c` | 실행 명령, 강의 예제 시나리오, 자동 검증 35개 |
| `Makefile` | 빌드 |

## 빌드와 실행
```bash
make                       # datalink 실행 파일 생성 (Windows MinGW: mingw32-make)
./datalink test            # 자동 검증

./datalink gbn             # 정상 / 프레임 분실 / ACK 분실 / 프레임 손상
./datalink gbn lost-frame  # 시나리오 하나만
./datalink gbn --loss 0.2 --packets 20 --seed 3     # 무작위 손실 20%

./datalink sr              # 정상 / 프레임 분실(NAK) / NAK 분실 / ACK 분실 / 짧은 타임아웃
./datalink sr --loss 0.2 --packets 20

./datalink window          # 윈도우를 규칙보다 크게 하면 무엇이 깨지나
./datalink util            # 강의 예제 a = 10 의 W별 이용률
./datalink compare         # 손실률별 GBN vs SR
```
Make가 없으면 `gcc -std=c99 -O2 -o datalink main.c sim.c channel.c go_back_n.c selective_repeat.c experiments.c`로 빌드합니다. Windows에서는 `datalink.exe gbn`처럼 실행하며, 프로그램이 콘솔을 UTF-8로 바꿔 한글이 보이게 합니다.

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

## 강의 코드와 다른 점 (단순화)
- 데이터는 A→B 한 방향, ACK·NAK는 B→A로 따로 보냄 (피기백 없음)
- ACK·NAK 전송 시간은 0, 전파 지연만 있음 (강의의 이용률 계산과 같은 가정)
- 타이머는 프레임 전송이 **끝난 시각**부터 잼
- `MAX_SEQ`는 `#define` 대신 변수: 실험마다 m을 바꾸기 위해서
