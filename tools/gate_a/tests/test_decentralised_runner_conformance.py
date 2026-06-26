"""SPEC-049-A §5 conformance: the decentralised CI runner soundness invariant.

ADR-049 / SPEC-049-A push the expensive *elaboration* onto the untrusted
contributor (which ``swarm/agent.sh::prove_local_verify()`` already runs) and
keep a mandatory, cheap, **central** re-check as the *sole* load-bearing
soundness gate. The load-bearing invariant (SPEC-049-A §2) is a NEGATIVE one:

    the central re-check MUST NOT consume any contributor-supplied compiled
    artifact (``.olean``, exported term, hash, or manifest field) as a
    *trusted* input — it re-derives the statement from canonical goal source
    and re-elaborates the changed closure from source, then runs leanchecker /
    axiom audit / statement-binding over *that*.

The substantive scoping logic already exists (ADR-033 incremental replay/audit
in :mod:`tools.gate_a.parallel_modules`; ADR-045 olean cache), so these tests do
not re-implement it. They LOCK IN the soundness invariant as a regression guard
so a future "just leanchecker the client's olean" optimisation cannot silently
regress it — the two unsound classes ADR-049 §4 names: (i) crafted structurally
invalid oleans and (ii) real, type-correct proofs of a weaker/renamed statement
(the PR-#64 vacuity class). This is the Phase-0 deliverable in SPEC-049-A §6 —
the suite that must exist *before* any Phase-1 change narrows the central build.

Conformance-item references below point at SPEC-049-A §5 (and the §2 invariant).
Forward-looking items that depend on not-yet-built Phase-1 machinery are marked
xfail/skip rather than left failing: this repo gates merges on green CI, so an
"authored red" placeholder lands as an expected-failure marker that flips to
xpass when Phase 1 implements it.
"""
from __future__ import annotations

import re
import subprocess
from pathlib import Path

import pytest

from tools.gate_a.parallel_modules import (
    FULL_REPLAY_PATHS,
    audit_shard,
    compute_audit_targets,
    forces_full_replay,
    import_graph,
    module_names,
    replay,
    replay_scope,
    scoped_targets,
)

# tools/gate_a/tests/<this file>  ->  parents[3] is the repo root.
REPO_ROOT = Path(__file__).resolve().parents[3]
GATE_A_WORKFLOW = REPO_ROOT / ".github" / "workflows" / "gate-a.yml"

# A trusted replay target is a dotted Lean module name (Unsorry.Foo[.Bar]) drawn
# from the locally-rebuilt library tree — never a filesystem path or an olean.
_MODULE_NAME_RE = re.compile(r"^Unsorry(\.[A-Za-z0-9_]+)+$")


def completed(
    argv, returncode: int = 0, stdout: str = "", stderr: str = ""
) -> subprocess.CompletedProcess[str]:
    return subprocess.CompletedProcess(tuple(argv), returncode, stdout, stderr)


def _write_lib(tmp_path: Path, modules: dict[str, list[str]]) -> None:
    """modules: {name: [imported Unsorry module names]} — mirrors the helper in
    test_parallel_modules.py so the closure semantics are exercised identically."""
    d = tmp_path / "library" / "Unsorry"
    d.mkdir(parents=True, exist_ok=True)
    for name, imports in modules.items():
        body = "".join(f"import Unsorry.{imp}\n" for imp in imports)
        (d / f"{name}.lean").write_text(body + "theorem t : True := trivial\n")


def _diff_runner(changed_stdout: str, git_rc: int = 0):
    """A runner that answers `git diff --name-only` with changed_stdout."""

    def runner(argv, **_kwargs):
        argv = tuple(argv)
        if argv[0] == "git" and "diff" in argv:
            return completed(argv, returncode=git_rc, stdout=changed_stdout)
        return completed(argv)

    return runner


def _replay_leanchecker_calls(
    tmp_path: Path, changed_stdout: str, *, base: str = "origin/main", git_rc: int = 0
) -> list[tuple[str, ...]]:
    """Run replay() against a mock runner and return the argv tuples that reached
    leanchecker."""
    calls: list[tuple[str, ...]] = []

    def runner(argv, **_kwargs):
        argv = tuple(argv)
        if argv[0] == "git" and "diff" in argv:
            return completed(argv, returncode=git_rc, stdout=changed_stdout)
        if argv[:3] == ("lake", "env", "leanchecker"):
            calls.append(argv)
        return completed(argv)

    assert replay(tmp_path, 1, runner, base=base) == 0
    return calls


