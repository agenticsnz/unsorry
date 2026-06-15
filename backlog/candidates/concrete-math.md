# Concrete-Mathematics / OEIS closed forms — candidate backlog (Identity Engine)

Theme staging file for the Identity Engine (#400, ADR-043). 21 vetted candidates — each **absence-clean** (no name/content match in pinned mathlib `c5ea00351c` or our goal set) and screened **non-trivial** (ADR-035 battery). The expensive gates (intended proof compiling under `lake env lean` + adversarial skeptic) run at promotion. Scoped 2026-06-15.

- [ ] `sum_range_id_mul_three_pow` — Four times the sum of i·3^i over i below n, plus 3^(n+1), equals 2n·3^n + 3
      absence: no-local-match · triviality: non-trivial · intended: Induction on n with Finset.sum_range_succ, then ring after rewriting 3^(n+1) · conf: high
- [ ] `sum_range_odd_mul_three_pow` — The sum of (2i+1)·3^i over i below n, plus 3^n, equals n·3^n + 1
      absence: no-local-match · triviality: non-trivial · intended: Induction on n via Finset.sum_range_succ; close inductive step with ring · conf: high
- [ ] `sum_range_sq_mul_two_pow` — The sum of k^2·2^k over k below n, plus 6, equals 2^n·(n^2 − 4n + 6)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; note n^2-4n+6 stays nonneg, ring/nlinarith on step · conf: high
- [ ] `sum_range_sq_mul_three_pow` — Twice the sum of k^2·3^k over k below n, plus 3, equals 3^n·(n^2 − 3n + 3)
      absence: no-local-match · triviality: non-trivial · intended: Induction via Finset.sum_range_succ; factor 3^(n+1) and finish with ring · conf: high
- [ ] `sum_icc_id_mul_two_pow_pred` — The sum of k·2^(k−1) for k from 1 to n equals (n−1)·2^n + 1
      absence: no-local-match · triviality: non-trivial · intended: Induction on n with Finset.sum_Icc_succ_top; handle 2^(k-1) shift and ring · conf: high
- [ ] `sum_range_succ_mul_factorial_succ` — The sum of (i+1)·(i+1)! over i below n, plus 1, telescopes to (n+1)!
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; use Nat.factorial_succ then ring · conf: high
- [ ] `sum_range_id_mul_fib` — The sum of i·Fib(i) over i below n, plus Fib(n+3), equals n·Fib(n+1) + 2
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; rewrite Fib(n+3) via Nat.fib_add_two, then omega/ring · conf: med
- [ ] `sum_range_fib_three_step` — Twice the sum of Fib(3(i+1)) over i below n, plus 1, equals Fib(3n+2)
      absence: no-local-match · triviality: non-trivial · intended: Induction; expand Fib(3n+5) via repeated Nat.fib_add_two and simplify with omega · conf: med
- [ ] `sum_range_fib_sq_eq_prod` — The sum of the squares of Fib(i) for i from 0 to n equals Fib(n)·Fib(n+1)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; use Fib(n+2)=Fib(n+1)+Fib(n) and ring · conf: high
- [ ] `sum_range_id_mul_add_two` — Six times the sum of i·(i+2) over i below n equals n·(n−1)·(2n+5)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; nonneg n-1, finish with ring/nlinarith · conf: high
- [ ] `sum_range_four_consecutive_product` — Five times the sum of i(i+1)(i+2)(i+3) over i below n equals (n−1)n(n+1)(n+2)(n+3)
      absence: no-local-match · triviality: non-trivial · intended: Telescoping/induction with Finset.sum_range_succ; ring after handling the n-1 factor · conf: high
- [ ] `sum_range_three_mul_add_one` — Twice the sum of 3k+1 over k below n equals n·(3n−1)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; close step with ring/nlinarith · conf: high
- [ ] `sum_range_four_mul_add_one` — The sum of 4k+1 over k below n equals n·(2n−1), the n-th centered-square-style count
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; finish with ring/nlinarith · conf: high
- [ ] `alternating_sum_range_sq_succ` — The alternating sum of (i+1)^2 over i below n equals (−1)^(n+1)·(n(n+1)/2)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; case-split parity of n via pow_succ, then ring · conf: med
- [ ] `sum_range_recip_two_pow` — The partial geometric sum of 1/2^i over i below n equals 2 − 2/2^n
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; clear denominators (field_simp) then ring · conf: high
- [ ] `sum_range_id_div_two_pow` — The sum of i/2^i for i from 0 to n equals 2 − (n+2)/2^n
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; field_simp then ring on the rational step · conf: high
- [ ] `sum_range_sq_div_two_pow` — The sum of i^2/2^i for i from 0 to n equals 6 − (n^2 + 4n + 6)/2^n
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; field_simp and ring on the rational closed form · conf: med
- [ ] `sum_range_odd_div_two_pow` — The sum of (2i+1)/2^i for i from 0 to n equals 6 − (2n+5)/2^n
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; field_simp then ring · conf: high
- [ ] `sum_range_recip_odd_consecutive` — The telescoping sum of 1/((2k+1)(2k+3)) over k below n equals n/(2n+1)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; partial-fraction step closed by field_simp; ring · conf: high
- [ ] `sum_range_recip_skip_one` — The telescoping sum of 1/((k+1)(k+3)) over k below n equals 3/4 − (2n+3)/(2(n+1)(n+2))
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; field_simp clears denominators, then ring · conf: med
- [ ] `sum_range_recip_three_consecutive` — The telescoping sum of 1/((k+1)(k+2)(k+3)) over k below n equals 1/4 − 1/(2(n+1)(n+2))
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; field_simp then ring on the telescoped tail · conf: high
