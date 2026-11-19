"""자동 검증: python3 -m unittest test_protocols.py

- 순서 번호 연산(inc, between)이 원형으로 맞게 동작하는지
- 강의 예제 시나리오가 슬라이드와 같은 결과를 내는지
- 무작위 손실·손상 수백 회에서도 '빠짐없이, 중복 없이, 순서대로' 전달하는지
- 윈도우 규칙을 어기면 실제로 중복 전달이 일어나는지
"""
import unittest

import go_back_n
import runner
import selective_repeat
from frame import between, inc


class SeqArithmetic(unittest.TestCase):
    def test_inc_wraps(self):
        self.assertEqual([inc(k, 3) for k in range(4)], [1, 2, 3, 0])

    def test_between(self):
        self.assertTrue(between(1, 2, 3))
        self.assertTrue(between(6, 7, 1))   # 6,7,0 구간에서 7
        self.assertTrue(between(6, 0, 1))   # 6,7,0 구간에서 0
        self.assertFalse(between(6, 1, 1))  # 위 끝은 포함 안 함
        self.assertFalse(between(2, 1, 5))


class LectureScenarios(unittest.TestCase):
    def test_gbn_lost_frame_resends_from_2(self):
        r = runner.run(go_back_n, n_packets=6, m=2, verbose=False,
                       data_drops={("data", 2, 1)})
        self.assertTrue(r["ok"])
        self.assertEqual(r["retransmissions"], 3)   # 2와 그 뒤 프레임까지

    def test_gbn_lost_ack_no_retransmission(self):
        r = runner.run(go_back_n, n_packets=6, m=2, verbose=False, timeout=20,
                       ack_drops={("ack", 2, 1)})
        self.assertTrue(r["ok"])
        self.assertEqual(r["retransmissions"], 0)   # ACK 3이 누적으로 덮음

    def test_sr_nak_resends_only_lost_frame(self):
        r = runner.run(selective_repeat, n_packets=4, m=3, verbose=False, timeout=25,
                       data_drops={("data", 1, 1)})
        self.assertTrue(r["ok"])
        self.assertEqual((r["retransmissions"], r["nak_sent"], r["ack_sent"]), (1, 1, 2))


class RandomLoss(unittest.TestCase):
    def check(self, protocol, m):
        for loss in (0.1, 0.3):
            for seed in range(1, 101):
                r = runner.run(protocol, n_packets=40, m=m, loss=loss, damage=0.05,
                               seed=seed, verbose=False, until=1e5)
                self.assertTrue(r["ok"], f"loss={loss} seed={seed} {r['errors']}")

    def test_gbn(self):
        self.check(go_back_n, 3)

    def test_sr(self):
        self.check(selective_repeat, 3)


class WindowLimit(unittest.TestCase):
    def run_case(self, protocol, window):
        return runner.run(protocol, n_packets=6, m=2, window=window, unsafe=True,
                          verbose=False, until=200,
                          ack_drops={("ack", i, 1) for i in range(window)})

    def test_gbn_limit(self):
        self.assertTrue(self.run_case(go_back_n, 3)["ok"])
        self.assertTrue(self.run_case(go_back_n, 4)["errors"])

    def test_sr_limit(self):
        self.assertTrue(self.run_case(selective_repeat, 2)["ok"])
        self.assertTrue(self.run_case(selective_repeat, 3)["errors"])

    def test_safe_mode_rejects_big_window(self):
        with self.assertRaises(ValueError):
            runner.run(go_back_n, m=2, window=4, verbose=False)


if __name__ == "__main__":
    unittest.main()
