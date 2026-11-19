/* sim.c : 이산 사건 시뮬레이터, 타이머, 네트워크 계층 흉내
 *
 * 실제 시간을 기다리지 않고 "언제 무슨 일이 일어나는지"를 우선순위 큐(힙)에 넣어
 * 시간 순서대로 꺼낸다. 꺼낸 사건을 프로토콜의 송신 측·수신 측 함수에 넘기는 것이
 * 강의 코드의 wait_for_event() + switch(event) 역할이다.
 */
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sim.h"

seq_nr MAX_SEQ;
const char *SENDER = "송신 ", *RECEIVER = "    수신";

/* ---------------------------------------------------------------- 사건 큐 */
typedef enum { EV_ARRIVE_B, EV_ARRIVE_A, EV_TIMER } ev_kind;
typedef struct {
    double t; long order;      /* 같은 시각이면 먼저 예약한 것부터 */
    ev_kind kind;
    frame f; boolean ok;       /* 도착 사건: 프레임과 손상 여부 */
    seq_nr nr; unsigned gen;   /* 타이머 사건: 프레임 번호와 세대 */
} event;

static event *heap; static int heap_n, heap_cap;
static long order_counter;
static double now;

static boolean earlier(const event *a, const event *b) {
    return a->t < b->t || (a->t == b->t && a->order < b->order);
}
static void push(event e) {
    if (heap_n == heap_cap) {
        heap_cap = heap_cap ? heap_cap * 2 : 256;
        heap = realloc(heap, sizeof(event) * heap_cap);
    }
    e.order = order_counter++;
    int i = heap_n++;
    while (i > 0 && earlier(&e, &heap[(i - 1) / 2])) { heap[i] = heap[(i - 1) / 2]; i = (i - 1) / 2; }
    heap[i] = e;
}
static event pop(void) {
    event top = heap[0], last = heap[--heap_n];
    int i = 0;
    for (;;) {
        int c = 2 * i + 1;
        if (c >= heap_n) break;
        if (c + 1 < heap_n && earlier(&heap[c + 1], &heap[c])) c++;
        if (!earlier(&heap[c], &last)) break;
        heap[i] = heap[c]; i = c;
    }
    heap[i] = last;
    return top;
}

double sim_now(void) { return now; }

void sim_schedule_arrival(side to, double at, const frame *f, boolean ok) {
    event e = {0};
    e.t = at; e.kind = (to == SIDE_B) ? EV_ARRIVE_B : EV_ARRIVE_A; e.f = *f; e.ok = ok;
    push(e);
}

/* ---------------------------------------------------------------- 로그 */
static boolean verbose;
void sim_log(const char *who, const char *fmt, ...) {
    if (!verbose) return;
    va_list ap; va_start(ap, fmt);
    printf("[t=%6.1f] %s | ", now, who);
    vprintf(fmt, ap);
    putchar('\n');
    va_end(ap);
}
const char *frame_str(const frame *f) {
    static char buf[4][48]; static int k;      /* 한 줄에 두 번 써도 안 겹치게 */
    char *b = buf[k++ % 4];
    if (f->kind == data) snprintf(b, 48, "DATA(seq=%u, %s)", f->seq, f->info.data);
    else if (f->kind == ack) snprintf(b, 48, "ACK %u", f->ack);
    else snprintf(b, 48, "NAK (ack=%u)", f->ack);
    return b;
}

/* ---------------------------------------------------------------- 순서 번호 비교 */
boolean between(seq_nr a, seq_nr b, seq_nr c) {
    /* 원형에서 a <= b < c 이면 참 (강의 코드 그대로) */
    return ((a <= b) && (b < c)) || ((c < a) && (a <= b)) || ((b < c) && (c < a));
}
boolean in_window(seq_nr lower, seq_nr x, seq_nr count) {
    /* between(lower, x, lower+count)와 같은 뜻. 윈도우가 2^m 전체를 채운
     * 경우(규칙 위반 실험)에도 동작하도록 개수로 비교한다. */
    return (x + (MAX_SEQ + 1) - lower) % (MAX_SEQ + 1) < count;
}

/* ---------------------------------------------------------------- 타이머 */
static unsigned timer_gen[SEQ_LIMIT];
static boolean timer_running[SEQ_LIMIT];
static double timeout_len;
static double last_send_done;        /* 바로 앞 to_physical_layer의 전송 완료 시각 */

void start_timer(seq_nr k) {
    /* start를 다시 부르면 이전 예약은 무효: 세대 번호가 달라져 울려도 무시된다 */
    event e = {0};
    timer_gen[k]++; timer_running[k] = true;
    e.t = last_send_done + timeout_len; e.kind = EV_TIMER; e.nr = k; e.gen = timer_gen[k];
    push(e);
}
void stop_timer(seq_nr k) { timer_gen[k]++; timer_running[k] = false; }

