# Binomial / central-binomial identities — candidate backlog (Identity Engine)

Theme staging file for the Identity Engine (#400, ADR-043). 20 vetted candidates — each **absence-clean** (no name/content match in pinned mathlib `c5ea00351c` or our goal set) and screened **non-trivial** (ADR-035 battery). The expensive gates (intended proof compiling under `lake env lean` + adversarial skeptic) run at promotion. Scoped 2026-06-15.

- [ ] `sum_range_fall_three_mul_choose` — The sum over k of the third falling factorial of k times C(n,k), scaled by 8, equals n(n-1)(n-2) times 2^n
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ plus Nat.succ_mul_choose_eq absorption; companion to the existing degree-2 falling goal · conf: med
- [ ] `sum_range_k_plus_one_mul_choose` — Twice the sum of (k+1)·C(n,k) over k equals (n+2)·2^n
      absence: no-local-match · triviality: non-trivial · intended: Split (k+1)·C(n,k) into k·C(n,k)+C(n,k) and use sum_range_mul_choose and sum_range_choose · conf: high
- [ ] `sum_range_shifted_choose_eq_two_pow_sub_one` — The sum of the shifted binomial coefficients C(n+1,k+1) for k from 0 to n equals 2^(n+1) minus 1
      absence: no-local-match · triviality: non-trivial · intended: Reindex against sum_range_choose for n+1, peeling off the C(n+1,0)=1 term · conf: high
- [ ] `alternating_sum_k_mul_choose_eq_zero` — For n at least 2 the alternating sum of k·C(n,k) over k is zero
      absence: no-local-match · triviality: non-trivial · intended: Rewrite k·C(n,k)=n·C(n-1,k-1), factor out n, reindex, then apply Int.alternating_sum_range_choose · conf: med
- [ ] `sum_range_adjacent_choose_prod_eq_central_shift` — The sum over k of C(n,k)·C(n,k+1) equals the off-center binomial coefficient C(2n,n-1)
      absence: no-local-match · triviality: non-trivial · intended: Vandermonde slice: pair C(n,k) with C(n,n-1-k) via choose_symm and apply add_choose_eq · conf: med
- [ ] `sum_range_k_mul_choose_sq_eq_central` — The sum of k·C(n,k)^2 equals n times the binomial coefficient C(2n-1,n-1)
      absence: no-local-match · triviality: non-trivial · intended: Absorb k via n·C(n-1,k-1)·C(n,k), then a Vandermonde convolution; not a single battery tactic · conf: med
- [ ] `succ_mul_central_binom_succ_eq` — The central binomial recurrence: (n+1)·C(2n+2,n+1) equals (4n+2)·C(2n,n)
      absence: no-local-match · triviality: non-trivial · intended: Derive from Nat.succ_mul_centralBinom_succ together with centralBinom_eq_two_mul_choose · conf: high
- [ ] `sum_range_k_sq_mul_choose_sq_eq_central` — The sum of k^2·C(n,k)^2 equals n^2 times the binomial coefficient C(2n-2,n-1)
      absence: no-local-match · triviality: non-trivial · intended: Double absorption k·C(n,k)=n·C(n-1,k-1) on both squared factors, then Vandermonde convolution · conf: med
- [ ] `sum_vandermonde_slice_three_five` — A Vandermonde slice: the convolution of row 3 with row n at total index 5 equals C(n+3,5)
      absence: no-local-match · triviality: non-trivial · intended: Specialize Nat.add_choose_eq (Vandermonde) at m=3, total=5; the fixed small index keeps it non-decidable over n · conf: high
- [ ] `sum_range_central_binom_convolution_eq_four_pow` — The self-convolution of central binomial coefficients summed to n equals 4^n
      absence: no-local-match · triviality: non-trivial · intended: Generating-function identity (Σ C(2k,k)x^k = 1/√(1-4x)); prove by strong induction or a Catalan/centralBinom recurrence · conf: med
- [ ] `alternating_sum_shifted_choose_eq_one` — The alternating sum of the shifted binomial coefficients C(n+1,k+1) equals 1
      absence: no-local-match · triviality: non-trivial · intended: Reindex into the full alternating row sum for n+1 (which is 0), isolating the missing k=0 term via Int.alternating_sum_range_choose · conf: med
- [ ] `sum_range_choose_mul_three_pow_eq_four_pow` — The sum of C(n,k)·3^k over k equals 4^n
      absence: no-local-match · triviality: non-trivial · intended: Binomial theorem (1+3)^n via Nat.sum_range_choose-style add_pow with x=1, y=3; needs the theorem, not pure ring · conf: high
- [ ] `alternating_sum_choose_mul_two_pow_eq_neg_one_pow` — The alternating sum of C(n,k)·2^k equals (-1)^n
      absence: no-local-match · triviality: non-trivial · intended: Binomial theorem (1-2)^n = (-1)^n via Int sub_pow / add_pow expansion · conf: high
- [ ] `sum_range_choose_mul_k_mul_comp_eq` — Four times the sum of C(n,k)·k·(n-k) equals n(n-1)·2^n
      absence: no-local-match · triviality: non-trivial · intended: Absorb both factors via k·C(n,k)=n·C(n-1,k-1) and symmetry, reducing to sum_range_choose; relates to variance of the binomial · conf: med
- [ ] `sum_range_choose_mul_choose_three_eq` — Eight times the subset-of-a-subset sum of C(n,k)·C(k,3) equals C(n,3)·2^n
      absence: no-local-match · triviality: non-trivial · intended: Subset-of-subset identity C(n,k)C(k,3)=C(n,3)C(n-3,k-3), factor out C(n,3), then sum the shifted row to 2^(n-3) · conf: med
- [ ] `sum_range_even_cols_eq_two_pow` — The sum of the even-indexed entries of row 2n of Pascal's triangle equals 2^(2n-1)
      absence: no-local-match · triviality: non-trivial · intended: Average the full row sum 2^(2n) with the alternating row sum 0 (parity split), via Int.alternating_sum_range_choose · conf: med
- [ ] `sum_range_odd_row_half_eq_four_pow` — The sum of the first n+1 entries of the odd row 2n+1 of Pascal's triangle equals 4^n
      absence: no-local-match · triviality: non-trivial · intended: Symmetry choose_symm pairs the lower half with the upper half of an odd-length row whose total is 2^(2n+1) · conf: high
- [ ] `sum_range_cube_sym_choose_sq_eq_zero` — The sum of (n-2k)^3·C(n,k)^2 over k vanishes by the antisymmetry k to n-k
      absence: no-local-match · triviality: non-trivial · intended: Reflection involution k to n-k sends the summand to its negation (odd power times symmetric square); use Finset.sum_involution / sum_range_reflect · conf: med
- [ ] `sum_range_pascal_diagonal_eq_choose` — The hockey-stick along a Pascal diagonal: the sum of C(m+k,k) for k from 0 to n equals C(m+n+1,n)
      absence: no-local-match · triviality: non-trivial · intended: Induction on n with Finset.sum_range_succ and Nat.succ_sub_one / choose_succ_succ Pascal step; a parallel-diagonal hockey-stick distinct from the Icc form · conf: high
- [ ] `sum_range_sq_sym_choose_sq_eq_central` — The sum of (n-2k)^2·C(n,k)^2 equals 2n times the binomial coefficient C(2n-2,n-1)
      absence: no-local-match · triviality: non-trivial · intended: Expand (n-2k)^2 and combine sum_range_choose_sq with the k and k^2 weighted convolutions; an SOS-style reduction to Vandermonde · conf: med
