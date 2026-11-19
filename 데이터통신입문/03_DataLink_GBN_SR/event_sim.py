"""이산 사건(discrete-event) 시뮬레이터와 타이머.

실제 시간을 기다리지 않고, '언제 무슨 일이 일어나는지'를 우선순위 큐에
넣어 시간 순서대로 처리한다. 강의 코드의 wait_for_event()가 돌려주는
사건(frame_arrival, cksum_err, timeout)을 여기서는 콜백 호출로 표현한다.
"""
import heapq
import itertools


class Simulator:
    def __init__(self, verbose: bool = True):
        self.now = 0.0
        self.verbose = verbose
        self._queue = []                 # (시각, 순번, 함수, 인자)
        self._order = itertools.count()  # 같은 시각이면 먼저 예약한 것부터

    def schedule(self, delay: float, fn, *args):
        heapq.heappush(self._queue, (self.now + delay, next(self._order), fn, args))

    def run(self, stop=lambda: False, until: float = 1e9):
        while self._queue and not stop():
            t, _, fn, args = heapq.heappop(self._queue)
            if t > until:
                break
            self.now = t
            fn(*args)

    def log(self, who: str, msg: str):
        if self.verbose:
            print(f"[t={self.now:6.1f}] {who} | {msg}")


class Timer:
    """논리 타이머 하나 (start_timer / stop_timer).

    start를 다시 부르면 이전 예약은 무효가 된다. 이미 큐에 들어간 사건을
    지울 수 없으므로 '세대 번호'를 올려서, 울릴 때 번호가 다르면 무시한다.
    """

    def __init__(self, sim: Simulator, on_expire):
        self.sim = sim
        self.on_expire = on_expire
        self.generation = 0
        self.running = False

    def start(self, delay: float, *args):
        self.generation += 1
        self.running = True
        self.sim.schedule(delay, self._fire, self.generation, args)

    def stop(self):
        self.generation += 1
        self.running = False

    def _fire(self, generation, args):
        if self.running and generation == self.generation:
            self.running = False
            self.on_expire(*args)