def _workflow_text() -> str:
    assert GATE_A_WORKFLOW.is_file(), f"missing Gate A workflow at {GATE_A_WORKFLOW}"
    return GATE_A_WORKFLOW.read_text(encoding="utf-8")


# --- §2 / §5.1(c): no contributor-supplied artifact is a trusted input -------


def test_leanchecker_receives_only_local_module_names_never_artifacts(tmp_path: Path):
    """SPEC-049-A §2 / §5.1(c). The central kernel re-check feeds leanchecker only
    module names derived from the locally-rebuilt library tree — never a
    contributor-supplied artifact (a ``.olean``/``.lean`` path or anything with a
    path separator would mean trusting a client artifact)."""
    _write_lib(tmp_path, {"A": [], "B": ["A"], "ABinding": ["A"]})
    local_modules = set(module_names(tmp_path, "library"))
    calls = _replay_leanchecker_calls(tmp_path, "library/Unsorry/A.lean\n")

    targets = [t for call in calls for t in call[3:]]
    assert targets, "a changed module must produce a non-empty replay set"
    for t in targets:
        assert _MODULE_NAME_RE.match(t), f"non-module-name target reached leanchecker: {t!r}"
        assert not t.endswith((".olean", ".lean")), f"artifact path reached leanchecker: {t!r}"
        assert "/" not in t and "\\" not in t, f"path-like target reached leanchecker: {t!r}"
        assert t in local_modules, f"target {t!r} is not a locally-derived library module"


def test_audit_shard_feeds_only_local_module_names_never_artifacts(tmp_path: Path):
    """SPEC-049-A §2 / SPEC-091-A §2.3 (ADR-091). A sharded audit leg must feed
    ``axiom_audit`` only module names derived from the locally-rebuilt library/goal
    tree — never a contributor-supplied artifact. No module list crosses a job
    boundary; each shard re-derives its slice from source, so the auditor's inputs
    stay locally-derived even under sharding."""
    _write_lib(tmp_path, {"A": [], "B": ["A"], "ABinding": ["A"]})
    local_modules = set(module_names(tmp_path, "library"))
    audited: list[str] = []

    def runner(argv, **_kwargs):
        argv = tuple(argv)
        if argv[0] == "git" and "diff" in argv:
            return completed(argv, stdout="library/Unsorry/A.lean\n")
        if argv[:3] == ("lake", "exe", "axiom_audit"):
            audited.extend(a for a in argv[3:] if a != "--allow-sorry")
        return completed(argv, stdout="[]")

    assert audit_shard(tmp_path, 0, 1, tmp_path / "shard.json", runner, base="origin/main") == 0
    assert audited, "a changed module must produce a non-empty audit set"
    for target in audited:
        assert not target.endswith((".olean", ".lean")), f"artifact reached the auditor: {target!r}"
        assert "/" not in target and "\\" not in target, f"path-like audit target: {target!r}"
        assert target in local_modules, f"target {target!r} is not a locally-derived module"


def test_audit_shard_untrusted_diff_fails_closed_to_full(tmp_path: Path):
    """SPEC-049-A §2 / SPEC-091-A §2.5. An untrusted diff (git unavailable) makes a
    sharded audit fall back to the FULL scope — never an empty/partial accept."""
    _write_lib(tmp_path, {"A": [], "B": ["A"]})
    full = compute_audit_targets(tmp_path, "deadbeef", _diff_runner("", git_rc=128))
    assert full.mode == "full"
    assert set(full.library) == {"Unsorry.A", "Unsorry.B"}


def test_untrusted_diff_fails_closed_to_full_recheck(tmp_path: Path):
    """SPEC-049-A §2. If the diff cannot be trusted (git unavailable / shallow
    clone missing base), the central re-check falls back to a FULL replay — it is
    never tricked into an empty/partial accept by a broken diff."""
    _write_lib(tmp_path, {"A": [], "B": ["A"]})
    assert scoped_targets(tmp_path, "deadbeef", runner=_diff_runner("", git_rc=128)) is None

    calls = _replay_leanchecker_calls(tmp_path, "", base="deadbeef", git_rc=128)
    replayed = {t for call in calls for t in call[3:]}
    assert replayed == {"Unsorry.A", "Unsorry.B"}  # whole library re-checked


