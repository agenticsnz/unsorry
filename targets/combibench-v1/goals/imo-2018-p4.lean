import Mathlib

abbrev Site := Fin 20 × Fin 20
def Site.asPoint (s : Site) : EuclideanSpace ℝ (Fin 2) :=
  fun x => if x = 0 then (s.1.val + 1) else (s.2.val + 1)
inductive State
  | red
  | blue
  | unoccupied
abbrev Game := Site → State
def initialGame : Game := fun _ => State.unoccupied
def valid_Amy_move (x : Site) (g : Game) : Prop :=
  g x = State.unoccupied ∧
  ∀ y, g y = State.red → dist x.asPoint y.asPoint ≠ √5
def valid_Ben_move (x : Site) (g : Game) : Prop :=
  g x = State.unoccupied
def AmyStrategy := Π (g : Game), Option ((x : Site) ×' valid_Amy_move x g)
def Game.updateAccordingToAmyStrategy (g : Game) (s : AmyStrategy) : Option Game :=
  (s g) >>= fun p => .some <| Function.update g p.1 .red
def BenStrategy := Π (g : Game), Option ((x : Site) ×' valid_Ben_move x g)
def Game.updateAccordingToBenStrategy (g : Game) (s : BenStrategy) : Option Game :=
  (s g) >>= fun p => .some <| Function.update g p.1 .blue
def updateOneTurn (a : AmyStrategy) (b : BenStrategy) (g : Game) : Option Game :=
  g.updateAccordingToAmyStrategy a >>= fun g' => g'.updateAccordingToBenStrategy b
def updateGame (a : AmyStrategy) (b : BenStrategy) (g : Game) : ℕ → Option Game
  | 0 => .some g
  | (n + 1) => updateOneTurn a b g >>= (updateGame a b · n)
def CanPlaceKRedStones (a : AmyStrategy) (b : BenStrategy) : ℕ → Prop
  | 0 => True
  | n+1 =>
    ∃ (h : updateGame a b initialGame n |>.isSome),
      a ((updateGame a b initialGame n).get h) |>.isSome

theorem imo_2018_p4 :
    -- there exists a strategy for Amy, such that no matter how Ben play, Amy can place at least `k` stone.
    (∃ a : AmyStrategy, ∀ b : BenStrategy, CanPlaceKRedStones a b ((100) : ℕ )) ∧
    -- but no matter how Amy play, there is a strategy for Ben, such that Amy can not place `k+1` stones.
    (∀ a : AmyStrategy, ∃ b : BenStrategy, ¬ CanPlaceKRedStones a b (((100) : ℕ ) + 1)) := by
  sorry
