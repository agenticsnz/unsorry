"""Generate the queued-proofs board (ADR-066 / SPEC-066-A).

A view of the proofs **submitted to the queue but not yet merged** — the
``queued/prove/<goal>/<agent>-<hex>`` branches produced by ``--prove`` agents in
``UNSORRY_SUBMIT_MODE=queue`` (ADR-058) — grouped by **solver**, in the shared
docs UX (ADR-038). Unlike the leaderboard / proof-graph / targets generators, the
data source is **git refs**, not the ``main`` working tree: the queue lives on
ephemeral branches that fill and drain without any push to ``main``. The generator
reads those refs (degrading to empty outside a checkout, like the proof graph's
``git_provenance``), resolves each submission's solver from the ``⟦Π:Provenance⟧``
of the index entry the branch adds (the leaderboard's precedence — explicit
``solver≜`` wins, else the commit's git author via ``contributor-aliases.json``),
excludes goals already proved on ``main`` (ADR-064), and labels each submission
``waiting`` or ``in-flight`` from the open prove-PR head refs the workflow supplies.

Usage::

    python3 -m tools.queue_board [<repo-root>]                       # JSON to stdout
    python3 -m tools.queue_board --json [<repo-root>]                # board model
    python3 -m tools.queue_board --html [<repo-root>]                # standalone HTML
    python3 -m tools.queue_board --write [<repo-root>]              # write docs/queue.*
    python3 -m tools.queue_board --check [<repo-root>]              # CI drift check
    python3 -m tools.queue_board --write --open-prs <file> <root>   # label in-flight
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from dataclasses import dataclass
from html import escape as _html_escape
from pathlib import Path

from tools.leaderboard.generate import (
    GitAuthor,
    _alias_for,
    _profile_url,
    _valid_github_handle,
    contributor_aliases,
)
from tools.leaderboard.generate import proofs as _proofs
from tools.site_nav import render_nav

#: GitHub blob base for goal click-through links (goal statements live on ``main``).
BLOB_BASE = "https://github.com/agenticsnz/unsorry/blob/main"

#: Output filenames under ``docs/`` (HTML for the browser, JSON for machines).
HTML_NAME = "queue.html"
JSON_NAME = "queue.json"

_QUEUE_PREFIX = "queued/prove/"
_REF_PREFIXES = ("refs/heads/", "refs/remotes/origin/")


@dataclass(frozen=True)
class Submission:
    """One queued proof: its goal, branch, and resolved solver identity."""

    goal: str
    branch: str  # the ``queued/prove/<goal>/<suffix>`` shortname
    sha: str
    model: str | None
    date: str | None
    solver_key: str  # grouping bucket: github handle, raw solver, or "unknown"
    solver_display: str  # "@handle" / raw name / "unknown"
    github: str | None


# ── Pure parsers ────────────────────────────────────────────────────────────


def branch_shortname(refname: str) -> str:
    """Strip ``refs/heads/`` or ``refs/remotes/origin/`` → the branch name."""
    for prefix in _REF_PREFIXES:
        if refname.startswith(prefix):
            return refname[len(prefix):]
    return refname


def parse_ref(shortname: str) -> tuple[str, str] | None:
    """``queued/prove/<goal>/<suffix>`` → ``(goal, suffix)``; ``None`` otherwise.

    The goal is the single path segment after ``queued/prove/``; the suffix is the
    final segment (``<agent>-<hex>``). Refs that do not match the shape are skipped.
    """
    if not shortname.startswith(_QUEUE_PREFIX):
        return None
    parts = shortname[len(_QUEUE_PREFIX):].split("/")
    if len(parts) < 2 or not parts[0] or not parts[-1]:
        return None
    return parts[0], "/".join(parts[1:])


def _field(text: str, key: str) -> str | None:
    """The value of an AISP ``key≜value`` field within ``text`` (or ``None``)."""
    match = re.search(key + r"≜([^;}\s]+)", text)
    return match.group(1) if match else None


def solver_from_index_diff(diff_text: str) -> tuple[str | None, str | None]:
    """``(solver, model)`` from the ``+`` (added) lines of a ``library/index`` diff."""
    added = "\n".join(
        line[1:]
        for line in diff_text.splitlines()
        if line.startswith("+") and not line.startswith("+++")
    )
    return _field(added, "solver"), _field(added, "model")


# ── Git IO (best-effort; degrades to empty outside a checkout) ───────────────


def _git(root: Path, *args: str) -> str | None:
    try:
        proc = subprocess.run(
            ["git", "-C", str(root), *args],
            capture_output=True,
            text=True,
            check=False,
        )
    except (OSError, ValueError):
        return None
    return proc.stdout if proc.returncode == 0 else None


def queued_ref_lines(root: Path) -> list[str]:
    """``<refname> <short-sha> <committer-date>`` lines for every queued branch."""
    out = _git(
        root,
        "for-each-ref",
        "--format=%(refname) %(objectname:short) %(committerdate:short)",
        "refs/heads/queued/prove/",
        "refs/remotes/origin/queued/prove/",
    )
    return out.splitlines() if out else []


def _author(root: Path, refname: str) -> GitAuthor | None:
    out = _git(root, "log", "-1", "--format=%an%x1f%ae", refname)
    if not out:
        return None
    name, _, email = out.strip().partition("\x1f")
    return GitAuthor(commit="", name=name, email=email, date="")


def _resolve_identity(
    solver_raw: str | None,
    author: GitAuthor | None,
    aliases: dict[str, dict[str, str]],
) -> tuple[str, str, str | None]:
    """``(bucket_key, display, github)`` from the index solver, else git author.

    Mirrors the leaderboard's precedence (ADR-023/ADR-037): an explicit, valid
    ``solver≜`` handle wins; a non-handle ``solver≜`` is kept verbatim; otherwise
    the branch commit's git author is mapped through ``contributor-aliases.json``.
    The branch's ``<agent>`` segment is never used (a ``reroute-*`` bot is not the
    solver).
    """
    github = _valid_github_handle(solver_raw) if solver_raw else None
    if github:
        return github, f"@{github}", github
    if solver_raw:
        return solver_raw, solver_raw, None
    display, mapped = _alias_for(aliases, author)
    if mapped:
        return mapped, f"@{mapped}", mapped
    if display:
        return f"name:{display}", display, None
    return "unknown", "unknown", None


def collect_submissions(
    root: Path, aliases: dict[str, dict[str, str]]
) -> list[Submission]:
    """Every queued submission, deduped by branch, with its solver resolved."""
    seen: set[str] = set()
    submissions: list[Submission] = []
    for line in queued_ref_lines(root):
        tokens = line.split()
        if len(tokens) < 2:
            continue
        refname, sha = tokens[0], tokens[1]
        date = tokens[2] if len(tokens) >= 3 else None
        short = branch_shortname(refname)
        parsed = parse_ref(short)
        if parsed is None or short in seen:
            continue
        seen.add(short)
        goal, _suffix = parsed
        diff = _git(root, "diff", f"HEAD...{refname}", "--", "library/index/") or ""
        solver_raw, model = solver_from_index_diff(diff)
        author = None if solver_raw else _author(root, refname)
        key, display, github = _resolve_identity(solver_raw, author, aliases)
        submissions.append(
            Submission(
                goal=goal,
                branch=short,
                sha=sha,
                model=model,
                date=date,
                solver_key=key,
                solver_display=display,
                github=github,
            )
        )
    return submissions


# ── Board model (pure) ──────────────────────────────────────────────────────


def build_board(
    submissions: list[Submission],
    *,
    proved_goals: set[str],
    open_pr_branches: set[str] | None,
    pr_status_known: bool,
) -> dict:
    """Group submissions by solver, excluding already-proved goals, labelling state."""
    proved = set(proved_goals or ())
    open_set = set(open_pr_branches or ())
    groups: dict[str, dict] = {}
    for sub in submissions:
        if sub.goal in proved:
            continue
        state = "in-flight" if (pr_status_known and sub.branch in open_set) else "waiting"
        group = groups.get(sub.solver_key)
        if group is None:
            group = groups[sub.solver_key] = {
                "github": sub.github,
                "display_name": sub.solver_display,
                "queued": [],
            }
        group["queued"].append(
            {
                "goal": sub.goal,
                "branch": sub.branch,
                "sha": sub.sha,
                "model": sub.model,
                "date": sub.date,
                "state": state,
            }
        )

    solvers: list[dict] = []
    for group in groups.values():
        rows = sorted(group["queued"], key=lambda r: (r["goal"], r["branch"]))
        solvers.append(
            {
                "solver": group["github"],
                "github": group["github"],
                "display_name": group["display_name"],
                "profile_url": _profile_url(group["github"]),
                "submissions": len(rows),
                "waiting": sum(1 for r in rows if r["state"] == "waiting"),
                "in_flight": sum(1 for r in rows if r["state"] == "in-flight"),
                "distinct_goals": len({r["goal"] for r in rows}),
                "queued": rows,
            }
        )
    solvers.sort(
        key=lambda r: (
            -r["submissions"],
            -r["distinct_goals"],
            (r["display_name"] or "").lower(),
        )
    )
    return {
        "schema_version": 1,
        "source": "queued/prove/* refs + library/index provenance",
        "pr_status_known": pr_status_known,
        "summary": {
            "queued_submissions": sum(r["submissions"] for r in solvers),
            "waiting": sum(r["waiting"] for r in solvers),
            "in_flight": sum(r["in_flight"] for r in solvers),
            "distinct_goals": len(
                {sub["goal"] for r in solvers for sub in r["queued"]}
            ),
            "solvers": len(solvers),
        },
        "solvers": solvers,
    }


def board_for(root: Path, open_pr_branches: set[str] | None = None) -> dict:
    """Assemble the board for ``root``; PR status is known iff head refs are given."""
    aliases = contributor_aliases(root)
    proved = {proof.goal for proof in _proofs(root)}
    submissions = collect_submissions(root, aliases)
    return build_board(
        submissions,
        proved_goals=proved,
        open_pr_branches=open_pr_branches,
        pr_status_known=open_pr_branches is not None,
    )


# ── Rendering ───────────────────────────────────────────────────────────────


def render_json(board: dict) -> str:
    return json.dumps(board, indent=2, ensure_ascii=False) + "\n"


def _esc(value: object) -> str:
    return "" if value is None else _html_escape(str(value))


def _chip(count: int, label: str) -> str:
    return (
        '<span class="inline-flex items-center bg-white border border-slate-200 '
        'text-slate-600 px-3 py-1.5 rounded-xl text-sm font-medium">'
        f'<b class="mr-1 text-slate-800">{count}</b>{label}</span>'
    )


def _chips(board: dict) -> str:
    summary = board["summary"]
    chips = [_chip(summary["queued_submissions"], "queued")]
    if board["pr_status_known"]:
        chips.append(_chip(summary["waiting"], "waiting"))
        chips.append(_chip(summary["in_flight"], "in-flight"))
    chips.append(_chip(summary["distinct_goals"], "goals"))
    chips.append(_chip(summary["solvers"], "solvers"))
    return "\n".join(chips)


def _note(board: dict) -> str:
    note = (
        "This board lists proofs submitted to the queue but not yet merged, grouped "
        "by solver (biggest queue first). Tap a solver to see their queued proofs. "
        "It is regenerated on a schedule, so it reflects the queue as of the last "
        "refresh."
    )
    if not board["pr_status_known"]:
        note += (
            " PR status was unavailable this run, so every submission is shown as "
            "<em>waiting</em>."
        )
    return note


def _sections(board: dict) -> str:
    if not board["solvers"]:
        return (
            '<div class="state-panel">The queue is empty — no submitted proofs are '
            "waiting to be processed.</div>"
        )
    out: list[str] = []
    # Solvers arrive ranked biggest-queue-first (build_board). Each is a
    # collapsed-by-default <details>: the summary shows the solver and their queue
    # size; tapping it reveals the submission table (ADR-066) — so the page opens
    # as a short, scannable list of solver names rather than hundreds of rows.
    for solver in board["solvers"]:
        name = _esc(solver["display_name"])
        if solver.get("github") and solver.get("profile_url"):
            profile = (
                f' · <a class="lnk" href="{_esc(solver["profile_url"])}">'
                f"{name} on GitHub ↗</a>"
            )
        else:
            profile = ""
        meta = (
            f'{solver["waiting"]} waiting · {solver["in_flight"]} in-flight · '
            f'{solver["distinct_goals"]} goals{profile}'
        )
        rows = []
        for row in solver["queued"]:
            badge = "in-flight" if row["state"] == "in-flight" else "waiting"
            rows.append(
                "<tr>"
                f'<td><a class="lnk" href="{BLOB_BASE}/goals/{_esc(row["goal"])}.lean">'
                f'<code>{_esc(row["goal"])}</code></a></td>'
                f'<td><code>{_esc(row["branch"])}</code></td>'
                f'<td>{_esc(row["model"]) or "—"}</td>'
                f'<td>{_esc(row["date"]) or "—"}</td>'
                f'<td><span class="badge {badge}">{badge}</span></td>'
                "</tr>"
            )
        out.append(
            '<details class="qd mb-2 rounded-xl border border-slate-200 bg-white">'
            '<summary class="flex items-center justify-between gap-3 cursor-pointer '
            'select-none px-4 py-3 rounded-xl hover:bg-slate-50">'
            '<span class="flex items-center gap-2 min-w-0">'
            '<span class="caret text-slate-400 transition-transform" aria-hidden="true">▸</span>'
            f'<span class="font-semibold text-slate-800 truncate">{name}</span>'
            "</span>"
            '<span class="text-xs font-medium text-slate-500 whitespace-nowrap flex-shrink-0">'
            f'{solver["submissions"]} queued</span>'
            "</summary>"
            '<div class="px-4 pb-4">'
            f'<p class="text-xs text-slate-500 mb-2">{meta}</p>'
            '<div class="overflow-x-auto rounded-xl border border-slate-100">'
            '<table class="q"><thead><tr><th>Goal</th><th>Branch</th><th>Model</th>'
            "<th>Submitted</th><th>State</th></tr></thead>"
            f'<tbody>{"".join(rows)}</tbody></table></div>'
            "</div>"
            "</details>"
        )
    return "\n".join(out)


_TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Unsorry — queue</title>
<!-- GENERATED by `python3 -m tools.queue_board --write`. Do not edit by hand. -->
<!-- Shares the leaderboard design language (ADR-038): Tailwind + Inter, brand
     palette, centred white card. -->
<script src="https://cdn.tailwindcss.com"></script>
<script>
  tailwind.config = {
    theme: {
      extend: {
        colors: {
          brand: {
            50: '#f0fdfa', 100: '#ccfbf1', blue: '#e0f2fe',
            text: '#334155', muted: '#64748b'
          }
        },
        fontFamily: {
          sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'Helvetica Neue', 'Arial', 'sans-serif'],
        }
      }
    }
  }
</script>
<style>
  body { background-color:#fafbfc; -webkit-font-smoothing:antialiased; }
  .badge { display:inline-flex; align-items:center; padding:.1rem .6rem; border-radius:999px; font-size:.78rem; font-weight:600; border:1px solid #cbd5e1; color:#334155; }
  .badge.waiting { background:#e2e8f0; }
  .badge.in-flight { background:#bee3f8; }
  .state-panel { border:1px dashed #cbd5e1; border-radius:14px; padding:18px; color:#64748b; background:#f8fafc; font-size:.9rem; }
  table.q { border-collapse:collapse; width:100%; }
  table.q th, table.q td { text-align:left; padding:.5rem .7rem; border-bottom:1px solid #e2e8f0; font-size:.875rem; white-space:nowrap; }
  table.q th { background:#f8fafc; color:#64748b; font-weight:600; text-transform:uppercase; letter-spacing:.03em; font-size:.72rem; }
  code { background:#f1f5f9; padding:0 .3rem; border-radius:4px; font-size:.85em; }
  a.lnk { color:#0369a1; text-decoration:none; } a.lnk:hover { text-decoration:underline; }
  /* Collapsible per-solver sections (collapsed by default): hide the native
     disclosure marker and use a caret that rotates when open. */
  details.qd > summary { list-style:none; }
  details.qd > summary::-webkit-details-marker { display:none; }
  details.qd[open] > summary .caret { transform:rotate(90deg); }
</style>
</head>
<body class="font-sans text-brand-text p-4 md:p-8 flex justify-center items-start min-h-screen">
<main class="w-full max-w-6xl bg-white rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-100 overflow-hidden">

__NAV__

  <header class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 px-6 md:px-10 py-6 md:py-8 border-b border-slate-100">
    <div class="flex flex-col">
      <h1 class="text-5xl md:text-7xl font-bold text-slate-200 tracking-tighter leading-none mb-2">Unsorry</h1>
      <div class="inline-flex items-center bg-slate-100 rounded-full px-4 py-1 text-xs font-semibold text-slate-600 uppercase tracking-wider w-max">
        Queue · __COUNT__ submitted
      </div>
    </div>
    <div class="flex flex-wrap gap-2">
__CHIPS__
    </div>
  </header>

  <section class="px-6 md:px-10 py-6 md:py-8">
    <p class="text-sm text-slate-500 leading-relaxed mb-6 max-w-3xl">__NOTE__</p>
__SECTIONS__
  </section>

</main>
<script type="application/json" id="queue-data">__DATA__</script>
</body>
</html>
"""


