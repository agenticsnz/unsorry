import json
import subprocess
from pathlib import Path

from tools.independent_check import check_proof, verdict_line
from tools.independent_check.__main__ import main


def completed(argv, returncode=0, stdout=b"", stderr=""):
    return subprocess.CompletedProcess(tuple(argv), returncode, stdout, stderr)


def _lib(tmp_path, module="Unsorry.Foo", theorem="foo_thm"):
    d = tmp_path / "library" / Path(*module.split(".")[:-1])
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{module.split('.')[-1]}.lean").write_text(
        f"import Mathlib\ntheorem {theorem} : True := trivial\n"
    )


def _ndjson(*objs):
    return "\n".join(json.dumps(o) for o in objs)


def clock_seq(*vals):
    it = iter(vals)
    return lambda: next(it)


def test_check_proof_ok_scopes_export_and_confirms_target(tmp_path):
    _lib(tmp_path)
    export = _ndjson({"meta": {}}, {"thm": {"name": 1, "type": 1, "value": 10, "all": []}})
    seen = []

    def runner(argv, check=False, capture_output=False, timeout=None):
        argv = tuple(argv)
        seen.append(argv)
        if argv[0] == "lean4export":
            return completed(argv, stdout=export.encode())
        if argv[0] == "nanoda":
            return completed(argv, returncode=0, stdout="Checked 1502 declarations with no errors")
        return completed(argv)

    v = check_proof(tmp_path, "Unsorry.Foo", ("lean4export",), ("nanoda",), tmp_path / "exp",
                    runner=runner, clock=clock_seq(0.0, 0.4), timeout=300)
    assert v["status"] == "ok"
    assert v["target_confirmed"] is True
    assert v["declars"] == 1502
    assert v["export_bytes"] == len(export.encode())
    # lean4export was declaration-SCOPED to the module's own theorem
    l4e = next(c for c in seen if c[0] == "lean4export")
    assert "--" in l4e and "foo_thm" in l4e


def test_check_proof_skips_when_no_decls(tmp_path):
    # module file absent → no decls → skipped, never crashes
    v = check_proof(tmp_path, "Unsorry.Missing", ("lean4export",), ("nanoda",), tmp_path / "exp",
                    runner=lambda *a, **k: completed(("x",)))
    assert v["status"] == "no-decls"


def test_check_proof_export_failure_is_clean(tmp_path):
    _lib(tmp_path)

    def runner(argv, check=False, capture_output=False, timeout=None):
        argv = tuple(argv)
        if argv[0] == "lean4export":
            return completed(argv, returncode=1)  # export failed
        return completed(argv)

    v = check_proof(tmp_path, "Unsorry.Foo", ("lean4export",), ("nanoda",), tmp_path / "exp", runner=runner)
    assert v["status"] == "export-failed"


def test_check_proof_negative_control(tmp_path):
    _lib(tmp_path)
    export = _ndjson(
        {"thm": {"name": 1, "type": 1, "value": 10, "all": []}},
        {"thm": {"name": 2, "type": 2, "value": 20, "all": []}},
    )

    def runner(argv, check=False, capture_output=False, timeout=None):
        argv = tuple(argv)
        if argv[0] == "lean4export":
            return completed(argv, stdout=export.encode())
        if argv[0] == "nanoda":
            cfg = argv[-1]
            rc = 1 if cfg.endswith(".bad.nanoda.json") else 0  # reject the swapped one
            return completed(argv, returncode=rc, stdout="Checked 2 declarations with no errors" if rc == 0 else "")
        return completed(argv)

    v = check_proof(tmp_path, "Unsorry.Foo", ("lean4export",), ("nanoda",), tmp_path / "exp",
                    runner=runner, clock=clock_seq(0.0, 0.4, 0.0, 0.2), negative_control=True)
    assert v["status"] == "ok"
    assert v["nc_rejected"] is True


def test_verdict_line_human_readable():
    v = {"module": "Unsorry.Foo", "status": "ok", "seconds": 0.4, "export_bytes": 14000000,
         "declars": 1502, "target_confirmed": True}
    line = verdict_line(v)
    assert "Unsorry.Foo" in line and "nanoda=ok" in line and "target=✓" in line


def test_cli_exit0_on_disagreement_but_warns(tmp_path, capsys, monkeypatch):
    # nanoda REJECTS a locally-accepted proof → advisory: exit 0, warn (never block)
    def fake_check(*a, **k):
        return {"module": "Unsorry.Foo", "status": "error", "seconds": 0.1,
                "export_bytes": 100, "export_sha256": "x", "declars": None,
                "target_confirmed": False, "stderr": "type mismatch"}

    # __main__ binds check_proof at import → patch it there, not on the package.
    monkeypatch.setattr("tools.independent_check.__main__.check_proof", fake_check)
    rc = main(["--module", "Unsorry.Foo", "--root", str(tmp_path)])
    assert rc == 0  # advisory — never fails the caller
    err = capsys.readouterr().err
    assert "::warning::independent-check disagreement" in err


def test_cli_exit2_on_tooling_error(tmp_path, capsys, monkeypatch):
    def boom(*a, **k):
        raise RuntimeError("nanoda binary not found")

    monkeypatch.setattr("tools.independent_check.__main__.check_proof", boom)
    rc = main(["--module", "Unsorry.Foo", "--root", str(tmp_path)])
    assert rc == 2  # tooling failure (distinct from a proof disagreement)
    assert "tooling error" in capsys.readouterr().err