# --- §5.3: scoping never under-scopes (closure + binding + global impact) -----


def test_changed_base_pulls_its_binding_and_importers_into_scope(tmp_path: Path):
    """SPEC-049-A §5.3. Scoping must never under-scope. A changed base module
    drags its generated ADR-011 ``*Binding`` module AND its transitive importers
    into the re-checked set, so a weakened/renamed-statement proof (the PR-#64
    vacuity class) is always re-bound and re-checked centrally."""
    _write_lib(
        tmp_path,
        {"A": [], "B": ["A"], "C": ["B"], "ABinding": ["A"], "Unrel": []},
    )
    scope = set(replay_scope(["Unsorry.A"], import_graph(tmp_path)))
    assert {"Unsorry.A", "Unsorry.ABinding"} <= scope  # binding re-checked
    assert {"Unsorry.B", "Unsorry.C"} <= scope  # transitive reverse-import closure
    assert "Unsorry.Unrel" not in scope  # unrelated module not dragged in


def test_global_impact_change_forces_full_recheck(tmp_path: Path):
    """SPEC-049-A §5.3 / §2.4. A toolchain/lakefile/manifest change invalidates
    every olean, so scoping falls back to a FULL central re-check rather than
    narrowing to the textual diff (which would skip silently-invalidated modules)."""
    _write_lib(tmp_path, {"A": [], "B": ["A"]})
    for offender in sorted(FULL_REPLAY_PATHS):
        assert forces_full_replay([offender]) == offender
        # Even paired with a library edit, the global-impact path wins → full.
        diff = f"{offender}\nlibrary/Unsorry/A.lean\n"
        assert scoped_targets(tmp_path, "origin/main", runner=_diff_runner(diff)) is None


# --- §2: workflow-level structural guards on the central re-check -------------


def test_workflow_feeds_no_uploaded_artifact_into_central_recheck():
    """SPEC-049-A §2. No contributor/external artifact may reach the central build
    or replay. gate-a.yml must not ``download-artifact`` into the gate — the only
    artifact action is the diagnostic axiom-report upload (an output, never an
    input to elaboration/replay)."""
    text = _workflow_text()
    assert "download-artifact" not in text, (
        "gate-a must not pull a downloaded artifact into the central re-check "
        "(SPEC-049-A §2: client artifacts are never trusted inputs)"
    )


def test_workflow_replays_locally_rebuilt_oleans_via_lake_env():
    """SPEC-049-A §2. The kernel replay runs the trusted local path
    (``parallel_modules replay`` → leanchecker under ``lake env`` over the
    locally-rebuilt oleans), preceded by the ``--wfail`` source elaboration —
    not a client-supplied olean."""
    text = _workflow_text()
    assert "tools.gate_a.parallel_modules replay" in text
    assert "lake build UnsorryLibrary --wfail" in text


def test_workflow_regenerates_statement_binding_from_source():
    """SPEC-049-A §2.1. The statement is re-derived from canonical goal source:
    Gate A regenerates the ADR-011 binding obligations rather than trusting a
    contributor-supplied statement, killing the weakened/renamed-statement class."""
    text = _workflow_text()
    assert "check_statement_binding generate" in text


# --- Phase-1 forward conformance (recorded as skipped placeholders) -----------
# SPEC-049-A §6: these items depend on not-yet-built Phase-1 machinery or are
# enforced at the Lean/CI layer rather than in this Python unit suite. They are
# recorded here so the contract is visible and a future implementer has a named
# home for the guard. They are NOT left hard-failing — this repo gates merges on
# green CI — and they deliberately avoid asserting a specific Phase-1 *mechanism*
# (e.g. matching a workflow substring), which would be a fragile false signal.


@pytest.mark.skip(
    reason="SPEC-049-A §5.4 cache provenance: a discrete commit-exact / "
    "toolchain-exact provenance gate on restored dependency oleans is a Phase-1 "
    "deliverable. Today a restored olean's provenance is implicit in the ADR-045 "
    "commit-sha cache key plus Lake content-hash traces; there is no standalone "
    "verifier for this suite to assert against yet."
)
def test_phase1_restored_dependency_olean_has_explicit_provenance_check():
    raise AssertionError("cache-provenance gate is a Phase-1 deliverable; see skip reason")


