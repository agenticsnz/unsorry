# Fibonacci / Lucas identities — candidate backlog (Identity Engine)

Theme staging file for the Identity Engine (#400, ADR-043). 20 vetted candidates — each **absence-clean** (no name/content match in pinned mathlib `c5ea00351c` or our goal set) and screened **non-trivial** (ADR-035 battery). The expensive gates (intended proof compiling under `lake env lean` + adversarial skeptic) run at promotion. Scoped 2026-06-15.

- [ ] `sum_range_fib_sq_eq_fib_mul_fib_succ` — The sum of the squares of the first n positive-index Fibonacci numbers equals the product of fib n and fib (n+1)
      absence: no-local-match · triviality: non-trivial · intended: Induction on n with Finset.sum_range_succ; step uses fib(n+1)^2 + fib(n)*fib(n+1) = fib(n+1)*fib(n+2) via fib_add_two and ring · conf: high
- [ ] `two_mul_sum_range_fib_triple_eq_fib_pred` — Twice the sum of fib at multiples of three up to 3n is one less than fib(3n-1)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; step needs fib(3n+2)=fib(3n-1)+2*fib(3n) (expand via fib_add_two repeatedly) plus an omega guard for the Nat subtraction · conf: med
- [ ] `sum_range_fib_two_mul_succ_eq_fib_pred` — The sum of the even-positive-index Fibonacci numbers fib 2, fib 4, ..., fib (2n) equals fib(2n+1) minus one
      absence: no-local-match · triviality: non-trivial · intended: Induction via Finset.sum_range_succ using fib(2n+1)+fib(2n+2)=fib(2n+3); omega discharges the truncated Nat subtraction (fib(2n+1) >= 1) · conf: high
- [ ] `fib_add_two_sq_sub_fib_sq_eq_fib_two_mul_add_two` — The difference of the squares fib(n+2)^2 - fib(n)^2 equals fib(2n+2)
      absence: no-local-match · triviality: non-trivial · intended: Rewrite via fib_add (fib(2n+2)=fib(n+1)(2fib n+fib(n+1))) and factor the difference of squares with fib(n+2)=fib(n+1)+fib n; ring after a Nat-subtraction guard · conf: high
- [ ] `fib_succ_sq_add_fib_add_two_sq_eq_fib_two_mul_add_three` — The sum of consecutive Fibonacci squares fib(n+1)^2 + fib(n+2)^2 equals fib(2n+3)
      absence: no-local-match · triviality: non-trivial · intended: Apply fib_two_mul_add_one at index n+1 (fib(2(n+1)+1)=fib(n+2)^2+fib(n+1)^2) and rewrite 2*n+3 = 2*(n+1)+1; ring · conf: high
- [ ] `fib_add_three_eq_two_mul_fib_succ_add_fib` — fib(n+3) equals twice fib(n+1) plus fib n
      absence: no-local-match · triviality: non-trivial · intended: Unfold fib(n+3) and fib(n+2) with fib_add_two twice, then ring/omega over fib n and fib(n+1) · conf: high
- [ ] `fib_add_four_eq_three_mul_fib_add_two_sub_fib` — fib(n+4) equals three times fib(n+2) minus fib n
      absence: no-local-match · triviality: non-trivial · intended: Expand fib(n+4),fib(n+3) via fib_add_two to express both sides in fib n, fib(n+1); discharge with omega (handles the Nat subtraction) · conf: high
- [ ] `fib_add_five_eq_five_mul_fib_succ_add_three_mul_fib` — fib(n+5) equals five times fib(n+1) plus three times fib n
      absence: no-local-match · triviality: non-trivial · intended: Repeatedly rewrite fib(n+k) down to fib n and fib(n+1) using fib_add_two, then omega · conf: high
- [ ] `fib_add_six_eq_eight_mul_fib_succ_add_five_mul_fib` — fib(n+6) equals eight times fib(n+1) plus five times fib n
      absence: no-local-match · triviality: non-trivial · intended: Telescope fib(n+6) down to fib n and fib(n+1) with six fib_add_two rewrites, then omega · conf: high
- [ ] `three_mul_fib_eq_fib_add_two_add_fib_sub_two` — Three times fib(n+2) equals fib(n+4) plus fib n
      absence: no-local-match · triviality: non-trivial · intended: Express fib(n+4),fib(n+2) via fib_add_two in terms of fib n, fib(n+1); omega closes it (shift avoids Nat subtraction) · conf: high
- [ ] `lucas_mul_fib_eq_fib_two_mul` — The Lucas number (fib(n+1)+fib(n-1)) times fib(n+1) expands as fib(2n+1) plus fib(n-1)*fib(n+1)
      absence: no-local-match · triviality: non-trivial · intended: Distribute the product, replace fib(n+1)^2 via fib_two_mul_add_one (fib(2n+1)=fib(n+1)^2+fib n^2) carefully, then ring; the n-1 stays symbolic so no case split needed beyond rewriting · conf: high
- [ ] `fib_succ_add_fib_add_three_eq_three_mul_fib_add_two` — fib(n+1) plus fib(n+3) equals three times fib(n+2): the Lucas-style sum of fib two apart
      absence: no-local-match · triviality: non-trivial · intended: Rewrite fib(n+3)=fib(n+1)+fib(n+2) and fib(n+2)=fib(n)+fib(n+1) with fib_add_two; omega · conf: high
- [ ] `fib_add_two_add_fib_eq_lucas_succ` — The Lucas number at n+1, written fib(n+2)+fib n, equals twice fib(n+1)
      absence: no-local-match · triviality: non-trivial · intended: fib(n+2)=fib n+fib(n+1) by fib_add_two, then omega/simp collapses both sides to 2*fib(n+1) · conf: high
- [ ] `cassini_nat_fib_int` — Over the integers, fib n times fib(n+2) minus fib(n+1) squared equals (-1)^(n+1) (a Cassini-form identity for Nat.fib)
      absence: no-local-match · triviality: non-trivial · intended: Induction on n: base by decide/norm_num; step rewrites fib(n+3)=fib(n+1)+fib(n+2) and fib(n+2)=fib n+fib(n+1) (cast fib_add_two), then ring_nf and use pow_succ on (-1) · conf: med
- [ ] `catalan_shift_nat_fib_int` — Over the integers, fib(n+1)*fib(n+3) minus fib(n+2) squared equals (-1)^n
      absence: no-local-match · triviality: non-trivial · intended: Reduce to the Cassini-form at shifted index via cassini_nat_fib_int, or induct directly using cast fib_add_two and (-1)^(n+1) bookkeeping with ring · conf: med
- [ ] `consecutive_fib_product_diff_nat_int` — Over the integers, fib n times fib(n+3) minus fib(n+1) times fib(n+2) equals (-1)^(n+1)
      absence: no-local-match · triviality: non-trivial · intended: Expand fib(n+3)=fib(n+1)+fib(n+2) and fib(n+2)=fib n+fib(n+1) (cast), reduce to Cassini fib n*fib(n+2)-fib(n+1)^2, then ring · conf: med
- [ ] `lucas_sq_sub_five_fib_sq_eq_four_neg_one_pow` — The Lucas number squared minus five times fib n squared equals 4*(-1)^n
      absence: no-local-match · triviality: non-trivial · intended: Cast to ℤ, expand the Lucas square, and reduce to Cassini (fib(n-1)*fib(n+1)-fib n^2 = (-1)^n) after rewriting fib(n+1)=fib n+fib(n-1); requires a Nat.fib n>=1 / index bridge and ring · conf: med
- [ ] `lucas_two_mul_eq_lucas_sq_sub_two_neg_one_pow` — The Lucas number at 2n equals the square of the Lucas number at n minus 2*(-1)^n
      absence: no-local-match · triviality: non-trivial · intended: Cast to ℤ, rewrite both Lucas numbers in fib, use fib_two_mul / fib_two_mul_add_one to express fib(2n±1) and reduce via Cassini for the (-1)^n term; ring · conf: med
- [ ] `lucas_succ_add_lucas_pred_eq_five_mul_fib` — The sum of the Lucas numbers at n+2 and n equals five times fib(n+1) (stated with a +1 index shift to keep terms in Nat)
      absence: no-local-match · triviality: non-trivial · intended: Rewrite fib(n+3)=fib(n+1)+fib(n+2), fib(n+2)=fib n+fib(n+1), and fib(n+1)=fib n+fib(n-1) via fib_add_two; omega collapses to 5*fib(n+1) · conf: high
- [ ] `fib_two_mul_eq_fib_mul_lucas` — fib(2(n+1)) equals fib(n+1) times the Lucas number (fib(n+2)+fib n), shifted to stay in Nat
      absence: no-local-match · triviality: non-trivial · intended: Use fib_two_mul_add_two (fib(2n+2)=fib(n+1)(2 fib n+fib(n+1))) and rewrite fib(n+2)+fib n = 2 fib n + fib(n+1) via fib_add_two; ring · conf: high
