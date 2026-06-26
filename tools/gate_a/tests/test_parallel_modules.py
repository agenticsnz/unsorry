import json
import subprocess
from pathlib import Path

from tools.gate_a.parallel_modules import (
    audit,
    audit_shard,
    collision_free_chunks,
    combine_audit_reports,
    compute_audit_targets,
    compute_replay_targets,
    forces_full_audit,
    forces_full_replay,
    goal_module_for_path,
    import_graph,
    library_module_for_path,
    module_names,
    module_top_level_names,
    plan_audit_shards,
    plan_shards,
    replay,
    replay_scope,
    replay_shard,
    scoped_audit_targets,
    split_evenly,
)


def completed(
    argv: tuple[str, ...],
    returncode: int = 0,
    stdout: str = "",
    stderr: str = "",
) -> subprocess.CompletedProcess[str]:
    return subprocess.CompletedProcess(argv, returncode, stdout, stderr)


def test_module_names_and_balanced_chunks(tmp_path: Path):
    (tmp_path / "library" / "Unsorry").mkdir(parents=True)
    (tmp_path / "goals").mkdir()
    (tmp_path / "library" / "Unsorry" / "One.lean").write_text("")
    (tmp_path / "library" / "Unsorry" / "Two.lean").write_text("")
    (tmp_path / "goals" / "three-four.lean").write_text("")

    assert module_names(tmp_path, "library") == ["Unsorry.One", "Unsorry.Two"]
    assert module_names(tmp_path, "goals") == ["goals.three-four"]
    assert split_evenly(["a", "b", "c", "d", "e"], 2) == [
        ["a", "b", "c"],
        ["d", "e"],
    ]


def test_audit_combines_parallel_json_reports(tmp_path: Path):
    (tmp_path / "library" / "Unsorry").mkdir(parents=True)
    (tmp_path / "goals").mkdir()
    (tmp_path / "library" / "Unsorry" / "One.lean").write_text("")
    (tmp_path / "library" / "Unsorry" / "Two.lean").write_text("")
    (tmp_path / "goals" / "three.lean").write_text("")
    output = tmp_path / "report.json"
    calls = []

    def runner(argv, **_kwargs):
        argv = tuple(argv)
        calls.append(argv)
        if argv[:3] == ("lake", "build", "axiom_audit"):
            return completed(argv)
        modules = [arg for arg in argv if "." in arg]
        report = [{"decl": module, "axioms": []} for module in modules]
        return completed(argv, stdout=json.dumps(report))

    assert audit(tmp_path, 4, output, runner) == 0
    assert json.loads(output.read_text()) == [
        {"decl": "Unsorry.One", "axioms": []},
        {"decl": "Unsorry.Two", "axioms": []},
        {"decl": "goals.three", "axioms": []},
    ]
    assert any("--allow-sorry" in call for call in calls)


def test_replay_propagates_a_chunk_failure(tmp_path: Path):
    (tmp_path / "library" / "Unsorry").mkdir(parents=True)
    (tmp_path / "library" / "Unsorry" / "One.lean").write_text("")
    (tmp_path / "library" / "Unsorry" / "Two.lean").write_text("")

    def runner(argv, **_kwargs):
        argv = tuple(argv)
        return completed(argv, returncode=1 if "Unsorry.Two" in argv else 0)

    assert replay(tmp_path, 2, runner) == 1


def test_replay_is_serial_regardless_of_jobs(tmp_path: Path):
    # leanchecker holds mathlib resident per process, so concurrent invocations
    # OOM-kill a standard CI runner (exit 143). A small library fits one serial
    # leanchecker; chunking only kicks in past REPLAY_CHUNK_SIZE. Either way the
    # --jobs request is ignored — replay never runs two leancheckers at once.
    (tmp_path / "library" / "Unsorry").mkdir(parents=True)
    for name in ("One", "Two", "Three", "Four", "Five"):
        (tmp_path / "library" / "Unsorry" / f"{name}.lean").write_text("")

    calls: list[tuple[str, ...]] = []

    def runner(argv, **_kwargs):
        argv = tuple(argv)
        calls.append(argv)
        return completed(argv, returncode=0)

    assert replay(tmp_path, 4, runner) == 0
    # one chunk → one leanchecker process → every module checked in it
    assert len(calls) == 1
    assert calls[0][:3] == ("lake", "env", "leanchecker")
    assert {"Unsorry.One", "Unsorry.Five"} <= set(calls[0])


