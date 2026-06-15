# Telescoping sums & products — candidate backlog (Identity Engine)

Theme staging file for the Identity Engine (#400, ADR-043). 22 vetted candidates — each **absence-clean** (no name/content match in pinned mathlib `c5ea00351c` or our goal set) and screened **non-trivial** (ADR-035 battery). The expensive gates (intended proof compiling under `lake env lean` + adversarial skeptic) run at promotion. Scoped 2026-06-15.

- [ ] `sum_range_succ_mul_factorial_eq` — The sum over k from 0 to n-1 of (k+1)·(k+1)! equals (n+1)! − 1
      absence: no-local-match · triviality: non-trivial · intended: Induction on n with Finset.sum_range_succ; rewrite (k+2)! = (k+2)·(k+1)! and close with Nat arithmetic · conf: high
- [ ] `sum_range_k_div_succ_factorial_eq` — The rational sum of k/(k+1)! for k from 0 to n-1 equals 1 − 1/n!
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; per-term identity k/(k+1)! = 1/k! − 1/(k+1)! via field_simp and factorial recurrence · conf: high
- [ ] `sum_range_recip_triple_consecutive` — The sum of 1/((k+1)(k+2)(k+3)) for k from 0 to n-1 equals 1/4 − 1/(2(n+1)(n+2))
      absence: no-local-match · triviality: non-trivial · intended: Induction; per-term partial fraction 1/((k+1)(k+2)(k+3)) = ½[1/((k+1)(k+2)) − 1/((k+2)(k+3))], field_simp then ring · conf: high
- [ ] `sum_range_recip_odd_pair_consecutive` — The sum of 1/((2k+1)(2k+3)) for k from 0 to n-1 equals n/(2n+1)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; per-term ½[1/(2k+1) − 1/(2k+3)], field_simp and ring · conf: high
- [ ] `sum_range_odd_num_sq_succ_sq_telescope` — The sum of (2k+3)/((k+1)²(k+2)²) for k from 0 to n-1 equals 1 − 1/(n+1)²
      absence: no-local-match · triviality: non-trivial · intended: Induction; per-term identity (2k+3)/((k+1)²(k+2)²) = 1/(k+1)² − 1/(k+2)², field_simp then ring · conf: high
- [ ] `sum_range_recip_odd_triple_consecutive` — The sum of 1/((2k+1)(2k+3)(2k+5)) for k from 0 to n-1 equals 1/12 − 1/(4(2n+1)(2n+3))
      absence: no-local-match · triviality: non-trivial · intended: Induction; per-term ¼[1/((2k+1)(2k+3)) − 1/((2k+3)(2k+5))], field_simp then ring · conf: med
- [ ] `sum_range_fib_div_fib_fib_telescope` — The sum of F(k+1)/(F(k+2)·F(k+3)) for k from 0 to n-1 equals 1 − 1/F(n+2), where F is Fibonacci
      absence: no-local-match · triviality: non-trivial · intended: Induction using Nat.fib_add_two (F(k+3)=F(k+2)+F(k+1)) so each term = 1/F(k+2) − 1/F(k+3); needs fib positivity for field_simp · conf: med
- [ ] `prod_icc_cube_sub_one_div_cube_add_one` — The product of (k³−1)/(k³+1) for k from 2 to n equals 2(n²+n+1)/(3n(n+1))
      absence: no-local-match · triviality: non-trivial · intended: Induction from base n=2; factor k³±1 = (k±1)(k²∓k+1) and telescope the two cubic-factor chains, field_simp + ring · conf: med
- [ ] `prod_icc_one_sub_two_div_pronic` — The product of (1 − 2/(k(k+1))) for k from 2 to n equals (n+2)/(3n)
      absence: no-local-match · triviality: non-trivial · intended: Induction; rewrite 1 − 2/(k(k+1)) = (k−1)(k+2)/(k(k+1)) and telescope both linear chains, field_simp + ring · conf: high
- [ ] `prod_icc_one_add_recip_pronic` — The product of (1 + 1/(k²+2k)) for k from 1 to n equals 2(n+1)/(n+2)
      absence: no-local-match · triviality: non-trivial · intended: Induction; rewrite 1 + 1/(k²+2k) = (k+1)²/(k(k+2)) and telescope, field_simp + ring · conf: high
- [ ] `prod_range_one_sub_recip_succ_sq` — The product of (1 − 1/(k+1)²) for k from 1 to n equals (n+2)/(2(n+1))
      absence: no-local-match · triviality: non-trivial · intended: Induction; rewrite 1 − 1/(k+1)² = k(k+2)/(k+1)² and telescope, field_simp + ring · conf: high
- [ ] `prod_icc_one_sub_recip_triangular` — The product of (1 − 1/C(k+1,2)) (one minus reciprocal triangular number) for k from 2 to n equals (n+2)/(3n)
      absence: no-local-match · triviality: non-trivial · intended: Rewrite Nat.choose (k+1) 2 = k(k+1)/2 (Nat.choose_two_right), reduce to the pronic product and telescope by induction · conf: med
- [ ] `sum_range_cube_diff_eq_cube` — The sum of (3k²+3k+1) for k from 0 to n-1 equals n³
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; the per-term is (k+1)³−k³, close with ring · conf: high
- [ ] `sum_range_four_cube_diff_eq` — The sum of (4k³+6k²+4k+1) for k from 0 to n-1 equals n⁴
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; per-term is (k+1)⁴−k⁴, close with ring · conf: high
- [ ] `sum_range_k_mul_two_pow_eq` — The sum of k·2^k for k from 0 to n-1 equals (n−2)·2ⁿ + 2
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; handle Nat subtraction by stating over ℤ or proving 2 ≤ result; ring_nf after expanding 2^(n+1) · conf: high
- [ ] `sum_range_recip_fib_prod_consecutive` — The sum of 1/(F(k+2)·F(k+3)) for k from 0 to n-1 equals F(n+1)/F(n+2), where F is Fibonacci
      absence: no-local-match · triviality: non-trivial · intended: Induction using the Fibonacci recurrence and fib positivity; combine fractions with field_simp and apply fib_add_two · conf: med
- [ ] `sum_range_recip_four_step_product` — The sum of 1/((4k+1)(4k+5)) for k from 0 to n-1 equals n/(4n+1)
      absence: no-local-match · triviality: non-trivial · intended: Induction; per-term ¼[1/(4k+1) − 1/(4k+5)], field_simp then ring · conf: high
- [ ] `sum_range_two_k_add_three_div_prod_sq` — The sum of (2k+1)/((k+1)²(k+2)) for k from 0 to n-1 telescopes to 1 − (n+1)/((n+1)(n+2))
      absence: no-local-match · triviality: non-trivial · intended: Induction; per-term decomposes as a difference of 1/(k+1) and (k+1)/((k+1)(k+2)) style terms, field_simp + ring · conf: high
- [ ] `prod_icc_one_sub_recip_sq_eq_frac` — The product of (k²−1)/k² for k from 2 to n equals (n+1)/(2n)
      absence: no-local-match · triviality: non-trivial · intended: Induction; factor k²−1 = (k−1)(k+1) and telescope the two linear chains, field_simp + ring · conf: high
- [ ] `sum_range_recip_five_step_product` — The sum of 1/((5k+2)(5k+7)) for k from 0 to n-1 equals n/(2(5n+2))
      absence: no-local-match · triviality: non-trivial · intended: Induction; per-term ⅕[1/(5k+2) − 1/(5k+7)], field_simp then ring · conf: high
- [ ] `prod_icc_one_add_recip_eq_succ` — The product of (2k+1)/(2k−1) for k from 1 to n equals 2n+1
      absence: no-local-match · triviality: non-trivial · intended: Induction from n=1; the numerator/denominator chain telescopes leaving the final numerator 2n+1, field_simp + ring · conf: high
- [ ] `sum_range_recip_prod_step_three_offset` — The sum of 3/((k+1)(k+4)) for k from 0 to n-1 equals (1+½+⅓) minus (1/(n+1)+1/(n+2)+1/(n+3))
      absence: no-local-match · triviality: non-trivial · intended: Induction; per-term 3/((k+1)(k+4)) = 1/(k+1) − 1/(k+4), a three-step telescope, field_simp + ring on the residual · conf: med
