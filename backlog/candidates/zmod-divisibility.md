# Divisibility via ZMod-decide — candidate backlog (Identity Engine)

Theme staging file for the Identity Engine (#400, ADR-043). 22 vetted candidates — each **absence-clean** (no name/content match in pinned mathlib `c5ea00351c` or our goal set) and screened **non-trivial** (ADR-035 battery). The expensive gates (intended proof compiling under `lake env lean` + adversarial skeptic) run at promotion. Scoped 2026-06-15.

- [ ] `dvd_504_pow_nine_sub_pow_three` — 504 divides n^9 minus n^3 for every integer n
      absence: no-local-match · triviality: non-trivial · intended: have ∀ x : ZMod 504, x^9 - x^3 = 0 by decide; transfer via ZMod.intCast_zmod_eq_zero_iff_dvd (build-verified) · conf: high
- [ ] `dvd_510_pow_seventeen_sub_self` — 510 divides n^17 minus n for every integer n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 510, x^17 - x = 0 by decide; ZMod.intCast_zmod_eq_zero_iff_dvd. 510 = 2·3·5·17 · conf: high
- [ ] `dvd_798_pow_nineteen_sub_self` — 798 divides n^19 minus n for every integer n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 798, x^19 - x = 0 by decide; transfer lemma. 798 = 2·3·7·19 · conf: high
- [ ] `dvd_330_pow_twentyone_sub_self` — 330 divides n^21 minus n for every integer n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 330, x^21 - x = 0 by decide; transfer lemma. 330 = 2·3·5·11 · conf: high
- [ ] `dvd_120_pow_eleven_sub_pow_three` — 120 divides n^11 minus n^3 for every integer n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 120, x^11 - x^3 = 0 by decide; transfer via intCast_zmod_eq_zero_iff_dvd · conf: high
- [ ] `dvd_480_pow_thirteen_sub_pow_five` — 480 divides n^13 minus n^5 for every integer n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 480, x^13 - x^5 = 0 by decide; transfer lemma. 480 = 2^5·3·5 · conf: high
- [ ] `dvd_120_pow_seven_sub_pow_three` — 120 divides n^7 minus n^3 for every integer n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 120, x^7 - x^3 = 0 by decide; transfer via intCast_zmod_eq_zero_iff_dvd · conf: high
- [ ] `dvd_240_pow_nine_sub_pow_five` — 240 divides n^9 minus n^5 for every integer n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 240, x^9 - x^5 = 0 by decide; transfer lemma. 240 = 2^4·3·5 · conf: high
- [ ] `dvd_252_pow_eight_sub_sq` — 252 divides n^8 minus n^2 for every integer n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 252, x^8 - x^2 = 0 by decide; transfer lemma. 252 = 2^2·3^2·7 · conf: high
- [ ] `dvd_240_pow_eight_sub_pow_four` — 240 divides n^8 minus n^4 for every integer n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 240, x^8 - x^4 = 0 by decide; transfer via intCast_zmod_eq_zero_iff_dvd · conf: high
- [ ] `dvd_sixty_pow_six_sub_sq` — 60 divides n^6 minus n^2 for every integer n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 60, x^6 - x^2 = 0 by decide; transfer lemma. 60 = 2^2·3·5 · conf: high
- [ ] `dvd_sixty_pow_ten_sub_sq` — 60 divides n^10 minus n^2 for every integer n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 60, x^10 - x^2 = 0 by decide; transfer via intCast_zmod_eq_zero_iff_dvd · conf: high
- [ ] `dvd_twentyfour_pow_seven_sub_pow_five` — 24 divides n^7 minus n^5 for every integer n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 24, x^7 - x^5 = 0 by decide; transfer lemma (small modulus, fast decide) · conf: high
- [ ] `dvd_twentyfour_pow_six_sub_pow_four` — 24 divides n^6 minus n^4 for every integer n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 24, x^6 - x^4 = 0 by decide; transfer via intCast_zmod_eq_zero_iff_dvd · conf: high
- [ ] `dvd_twentyfour_pow_five_sub_pow_three` — 24 divides n^5 minus n^3 for every integer n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 24, x^5 - x^3 = 0 by decide; transfer lemma · conf: high
- [ ] `dvd_5040_seven_consecutive_product` — 5040 (=7!) divides n·(n^2-1)·(n^2-4)·(n^2-9), the product of seven consecutive integers centred at n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 5040, x*(x^2-1)*(x^2-4)*(x^2-9)=0 by decide (needs set_option maxRecDepth 100000, build-verified); transfer lemma · conf: med
- [ ] `dvd_120_five_consecutive_product` — 120 (=5!) divides n·(n^2-1)·(n^2-4), the product of five consecutive integers centred at n
      absence: no-local-match · triviality: non-trivial · intended: ∀ x : ZMod 120, x*(x^2-1)*(x^2-4)=0 by decide; transfer via intCast_zmod_eq_zero_iff_dvd · conf: high
- [ ] `prime_pow_six_mod_504` — For every prime p greater than 7, p^6 is congruent to 1 modulo 504
      absence: no-local-match · triviality: non-trivial · intended: Reduce mod 504=8·9·7 via CRT/ZMod units; for p coprime to 504, p is a unit whose order divides 6 in each factor (decide over coprime residues of ZMod 504) · conf: med
- [ ] `prime_pow_eight_mod_480` — For every prime p greater than 5, p^8 is congruent to 1 modulo 480
      absence: no-local-match · triviality: non-trivial · intended: 480 = 32·3·5; for p coprime to 480 the residue's 8th power is 1 in each unit group; decide over coprime residues / ZMod CRT · conf: med
- [ ] `dvd_thirtytwo_odd_pow_eight_sub_one` — For every odd integer n, 32 divides n^8 minus 1
      absence: no-local-match · triviality: non-trivial · intended: obtain ⟨k,rfl⟩ from Odd; ∀ x : ZMod 32, (2*x+1)^8 - 1 = 0 by decide; transfer lemma (build-verified) · conf: high
- [ ] `dvd_sixteen_odd_pow_four_sub_one` — For every odd integer n, 16 divides n^4 minus 1
      absence: no-local-match · triviality: non-trivial · intended: obtain ⟨k,rfl⟩ from Odd; ∀ x : ZMod 16, (2*x+1)^4 - 1 = 0 by decide; transfer via intCast_zmod_eq_zero_iff_dvd · conf: high
- [ ] `dvd_fortyeight_coprime_six_pow_four_sub_one` — For every integer n divisible by neither 2 nor 3, 48 divides n^4 minus 1
      absence: no-local-match · triviality: non-trivial · intended: n coprime to 6 means its ZMod 48 residue is a unit; ∀ x : ZMod 48 that is a unit, x^4 = 1 (decide over the unit residues), then transfer; coprimality hyps select the unit residues · conf: med
