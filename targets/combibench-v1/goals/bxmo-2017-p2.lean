import Mathlib

variable (m : ℕ)
local notation3 (prettyPrint := false) "n" => (m + 2)
local notation3 (prettyPrint := false) "F1" => (0 : Fin n)
local notation3 (prettyPrint := false) "F2" => (1 : Fin n)
structure GameState where
  islands: SimpleGraph (Fin n)
  decidable: DecidableRel islands.Adj
instance (s : GameState m) : DecidableRel s.islands.Adj := by
  exact s.decidable
def GameState.initial : GameState m := {
  islands := ⊥
  decidable := SimpleGraph.Bot.adjDecidable (Fin n)
}
structure Bridge where
  island1 : Fin n
  island2 : Fin n
def reachableByFactory (s : GameState m) (b : Bridge m) : Prop :=
  s.islands.Reachable b.island1 F1 ∨ s.islands.Reachable b.island1 F2
  ∨ s.islands.Reachable b.island2 F1 ∨ s.islands.Reachable b.island2 F2
def isValidMove (s : GameState m) (b : Bridge m) : Prop :=
  b.island1 ≠ b.island2 ∧ ¬ s.islands.Adj b.island1 b.island2 ∧ reachableByFactory m s b
def GameState.next (s : GameState m) (b : Bridge m) : GameState m := {
  islands := s.islands ⊔ (SimpleGraph.fromEdgeSet {s(b.island1, b.island2)})
  decidable := by
    have newEdge: DecidableRel (SimpleGraph.fromEdgeSet {s(b.island1, b.island2)}).Adj := by
      intro x y; unfold SimpleGraph.fromEdgeSet
      simp only [Pi.inf_apply, Sym2.toRel_prop, Set.mem_singleton_iff, Sym2.eq, Sym2.rel_iff',
        Prod.mk.injEq, Prod.swap_prod_mk, ne_eq, inf_Prop_eq]
      infer_instance
    exact SimpleGraph.Sup.adjDecidable (Fin n) s.islands (SimpleGraph.fromEdgeSet {s(b.island1, b.island2)})
}
def GameState.is_losing_state (s : GameState m) : Prop :=
  s.islands.Reachable F1 F2
abbrev Strategy := GameState m → Bridge m
instance (s: GameState m) : Decidable (GameState.is_losing_state m s) := by
  simp [GameState.is_losing_state]; infer_instance
instance (s: GameState m) (b : Bridge m) : Decidable (reachableByFactory m s b) := by
  simp [reachableByFactory]; infer_instance
instance (s: GameState m) (b : Bridge m) : Decidable (isValidMove m s b) := by
  simp [isValidMove]; infer_instance
structure MoveOutcome where
  nextState : GameState m
  hasLost : Bool
def executeStrategy (s : GameState m) (strategy: Strategy m): MoveOutcome m :=
  let bridge := strategy s
  if ¬ isValidMove m s bridge
    then { nextState := s, hasLost := true }
  else
    let nextState := s.next m bridge
    { nextState := nextState, hasLost := nextState.is_losing_state m }
partial def aliceWins (s : GameState m) (sA: Strategy m) (sB: Strategy m): Bool :=
  let ⟨stateAfterAlicesMove, aliceHasLost⟩ := executeStrategy m s sA;
  if aliceHasLost then False else
  let ⟨stateAfterBobsMove, bobHasLost⟩ := executeStrategy m stateAfterAlicesMove sB;
  if bobHasLost then True else
  aliceWins stateAfterBobsMove sA sB

theorem bxmo_2017_p2 : (((fun x => if x % 4 = 3 then 0 else 1) : ℕ → Fin 2 ) n = 0 →
    ∃ strategyA , ∀ strategyB, aliceWins m (GameState.initial m) strategyA strategyB)
    ∧ (((fun x => if x % 4 = 3 then 0 else 1) : ℕ → Fin 2 ) n = 1 →
    ∃ strategyB, ∀ strategyA, ¬ aliceWins m (GameState.initial m) strategyA strategyB) := by
  sorry
