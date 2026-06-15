import Mathlib
import Unsorry.PlatonicSchlafliCore

/-- Track-1 classification (Freek #50, combinatorial/Euler form — ADR-031).
The incidence data of an abstract regular polyhedron (`V` vertices, `E` edges,
`F` faces that are `p`-gons, vertices of degree `q`) satisfying the two handshakes
`p·F = 2E`, `q·V = 2E` and Euler's relation `V + F = E + 2` forces `(p, q)` to be one
of the five Platonic Schläfli pairs. The proof reuses the proved arithmetic core
`platonic_schlafli_pairs`: Euler + the handshakes give `1/p + 1/q = 1/2 + 1/E > 1/2`. -/
theorem abstract_regular_polyhedron_classification
    (p q V E F : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q) (hV : 0 < V) (hF : 0 < F)
    (hpF : p * F = 2 * E) (hqV : q * V = 2 * E) (hEuler : V + F = E + 2) :
    (p, q) ∈ ({(3, 3), (3, 4), (4, 3), (3, 5), (5, 3)} : Finset (ℕ × ℕ)) := by
  -- E > 0, since 2E = p·F ≥ 3·1.
  have hE : 0 < E := by
    have h0 : 0 < p * F := Nat.mul_pos (by omega) hF
    rw [hpF] at h0; omega
  -- The combinatorial heart: 2E·(2p + 2q − pq) = 4pq > 0, so 2p + 2q > pq.
  have key_ineq : (p : ℤ) * q < 2 * p + 2 * q := by
    have A : (p : ℤ) * F = 2 * E := by exact_mod_cast hpF
    have B : (q : ℤ) * V = 2 * E := by exact_mod_cast hqV
    have C : (V : ℤ) + F = E + 2 := by exact_mod_cast hEuler
    have hEZ : (0 : ℤ) < E := by exact_mod_cast hE
    have hpZ : (0 : ℤ) < p := by exact_mod_cast (show 0 < p by omega)
    have hqZ : (0 : ℤ) < q := by exact_mod_cast (show 0 < q by omega)
    -- 4pE + 4qE = 2pqE + 4pq  (from 2pq·Euler, substituting the handshakes)
    have ident : 4 * (p : ℤ) * E + 4 * q * E = 2 * p * q * E + 4 * p * q := by
      linear_combination (2 * (p : ℤ) * q) * C - (2 * (q : ℤ)) * A - (2 * (p : ℤ)) * B
    nlinarith [ident, hEZ, mul_pos hpZ hqZ]
  -- Convert 2p + 2q > pq into the inverse form the core consumes.
  have key : (p : ℚ)⁻¹ + (q : ℚ)⁻¹ > 2⁻¹ := by
    have hpQ : (0 : ℚ) < (p : ℚ) := by exact_mod_cast (show 0 < p by omega)
    have hqQ : (0 : ℚ) < (q : ℚ) := by exact_mod_cast (show 0 < q by omega)
    have hpne : (p : ℚ) ≠ 0 := ne_of_gt hpQ
    have hqne : (q : ℚ) ≠ 0 := ne_of_gt hqQ
    have hpq : (p : ℚ) * q < 2 * p + 2 * q := by exact_mod_cast key_ineq
    rw [gt_iff_lt, ← sub_pos]
    have hrw : (p : ℚ)⁻¹ + (q : ℚ)⁻¹ - 2⁻¹
        = (2 * (p : ℚ) + 2 * q - p * q) / (2 * (p * q)) := by
      field_simp
      ring
    rw [hrw]
    apply div_pos
    · linarith [hpq]
    · positivity
  exact platonic_schlafli_pairs p q hp hq key
