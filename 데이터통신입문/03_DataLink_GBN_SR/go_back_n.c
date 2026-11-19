/* go_back_n.c : Go-Back-N (강의 L12, Tanenbaum protocol 5)
 *
 * 송신 측: 윈도우 <= MAX_SEQ = 2^m - 1. ack_expected(S_f) ~ next_frame_to_send(S_n)
 *          사이 프레임 사본을 보관. 프레임마다 타이머, 타임아웃이면 ack_expected부터 전부 재전송.
 * 수신 측: 윈도우 = 1 (frame_expected 하나). 기대한 번호만 받고 나머지는 버림.
 *          받든 버리든 '마지막으로 순서대로 받은 번호'로 ACK (누적 ACK, 중복 ACK).
 *
 * 강의 코드와 다른 점: 데이터는 A→B 한 방향, ACK는 따로 보내는 ack 프레임 (피기백 없음).
 */
#include "sim.h"

/* 송신 측 상태 */
static seq_nr next_frame_to_send;    /* S_n: 다음에 보낼 새 프레임 */
static seq_nr ack_expected;          /* S_f: 가장 오래된 미확인 프레임 */
static seq_nr nbuffered;             /* 보냈지만 ACK 못 받은 개수 */
static seq_nr window;
static packet buffer[SEQ_LIMIT];     /* 재전송용 사본 */
/* 수신 측 상태 */
static seq_nr frame_expected;        /* R_n */

static seq_nr max_window(void) { return MAX_SEQ; }
static boolean sender_idle(void) { return nbuffered == 0; }

static void init(seq_nr w) {
    next_frame_to_send = ack_expected = nbuffered = frame_expected = 0;
    window = w;
}

static void send_data(seq_nr frame_nr, boolean resend) {
    frame s;
    s.kind = data;
    s.info = buffer[frame_nr];
    s.seq = frame_nr;
    s.ack = 0;                                   /* 피기백 ACK는 쓰지 않음 */
    sim_log(SENDER, "%s %s", resend ? "재전송" : "전송", frame_str(&s));
    to_physical_layer(&s);
    start_timer(frame_nr);
}

static void sender(event_type event, frame *r, seq_nr timer_nr) {
    seq_nr i, first = ack_expected, moved = 0;

    switch (event) {
    case network_layer_ready:                    /* 새 패킷을 받아 보내고 윈도우 위 끝을 늘림 */
        from_network_layer(&buffer[next_frame_to_send]);
        nbuffered = nbuffered + 1;
        send_data(next_frame_to_send, false);
        inc(next_frame_to_send);
        break;

    case frame_arrival:                          /* ACK n은 n, n-1, ... 까지 모두 확인 (누적) */
        while (in_window(ack_expected, r->ack, nbuffered)) {
            nbuffered = nbuffered - 1;
            stop_timer(ack_expected);
            inc(ack_expected);                   /* 윈도우 아래 끝 전진 */
            moved++;
        }
        if (moved == 0)
            sim_log(SENDER, "%s 수신 → 이미 확인된 번호(중복 ACK), 무시", frame_str(r));
        else if (moved == 1)
            sim_log(SENDER, "%s 수신 → %u번 확인, 윈도우 [S_f=%u, S_n=%u) 미확인 %u개",
                    frame_str(r), first, ack_expected, next_frame_to_send, nbuffered);
        else
            sim_log(SENDER, "%s 수신 → %u~%u번 %u개 확인, 윈도우 [S_f=%u, S_n=%u) 미확인 %u개",
                    frame_str(r), first, r->ack, moved, ack_expected, next_frame_to_send, nbuffered);
        break;

    case cksum_err:
        sim_log(SENDER, "손상된 ACK 도착 → 버림");
        break;

    case timeout:                                /* Go back N: 미확인 프레임 전부 다시 */
        sim_log(SENDER, "⏰ 프레임 %u 타임아웃 → %u번부터 %u개 전부 재전송",
                timer_nr, ack_expected, nbuffered);
        next_frame_to_send = ack_expected;
        for (i = 1; i <= nbuffered; i++) {
            send_data(next_frame_to_send, true);
            inc(next_frame_to_send);
        }
        break;
    }

    if (nbuffered < window) enable_network_layer();
    else disable_network_layer();
}

static void receiver(event_type event, frame *r) {
    frame s;
    if (event == cksum_err) {                    /* 손상 프레임은 조용히 버림 */
        sim_log(RECEIVER, "손상된 프레임 도착(체크섬 오류) → 조용히 버림");
        return;
    }
    if (r->seq == frame_expected) {              /* 순서대로 온 프레임만 받는다 */
        sim_log(RECEIVER, "%s 순서 맞음 → 네트워크 계층에 전달", frame_str(r));
        to_network_layer(&r->info);
        inc(frame_expected);                     /* 수신 윈도우 한 칸 이동 */
    } else {
        sim_log(RECEIVER, "%s 기대 번호는 %u → 버림", frame_str(r), frame_expected);
    }
    s.kind = ack;
    s.seq = 0;
    s.ack = (frame_expected + MAX_SEQ) % (MAX_SEQ + 1);   /* frame_expected - 1 (원형) */
    to_physical_layer(&s);
}

const protocol GO_BACK_N = { "GBN", max_window, init, sender, receiver, sender_idle };