@pytest.mark.skip(
    reason="SPEC-049-A §5.5 determinism (an unchanged module's olean rebuilds "
    "byte-identically under ADR-002 pinning — the ADR-033 invariant) is enforced "
    "at the Lean/CI layer by the pinned toolchain + Lake lockfile and guarded by "
    "the scheduled gate-a-full-replay backstop, not by this Python unit suite."
)
def test_phase1_unchanged_module_olean_rebuilds_byte_identically():
    raise AssertionError("determinism is a Lean-layer property; see skip reason")


# --- ADR-097 / SPEC-097-A §6: nanoda audit-replacement cutover is wired sound ---

def test_gate_a_aggregator_requires_nanoda_and_keeps_replay_p1():
    """The required `gate-a` aggregator must require gate-a-nanoda AND gate-a-replay
    on the active path (replay keeps p=1 — ADR-097 does NOT amend the kernel oracle)."""
    text = _workflow_text()
    assert "gate-a-nanoda:$NANODA_RESULT" in text, "aggregator must require the nanoda check"
    assert "gate-a-replay:$REPLAY_RESULT" in text, "aggregator must still require the leanchecker replay (p=1)"


def test_gate_a_audit_runs_only_as_nanoda_fallback():
    """The real axiom_audit must be GATED on nanoda not covering — i.e. it runs only
    on the non-leaf fallback, and the aggregator requires it only then (fail-closed:
    a covered leaf is gated by nanoda; anything else falls back to the audit)."""
    text = _workflow_text()
    assert "needs.gate_a_nanoda.outputs.covered != 'true'" in text, \
        "audit jobs must be conditional on nanoda NOT covering"
    # the aggregator requires the audit only when nanoda did not cover
    assert 'if [ "$NANODA_COVERED" != "true" ]; then' in text, \
        "aggregator must require the audit only on the nanoda-not-covered fallback"


def test_nanoda_is_pinned_not_master_head():
    """nanoda must be built from a PINNED commit, never master HEAD (ADR-096 gate 2):
    no `git clone … nanoda_lib.git` without a pinned SHA in setup.sh or the workflows."""
    import re
    setup = (REPO_ROOT / "tools" / "independent_check" / "setup.sh").read_text(encoding="utf-8")
    assert "NANODA_COMMIT=" in setup, "setup.sh must pin a NANODA_COMMIT"
    # a shallow clone of nanoda_lib WITHOUT a pinned checkout is forbidden
    for path in (REPO_ROOT / "tools" / "independent_check" / "setup.sh",
                 REPO_ROOT / ".github" / "workflows" / "export-checker-pilot.yml"):
        t = path.read_text(encoding="utf-8")
        assert not re.search(r"clone --depth 1 https://github\.com/ammkrn/nanoda_lib\.git", t), \
            f"{path.name}: nanoda must be fetched at a pinned commit, not cloned at HEAD"


def test_nanoda_binary_cache_key_busts_on_pin_bump():
    """The gate-a-nanoda binary cache MUST key on both pin sources — the
    lean-toolchain tag (lean4export pin) and setup.sh (which holds NANODA_COMMIT) —
    so bumping either pin changes the key and forces a fresh build. A cache keyed on
    less (e.g. a constant) could serve a stale binary built from an old pin after a
    bump, silently diverging the trusted checker from its reviewed commit."""
    text = _workflow_text()
    # the cache step exists and points at the independent-check prefix
    assert "~/.unsorry/independent-check" in text, \
        "gate-a-nanoda must cache the pinned independent-check binaries"
    # its key must include BOTH pin sources via hashFiles, so a pin bump busts it
    assert re.search(
        r"key:\s*indep-check-\$\{\{\s*runner\.os\s*\}\}-"
        r"\$\{\{\s*hashFiles\([^)]*lean-toolchain[^)]*"
        r"tools/independent_check/setup\.sh[^)]*\)\s*\}\}",
        text,
    ), "binary cache key must hash lean-toolchain AND setup.sh so either pin bump busts it"
