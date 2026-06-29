import Mathlib

theorem hackmath_6 : PMF.binomial (1/2 : NNReal) (by norm_num) 2 1 +
    PMF.binomial (1/2 : NNReal) (by norm_num) 2 2 = ((3 / 4) : ENNReal ) ∧
    PMF.binomial (1/2 : NNReal) (by norm_num) 2 0 +
    PMF.binomial (1/2 : NNReal) (by norm_num) 2 1 = ((3 / 4) : ENNReal ) ∧
    PMF.binomial (1/2 : NNReal) (by norm_num) 2 1 = ((1 / 2) : ENNReal ) := by
  sorry