def test_replay_chunks_a_large_library_serially(tmp_path: Path):
    # As the library grows past REPLAY_CHUNK_SIZE, one leanchecker over every
    # module OOMs even serially (#294 was not enough). Replay splits into
    # bounded chunks run one at a time, and every module is still replayed.
    from tools.gate_a.parallel_modules import REPLAY_CHUNK_SIZE
    (tmp_path / "library" / "Unsorry").mkdir(parents=True)
    names = [f"M{i}" for i in range(REPLAY_CHUNK_SIZE * 2 + 5)]
    for n in names:
        (tmp_path / "library" / "Unsorry" / f"{n}.lean").write_text("")

    calls: list[tuple[str, ...]] = []

    def runner(argv, **_kwargs):
        argv = tuple(argv)
        calls.append(argv)
        return completed(argv, returncode=0)

    assert replay(tmp_path, 4, runner) == 0
    assert len(calls) >= 3  # split into multiple chunks
    assert all(c[:3] == ("lake", "env", "leanchecker") for c in calls)
    covered = {m for c in calls for m in c[3:]}
    assert covered == {f"Unsorry.{n}" for n in names}  # every module replayed


def _replay_calls(tmp_path: Path, n_modules: int) -> list[tuple[str, ...]]:
    (tmp_path / "library" / "Unsorry").mkdir(parents=True)
    for i in range(n_modules):
        (tmp_path / "library" / "Unsorry" / f"M{i}.lean").write_text("")
    calls: list[tuple[str, ...]] = []

    def runner(argv, **_kwargs):
        argv = tuple(argv)
        calls.append(argv)
        return completed(argv, returncode=0)

    assert replay(tmp_path, 1, runner) == 0
    return calls


def test_replay_chunk_size_env_override_shrinks_chunks(tmp_path: Path, monkeypatch):
    # ADR-048 Phase 2: UNSORRY_REPLAY_CHUNK lets a FULL replay fit a smaller (8 GB)
    # runner by cutting the chunk size, so the same module set splits into more,
    # smaller chunks (each chunk's peak RSS is the few oleans on top of mathlib).
    monkeypatch.setenv("UNSORRY_REPLAY_CHUNK", "6")
    calls = _replay_calls(tmp_path, 30)
    # 30 modules / 6-per-chunk = 5 chunks (vs 1 chunk at the default 30).
    assert len(calls) == 5
    covered = {m for c in calls for m in c[3:]}
    assert covered == {f"Unsorry.M{i}" for i in range(30)}  # every module replayed


def test_replay_chunk_size_env_invalid_falls_back_to_default(tmp_path: Path, monkeypatch):
    # A bad value (non-int, zero, negative) must not silently disable chunking —
    # it falls back to the safe 30-module default so the gate cannot be tricked
    # into one unbounded leanchecker process.
    for bad in ("not-a-number", "0", "-5", ""):
        monkeypatch.setenv("UNSORRY_REPLAY_CHUNK", bad)
        from tools.gate_a.parallel_modules import _replay_chunk_size

        assert _replay_chunk_size() == 30, bad


def test_replay_chunk_size_env_unset_is_default(monkeypatch):
    from tools.gate_a.parallel_modules import _replay_chunk_size

    monkeypatch.delenv("UNSORRY_REPLAY_CHUNK", raising=False)
    assert _replay_chunk_size() == 30


# --- incremental replay (ADR-033) -------------------------------------------

def _write_lib(tmp_path: Path, modules: dict[str, list[str]]) -> None:
    """modules: {name: [imported Unsorry module names]}."""
    d = tmp_path / "library" / "Unsorry"
    d.mkdir(parents=True, exist_ok=True)
    for name, imports in modules.items():
        body = "".join(f"import Unsorry.{imp}\n" for imp in imports)
        (d / f"{name}.lean").write_text(body + "theorem t : True := trivial\n")


def _runner_for(tmp_path, changed_stdout, *, git_rc=0):
    """A runner that answers `git diff` with changed_stdout and records the
    module lists passed to leanchecker."""
    replayed: set[str] = set()

    def runner(argv, **_kwargs):
        argv = tuple(argv)
        if argv[0] == "git" and "diff" in argv:
            return completed(argv, returncode=git_rc, stdout=changed_stdout)
        if argv[:3] == ("lake", "env", "leanchecker"):
            replayed.update(argv[3:])
        return completed(argv)

    return runner, replayed


def test_library_module_for_path():
    assert library_module_for_path("library/Unsorry/Foo.lean") == "Unsorry.Foo"
    assert library_module_for_path("library/Unsorry/Sub/Bar.lean") == "Unsorry.Sub.Bar"
    assert library_module_for_path("goals/x.lean") is None
    assert library_module_for_path("docs/readme.md") is None


def test_goal_module_for_path():
    assert goal_module_for_path("goals/foo.lean") == "goals.foo"
    assert goal_module_for_path("goals/sub/foo.lean") == "goals.sub.foo"
    assert goal_module_for_path("library/Unsorry/Foo.lean") is None
    assert goal_module_for_path("goals/index.json") is None
    # ADR-110: benchmark obligation statements live in benchmark-goals/ and are NOT part
    # of the repo-pin UnsorryGoals build/audit set (elaborated at the suite pin instead).
    assert goal_module_for_path("benchmark-goals/combibench-x.lean") is None


