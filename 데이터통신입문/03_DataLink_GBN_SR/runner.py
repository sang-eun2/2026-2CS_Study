"""송신자·수신자·채널 두 개(A→B 데이터, B→A ACK/NAK)를 연결해 한 번 실행한다.

    [Source] → 송신자 ──(데이터 채널)──▶ 수신자 → [Sink]
                  ◀──(ACK 채널)──────
"""
from channel import Channel
from event_sim import Simulator
from network_layer import Sink, Source


def run(protocol, n_packets=8, m=3, window=None, tf=1.0, tp=5.0, timeout=None,
        loss=0.0, damage=0.0, ack_loss=None, data_drops=(), ack_drops=(),
        data_damages=(), seed=None, verbose=True, unsafe=False, until=1e6):
    """protocol 모듈(go_back_n 또는 selective_repeat)로 시뮬레이션을 돌리고 결과를 돌려준다."""
    sim = Simulator(verbose)
    source = Source(n_packets)
    sink = Sink(source.packets)
    # 데이터 채널과 ACK 채널은 서로 다른 난수열을 쓴다
    data_ch = Channel(sim, "A→B", tf=tf, tp=tp, loss=loss, damage=damage,
                      drop_script=data_drops, damage_script=data_damages,
                      seed=None if seed is None else seed * 2)
    ack_ch = Channel(sim, "B→A", tf=0.0, tp=tp,
                     loss=loss if ack_loss is None else ack_loss,
                     drop_script=ack_drops, seed=None if seed is None else seed * 2 + 1)
    if timeout is None:
        timeout = 2 * tp + 2 * tf   # 왕복 시간(RTT)보다 조금 길게
    sender = protocol.Sender(sim, data_ch, source, m, window, timeout, unsafe)
    receiver = protocol.Receiver(sim, ack_ch, sink, m, window, unsafe)
    data_ch.connect(receiver.on_frame)
    ack_ch.connect(sender.on_frame)

    sender.start()
    sim.run(stop=lambda: sink.errors or (sink.complete() and sender.idle()), until=until)
    return {
        "ok": sink.complete() and not sink.errors,
        "errors": sink.errors,
        "time": sim.now,
        "data_sent": data_ch.stats["sent_data"],
        "retransmissions": sender.retransmissions,
        "ack_sent": ack_ch.stats["sent_ack"],
        "nak_sent": ack_ch.stats["sent_nak"],
        "delivered": sink.delivered,
        "departures": data_ch.departures,
    }


def summary(r):
    state = "성공" if r["ok"] else "실패: " + "; ".join(r["errors"] or ["시간 초과"])
    return (f"→ {state} | 끝난 시각 {r['time']:.1f} | 데이터 전송 {r['data_sent']}회"
            f"(재전송 {r['retransmissions']}) | ACK {r['ack_sent']} | NAK {r['nak_sent']}")
