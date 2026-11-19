/* experiments.c : 윈도우 제한 실험, 이용률, 손실률별 GBN vs SR 비교 */
#include <stdio.h>
#include "sim.h"

/* ---------------------------------------------------------------- 윈도우 제한
 * m = 2 (번호 0~3). 첫 윈도우의 데이터는 다 도착하는데 그 ACK가 전부 사라지는 각본.
 * 규칙(GBN <= 2^m-1, SR <= 2^(m-1))을 어기면 옛 프레임을 새 프레임으로 받아들인다. */
static void trial(const char *title, const protocol *p, seq_nr w) {
    config c = default_config();
    c.m = 2; c.window = w; c.n_packets = 6; c.unsafe = true; c.until = 200;
    for (seq_nr i = 0; i < w; i++) c.ack_drops[c.n_ack_drops++] = (script_entry){ ack, i, 1 };
    printf("\n=== %s ===\n", title);
    result r = run(p, &c);
    print_summary(&r);
    printf("   네트워크 계층이 받은 순서: %s\n", r.delivered_list);
}

void window_limit_demo(void) {
    trial("GBN 윈도우 3 (= 2^m - 1, 허용) : 재전송된 0은 기대 번호 3과 달라 버려짐", &GO_BACK_N, 3);
    trial("GBN 윈도우 4 (= 2^m, 규칙 위반) : 재전송된 옛 0을 새 0으로 받아들임", &GO_BACK_N, 4);
    trial("SR 윈도우 2 (= 2^(m-1), 허용) : 재전송된 0은 새 수신 윈도우 {2,3} 밖이라 버려짐", &SELECTIVE_REPEAT, 2);
    trial("SR 윈도우 3 (규칙 위반) : 새 수신 윈도우 {3,0,1} 안에 옛 0이 들어가 새 프레임으로 저장됨", &SELECTIVE_REPEAT, 3);
}

/* ---------------------------------------------------------------- 이용률
 * U = min(1, W / (1 + 2a)), a = T_p / T_f
 * 강의 예제: R = 1 Mbps, L = 1,000 bit, RTT = 20 ms → T_f = 1 ms, T_p = 10 ms, a = 10 */
double simulate_utilization(seq_nr w, double a) {
    const int cycles = 10;
    config c = default_config();
    c.m = 5; c.window = w; c.n_packets = (int)w * (cycles + 1);
    c.tf = 1.0; c.tp = a; c.timeout = 3 * (2 * a + 1); c.verbose = false;
    result r = run(&GO_BACK_N, &c);
    if (!r.ok || r.retransmissions) return -1;
    /* 정상 상태: 프레임 0과 프레임 W*cycles의 전송 완료 시각 사이에
     * 회선이 실제로 데이터를 내보낸 시간의 비율 */
    return w * cycles * c.tf / (r.departures[w * cycles] - r.departures[0]);
}

void utilization_demo(void) {
    double R = 1e6, L = 1000, RTT = 20e-3, tf = L / R, tp = RTT / 2, a = tp / tf;
    seq_nr ws[] = { 1, 5, 10, 15, 21, 30 };
    printf("T_f = %.0f ms, T_p = %.0f ms, a = %.0f, BDP = %.0f kbit = 프레임 %.0f개\n",
           tf * 1e3, tp * 1e3, a, R * RTT / 1e3, R * RTT / L);
    printf("%4s | %8s | %12s\n", "W", "공식 U", "시뮬레이션 U");
    for (int i = 0; i < 6; i++) {
        double f = ws[i] / (1 + 2 * a);
        if (f > 1) f = 1;
        printf("%4u | %7.1f%% | %11.1f%%\n", ws[i], 100 * f, 100 * simulate_utilization(ws[i], a));
    }
    printf("W >= 1 + 2a = 21 이면 송신 측이 ACK를 기다리며 쉬는 시간이 없어진다 (오류 없는 채널 가정).\n");
}

/* ---------------------------------------------------------------- GBN vs SR
 * 같은 윈도우 7 (GBN m=3 → 최대 7, SR m=4 → 최대 8), 데이터·ACK 채널 같은 손실률, 시드 30개 평균 */
#define N_PKT 200
#define W_CMP 7
#define TP_CMP 5.0
#define SEEDS 30

static void average(const protocol *p, int m, double loss, double *sent, double *time) {
    *sent = *time = 0;
    for (unsigned s = 1; s <= SEEDS; s++) {
        config c = default_config();
        c.m = m; c.window = W_CMP; c.n_packets = N_PKT; c.tp = TP_CMP; c.loss = loss;
        c.timeout = 2 * TP_CMP + W_CMP + 4; c.seed = s; c.verbose = false;
        result r = run(p, &c);
        if (!r.ok) printf("  (경고: %s seed %u 실패: %s)\n", p->name, s, r.error);
        *sent += r.data_sent; *time += r.time;
    }
    *sent /= SEEDS; *time /= SEEDS;
}

void compare_demo(void) {
    double losses[] = { 0.0, 0.05, 0.1, 0.2, 0.3 };
    printf("패킷 %d개, 윈도우 %d, T_f=1, T_p=%.0f, 시드 %d개 평균\n\n", N_PKT, W_CMP, TP_CMP, SEEDS);
    printf("%6s | %9s | %8s %7s %6s | %7s %7s %6s\n",
           "손실률", "이론 최소", "GBN 전송", "효율", "완료", "SR 전송", "효율", "완료");
    for (int i = 0; i < 5; i++) {
        double gs, gt, ss, st;
        average(&GO_BACK_N, 3, losses[i], &gs, &gt);
        average(&SELECTIVE_REPEAT, 4, losses[i], &ss, &st);
        printf("%5.0f%% | %9.0f | %8.0f %6.1f%% %6.0f | %7.0f %6.1f%% %6.0f\n",
               100 * losses[i], N_PKT / (1 - losses[i]), gs, 100 * N_PKT / gs, gt, ss, 100 * N_PKT / ss, st);
    }
    printf("\n이론 최소 = N/(1-p): 데이터 프레임만 잃고 잃은 것만 정확히 다시 보낼 때의 기대 전송 수.\n");
    printf("GBN은 잃은 프레임 뒤의 것까지 다시 보내 전송 수가 빠르게 늘어난다.\n");
    printf("SR은 훨씬 적지만 이론 최소보다는 많다. ACK도 사라지고, ACK가 누적 방식이라\n");
    printf("빈칸이 메워질 때까지 저장된 프레임의 타이머도 계속 돌기 때문이다.\n");
}
