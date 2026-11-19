/* main.c : 실행 진입점. 강의 예제 시나리오와 자동 검증(test)
 *
 *   ./datalink gbn [시나리오]          ./datalink sr [시나리오]
 *   ./datalink gbn --loss 0.2 [--packets N] [--seed S] [-m M]
 *   ./datalink window | util | compare | test
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sim.h"
#ifdef _WIN32
#include <windows.h>
#endif

typedef struct { const char *name, *title; config c; } scenario;

static config with_drop(config c, frame_kind k, seq_nr num) {
    c.data_drops[c.n_data_drops++] = (script_entry){ k, num, 1 };
    return c;
}

/* ---------------------------------------------------------------- 강의 예제 */
static int gbn_scenarios(scenario *s) {
    config b = default_config();
    b.m = 2; b.n_packets = 6;                       /* 번호 0~3, 윈도우 3 */
    int n = 0;
    s[n++] = (scenario){ "normal", "정상 (윈도우 3)", b };
    s[n++] = (scenario){ "lost-frame", "프레임 2 분실 → 3은 순서 어긋나 버려짐 → 타임아웃 후 2부터 재전송",
                         with_drop(b, data, 2) };
    config la = b; la.timeout = 20; la.ack_drops[la.n_ack_drops++] = (script_entry){ ack, 2, 1 };
    s[n++] = (scenario){ "lost-ack", "ACK 2 분실 → 타임아웃 전에 ACK 3이 와서 누적 ACK로 해결 (타임아웃 20)", la };
    config dm = b; dm.data_damages[dm.n_data_damages++] = (script_entry){ data, 1, 1 };
    s[n++] = (scenario){ "damaged", "프레임 1 손상 → 수신 측이 조용히 버림 → 타임아웃 후 1부터 재전송", dm };
    return n;
}

static int sr_scenarios(scenario *s) {
    config b = default_config();
    b.m = 3; b.n_packets = 4; b.timeout = 25;       /* 윈도우 4. 누적 ACK가 늦으니 타임아웃 넉넉히 */
    int n = 0;
    s[n++] = (scenario){ "normal", "정상 (m=3, 윈도우 4)", b };
    s[n++] = (scenario){ "lost-frame", "프레임 1 분실 → 2, 3 저장 + NAK 1 → 1만 재전송 → ACK 3으로 1~3 한꺼번에 전달",
                         with_drop(b, data, 1) };
    config ln = with_drop(b, data, 1); ln.ack_drops[ln.n_ack_drops++] = (script_entry){ nak, 0, 1 };
    s[n++] = (scenario){ "lost-nak", "프레임 1 분실 + NAK도 분실 → 프레임 1 타이머가 복구 (2, 3도 ACK가 늦어 타임아웃)", ln };
    config la = b;
    for (seq_nr i = 0; i < 4; i++) la.ack_drops[la.n_ack_drops++] = (script_entry){ ack, i, 1 };
    s[n++] = (scenario){ "lost-ack", "ACK 0~3 분실 → 재전송분은 윈도우 밖이라 버리고, NAK에 실린 누적 ack로 복구", la };
    config st = with_drop(b, data, 1); st.timeout = 12;
    s[n++] = (scenario){ "short-timeout", "[비교] lost-frame과 같지만 타임아웃이 짧으면(12) 저장된 2, 3까지 재전송됨", st };
    return n;
}

static int run_protocol_cli(const protocol *p, int argc, char **argv) {
    scenario s[8];
    int n = (p == &GO_BACK_N) ? gbn_scenarios(s) : sr_scenarios(s);
    const char *pick = NULL;
    config c = default_config();
    boolean random_mode = false;
    c.n_packets = 10;
    for (int i = 2; i < argc; i++) {
        if (!strcmp(argv[i], "--loss") && i + 1 < argc) { c.loss = atof(argv[++i]); random_mode = true; }
        else if (!strcmp(argv[i], "--packets") && i + 1 < argc) c.n_packets = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--seed") && i + 1 < argc) c.seed = (unsigned)atoi(argv[++i]);
        else if (!strcmp(argv[i], "-m") && i + 1 < argc) c.m = atoi(argv[++i]);
        else pick = argv[i];
    }
    if (random_mode) {
        if (c.n_packets > MAX_PACKETS) c.n_packets = MAX_PACKETS;
        printf("=== %s 무작위 손실 %.0f%%, m=%d ===\n", p->name, 100 * c.loss, c.m);
        result r = run(p, &c);
        print_summary(&r);
        return r.ok ? 0 : 1;
    }
    int found = 0;
    for (int i = 0; i < n; i++) {
        if (pick && strcmp(pick, s[i].name)) continue;
        found = 1;
        printf("\n=== %s [%s] %s ===\n", p->name, s[i].name, s[i].title);
        result r = run(p, &s[i].c);
        print_summary(&r);
    }
    if (!found) {
        printf("시나리오 이름: ");
        for (int i = 0; i < n; i++) printf("%s ", s[i].name);
        printf("\n");
        return 1;
    }
    return 0;
}

/* ---------------------------------------------------------------- 자동 검증 */
static int passed, failed;
#define CHECK(cond, msg) do { if (cond) passed++; else { failed++; printf("  실패: %s\n", msg); } } while (0)

static result quiet(const protocol *p, config c) { c.verbose = false; return run(p, &c); }
extern double simulate_utilization(seq_nr w, double a);

