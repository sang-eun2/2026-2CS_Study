"""Go-Back-N (Tanenbaum 프로토콜 5, 강의 L12).

송신자
  - 송신 윈도우 ≤ MAX_SEQ = 2^m - 1
  - ack_expected(S_f) ~ next_frame_to_send(S_n) 사이 프레임의 사본을 보관
  - 프레임마다 타이머. 타임아웃이면 ack_expected부터 보낸 것 전부 재전송
  - 누적 ACK k를 받으면 k까지 한꺼번에 윈도우를 민다
수신자
  - 수신 윈도우 = 1, 변수 frame_expected(R_n) 하나
  - 기대한 번호면 전달, 아니면 버리고 '마지막으로 순서대로 받은 번호'로 ACK(중복 ACK)
  - 손상 프레임은 조용히 버림, 타이머 없음
"""
from event_sim import Timer
from frame import ACK, DATA, Frame, inc, in_window

S, R = "송신 ", "    수신"


class Sender:
    def __init__(self, sim, channel, source, m, window, timeout, unsafe=False):
        self.sim, self.ch, self.source = sim, channel, source
        self.MAX_SEQ = 2 ** m - 1
        self.window = window or self.MAX_SEQ
        if self.window > self.MAX_SEQ and not unsafe:
            raise ValueError(f"GBN 송신 윈도우는 2^m-1 = {self.MAX_SEQ} 이하여야 함")
        self.timeout = timeout
        self.ack_expected = 0        # S_f: 아직 ACK 못 받은 가장 오래된 프레임
        self.next_frame_to_send = 0  # S_n: 다음에 보낼 새 프레임 번호
        self.nbuffered = 0           # 보냈지만 ACK 못 받은 프레임 수
        self.buffer = [None] * (self.MAX_SEQ + 1)            # 재전송용 사본
        self.timers = [Timer(sim, self.on_timeout) for _ in range(self.MAX_SEQ + 1)]
        self.retransmissions = 0

    # --- 상태 ---
    def idle(self):
        return self.nbuffered == 0 and not self.source.has_packet()

    def window_str(self):
        return f"윈도우 [S_f={self.ack_expected}, S_n={self.next_frame_to_send}) 미확인 {self.nbuffered}개"

    # --- 보내기 ---
    def start(self):
        self.fill_window()

    def fill_window(self):
        """enable_network_layer: 윈도우에 빈자리가 있는 동안 새 패킷을 보낸다."""
        while self.nbuffered < self.window and self.source.has_packet():
            seq = self.next_frame_to_send
            self.buffer[seq] = self.source.get()
            self.nbuffered += 1
            self.send_data(seq)
            self.next_frame_to_send = inc(seq, self.MAX_SEQ)

    def send_data(self, seq, resend=False):
        frame = Frame(DATA, seq=seq, info=self.buffer[seq])
        self.sim.log(S, f"{'재전송' if resend else '전송'} {frame}")
        done = self.ch.send(frame)
        self.timers[seq].start(done - self.sim.now + self.timeout, seq)

    # --- 사건 처리 ---
    def on_frame(self, frame, ok):
        if not ok:
            self.sim.log(S, "손상된 ACK 도착 → 버림")
            return
        first, moved = self.ack_expected, 0
        # 누적 ACK: frame.ack가 윈도우 안이면 ack_expected부터 frame.ack까지 모두 확인
        while self.nbuffered > 0 and in_window(self.ack_expected, frame.ack,
                                                self.nbuffered, self.MAX_SEQ):
            self.timers[self.ack_expected].stop()
            self.buffer[self.ack_expected] = None
            self.nbuffered -= 1
            self.ack_expected = inc(self.ack_expected, self.MAX_SEQ)
            moved += 1
        if moved:
            covered = f"{first}번" if moved == 1 else f"{first}~{frame.ack}번 {moved}개"
            self.sim.log(S, f"{frame} 수신 → {covered} 확인, {self.window_str()}")
            self.fill_window()
        else:
            self.sim.log(S, f"{frame} 수신 → 이미 확인된 번호(중복 ACK), 무시")

    def on_timeout(self, seq):
        """Go back N: ack_expected부터 보낸 프레임을 전부 다시 보낸다."""
        self.sim.log(S, f"⏰ 프레임 {seq} 타임아웃 → {self.ack_expected}번부터 {self.nbuffered}개 전부 재전송")
        seq = self.ack_expected
        for _ in range(self.nbuffered):
            self.send_data(seq, resend=True)
            self.retransmissions += 1
            seq = inc(seq, self.MAX_SEQ)


class Receiver:
    def __init__(self, sim, channel, sink, m, window=None, unsafe=False):
        self.sim, self.ch, self.sink = sim, channel, sink
        self.MAX_SEQ = 2 ** m - 1
        self.frame_expected = 0      # R_n: 수신 윈도우(크기 1)

    def on_frame(self, frame, ok):
        if not ok:
            self.sim.log(R, "손상된 프레임 도착(체크섬 오류) → 조용히 버림")
            return
        if frame.seq == self.frame_expected:
            self.sim.log(R, f"{frame} 순서 맞음 → 네트워크 계층에 전달")
            self.sink.deliver(frame.info)
            self.frame_expected = inc(self.frame_expected, self.MAX_SEQ)
        else:
            self.sim.log(R, f"{frame} 기대 번호는 {self.frame_expected} → 버림")
        # 마지막으로 순서대로 받은 번호 = frame_expected - 1 (원형)
        last_in_order = (self.frame_expected + self.MAX_SEQ) % (self.MAX_SEQ + 1)
        self.ch.send(Frame(ACK, ack=last_in_order))


# ---------------------------------------------------------------- 실행 예제
SCENARIOS = {
    "normal": ("정상 (윈도우 3)", {}),
    "lost-frame": ("프레임 2 분실 → 3은 순서 어긋나 버려짐 → 타임아웃 후 2, 3 재전송",
                   {"data_drops": {("data", 2, 1)}}),
    "lost-ack": ("ACK 2 분실 → 타임아웃 전에 ACK 3이 와서 누적 ACK로 해결 (타임아웃 20)",
                 {"ack_drops": {("ack", 2, 1)}, "timeout": 20}),
    "damaged": ("프레임 1 손상 → 수신자가 조용히 버림 → 타임아웃 후 1부터 재전송",
                {"data_damages": {("data", 1, 1)}}),
}

if __name__ == "__main__":
    import argparse

    import runner
    p = argparse.ArgumentParser(description="Go-Back-N 시뮬레이션")
    p.add_argument("--scenario", choices=list(SCENARIOS) + ["all"], default="all")
    p.add_argument("--loss", type=float, help="무작위 손실 확률로 실행 (예: 0.2)")
    p.add_argument("--packets", type=int, default=10)
    p.add_argument("-m", type=int, default=3, help="순서 번호 비트 수")
    p.add_argument("--seed", type=int, default=1)
    a = p.parse_args()

    if a.loss is not None:
        print(f"=== GBN 무작위 손실 {a.loss:.0%}, m={a.m}, 윈도우 {2**a.m - 1} ===")
        print(runner.summary(runner.run(__import__("go_back_n"), n_packets=a.packets, m=a.m,
                                        loss=a.loss, seed=a.seed)))
    else:
        for name in (SCENARIOS if a.scenario == "all" else [a.scenario]):
            title, kw = SCENARIOS[name]
            print(f"\n=== GBN [{name}] {title} ===")
            # 강의 예제: m=2 (번호 0~3), 윈도우 3, 프레임 6개
            r = runner.run(__import__("go_back_n"), n_packets=6, m=2, **kw)
            print(runner.summary(r))
