import Mathlib.Data.ZMod.Basic
import Mathlib.RingTheory.Coprime.Basic

/-- `462` divides `n ^ 31 - n` for every integer `n`.

Since `462 = 2 * 3 * 7 * 11`, it suffices to verify the divisibility modulo each
of these pairwise coprime prime factors, where the claim reduces to a decidable
identity over the finitely many residues, and then to recombine the factors. -/
theorem dvd_462_pow_thirtyone_sub_self (n : ℤ) : (462 : ℤ) ∣ n ^ 31 - n := by
  -- Divisibility by a prime modulus, obtained by checking every residue.
  have key : ∀ (m : ℕ) [NeZero m], (∀ x : ZMod m, x ^ 31 - x = 0) →
      ((m : ℤ) ∣ n ^ 31 - n) := by
    intro m _ hm
    have h : ((n ^ 31 - n : ℤ) : ZMod m) = 0 := by
      push_cast
      exact hm _
    rwa [ZMod.intCast_zmod_eq_zero_iff_dvd] at h
  have h2 : (2 : ℤ) ∣ n ^ 31 - n := by exact_mod_cast key 2 (by decide)
  have h3 : (3 : ℤ) ∣ n ^ 31 - n := by exact_mod_cast key 3 (by decide)
  have h7 : (7 : ℤ) ∣ n ^ 31 - n := by exact_mod_cast key 7 (by decide)
  have h11 : (11 : ℤ) ∣ n ^ 31 - n := by exact_mod_cast key 11 (by decide)
  -- Recombine the coprime factors using explicit Bézout witnesses.
  have c23 : IsCoprime (2 : ℤ) 3 := ⟨-1, 1, by ring⟩
  have h6 : (6 : ℤ) ∣ n ^ 31 - n := by
    have h := c23.mul_dvd h2 h3
    norm_num at h
    exact h
  have c67 : IsCoprime (6 : ℤ) 7 := ⟨-1, 1, by ring⟩
  have h42 : (42 : ℤ) ∣ n ^ 31 - n := by
    have h := c67.mul_dvd h6 h7
    norm_num at h
    exact h
  have c4211 : IsCoprime (42 : ℤ) 11 := ⟨5, -19, by ring⟩
  have h := c4211.mul_dvd h42 h11
  norm_num at h
  exact h
