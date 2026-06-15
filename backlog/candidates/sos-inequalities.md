# Classical 2–3 variable SOS inequalities — candidate backlog (Identity Engine)

Theme staging file for the Identity Engine (#400, ADR-043). 20 vetted candidates — each **absence-clean** (no name/content match in pinned mathlib `c5ea00351c` or our goal set) and screened **non-trivial** (ADR-035 battery). The expensive gates (intended proof compiling under `lake env lean` + adversarial skeptic) run at promotion. Scoped 2026-06-15.

- [ ] `schur_inequality_deg_one` — Schur's inequality of degree one: the symmetric sum a(a-b)(a-c)+b(b-c)(b-a)+c(c-a)(c-b) is nonnegative for nonnegative reals
      absence: no-local-match · triviality: non-trivial · intended: WLOG-free nlinarith with sq_nonneg and mul_nonneg products of the (a-b),(b-c),(c-a) differences · conf: med
- [ ] `schur_deg_one_expanded` — Expanded Schur degree-one form: the sum of cubes plus 2abc dominates the cyclic sum ab(a+b)+bc(b+c)+ca(c+a)
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with sq_nonneg (a-b) etc. weighted by a,b,c via mul_nonneg · conf: med
- [ ] `ravi_amgm_product_le` — Under triangle-like nonnegativity of the Ravi substitutions, the product (a+b-c)(b+c-a)(c+a-b) is at most abc
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with sq_nonneg (a-b),(b-c),(c-a) and mul_nonneg of the hypotheses · conf: med
- [ ] `sum_recip_times_sum_ge_nine` — For positive reals, (a+b+c)(1/a+1/b+1/c) is at least 9 (Cauchy-Schwarz / AM-HM corollary)
      absence: no-local-match · triviality: non-trivial · intended: clear denominators via field_simp, then nlinarith with sq_nonneg of pairwise differences · conf: high
- [ ] `cyclic_square_times_ge_product_sum` — The product of the sum of squares and the pairwise-product sum dominates 3abc(a+b+c)
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with sq_nonneg combinations and mul_nonneg a,b,c times sq_nonneg differences · conf: med
- [ ] `cyclic_quad_ge_abc_times_sum` — The sum of squared pairwise products dominates abc(a+b+c) for all reals
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with sq_nonneg (a*b - b*c), sq_nonneg (b*c - c*a), sq_nonneg (c*a - a*b) · conf: high
- [ ] `power_mean_cube_three_var` — For nonnegative reals, the cube of the sum is at most nine times the sum of cubes
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with mul_nonneg of a,b,c against sq_nonneg of pairwise differences · conf: med
- [ ] `sum_sq_ge_third_sq_sum` — The mean-square form: one third of the squared sum is at most the sum of squares (QM-AM in fractional form)
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with sq_nonneg (a-b), sq_nonneg (b-c), sq_nonneg (c-a) · conf: high
- [ ] `amgm_four_cross_three_var` — The sum of fourth powers dominates the sum of squared pairwise products
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with sq_nonneg (a^2 - b^2), sq_nonneg (b^2 - c^2), sq_nonneg (c^2 - a^2) · conf: high
- [ ] `tangent_line_cube_trick` — The tangent-line bound at x=1 for the cube: 3x is at most x cubed plus two for nonnegative x
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with sq_nonneg (x-1) and mul_nonneg hx (sq_nonneg (x-1)) to capture the (x-1)^2(x+2) factorisation · conf: high
- [ ] `amgm_prod_half_sum_le_cubes` — Twice ab(a+b) is at most twice the sum of cubes for nonnegative reals
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with mul_nonneg ha hb and mul_nonneg (add_nonneg ha hb) (sq_nonneg (a-b)) · conf: high
- [ ] `two_var_quartic_mixed_sos` — A mixed quartic SOS bound: 6a^2b^2 is dominated by a^4+b^4 plus twice the mixed cubic cross terms
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with sq_nonneg (a-b), sq_nonneg (a+b), and sq_nonneg (a^2 - b^2) · conf: med
- [ ] `sos_weighted_three_one_two` — A weighted AM-GM cubic: 3a^2b is at most 2a^3 plus 2b^3 for nonnegative reals
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with mul_nonneg and sq_nonneg (a-b) scaled by nonneg a and b · conf: high
- [ ] `amgm_ratio_cycle_ge_three` — For positive reals the cyclic ratio sum a/b+b/c+c/a is at least three
      absence: no-local-match · triviality: non-trivial · intended: field_simp to clear denominators, then nlinarith with sq_nonneg differences and product positivity · conf: med
- [ ] `sum_sq_over_cycle_ge_sum` — The cyclic Engel-form sum a^2/b+b^2/c+c^2/a is at least a+b+c for positive reals
      absence: no-local-match · triviality: non-trivial · intended: field_simp then nlinarith with sq_nonneg (a-b),(b-c),(c-a) times positive denominators · conf: med
- [ ] `pairwise_product_sum_sq_ge_three_abc_sum` — The square of the pairwise-product sum dominates 3abc(a+b+c)
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with sq_nonneg (a*b - b*c), sq_nonneg (b*c - c*a), sq_nonneg (c*a - a*b) · conf: high
- [ ] `cyclic_cube_cross_le_quartic_sum` — For nonnegative reals the cyclic cubic-cross sum is dominated by the sum of fourth powers
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with sq_nonneg (a^2 - a*b) style hints plus sq_nonneg of differences scaled by nonneg vars · conf: med
- [ ] `cyclic_square_cross_le_cube_sum` — For nonnegative reals the cyclic squared-cross sum is at most the sum of cubes
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with mul_nonneg ha (sq_nonneg (a-b)) and the two cyclic analogues · conf: med
- [ ] `shifted_sum_sq_ge_twice_sum_three_var` — Each variable's square plus one dominates twice the variable, summed over three variables
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with sq_nonneg (a-1), sq_nonneg (b-1), sq_nonneg (c-1) · conf: high
- [ ] `amgm_prod_le_cube_of_third_sum` — The three-variable AM-GM in cube form: 27abc is at most the cube of the sum for nonnegative reals
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with mul_nonneg products of a,b,c against sq_nonneg pairwise differences (Schur-assisted SOS) · conf: med