def render_html(board: dict) -> str:
    """A standalone page: shared nav (Queue current), summary chips, per-solver tables."""
    return (
        _TEMPLATE.replace("__NAV__", render_nav("queue.html"))
        .replace("__COUNT__", str(board["summary"]["queued_submissions"]))
        .replace("__CHIPS__", _chips(board))
        .replace("__NOTE__", _note(board))
        .replace("__SECTIONS__", _sections(board))
        .replace("__DATA__", json.dumps(board, ensure_ascii=False))
    )


# ── CLI ─────────────────────────────────────────────────────────────────────


def _read_open_prs(path: str) -> set[str]:
    file = Path(path)
    if not file.is_file():
        return set()
    return {
        line.strip()
        for line in file.read_text(encoding="utf-8").splitlines()
        if line.strip()
    }


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    flags = ("--check", "--write", "--json", "--html")
    modes = [flag for flag in flags if flag in argv]
    if len(modes) > 1:
        print(f"{', '.join(flags)} are mutually exclusive", file=sys.stderr)
        return 2
    mode = modes[0] if modes else None

    open_pr_branches: set[str] | None = None
    if "--open-prs" in argv:
        index = argv.index("--open-prs")
        if index + 1 >= len(argv):
            print("--open-prs needs a file path", file=sys.stderr)
            return 2
        open_pr_branches = _read_open_prs(argv[index + 1])
        del argv[index : index + 2]

    rest = [arg for arg in argv if arg not in flags]
    root = Path(rest[0]) if rest else Path(".")
    board = board_for(root, open_pr_branches)

    if mode == "--json":
        sys.stdout.write(render_json(board))
        return 0
    if mode == "--html":
        sys.stdout.write(render_html(board))
        return 0

    artifacts = [
        (root / "docs" / HTML_NAME, render_html(board)),
        (root / "docs" / JSON_NAME, render_json(board)),
    ]
    if mode == "--write":
        for target, content in artifacts:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8")
        return 0
    if mode == "--check":
        stale = [
            str(target)
            for target, content in artifacts
            if (target.read_text(encoding="utf-8") if target.exists() else "") != content
        ]
        if stale:
            print(
                f"{', '.join(stale)} stale; regenerate with "
                "`python3 -m tools.queue_board --write`",
                file=sys.stderr,
            )
            return 1
        return 0

    sys.stdout.write(render_json(board))
    return 0