def test_forces_full_replay():
    # Only olean-invalidating changes force a full replay.
    assert forces_full_replay(["library/Unsorry/A.lean"]) is None
    assert forces_full_replay(["lean-toolchain"]) == "lean-toolchain"
    assert forces_full_replay(["lakefile.toml"]) == "lakefile.toml"
    assert forces_full_replay(["lake-manifest.json"]) == "lake-manifest.json"


def test_replay_trigger_excludes_orchestration_and_workflow():
    # tools/gate_a and the CI workflow do not change any olean (ADR-033) — they
    # run an incremental replay, not the memory-bound full replay (ADR-047).
    assert forces_full_replay(["tools/gate_a/parallel_modules.py"]) is None
    assert forces_full_replay([".github/workflows/gate-a.yml"]) is None
    assert forces_full_replay(["x", "tools/gate_a/check.py"]) is None


def test_forces_full_audit():
    # The audit stays conservative: auditor, fixtures, orchestration, workflow.
    assert forces_full_audit(["library/Unsorry/A.lean"]) is None
    assert forces_full_audit(["lean-toolchain"]) == "lean-toolchain"
    assert forces_full_audit(["AxiomAudit/Main.lean"]) == "AxiomAudit/Main.lean"
    assert forces_full_audit(["AuditFixtures/Opaque.lean"]) == "AuditFixtures/Opaque.lean"
    assert forces_full_audit(["tools/gate_a/parallel_modules.py"]) == "tools/gate_a/parallel_modules.py"
    assert forces_full_audit([".github/workflows/gate-a.yml"]) == ".github/workflows/gate-a.yml"


def test_replay_scope_reverse_closure(tmp_path):
    _write_lib(tmp_path, {"A": [], "B": ["A"], "C": ["B"], "ABinding": ["A"], "Unrel": []})
    graph = import_graph(tmp_path)
    # changing A pulls in everything that transitively imports A (incl. its binding)
    assert set(replay_scope(["Unsorry.A"], graph)) == {
        "Unsorry.A", "Unsorry.B", "Unsorry.C", "Unsorry.ABinding"
    }
    # a leaf only replays itself
    assert replay_scope(["Unsorry.C"], graph) == ["Unsorry.C"]
    assert replay_scope(["Unsorry.Unrel"], graph) == ["Unsorry.Unrel"]


def test_replay_incremental_changed_plus_dependents_only(tmp_path):
    _write_lib(tmp_path, {"A": [], "B": ["A"], "C": [], "ABinding": ["A"]})
    runner, replayed = _runner_for(tmp_path, "library/Unsorry/A.lean\n")
    assert replay(tmp_path, 2, runner, base="origin/main") == 0
    # A changed -> A + B + ABinding (import A); C untouched and skipped
    assert replayed == {"Unsorry.A", "Unsorry.B", "Unsorry.ABinding"}


def test_replay_incremental_no_library_change_skips(tmp_path):
    _write_lib(tmp_path, {"A": []})
    runner, replayed = _runner_for(tmp_path, "docs/readme.md\nCHANGELOG.md\n")
    assert replay(tmp_path, 2, runner, base="origin/main") == 0
    assert replayed == set()  # leanchecker never invoked


def test_replay_global_impact_forces_full(tmp_path):
    _write_lib(tmp_path, {"A": [], "B": ["A"]})
    runner, replayed = _runner_for(tmp_path, "lean-toolchain\nlibrary/Unsorry/A.lean\n")
    assert replay(tmp_path, 2, runner, base="origin/main") == 0
    assert replayed == {"Unsorry.A", "Unsorry.B"}  # FULL replay


def test_replay_git_failure_falls_back_to_full(tmp_path):
    _write_lib(tmp_path, {"A": [], "B": []})
    runner, replayed = _runner_for(tmp_path, "", git_rc=128)
    assert replay(tmp_path, 2, runner, base="deadbeef") == 0
    assert replayed == {"Unsorry.A", "Unsorry.B"}  # FULL replay on git failure


def test_replay_without_base_is_full(tmp_path):
    _write_lib(tmp_path, {"A": [], "B": ["A"]})
    calls: list[tuple[str, ...]] = []

    def runner(argv, **_kwargs):
        argv = tuple(argv)
        if argv[0] == "git":
            raise AssertionError("full replay must not consult git")
        if argv[:3] == ("lake", "env", "leanchecker"):
            calls.append(argv)
        return completed(argv)

    assert replay(tmp_path, 2, runner) == 0  # no base -> full, no git
    replayed = {m for c in calls for m in c[3:]}
    assert replayed == {"Unsorry.A", "Unsorry.B"}


# --- incremental axiom audit ------------------------------------------------

