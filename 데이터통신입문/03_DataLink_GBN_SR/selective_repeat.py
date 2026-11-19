"""Selective Repeat (Tanenbaum 프로토콜 6, 강의 L12).

윈도우 크기 NR_BUFS = (MAX_SEQ + 1) / 2 = 2^(m-1)  (송신·수신 모두)
송신자
  - 프레임마다 타이머. 타임아웃이면 '그 프레임만' 재전송
  - NAK k (ack = k-1)를 받으면 프레임 k를 바로 재전송 (빠른 재전송)
  - ACK·NAK의 ack 필드는 누적 ACK로 처리해 윈도우를 민다
수신자
  - 수신 윈도우 frame_expected(R_n) ~ too_far 안의 올바른 프레임은 순서가 어긋나도 저장(수락)
  - 윈도우 앞부분부터 연속으로 채워지면 그만큼 한꺼번에 전달하고 누적 ACK
  - 수락 ≠ 전달: arrived[] 비트로 '받아 둠'을 표시
  - NAK는 한 번에 하나, 첫 번째 빈칸에 대해서만 (no_nak 플래그)
"""
from event_sim import Timer
from frame import ACK, DATA, NAK, Frame, between, inc, in_window

S, R = "송신 ", "    수신"


class Sender:
    def __init__(self, sim, channel, source, m, window, timeout, unsafe=False):
        self.sim, self.ch, self.source = sim, channel, source
        self.MAX_SEQ = 2 ** m - 1
        self.NR_BUFS = (self.MAX_SEQ + 1) // 2
        self.window = window or self.NR_BUFS
        if self.window > self.NR_BUFS and not unsafe:
            raise ValueError(f"SR 윈도우는 2^(m-1) = {self.NR_BUFS} 이하여야 함")
        self.timeout = timeout
        self.ack_expected = 0
        self.next_frame_to_send = 0
        self.nbuffered = 0
        # 강의 코드는 out_buf[seq % NR_BUFS]로 메모리를 아끼지만,
        # 여기서는 이해하기 쉽게 순서 번호마다 칸을 둔다.
        self.out_buf = [None] * (self.MAX_SEQ + 1)
        self.timers = [Timer(sim, self.on_timeout) for _ in range(self.MAX_SEQ + 1)]
        self.retransmissions = 0

    def idle(self):
        return self.nbuffered == 0 and not self.source.has_packet()

    def window_str(self):
        return f"윈도우 [S_f={self.ack_expected}, S_n={self.next_frame_to_send}) 미확인 {self.nbuffered}개"

    def outstanding(self, seq):
        return in_window(self.ack_expected, seq, self.nbuffered, self.MAX_SEQ)

    def start(self):
        self.fill_window()

    def fill_window(self):
        while self.nbuffered < self.window and self.source.has_packet():
            seq = self.next_frame_to_send
            self.out_buf[seq] = self.source.get()
            self.nbuffered += 1
            self.send_data(seq)
            self.next_frame_to_send = inc(seq, self.MAX_SEQ)

    def send_data(self, seq, why=""):
        frame = Frame(DATA, seq=seq, info=self.out_buf[seq])
        self.sim.log(S, f"{'재전송' if why else '전송'} {frame}{why}")
        if why:
            self.retransmissions += 1
        done = self.ch.send(frame)
        self.timers[seq].start(done - self.sim.now + self.timeout, seq)

    def on_frame(self, frame, ok):
        if not ok:
            self.sim.log(S, "손상된 ACK/NAK 도착 → 버림")
            return
        # 1) NAK: ack+1 번 프레임이 아직 미확인이면 그것만 바로 재전송
        if frame.kind == NAK:
            k = inc(frame.ack, self.MAX_SEQ)
            if self.outstanding(k):
                self.sim.log(S, f"NAK {k} 수신")
                self.send_data(k, why=" ← NAK로 빠른 재전송")
            else:
                self.sim.log(S, f"NAK {k} 수신 → {k}번은 미확인 프레임이 아님, 무시")
        # 2) ACK·NAK 공통: ack 필드는 누적 ACK
        first, moved = self.ack_expected, 0
        while self.nbuffered > 0 and self.outstanding(frame.ack):
            self.timers[self.ack_expected].stop()
            self.out_buf[self.ack_expected] = None
            self.nbuffered -= 1
            self.ack_expected = inc(self.ack_expected, self.MAX_SEQ)
            moved += 1
        if moved:
            covered = f"{first}번" if moved == 1 else f"{first}~{frame.ack}번 {moved}개"
            self.sim.log(S, f"누적 ack={frame.ack} → {covered} 확인, {self.window_str()}")
            self.fill_window()
        elif frame.kind == ACK:
            self.sim.log(S, f"{frame} 수신 → 이미 확인된 번호, 무시")

    def on_timeout(self, seq):
        self.sim.log(S, f"⏰ 프레임 {seq} 타임아웃")
        self.send_data(seq, why=" ← 타임아웃, 이 프레임만")


