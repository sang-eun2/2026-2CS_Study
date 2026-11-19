"""프레임 형식과 순서 번호 연산 (L11, L12 공통).

강의 슬라이드의 프레임 구조를 그대로 옮겼다.
    데이터 : kind=data, seq, ack, info
    ACK    : kind=ack,  (seq 사용 안 함), ack
    NAK k  : kind=nak,  (seq 사용 안 함), ack = k - 1
"""
from dataclasses import dataclass

DATA, ACK, NAK = "data", "ack", "nak"


@dataclass(frozen=True)
class Frame:
    kind: str      # DATA / ACK / NAK
    seq: int = 0   # 데이터 프레임의 순서 번호 (0 ~ MAX_SEQ)
    ack: int = 0   # 마지막으로 '순서대로' 올바르게 받은 프레임 번호 (누적 ACK)
    info: str = "" # 네트워크 계층 패킷 (여기서는 "P0", "P1" 같은 이름)

    def __str__(self):
        if self.kind == DATA:
            return f"DATA(seq={self.seq}, {self.info})"
        if self.kind == ACK:
            return f"ACK {self.ack}"
        return f"NAK (ack={self.ack})"


def inc(k: int, max_seq: int) -> int:
    """순서 번호를 원형으로 1 증가: 0, 1, ..., MAX_SEQ, 0, 1, ..."""
    return k + 1 if k < max_seq else 0


def between(a: int, b: int, c: int) -> bool:
    """원형 순서 번호에서 a <= b < c 이면 True (Tanenbaum 프로토콜 5·6의 between).

    세 경우 중 하나면 b가 [a, c) 구간 안에 있다.
      a <= b < c   : 구간이 한 바퀴를 넘지 않음
      c < a <= b   : 구간이 MAX_SEQ에서 0으로 넘어가고, b는 넘어가기 전
      b < c < a    : 구간이 넘어가고, b는 넘어간 뒤
    """
    return (a <= b < c) or (c < a <= b) or (b < c < a)


def in_window(lower: int, x: int, count: int, max_seq: int) -> bool:
    """x가 lower부터 시작하는 count개짜리 윈도우 안에 있으면 True.

    between(lower, x, lower+count)와 같은 뜻이지만, 윈도우가 순서 번호
    공간 전체(2^m)를 채운 경우에도 동작한다. window_limit_demo.py에서
    윈도우를 일부러 규칙보다 크게 잡는 실험을 하려고 따로 둔다.
    """
    return (x - lower) % (max_seq + 1) < count
