# platonic-schlafli-core

For p,q >= 3, the only solutions to 1/p + 1/q > 1/2 are the five Schläfli pairs {3,3},{3,4},{4,3},{3,5},{5,3} — the bounded-arithmetic core of 'there are exactly five Platonic solids'.

- **Source:** Freek 100 (#50)
- **Reference:** Freek Wiedijk's 100 Theorems #50 (The Number of Platonic Solids) — EMPTY in the Lean column (only HOL Light). Euclid, Elements XIII; Coxeter, Regular Polytopes, Ch. 1. The 1/p+1/q>1/2 reduction is…
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-10); related lemmas exist but are different identities
- **Difficulty:** 4
- **Decomposition sketch:** Pure number-theory reduction (sidesteps geometry): L1: from h derive p < 6 (if p≥6,q≥3 then 1/p+1/q ≤ 1/6+1/3 = 1/2, contradiction); symmetric q < 6. L2: with 3≤p,q≤5 enumerate via interval_cases/decide. L3: check each of ≤9 pairs, keep the 5. CAVEAT: proves the combinatorial classification ONLY, no
