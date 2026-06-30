import Mathlib

abbrev sortedList (n : ℕ) := (List.range (2 * n))|>.map
  (fun i ↦ if i < n then 0 else 1)
def checkList (k : ℕ) : List ℕ → ℕ × ℕ := fun L ↦ Id.run do
  let mut i0 := k - 1
  let mut i1 := k - 1
  for i in [k : L.length] do
    if L[i]! = L[k-1]! then
      i1 := i1 + 1
    else break
  for j in [1 : k] do
    if L[k-1-j]! = L[k-1]! then
      i0 := i0 - 1
    else break
  return (i0, i1)
abbrev action (k : ℕ) : List ℕ → List ℕ := fun L ↦
  (List.range ((checkList k L).2 - (checkList k L).1 + 1)).map (fun _ ↦ L[k-1]!) ++
  (List.range (checkList k L).1).map (fun i ↦ L[i]!) ++
  (List.range (L.length - (checkList k L).2 - 1)).map (fun i ↦ L[i + (checkList k L).2 + 1]!)
abbrev pown (k m : ℕ) : List ℕ → List ℕ := fun L ↦ Id.run do
  let mut L' := L
  for _ in [0 : m] do
    L' := action k L'
  return L'
abbrev checkLeft (n : ℕ) : List ℕ → Bool := fun L ↦ Id.run do
  for i in [0 : n] do
    if L[i]! ≠ L[0]! then
      return false
    else continue
  return true
def initial (n : ℕ) : Finset (List ℕ) := (List.replicate n 0 ++ List.replicate n 1).permutations.toFinset

theorem imo_2022_p1 (n : ℕ) (hn : n > 0) :
    {(n', k) | n = n' ∧ k ≥ 1 ∧ k ≤ 2 * n ∧ (∀ I ∈ initial n, ∃ m : ℕ, checkLeft n' (pown k m I))} =
    ((fun n => {p | p.1 = n ∧ n ≤ p.2 ∧ p.2 ≤ ⌈(3 * n : ℝ) / 2⌉₊}) : ℕ → Set (ℕ × ℕ) ) n := by
  sorry
