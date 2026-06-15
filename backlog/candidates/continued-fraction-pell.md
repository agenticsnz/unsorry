# Continued-fraction / Pell-equation facts — candidate backlog (Identity Engine)

Theme staging file for the Identity Engine (#400, ADR-043). 24 vetted candidates — each **absence-clean** (no name/content match in pinned mathlib `c5ea00351c` or our goal set) and screened **non-trivial** (ADR-035 battery). The expensive gates (intended proof compiling under `lake env lean` + adversarial skeptic) run at promotion. Scoped 2026-06-15.

- [ ] `pell_d2_ladder_step_preserves` — Applying the fundamental Pell ladder map (x,y) ↦ (3x+4y, 2x+3y) to any solution of x²−2y²=1 yields another solution
      absence: no-local-match · triviality: non-trivial · intended: linear_combination using the hypothesis after ring-normalising the expanded square · conf: high
- [ ] `pell_d3_ladder_step_preserves` — The d=3 fundamental ladder map (x,y) ↦ (2x+3y, x+2y) sends each solution of x²−3y²=1 to another solution
      absence: no-local-match · triviality: non-trivial · intended: linear_combination h; ring closes the residual · conf: high
- [ ] `pell_d5_ladder_step_preserves` — The d=5 fundamental ladder map (x,y) ↦ (9x+20y, 4x+9y) preserves the Pell relation x²−5y²=1
      absence: no-local-match · triviality: non-trivial · intended: linear_combination h after expanding the two squares · conf: high
- [ ] `pell_d2_negative_to_positive_step` — One half-step (x,y) ↦ (x+2y, x+y) turns a solution of the negative Pell equation x²−2y²=−1 into a solution of x²−2y²=1
      absence: no-local-match · triviality: non-trivial · intended: the map negates the form value: linear_combination -h · conf: high
- [ ] `pell_d2_positive_to_negative_step` — The same half-step (x,y) ↦ (x+2y, x+y) sends a solution of x²−2y²=1 to a solution of the negative Pell equation x²−2y²=−1
      absence: no-local-match · triviality: non-trivial · intended: linear_combination -h; ring residual vanishes · conf: high
- [ ] `pell_brahmagupta_composition_d2` — Brahmagupta composition: multiplying two solutions of x²−2y²=1 via (ac+2be, ae+bc) gives another solution
      absence: no-local-match · triviality: non-trivial · intended: nlinarith [h1, h2] or linear_combination c^2*h1 + ... ; the product of the two relations equals the goal LHS · conf: high
- [ ] `pell_brahmagupta_composition_generic_d` — For every parameter d, the Brahmagupta product (ac+dbe, ae+bc) composes two solutions of x²−dy²=1 into a third
      absence: no-local-match · triviality: non-trivial · intended: show LHS = (a²−d·b²)(c²−d·e²) by ring, then rewrite both hypotheses via linear_combination · conf: high
- [ ] `pell_doubling_identity_generic_d` — Squaring a fundamental-type solution via (a²+db², 2ab) again solves x²−dy²=1, for any d
      absence: no-local-match · triviality: non-trivial · intended: LHS = (a²−d·b²)² as a ring identity; substitute h so it becomes 1² = 1 via linear_combination · conf: high
- [ ] `pell_d2_convergent_cross_difference` — Consecutive √2-convergents produced by the ladder satisfy the determinant relation p_{n+1}q_n − p_n q_{n+1} = −1
      absence: no-local-match · triviality: non-trivial · intended: expand and reduce the cross product to −(p²−2q²) then apply h · conf: high
- [ ] `pell_d2_x_odd` — In every integer solution of x²−2y²=1 the x-coordinate is odd
      absence: no-local-match · triviality: non-trivial · intended: x² = 1 + 2y² is odd, so x is odd; via Int.odd_iff and parity of squares (omega after Int.emod reasoning) · conf: high
- [ ] `pell_d2_y_even` — The product xy of any integer solution of x²−2y²=1 is even
      absence: no-local-match · triviality: non-trivial · intended: x is odd; if y odd then x²−2y² ≡ 1−2 ≡ 3 (mod 4) contradicting =1, so y even, hence xy even — ZMod 4 / decide bridge · conf: high
- [ ] `pell_d3_x_coord_pos_gt_y` — Any positive solution of x²−3y²=1 has y strictly less than x
      absence: no-local-match · triviality: non-trivial · intended: from x² = 1 + 3y² > y², deduce x > y by nlinarith [sq_nonneg (x - y)] · conf: high
- [ ] `pell_d2_rational_bound_above` — Every positive Pell solution of x²−2y²=1 makes x/y exceed √2, i.e. 2y² < x²
      absence: no-local-match · triviality: non-trivial · intended: x² = 2y² + 1 > 2y²; linarith after rewriting h, but with the strict gap it needs nlinarith on positivity · conf: high
- [ ] `pell_d2_rational_bound_gap` — The √2-approximation gap is controlled: for a solution of x²−2y²=1 one has x²−2y² ≤ y²+1
      absence: no-local-match · triviality: non-trivial · intended: rewrite h to get 1 ≤ y²+1; nlinarith [sq_nonneg y] · conf: high
- [ ] `pell_numbers_determinant_identity` — The Pell numbers (Pₙ₊₂ = 2Pₙ₊₁ + Pₙ) satisfy the Cassini-type identity Pₙ₊₁² − Pₙ₊₂·Pₙ = (−1)ⁿ
      absence: no-local-match · triviality: non-trivial · intended: induction on n using hrec; the step expands and folds back to the previous case (linear_combination) · conf: med
- [ ] `pell_numbers_half_companion_relation` — The Pell numbers Pₙ and half-companion Pell numbers Qₙ (both with the 2x+previous recurrence) satisfy Qₙ²−2Pₙ² = (−1)ⁿ
      absence: no-local-match · triviality: non-trivial · intended: strong/two-step induction tracking both sequences; combine hPrec and hQrec at the step with linear_combination · conf: med
- [ ] `pell_numbers_adjacent_sum_companion` — The half-companion Pell numbers are recovered from adjacent Pell numbers via Qₙ = Pₙ₊₁ (stated as Pₙ + Pₙ₊₁ − Pₙ)
      absence: no-local-match · triviality: non-trivial · intended: reduces to Qₙ = Pₙ₊₁; prove by two-step induction matching base cases and the shared recurrence · conf: med
- [ ] `square_triangular_recurrence_step` — The square-triangular recurrence (m,k) ↦ (3m+2k+1, 6k+8m+2) maps one square triangular number to the next
      absence: no-local-match · triviality: non-trivial · intended: clear the /2 using hk, reduce to a polynomial identity in m,k, then linear_combination with h · conf: med
- [ ] `square_triangular_pell_link` — A square triangular number m²=T_k is equivalent to the Pell solution (2k+1)²−8m²=1, linking T_k to x²−8y²=1
      absence: no-local-match · triviality: non-trivial · intended: linear_combination h; pure rearrangement of the hypothesis · conf: high
- [ ] `pell_d2_no_small_nontrivial_y` — There is no solution of x²−2y²=1 with y=1; the smallest positive y is 2 (the fundamental solution)
      absence: no-local-match · triviality: non-trivial · intended: rule out y=1 (would force x²=3, impossible) via interval_cases/nlinarith, otherwise y≥2 · conf: high
- [ ] `pell_d3_no_small_nontrivial_y` — Every positive solution of x²−3y²=1 has y≥1 and x≥2 (the fundamental solution (2,1) is minimal)
      absence: no-local-match · triviality: non-trivial · intended: x²=1+3y²≥4 so x≥2 by nlinarith [sq_nonneg x]; y≥1 from hy on integers · conf: high
- [ ] `pell_d7_ladder_step_preserves` — The d=7 fundamental ladder map (x,y) ↦ (8x+21y, 3x+8y), from the solution (8,3), preserves x²−7y²=1
      absence: no-local-match · triviality: non-trivial · intended: linear_combination h after expanding both squares · conf: high
- [ ] `pell_d6_ladder_step_preserves` — The d=6 fundamental ladder map (x,y) ↦ (5x+12y, 2x+5y), from the solution (5,2), preserves x²−6y²=1
      absence: no-local-match · triviality: non-trivial · intended: linear_combination h; ring closes the remainder · conf: high
- [ ] `pell_d13_ladder_step_preserves` — The d=13 fundamental ladder map (x,y) ↦ (649x+2340y, 180x+649y), from the large fundamental solution (649,180), preserves x²−13y²=1
      absence: no-local-match · triviality: non-trivial · intended: linear_combination h; the large coefficients make this real work but ring-mechanical after substitution · conf: high
