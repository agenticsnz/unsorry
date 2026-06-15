# Partition / generating-function coefficient facts — candidate backlog (Identity Engine)

Theme staging file for the Identity Engine (#400, ADR-043). 18 vetted candidates — each **absence-clean** (no name/content match in pinned mathlib `c5ea00351c` or our goal set) and screened **non-trivial** (ADR-035 battery). The expensive gates (intended proof compiling under `lake env lean` + adversarial skeptic) run at promotion. Scoped 2026-06-15.

- [ ] `sum_range_choose_mul_fib_eq_fib_two_mul` — The binomial transform of the Fibonacci numbers gives every second Fibonacci number: the sum over k of C(n,k)·F(k) equals F(2n)
      absence: no-local-match · triviality: non-trivial · intended: Induction on n using Pascal's rule and fib_add / the doubling identity; or a generating-function/binomial-transform lemma · conf: med
- [ ] `sum_range_choose_mul_fib_succ_eq_fib` — The shifted binomial transform of the Fibonacci numbers gives the odd-index Fibonacci numbers: the sum over k of C(n,k)·F(k+1) equals F(2n+1)
      absence: no-local-match · triviality: non-trivial · intended: Induction on n with Pascal's rule, paired with the companion C(n,k)·F(k)=F(2n) identity and fib_add_two · conf: med
- [ ] `fib_sq_add_fib_succ_sq_eq_fib_two_mul_succ` — The sum of the squares of two consecutive Fibonacci numbers is the Fibonacci number of odd index 2n+1
      absence: no-local-match · triviality: non-trivial · intended: Specialise fib_add with m=n (so fib(2n+1)=fib n^2 + fib(n+1)^2), or induct with fib_add_two · conf: high
- [ ] `alt_sum_range_fib_eq_signed_fib_pred` — The alternating sum of the first n+1 Fibonacci numbers has the signed closed form (-1)^n·F(n+1) - F(n)
      absence: no-local-match · triviality: non-trivial · intended: Induction on n with Finset.sum_range_succ; collapse the step using fib_add_two and push_cast/ring over ℤ · conf: high
- [ ] `sum_range_choose_mul_four_pow_eq_five_pow` — Weighting the binomial coefficients of row n by powers of 4 sums to 5^n
      absence: no-local-match · triviality: non-trivial · intended: Instantiate the binomial theorem with 1 and 4, rewriting 1+4=5; the Finset sum is not closed by a single battery tactic · conf: high
- [ ] `sum_range_choose_mul_succ_eq_add_two_mul_two_pow` — Weighting row n of Pascal's triangle by (k+1) sums to (n+2)·2^(n-1)
      absence: no-local-match · triviality: non-trivial · intended: Split (k+1)·C(n,k) = k·C(n,k) + C(n,k), then use sum_range_mul_choose and Nat.sum_range_choose; handle n=0 separately · conf: high
- [ ] `alt_sum_range_k_mul_choose_eq_zero` — For row index at least two, the alternating sum of k·C(n,k) vanishes
      absence: no-local-match · triviality: non-trivial · intended: Use k·C(m,k)=m·C(m-1,k-1) to reduce to the alternating row sum Int.alternating_sum_range_choose, which is zero for m≥1 · conf: med
- [ ] `sum_range_choose_mul_choose_succ_eq_central` — Summing the products of horizontally adjacent entries in row n of Pascal's triangle gives the central-adjacent binomial coefficient C(2n, n+1)
      absence: no-local-match · triviality: non-trivial · intended: Vandermonde/Cauchy convolution: rewrite C(n,k+1)=C(n,n-1-k) and apply Nat.add_pow_le / choose_symm with Nat.choose_sum_pow style Vandermonde · conf: med
- [ ] `sum_range_k_mul_factorial_eq_factorial_succ_sub_one` — The sum of k·k! for k up to n telescopes to (n+1)! - 1
      absence: no-local-match · triviality: non-trivial · intended: Induction on n with Finset.sum_range_succ; the step uses k·k! = (k+1)! - k! and Nat.factorial_succ, watching Nat subtraction · conf: high
- [ ] `sum_range_two_k_add_one_mul_two_pow_closed` — The sum of (2k+1)·2^k for k up to n has the closed form (2n-1)·2^(n+1) + 3 over the integers
      absence: no-local-match · triviality: non-trivial · intended: Induction on n with Finset.sum_range_succ over ℤ; close each step with ring after push_cast · conf: high
- [ ] `sum_range_choose_div_succ_eq_two_pow_sub_one_div` — The sum of C(n,k)/(k+1) over a row equals (2^(n+1) - 1)/(n+1) as a rational
      absence: no-local-match · triviality: non-trivial · intended: Use C(n,k)/(k+1) = C(n+1,k+1)/(n+1) (succ_mul_choose_eq) to reindex into a partial row sum, then Nat.sum_range_choose over ℚ · conf: med
- [ ] `alt_sum_range_choose_sq_odd_eq_zero` — For an odd row, the alternating sum of the squares of the binomial coefficients vanishes
      absence: no-local-match · triviality: non-trivial · intended: Pair term k with term (m-k) using choose_symm and the parity of (-1)^k over an odd-length row; the involution cancels in pairs · conf: med
- [ ] `sum_range_recip_choose_two_eq_two_n_div_succ` — The sum of the reciprocals of the binomial coefficients C(k+2,2) telescopes to 2n/(n+1)
      absence: no-local-match · triviality: non-trivial · intended: Rewrite 1/C(k+2,2) = 2·(1/(k+1) - 1/(k+2)) and telescope via Finset.sum_range_succ over ℚ · conf: high
- [ ] `central_binom_eq_sum_range_choose_mul_choose` — The central binomial coefficient C(2n,n) is the Vandermonde self-convolution of row n of Pascal's triangle
      absence: no-local-match · triviality: non-trivial · intended: Apply Nat.add_pow_le-free Vandermonde (Nat.choose_symm to fold one factor, then the Cauchy/Vandermonde convolution identity) · conf: high
- [ ] `fib_two_mul_eq_fib_mul_two_mul_fib_succ_sub_fib` — The Fibonacci doubling identity in additive form: F(2n) + F(n)^2 equals F(n)·2F(n+1)
      absence: no-local-match · triviality: non-trivial · intended: Derive from fib_add with m=n minus one, i.e. F(2n)=F(n)(2F(n+1)-F(n)); rearrange over ℕ avoiding subtraction by moving F(n)^2 to the left · conf: high
- [ ] `sum_range_fib_mul_choose_two_eq` — A weighted Fibonacci partial sum: twice the sum of (k+1)·F(k) over a range equals (n+1)·F(n+2) - F(n+3) + 1
      absence: no-local-match · triviality: non-trivial · intended: Induction on n with Finset.sum_range_succ, combining the known sum F(k)=F(n+2)-1 with the index-weighted Abel summation; track Nat subtraction carefully · conf: med
- [ ] `sum_range_two_pow_mul_fib_succ_sub_fib` — A 2^k-weighted telescoping sum of consecutive Fibonacci differences collapses to 2^(n+1)·F(n+1) - 1
      absence: no-local-match · triviality: non-trivial · intended: Note F(k+2)-F(k)=F(k+1); then induct over ℤ with Finset.sum_range_succ, closing the step with fib_add_two and ring · conf: med
- [ ] `sum_range_catalan_mul_catalan_eq_catalan_succ` — The Catalan numbers satisfy the convolution recurrence: the self-convolution of the first n+1 Catalan numbers gives C(n+1)
      absence: no-local-match · triviality: non-trivial · intended: Rewrite catalan_succ (a Fin-indexed convolution) as a Finset.range sum via Fin.sum_univ_eq_sum_range and Nat.sub bookkeeping · conf: high