static int self_test(void) {
    scenario s[8];
    char msg[96];

    /* 순서 번호 연산 */
    MAX_SEQ = 3;
    seq_nr k = 3; inc(k);
    CHECK(k == 0, "inc: 3 다음은 0 (m=2)");
    MAX_SEQ = 7;
    CHECK(between(1, 2, 3), "between(1,2,3)");
    CHECK(between(6, 7, 1) && between(6, 0, 1), "between: 6,7,0 구간");
    CHECK(!between(6, 1, 1) && !between(2, 1, 5), "between: 구간 밖");

    /* 강의 예제 */
    gbn_scenarios(s);
    result r = quiet(&GO_BACK_N, s[1].c);
    CHECK(r.ok && r.retransmissions == 3, "GBN 프레임 2 분실 → 2부터 3개 재전송");
    r = quiet(&GO_BACK_N, s[2].c);
    CHECK(r.ok && r.retransmissions == 0, "GBN ACK 2 분실 → ACK 3이 덮어 재전송 없음");
    sr_scenarios(s);
    r = quiet(&SELECTIVE_REPEAT, s[1].c);
    CHECK(r.ok && r.retransmissions == 1 && r.naks_sent == 1 && r.acks_sent == 2,
          "SR 프레임 1 분실 → NAK 1, 1만 재전송, ACK 0·3");

    /* 무작위 손실·손상: 빠짐없이, 중복 없이, 순서대로 */
    const protocol *ps[2] = { &GO_BACK_N, &SELECTIVE_REPEAT };
    double losses[3] = { 0.1, 0.3, 0.5 };
    for (int pi = 0; pi < 2; pi++)
        for (int m = 2; m <= 4; m++)
            for (int li = 0; li < 3; li++) {
                int bad = 0;
                for (unsigned seed = 1; seed <= 100; seed++) {
                    config c = default_config();
                    c.m = m; c.n_packets = 40; c.loss = losses[li]; c.damage = 0.05; c.seed = seed;
                    c.until = 1e5;
                    if (!quiet(ps[pi], c).ok) bad++;
                }
                snprintf(msg, sizeof msg, "%s m=%d 손실 %.0f%% 100회 모두 성공 (실패 %d)",
                         ps[pi]->name, m, 100 * losses[li], bad);
                CHECK(bad == 0, msg);
            }

    /* 너무 짧은 타임아웃에서도 결과는 맞아야 함 (효율만 나빠짐) */
    for (int pi = 0; pi < 2; pi++) {
        int bad = 0;
        for (unsigned seed = 1; seed <= 50; seed++) {
            config c = default_config();
            c.m = 3; c.n_packets = 40; c.loss = 0.2; c.timeout = 2; c.seed = seed;
            if (!quiet(ps[pi], c).ok) bad++;
        }
        snprintf(msg, sizeof msg, "%s 짧은 타임아웃(2)에서도 정확히 전달", ps[pi]->name);
        CHECK(bad == 0, msg);
    }

    /* 윈도우 제한 */
    for (int pi = 0; pi < 2; pi++) {
        seq_nr ok_w = pi == 0 ? 3 : 2;
        for (seq_nr w = ok_w; w <= ok_w + 1; w++) {
            config c = default_config();
            c.m = 2; c.window = w; c.n_packets = 6; c.unsafe = true; c.until = 200;
            for (seq_nr i = 0; i < w; i++) c.ack_drops[c.n_ack_drops++] = (script_entry){ ack, i, 1 };
            r = quiet(ps[pi], c);
            snprintf(msg, sizeof msg, "%s 윈도우 %u → %s", ps[pi]->name, w, w == ok_w ? "성공" : "중복 전달");
            CHECK(w == ok_w ? r.ok : (!r.ok && strstr(r.error, "중복") != NULL), msg);
        }
    }
    config big = default_config(); big.m = 2; big.window = 4;
    CHECK(!quiet(&GO_BACK_N, big).ok, "규칙보다 큰 윈도우는 unsafe 없이 거부");

    /* 이용률 */
    CHECK(simulate_utilization(1, 10) > 0.047 && simulate_utilization(1, 10) < 0.048, "W=1 이용률 1/21");
    CHECK(simulate_utilization(15, 10) > 0.714 && simulate_utilization(15, 10) < 0.715, "W=15 이용률 15/21");
    CHECK(simulate_utilization(21, 10) > 0.999, "W=21 이용률 100%");

    printf("테스트 %d개 중 %d개 통과\n", passed + failed, passed);
    return failed ? 1 : 0;
}

/* ---------------------------------------------------------------- 진입점 */
int main(int argc, char **argv) {
#ifdef _WIN32
    SetConsoleOutputCP(CP_UTF8);         /* 한글 출력 */
#endif
    const char *cmd = argc > 1 ? argv[1] : "";
    if (!strcmp(cmd, "gbn")) return run_protocol_cli(&GO_BACK_N, argc, argv);
    if (!strcmp(cmd, "sr")) return run_protocol_cli(&SELECTIVE_REPEAT, argc, argv);
    if (!strcmp(cmd, "window")) { window_limit_demo(); return 0; }
    if (!strcmp(cmd, "util")) { utilization_demo(); return 0; }
    if (!strcmp(cmd, "compare")) { compare_demo(); return 0; }
    if (!strcmp(cmd, "test")) return self_test();
    printf("사용법: %s gbn|sr [시나리오] | gbn|sr --loss P [--packets N] [--seed S] [-m M]\n"
           "        %s window | util | compare | test\n", argv[0], argv[0]);
    return 1;
}
