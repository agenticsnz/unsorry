"""Where proofs live — the one place that knows.

A proof's index entry (``index/<sha>.aisp``, the authoritative "this goal is
proved" marker) can sit in **three** namespaces:

* ``library/index`` — the active repo library, proved at the repo-wide pin;
* ``targets/<suite>/_verify/library/index`` — proved at a **suite's** own
  toolchain+mathlib pin (ADR-099 / ADR-116). A benchmark obligation, and through
  the decomposition graph its sub-lemmas, land here and *never* reach the repo
  library;
* ``packages/unsorry-archive-*/library/index`` — retired into an immutable
  archive block (ADR-041).

Before this module every reader hand-rolled its own enumeration, and the suite
namespace was the one they forgot. That single omission has now been fixed five
separate times, each as a production bug:

===========  =================================================================
 #7158        Gate B could not resolve a suite index, so it rejected a valid
              proof tree — and the harness mapped that onto its prove-failed
              path and **decomposed an already-proved goal** (permanent under
              ADR-018).
 #7166        The unblock/recompose sweep could not see suite-pinned proofs, so
              a parent whose sub-lemmas were all proved stayed ``blocked``
              forever.
 #7189        The leaderboard credited none of them: the public goal page read
              "Attribution inferred from git history (no explicit solver
              credit)".
 #7191        Gate A never generated the ADR-011 statement binding for them, so
              statement identity was verified on the proving agent's machine and
              nowhere else — a **soundness** gap.
 (this)       ``targets_board._proved`` did not mark them proved on the board.
===========  =================================================================

ADR-116's Pilot Outcome records the lesson — *enumerate every reader of an
artifact, not just its writers*. This module is the structural answer: readers
should ask here rather than glob for themselves.

**Not every reader wants all three namespaces**, which is why the callers pass
flags rather than getting a single blessed list:

* ``tools.archive.plan`` is repo-only **by design** — archiving MOVES a module
  and its index into a new package with its own lakefile and toolchain, and a
  suite proof already lives in a self-contained package pinned to that suite's
  Lean+mathlib. Archiving one would strip the pin it depends on.
* ``tools.upstream.eligible`` must EXCLUDE the suite namespace — a curated
  benchmark obligation is a competition problem statement, not a mathlib
  contribution candidate. See ``suite_proved_goals``.

Readers still hand-rolling their own enumeration, and could migrate here:
``gate_b.validator``, ``gate_a.check_statement_binding``, ``leaderboard.generate``,
``leaderboard.registered_targets``, ``intake.remigrate_benchmark_subs``. They are
correct today; the duplication is the remaining risk, not a live defect.
"""
from __future__ import annotations

import re
from pathlib import Path

_GOAL_RE = re.compile(r"goal≜([A-Za-z0-9-]+)")


def repo_index_dir(root: Path) -> Path:
    return Path(root) / "library" / "index"


def suite_index_dirs(root: Path) -> list[Path]:
    """Every suite verification package's proof index (ADR-099 / ADR-116)."""
    targets = Path(root) / "targets"
    if not targets.is_dir():
        return []
    return sorted(p for p in targets.glob("*/_verify/library/index") if p.is_dir())


def archive_index_dirs(root: Path) -> list[Path]:
    """Every immutable archive block's proof index (ADR-041)."""
    packages = Path(root) / "packages"
    if not packages.is_dir():
        return []
    return sorted(
        p for p in packages.glob("unsorry-archive-*/library/index") if p.is_dir()
    )


def index_dirs(
    root: Path, *, repo: bool = True, suites: bool = True, archives: bool = True
) -> list[Path]:
    """The index directories a reader cares about, in precedence order.

    Repo first so that when a sha appears in more than one namespace the active
    copy wins — the same precedence the archive readers already relied on.
    """
    dirs: list[Path] = []
    if repo:
        active = repo_index_dir(root)
        if active.is_dir():
            dirs.append(active)
    if suites:
        dirs.extend(suite_index_dirs(root))
    if archives:
        dirs.extend(archive_index_dirs(root))
    return dirs


def goals_in(index_dirs_: list[Path]) -> set[str]:
    """Goal ids marked proved by the given index directories."""
    proved: set[str] = set()
    for index in index_dirs_:
        for entry in sorted(index.glob("*.aisp")):
            match = _GOAL_RE.search(entry.read_text(encoding="utf-8"))
            if match:
                proved.add(match.group(1))
    return proved


def proved_goals(
    root: Path, *, repo: bool = True, suites: bool = True, archives: bool = True
) -> set[str]:
    """Goal ids with a proof index entry in the selected namespaces."""
    return goals_in(index_dirs(root, repo=repo, suites=suites, archives=archives))


def suite_proved_goals(root: Path) -> set[str]:
    """Goal ids whose proof was made at a SUITE's pin.

    Callers use this to *exclude*. `tools.upstream.eligible` is the motivating
    one: a benchmark obligation carries a `backlog/<id>.md` with an `Absence:`
    field (it was sourced like any other goal), so once the board correctly marks
    it proved it satisfies every upstream-packet criterion — and would put an
    AMC/AIME competition statement forward as a mathlib contribution. Measured
    when the board fix landed without this guard: eligibility went 0 → 3, all
    three competition problems.
    """
    return goals_in(suite_index_dirs(root))
