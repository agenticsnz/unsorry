"""Contributor-side independent (kernel-diverse) proof check — ADR-096 Phase 3a.

ADVISORY and NON-GATING. After `swarm/agent.sh::prove_local_verify` accepts a
proof, this re-verifies it with an *independent* Lean kernel (`nanoda`) over a
declaration-scoped `lean4export` of the proved theorem — a second-kernel
confirmation. It admits nothing, gates nothing, and is strictly subordinate to
ADR-049's `p = 1` Lean gate (which still runs in CI regardless). A disagreement is
surfaced as a warning, never a block.

It reuses the pilot primitives (`tools.pilot.export_checker_pilot`) — DRY — so the
production check and the validated pilot share one implementation.
"""
from __future__ import annotations

import json
import subprocess
import time
from pathlib import Path
from typing import Callable, Sequence

from tools.pilot.export_checker_pilot import (
    export_capture,
    module_source_decls,
    nanoda_config,
    parse_declars_checked,
    sha256_hex,
    swap_two_theorem_values,
    timed_checker,
)

Runner = Callable[..., subprocess.CompletedProcess]


def check_proof(
    root: Path,
    module: str,
    lean4export_cmd: Sequence[str],
    nanoda_cmd: Sequence[str],
    export_dir: Path,
    runner: Runner = subprocess.run,
    clock: Callable[[], float] = time.perf_counter,
    timeout: float = 300.0,
    negative_control: bool = False,
) -> dict:
    """Independently re-check one proved module's own theorem(s). Returns a verdict
    dict: status (`ok`/`error`/`incompatible`/`timeout`/`export-failed`/`no-decls`),
    seconds, export_bytes, export_sha256, declars, target_confirmed, and (if
    requested) nc_rejected. `ok` + target_confirmed ⇒ the independent kernel agrees
    the proof checks and the theorem is genuinely present (not a deps-only export)."""
    export_dir.mkdir(parents=True, exist_ok=True)
    decls = module_source_decls(root, module)
    if not decls:
        return {"module": module, "status": "no-decls"}
    data = export_capture(module, lean4export_cmd, runner, scope_decls=decls)
    if data is None:
        return {"module": module, "status": "export-failed"}

    export_path = export_dir / f"{module}.export"
    export_path.write_bytes(data)
    config_path = export_dir / f"{module}.nanoda.json"
    config_path.write_text(json.dumps(nanoda_config(export_path, confirm_decls=decls)), encoding="utf-8")

    seconds, status, stderr, stdout = timed_checker((*nanoda_cmd, str(config_path)), runner, clock, timeout)
    verdict = {
        "module": module,
        "status": status,
        "seconds": seconds,
        "export_bytes": len(data),
        "export_sha256": sha256_hex(data),
        "declars": parse_declars_checked(stdout),
        "target_confirmed": status == "ok",  # pp_declars guard ⇒ ok means target present
        "stderr": stderr if status != "ok" else "",
    }
    if negative_control and status == "ok":
        mutated = swap_two_theorem_values(data.decode("utf-8", "replace"))
        if mutated is not None:
            bad = export_dir / f"{module}.bad.export"
            bad.write_text(mutated, encoding="utf-8")
            bad_cfg = export_dir / f"{module}.bad.nanoda.json"
            bad_cfg.write_text(json.dumps(nanoda_config(bad)), encoding="utf-8")
            _, bad_status, _, _ = timed_checker((*nanoda_cmd, str(bad_cfg)), runner, clock, timeout)
            verdict["nc_rejected"] = bad_status != "ok"
    return verdict


def verdict_line(v: dict) -> str:
    """One-line human summary for the agent log."""
    s = v["status"]
    if s in ("no-decls", "export-failed"):
        return f"independent-check: {v['module']} — {s} (skipped)"
    parts = [
        f"independent-check: {v['module']}",
        f"nanoda={s}",
        f"decls={v.get('declars')}",
        f"target={'✓' if v.get('target_confirmed') else '✗'}",
        f"{v.get('seconds')}s",
        f"{v.get('export_bytes')}B",
    ]
    if "nc_rejected" in v:
        parts.append(f"neg-ctrl={'rejected✓' if v['nc_rejected'] else 'ACCEPTED✗'}")
    if s != "ok":
        parts.append(f"— {v.get('stderr', '')}")
    return " ".join(parts)
