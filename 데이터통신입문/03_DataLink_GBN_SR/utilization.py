"""링크 이용률 U = min(1, W / (1 + 2a)),  a = T_p / T_f  (강의 L12 예제).

예제: R = 1 Mbps, L = 1,000 bit, RTT = 20 ms
     → T_f = L/R = 1 ms, T_p = 10 ms, a = 10, 1 + 2a = 21
공식 값과, 오류 없는 채널에서 GBN을 실제로 돌려 잰 값을 나란히 출력한다.
"""
import go_back_n
import runner


def formula(W, a):
    return min(1.0, W / (1 + 2 * a))


def simulate(W, tf=1.0, tp=10.0, cycles=10):
    # m=5 → 번호 0~31, GBN 최대 윈도우 31 이므로 W=30까지 실험 가능
    n = W * (cycles + 1)
    r = runner.run(go_back_n, n_packets=n, m=5, window=W, tf=tf, tp=tp,
                   timeout=3 * (2 * tp + tf), verbose=False)
    assert r["ok"] and r["retransmissions"] == 0
    # 정상 상태 측정: 프레임 0과 프레임 W*cycles의 전송 완료 시각 차이 동안
    # 회선이 실제로 데이터를 내보낸 시간(W*cycles*T_f)의 비율
    d = r["departures"]
    return W * cycles * tf / (d[W * cycles] - d[0])


if __name__ == "__main__":
    R, L, RTT = 1e6, 1000, 20e-3
    tf, tp = L / R, RTT / 2
    a = tp / tf
    print(f"T_f = {tf*1e3:.0f} ms, T_p = {tp*1e3:.0f} ms, a = {a:.0f}, "
          f"BDP = {R*RTT/1e3:.0f} kbit = 프레임 {R*RTT/L:.0f}개")
    print(f"{'W':>4} | {'공식 U':>8} | {'시뮬레이션 U':>10}")
    for W in (1, 5, 10, 15, 21, 30):
        print(f"{W:>4} | {formula(W, a):>8.1%} | {simulate(W, tf=1.0, tp=a):>10.1%}")
    print("W ≥ 1 + 2a = 21 이면 송신자가 ACK를 기다리며 쉬는 시간이 없어진다 (오류 없는 채널 가정).")
