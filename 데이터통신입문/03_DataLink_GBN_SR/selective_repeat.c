/* selective_repeat.c : Selective Repeat (강의 L12, Tanenbaum protocol 6)
 *
 * 윈도우 NR_BUFS = (MAX_SEQ + 1) / 2 = 2^(m-1) (송신·수신 모두)
 * 송신 측: 프레임마다 타이머. 타임아웃이면 그 프레임만 재전송.
 *          NAK k(ack = k-1)를 받으면 프레임 k를 바로 재전송 (빠른 재전송).
 *          ACK·NAK의 ack 필드는 누적 ACK로 처리.
 * 수신 측: frame_expected ~ too_far 안의 올바른 프레임은 순서가 어긋나도 저장(수락).
 *          윈도우 앞부분부터 연속으로 채워지면 한꺼번에 전달(수락 ≠ 전달)하고 누적 ACK.
 *          NAK는 한 번에 하나, 첫 번째 빈칸에 대해서만 (no_nak).
 *
 * 강의 코드와 다른 점
 *  - 단방향 데이터 + 별도 ACK 프레임. 강의 코드의 ack 타이머 대신 '전달 즉시 ACK'와
 *    '옛 프레임이 다시 오면 ACK 재전송'으로 같은 일을 한다.
 *  - 버퍼를 [seq % NR_BUFS] 대신 [seq]로 둔다. 윈도우 규칙을 일부러 어기는
 *    실험(experiments.c)에서도 칸이 겹치지 않게 하려는 것.
 */
#include <stdio.h>
#include <string.h>
#include "sim.h"

/* 송신 측 */
static seq_nr ack_expected, next_frame_to_send, nbuffered, window;
static packet out_buf[SEQ_LIMIT];
/* 수신 측 */
static seq_nr frame_expected, too_far;
static packet in_buf[SEQ_LIMIT];
static boolean arrived[SEQ_LIMIT];       /* 받아 둔 프레임 표시 비트 */
static boolean no_nak;                   /* 아직 NAK를 안 보냈으면 true */

static seq_nr max_window(void) { return (MAX_SEQ + 1) / 2; }
static boolean sender_idle(void) { return nbuffered == 0; }

static void init(seq_nr w) {
    ack_expected = next_frame_to_send = nbuffered = 0;
    window = w;
    frame_expected = 0;
    too_far = w;
    memset(arrived, 0, sizeof arrived);
    no_nak = true;
}

static const char *rx_window(void) {     /* 수신 윈도우를 {4,5,6,7} 꼴로 */
    static char b[128];
    int n = snprintf(b, sizeof b, "{");
    for (seq_nr k = frame_expected; k != too_far; ) {
        n += snprintf(b + n, sizeof b - n, k == frame_expected ? "%u" : ",%u", k);
        inc(k);
    }
    snprintf(b + n, sizeof b - n, "}");
    return b;
}

/* 데이터·ACK·NAK 프레임을 만들어 보낸다 (강의 코드의 send_frame) */
static void send_frame(frame_kind fk, seq_nr frame_nr, const char *why) {
    frame s;
    s.kind = fk;
    s.seq = frame_nr;
    s.ack = (frame_expected + MAX_SEQ) % (MAX_SEQ + 1);   /* 수신 측: 마지막으로 전달한 번호 */
    if (fk == data) {
        s.info = out_buf[frame_nr];
        s.ack = 0;
        sim_log(SENDER, "%s %s%s", why[0] ? "재전송" : "전송", frame_str(&s), why);
    }
    if (fk == nak) {
        no_nak = false;                                    /* 빈칸당 NAK 한 번 */
        sim_log(RECEIVER, "첫 빈칸 %u번에 대해 NAK 전송", frame_expected);
    }
    to_physical_layer(&s);
    if (fk == data) start_timer(frame_nr);
}

