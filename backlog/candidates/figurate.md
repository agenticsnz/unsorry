# Figurate-number closed forms — candidate backlog (Identity Engine)

Theme staging file for the Identity Engine (#400, ADR-043). 24 vetted candidates — each **absence-clean** (no name/content match in pinned mathlib `c5ea00351c` or our goal set) and screened **non-trivial** (ADR-035 battery). The expensive gates (intended proof compiling under `lake env lean` + adversarial skeptic) run at promotion. Scoped 2026-06-15.

- [ ] `sum_centered_hexagonal_eq_cube` — The sum of the first n centered hexagonal numbers equals n cubed
      absence: no-local-match · triviality: non-trivial · intended: Induction on n with Finset.sum_range_succ, then ring · conf: high
- [ ] `sum_centered_cube_eq_biquadratic` — Twice the sum over k<n of k^3+(k+1)^3 equals n^2 times (n^2+1)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; ring closes the step · conf: high
- [ ] `sum_octahedral_centered_squares` — Three times the sum of the first n centered-square numbers is n times (2n^2+1), the octahedral closed form
      absence: no-local-match · triviality: non-trivial · intended: Induction on n; Finset.sum_range_succ then nlinarith handling Nat subtraction · conf: high
- [ ] `sum_odd_squares_faulhaber` — Three times the sum of the first n odd squares equals n(2n-1)(2n+1)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; nlinarith to close with the Nat subtraction · conf: high
- [ ] `sum_odd_cubes_eq_biquadratic` — The sum of the first n odd cubes equals n^2 times (2n^2-1)
      absence: no-local-match · triviality: non-trivial · intended: Induction on n; Finset.sum_range_succ then nlinarith for the (2n^2-1) Nat-subtraction step · conf: high
- [ ] `sum_star_numbers_closed_form` — The sum of the first n star numbers equals n times (2n^2-1)
      absence: no-local-match · triviality: non-trivial · intended: Induction; Finset.sum_range_succ then nlinarith over Nat subtraction terms · conf: high
- [ ] `sum_k_sq_mul_succ_closed_form` — Twelve times the sum of k^2(k+1) over k up to n equals n(n+1)(n+2)(3n+1)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; ring closes the step · conf: high
- [ ] `sum_quadruple_product_closed_form` — Five times the sum of four consecutive integer products equals the five-term product n through n+4
      absence: no-local-match · triviality: non-trivial · intended: Telescoping induction via Finset.sum_range_succ; ring · conf: high
- [ ] `sum_pentatope_triple_product` — Four times the sum of three consecutive integer products equals n(n+1)(n+2)(n+3), the pentatope closed form
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; ring · conf: high
- [ ] `sum_centered_triangular_closed_form` — The sum of the first n centered triangular numbers equals n times (n^2+1)
      absence: no-local-match · triviality: non-trivial · intended: Induction on n; Finset.sum_range_succ then nlinarith handling 3k^2-3k Nat subtraction · conf: high
- [ ] `sum_even_squares_faulhaber` — Three times the sum of the first n even squares equals 2n(n+1)(2n+1)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; ring · conf: high
- [ ] `sum_even_cubes_eq_twice_square` — The sum of the first n even cubes equals 2n^2(n+1)^2
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; ring · conf: high
- [ ] `sum_heptagonal_closed_form` — Six times the sum of the first n heptagonal-gnomon terms equals 2n(n+1)(5n-2)
      absence: no-local-match · triviality: non-trivial · intended: Induction on n; Finset.sum_range_succ then nlinarith over Nat subtractions · conf: high
- [ ] `sum_nonagonal_closed_form` — Three times the sum of the first n nonagonal-gnomon terms equals n(n+1)(7n-4)
      absence: no-local-match · triviality: non-trivial · intended: Induction on n; Finset.sum_range_succ then nlinarith over Nat subtractions · conf: high
- [ ] `sum_decagonal_closed_form` — Six times the sum of the first n decagonal numbers equals n(n+1)(8n-5)
      absence: no-local-match · triviality: non-trivial · intended: Induction on n; Finset.sum_range_succ then nlinarith over the Nat subtraction 4k-3 · conf: high
- [ ] `sum_hexagonal_numbers_closed_form` — Six times the sum of the first n hexagonal numbers equals n(n+1)(4n-1)
      absence: no-local-match · triviality: non-trivial · intended: Induction on n; Finset.sum_range_succ then nlinarith over the Nat subtraction 2k-1 · conf: high
- [ ] `sum_triangular_squared_closed_form` — Fifteen times the sum of squares of consecutive products k^2(k+1)^2 equals n(n+1)(n+2)(3n^2+6n+1)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; ring (no subtraction) · conf: high
- [ ] `sum_k_mul_succ_mul_two_k_succ` — Twice the sum of k(k+1)(2k+1) over k up to n equals n(n+1)^2(n+2)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; ring · conf: high
- [ ] `sum_k_mul_k_add_two_closed_form` — Six times the sum of k(k+2) over k up to n equals n(n+1)(2n+7)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; ring · conf: high
- [ ] `sum_odd_gnomon_squares_closed_form` — Twice the sum of (3k-2)^2 over k up to n equals n(6n^2-3n-1)
      absence: no-local-match · triviality: non-trivial · intended: Induction on n; Finset.sum_range_succ then nlinarith over the Nat subtractions · conf: high
- [ ] `sum_gnomon_cubes_eq_fourth_power` — The sum over k<n of the quartic gnomon 4k^3+6k^2+4k+1 equals n to the fourth
      absence: no-local-match · triviality: non-trivial · intended: Telescoping (k+1)^4-k^4 via Finset.sum_range_succ; ring · conf: high
- [ ] `sum_quintic_gnomon_eq_fifth_power` — The sum over k<n of the quintic gnomon equals n to the fifth
      absence: no-local-match · triviality: non-trivial · intended: Telescoping (k+1)^5-k^5 via Finset.sum_range_succ; ring · conf: high
- [ ] `sum_octahedral_numbers_closed_form` — Six times the sum of the first n octahedral numbers equals 3n(n+1)(n^2+n+1)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; ring · conf: high
- [ ] `sum_five_consecutive_product_closed_form` — Six times the sum of five consecutive integer products equals the six-term product n through n+5, the 5-simplex closed form
      absence: no-local-match · triviality: non-trivial · intended: Telescoping induction via Finset.sum_range_succ; ring · conf: high
