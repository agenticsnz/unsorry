"""Generate community proof statistics and leaderboard views.

Usage:
  python3 -m tools.leaderboard [<repo-root>]
  python3 -m tools.leaderboard --json [<repo-root>]
  python3 -m tools.leaderboard --write [<repo-root>]
  python3 -m tools.leaderboard --check [<repo-root>]
"""
from __future__ import annotations

import datetime
import functools
import json
import math
import os
import re
import statistics
import subprocess
import sys
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
from html import escape as html_escape
from pathlib import Path

from tools.gate_b.records import parse_record
from tools.leaderboard.registered_targets import (
    benchmark_goal_ids,
    registered_targets_path,
    render_registered_targets_json,
)
from tools.leaderboard.benchmark_runs import (
    benchmark_runs_path,
    render_benchmark_runs_json,
)


SCORE_POLICY = (
    "rank by score desc; "
    "score = difficulty_points * 100 + credited_proofs * 25 "
    "+ dispatch_points * 100 (dispatch_points = 0.9 flat for each proof PR you "
    "opened/landed for another contributor; self-dispatch excluded — the system "
    "does not run without dispatchers)"
)

# Flat credit, in difficulty-point units, for landing ANOTHER contributor's proof
# PR. Dispatch is load-bearing infrastructure (no dispatch -> nothing merges), so
# it is valued at nearly a full proof regardless of that proof's difficulty.
DISPATCH_POINTS_PER_DISPATCH = 0.9


@dataclass(frozen=True)
class Goal:
    id: str
    status: str
    difficulty: int


@dataclass(frozen=True)
class Proof:
    path: str
    sha: str
    goal: str
    date: str
    solver: str | None
    agent: str | None
    provider: str | None
    model: str | None
    effort: str | None
    attempts: int | None
    solve_s: int | None
    difficulty: int


@dataclass(frozen=True)
class Run:
    id: str
    goal: str
    ended: str
    outcome: str
    solver: str
    agent: str
    provider: str
    model: str | None
    effort: str | None
    attempts: int
    solve_s: int
    difficulty: int

    @property
    def succeeded(self) -> bool:
        return self.outcome == "proved"

    @property
    def failed_attempts(self) -> int:
        return self.attempts - 1 if self.succeeded else self.attempts


@dataclass(frozen=True)
class Dataset:
    goals: list[Goal]
    proofs: list[Proof]
    runs: list[Run]


@dataclass(frozen=True)
class GitAuthor:
    commit: str
    name: str
    email: str
    date: str

    @property
    def key(self) -> str:
        return f"{self.name} <{self.email}>"


# --- Per-generation memoisation (issue #6317) --------------------------------
#
# The board's source corpus (goals/ + library/index + proof-runs/ + archive
# blocks + contributor-aliases + git add-author history) is read MANY times per
# refresh: `base_stats` alone runs ~4× across the markdown / community-stats /
# leaderboard-ui / svg renderers, each one re-parsing every AISP record and
# re-walking git attribution. As the corpus grew to ~4k proofs / ~1.2k runs that
# *repetition* — not the per-record work — is what pushed a single regen to the
# ~64 min that starved the push-on-merge refresh (issue #6317).
#
# The two pieces below memoise each loader so a single generation parses every
# record and walks git attribution exactly ONCE, then reuses it across every
# renderer:
#
#   * `@_memo_by_root` caches a `fn(root, …)` loader on the resolved repo root.
#     Invariant: every memoised loader is a pure function of `root` (its other
#     parameters are themselves derived from `root` — `known_goals` is always
#     `goals(root)`, `proof_data` is always `load_dataset(root).proofs`), so
#     keying on `root` alone is sound.
#
#   * `@_scoped` bounds a cache's lifetime to ONE outermost call. Re-entering at
#     depth 0 (a fresh top-level generation) clears every cache first, so each
#     generation re-reads the working tree; nested calls (a renderer asking for
#     the dataset main already loaded) run at depth > 0 and hit the warm cache.
#     This is what keeps the memo from going stale when the corpus changes
#     between two in-process generations — e.g. a test that registers a benchmark
#     suite then recomputes, or the workflow's rebase-and-regen push retry.
_ROOT_CACHES: list[dict] = []
_SCOPE_DEPTH = 0


def reset_caches() -> None:
    """Drop every per-root loader cache."""
    for cache in _ROOT_CACHES:
        cache.clear()


def _memo_by_root(fn):
    """Memoise a ``fn(root, …)`` loader on the resolved repo root."""
    cache: dict[str, object] = {}
    _ROOT_CACHES.append(cache)

    @functools.wraps(fn)
    def wrapper(root: Path, *args, **kwargs):
        key = str(Path(root).resolve())
        if key not in cache:
            cache[key] = fn(root, *args, **kwargs)
        return cache[key]

    return wrapper


def _scoped(fn):
    """Bound the loader caches to one outermost call (see the block comment).

    A fresh top-level call (``_SCOPE_DEPTH == 0``) clears the caches on entry and
    exit, so it always re-reads the working tree; nested calls reuse the warm
    cache. Wraps a memoised loader OUTSIDE ``@_memo_by_root``.
    """

    @functools.wraps(fn)
    def wrapper(*args, **kwargs):
        global _SCOPE_DEPTH
        if _SCOPE_DEPTH == 0:
            reset_caches()
        _SCOPE_DEPTH += 1
        try:
            return fn(*args, **kwargs)
        finally:
            _SCOPE_DEPTH -= 1
            if _SCOPE_DEPTH == 0:
                reset_caches()

    return wrapper


_GITHUB_HANDLE = re.compile(r"^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$")


def _optional(value: str | None) -> str | None:
    return None if not value or value == "∅" else value


def _integer(value: str | None) -> int | None:
    return int(value) if value and value.isdigit() else None


@_scoped
@_memo_by_root
def goals(root: Path) -> list[Goal]:
    result = []
    for path in sorted((root / "goals").glob("*.aisp")):
        record = parse_record(path.read_text(encoding="utf-8"))
        raw = record.fields.get("difficulty", "0")
        result.append(
            Goal(
                id=path.stem,
                status=record.fields.get("status", "unknown"),
                difficulty=int(raw) if raw.isdigit() else 0,
            )
        )
    return result


def proof_index_paths(root: Path) -> list[Path]:
    paths = []
    active_shas = set()
    active = root / "library" / "index"
    if active.is_dir():
        active_paths = sorted(active.glob("*.aisp"))
        paths.extend(active_paths)
        active_shas = {path.stem for path in active_paths}
    packages = root / "packages"
    if packages.is_dir():
        for index in sorted(packages.glob("unsorry-archive-*/library/index")):
            if index.is_dir():
                paths.extend(
                    path for path in index.glob("*.aisp")
                    if path.stem not in active_shas
                )
    return sorted(paths)


@_scoped
@_memo_by_root
def proofs(root: Path, known_goals: list[Goal] | None = None) -> list[Proof]:
    known_goals = goals(root) if known_goals is None else known_goals
    difficulty = {goal.id: goal.difficulty for goal in known_goals}
    result = []
    for path in proof_index_paths(root):
        record = parse_record(path.read_text(encoding="utf-8"))
        goal = record.fields.get("goal", path.stem)
        result.append(
            Proof(
                path=path.relative_to(root).as_posix(),
                sha=path.stem,
                goal=goal,
                date=record.header.date if record.header else "",
                solver=_optional(record.fields.get("solver")),
                agent=_optional(record.fields.get("agent")),
                provider=_optional(record.fields.get("provider")),
                model=_optional(record.fields.get("model")),
                effort=_optional(record.fields.get("effort")),
                attempts=_integer(record.fields.get("attempts")),
                solve_s=_integer(record.fields.get("solve_s")),
                difficulty=difficulty.get(goal, 0),
            )
        )
    return result


@_scoped
@_memo_by_root
def runs(root: Path, known_goals: list[Goal] | None = None) -> list[Run]:
    known_goals = goals(root) if known_goals is None else known_goals
    difficulty = {goal.id: goal.difficulty for goal in known_goals}
    result = []
    for path in sorted((root / "proof-runs").glob("*.aisp")):
        record = parse_record(path.read_text(encoding="utf-8"))
        attempts = _integer(record.fields.get("attempts"))
        solve_s = _integer(record.fields.get("solve_s"))
        if attempts is None or solve_s is None:
            continue
        goal = record.fields.get("goal", "")
        result.append(
            Run(
                id=record.fields.get("id", path.stem),
                goal=goal,
                ended=record.fields.get("ended", ""),
                outcome=record.fields.get("outcome", "unknown"),
                solver=record.fields.get("solver", "unknown"),
                agent=record.fields.get("agent", "unknown"),
                provider=record.fields.get("provider", "unknown"),
                model=_optional(record.fields.get("model")),
                effort=_optional(record.fields.get("effort")),
                attempts=attempts,
                solve_s=solve_s,
                difficulty=difficulty.get(goal, 0),
            )
        )
    return result


