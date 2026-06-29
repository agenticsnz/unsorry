from pathlib import Path

from tools.gate_a import nanoda_gate as ng
from tools.gate_a.parallel_modules import AuditScope


def _scope(library, goals=(), mode="incremental"):
    return AuditScope(list(library), list(goals), mode)


# --- pure: exit-code mapping ------------------------------------------------

def test_gate_exit_code():
    assert ng.gate_exit_code({"covered": True, "ok": True}) == 0     # pass
    assert ng.gate_exit_code({"covered": True, "ok": False}) == 1    # fail
    assert ng.gate_exit_code({"covered": False}) == 2                # fall back to real audit


# --- full scope ⇒ NOT covered (fail-closed fallback) ------------------------

def test_full_scope_reports_not_covered(monkeypatch, tmp_path):
    monkeypatch.setattr(ng, "compute_audit_targets", lambda root, base: _scope([], [], "full"))
    # check_proof must NOT be called when we bail to the real audit
    monkeypatch.setattr(ng, "check_proof", lambda *a, **k: (_ for _ in ()).throw(AssertionError("called")))
    r = ng.nanoda_gate(tmp_path, None, ("lean4export",), ("nanoda",), tmp_path)
    assert r["covered"] is False and r["mode"] == "full"
    assert ng.gate_exit_code(r) == 2
    assert "real axiom_audit" in ng.render_summary(r)


# --- incremental: every library proof checked, axioms enforced --------------

def test_incremental_all_pass(monkeypatch, tmp_path):
    monkeypatch.setattr(ng, "compute_audit_targets",
                        lambda root, base: _scope(["Unsorry.A", "Unsorry.B"], ["Unsorry.G"]))
    seen = []

    def fake_check(root, module, l4e, nan, export_dir, *a, **k):
        seen.append((module, k.get("enforce_axioms")))
        return {"module": module, "status": "ok", "target_confirmed": True}

    monkeypatch.setattr(ng, "check_proof", fake_check)
    r = ng.nanoda_gate(tmp_path, "BASE", ("lean4export",), ("nanoda",), tmp_path)
    assert r["covered"] is True and r["ok"] is True
    assert r["library_count"] == 2 and r["goal_count"] == 1   # goals counted, not nanoda-checked
    assert seen == [("Unsorry.A", True), ("Unsorry.B", True)]  # only library; axioms ENFORCED
    assert ng.gate_exit_code(r) == 0


def test_incremental_one_fails_makes_gate_fail(monkeypatch, tmp_path):
    monkeypatch.setattr(ng, "compute_audit_targets",
                        lambda root, base: _scope(["Unsorry.A", "Unsorry.B"]))

    def fake_check(root, module, *a, **k):
        ok = module == "Unsorry.A"
        return {"module": module, "status": "ok" if ok else "error",
                "target_confirmed": ok, "stderr": "" if ok else "unpermitted axiom sorryAx"}

    monkeypatch.setattr(ng, "check_proof", fake_check)
    r = ng.nanoda_gate(tmp_path, "BASE", ("lean4export",), ("nanoda",), tmp_path)
    assert r["covered"] is True and r["ok"] is False
    assert ng.gate_exit_code(r) == 1
    summary = ng.render_summary(r)
    assert "FAIL" in summary and "Unsorry.B" in summary and "sorryAx" in summary


def test_target_not_confirmed_fails_even_if_status_ok(monkeypatch, tmp_path):
    # a deps-only export (ok but theorem absent) must NOT pass the gate
    monkeypatch.setattr(ng, "compute_audit_targets", lambda root, base: _scope(["Unsorry.A"]))
    monkeypatch.setattr(ng, "check_proof",
                        lambda *a, **k: {"module": "Unsorry.A", "status": "ok", "target_confirmed": False})
    r = ng.nanoda_gate(tmp_path, "BASE", ("lean4export",), ("nanoda",), tmp_path)
    assert r["ok"] is False and ng.gate_exit_code(r) == 1