def test_scoped_audit_targets_changed_library_and_goal(tmp_path):
    _write_lib(tmp_path, {"A": [], "B": ["A"], "C": [], "ABinding": ["A"]})
    (tmp_path / "goals").mkdir()
    (tmp_path / "goals" / "one.lean").write_text("")
    (tmp_path / "goals" / "two.lean").write_text("")
    runner, _ = _runner_for(
        tmp_path,
        "library/Unsorry/A.lean\ngoals/one.lean\ndocs/readme.md\n",
    )

    scoped = scoped_audit_targets(
        tmp_path,
        "origin/main",
        ["Unsorry.A", "Unsorry.B", "Unsorry.C", "Unsorry.ABinding"],
        ["goals.one", "goals.two"],
        runner,
    )

    assert scoped is not None
    assert scoped.mode == "incremental"
    assert scoped.library == ["Unsorry.A", "Unsorry.ABinding", "Unsorry.B"]
    assert scoped.goals == ["goals.one"]


def test_scoped_audit_targets_global_impact_falls_back(tmp_path):
    _write_lib(tmp_path, {"A": []})
    runner, _ = _runner_for(tmp_path, "AxiomAudit/Main.lean\nlibrary/Unsorry/A.lean\n")
    assert scoped_audit_targets(
        tmp_path,
        "origin/main",
        ["Unsorry.A"],
        [],
        runner,
    ) is None


def test_audit_incremental_empty_scope_writes_empty_report(tmp_path: Path):
    _write_lib(tmp_path, {"A": []})
    output = tmp_path / "report.json"
    calls = []

    def runner(argv, **_kwargs):
        argv = tuple(argv)
        calls.append(argv)
        if argv[0] == "git" and "diff" in argv:
            return completed(argv, stdout="docs/readme.md\n")
        return completed(argv, stdout="[]")

    assert audit(tmp_path, 1, output, runner, base="origin/main") == 0
    assert json.loads(output.read_text()) == []
    assert all(call[:3] != ("lake", "build", "axiom_audit") for call in calls)


def test_audit_incremental_runs_only_scoped_modules(tmp_path: Path):
    _write_lib(tmp_path, {"A": [], "B": ["A"], "C": [], "ABinding": ["A"]})
    (tmp_path / "goals").mkdir()
    (tmp_path / "goals" / "one.lean").write_text("")
    (tmp_path / "goals" / "two.lean").write_text("")
    output = tmp_path / "report.json"
    calls = []

    def runner(argv, **_kwargs):
        argv = tuple(argv)
        calls.append(argv)
        if argv[0] == "git" and "diff" in argv:
            return completed(argv, stdout="library/Unsorry/A.lean\ngoals/one.lean\n")
        if argv[:3] == ("lake", "build", "axiom_audit"):
            return completed(argv)
        modules = [arg for arg in argv if "." in arg]
        report = [{"decl": module, "axioms": []} for module in modules]
        return completed(argv, stdout=json.dumps(report))

    assert audit(tmp_path, 1, output, runner, base="origin/main") == 0
    assert json.loads(output.read_text()) == [
        {"decl": "Unsorry.A", "axioms": []},
        {"decl": "Unsorry.ABinding", "axioms": []},
        {"decl": "Unsorry.B", "axioms": []},
        {"decl": "goals.one", "axioms": []},
    ]
    audited = {arg for call in calls for arg in call if arg.startswith(("Unsorry.", "goals."))}
    assert audited == {"Unsorry.A", "Unsorry.ABinding", "Unsorry.B", "goals.one"}


# --- sharded kernel replay (ADR-063) ----------------------------------------

def _many_lib(tmp_path: Path, n: int) -> set[str]:
    d = tmp_path / "library" / "Unsorry"
    d.mkdir(parents=True, exist_ok=True)
    for i in range(n):
        (d / f"M{i}.lean").write_text("theorem t : True := trivial\n")
    return {f"Unsorry.M{i}" for i in range(n)}


def _shard_modules(tmp_path, shard_total, *, base=None, changed=""):
    """Run every shard 0..shard_total-1; return the list of module-sets each replayed."""
    per_shard = []
    for index in range(shard_total):
        recorded: list[str] = []

        def runner(argv, _rec=recorded, **_kw):
            argv = tuple(argv)
            if argv[0] == "git" and "diff" in argv:
                return completed(argv, stdout=changed)
            if argv[:3] == ("lake", "env", "leanchecker"):
                _rec.extend(argv[3:])
            return completed(argv)

        assert replay_shard(tmp_path, index, shard_total, runner, base=base) == 0
        per_shard.append(set(recorded))
    return per_shard


