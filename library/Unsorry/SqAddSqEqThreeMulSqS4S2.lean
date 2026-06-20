import Mathlib.Data.Int.Basic
import Mathlib.Data.Nat.Find

theorem integer_triple_descent_minimal_positive_exists (P : ℤ → ℤ → ℤ → Prop) (x y z : ℤ) (hP : P x y z) (hpos : 0 < Int.natAbs x + Int.natAbs y + Int.natAbs z) : ∃ a b c, P a b c ∧ 0 < Int.natAbs a + Int.natAbs b + Int.natAbs c ∧ ∀ u v w, P u v w → 0 < Int.natAbs u + Int.natAbs v + Int.natAbs w → Int.natAbs a + Int.natAbs b + Int.natAbs c ≤ Int.natAbs u + Int.natAbs v + Int.natAbs w := by
  classical
  let size : ℤ → ℤ → ℤ → ℕ := fun a b c =>
    Int.natAbs a + Int.natAbs b + Int.natAbs c
  let Good : ℕ → Prop := fun n =>
    ∃ a b c, P a b c ∧ 0 < size a b c ∧ size a b c = n
  have hGood : ∃ n, Good n := by
    exact ⟨size x y z, x, y, z, hP, hpos, rfl⟩
  let n := Nat.find hGood
  obtain ⟨a, b, c, ha, hapos, hasize⟩ := Nat.find_spec hGood
  refine ⟨a, b, c, ha, hapos, ?_⟩
  intro u v w hu hupos
  have hGoodUVW : Good (size u v w) := by
    exact ⟨u, v, w, hu, hupos, rfl⟩
  have hnle : n ≤ size u v w := Nat.find_min' hGood hGoodUVW
  have hsizele : size a b c ≤ size u v w := by
    rw [hasize]
    exact hnle
  simpa [size] using hsizele