@_scoped
@_memo_by_root
def load_dataset(root: Path) -> Dataset:
    goal_data = goals(root)
    proof_data = proofs(root, goal_data)
    # ADR-092 cohort segregation: a registered benchmark obligation is scored on its
    # own surface (registered-targets.json), never the organic board. No-op until a
    # suite is registered — benchmark_goal_ids is empty without targets/ — so organic
    # stats stay byte-identical until a suite actually lands.
    bench = benchmark_goal_ids(root)
    if bench:
        proof_data = [proof for proof in proof_data if proof.goal not in bench]
    return Dataset(goal_data, proof_data, runs(root, goal_data))


def _valid_github_handle(value: str | None) -> str | None:
    if value and _GITHUB_HANDLE.fullmatch(value):
        return value
    return None


def _profile_url(handle: str | None) -> str | None:
    handle = _valid_github_handle(handle)
    return f"https://github.com/{handle}" if handle else None


def _avatar_url(handle: str | None) -> str | None:
    handle = _valid_github_handle(handle)
    return f"https://github.com/{handle}.png?size=96" if handle else None


def contributor_aliases(root: Path) -> dict[str, dict[str, str]]:
    path = root / "docs" / "metrics" / "contributor-aliases.json"
    if not path.is_file():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema_version") != 1:
        return {}
    aliases = data.get("git_authors", {})
    if not isinstance(aliases, dict):
        return {}
    return {
        str(key): value
        for key, value in aliases.items()
        if isinstance(value, dict)
    }


def _git_attribution_path(path: str) -> str:
    parts = Path(path).parts
    if (
        len(parts) == 5
        and parts[0] == "packages"
        and parts[1].startswith("unsorry-archive-")
        and parts[2] == "library"
        and parts[3] == "index"
    ):
        return f"library/index/{parts[4]}"
    return path


