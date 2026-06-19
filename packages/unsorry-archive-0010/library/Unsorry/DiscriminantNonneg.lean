import Mathlib.Data.Real.Basic
import Unsorry.DiscriminantNonnegS1
import Unsorry.DiscriminantNonnegS2
import Unsorry.DiscriminantNonnegS3

theorem discriminant_nonneg (a b c x : ℝ) (ha : 0 < a) (hdisc : b ^ 2 ≤ 4 * a * c) : 0 ≤ a * x ^ 2 + b * x + c := by
  have h1 := completed_square_form_nonneg a b c x hdisc
  have h2 := mul_four_a_quadratic_eq_completed_square a b c x
  rw [← h2] at h1
  exact nonneg_of_pos_mul_four_a_nonneg a (a * x ^ 2 + b * x + c) ha h1