def test_shards_partition_covers_every_module_exactly_once(tmp_path):
    # THE soundness invariant (ADR-063): across all shards, every olean is
    # kernel-replayed exactly once — the shards are disjoint AND covering, so the
    # sharded replay checks the same set a single serial replay would.
    all_modules = _many_lib(tmp_path, 25)
    per_shard = _shard_modules(tmp_path, 4)
    union: set[str] = set()
    for modules in per_shard:
        assert union.isdisjoint(modules)  # disjoint: no module in two shards
        union |= modules
    assert union == all_modules  # covering: no module skipped


def test_shards_partition_covers_incremental_scope_exactly_once(tmp_path):
    # Same exactly-once guarantee on the incremental path: the shards partition
    # the changed + reverse-import closure, nothing outside it, nothing twice.
    _write_lib(tmp_path, {"A": [], "B": ["A"], "C": [], "ABinding": ["A"]})
    per_shard = _shard_modules(
        tmp_path, 3, base="origin/main", changed="library/Unsorry/A.lean\n"
    )
    union: set[str] = set()
    for modules in per_shard:
        assert union.isdisjoint(modules)
        union |= modules
    assert union == {"Unsorry.A", "Unsorry.ABinding", "Unsorry.B"}  # C excluded


def test_plan_shards_full_library(tmp_path):
    _many_lib(tmp_path, 10)
    plan = plan_shards(tmp_path, 4, None)
    assert plan["mode"] == "full"
    assert plan["count"] == 10
    assert plan["shards"] == [0, 1, 2, 3]


def test_plan_shards_caps_at_module_count(tmp_path):
    _many_lib(tmp_path, 3)
    plan = plan_shards(tmp_path, 8, None)  # 8 requested, only 3 modules
    assert plan["count"] == 3
    assert plan["shards"] == [0, 1, 2]  # capped — no empty shards


def test_plan_shards_empty_on_no_library_change(tmp_path):
    _write_lib(tmp_path, {"A": []})
    runner, _ = _runner_for(tmp_path, "docs/readme.md\n")
    plan = plan_shards(tmp_path, 8, "origin/main", runner)
    assert plan["count"] == 0
    assert plan["shards"] == []  # empty matrix -> matrix job skipped
    assert plan["mode"] == "none"


def test_plan_shards_fail_closed_to_full_on_git_failure(tmp_path):
    # An untrusted diff must plan the FULL set, never an empty one (fail-closed).
    _write_lib(tmp_path, {"A": [], "B": []})
    runner, _ = _runner_for(tmp_path, "", git_rc=128)
    plan = plan_shards(tmp_path, 8, "deadbeef", runner)
    assert plan["mode"] == "full"
    assert plan["count"] == 2


def test_plan_shards_fail_closed_to_full_on_global_impact(tmp_path):
    _write_lib(tmp_path, {"A": [], "B": ["A"]})
    runner, _ = _runner_for(tmp_path, "lean-toolchain\n")
    plan = plan_shards(tmp_path, 8, "origin/main", runner)
    assert plan["mode"] == "full"
    assert plan["count"] == 2


def test_replay_shard_runs_only_its_slice(tmp_path):
    _many_lib(tmp_path, 8)
    targets, _ = compute_replay_targets(tmp_path, None)
    expected = set(split_evenly(targets, 4)[1])  # slice 1 of 4
    recorded: list[str] = []

    def runner(argv, **_kw):
        argv = tuple(argv)
        if argv[:3] == ("lake", "env", "leanchecker"):
            recorded.extend(argv[3:])
        return completed(argv)

    assert replay_shard(tmp_path, 1, 4, runner) == 0
    assert set(recorded) == expected


def test_replay_shard_out_of_range_is_noop(tmp_path):
    _many_lib(tmp_path, 3)
    calls: list[tuple] = []

    def runner(argv, **_kw):
        argv = tuple(argv)
        if argv[:3] == ("lake", "env", "leanchecker"):
            calls.append(argv)
        return completed(argv)

    # 3 modules split into 5 -> only 3 shards exist; index 4 is a no-op, not red.
    assert replay_shard(tmp_path, 4, 5, runner) == 0
    assert calls == []


def test_replay_shard_propagates_failure(tmp_path):
    _many_lib(tmp_path, 8)

    def runner(argv, **_kw):
        argv = tuple(argv)
        rc = 1 if (argv[:3] == ("lake", "env", "leanchecker") and "Unsorry.M0" in argv) else 0
        return completed(argv, returncode=rc)

    # a failing module in shard 0 turns that shard red
    assert replay_shard(tmp_path, 0, 4, runner) == 1


def test_replay_shard_fail_closed_full_on_git_failure(tmp_path):
    # If git can't diff, a shard must replay from the FULL set (fail-closed),
    # never silently skip — same invariant as the serial replay.
    all_modules = _many_lib(tmp_path, 6)
    union: set[str] = set()
    for index in range(3):
        recorded: list[str] = []

        def runner(argv, _rec=recorded, **_kw):
            argv = tuple(argv)
            if argv[0] == "git" and "diff" in argv:
                return completed(argv, returncode=128)  # git can't answer
            if argv[:3] == ("lake", "env", "leanchecker"):
                _rec.extend(argv[3:])
            return completed(argv)

        assert replay_shard(tmp_path, index, 3, runner, base="deadbeef") == 0
        union |= set(recorded)
    assert union == all_modules  # FULL set covered despite the git failure


