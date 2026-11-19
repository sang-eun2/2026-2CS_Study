/* channel.c : 손실·손상이 일어나는 물리 회선 (A→B 데이터, B→A ACK·NAK)
 *
 * - 전송 시간 tf : 프레임 하나를 회선에 내보내는 시간 (T_f = L/R). ACK·NAK는 0
 * - 전파 지연 tp : 회선 끝까지 가는 시간 (T_p = d/v)
 * - 분실 : 프레임이 사라짐 → 받는 쪽은 아무 사건도 없음
 * - 손상 : 도착은 하지만 체크섬 오류(cksum_err) 사건이 됨
 * - 각본(drops/damages) : 강의 그림 같은 상황을 정확히 재현
 */
#include <stdint.h>
#include <string.h>
#include "sim.h"

typedef struct {
    double tf, tp, loss, damage;
    uint64_t rng;                     /* 플랫폼과 무관하게 같은 결과가 나오도록 직접 만든 난수 */
    double busy_until;                /* 앞 프레임을 내보내는 중이면 그 끝 시각 */
    int nth[3][SEQ_LIMIT];            /* (종류, 번호)별 지금까지 보낸 횟수 */
    int sent[3];
    const script_entry *drops; int n_drops;
    const script_entry *damages; int n_damages;
} channel;

static channel ch[2];                 /* ch[SIDE_A]: A→B, ch[SIDE_B]: B→A */
double departures[MAX_PACKETS * 8];
int n_departures;

static double uniform(channel *c) {   /* xorshift64* → [0, 1) */
    c->rng ^= c->rng >> 12; c->rng ^= c->rng << 25; c->rng ^= c->rng >> 27;
    return (double)((c->rng * 2685821657736338717ULL) >> 11) / 9007199254740992.0;
}

static boolean in_script(const script_entry *s, int n, frame_kind k, seq_nr num, int nth) {
    for (int i = 0; i < n; i++)
        if (s[i].kind == k && s[i].num == num && s[i].nth == nth) return true;
    return false;
}

void channel_setup(const config *c) {
    memset(ch, 0, sizeof ch);
    n_departures = 0;
    ch[SIDE_A].tf = c->tf; ch[SIDE_A].tp = c->tp; ch[SIDE_A].loss = c->loss; ch[SIDE_A].damage = c->damage;
    ch[SIDE_A].rng = 0x9E3779B97F4A7C15ULL * (2ULL * c->seed + 1);
    ch[SIDE_A].drops = c->data_drops; ch[SIDE_A].n_drops = c->n_data_drops;
    ch[SIDE_A].damages = c->data_damages; ch[SIDE_A].n_damages = c->n_data_damages;
    ch[SIDE_B].tf = 0; ch[SIDE_B].tp = c->tp; ch[SIDE_B].loss = c->ack_loss < 0 ? c->loss : c->ack_loss;
    ch[SIDE_B].rng = 0xD1B54A32D192ED03ULL * (2ULL * c->seed + 2);
    ch[SIDE_B].drops = c->ack_drops; ch[SIDE_B].n_drops = c->n_ack_drops;
}

double channel_send(side from, const frame *f) {
    channel *c = &ch[from];
    double now = sim_now();
    double start = now > c->busy_until ? now : c->busy_until;
    double done = start + c->tf;
    c->busy_until = done;

    seq_nr num = (f->kind == data) ? f->seq : f->ack;
    int nth = ++c->nth[f->kind][num];
    c->sent[f->kind]++;
    if (f->kind == data && n_departures < MAX_PACKETS * 8) departures[n_departures++] = done;

    boolean lost = in_script(c->drops, c->n_drops, f->kind, num, nth) || uniform(c) < c->loss;
    if (lost) {
        sim_log(from == SIDE_A ? "  채널 A→B" : "  채널 B→A", "✗ %s 분실", frame_str(f));
        return done;
    }
    boolean ok = !(in_script(c->damages, c->n_damages, f->kind, num, nth) || uniform(c) < c->damage);
    sim_schedule_arrival(from == SIDE_A ? SIDE_B : SIDE_A, done + c->tp, f, ok);
    return done;
}

void channel_stats(int *data_sent, int *acks, int *naks) {
    *data_sent = ch[SIDE_A].sent[data];
    *acks = ch[SIDE_B].sent[ack];
    *naks = ch[SIDE_B].sent[nak];
}
