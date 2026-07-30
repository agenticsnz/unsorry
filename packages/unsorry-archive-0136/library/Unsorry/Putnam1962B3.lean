import Mathlib

open Filter Topology

/-- Putnam 1962 B3: a planar convex set `S` containing the origin, that is either open at the
origin or closed, and out of which every ray from the origin eventually escapes, is bounded.

The argument is by contradiction. If `S` is unbounded, pick points `x n ∈ S` with `‖x n‖ > n` and
normalise them to unit vectors `u n` on the (compact) unit sphere. A convergent subsequence has a
limit direction `a` with `‖a‖ = 1`. For each `t ≥ 0`, the points `t • u (φ m)` lie in `S` once
`‖x (φ m)‖ ≥ t` (they are convex combinations of `0` and `x (φ m)`), so their limit `t • a` lies in
the closure of `S`. The whole ray `{t • a : t ≥ 0}` therefore sits in `closure S`, and in both
topological cases this forces it into `S` itself — contradicting the escape hypothesis applied to
the nonzero direction `a`. -/
theorem putnam_1962_b3 (S : Set (EuclideanSpace ℝ (Fin 2))) (hS : Convex ℝ S ∧ 0 ∈ S)
    (htopo : (0 ∈ interior S) ∨ IsClosed S)
    (hray : ∀ P : EuclideanSpace ℝ (Fin 2), P ≠ 0 → ∃ Q : EuclideanSpace ℝ (Fin 2),
      SameRay ℝ P Q ∧ Q ∉ S) : Bornology.IsBounded S := by
  obtain ⟨hconv, h0S⟩ := hS
  by_contra hub
  rw [isBounded_iff_forall_norm_le] at hub
  -- An unbounded set yields points of norm exceeding every natural number.
  have hseq : ∀ n : ℕ, ∃ y, y ∈ S ∧ (n : ℝ) < ‖y‖ := by
    intro n
    by_contra h
    apply hub
    refine ⟨(n : ℝ), fun y hy => ?_⟩
    by_contra hlt
    exact h ⟨y, hy, not_le.mp hlt⟩
  choose x hxS hxn using hseq
  have hxpos : ∀ n, 0 < ‖x n‖ := fun n => lt_of_le_of_lt (Nat.cast_nonneg n) (hxn n)
  -- Normalise to unit vectors.
  set u : ℕ → EuclideanSpace ℝ (Fin 2) := fun n => (‖x n‖)⁻¹ • x n with hu_def
  have hudef : ∀ n, u n = (‖x n‖)⁻¹ • x n := fun n => by rw [hu_def]
  have hunorm : ∀ n, ‖u n‖ = 1 := by
    intro n
    rw [hudef n, norm_smul, norm_inv, norm_norm, inv_mul_cancel₀ (ne_of_gt (hxpos n))]
  have husph : ∀ n, u n ∈ Metric.sphere (0 : EuclideanSpace ℝ (Fin 2)) 1 := by
    intro n
    rw [Metric.mem_sphere, dist_zero_right]
    exact hunorm n
  -- The unit sphere is compact, so a subsequence of directions converges.
  obtain ⟨a, haS, φ, hφ, hφtend⟩ :=
    (isCompact_sphere (0 : EuclideanSpace ℝ (Fin 2)) 1).tendsto_subseq husph
  have hanorm : ‖a‖ = 1 := by
    have := haS
    rw [Metric.mem_sphere, dist_zero_right] at this
    exact this
  have hane : a ≠ 0 := norm_pos_iff.mp (by rw [hanorm]; norm_num)
  -- Every point of the ray through `a` lies in the closure of `S`.
  have hclosure : ∀ t : ℝ, 0 ≤ t → t • a ∈ closure S := by
    intro t ht
    have htend : Tendsto (fun m => t • u (φ m)) atTop (𝓝 (t • a)) := hφtend.const_smul t
    apply mem_closure_of_tendsto htend
    rw [eventually_atTop]
    obtain ⟨N, hN⟩ := exists_nat_gt t
    refine ⟨N, fun m hm => ?_⟩
    have hbig : t < ‖x (φ m)‖ := by
      have h1 : (N : ℝ) < ‖x (φ m)‖ :=
        calc (N : ℝ) ≤ (m : ℝ) := by exact_mod_cast hm
          _ ≤ (φ m : ℝ) := by exact_mod_cast hφ.id_le m
          _ < ‖x (φ m)‖ := hxn (φ m)
      linarith
    have hc0 : 0 ≤ t / ‖x (φ m)‖ := div_nonneg ht (le_of_lt (hxpos (φ m)))
    have hc1 : t / ‖x (φ m)‖ ≤ 1 := (div_le_one (hxpos (φ m))).mpr (le_of_lt hbig)
    have hmem : (t / ‖x (φ m)‖) • x (φ m) ∈ S := by
      have h := hconv h0S (hxS (φ m)) (a := 1 - t / ‖x (φ m)‖) (b := t / ‖x (φ m)‖)
        (by linarith) hc0 (by ring)
      simpa using h
    have heq : t • u (φ m) = (t / ‖x (φ m)‖) • x (φ m) := by
      rw [hudef (φ m), smul_smul, div_eq_mul_inv]
    rw [heq]
    exact hmem
  -- Upgrade the closure statement to membership in `S`, in both topological cases.
  have key : ∀ t : ℝ, 0 ≤ t → t • a ∈ S := by
    intro t ht
    rcases htopo with hint | hclosed
    · rcases eq_or_lt_of_le ht with h0 | hpos
      · rw [← h0, zero_smul]; exact h0S
      · have h2 : (2 * t) • a ∈ closure S := hclosure (2 * t) (by linarith)
        have hmid := hconv.combo_interior_closure_mem_interior hint h2 (a := (1 : ℝ) / 2)
          (b := (1 : ℝ) / 2) (by norm_num) (by norm_num) (by norm_num)
        have heq : (1 / 2 : ℝ) • (0 : EuclideanSpace ℝ (Fin 2)) + (1 / 2 : ℝ) • ((2 * t) • a)
            = t • a := by
          rw [smul_zero, zero_add, smul_smul]; congr 1; ring
        rw [heq] at hmid
        exact interior_subset hmid
    · rw [← hclosed.closure_eq]
      exact hclosure t ht
  -- The escape hypothesis on the nonzero direction `a` gives the contradiction.
  obtain ⟨Q, hQray, hQnotS⟩ := hray a hane
  rcases hQray with ha0 | hQ0 | ⟨r₁, r₂, hr₁, hr₂, hreq⟩
  · exact hane ha0
  · rw [hQ0] at hQnotS; exact hQnotS h0S
  · apply hQnotS
    have hQeq : Q = (r₁ / r₂) • a := by
      have hrw : Q = r₂⁻¹ • (r₂ • Q) := by
        rw [smul_smul, inv_mul_cancel₀ (ne_of_gt hr₂), one_smul]
      rw [hrw, ← hreq, smul_smul]
      congr 1
      rw [div_eq_mul_inv]; ring
    rw [hQeq]
    exact key (r₁ / r₂) (le_of_lt (div_pos hr₁ hr₂))