# --- sharded axiom audit (ADR-091) ------------------------------------------

def _make_goals(tmp_path: Path, names) -> set[str]:
    (tmp_path / "goals").mkdir(exist_ok=True)
    for name in names:
        (tmp_path / "goals" / f"{name}.lean").write_text("")
    return {f"goals.{name}" for name in names}


def _audit_shard_modules(tmp_path, shard_total, *, base=None, changed=""):
    """Run every audit shard 0..shard_total-1; return the module-sets each audited."""
    per_shard = []
    for index in range(shard_total):
        recorded: list[str] = []

        def runner(argv, _rec=recorded, **_kw):
            argv = tuple(argv)
            if argv[0] == "git" and "diff" in argv:
                return completed(argv, stdout=changed)
            if argv[:3] == ("lake", "exe", "axiom_audit"):
                mods = [a for a in argv[3:] if a != "--allow-sorry"]
                _rec.extend(mods)
                return completed(argv, stdout=json.dumps([{"decl": m, "axioms": []} for m in mods]))
            return completed(argv)  # lake build axiom_audit etc.

        out = tmp_path / f"shard-{index}.json"
        assert audit_shard(tmp_path, index, shard_total, out, runner, base=base) == 0
        per_shard.append(set(recorded))
    return per_shard


def test_audit_shards_partition_covers_every_module_exactly_once(tmp_path):
    # THE soundness invariant (ADR-091): across all shards, every in-scope module
    # (library AND goals) is axiom-audited exactly once — disjoint AND covering.
    lib = _many_lib(tmp_path, 20)
    goals = _make_goals(tmp_path, [f"g{i}" for i in range(5)])
    per_shard = _audit_shard_modules(tmp_path, 4)
    union: set[str] = set()
    for modules in per_shard:
        assert union.isdisjoint(modules)  # disjoint: no module in two shards
        union |= modules
    assert union == lib | goals  # covering: every library and goal module audited


def test_audit_shards_partition_covers_incremental_scope_exactly_once(tmp_path):
    # Same exactly-once guarantee on the incremental path: the shards partition the
    # changed library closure + changed goals, nothing outside, nothing twice.
    _write_lib(tmp_path, {"A": [], "B": ["A"], "C": [], "ABinding": ["A"]})
    _make_goals(tmp_path, ["one", "two"])
    per_shard = _audit_shard_modules(
        tmp_path, 3, base="origin/main", changed="library/Unsorry/A.lean\ngoals/one.lean\n"
    )
    union: set[str] = set()
    for modules in per_shard:
        assert union.isdisjoint(modules)
        union |= modules
    # A -> A + ABinding + B; goal one; C and goal two excluded
    assert union == {"Unsorry.A", "Unsorry.ABinding", "Unsorry.B", "goals.one"}


def test_plan_audit_shards_full(tmp_path):
    _many_lib(tmp_path, 8)
    _make_goals(tmp_path, ["g0", "g1"])
    plan = plan_audit_shards(tmp_path, 4, None)
    assert plan["mode"] == "full"
    assert plan["count"] == 10  # 8 library + 2 goals
    assert plan["shards"] == [0, 1, 2, 3]


def test_plan_audit_shards_caps_at_module_count(tmp_path):
    _many_lib(tmp_path, 3)
    plan = plan_audit_shards(tmp_path, 8, None)  # 8 requested, only 3 modules
    assert plan["count"] == 3
    assert plan["shards"] == [0, 1, 2]  # capped — no empty shards


def test_plan_audit_shards_empty_on_no_change(tmp_path):
    _write_lib(tmp_path, {"A": []})
    runner, _ = _runner_for(tmp_path, "docs/readme.md\n")
    plan = plan_audit_shards(tmp_path, 8, "origin/main", runner)
    assert plan["count"] == 0
    assert plan["shards"] == []  # empty matrix -> matrix job skipped
    assert plan["mode"] == "none"


def test_plan_audit_shards_fail_closed_to_full_on_git_failure(tmp_path):
    # An untrusted diff must plan the FULL set, never an empty one (fail-closed).
    _write_lib(tmp_path, {"A": [], "B": []})
    runner, _ = _runner_for(tmp_path, "", git_rc=128)
    plan = plan_audit_shards(tmp_path, 8, "deadbeef", runner)
    assert plan["mode"] == "full"
    assert plan["count"] == 2


