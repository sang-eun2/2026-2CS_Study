"""손실·손상이 일어나는 단방향 채널 (물리 계층 + 회선 역할).

- 전송 시간 tf : 프레임 하나를 회선에 내보내는 데 걸리는 시간 (T_f = L/R)
- 전파 지연 tp : 회선 끝까지 가는 시간 (T_p = d/v)
- loss         : 프레임이 통째로 사라질 확률 (수신자는 아무것도 모름)
- damage       : 비트 오류로 손상될 확률 (수신자는 CRC로 알아채고 cksum_err)
- drop_script / damage_script : 재현용 각본. {(종류, 번호, n번째 전송)} 형태로
  "데이터 2번의 첫 전송을 잃어버린다" 같은 강의 예제를 그대로 만든다.
  번호는 데이터면 seq, ACK·NAK면 ack 필드다.
"""
import random
from collections import Counter

from frame import DATA, Frame


class Channel:
    def __init__(self, sim, name, tf=1.0, tp=5.0, loss=0.0, damage=0.0,
                 drop_script=(), damage_script=(), seed=None):
        self.sim, self.name = sim, name
        self.tf, self.tp = tf, tp
        self.loss, self.damage = loss, damage
        self.drop_script = set(drop_script)
        self.damage_script = set(damage_script)
        self.rng = random.Random(seed)
        self.receiver = None        # 도착 시 부를 함수 f(frame, ok)
        self.busy_until = 0.0       # 회선이 앞 프레임을 내보내는 중이면 그 끝 시각
        self.nth = Counter()        # (종류, 번호) -> 지금까지 몇 번 보냈나
        self.stats = Counter()
        self.departures = []        # 데이터 프레임 전송이 끝난 시각들 (이용률 측정용)

    def connect(self, receiver_fn):
        self.receiver = receiver_fn

    def send(self, frame: Frame) -> float:
        """프레임을 회선에 올린다. 전송이 끝나는 시각을 돌려준다.

        송신자는 이 시각부터 타이머를 잰다 (회선 대기 시간 때문에 너무 이른
        타임아웃이 나지 않도록).
        """
        start = max(self.sim.now, self.busy_until)
        done = start + self.tf
        self.busy_until = done

        num = frame.seq if frame.kind == DATA else frame.ack
        self.nth[(frame.kind, num)] += 1
        key = (frame.kind, num, self.nth[(frame.kind, num)])
        self.stats["sent_" + frame.kind] += 1
        if frame.kind == DATA:
            self.departures.append(done)

        if key in self.drop_script or self.rng.random() < self.loss:
            self.stats["lost"] += 1
            self.sim.log(f"  채널 {self.name}", f"✗ {frame} 분실")
            return done
        ok = not (key in self.damage_script or self.rng.random() < self.damage)
        if not ok:
            self.stats["damaged"] += 1
        self.sim.schedule(done + self.tp - self.sim.now, self.receiver, frame, ok)
        return done
