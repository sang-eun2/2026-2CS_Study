"""네트워크 계층 흉내: 보낼 패킷 공급(from_network_layer)과
받은 패킷 검사(to_network_layer).

데이터링크 계층이 지켜야 할 약속은 '패킷을 빠짐없이, 중복 없이, 순서대로'
위 계층에 넘기는 것이다. Sink는 이 약속이 깨지는 순간을 기록한다.
"""


class Source:
    def __init__(self, n_packets: int):
        self.packets = [f"P{i}" for i in range(n_packets)]
        self.next = 0

    def has_packet(self) -> bool:
        return self.next < len(self.packets)

    def get(self) -> str:
        pkt = self.packets[self.next]
        self.next += 1
        return pkt


class Sink:
    def __init__(self, expected):
        self.expected = list(expected)
        self.delivered = []
        self.errors = []

    def deliver(self, pkt: str):
        i = len(self.delivered)
        want = self.expected[i] if i < len(self.expected) else "(없음)"
        if pkt != want:
            self.errors.append(f"{i}번째 자리: {want} 기대, {pkt} 전달됨(중복)")
        self.delivered.append(pkt)

    def complete(self) -> bool:
        return self.delivered == self.expected
