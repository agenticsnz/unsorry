`tools/seedkit` is now documented as a first-class **fixture / library-growth**
path, distinct from sourcing, with its attribution and difficulty conformed to
the sourcing paradigm ([ADR-086](docs/adrs/ADR-086-Seedkit-Fixture-Generation-Path.md)).
seedkit mints goals *born proved* straight into the library — a path previously
undocumented in the README, CONTRIBUTING, and the `unsorry-goal-sourcing` skill,
and stamped with a bespoke provenance/difficulty scheme. The generator now
records honest, identity-bearing provenance at write time: an authenticated
`solver` resolved from `UNSORRY_SOLVER`/`SEEDKIT_SOLVER` (it now **refuses to
write anonymous fixtures**, replacing the silent `anon` default), `provider≜lean`,
and the real engine `model≜decide`/`ring` (no more `provider≜seedkit` /
`model≜template-*`, so no post-hoc relabel is needed). Every template family is
rated at the honest **difficulty 1** the sourcing skeptic's "no short one-tactic
proof" bar assigns, replacing the inflated 3–5 self-tags. The README "the path is
the same" invariant, CONTRIBUTING's ways-to-contribute, and the sourcing skill's
`status≜open`/`sha≜∅` invariants are amended to admit the fixture exception, with
cross-references both ways so an agent asked to batch-generate a parametric family
reaches for seedkit rather than the four-gate sourcer.
