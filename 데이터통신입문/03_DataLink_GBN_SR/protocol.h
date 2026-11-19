/* protocol.h : 강의 L11·L12(Tanenbaum)의 protocol.h를 따라 만든 공통 정의.
 *
 * 데이터링크 계층 프로토콜(go_back_n.c, selective_repeat.c)은 이 파일에 선언된
 * 함수만 써서 아래(물리 계층)·위(네트워크 계층)와 주고받는다.
 * 실제 구현은 sim.c(사건 처리·타이머·네트워크 계층)와 channel.c(물리 회선)에 있다.
 */
#ifndef PROTOCOL_H
#define PROTOCOL_H

#include <stdbool.h>

#define MAX_PKT   8          /* 패킷 크기 (여기서는 "P12" 같은 이름만 담음) */
#define SEQ_LIMIT 256        /* 순서 번호 공간의 최대 크기 (m <= 8) */

typedef bool boolean;
typedef unsigned int seq_nr;                       /* 순서 번호, ACK 번호 */
typedef struct { char data[MAX_PKT]; } packet;     /* 네트워크 계층 패킷 */
typedef enum { data, ack, nak } frame_kind;        /* 프레임 종류 */

typedef struct {
    frame_kind kind;   /* data / ack / nak */
    seq_nr seq;        /* 데이터 프레임의 순서 번호 */
    seq_nr ack;        /* 마지막으로 '순서대로' 받은 프레임 번호 (누적 ACK). NAK k면 k-1 */
    packet info;       /* 네트워크 계층 패킷 */
} frame;

/* wait_for_event()가 돌려주는 사건들. 여기서는 시뮬레이터가 handler를 부를 때 넘긴다. */
typedef enum { frame_arrival, cksum_err, timeout, network_layer_ready } event_type;

/* MAX_SEQ = 2^m - 1. 강의 코드는 #define MAX_SEQ 7 이지만,
 * 실험마다 m을 바꾸려고 실행 중에 정하는 변수로 둔다. */
extern seq_nr MAX_SEQ;

/* 순서 번호를 원형으로 1 증가: 0, 1, ..., MAX_SEQ, 0, ... (강의 코드의 inc 매크로) */
#define inc(k) do { if ((k) < MAX_SEQ) (k) = (k) + 1; else (k) = 0; } while (0)

/* ---- 순서 번호 비교 (sim.c) ---- */
boolean between(seq_nr a, seq_nr b, seq_nr c);          /* 원형에서 a <= b < c 인가 */
boolean in_window(seq_nr lower, seq_nr x, seq_nr count); /* x가 lower부터 count개 안에 있나 */

/* ---- 네트워크 계층과의 인터페이스 (sim.c) ---- */
void from_network_layer(packet *p);   /* 보낼 패킷 하나 가져오기 */
void to_network_layer(packet *p);     /* 받은 패킷 위로 넘기기 */
void enable_network_layer(void);      /* network_layer_ready 사건 허용 */
void disable_network_layer(void);     /* 윈도우가 찼으면 막기 */

/* ---- 물리 계층과의 인터페이스 (channel.c) ---- */
void to_physical_layer(frame *s);     /* 송신 측이면 A→B, 수신 측이면 B→A 회선으로 */

/* ---- 타이머 (sim.c) ---- */
void start_timer(seq_nr k);           /* 프레임 k의 타이머 시작 (전송이 끝난 시각부터) */
void stop_timer(seq_nr k);

/* ---- 프로토콜 하나를 시뮬레이터에 끼우는 틀 ----
 * 강의 코드는 protocol5()/protocol6() 안의 while(true){ wait_for_event(); switch... }
 * 한 덩어리이지만, 여기서는 송신 측·수신 측 처리를 따로 떼어 시뮬레이터가 부른다. */
typedef struct {
    const char *name;
    seq_nr (*max_window)(void);                          /* 규칙상 최대 윈도우 */
    void (*init)(seq_nr window);
    void (*sender)(event_type event, frame *r, seq_nr timer_nr);
    void (*receiver)(event_type event, frame *r);
    boolean (*sender_idle)(void);                        /* 미확인 프레임이 없나 */
} protocol;

extern const protocol GO_BACK_N;
extern const protocol SELECTIVE_REPEAT;

#endif