def test_plan_audit_shards_fail_closed_to_full_on_global_impact(tmp_path):
    # The audit's conservative trigger (AxiomAudit/ change) forces a full audit.
    _write_lib(tmp_path, {"A": [], "B": ["A"]})
    runner, _ = _runner_for(tmp_path, "AxiomAudit/Main.lean\n")
    plan = plan_audit_shards(tmp_path, 8, "origin/main", runner)
    assert plan["mode"] == "full"
    assert plan["count"] == 2


def test_audit_shard_runs_only_its_slice(tmp_path):
    _many_lib(tmp_path, 8)
    scope = compute_audit_targets(tmp_path, None)
    targets = list(scope.library) + list(scope.goals)
    expected = set(split_evenly(targets, 4)[1])  # slice 1 of 4
    recorded: list[str] = []

    def runner(argv, **_kw):
        argv = tuple(argv)
        if argv[:3] == ("lake", "exe", "axiom_audit"):
            recorded.extend(a for a in argv[3:] if a != "--allow-sorry")
        return completed(argv, stdout="[]")

    assert audit_shard(tmp_path, 1, 4, tmp_path / "shard.json", runner) == 0
    assert set(recorded) == expected


def test_audit_shard_splits_library_and_goal_invocations(tmp_path):
    # Library members audit plainly; goal members audit with --allow-sorry.
    _write_lib(tmp_path, {"A": [], "B": []})
    _make_goals(tmp_path, ["g"])
    calls: list[tuple[str, ...]] = []

    def runner(argv, **_kw):
        argv = tuple(argv)
        if argv[:3] == ("lake", "exe", "axiom_audit"):
            calls.append(argv)
        return completed(argv, stdout="[]")

    assert audit_shard(tmp_path, 0, 1, tmp_path / "shard.json", runner) == 0  # one shard = everything
    lib_calls = [c for c in calls if "--allow-sorry" not in c]
    goal_calls = [c for c in calls if "--allow-sorry" in c]
    assert any("Unsorry.A" in c and "Unsorry.B" in c for c in lib_calls)
    assert any("goals.g" in c for c in goal_calls)
    assert all("goals.g" not in c for c in lib_calls)  # goals never plain-audited


def test_audit_shard_out_of_range_writes_empty_fragment(tmp_path):
    _many_lib(tmp_path, 3)
    out = tmp_path / "shard.json"
    calls: list[tuple] = []

    def runner(argv, **_kw):
        argv = tuple(argv)
        if argv[:3] == ("lake", "exe", "axiom_audit"):
            calls.append(argv)
        return completed(argv, stdout="[]")

    # 3 modules split into 5 -> only 3 shards exist; index 4 is a no-op empty.
    assert audit_shard(tmp_path, 4, 5, out, runner) == 0
    assert calls == []
    assert json.loads(out.read_text()) == []


def test_audit_shard_propagates_failure(tmp_path):
    _many_lib(tmp_path, 8)

    def runner(argv, **_kw):
        argv = tuple(argv)
        if argv[:3] == ("lake", "exe", "axiom_audit"):
            return completed(argv, returncode=1, stdout="")
        return completed(argv)

    # a failing audit in shard 0 turns that shard red
    assert audit_shard(tmp_path, 0, 4, tmp_path / "shard.json", runner) == 1


def test_audit_shard_fail_closed_full_on_git_failure(tmp_path):
    # If git can't diff, a shard must audit from the FULL set (fail-closed).
    all_modules = _many_lib(tmp_path, 6)
    union: set[str] = set()
    for index in range(3):
        recorded: list[str] = []

        def runner(argv, _rec=recorded, **_kw):
            argv = tuple(argv)
            if argv[0] == "git" and "diff" in argv:
                return completed(argv, returncode=128)  # git can't answer
            if argv[:3] == ("lake", "exe", "axiom_audit"):
                _rec.extend(a for a in argv[3:] if a != "--allow-sorry")
            return completed(argv, stdout="[]")

        assert audit_shard(tmp_path, index, 3, tmp_path / f"s{index}.json", runner, base="deadbeef") == 0
        union |= set(recorded)
    assert union == all_modules  # FULL set covered despite the git failure


def test_audit_shard_fragments_combine_to_full_sorted_report(tmp_path):
    # The composability property: concatenating every shard's fragment reproduces
    # the serial audit's combined, decl-sorted report (the footprint comment).
    _many_lib(tmp_path, 10)
    fragments = []
    for index in range(4):
        out = tmp_path / f"shard-{index}.json"

        def runner(argv, **_kw):
            argv = tuple(argv)
            if argv[:3] == ("lake", "exe", "axiom_audit"):
                mods = [a for a in argv[3:] if a != "--allow-sorry"]
                return completed(argv, stdout=json.dumps([{"decl": m, "axioms": []} for m in mods]))
            return completed(argv)

        assert audit_shard(tmp_path, index, 4, out, runner) == 0
        fragments.append(out)

    combined = tmp_path / "axiom-report.json"
    assert combine_audit_reports(fragments, combined) == 0
    decls = [item["decl"] for item in json.loads(combined.read_text())]
    assert decls == sorted(f"Unsorry.M{i}" for i in range(10))  # full + sorted