/* ---------------------------------------------------------------- 네트워크 계층 */
static int n_packets, next_packet, n_delivered;
static boolean net_enabled;
static char error_msg[160];
static char delivered_list[256];

void enable_network_layer(void)  { net_enabled = true; }
void disable_network_layer(void) { net_enabled = false; }

void from_network_layer(packet *p) { snprintf(p->data, MAX_PKT, "P%d", next_packet++); }

void to_network_layer(packet *p) {
    /* 데이터링크 계층의 약속: 빠짐없이, 중복 없이, 순서대로. 깨지면 기록 */
    char want[MAX_PKT];
    snprintf(want, MAX_PKT, "P%d", n_delivered);
    if (strcmp(p->data, want) != 0 && error_msg[0] == '\0')
        snprintf(error_msg, sizeof error_msg, "%d번째 자리에 %s 대신 %s 전달(중복)", n_delivered, want, p->data);
    if (strlen(delivered_list) + strlen(p->data) + 2 < sizeof delivered_list) {
        strcat(delivered_list, p->data); strcat(delivered_list, " ");
    }
    n_delivered++;
}

/* ---------------------------------------------------------------- 물리 계층 연결 */
static side current_side;             /* 지금 실행 중인 쪽 (to_physical_layer 방향 결정) */
void to_physical_layer(frame *s) { last_send_done = channel_send(current_side, s); }

/* ---------------------------------------------------------------- 실행 */
config default_config(void) {
    config c = {0};
    c.m = 3; c.n_packets = 8; c.tf = 1.0; c.tp = 5.0; c.ack_loss = -1; c.seed = 1;
    c.verbose = true; c.until = 1e6;
    return c;
}

static void pump(const protocol *p) {
    /* network_layer_ready: 네트워크 계층이 허용돼 있고 보낼 패킷이 있는 동안 */
    while (net_enabled && next_packet < n_packets) {
        current_side = SIDE_A;
        p->sender(network_layer_ready, NULL, 0);
    }
}

result run(const protocol *p, const config *c) {
    result r = {0};
    MAX_SEQ = (1u << c->m) - 1;
    seq_nr window = c->window ? c->window : p->max_window();
    if (window > p->max_window() && !c->unsafe) {
        snprintf(r.error, sizeof r.error, "%s 윈도우는 %u 이하여야 함", p->name, p->max_window());
        return r;
    }
    heap_n = 0; order_counter = 0; now = 0; verbose = c->verbose;
    memset(timer_gen, 0, sizeof timer_gen); memset(timer_running, 0, sizeof timer_running);
    timeout_len = c->timeout > 0 ? c->timeout : 2 * c->tp + 2 * c->tf;
    n_packets = c->n_packets; next_packet = 0; n_delivered = 0;
    error_msg[0] = '\0'; delivered_list[0] = '\0';
    channel_setup(c);
    p->init(window);

    enable_network_layer();
    pump(p);
    while (heap_n > 0) {
        if (error_msg[0] || (n_delivered == n_packets && next_packet == n_packets && p->sender_idle()))
            break;
        event e = pop();
        if (e.t > c->until) break;
        now = e.t;
        switch (e.kind) {
        case EV_ARRIVE_B:
            current_side = SIDE_B;
            p->receiver(e.ok ? frame_arrival : cksum_err, &e.f);
            break;
        case EV_ARRIVE_A:
            current_side = SIDE_A;
            p->sender(e.ok ? frame_arrival : cksum_err, &e.f, 0);
            break;
        case EV_TIMER:
            if (!timer_running[e.nr] || e.gen != timer_gen[e.nr]) break;   /* 이미 멈춘 타이머 */
            timer_running[e.nr] = false;
            current_side = SIDE_A;
            p->sender(timeout, NULL, e.nr);
            break;
        }
        pump(p);
    }

    r.ok = !error_msg[0] && n_delivered == n_packets;
    strcpy(r.error, error_msg[0] ? error_msg : (r.ok ? "" : "시간 초과"));
    r.time = now;
    channel_stats(&r.data_sent, &r.acks_sent, &r.naks_sent);
    r.retransmissions = r.data_sent - next_packet;
    r.delivered = n_delivered;
    strcpy(r.delivered_list, delivered_list);
    r.departures = departures;
    return r;
}

void print_summary(const result *r) {
    printf("→ %s%s | 끝난 시각 %.1f | 데이터 전송 %d회(재전송 %d) | ACK %d | NAK %d\n",
           r->ok ? "성공" : "실패: ", r->error, r->time, r->data_sent, r->retransmissions,
           r->acks_sent, r->naks_sent);
}