@_scoped
@_memo_by_root
def git_add_authors(root: Path, proof_data: list[Proof]) -> dict[str, GitAuthor]:
    lookup_by_proof = {
        proof.path: _git_attribution_path(proof.path) for proof in proof_data
    }
    lookup_paths = sorted(set(lookup_by_proof.values()))
    if not lookup_paths:
        return {}
    # Walk the add-history of the `library/index` DIRECTORY, not each of the
    # thousands of individual index files. Every attribution path is under
    # `library/index/` (active records sit there; archived records remap to it via
    # `_git_attribution_path`), so one directory pathspec yields exactly the same
    # add-commits while we filter to `wanted` below. Passing ~4k literal pathspecs
    # instead made `git log` O(history × pathspecs) — ~86 s per call on the current
    # corpus, ×~9 calls per refresh — which was the dominant term in the ~64 min
    # regen (issue #6317). The directory walk does the same work in well under a
    # second; the streamed result is filtered in Python, so the output is identical.
    command = [
        "git",
        "-C",
        str(root),
        "log",
        "--diff-filter=A",
        "--name-only",
        "--format=\x1e%H\x1f%an\x1f%ae\x1f%cs",
        "--",
        "library/index",
    ]
    result = subprocess.run(
        command,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    if result.returncode != 0:
        return {}

    authors_by_lookup: dict[str, GitAuthor] = {}
    current: GitAuthor | None = None
    wanted = set(lookup_paths)
    for raw_line in result.stdout.split("\n"):
        line = raw_line.rstrip("\n\r")
        if not line:
            continue
        if line.startswith("\x1e"):
            fields = line[1:].split("\x1f")
            if len(fields) == 4:
                current = GitAuthor(
                    commit=fields[0],
                    name=fields[1],
                    email=fields[2],
                    date=fields[3],
                )
            else:
                current = None
            continue
        path = line.strip()
        if current and path in wanted:
            # `git log` is newest-first. Assigning through the stream leaves the
            # earliest add commit if a path was deleted and later re-added.
            authors_by_lookup[path] = current
    return {
        proof_path: authors_by_lookup[lookup_path]
        for proof_path, lookup_path in lookup_by_proof.items()
        if lookup_path in authors_by_lookup
    }


def _alias_for(
    aliases: dict[str, dict[str, str]], author: GitAuthor | None
) -> tuple[str | None, str | None]:
    if author is None:
        return None, None
    alias = aliases.get(author.key, {})
    display_name = str(alias.get("display_name") or author.name)
    github = _valid_github_handle(str(alias.get("github") or ""))
    return display_name, github


def historical_attribution(root: Path, data: Dataset | None = None) -> dict:
    data = load_dataset(root) if data is None else data
    aliases = contributor_aliases(root)
    authors_by_path = git_add_authors(root, data.proofs)
    by_author: dict[str, dict] = {}
    author_objects: dict[str, GitAuthor] = {}
    for proof in data.proofs:
        author = authors_by_path.get(proof.path)
        if author is None:
            continue
        author_objects.setdefault(author.key, author)
        row = by_author.setdefault(
            author.key,
            {
                "git_author": author.key,
                "git_author_name": author.name,
                "sample_add_commit": author.commit,
                "sample_add_date": author.date,
                "index_files_added": 0,
                "missing_solver_provenance": 0,
                "solver_provenance_proofs": 0,
                "difficulty_points": 0,
            },
        )
        row["index_files_added"] += 1
        row["difficulty_points"] += proof.difficulty
        if proof.solver:
            row["solver_provenance_proofs"] += 1
        else:
            row["missing_solver_provenance"] += 1

    authors = []
    for key, row in by_author.items():
        author = author_objects[key]
        display_name, github = _alias_for(aliases, author)
        authors.append(
            {
                **row,
                "display_name": display_name or row["git_author_name"],
                "github": github,
                "profile_url": _profile_url(github),
                "avatar_url": _avatar_url(github),
                "attribution_source": "git-add-author",
                "solver_credit": False,
            }
        )
    authors.sort(
        key=lambda row: (
            -int(row["index_files_added"]),
            str(row["display_name"]).lower(),
            str(row["git_author"]).lower(),
        )
    )
    return {
        "source": "git-add-author",
        "scope": "library/index/*.aisp",
        "records": len(data.proofs),
        "git_attributed_index_files": sum(
            int(row["index_files_added"]) for row in authors
        ),
        "unattributed_index_files": len(data.proofs)
        - sum(int(row["index_files_added"]) for row in authors),
        "author_count": len(authors),
        "alias_file": (
            "docs/metrics/contributor-aliases.json"
            if (root / "docs" / "metrics" / "contributor-aliases.json").is_file()
            else None
        ),
        "authors": authors,
    }


def credited_contributors(
    root: Path,
    data: Dataset,
    contributor_runs: dict[str, list[Run]],
) -> list[dict]:
    aliases = contributor_aliases(root)
    authors_by_path = git_add_authors(root, data.proofs)
    rows: dict[str, dict] = {}

    for proof in data.proofs:
        source = "explicit-solver"
        github = _valid_github_handle(proof.solver)
        display_name = f"@{github}" if github else None
        key = github
        git_author = None

        if key is None:
            author = authors_by_path.get(proof.path)
            if author is None:
                continue
            display, mapped_github = _alias_for(aliases, author)
            github = mapped_github
            display_name = f"@{mapped_github}" if mapped_github else display
            key = mapped_github or f"git:{author.key}"
            git_author = author.key
            source = "inferred-git-add-author"

        row = rows.setdefault(
            key,
            {
                "solver": github,
                "github": github,
                "display_name": display_name or str(key),
                "profile_url": _profile_url(github),
                "avatar_url": _avatar_url(github),
                "git_author": git_author,
                "verified_proofs": 0,
                "credited_proofs": 0,
                "explicit_solver_proofs": 0,
                "inferred_git_proofs": 0,
                "difficulty_points": 0,
                "dispatch_proofs": 0,
                "dispatch_points": 0.0,
                "credit_sources": [],
            },
        )
        if row["github"] is None and github:
            row["solver"] = github
            row["github"] = github
            row["profile_url"] = _profile_url(github)
            row["avatar_url"] = _avatar_url(github)
        if row["display_name"].startswith("git:") and display_name:
            row["display_name"] = display_name
        if git_author and not row.get("git_author"):
            row["git_author"] = git_author

        row["verified_proofs"] += 1
        row["credited_proofs"] += 1
        row["difficulty_points"] += proof.difficulty
        if source == "explicit-solver":
            row["explicit_solver_proofs"] += 1
        else:
            row["inferred_git_proofs"] += 1
        if source not in row["credit_sources"]:
            row["credit_sources"].append(source)

    # Dispatch credit (fairness): the contributor who opened/landed a proof PR did
    # real plumbing — without dispatchers nothing merges — so they earn a flat
    # DISPATCH_POINTS_PER_DISPATCH (≈ a full proof), but ONLY when they dispatched
    # SOMEONE ELSE's proof. Opening your own PR (self-dispatch) earns nothing extra,
    # so a high-volume prover cannot also farm dispatch points. Credited only to
    # contributors who already have a proof row (no phantom rows).
    for proof in data.proofs:
        if not proof.solver:
            continue  # no explicit solver: the git-author IS the inferred prover
        author = authors_by_path.get(proof.path)
        if author is None:
            continue
        _, disp_github = _alias_for(aliases, author)
        disp_key = disp_github or f"git:{author.key}"
        solver_handle = _valid_github_handle(proof.solver)
        if disp_github and solver_handle and disp_github == solver_handle:
            continue  # self-dispatch
        drow = rows.get(disp_key)
        if drow is None:
            continue
        drow["dispatch_proofs"] += 1
        drow["dispatch_points"] += DISPATCH_POINTS_PER_DISPATCH

    for row in rows.values():
        handle = row.get("github") or row.get("solver")
        run_stats = _group_stats(contributor_runs.get(str(handle), []))
        row.update(run_stats)
        row["dispatch_points"] = round(row["dispatch_points"], 1)
        row["credit_sources"].sort()
        if row["explicit_solver_proofs"] and row["inferred_git_proofs"]:
            row["credit_source_summary"] = "explicit + inferred"
        elif row["explicit_solver_proofs"]:
            row["credit_source_summary"] = "explicit"
        else:
            row["credit_source_summary"] = "inferred"

    result = list(rows.values())
    result.sort(
        key=lambda row: (
            -int(row["credited_proofs"]),
            -int(row["difficulty_points"]),
            str(row["display_name"]).lower(),
        )
    )
    return result


def attribution_gaps_payload(root: Path) -> dict:
    data = load_dataset(root)
    aliases = contributor_aliases(root)
    authors_by_path = git_add_authors(root, data.proofs)
    gaps = []
    for proof in sorted(data.proofs, key=lambda item: item.path):
        if proof.solver:
            continue
        author = authors_by_path.get(proof.path)
        display_name, github = _alias_for(aliases, author)
        gaps.append(
            {
                "path": proof.path,
                "sha": proof.sha,
                "goal": proof.goal,
                "date": proof.date,
                "difficulty": proof.difficulty,
                "git_author": author.key if author else None,
                "git_author_name": author.name if author else None,
                "git_add_commit": author.commit if author else None,
                "git_add_date": author.date if author else None,
                "display_name": display_name,
                "mapped_github": github,
                "alias_mapped": bool(github),
                "review_status": "candidate" if author else "needs-git-history",
            }
        )
    mapped = sum(1 for gap in gaps if gap["alias_mapped"])
    return {
        "schema_version": 1,
        "generated_from": [
            "library/index/*.aisp",
            "docs/metrics/contributor-aliases.json",
            "git add-author history",
        ],
        "source": "git-add-author",
        "summary": {
            "missing_solver_provenance": len(gaps),
            "git_attributed_missing_solver": sum(
                1 for gap in gaps if gap["git_author"]
            ),
            "mapped_missing_solver": mapped,
            "unmapped_missing_solver": len(gaps) - mapped,
        },
        "missing_solver_provenance": gaps,
    }


def _corroborated_handles(root: Path, data: Dataset) -> set[str]:
    """Casefolded solver handles backed by a *real* contributor footprint (ADR-037).

    A handle is corroborated by: a proof-runs telemetry record (the agent's
    machine-captured solver), or a contributor-aliases `github` mapping. The
    per-proof git add-author is checked separately (it is proof-specific).
    """
    handles = {run.solver.casefold() for run in data.runs if run.solver}
    for value in contributor_aliases(root).values():
        github = _valid_github_handle(str(value.get("github") or ""))
        if github:
            handles.add(github.casefold())
    return handles


def provenance_phantoms(root: Path, data: Dataset | None = None) -> list[dict]:
    """Proof-index records whose explicit ``solver≜`` is corroborated by nothing
    real (ADR-037).

    The leaderboard credits the self-reported ``solver≜`` (ADR-023). A handle that
    appears *only* as that field — with no matching proof-run, no matching git
    add-author, and no contributor-alias — is almost certainly a typo or a
    placeholder (e.g. the ``solver≜kev`` that mis-credited Adam Holt's proofs),
    and it silently steals credit from the real solver. This flags them.
    """
    data = load_dataset(root) if data is None else data
    aliases = contributor_aliases(root)
    authors_by_path = git_add_authors(root, data.proofs)
    corroborated = _corroborated_handles(root, data)
    phantoms = []
    for proof in sorted(data.proofs, key=lambda item: item.path):
        if not proof.solver:
            continue
        handle = proof.solver.casefold()
        author = authors_by_path.get(proof.path)
        _, github = _alias_for(aliases, author)
        if (
            handle in corroborated
            or (github is not None and handle == github.casefold())
            or (author is not None and handle == author.name.casefold())
        ):
            continue
        phantoms.append(
            {
                "path": proof.path,
                "sha": proof.sha,
                "goal": proof.goal,
                "solver": proof.solver,
                "git_author": author.key if author else None,
                "git_author_name": author.name if author else None,
                "git_add_commit": author.commit if author else None,
            }
        )
    return phantoms


def _run_provenance_audit(root: Path) -> int:
    phantoms = provenance_phantoms(root)
    if not phantoms:
        print("provenance audit: every solver≜ is corroborated (ADR-037)")
        return 0
    print(
        f"provenance audit: {len(phantoms)} uncorroborated solver attribution(s) "
        "(ADR-037) — a solver≜ with no proof-run, git add-author, or contributor-"
        "alias footprint (likely a typo or placeholder stealing real credit):",
        file=sys.stderr,
    )
    for phantom in phantoms:
        print(
            f"  {phantom['path']}: solver≜{phantom['solver']}  "
            f"(goal {phantom['goal']}; git add-author "
            f"{phantom['git_author_name'] or '?'})",
            file=sys.stderr,
        )
    print(
        "Fix: set solver≜ to the real solver's handle (cross-check the goal's "
        "proof-runs/ telemetry and the prove commit's git author), or add a "
        "contributor-alias.",
        file=sys.stderr,
    )
    return 1


def _rate(numerator: int, denominator: int) -> float | None:
    return round(numerator / denominator, 4) if denominator else None


def _median(values: list[int]) -> int | None:
    return int(statistics.median(values)) if values else None


def _p90(values: list[int]) -> int | None:
    if not values:
        return None
    ordered = sorted(values)
    return ordered[max(0, math.ceil(0.9 * len(ordered)) - 1)]


def _group_stats(items: list[Run]) -> dict[str, int | float | None]:
    successes = sum(item.succeeded for item in items)
    attempts = sum(item.attempts for item in items)
    seconds = sum(item.solve_s for item in items)
    return {
        "runs": len(items),
        "successes": successes,
        "failures": len(items) - successes,
        "run_success_rate": _rate(successes, len(items)),
        "attempts": attempts,
        "failed_attempts": sum(item.failed_attempts for item in items),
        "attempt_yield": _rate(successes, attempts),
        "total_solve_s": seconds,
        "median_solve_s": _median([item.solve_s for item in items]),
        "p90_solve_s": _p90([item.solve_s for item in items]),
        "successes_per_recorded_hour": (
            round(successes * 3600 / seconds, 3) if seconds else None
        ),
    }


def base_stats(root: Path) -> dict:
    data = load_dataset(root)
    attributed = [
        proof for proof in data.proofs if proof.solver and proof.provider
    ]
    successful_run_goals = {run.goal for run in data.runs if run.succeeded}
    queue = Counter(goal.status for goal in data.goals)

    contributor_runs: dict[str, list[Run]] = defaultdict(list)
    contributor_proofs: dict[str, list[Proof]] = defaultdict(list)
    model_runs: dict[str, list[Run]] = defaultdict(list)
    model_proofs: dict[str, list[Proof]] = defaultdict(list)
    difficulty_runs: dict[int, list[Run]] = defaultdict(list)
    effort_runs: dict[str, list[Run]] = defaultdict(list)
    daily_runs: dict[str, list[Run]] = defaultdict(list)
    goal_runs: dict[str, list[Run]] = defaultdict(list)
    for run in data.runs:
        contributor_runs[run.solver].append(run)
        model_runs[f"{run.provider} / {run.model or 'unknown'}"].append(run)
        difficulty_runs[run.difficulty].append(run)
        effort_runs[run.effort or "unknown"].append(run)
        daily_runs[run.ended[:10] or "unknown"].append(run)
        goal_runs[run.goal].append(run)
    for proof in attributed:
        assert proof.solver and proof.provider
        contributor_proofs[proof.solver].append(proof)
        model_proofs[f"{proof.provider} / {proof.model or 'unknown'}"].append(proof)

    contributors = []
    for solver in sorted(set(contributor_runs) | set(contributor_proofs)):
        run_stats = _group_stats(contributor_runs[solver])
        proof_items = contributor_proofs[solver]
        contributors.append(
            {
                "solver": solver,
                "verified_proofs": len(proof_items),
                "difficulty_points": sum(item.difficulty for item in proof_items),
                **run_stats,
            }
        )
    contributors.sort(
        key=lambda row: (
            -int(row["verified_proofs"]),
            -int(row["difficulty_points"]),
            str(row["solver"]).lower(),
        )
    )
    credited = credited_contributors(root, data, contributor_runs)
    credit_summary = {
        "credited_proofs": sum(int(row["credited_proofs"]) for row in credited),
        "explicit_solver_proofs": sum(
            int(row["explicit_solver_proofs"]) for row in credited
        ),
        "inferred_git_proofs": sum(int(row["inferred_git_proofs"]) for row in credited),
        "uncredited_proofs": len(data.proofs)
        - sum(int(row["credited_proofs"]) for row in credited),
        "credited_contributors": len(credited),
    }

    models = []
    for label in sorted(set(model_runs) | set(model_proofs)):
        run_items = model_runs[label]
        proof_items = model_proofs[label]
        models.append(
            {
                "provider_model": label,
                "verified_proofs": len(proof_items),
                "solvers": len(
                    {item.solver for item in run_items}
                    | {item.solver for item in proof_items if item.solver}
                ),
                **_group_stats(run_items),
            }
        )
    models.sort(
        key=lambda row: (-int(row["verified_proofs"]), -int(row["runs"]), str(row["provider_model"]))
    )

    difficulty = [
        {"difficulty": level, **_group_stats(items)}
        for level, items in sorted(difficulty_runs.items())
    ]
    effort = [
        {"effort": level, **_group_stats(items)}
        for level, items in sorted(effort_runs.items())
    ]
    daily = [
        {"date": date, **_group_stats(items)}
        for date, items in sorted(daily_runs.items())
    ]
    goal_state = {goal.id: goal.status for goal in data.goals}
    goal_effort = [
        {
            "goal": goal,
            "status": goal_state.get(goal, "unknown"),
            "difficulty": items[0].difficulty,
            **_group_stats(items),
        }
        for goal, items in goal_runs.items()
    ]
    goal_effort.sort(
        key=lambda row: (
            -int(row["failed_attempts"]),
            -int(row["total_solve_s"]),
            str(row["goal"]),
        )
    )
    return {
        "schema_version": 1,
        "coverage": {
            "verified_proofs": len(data.proofs),
            "attributed_proofs": len(attributed),
            "historical_unknown_proofs": len(data.proofs) - len(attributed),
            "terminal_runs": len(data.runs),
            "successful_proofs_with_run_telemetry": len(successful_run_goals),
            "proof_run_coverage": _rate(len(successful_run_goals), len(data.proofs)),
        },
        "outcomes": _group_stats(data.runs),
        "outcome_counts": dict(sorted(Counter(run.outcome for run in data.runs).items())),
        "queue": {
            "goals": len(data.goals),
            "status_counts": dict(sorted(queue.items())),
            "difficulty_counts": dict(
                sorted(Counter(goal.difficulty for goal in data.goals).items())
            ),
        },
        "contributors": contributors,
        "credited_contributors": credited,
        "credit": credit_summary,
        "models": models,
        "difficulty": difficulty,
        "effort": effort,
        "daily": daily,
        "historical_attribution": historical_attribution(root, data),
        "goal_effort": goal_effort,
        "recent_runs": [
            asdict(run)
            for run in sorted(data.runs, key=lambda item: (item.ended, item.id), reverse=True)[:20]
        ],
    }


def _duration(seconds: int | None) -> str:
    if seconds is None:
        return "—"
    minutes, seconds = divmod(seconds, 60)
    hours, minutes = divmod(minutes, 60)
    if hours:
        return f"{hours}h {minutes}m"
    if minutes:
        return f"{minutes}m {seconds}s"
    return f"{seconds}s"


def _percent(value: float | None) -> str:
    return "—" if value is None else f"{100 * value:.1f}%"


def _number(value: float | None) -> str:
    return "—" if value is None else f"{value:.2f}"


def render(root: Path) -> str:
    data = load_dataset(root)
    stats = base_stats(root)
    coverage = stats["coverage"]
    outcomes = stats["outcomes"]
    queue = stats["queue"]
    status_text = " · ".join(
        f"{count} {status}" for status, count in queue["status_counts"].items()
    )

    lines = [
        "# Community Proof Statistics",
        "",
        "<!-- generated by tools/leaderboard/generate.py — do not edit by hand -->",
        "",
        "Verified output comes from active `library/index` records plus archived index "
        "records only after their active copy has been retired; append-only terminal-run "
        "telemetry comes from `proof-runs/`. Rates cover only logged runs and never guess "
        "historical failures from Git history. Timing is contributor-reported local proof "
        "plus verification time.",
        "",
        f"**{coverage['verified_proofs']} verified proofs · "
        f"{coverage['attributed_proofs']} attributed · "
        f"{coverage['historical_unknown_proofs']} historical/unknown · "
        f"{coverage['terminal_runs']} logged terminal runs.**",
        "",
        "## Efficiency Baseline",
        "",
        "| Metric | Value |",
        "|--------|------:|",
        f"| Successful terminal runs | {outcomes['successes']} |",
        f"| Failed terminal runs | {outcomes['failures']} |",
        f"| Decomposed after failure | {stats['outcome_counts'].get('decomposed', 0)} |",
        f"| Failed without decomposition | {stats['outcome_counts'].get('failed', 0)} |",
        f"| Run success rate | {_percent(outcomes['run_success_rate'])} |",
        f"| Provider attempts | {outcomes['attempts']} |",
        f"| Failed attempts | {outcomes['failed_attempts']} |",
        f"| Attempt yield | {_percent(outcomes['attempt_yield'])} |",
        f"| Recorded run time | {_duration(outcomes['total_solve_s'])} |",
        f"| Median / p90 run time | {_duration(outcomes['median_solve_s'])} / "
        f"{_duration(outcomes['p90_solve_s'])} |",
        f"| Verified successes per recorded hour | "
        f"{_number(outcomes['successes_per_recorded_hour'])} |",
        f"| Proofs with run telemetry | "
        f"{coverage['successful_proofs_with_run_telemetry']} "
        f"({_percent(coverage['proof_run_coverage'])}) |",
        "",
        "## Work Queue",
        "",
        f"**{queue['goals']} goals · {status_text or 'no status data'}.**",
        "",
        "## Efficiency by Difficulty",
        "",
        "| Difficulty | Runs | Successes | Run success | Failed attempts | Median time |",
        "|-----------:|-----:|----------:|------------:|----------------:|------------:|",
    ]
    if not stats["difficulty"]:
        lines.append("| — | No logged runs yet | — | — | — | — |")
    for row in stats["difficulty"]:
        lines.append(
            f"| {row['difficulty']} | {row['runs']} | {row['successes']} | "
            f"{_percent(row['run_success_rate'])} | {row['failed_attempts']} | "
            f"{_duration(row['median_solve_s'])} |"
        )

    unresolved = [
        row for row in stats["goal_effort"] if row["status"] != "proved"
    ][:10]
    lines.extend([
        "",
        "## Unresolved Effort",
        "",
        "| Goal | Status | Difficulty | Runs | Failed attempts | Recorded time |",
        "|------|--------|-----------:|-----:|----------------:|--------------:|",
    ])
    if not unresolved:
        lines.append("| No logged unresolved effort yet | — | — | — | — | — |")
    for row in unresolved:
        lines.append(
            f"| `{row['goal']}` | `{row['status']}` | {row['difficulty']} | "
            f"{row['runs']} | {row['failed_attempts']} | "
            f"{_duration(row['total_solve_s'])} |"
        )

    lines.extend([
        "",
        "## Contributor Leaderboard",
        "",
        "Rank uses Score (difficulty points + dispatch credit). Explicit `solver≜...` "
        "provenance wins; older proof records without solver provenance use git "
        "add-author attribution as inferred historical credit. **Dispatch credit** "
        "awards 0.9 points to the contributor who opened/landed "
        "someone else's proof PR (self-dispatch excluded); it is added to Score.",
        "",
        "| Rank | Contributor | Proof credit | Explicit | Inferred | Runs | Run success | Difficulty points | Dispatch (0.9 ea) | Score |",
        "|-----:|-------------|-------------:|---------:|---------:|-----:|------------:|------------------:|------------------:|------:|",
    ])
    if not stats["credited_contributors"]:
        lines.append("| — | No credited work yet | — | — | — | — | — | — | — | — |")
    ranked = sorted(
        stats["credited_contributors"],
        key=lambda r: (-_score(r), str(r.get("display_name") or "").lower()),
    )
    for rank, row in enumerate(ranked, 1):
        contributor = (
            f"[@{row['github']}]({row['profile_url']})"
            if row.get("github") and row.get("profile_url")
            else str(row["display_name"])
        )
        lines.append(
            f"| {rank} | {contributor} | {row['credited_proofs']} | "
            f"{row['explicit_solver_proofs']} | {row['inferred_git_proofs']} | "
            f"{row['runs']} | {_percent(row['run_success_rate'])} | "
            f"{row['difficulty_points']} | {row['dispatch_points']} | {_score(row)} |"
        )

    historical = stats["historical_attribution"]
    lines.extend([
        "",
        "## Attribution Notes",
        "",
        f"**{stats['credit']['explicit_solver_proofs']} explicit solver credits · "
        f"{stats['credit']['inferred_git_proofs']} inferred git credits · "
        f"{stats['credit']['uncredited_proofs']} uncredited proof records.**",
        "",
        f"Git add-author attribution covers {historical['git_attributed_index_files']} "
        f"of {historical['records']} proof index files. It is used only where explicit "
        "`solver≜` provenance is missing.",
    ])

    lines.extend([
        "",
        "## Providers and Models",
        "",
        "| Provider / model | Verified proofs | Runs | Run success | Failed attempts | Solvers | Median time | Successes / recorded hour |",
        "|------------------|----------------:|-----:|------------:|----------------:|--------:|------------:|-------------------------:|",
    ])
    if not stats["models"]:
        lines.append("| No attributed work yet | — | — | — | — | — | — | — |")
    for row in stats["models"]:
        lines.append(
            f"| `{row['provider_model']}` | {row['verified_proofs']} | {row['runs']} | "
            f"{_percent(row['run_success_rate'])} | {row['failed_attempts']} | "
            f"{row['solvers']} | {_duration(row['median_solve_s'])} | "
            f"{_number(row['successes_per_recorded_hour'])} |"
        )

    lines.extend([
        "",
        "## Recent Terminal Runs",
        "",
        "| Ended (UTC) | Goal | Solver | Provider / model | Outcome | Attempts | Failed attempts | Time |",
        "|-------------|------|--------|------------------|---------|---------:|----------------:|-----:|",
    ])
    if not data.runs:
        lines.append("| No logged runs yet | — | — | — | — | — | — | — |")
    for run in sorted(data.runs, key=lambda item: (item.ended, item.id), reverse=True)[:20]:
        lines.append(
            f"| `{run.ended}` | `{run.goal}` | "
            f"[@{run.solver}](https://github.com/{run.solver}) | "
            f"`{run.provider} / {run.model or 'unknown'}` | `{run.outcome}` | "
            f"{run.attempts} | {run.failed_attempts} | {_duration(run.solve_s)} |"
        )

    lines.extend([
        "",
        "## Interpretation",
        "",
        "- Leaderboard rank is based on verified proofs, then difficulty points; failures are credited as effort but do not improve rank.",
        "- Run and attempt rates are descriptive, not causal model comparisons. Stratify by difficulty and wait for useful sample sizes.",
        "- Infrastructure failures are excluded because they provide no evidence about mathematical or model performance.",
        "- Historical proofs and failed attempts before this telemetry existed remain unknown rather than reconstructed.",
        "",
    ])
    return "\n".join(lines)


def render_json(root: Path) -> str:
    return json.dumps(base_stats(root), ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def _score(row: dict) -> int:
    dispatch = float(row.get("dispatch_points", 0) or 0)
    return (
        int(row["difficulty_points"]) * 100
        + int(row["verified_proofs"]) * 25
        + int(round(dispatch * 100))
    )


def _success_rate_percent(value: float | None) -> float | None:
    return None if value is None else round(value * 100, 2)


#: ``prove(<goal>)`` / ``recompose(<goal>)`` squash-merge subject (ADR-026) —
#: the authoritative record of a proof landing on the branch. Only the goal id is
#: needed here (the merge *timestamp* comes from the commit, not the subject).
_PROVE_GOAL_RE = re.compile(r"^(?:prove|recompose)\((?P<goal>[a-z0-9][a-z0-9-]*)\):")


def parse_merge_log(text: str) -> dict[str, str]:
    """Map goal → UTC merge-hour timestamp from ``<iso-hour>\\0<subject>`` lines.

    ``git log`` is newest-first, so the *last* assignment per goal wins — the
    oldest ``prove(<goal>)`` commit, i.e. the merge that first landed the proof.
    Pure and testable; no git access here.
    """
    result: dict[str, str] = {}
    for line in text.splitlines():
        timestamp, _, subject = line.partition("\x00")
        match = _PROVE_GOAL_RE.match(subject)
        if match and timestamp:
            result[match.group("goal")] = timestamp
    return result


@_scoped
@_memo_by_root
def merge_times(root: Path) -> dict[str, str]:
    """Resolve goal → UTC merge-hour timestamp from the ``prove(...)`` commits.

    The commit timestamp is normalised to UTC and truncated to the hour (via git's
    ``format-local`` under ``TZ=UTC``) so the merge timeline can bucket hourly —
    the AISP solve ``@date`` carries no time, so it can only bucket daily, whereas
    the merge time records to the second. Degrades to ``{}`` outside a git checkout
    so the AISP-only path (and the fixture tests) stay green.
    """
    try:
        proc = subprocess.run(
            [
                "git", "-C", str(root), "log", "--no-merges",
                "--date=format-local:%Y-%m-%dT%H:00:00Z", "--format=%cd%x00%s",
            ],
            capture_output=True,
            text=True,
            check=False,
            env={**os.environ, "TZ": "UTC"},
        )
    except (OSError, ValueError):
        return {}
    if proc.returncode != 0:
        return {}
    return parse_merge_log(proc.stdout)


def _cumulative_series(buckets: list[str]) -> list[dict]:
    """Cumulative proof count per non-empty time bucket, in ascending order.

    Shared by both proofs-over-time series. Empty bucket keys — a proof with no
    recorded solve date, or no ``prove(...)`` commit on the merge series — are
    dropped so the series stays monotonic in time.
    """
    by_bucket: dict[str, int] = defaultdict(int)
    for bucket in buckets:
        if bucket:
            by_bucket[bucket] += 1
    cumulative = 0
    series: list[dict] = []
    for bucket in sorted(by_bucket):
        cumulative += by_bucket[bucket]
        series.append(
            {"t": bucket, "proofs": by_bucket[bucket], "cumulative_proofs": cumulative}
        )
    return series


def proof_timelines(proof_list: list[Proof], merges: dict[str, str]) -> dict:
    """The two proofs-over-time series for the leaderboard toggle (issue #738).

    ``merge`` (the default): bucketed hourly by the git merge timestamp — when
    each proof landed on the branch — so a merge wave clearing a solve backlog
    reads as recent slope rather than a flat tail. ``solve``: bucketed daily by
    the recorded AISP ``@date`` (a date-only source — daily is the finest honest
    bucket). The ``merge`` series is empty outside a git checkout; ``default``
    names the series the page should show first.
    """
    return {
        "default": "merge",
        "merge": _cumulative_series(
            [merges.get(proof.goal, "") for proof in proof_list]
        ),
        "solve": _cumulative_series(
            [(proof.date or "")[:10] for proof in proof_list]
        ),
    }


# Data paths whose commits change what the board reports — proof merges, archive
# rolls, attribution relabels, and sourcing all land here. Generated docs under
# docs/ are deliberately excluded, so the refresh's own [skip ci] docs commit never
# moves the timestamp (keeping --check free of timestamp-only drift; ADR-036).
_BOARD_SOURCE_PATHS = (
    "goals",
    "library/index",
    "packages",
    "proof-runs",
    "docs/metrics/contributor-aliases.json",
)


def _latest_source_commit_z(root: Path) -> str | None:
    """ISO-8601 UTC (``…Z``) committer time of the most recent commit under ``root``
    that touched the board's source data, or ``None`` when git is unavailable (no
    repo, shallow clone, or a non-repo fixture root). Deterministic for a given
    commit — so it bumps on every proof/relabel merge yet never on the refresh's own
    docs-only commit, leaving ``--check`` free of spurious timestamp-only drift."""
    try:
        result = subprocess.run(
            ["git", "-C", str(root), "log", "-1", "--format=%ct", "--",
             *_BOARD_SOURCE_PATHS],
            check=False, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
        )
    except OSError:
        return None
    out = result.stdout.strip()
    if result.returncode != 0 or not out:
        return None
    return datetime.datetime.fromtimestamp(
        int(out), tz=datetime.timezone.utc
    ).strftime("%Y-%m-%dT%H:%M:%SZ")


def ui_payload(root: Path) -> dict:
    stats = base_stats(root)
    coverage = stats["coverage"]
    historical = stats["historical_attribution"]
    contributors = []
    for rank, row in enumerate(stats["credited_contributors"], 1):
        contributors.append(
            {
                "rank": rank,
                "solver": row["solver"],
                "github": row["github"],
                "display_name": row["display_name"],
                "profile_url": row["profile_url"],
                "avatar_url": row["avatar_url"],
                "score": _score(row),
                "verified_proofs": row["credited_proofs"],
                "credited_proofs": row["credited_proofs"],
                "explicit_solver_proofs": row["explicit_solver_proofs"],
                "inferred_git_proofs": row["inferred_git_proofs"],
                "difficulty_points": row["difficulty_points"],
                "dispatch_proofs": row["dispatch_proofs"],
                "dispatch_points": row["dispatch_points"],
                "runs": row["runs"],
                "successes": row["successes"],
                "run_success_rate": row["run_success_rate"],
                "attempt_yield": row["attempt_yield"],
                "failed_attempts": row["failed_attempts"],
                "median_solve_s": row["median_solve_s"],
                "credit_sources": row["credit_sources"],
                "credit_source_summary": row["credit_source_summary"],
                "badges": {
                    "proofs": row["credited_proofs"],
                    "difficulty": row["difficulty_points"],
                    "success_rate_percent": _success_rate_percent(row["run_success_rate"]),
                },
            }
        )
    historical_contributors = []
    for rank, row in enumerate(historical["authors"], 1):
        historical_contributors.append(
            {
                "rank": rank,
                "display_name": row["display_name"],
                "github": row["github"],
                "profile_url": row["profile_url"],
                "avatar_url": row["avatar_url"],
                "index_files_added": row["index_files_added"],
                "missing_solver_provenance": row["missing_solver_provenance"],
                "solver_provenance_proofs": row["solver_provenance_proofs"],
                "difficulty_points": row["difficulty_points"],
                "attribution_source": row["attribution_source"],
                "solver_credit": False,
            }
        )
    return {
        "schema_version": 1,
        "generated_from": "docs/metrics/community-stats.json",
        # Current as of the latest commit that changed the board's source data
        # (proof merges and attribution relabels both land there) — so it bumps on
        # every refresh that follows a real change while staying deterministic: the
        # refresh's own docs-only [skip ci] commit doesn't touch those paths, so
        # --check sees no timestamp-only drift (no churn). Falls back to the latest
        # recorded run time when git is unavailable (e.g. a non-repo fixture root).
        "generated_at": (
            _latest_source_commit_z(root)
            or (stats["recent_runs"][0]["ended"] if stats["recent_runs"] else None)
        ),
        "score_policy": SCORE_POLICY,
        "summary": {
            "verified_proofs": coverage["verified_proofs"],
            "attributed_proofs": coverage["attributed_proofs"],
            "historical_unknown_proofs": coverage["historical_unknown_proofs"],
            "terminal_runs": coverage["terminal_runs"],
            "proof_run_coverage": coverage["proof_run_coverage"],
            "credited_proofs": stats["credit"]["credited_proofs"],
            "explicit_solver_proofs": stats["credit"]["explicit_solver_proofs"],
            "inferred_git_proofs": stats["credit"]["inferred_git_proofs"],
            "uncredited_proofs": stats["credit"]["uncredited_proofs"],
            "credited_contributors": stats["credit"]["credited_contributors"],
            "git_attributed_index_files": historical["git_attributed_index_files"],
            "historical_contributors": historical["author_count"],
            "attribution_gap_count": coverage["historical_unknown_proofs"],
        },
        "contributors": contributors,
        "historical_contributors": historical_contributors,
        # Model distribution across solved proofs (ADR-023 provider/model cohort),
        # trimmed for the leaderboard UI's "Model distribution" section.
        "models": [
            {
                "provider_model": model["provider_model"],
                "verified_proofs": model["verified_proofs"],
                "runs": model["runs"],
                "run_success_rate": model["run_success_rate"],
            }
            for model in stats["models"]
        ],
        # Cumulative library proofs over time — the "proofs over time" line graph
        # on the leaderboard page (issue #738), with a solve/merge toggle: merge
        # (hourly, default) keys on when each proof landed; solve (daily) keys on
        # the recorded AISP solve date.
        "timelines": proof_timelines(proofs(root), merge_times(root)),
    }


def render_ui_json(root: Path) -> str:
    return json.dumps(ui_payload(root), ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def _bucket_dt(t: str) -> datetime.datetime:
    """Parse a timeline bucket (``2026-06-20T17:00:00Z`` or ``2026-06-13``).

    Used only for x-axis positioning, so naïve date-only buckets and aware hour
    buckets never mix within a single series — differences stay deterministic.
    """
    return datetime.datetime.fromisoformat(t.replace("Z", "+00:00"))


def render_timeline_svg(root: Path) -> str:
    """README preview card: cumulative kernel-verified proofs over time.

    Plots the **merge** series (hourly — when each proof landed on ``main``; the
    leaderboard's default proofs-over-time view, issue #738), falling back to the
    daily **solve** series outside a git checkout. A self-contained SVG mirroring
    ``docs/leaderboard.svg``'s visual language, and a pure function of the series
    so it is deterministic for the ``--check`` gate.
    """
    series = proof_timelines(proofs(root), merge_times(root))
    points = series.get("merge") or series.get("solve") or []
    by_merge = bool(series.get("merge"))
    width, height = 900, 320
    pad_l, pad_r, pad_t, pad_b = 52, 28, 90, 48
    font = "Inter, system-ui, sans-serif"
    total = points[-1]["cumulative_proofs"] if points else 0
    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
        '<title id="title">unsorry proofs over time</title>',
        '<desc id="desc">Cumulative kernel-verified proofs over time, '
        "by the hour each proof was merged.</desc>",
        f'<rect width="{width}" height="100%" rx="18" fill="#ffffff"/>',
        f'<rect x="0.5" y="0.5" width="{width - 1}" height="{height - 1}" rx="18" '
        'fill="none" stroke="#e2e8f0"/>',
        f'<text x="32" y="44" font-family="{font}" font-size="28" font-weight="700" '
        'fill="#334155">unsorry — Proofs Over Time</text>',
        f'<text x="32" y="72" font-family="{font}" font-size="13" fill="#64748b">'
        f"{total} cumulative kernel-verified proofs · "
        f"{'merged, hourly' if by_merge else 'solved, daily'}</text>",
    ]
    if not points:
        out.append(
            f'<text x="32" y="{pad_t + 40}" font-family="{font}" font-size="16" '
            'fill="#64748b">No dated proofs yet.</text>'
        )
        out.append("</svg>")
        return "\n".join(out) + "\n"

    plot_w = width - pad_l - pad_r
    plot_h = height - pad_t - pad_b
    dts = [_bucket_dt(p["t"]) for p in points]
    span = max(1.0, (dts[-1] - dts[0]).total_seconds())
    max_y = max(total, 1)
    n = len(points)

    def px(i: int) -> float:
        if n == 1:
            return pad_l + plot_w / 2
        return pad_l + (dts[i] - dts[0]).total_seconds() / span * plot_w

    def py(v: float) -> float:
        return pad_t + plot_h - v / max_y * plot_h

    for frac in (0, 0.25, 0.5, 0.75, 1):
        v = round(max_y * frac)
        yy = py(v)
        out.append(
            f'<line x1="{pad_l}" y1="{yy:.1f}" x2="{width - pad_r}" y2="{yy:.1f}" '
            'stroke="#f1f5f9"/>'
        )
        out.append(
            f'<text x="{pad_l - 8}" y="{yy + 4:.1f}" text-anchor="end" '
            f'font-family="{font}" font-size="11" fill="#94a3b8">{v}</text>'
        )

    coords = " ".join(
        f"{px(i):.1f},{py(p['cumulative_proofs']):.1f}" for i, p in enumerate(points)
    )
    base = pad_t + plot_h
    out.append(
        f'<polygon points="{px(0):.1f},{base:.1f} {coords} {px(n - 1):.1f},{base:.1f}" '
        'fill="#e0f2fe" opacity="0.55"/>'
    )
    out.append(
        f'<polyline points="{coords}" fill="none" stroke="#38bdf8" stroke-width="2.5" '
        'stroke-linejoin="round" stroke-linecap="round"/>'
    )
    lx, ly = px(n - 1), py(max_y)
    out.append(f'<circle cx="{lx:.1f}" cy="{ly:.1f}" r="4" fill="#0ea5e9"/>')
    out.append(
        f'<text x="{lx - 6:.1f}" y="{ly - 10:.1f}" text-anchor="end" font-family="{font}" '
        f'font-size="13" font-weight="700" fill="#334155">{max_y}</text>'
    )

    def label(dt: datetime.datetime) -> str:
        return f"{dt:%b %d}" + (f" {dt:%H}:00" if by_merge else "")

    for i in sorted({0, n // 2, n - 1}):
        out.append(
            f'<text x="{px(i):.1f}" y="{height - pad_b + 22}" text-anchor="middle" '
            f'font-family="{font}" font-size="11" fill="#94a3b8">{label(dts[i])}</text>'
        )
    out.append("</svg>")
    return "\n".join(out) + "\n"


def render_svg(root: Path) -> str:
    payload = ui_payload(root)
    contributors = payload["contributors"][:5]
    width = 900
    row_h = 64
    top = 112
    rows = max(1, len(contributors))
    height = top + rows * row_h + 54
    max_score = max([int(row["score"]) for row in contributors] + [100])
    summary = payload["summary"]
    lines = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
        "<title id=\"title\">unsorry leaderboard</title>",
        "<desc id=\"desc\">Gamified unsorry contributor leaderboard ranked by credited verified proofs and difficulty points.</desc>",
        "<rect width=\"900\" height=\"100%\" rx=\"18\" fill=\"#ffffff\"/>",
        "<rect x=\"0.5\" y=\"0.5\" width=\"899\" height=\"{h}\" rx=\"18\" fill=\"none\" stroke=\"#e2e8f0\"/>".format(h=height - 1),
        "<text x=\"32\" y=\"44\" font-family=\"Inter, system-ui, sans-serif\" font-size=\"28\" font-weight=\"700\" fill=\"#334155\">unsorry — Leaderboard</text>",
        (
            "<text x=\"32\" y=\"72\" font-family=\"Inter, system-ui, sans-serif\" "
            "font-size=\"13\" fill=\"#64748b\">"
            f"{summary['credited_proofs']} credited proofs · "
            f"{summary['explicit_solver_proofs']} explicit · "
            f"{summary['inferred_git_proofs']} inferred from git · "
            f"{summary['credited_contributors']} contributors"
            "</text>"
        ),
    ]
    if not contributors:
        lines.extend([
            f"<rect x=\"32\" y=\"{top}\" width=\"836\" height=\"58\" rx=\"10\" fill=\"#f8fafc\" stroke=\"#cbd5e1\" stroke-dasharray=\"4 4\"/>",
            f"<text x=\"56\" y=\"{top + 36}\" font-family=\"Inter, system-ui, sans-serif\" font-size=\"16\" fill=\"#64748b\">No credited proofs yet.</text>",
        ])
    for index, row in enumerate(contributors):
        y = top + index * row_h
        bar_w = max(6, int(390 * int(row["score"]) / max_score))
        rank_color = "#fbbf24" if row["rank"] == 1 else "#94a3b8" if row["rank"] == 2 else "#b45309" if row["rank"] == 3 else "#cbd5e1"
        solver = html_escape(str(row["display_name"]))
        profile = row.get("profile_url")
        profile = html_escape(str(profile)) if profile else None
        source = html_escape(str(row["credit_source_summary"]))
        explicit = int(row["explicit_solver_proofs"])
        inferred = int(row["inferred_git_proofs"])
        lines.extend([
            f"<text x=\"34\" y=\"{y + 36}\" font-family=\"Georgia, serif\" font-size=\"24\" font-style=\"italic\" font-weight=\"700\" fill=\"{rank_color}\">{row['rank']}</text>",
        ])
        if profile:
            lines.extend([
                f"<a href=\"{profile}\">",
                f"<text x=\"82\" y=\"{y + 26}\" font-family=\"Inter, system-ui, sans-serif\" font-size=\"17\" font-weight=\"650\" fill=\"#334155\">{solver}</text>",
                "</a>",
            ])
        else:
            lines.append(
                f"<text x=\"82\" y=\"{y + 26}\" font-family=\"Inter, system-ui, sans-serif\" font-size=\"17\" font-weight=\"650\" fill=\"#334155\">{solver}</text>"
            )
        lines.extend([
            (
                f"<text x=\"82\" y=\"{y + 46}\" font-family=\"Inter, system-ui, sans-serif\" "
                f"font-size=\"12\" fill=\"#64748b\">{row['credited_proofs']} proofs · "
                f"{row['difficulty_points']} difficulty · {explicit} explicit · "
                f"{inferred} inferred · {row['runs']} runs</text>"
            ),
            f"<rect x=\"320\" y=\"{y + 15}\" width=\"420\" height=\"26\" rx=\"13\" fill=\"#f1f5f9\"/>",
            f"<rect x=\"320\" y=\"{y + 15}\" width=\"{bar_w}\" height=\"26\" rx=\"13\" fill=\"#e0f2fe\"/>",
            f"<text x=\"760\" y=\"{y + 34}\" font-family=\"Inter, system-ui, sans-serif\" font-size=\"14\" font-weight=\"700\" fill=\"#334155\">{row['score']} pts</text>",
            f"<text x=\"760\" y=\"{y + 50}\" font-family=\"Inter, system-ui, sans-serif\" font-size=\"10\" fill=\"#64748b\">{source}</text>",
        ])
    footer_y = top + rows * row_h + 22
    lines.append(
        f"<text x=\"32\" y=\"{footer_y}\" font-family=\"Inter, system-ui, sans-serif\" font-size=\"12\" fill=\"#64748b\">Inferred credits use git add-author history only when explicit solver provenance is missing.</text>"
    )
    lines.append("</svg>")
    return "\n".join(lines) + "\n"


def render_attribution_gaps_json(root: Path) -> str:
    return json.dumps(
        attribution_gaps_payload(root),
        ensure_ascii=False,
        indent=2,
        sort_keys=True,
    ) + "\n"


@_scoped
@_memo_by_root
def goal_add_authors(root: Path, goal_ids: list[str]) -> dict[str, GitAuthor]:
    """git add-author for each ``goals/<id>.aisp`` — who **sourced** the goal
    (the earliest commit that added the record). Mirrors ``git_add_authors`` but
    for goal records; goals are never archived under ``packages/``, so no
    attribution-path remapping is needed (ADR-060 §6)."""
    lookup = {goal_id: f"goals/{goal_id}.aisp" for goal_id in goal_ids}
    if not lookup:
        return {}
    # As in `git_add_authors`, walk the `goals` directory's add-history once
    # rather than passing one pathspec per goal (O(history × goals); issue #6317),
    # then filter the stream to `wanted`. Identical output, sub-second instead of
    # tens of seconds on the grown corpus.
    result = subprocess.run(
        [
            "git", "-C", str(root), "log", "--diff-filter=A", "--name-only",
            "--format=\x1e%H\x1f%an\x1f%ae\x1f%cs", "--", "goals",
        ],
        check=False, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
    )
    if result.returncode != 0:
        return {}
    by_path: dict[str, GitAuthor] = {}
    current: GitAuthor | None = None
    wanted = set(lookup.values())
    for raw_line in result.stdout.split("\n"):
        line = raw_line.rstrip("\n\r")
        if not line:
            continue
        if line.startswith("\x1e"):
            fields = line[1:].split("\x1f")
            current = GitAuthor(*fields) if len(fields) == 4 else None
            continue
        path = line.strip()
        if current and path in wanted:
            # newest-first ⇒ leaving the last assignment keeps the earliest add.
            by_path[path] = current
    return {gid: by_path[p] for gid, p in lookup.items() if p in by_path}


def sourcing_contributors(root: Path, data: Dataset | None = None) -> list[dict]:
    """Per-sourcer aggregation: who added which goals, with difficulty points and
    a proved/open split. Credit is independent of who *proves* the goal."""
    data = load_dataset(root) if data is None else data
    aliases = contributor_aliases(root)
    authors = goal_add_authors(root, [goal.id for goal in data.goals])
    by_goal = {goal.id: goal for goal in data.goals}
    agg: dict[str, dict] = {}
    for goal_id, author in authors.items():
        goal = by_goal[goal_id]
        display_name, github = _alias_for(aliases, author)
        bucket = github or author.key  # collapse a sourcer's aliases by handle
        row = agg.get(bucket)
        if row is None:
            row = agg[bucket] = {
                "sourcer": github,
                "git_author": author.key,
                "display_name": display_name,
                "github": github,
                "profile_url": _profile_url(github),
                "avatar_url": _avatar_url(github),
                "sourced_goals": 0,
                "difficulty_points": 0,
                "proved": 0,
                "open": 0,
                "earliest_sourced": author.date,
                "latest_sourced": author.date,
            }
        row["sourced_goals"] += 1
        row["difficulty_points"] += goal.difficulty
        if goal.status == "proved":
            row["proved"] += 1
        elif goal.status == "open":
            row["open"] += 1
        row["earliest_sourced"] = min(row["earliest_sourced"], author.date)
        row["latest_sourced"] = max(row["latest_sourced"], author.date)
    return sorted(
        agg.values(),
        key=lambda r: (-r["sourced_goals"], -r["difficulty_points"], r["display_name"] or ""),
    )


def sourcing_payload(root: Path) -> dict:
    rows = sourcing_contributors(root)
    return {
        "schema_version": 1,
        "sourcers": rows,
        "totals": {
            "sourcers": len(rows),
            "sourced_goals": sum(r["sourced_goals"] for r in rows),
            "difficulty_points": sum(r["difficulty_points"] for r in rows),
        },
    }


def render_sourcing_json(root: Path) -> str:
    return json.dumps(sourcing_payload(root), ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def render_sourcing(root: Path) -> str:
    """Markdown view of the sourcing leaderboard (ADR-060 §6)."""
    rows = sourcing_contributors(root)
    lines = [
        "# Sourcing leaderboard",
        "",
        "Who **sourced** the goals — added `goals/<id>.aisp` — independent of who "
        "proves them. Attribution is git add-author (ADR-060); a contributor may "
        "also appear on the proof [leaderboard](../leaderboard.md).",
        "",
        "| # | Contributor | Sourced | Difficulty pts | Proved | Open |",
        "|---|---|---|---|---|---|",
    ]
    for i, r in enumerate(rows, 1):
        who = (
            f"[@{r['github']}]({r['profile_url']})"
            if r.get("github") and r.get("profile_url")
            else r["display_name"]
        )
        lines.append(
            f"| {i} | {who} | {r['sourced_goals']} | {r['difficulty_points']} "
            f"| {r['proved']} | {r['open']} |"
        )
    if not rows:
        lines.append("| — | _no sourced goals attributed yet_ | 0 | 0 | 0 | 0 |")
    return "\n".join(lines) + "\n"


@_scoped
def main(argv: list[str] | None = None) -> int:
    # @_scoped makes this the outermost generation: the whole run shares one warm
    # cache (each record parsed once, each git attribution walked once across all
    # renderers), and the cache is cleared on entry/exit so a second in-process
    # invocation — the workflow's rebase-and-regen push retry — re-reads the tree.
    argv = sys.argv[1:] if argv is None else argv
    if "--audit-provenance" in argv:
        rest = [arg for arg in argv if arg != "--audit-provenance"]
        return _run_provenance_audit(Path(rest[0]) if rest else Path.cwd())
    if "--sourcing" in argv:
        # Standalone human view of the sourcing leaderboard. The machine-readable
        # docs/metrics/sourcing-leaderboard.json is kept fresh by --write/--check
        # alongside the other generated artifacts.
        rest = [arg for arg in argv if arg not in ("--sourcing", "--json")]
        root = Path(rest[0]) if rest else Path.cwd()
        sys.stdout.write(
            render_sourcing_json(root) if "--json" in argv else render_sourcing(root)
        )
        return 0
    write_modes = ("--check", "--write", "--write-if-stale", "--json")
    modes = [flag for flag in write_modes if flag in argv]
    if len(modes) > 1:
        print(
            "--check, --write, --write-if-stale, and --json are mutually exclusive",
            file=sys.stderr,
        )
        return 2
    mode = modes[0] if modes else ""
    rest = [arg for arg in argv if arg not in write_modes]
    root = Path(rest[0]) if rest else Path.cwd()
    markdown = render(root)
    payload = render_json(root)
    ui_payload_json = render_ui_json(root)
    svg = render_svg(root)
    timeline_svg = render_timeline_svg(root)
    gaps_payload = render_attribution_gaps_json(root)
    sourcing_payload_json = render_sourcing_json(root)
    registered_targets_payload = render_registered_targets_json(root)
    benchmark_runs_payload = render_benchmark_runs_json(root)
    markdown_path = root / "docs" / "leaderboard.md"
    json_path = root / "docs" / "metrics" / "community-stats.json"
    ui_json_path = root / "docs" / "metrics" / "leaderboard-ui.json"
    gaps_json_path = root / "docs" / "metrics" / "attribution-gaps.json"
    sourcing_json_path = root / "docs" / "metrics" / "sourcing-leaderboard.json"
    registered_targets_json_path = registered_targets_path(root)
    benchmark_runs_json_path = benchmark_runs_path(root)
    svg_path = root / "docs" / "leaderboard.svg"
    timeline_svg_path = root / "docs" / "proofs-over-time.svg"
    # Single source of truth for the generated artifacts so --check, --write and
    # --write-if-stale share one staleness/write definition (DRY).
    artifacts = (
        (markdown_path, markdown),
        (json_path, payload),
        (ui_json_path, ui_payload_json),
        (gaps_json_path, gaps_payload),
        (sourcing_json_path, sourcing_payload_json),
        (registered_targets_json_path, registered_targets_payload),
        (benchmark_runs_json_path, benchmark_runs_payload),
        (svg_path, svg),
        (timeline_svg_path, timeline_svg),
    )

    def stale_paths() -> list[str]:
        return [
            path.relative_to(root).as_posix()
            for path, content in artifacts
            if not path.is_file() or path.read_text(encoding="utf-8") != content
        ]

    def write_all() -> None:
        for path, content in artifacts:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")

    if mode == "--check":
        stale = stale_paths()
        if stale:
            print(
                f"{', '.join(stale)} stale — regenerate with "
                "`python3 -m tools.leaderboard --write`",
                file=sys.stderr,
            )
            return 1
        return 0
    if mode == "--write":
        write_all()
        return 0
    if mode == "--write-if-stale":
        # ADR-082: fold --check + --write into ONE recompute for the post-merge
        # refresh. The artifacts above are computed exactly once; here we write
        # them only if they drifted and signal that via the exit code — mirroring
        # --check (1 = was stale, now rewritten; 0 = already in sync) — so the
        # workflow no longer pays the heavy regen twice per refresh.
        stale = stale_paths()
        if not stale:
            return 0
        write_all()
        print(f"{', '.join(stale)} regenerated", file=sys.stderr)
        return 1
    sys.stdout.write(payload if mode == "--json" else markdown)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
