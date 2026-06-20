import Unsorry.NesbittInequalityS1
import Unsorry.NesbittInequalityS2
import Unsorry.NesbittInequalityS3
import Unsorry.NesbittInequalityS4

theorem nesbitt_inequality (a b c : ℝ) (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) :
    3 / 2 ≤ a / (b + c) + b / (c + a) + c / (a + b) :=
  le_trans
    (symmetric_bound_implies_three_halves a b c
      (positive_pairwise_sum a b c ha hb hc)
      (three_pairwise_le_sum_square a b c))
    (nesbitt_titu_lower_bound a b c ha hb hc)
