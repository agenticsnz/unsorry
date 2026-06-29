import Mathlib

abbrev Coin := Fin 2
abbrev Coin.H : Coin := 0
abbrev Coin.T : Coin := 1
abbrev CoinConfig (n : ℕ) := Fin n → Coin
def CoinConfig.countH {n : ℕ} (c : CoinConfig n) : ℕ := (List.ofFn c).count .H
def CoinConfig.flip {n : ℕ} (c : CoinConfig n) (k : ℕ) : CoinConfig n :=
  fun i => if i.val + 1 = k then
    match c i with
    | .H => .T
    | .T => .H
  else c i
def CoinConfig.update {n : ℕ} (c : CoinConfig n) : Option (CoinConfig n) :=
  if c.countH = 0 then none else .some <| c.flip c.countH
def CoinConfig.updateMultipleTimes {n : ℕ} (c : CoinConfig n) : ℕ → Option (CoinConfig n)
  | 0 => if c.countH = 0 then none else .some c
  | k+1 => c.updateMultipleTimes k >>= update

theorem imo_2019_p5_1 {n : ℕ} (hn : n > 0) : ∀ (c : CoinConfig n), ∃ N : ℕ, c.updateMultipleTimes N = .none := by
  sorry
