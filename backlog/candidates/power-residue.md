# Power-residue / modular range facts — candidate backlog (Identity Engine)

Theme staging file for the Identity Engine (#400, ADR-043). 24 vetted candidates — each **absence-clean** (no name/content match in pinned mathlib `c5ea00351c` or our goal set) and screened **non-trivial** (ADR-035 battery). The expensive gates (intended proof compiling under `lake env lean` + adversarial skeptic) run at promotion. Scoped 2026-06-15.

- [ ] `sq_mod_eight_mem` — Every natural number's square leaves remainder 0, 1, or 4 when divided by 8
      absence: no-local-match · triviality: non-trivial · intended: omega-on (n % 8) after Nat.pow_mod, then decide over the 8 residues · conf: high
- [ ] `sq_mod_sixteen_mem` — Every natural number's square is congruent to 0, 1, 4, or 9 modulo 16
      absence: no-local-match · triviality: non-trivial · intended: rewrite n^2%16 via Nat.pow_mod, case-split on n%16 with decide/omega · conf: high
- [ ] `sq_mod_eleven_mem` — The quadratic residues modulo 11 are exactly {0,1,3,4,5,9}
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod then decide over residues 0..10 · conf: high
- [ ] `sq_mod_thirteen_mem` — The quadratic residues modulo 13 are exactly {0,1,3,4,9,10,12}
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod, case-split on n%13, decide each branch · conf: high
- [ ] `sq_mod_twelve_mem` — Every natural number's square is congruent to 0, 1, 4, or 9 modulo 12
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod then decide over the 12 residue classes · conf: high
- [ ] `sq_mod_twentyfour_mem` — The squares modulo 24 fall in exactly {0,1,4,9,12,16}
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod, case-split on n%24, decide each of 24 branches · conf: high
- [ ] `cube_mod_eighteen_mem` — The cubes modulo 18 are exactly {0,1,8,9,10,17}
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod then decide over residues 0..17 · conf: high
- [ ] `cube_mod_nineteen_mem` — The cubic residues modulo 19 are exactly {0,1,7,8,11,12,18}
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod, case-split on n%19, decide each branch · conf: high
- [ ] `fourth_power_mod_seventeen_mem` — The fourth-power residues modulo 17 are exactly {0,1,4,13,16}
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod then decide over residues 0..16 · conf: high
- [ ] `fourth_power_mod_twentynine_mem` — The fourth-power residues modulo 29 are exactly {0,1,7,16,20,23,24,25}
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod, case-split on n%29, decide each of 29 branches · conf: med
- [ ] `fourth_power_mod_sixteen_mem` — Every natural number's fourth power is congruent to 0 or 1 modulo 16
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod then decide over residues 0..15 (unconditional, unlike the Odd-only version) · conf: high
- [ ] `fifth_power_mod_twentyfive_mem` — The fifth-power residues modulo 25 are exactly {0,1,7,18,24}
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod, case-split on n%25, decide each branch · conf: high
- [ ] `fifth_power_mod_thirtyone_mem` — The fifth-power residues modulo 31 are exactly {0,1,5,6,25,26,30}
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod, case-split on n%31, decide each of 31 branches · conf: med
- [ ] `sixth_power_mod_thirteen_mem` — Every natural number's sixth power is congruent to 0, 1, or 12 modulo 13
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod then decide over residues 0..12 · conf: high
- [ ] `sixth_power_mod_nine_mem` — Every natural number's sixth power is congruent to 0 or 1 modulo 9
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod then decide over residues 0..8 · conf: high
- [ ] `seventh_power_mod_twentynine_mem` — The seventh-power residues modulo 29 are exactly {0,1,12,17,28}
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod, case-split on n%29, decide each of 29 branches · conf: med
- [ ] `eighth_power_mod_seventeen_mem` — Every natural number's eighth power is congruent to 0, 1, or 16 modulo 17
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod then decide over residues 0..16 · conf: high
- [ ] `sum_two_squares_zmod_four_ne_three` — A sum of two integer squares is never congruent to 3 modulo 4
      absence: no-local-match · triviality: non-trivial · intended: push casts to ZMod 4, then decide over the finite ZMod 4 × ZMod 4 cases · conf: high
- [ ] `sum_two_fourth_powers_zmod_sixteen_mem` — A sum of two integer fourth powers is congruent to 0, 1, or 2 modulo 16
      absence: no-local-match · triviality: non-trivial · intended: cast to ZMod 16, decide over ZMod 16 × ZMod 16 since each fourth power is 0 or 1 · conf: high
- [ ] `sum_three_squares_zmod_sixteen_ne_fifteen` — A sum of three integer squares is never congruent to 15 modulo 16
      absence: no-local-match · triviality: non-trivial · intended: cast to ZMod 16, decide over the finite cube of ZMod 16 · conf: high
- [ ] `sum_two_cubes_zmod_seven_mem` — A sum of two integer cubes is never congruent to 3 or 4 modulo 7
      absence: no-local-match · triviality: non-trivial · intended: cast to ZMod 7, decide over ZMod 7 × ZMod 7 (cubes hit only {0,1,6}) · conf: high
- [ ] `diff_two_squares_zmod_four_ne_two` — A difference of two integer squares is never congruent to 2 modulo 4
      absence: no-local-match · triviality: non-trivial · intended: cast to ZMod 4, decide over the finite ZMod 4 × ZMod 4 cases · conf: high
- [ ] `sq_mod_five_ne_two_three` — No natural number's square leaves remainder 2 or 3 when divided by 5
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod then decide over residues 0..4 to rule out both non-residues · conf: high
- [ ] `cube_mod_thirtyone_nonresidue_five` — None of 3, 5, 6, 7 is a cubic residue modulo 31
      absence: no-local-match · triviality: non-trivial · intended: Nat.pow_mod, case-split on n%31, decide to exclude the four named non-residues · conf: high
