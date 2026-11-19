"""윈도우 크기 제한이 왜 필요한지 직접 깨뜨려 보는 실험 (m = 2, 순서 번호 0~3).

GBN: 송신 윈도우 ≤ 2^m - 1 = 3
SR : 송신·수신 윈도우 ≤ 2^(m-1) = 2

각본: 첫 윈도우의 데이터는 모두 잘 도착하지만, 그 ACK가 전부 사라진다.
송신자는 타임아웃 후 옛 프레임을 재전송하고, 수신자는 그 번호를
'새 프레임'으로 받아들일지 판단해야 한다.
"""
import go_back_n
import runner
import selective_repeat


def trial(title, protocol, window, n_acks):
    print(f"\n=== {title} ===")
    r = runner.run(protocol, n_packets=6, m=2, window=window, unsafe=True,
                   ack_drops={("ack", i, 1) for i in range(n_acks)}, until=200)
    print(runner.summary(r))
    print(f"   네트워크 계층이 받은 순서: {' '.join(r['delivered'])}")


if __name__ == "__main__":
    trial("GBN 윈도우 3 (= 2^m - 1, 허용) : 재전송된 0은 기대 번호 3과 달라 버려짐",
          go_back_n, 3, 3)
    trial("GBN 윈도우 4 (= 2^m, 규칙 위반) : 재전송된 옛 0을 새 0으로 받아들임",
          go_back_n, 4, 4)
    trial("SR 윈도우 2 (= 2^(m-1), 허용) : 재전송된 0은 새 수신 윈도우 {2,3} 밖이라 버려짐",
          selective_repeat, 2, 2)
    trial("SR 윈도우 3 (규칙 위반) : 새 수신 윈도우 {3,0,1} 안에 옛 0이 들어가 새 프레임으로 저장됨",
          selective_repeat, 3, 3)
