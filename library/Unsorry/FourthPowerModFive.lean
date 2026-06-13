import Unsorry.FourthPowerModFiveS1
import Unsorry.FourthPowerModFiveS2

theorem fourth_power_mod_five (n : ℕ) (h : n % 5 ≠ 0) : n ^ 4 % 5 = 1 := by
  rw [fourth_power_mod_five_reduce]
  exact fourth_power_residue_mod_five (n % 5) (by omega) (by omega)