def test_combine_audit_reports_fails_closed_on_bad_fragment(tmp_path):
    good = tmp_path / "good.json"
    good.write_text(json.dumps([{"decl": "Unsorry.A", "axioms": []}]))
    bad = tmp_path / "bad.json"
    bad.write_text("{ not an array }")
    assert combine_audit_reports([good, bad], tmp_path / "out.json") == 1


# --- ADR-018-safe audit fix: goal name-collision tolerance ------------------

def test_module_top_level_names_extracts_declarations(tmp_path: Path):
    (tmp_path / "goals").mkdir()
    (tmp_path / "goals" / "magic-16.lean").write_text(
        "import Mathlib\n"
        "structure IsMagicSquare {n : ℕ} (M : X) : Prop where\n"
        "  rowsum : True\n"
        "noncomputable def helper : Nat := 0\n"
        "theorem brualdi_ch1_16 (M : X) : IsMagicSquare M := by sorry\n"
    )
    names = module_top_level_names(tmp_path, "goals.magic-16")
    assert {"IsMagicSquare", "helper", "brualdi_ch1_16"} <= names


def test_module_top_level_names_missing_file_is_empty(tmp_path: Path):
    assert module_top_level_names(tmp_path, "goals.nope") == set()


def test_collision_free_chunks_separates_clashing_modules():
    names = {
        "g.a": {"IsMagicSquare", "brualdi_ch1_10"},
        "g.b": {"IsMagicSquare", "brualdi_ch1_16"},  # clashes with g.a on IsMagicSquare
        "g.c": {"foo"},
    }
    chunks = collision_free_chunks(["g.a", "g.b", "g.c"], lambda m: names[m], 1)
    # one requested chunk, but the clash forces g.a and g.b into different chunks
    assert any("g.a" in c and "g.b" in c for c in chunks) is False
    # every module appears exactly once
    flat = [m for c in chunks for m in c]
    assert sorted(flat) == ["g.a", "g.b", "g.c"]


def test_collision_free_chunks_packs_disjoint_like_split_evenly():
    names = {m: {m} for m in ("g.a", "g.b", "g.c", "g.d")}  # all unique
    chunks = collision_free_chunks(["g.a", "g.b", "g.c", "g.d"], lambda m: names[m], 2)
    assert len(chunks) == 2
    assert sorted(m for c in chunks for m in c) == ["g.a", "g.b", "g.c", "g.d"]
    assert all(len(c) == 2 for c in chunks)  # balanced


def test_collision_free_chunks_empty():
    assert collision_free_chunks([], lambda m: set(), 4) == []


def test_audit_keeps_colliding_goals_in_separate_calls(tmp_path: Path):
    """End-to-end: two goals declaring `IsMagicSquare` must never be passed to one
    `axiom_audit` invocation (which would fail the importModules with a name clash)."""
    (tmp_path / "library" / "Unsorry").mkdir(parents=True)
    (tmp_path / "goals").mkdir()
    body = (
        "import Mathlib\n"
        "structure IsMagicSquare (M : Nat) : Prop where mk ::\n"
        "theorem {name} (M : Nat) : IsMagicSquare M := by sorry\n"
    )
    (tmp_path / "goals" / "brualdi-ch1-10.lean").write_text(body.format(name="brualdi_ch1_10"))
    (tmp_path / "goals" / "brualdi-ch1-16.lean").write_text(body.format(name="brualdi_ch1_16"))

    audit_calls: list[tuple[str, ...]] = []

    def runner(argv, **kwargs):
        argv = tuple(argv)
        if argv[0] == "git" and "diff" in argv:
            return completed(argv, returncode=128)  # untrusted ⇒ full scope (both goals)
        if argv[:3] == ("lake", "build", "axiom_audit"):
            return completed(argv)
        if argv[:3] == ("lake", "exe", "axiom_audit"):
            audit_calls.append(argv)
            return completed(argv, stdout="[]")
        return completed(argv, stdout="[]")

    audit(tmp_path, jobs=1, output=tmp_path / "report.json", runner=runner, base="deadbeef")

    goal_calls = [c for c in audit_calls if "--allow-sorry" in c]
    assert goal_calls, "the goal audit must run"
    for call in goal_calls:
        mods = [a for a in call if a.startswith("goals.")]
        assert not ("goals.brualdi-ch1-10" in mods and "goals.brualdi-ch1-16" in mods), \
            "colliding goals were passed to the same axiom_audit import"
    # both goals are still audited, just in separate calls
    audited = {m for c in goal_calls for m in c if m.startswith("goals.")}
    assert {"goals.brualdi-ch1-10", "goals.brualdi-ch1-16"} <= audited
