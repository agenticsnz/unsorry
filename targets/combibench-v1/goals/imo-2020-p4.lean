import Mathlib

def Iscompanies (n k : ℕ) (car_set : Finset (Fin n × Fin n)) : Prop :=
  car_set.card = k ∧
  (∀ (a b : Fin n), (a, b) ∈ car_set → a < b)∧
  (∀ a ∈ car_set, ∀ b ∈ car_set, a ≠ b → a.1 ≠ b.1 ∧ a.2 ≠ b.2)
def Islinked {n : ℕ} (a b : Fin n) (car_set : Finset (Fin n × Fin n)) : Prop :=
  ∃ s : List (Fin n × Fin n), s.Nodup ∧ (∀ i ∈ s, (i ∈ car_set ∧
  (List.foldl (fun x y => if x.2 = y.1 then (x.1, y.2) else x) (a, a) s = (a, b))))
def Condition (n k : ℕ) : Prop :=
  ∃ (companyA companyB : Finset (Fin n × Fin n)), Iscompanies n k companyA ∧ Iscompanies n k companyB ∧
  (∃ (a b : Fin n), a ≠ b ∧ Islinked a b companyA ∧ Islinked a b companyB)

theorem imo_2020_p4 (n : ℕ) (hn : n > 1) : IsLeast {k | Condition n k} (((fun n => n ^ 2 - n + 1) : ℕ → ℕ ) n) := by
  sorry
