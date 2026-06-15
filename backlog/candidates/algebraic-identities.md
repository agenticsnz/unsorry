# Polynomial / algebraic identities — candidate backlog (Identity Engine)

Theme staging file for the Identity Engine (#400, ADR-043). 20 vetted candidates — each **absence-clean** (no name/content match in pinned mathlib `c5ea00351c` or our goal set) and screened **non-trivial** (ADR-035 battery). The expensive gates (intended proof compiling under `lake env lean` + adversarial skeptic) run at promotion. Scoped 2026-06-15.

- [ ] `three_cubes_minus_three_prod_dvd_sum` — The sum a+b+c divides the symmetric expression a cubed plus b cubed plus c cubed minus three times abc
      absence: no-local-match · triviality: non-trivial · intended: Provide the cofactor a^2+b^2+c^2-ab-bc-ca as a Dvd witness, then close with ring · conf: high
- [ ] `diff_fifth_power_dvd_by_diff` — The difference a minus b divides the difference of fifth powers a^5 minus b^5
      absence: no-local-match · triviality: non-trivial · intended: Exhibit a^4+a^3 b+a^2 b^2+a b^3+b^4 as the explicit Dvd witness and discharge with ring · conf: high
- [ ] `sum_cubes_dvd_by_sum` — The sum a plus b divides the sum of cubes a^3 plus b^3
      absence: no-local-match · triviality: non-trivial · intended: Use the witness a^2-a*b+b^2 via Dvd.intro and finish with ring · conf: high
- [ ] `succ_dvd_n_cubed_add_one` — For every integer n, n+1 divides n^3 + 1
      absence: no-local-match · triviality: non-trivial · intended: Witness n^2-n+1 by Dvd.intro and close with ring · conf: high
- [ ] `three_dvd_n_cubed_add_two_n` — Three always divides n cubed plus twice n
      absence: no-local-match · triviality: non-trivial · intended: Decide over ZMod 3 (Int.emod_emod_of_dvd / Decidable.decide on the residue), or induct splitting n into residues · conf: high
- [ ] `quartic_n4_plus_four_dvd_by_shift_quadratic` — The quadratic n^2-2n+2 divides n^4+4, the Sophie Germain factorisation at b equal to one
      absence: no-local-match · triviality: non-trivial · intended: Provide the conjugate factor n^2+2*n+2 as the Dvd witness and verify with ring · conf: high
- [ ] `aurifeuillian_sextic_x6_plus_27_dvd` — The quadratic x^2+3 divides x^6+27, the sum-of-cubes factorisation of (x^2)^3 + 3^3
      absence: no-local-match · triviality: non-trivial · intended: Sum-of-cubes: witness x^4-3*x^2+9 by Dvd.intro, then ring · conf: high
- [ ] `sum_sq_dvd_diff_sixth_power` — The sum of squares a^2+b^2 divides the sum of sixth powers a^6+b^6
      absence: no-local-match · triviality: non-trivial · intended: Sum-of-cubes on (a^2)^3+(b^2)^3: witness a^4-a^2 b^2+b^4 then ring · conf: high
- [ ] `diff_seventh_power_dvd_by_diff` — The difference a minus b divides the difference of seventh powers a^7 minus b^7
      absence: no-local-match · triviality: non-trivial · intended: Geometric-series witness a^6+a^5 b+...+b^6 via Dvd.intro, close with ring · conf: high
- [ ] `sophie_germain_quartic_not_prime` — For n at least 2 and m at least 1 the Sophie Germain form n^4+4m^4 is never prime
      absence: no-local-match · triviality: non-trivial · intended: Sophie Germain factorisation into (n^2-2nm+2m^2)(n^2+2nm+2m^2); show smaller factor exceeds 1 then apply Nat.Prime.eq_one_of_dvd / not_prime_mul · conf: med
- [ ] `sextic_x6_plus_27_not_prime` — For integer x at least 2 the value x^6+27 is composite
      absence: no-local-match · triviality: non-trivial · intended: Factor as (x^2+3)(x^4-3x^2+9); bound both factors above 1 and use Int.Prime / not-prime-of-mul with nlinarith bounds · conf: med
- [ ] `quartic_n4_plus_four_not_prime` — For n at least 2 the value n^4+4 is composite (special case of the Sophie Germain identity)
      absence: no-local-match · triviality: non-trivial · intended: Factor n^4+4 = (n^2-2n+2)(n^2+2n+2); show 1 < n^2-2n+2 by nlinarith then not_prime_mul · conf: high
- [ ] `nicomachus_sum_cubes_eq_sum_id_sq` — The sum of the first n cubes equals the square of the sum of the first n naturals (Nicomachus's theorem)
      absence: no-local-match · triviality: non-trivial · intended: Induction on n with Finset.sum_range_succ; rewrite the inner triangular sum via Gauss and close with ring · conf: high
- [ ] `sum_range_k_mul_factorial_succ` — One plus the sum of k times k-factorial over k below n equals n-factorial
      absence: no-local-match · triviality: non-trivial · intended: Induction on n using Finset.sum_range_succ and Nat.factorial_succ; finish with ring/omega on the factorial step · conf: high
- [ ] `faulhaber_sum_range_pow_four_closed` — Thirty times the sum of fourth powers below n equals the closed Faulhaber polynomial n(n-1)(2n-1)(3n^2-3n-1)
      absence: no-local-match · triviality: non-trivial · intended: Induction with Finset.sum_range_succ; clear the factor 30, then ring (cast to ℤ if Nat subtraction bites) · conf: med
- [ ] `schur_degree_one_nonneg` — Schur's degree-one inequality: the cyclic sum a(a-b)(a-c)+... is nonnegative for nonnegative reals
      absence: no-local-match · triviality: non-trivial · intended: WLOG order a≥b≥c then nlinarith with products of (a-b),(b-c),(a-c) and the nonnegativity hypotheses as hints · conf: med
- [ ] `sum_fourth_powers_ge_cube_times_sum` — For nonnegative reals, a^3 b + a b^3 is at most a^4 + b^4
      absence: no-local-match · triviality: non-trivial · intended: nlinarith with sq_nonneg (a-b) and sq_nonneg (a+b) times sq_nonneg (a-b) as SOS hints · conf: high
- [ ] `diff_squares_prod_dvd_quartic_diff` — The difference of squares a^2-b^2 divides the difference of fourth powers a^4-b^4
      absence: no-local-match · triviality: non-trivial · intended: Witness a^2+b^2 via Dvd.intro and close with ring · conf: high
- [ ] `sum_fifth_powers_dvd_by_sum` — The sum a plus b divides the sum of fifth powers a^5 plus b^5
      absence: no-local-match · triviality: non-trivial · intended: Witness a^4-a^3 b+a^2 b^2-a b^3+b^4 via Dvd.intro, then ring · conf: high
- [ ] `n_pow_three_sub_n_dvd_by_six` — Six divides n cubed minus n for every integer n (product of three consecutive integers)
      absence: no-local-match · triviality: non-trivial · intended: Rewrite n^3-n = (n-1)*n*(n+1) and combine 2 ∣ and 3 ∣ via a ZMod 6 residue decide or consecutive-integer lemmas · conf: high