static void sender(event_type event, frame *r, seq_nr timer_nr) {
    seq_nr k, first = ack_expected, moved = 0;

    switch (event) {
    case network_layer_ready:
        nbuffered = nbuffered + 1;
        from_network_layer(&out_buf[next_frame_to_send]);
        send_frame(data, next_frame_to_send, "");
        inc(next_frame_to_send);
        break;

    case frame_arrival:
        if (r->kind == nak) {                              /* ① NAK k: k = ack + 1 만 재전송 */
            k = (r->ack + 1) % (MAX_SEQ + 1);
            if (in_window(ack_expected, k, nbuffered)) {
                sim_log(SENDER, "NAK %u 수신", k);
                send_frame(data, k, " ← NAK로 빠른 재전송");
            } else {
                sim_log(SENDER, "NAK %u 수신 → %u번은 미확인 프레임이 아님, 무시", k, k);
            }
        }
        while (in_window(ack_expected, r->ack, nbuffered)) {   /* ② 누적 ACK */
            nbuffered = nbuffered - 1;
            stop_timer(ack_expected);
            inc(ack_expected);
            moved++;
        }
        if (moved == 1)
            sim_log(SENDER, "누적 ack=%u → %u번 확인, 윈도우 [S_f=%u, S_n=%u) 미확인 %u개",
                    r->ack, first, ack_expected, next_frame_to_send, nbuffered);
        else if (moved > 1)
            sim_log(SENDER, "누적 ack=%u → %u~%u번 %u개 확인, 윈도우 [S_f=%u, S_n=%u) 미확인 %u개",
                    r->ack, first, r->ack, moved, ack_expected, next_frame_to_send, nbuffered);
        else if (r->kind == ack)
            sim_log(SENDER, "%s 수신 → 이미 확인된 번호, 무시", frame_str(r));
        break;

    case cksum_err:
        sim_log(SENDER, "손상된 ACK/NAK 도착 → 버림");
        break;

    case timeout:                                          /* 그 프레임만 다시 */
        sim_log(SENDER, "⏰ 프레임 %u 타임아웃", timer_nr);
        send_frame(data, timer_nr, " ← 타임아웃, 이 프레임만");
        break;
    }

    if (nbuffered < window) enable_network_layer();
    else disable_network_layer();
}

static void receiver(event_type event, frame *r) {
    boolean nak_now = false;
    char delivered[128] = "";

    if (event == cksum_err) {
        sim_log(RECEIVER, "손상된 프레임 도착(체크섬 오류) → 버림");
        if (no_nak) send_frame(nak, 0, "");
        return;
    }
    if (r->seq != frame_expected && no_nak) {             /* 첫 빈칸에 대해 NAK 한 번 */
        sim_log(RECEIVER, "%s 기대 번호(%u)와 다름, 수신 윈도우 %s", frame_str(r), frame_expected, rx_window());
        send_frame(nak, 0, "");
        nak_now = true;
    }
    if (between(frame_expected, r->seq, too_far) && !arrived[r->seq]) {
        arrived[r->seq] = true;                            /* 수락: 순서와 상관없이 저장 */
        in_buf[r->seq] = r->info;
        sim_log(RECEIVER, "%s 수락(버퍼 저장) 수신 윈도우 %s", frame_str(r), rx_window());
        while (arrived[frame_expected]) {                  /* 전달: 윈도우 앞부분부터 연속인 만큼 */
            to_network_layer(&in_buf[frame_expected]);
            if (strlen(delivered) + MAX_PKT + 2 < sizeof delivered) {
                if (delivered[0]) strcat(delivered, ", ");
                strcat(delivered, in_buf[frame_expected].data);
            }
            no_nak = true;                                 /* 빈칸이 메워졌으니 다음 NAK 허용 */
            arrived[frame_expected] = false;
            inc(frame_expected);                           /* 수신 윈도우 이동 */
            inc(too_far);
        }
        if (delivered[0]) {
            sim_log(RECEIVER, "%s 네트워크 계층에 전달 → ACK %u", delivered,
                    (frame_expected + MAX_SEQ) % (MAX_SEQ + 1));
            send_frame(ack, 0, "");
        }
    } else {
        sim_log(RECEIVER, "%s 윈도우 밖이거나 이미 받은 프레임 → 버림 (수신 윈도우 %s)", frame_str(r), rx_window());
        /* 옛 프레임이 또 왔다 = 송신 측이 ACK를 못 받았다. 방금 NAK(누적 ack 포함)를
         * 안 보냈다면 ACK를 다시 보낸다. 이게 없으면 ACK와 NAK가 모두 사라졌을 때
         * 송신 측이 영원히 재전송만 반복한다. */
        if (!nak_now) {
            sim_log(RECEIVER, "중복 수신 → ACK %u 다시 전송", (frame_expected + MAX_SEQ) % (MAX_SEQ + 1));
            send_frame(ack, 0, "");
        }
    }
}

const protocol SELECTIVE_REPEAT = { "SR", max_window, init, sender, receiver, sender_idle };
