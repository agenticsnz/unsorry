import Mathlib

set_option maxRecDepth 8000 in
theorem cube_mod_fortythree_mem (n : ℕ) :
    (n^3) % 43 ∈ ({0,1,2,4,8,11,16,21,22,27,32,35,39,41,42} : Finset ℕ) := by
  sorry
