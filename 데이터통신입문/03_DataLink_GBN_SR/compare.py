"""손실률을 바꿔 가며 GBN과 SR을 비교한다.

같은 윈도우 크기 W = 7 에서 비교한다 (GBN은 m=3 → 최대 7, SR은 m=4 → 최대 8).
손실은 데이터·ACK 채널 모두에 같은 확률로 일어난다.
지표
  - 데이터 전송 수 : 패킷 N개를 보내려고 회선에 올린 데이터 프레임 수 (N이면 재전송 0)
  - 효율          : N / 데이터 전송 수
  - 완료 시각     : 마지막 ACK를 받은 시각 (T_f = 1 단위)
"""
import statistics

import go_back_n
import runner
import selective_repeat

N, W, TP, SEEDS = 200, 7, 5.0, range(1, 31)


def average(protocol, m, loss):
    rs = [runner.run(protocol, n_packets=N, m=m, window=W, tp=TP, loss=loss,
                     timeout=2 * TP + W + 4, seed=s, verbose=False) for s in SEEDS]
    assert all(r["ok"] for r in rs), "전달 실패"
    sent = statistics.mean(r["data_sent"] for r in rs)
    time = statistics.mean(r["time"] for r in rs)
    return sent, time


if __name__ == "__main__":
    print(f"패킷 {N}개, 윈도우 {W}, T_f=1, T_p={TP:g}, 시드 {len(SEEDS)}개 평균\n")
    print(f"{'손실률':>5} | {'이론 최소':>6} | {'GBN 전송':>7} {'효율':>6} {'완료':>6} | {'SR 전송':>6} {'효율':>6} {'완료':>6}")
    for loss in (0.0, 0.05, 0.1, 0.2, 0.3):
        g_sent, g_time = average(go_back_n, 3, loss)
        s_sent, s_time = average(selective_repeat, 4, loss)
        print(f"{loss:>6.0%} | {N/(1-loss):>9.0f} | {g_sent:>8.0f} {N/g_sent:>6.1%} {g_time:>6.0f} | "
              f"{s_sent:>7.0f} {N/s_sent:>6.1%} {s_time:>6.0f}")
    print("\n이론 최소 = N/(1-p): 데이터 프레임만 잃고 잃은 것만 정확히 다시 보낼 때의 기대 전송 수.")
    print("GBN은 잃은 프레임 뒤의 것까지 다시 보내 전송 수가 빠르게 늘어난다.")
    print("SR은 훨씬 적지만 이론 최소보다는 많다. ACK도 사라지고, ACK가 누적 방식이라")
    print("빈칸이 메워질 때까지 저장된 프레임의 타이머도 계속 돌기 때문이다.")
