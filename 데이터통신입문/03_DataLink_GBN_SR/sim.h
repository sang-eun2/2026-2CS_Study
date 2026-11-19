/* sim.h : 시뮬레이션 설정·결과와 시뮬레이터 내부 함수 */
#ifndef SIM_H
#define SIM_H

#include "protocol.h"

#define MAX_SCRIPT   16
#define MAX_PACKETS  2000

/* 재현용 각본: "kind 프레임 num번의 nth번째 전송"을 잃거나 손상시킨다.
 * num은 데이터면 seq, ACK·NAK면 ack 필드. */
typedef struct { frame_kind kind; seq_nr num; int nth; } script_entry;

typedef struct {
    int m;                 /* 순서 번호 비트 수 */
    seq_nr window;         /* 0이면 프로토콜의 최대 윈도우 */
    int n_packets;
    double tf, tp;         /* 데이터 프레임 전송 시간, 전파 지연 */
    double timeout;        /* 0이면 2*tp + 2*tf */
    double loss, damage;   /* 무작위 손실·손상 확률 (데이터 채널) */
    double ack_loss;       /* ACK 채널 손실 확률. 음수면 loss와 같음 */
    unsigned seed;
    boolean verbose, unsafe;   /* unsafe: 윈도우 규칙 위반 허용(실험용) */
    double until;              /* 이 시각이 지나면 멈춤 */
    script_entry data_drops[MAX_SCRIPT];   int n_data_drops;
    script_entry ack_drops[MAX_SCRIPT];    int n_ack_drops;
    script_entry data_damages[MAX_SCRIPT]; int n_data_damages;
} config;

typedef struct {
    boolean ok;            /* 모든 패킷을 순서대로, 중복 없이 전달 */
    char error[160];
    double time;           /* 끝난 시각 */
    int data_sent, retransmissions, acks_sent, naks_sent;
    int delivered;
    char delivered_list[256];      /* "P0 P1 ..." (앞부분만) */
    const double *departures;      /* 데이터 프레임 전송 완료 시각들 */
} result;

config default_config(void);
result run(const protocol *p, const config *c);
void print_summary(const result *r);

/* 프로토콜 코드에서 쓰는 보조 함수 */
void sim_log(const char *who, const char *fmt, ...);
const char *frame_str(const frame *f);
extern const char *SENDER, *RECEIVER;

/* channel.c ↔ sim.c */
typedef enum { SIDE_A, SIDE_B } side;      /* A: 송신 측, B: 수신 측 */
void   channel_setup(const config *c);
double channel_send(side from, const frame *f);    /* 전송 완료 시각을 돌려줌 */
void   channel_stats(int *data_sent, int *acks, int *naks);
void   sim_schedule_arrival(side to, double at, const frame *f, boolean ok);
double sim_now(void);
extern double departures[MAX_PACKETS * 8];
extern int n_departures;

/* experiments.c */
void window_limit_demo(void);
void utilization_demo(void);
void compare_demo(void);

#endif
