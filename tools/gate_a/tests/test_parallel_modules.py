import json
import subprocess
from pathlib import Path

from tools.gate_a.parallel_modules import audit, module_names, replay, split_evenly


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
    # leanchecker holds ~all of mathlib resident per process, so even two
    # concurrent invocations OOM-kill a standard CI runner (exit 143 in the
    # replay step, observed repo-wide after #264). Replay must run as a single
    # serial leanchecker over every module, regardless of the --jobs request.
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
