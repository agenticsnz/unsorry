import Mathlib.Analysis.Asymptotics.SpecificAsymptotics
import Mathlib.Topology.Order.MonotoneConvergence
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Order.Filter.AtTopBot.Archimedean

/-!
# Putnam 1966 A3

For `x₁ ∈ (0,1)` and `xₙ₊₁ = xₙ(1 - xₙ)`, the sequence `n · xₙ` converges to `1`.

The argument follows the classical route: the reciprocals satisfy
`1/xₙ₊₁ - 1/xₙ = 1/(1 - xₙ)`, whose right-hand side tends to `1` since `xₙ → 0`.
A Cesàro-mean lemma then gives `(1/xₙ)/n → 1`, hence `n · xₙ → 1`.
-/

open Topology Filter

theorem putnam_1966_a3 (x : ℕ → ℝ)
    (hx1 : 0 < x 1 ∧ x 1 < 1)
    (hxi : ∀ n ≥ 1, x (n + 1) = (x n) * (1 - (x n))) :
    Tendsto (fun n : ℕ => n * (x n)) atTop (𝓝 1) := by
  -- Invariant: `0 < x (k+1) < 1` for every `k`.
  have hinv : ∀ k : ℕ, 0 < x (k + 1) ∧ x (k + 1) < 1 := by
    intro k
    induction k with
    | zero => exact hx1
    | succ m ih =>
      obtain ⟨hpos, hlt⟩ := ih
      have hrec : x (m + 1 + 1) = x (m + 1) * (1 - x (m + 1)) := hxi (m + 1) (by omega)
      rw [hrec]
      refine ⟨?_, ?_⟩
      · have : 0 < 1 - x (m + 1) := by linarith
        positivity
      · nlinarith [hpos, hlt]
  have hxpos : ∀ k : ℕ, 0 < x (k + 1) := fun k => (hinv k).1
  have hxlt : ∀ k : ℕ, x (k + 1) < 1 := fun k => (hinv k).2
  have hxne : ∀ k : ℕ, x (k + 1) ≠ 0 := fun k => (hxpos k).ne'
  have h1ne : ∀ k : ℕ, (1 - x (k + 1)) ≠ 0 := fun k => (sub_pos.mpr (hxlt k)).ne'
  -- The shifted sequence `k ↦ x (k+1)` is antitone and bounded below, hence converges.
  have ha_rec : ∀ k : ℕ, x (k + 1 + 1) = x (k + 1) * (1 - x (k + 1)) :=
    fun k => hxi (k + 1) (by omega)
  have ha_anti : Antitone (fun k => x (k + 1)) := by
    apply antitone_nat_of_succ_le
    intro k
    show x (k + 1 + 1) ≤ x (k + 1)
    rw [ha_rec k]
    nlinarith [sq_nonneg (x (k + 1))]
  have ha_bdd : BddBelow (Set.range (fun k => x (k + 1))) := by
    refine ⟨0, ?_⟩
    rintro _ ⟨k, rfl⟩
    exact (hxpos k).le
  have ha_tendsto : Tendsto (fun k => x (k + 1)) atTop (𝓝 (⨅ k, x (k + 1))) :=
    tendsto_atTop_ciInf ha_anti ha_bdd
  set L : ℝ := ⨅ k, x (k + 1) with hL_def
  -- The limit `L` satisfies `L = L (1 - L)`, forcing `L = 0`.
  have hshift : Tendsto (fun k => x (k + 1 + 1)) atTop (𝓝 L) :=
    (tendsto_add_atTop_iff_nat 1).mpr ha_tendsto
  have hmul : Tendsto (fun k => x (k + 1) * (1 - x (k + 1))) atTop (𝓝 (L * (1 - L))) :=
    ha_tendsto.mul (tendsto_const_nhds.sub ha_tendsto)
  have heq : Tendsto (fun k => x (k + 1 + 1)) atTop (𝓝 (L * (1 - L))) :=
    hmul.congr (fun k => (ha_rec k).symm)
  have hLeq : L = L * (1 - L) := tendsto_nhds_unique hshift heq
  have hL0 : L = 0 := mul_self_eq_zero.mp (by linear_combination hLeq)
  have ha0 : Tendsto (fun k => x (k + 1)) atTop (𝓝 0) := by
    rw [hL0] at ha_tendsto; exact ha_tendsto
  -- The increments `1/(1 - x (i+1))` tend to `1`.
  have hu : Tendsto (fun i => (1 - x (i + 1))⁻¹) atTop (𝓝 1) := by
    have h1 : Tendsto (fun i => 1 - x (i + 1)) atTop (𝓝 1) := by
      have hc : Tendsto (fun _ : ℕ => (1 : ℝ)) atTop (𝓝 1) := tendsto_const_nhds
      have := hc.sub ha0
      simpa using this
    have h2 := h1.inv₀ (one_ne_zero)
    simpa using h2
  -- Telescoping the increments recovers `1/x (n+1) - 1/x 1`.
  have hstepu : ∀ n : ℕ, (1 - x (n + 1))⁻¹ = (x (n + 1 + 1))⁻¹ - (x (n + 1))⁻¹ := by
    intro n
    rw [ha_rec n]
    have ht0 : x (n + 1) ≠ 0 := hxne n
    have ht1 : (1 - x (n + 1)) ≠ 0 := h1ne n
    field_simp
    ring
  have hS : ∀ n : ℕ,
      ∑ i ∈ Finset.range n, (1 - x (i + 1))⁻¹ = (x (n + 1))⁻¹ - (x 1)⁻¹ := by
    intro n
    induction n with
    | zero => simp
    | succ m ih =>
      rw [Finset.sum_range_succ, ih, hstepu m]
      ring
  -- Cesàro mean of the increments converges to `1`.
  have hces := hu.cesaro
  have hces' : Tendsto (fun n : ℕ => (n : ℝ)⁻¹ * ((x (n + 1))⁻¹ - (x 1)⁻¹)) atTop (𝓝 1) :=
    hces.congr (fun n => by rw [hS n])
  -- The `1/x 1` tail divided by `n` vanishes.
  have hinv0 : Tendsto (fun n : ℕ => (n : ℝ)⁻¹) atTop (𝓝 0) :=
    tendsto_inv_atTop_zero.comp tendsto_natCast_atTop_atTop
  have htail : Tendsto (fun n : ℕ => (n : ℝ)⁻¹ * (x 1)⁻¹) atTop (𝓝 0) := by
    have := hinv0.mul_const ((x 1)⁻¹)
    simpa using this
  have hH : Tendsto (fun n : ℕ => (n : ℝ)⁻¹ * (x (n + 1))⁻¹) atTop (𝓝 1) := by
    have hsum := hces'.add htail
    rw [add_zero] at hsum
    exact hsum.congr (fun n => by ring)
  -- Taking reciprocals: `n · x (n+1) → 1`.
  have hnx1 : Tendsto (fun n : ℕ => (n : ℝ) * x (n + 1)) atTop (𝓝 1) := by
    have h := hH.inv₀ (one_ne_zero)
    rw [inv_one] at h
    exact h.congr (fun n => by rw [mul_inv, inv_inv, inv_inv])
  -- Then `(n+1) · x (n+1) → 1`.
  have hstep2 : Tendsto (fun n : ℕ => ((n : ℝ) + 1) * x (n + 1)) atTop (𝓝 1) := by
    have h := hnx1.add ha0
    rw [add_zero] at h
    exact h.congr (fun n => by ring)
  have hfinal : Tendsto (fun n : ℕ => ((n + 1 : ℕ) : ℝ) * x (n + 1)) atTop (𝓝 1) :=
    hstep2.congr (fun n => by rw [Nat.cast_add, Nat.cast_one])
  -- Reindexing yields the claim for `n · x n`.
  rw [← tendsto_add_atTop_iff_nat 1]
  exact hfinal
