import Mathlib

namespace Imo_2024_p5
abbrev Cell (N : ℕ) : Type := Fin (N + 2) × Fin (N + 1)
abbrev InteriorRow (N : ℕ) : Type := (Set.Icc 1 ⟨N, by omega⟩ : Set (Fin (N + 2)))
abbrev MonsterData (N : ℕ) : Type := InteriorRow N ↪ Fin (N + 1)
def MonsterData.monsterCells {N} (m : MonsterData N) :
    Set (Cell N) :=
  Set.range (fun x : InteriorRow N ↦ ((x : Fin (N + 2)), m x))
def Adjacent {N} (x y : Cell N) : Prop :=
  Nat.dist x.1 y.1 + Nat.dist x.2 y.2 = 1
structure Path (N : ℕ) where
  cells : List (Cell N)
  nonempty : cells ≠ []
  head_first_row : (cells.head nonempty).1 = 0
  last_last_row : (cells.getLast nonempty).1 = N + 1
  valid_move_seq : cells.Chain' Adjacent
noncomputable def Path.firstMonster {N} (p : Path N) (m : MonsterData N) : Option (Cell N) :=
  letI := Classical.propDecidable
  p.cells.find? (fun x ↦ (x ∈ m.monsterCells : Bool))
abbrev Strategy (N : ℕ) : Type := ⦃k : ℕ⦄ → (Fin k → Option (Cell N)) → Path N
noncomputable def Strategy.play {N} (s : Strategy N) (m : MonsterData N) :
    (k : ℕ) → Fin k → Option (Cell N)
  | 0 => Fin.elim0
  | k + 1 => Fin.snoc (s.play m k) ((s (s.play m k)).firstMonster m)
def Strategy.WinsIn {N} (s : Strategy N) (m : MonsterData N) (k : ℕ) : Prop :=
  none ∈ Set.range (s.play m k)
def Strategy.ForcesWinIn {N} (s : Strategy N) (k : ℕ) : Prop :=
  ∀ m, s.WinsIn m k

theorem imo_2024_p5 : IsLeast {k | ∃ s : Strategy 2022, s.ForcesWinIn k} ((3) : ℕ ) := by
  sorry
