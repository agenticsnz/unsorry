import Mathlib

theorem pell_negative_brahmagupta_composition_generic_d (d a b c e : ℤ) (h1 : a^2 - d * b^2 = -1) (h2 : c^2 - d * e^2 = -1) : (a * c + d * b * e)^2 - d * (a * e + b * c)^2 = 1 := by
  linear_combination (c ^ 2 - d * e ^ 2) * h1 - h2