class Receiver:
    def __init__(self, sim, channel, sink, m, window=None, unsafe=False):
        self.sim, self.ch, self.sink = sim, channel, sink
        self.MAX_SEQ = 2 ** m - 1
        self.NR_BUFS = window or (self.MAX_SEQ + 1) // 2
        self.frame_expected = 0                 # 수신 윈도우 아래 끝 (R_n)
        self.too_far = self.NR_BUFS             # 수신 윈도우 위 끝 + 1
        self.arrived = [False] * (self.MAX_SEQ + 1)  # 받아 둔 프레임 표시 비트
        self.in_buf = [None] * (self.MAX_SEQ + 1)
        self.no_nak = True                      # 아직 NAK를 보내지 않았으면 True

    def window_list(self):
        seqs, k = [], self.frame_expected
        while k != self.too_far:
            seqs.append(str(k))
            k = inc(k, self.MAX_SEQ)
        return "{" + ",".join(seqs) + "}"

    def last_in_order(self):
        return (self.frame_expected + self.MAX_SEQ) % (self.MAX_SEQ + 1)

    def send_nak(self):
        self.no_nak = False
        self.sim.log(R, f"첫 빈칸 {self.frame_expected}번에 대해 NAK 전송")
        self.ch.send(Frame(NAK, ack=self.last_in_order()))

    def on_frame(self, frame, ok):
        if not ok:
            self.sim.log(R, "손상된 프레임 도착(체크섬 오류) → 버림")
            if self.no_nak:
                self.send_nak()
            return
        win = f"수신 윈도우 {self.window_list()}"
        nak_now = False
        if frame.seq != self.frame_expected and self.no_nak:
            self.sim.log(R, f"{frame} 기대 번호({self.frame_expected})와 다름, {win}")
            self.send_nak()
            nak_now = True
        if between(self.frame_expected, frame.seq, self.too_far) and not self.arrived[frame.seq]:
            self.arrived[frame.seq] = True          # 수락: 버퍼에 저장
            self.in_buf[frame.seq] = frame.info
            self.sim.log(R, f"{frame} 수락(버퍼 저장) {win}")
            delivered = []
            while self.arrived[self.frame_expected]:  # 윈도우 앞부분이 채워졌으면 전달
                self.sink.deliver(self.in_buf[self.frame_expected])
                delivered.append(self.in_buf[self.frame_expected])
                self.arrived[self.frame_expected] = False
                self.no_nak = True
                self.frame_expected = inc(self.frame_expected, self.MAX_SEQ)
                self.too_far = inc(self.too_far, self.MAX_SEQ)
            if delivered:
                self.sim.log(R, f"{', '.join(delivered)} 네트워크 계층에 전달 → ACK {self.last_in_order()}")
                self.ch.send(Frame(ACK, ack=self.last_in_order()))
        else:
            self.sim.log(R, f"{frame} 윈도우 밖이거나 이미 받은 프레임 → 버림 ({win})")
            # 옛 프레임이 다시 왔다 = 송신자가 우리 ACK를 못 받았다는 뜻.
            # 방금 NAK(누적 ack 포함)를 보내지 않았다면 ACK를 다시 보낸다.
            # (강의 코드에서 ack 타이머가 하는 일을 단순화한 것. 이게 없으면
            #  NAK마저 사라졌을 때 송신자는 영원히 재전송만 반복한다.)
            if not nak_now:
                self.sim.log(R, f"중복 수신 → ACK {self.last_in_order()} 다시 전송")
                self.ch.send(Frame(ACK, ack=self.last_in_order()))


# ---------------------------------------------------------------- 실행 예제
SCENARIOS = {
    "normal": ("정상 (m=3, 윈도우 4)", {}),
    "lost-frame": ("프레임 1 분실 → 2, 3 저장 + NAK 1 → 1만 재전송 → ACK 3으로 1~3 한꺼번에 전달",
                   {"data_drops": {("data", 1, 1)}}),
    "lost-nak": ("프레임 1 분실 + NAK도 분실 → 프레임 1 타이머가 복구 (2, 3도 ACK가 늦어 타임아웃)",
                 {"data_drops": {("data", 1, 1)}, "ack_drops": {("nak", 0, 1)}}),
    "lost-ack": ("ACK 0~3 분실 → 재전송분은 윈도우 밖이라 버리고, NAK에 실린 누적 ack로 복구",
                 {"ack_drops": {("ack", i, 1) for i in range(4)}}),
    "short-timeout": ("[비교] lost-frame과 같지만 타임아웃이 짧으면(12) 저장된 2, 3까지 재전송됨",
                      {"data_drops": {("data", 1, 1)}, "timeout": 12}),
}

if __name__ == "__main__":
    import argparse

    import runner
    p = argparse.ArgumentParser(description="Selective Repeat 시뮬레이션")
    p.add_argument("--scenario", choices=list(SCENARIOS) + ["all"], default="all")
    p.add_argument("--loss", type=float, help="무작위 손실 확률로 실행 (예: 0.2)")
    p.add_argument("--packets", type=int, default=10)
    p.add_argument("-m", type=int, default=3, help="순서 번호 비트 수")
    p.add_argument("--seed", type=int, default=1)
    a = p.parse_args()

    if a.loss is not None:
        print(f"=== SR 무작위 손실 {a.loss:.0%}, m={a.m}, 윈도우 {2**(a.m - 1)} ===")
        print(runner.summary(runner.run(__import__("selective_repeat"), n_packets=a.packets, m=a.m,
                                        loss=a.loss, seed=a.seed)))
    else:
        for name in (SCENARIOS if a.scenario == "all" else [a.scenario]):
            title, kw = SCENARIOS[name]
            print(f"\n=== SR [{name}] {title} ===")
            kw = {"timeout": 25, **kw}   # 누적 ACK가 늦게 오므로 타임아웃을 넉넉히
            r = runner.run(__import__("selective_repeat"), n_packets=4, m=3, **kw)
            print(runner.summary(r))
