"""Queued-proofs board tests (ADR-066 / SPEC-066-A).

Pure unit tests over constructed submissions + canned git text, plus one
hermetic git-integration test that builds a real repo with ``queued/prove/*``
branches. No network.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
from pathlib import Path

import pytest

from tools.queue_board.generate import (
    Submission,
    branch_shortname,
    build_board,
    main,
    parse_ref,
    render_html,
    render_json,
    solver_from_index_diff,
)


# ── Pure parsers ────────────────────────────────────────────────────────────


def test_parse_ref():
    assert parse_ref("queued/prove/dvd-120-pow/mac-158f-31571d") == (
        "dvd-120-pow",
        "mac-158f-31571d",
    )
    assert parse_ref("queued/prove/g/reroute-a9e750") == ("g", "reroute-a9e750")
    # Not a queued/prove ref, or missing the suffix segment → ignored.
    assert parse_ref("queued/prove/lonely") is None
    assert parse_ref("feature/whatever") is None


def test_branch_shortname():
    assert branch_shortname("refs/heads/queued/prove/g/x") == "queued/prove/g/x"
    assert (
        branch_shortname("refs/remotes/origin/queued/prove/g/x") == "queued/prove/g/x"
    )
    assert branch_shortname("queued/prove/g/x") == "queued/prove/g/x"


def test_solver_from_index_diff():
    diff = (
        "diff --git a/library/index/abc.aisp b/library/index/abc.aisp\n"
        "new file mode 100644\n"
        "--- /dev/null\n"
        "+++ b/library/index/abc.aisp\n"
        "+𝔸5.1.lemma.g@2026-06-17\n"
        "+⟦Π:Provenance⟧{solver≜ruvnet; provider≜claude; model≜opus}\n"
    )
    assert solver_from_index_diff(diff) == ("ruvnet", "opus")
    # Removed/context lines are ignored; absence yields (None, None).
    assert solver_from_index_diff("-⟦Π:Provenance⟧{solver≜ghost}\n x") == (None, None)
    assert solver_from_index_diff("") == (None, None)


# ── build_board (pure) ──────────────────────────────────────────────────────


def _sub(goal, branch, key, display, *, github=None, model="opus"):
    return Submission(
        goal=goal,
        branch=branch,
        sha="abc1234",
        model=model,
        date="2026-06-17",
        solver_key=key,
        solver_display=display,
        github=github,
    )


def _subs():
    return [
        _sub("g1", "queued/prove/g1/a-1", "ruvnet", "@ruvnet", github="ruvnet"),
        _sub("g2", "queued/prove/g2/a-2", "ruvnet", "@ruvnet", github="ruvnet"),
        _sub("g3", "queued/prove/g3/b-1", "macbook", "macbook"),
    ]


def test_build_board_groups_ranks_and_links():
    board = build_board(
        _subs(), proved_goals=set(), open_pr_branches=None, pr_status_known=False
    )
    assert board["pr_status_known"] is False
    assert board["summary"]["queued_submissions"] == 3
    assert board["summary"]["solvers"] == 2
    assert board["summary"]["distinct_goals"] == 3
    top = board["solvers"][0]  # ranked by submissions desc
    assert top["github"] == "ruvnet" and top["submissions"] == 2
    assert top["profile_url"] == "https://github.com/ruvnet"
    assert top["distinct_goals"] == 2
    # No PR knowledge → every submission waiting.
    assert all(r["state"] == "waiting" for s in board["solvers"] for r in s["queued"])
    assert board["summary"]["in_flight"] == 0


def test_build_board_excludes_proved_goals():
    board = build_board(
        _subs(), proved_goals={"g1"}, open_pr_branches=None, pr_status_known=False
    )
    goals = {r["goal"] for s in board["solvers"] for r in s["queued"]}
    assert goals == {"g2", "g3"}
    assert board["summary"]["queued_submissions"] == 2


def test_build_board_waiting_vs_in_flight():
    board = build_board(
        _subs(),
        proved_goals=set(),
        open_pr_branches={"queued/prove/g1/a-1"},
        pr_status_known=True,
    )
    assert board["pr_status_known"] is True
    assert board["summary"]["in_flight"] == 1
    assert board["summary"]["waiting"] == 2
    states = {
        r["goal"]: r["state"] for s in board["solvers"] for r in s["queued"]
    }
    assert states["g1"] == "in-flight" and states["g2"] == "waiting"


def test_build_board_distinct_goals_dedup():
    subs = [
        _sub("g1", "queued/prove/g1/a-1", "ruvnet", "@ruvnet", github="ruvnet"),
        _sub("g1", "queued/prove/g1/a-2", "ruvnet", "@ruvnet", github="ruvnet"),
    ]
    board = build_board(
        subs, proved_goals=set(), open_pr_branches=None, pr_status_known=False
    )
    solver = board["solvers"][0]
    assert solver["submissions"] == 2 and solver["distinct_goals"] == 1


def test_build_board_unknown_bucket():
    subs = [_sub("g", "queued/prove/g/x", "unknown", "unknown")]
    board = build_board(
        subs, proved_goals=set(), open_pr_branches=None, pr_status_known=False
    )
    assert board["solvers"][0]["display_name"] == "unknown"
    assert board["solvers"][0]["github"] is None


# ── Rendering ───────────────────────────────────────────────────────────────


def test_render_json_shape():
    payload = json.loads(render_json(build_board(
        _subs(), proved_goals=set(), open_pr_branches=None, pr_status_known=False
    )))
    assert payload["schema_version"] == 1
    assert "queued/prove" in payload["source"]
    assert payload["summary"]["solvers"] == 2


def test_render_html_shares_nav_and_design():
    html = render_html(build_board(
        _subs(),
        proved_goals=set(),
        open_pr_branches={"queued/prove/g1/a-1"},
        pr_status_known=True,
    ))
    assert html.startswith("<!doctype html>")
    # Shared top-nav with Queue current and the other three pages present.
    assert 'href="queue.html" aria-current="page"' in html
    assert 'href="index.html"' in html and 'href="leaderboard.html"' in html
    assert 'href="proofs-contributors-visualisation.html"' in html
    # Shared design language (ADR-038).
    assert "cdn.tailwindcss.com" in html and "Inter" in html and ">Unsorry<" in html
    assert 'name="viewport"' in html
    # Solver sections + state badges + summary chips.
    assert "@ruvnet" in html and "macbook" in html
    assert "in-flight" in html and "waiting" in html
    assert "queued" in html
    # Embedded model + no unreplaced placeholders.
    assert '<script type="application/json" id="queue-data">' in html
    assert re.search(r"__[A-Z]+__", html) is None


def test_render_html_empty_state():
    html = render_html(build_board(
        [], proved_goals=set(), open_pr_branches=None, pr_status_known=False
    ))
    assert "queue is empty" in html.lower()
    assert re.search(r"__[A-Z]+__", html) is None


def test_render_html_solvers_collapsed_by_default():
    html = render_html(build_board(
        _subs(), proved_goals=set(), open_pr_branches=None, pr_status_known=False
    ))
    # Each solver is a collapsible section, collapsed by default (no `open` attr),
    # with the solver name in the tap target (summary).
    assert "<details" in html and "<summary" in html
    assert "<details open" not in html
    assert "@ruvnet" in html


def test_render_html_sorted_biggest_queue_first():
    html = render_html(build_board(
        _subs(), proved_goals=set(), open_pr_branches=None, pr_status_known=False
    ))
    # ruvnet (2 submissions) ranks before macbook (1).
    assert html.index("@ruvnet") < html.index("macbook")


def test_render_html_no_adr_058_mention():
    html = render_html(build_board(
        _subs(), proved_goals=set(), open_pr_branches=None, pr_status_known=False
    ))
    assert "ADR-058" not in html


def test_main_modes_mutually_exclusive(tmp_path):
    assert main(["--json", "--html", str(tmp_path)]) == 2


# ── Hermetic git integration ────────────────────────────────────────────────

_ENV = {
    **os.environ,
    "GIT_CONFIG_GLOBAL": os.devnull,
    "GIT_CONFIG_SYSTEM": os.devnull,
    "GIT_AUTHOR_NAME": "swarm",
    "GIT_AUTHOR_EMAIL": "swarm@unsorry",
    "GIT_COMMITTER_NAME": "swarm",
    "GIT_COMMITTER_EMAIL": "swarm@unsorry",
}


def _git(root: Path, *args: str, env: dict | None = None) -> None:
    subprocess.run(
        ["git", "-C", str(root), *args],
        check=True,
        capture_output=True,
        text=True,
        env={**_ENV, **(env or {})},
    )


def _index(root: Path, fname: str, *, goal: str, solver: str | None, model: str) -> None:
    (root / "library" / "index").mkdir(parents=True, exist_ok=True)
    prov = (
        f"⟦Π:Provenance⟧{{solver≜{solver}; provider≜claude; model≜{model}}}\n"
        if solver
        else ""
    )
    (root / "library" / "index" / f"{fname}.aisp").write_text(
        f"𝔸5.1.lemma.{goal}@2026-06-17\n"
        "γ≔unsorry.lemma.index\n"
        f"⟦Ω:Lemma⟧{{sha≜{'0' * 64}; goal≜{goal}; name≜{goal.replace('-', '_')}}}\n"
        f"{prov}"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        encoding="utf-8",
    )


def _queued(root: Path, goal: str, suffix: str, *, solver, model="opus", author=None):
    branch = f"queued/prove/{goal}/{suffix}"
    _git(root, "checkout", "-q", "-b", branch)
    _index(root, f"{goal}-{suffix}", goal=goal, solver=solver, model=model)
    _git(root, "add", "-A")
    env = (
        {"GIT_AUTHOR_NAME": author[0], "GIT_AUTHOR_EMAIL": author[1]}
        if author
        else None
    )
    _git(root, "commit", "-q", "-m", f"prove({goal})", env=env)
    _git(root, "checkout", "-q", "main")


def _repo(tmp_path: Path) -> Path:
    root = tmp_path
    subprocess.run(
        ["git", "init", "-q", "-b", "main", str(root)],
        check=True, capture_output=True, text=True, env=_ENV,
    )
    # Alias file (read from the working tree = main) for the author-fallback path.
    (root / "docs" / "metrics").mkdir(parents=True, exist_ok=True)
    (root / "docs" / "metrics" / "contributor-aliases.json").write_text(
        json.dumps({
            "schema_version": 1,
            "git_authors": {
                "Alice H <alice@h>": {"display_name": "Alice H", "github": "aliceh"}
            },
        }),
        encoding="utf-8",
    )
    # main: one already-proved goal (its index marker lives on main).
    _index(root, "proved-marker", goal="already-proved", solver="someone", model="opus")
    _git(root, "add", "-A")
    _git(root, "commit", "-q", "-m", "seed main")
    # Queued branches.
    _queued(root, "dvd-1", "mac-158f-aaaaaa", solver="ruvnet")
    # reroute branch: committed by a bot, but the index credits ruvnet — the
    # board must attribute the index solver, not the committer.
    _queued(root, "dvd-2", "reroute-bbbbbb", solver="ruvnet", model="sonnet",
            author=("reroute-bot", "bot@reroute"))
    # already-proved goal in the queue → excluded by the proved-on-main filter.
    _queued(root, "already-proved", "mac-158f-cccccc", solver="ruvnet")
    # No index solver → attributed via git author + contributor alias.
    _queued(root, "dvd-3", "host-dddddd", solver=None, author=("Alice H", "alice@h"))
    return root


def test_integration_write_check_and_attribution(tmp_path):
    root = _repo(tmp_path)
    assert main(["--write", str(root)]) == 0
    payload = json.loads((root / "docs" / "queue.json").read_text(encoding="utf-8"))
    assert (root / "docs" / "queue.html").exists()

    goals = {r["goal"] for s in payload["solvers"] for r in s["queued"]}
    assert goals == {"dvd-1", "dvd-2", "dvd-3"}  # already-proved excluded

    by_handle = {s["github"]: s for s in payload["solvers"]}
    # reroute branch credited to the index solver (ruvnet), not the committer.
    assert by_handle["ruvnet"]["submissions"] == 2
    assert {r["goal"] for r in by_handle["ruvnet"]["queued"]} == {"dvd-1", "dvd-2"}
    # No-solver branch credited via git author → alias handle.
    assert by_handle["aliceh"]["submissions"] == 1

    # Freshly written → check is clean; a new queued branch reddens it.
    assert main(["--check", str(root)]) == 0
    _queued(root, "dvd-4", "mac-158f-eeeeee", solver="ruvnet")
    assert main(["--check", str(root)]) == 1


def test_integration_open_prs_label_in_flight(tmp_path):
    root = _repo(tmp_path)
    prs = root / "open-prs.txt"
    prs.write_text("queued/prove/dvd-1/mac-158f-aaaaaa\n", encoding="utf-8")
    assert main(["--write", "--open-prs", str(prs), str(root)]) == 0
    payload = json.loads((root / "docs" / "queue.json").read_text(encoding="utf-8"))
    assert payload["pr_status_known"] is True
    states = {r["goal"]: r["state"] for s in payload["solvers"] for r in s["queued"]}
    assert states["dvd-1"] == "in-flight"
    assert states["dvd-2"] == "waiting"
