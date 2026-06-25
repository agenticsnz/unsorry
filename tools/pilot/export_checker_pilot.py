"""Phase-3 pilot driver (ADR-093 / SPEC-093-A): measure lean4export determinism
(Q2) and nanoda wall-clock / timeout (Q3) on real library closures.

OBSERVE-ONLY. This admits no content and is never on a soundness path — it runs
external tools, records numbers, and writes a report. The authoritative gate
(`leanchecker`-on-locally-rebuilt-environment) is untouched.

For each sampled library module it:
  1. runs `lean4export` `--runs` times → export bytes + sha256, and compares the
     sha across runs (Q2 cross-run determinism);
  2. runs `nanoda` against the export under `--timeout` → wall-clock + status (Q3);
  3. times `leanchecker` on the same module → the nanoda/leanchecker ratio (Q3).

It emits `pilot-report.json` (per-module rows + summary) and `pilot-report.md`
(human summary). The tool invocations are injectable (a `runner` + `clock`) so the
pure metric/aggregation logic is unit-tested without the real tools (SPEC-093-A §5).

Usage:
  python3 -m tools.pilot.export_checker_pilot \
    --modules 10 --runs 2 --timeout 300 \
    --lean4export-cmd "lake env lean4export" \
    --nanoda-cmd "nanoda" --leanchecker-cmd "lake env leanchecker" \
    --output-json pilot-report.json --output-md pilot-report.md
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shlex
import subprocess
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Callable, Sequence

from tools.gate_a.parallel_modules import module_names

Runner = Callable[..., subprocess.CompletedProcess]
Clock = Callable[[], float]

# The ">100× slower than Lean" definitional-equality pathology ADR-049 / ADR-093
# flag as the gate on whether an independent checker could ever be a second anchor.
PATHOLOGY_RATIO = 100.0

# nanoda_bin takes a single arg: a path to a JSON config (there is no CLI). The
# config names the export and the permitted axioms. We permit the project's audit
# whitelist {propext, Classical.choice, Quot.sound} plus Lean.trustCompiler, which
# lean4export emits; unpermitted_axiom_hard_error is false so a declared-but-unused
# sorryAx in the prelude doesn't abort startup (per nanoda's README guidance) —
# soundness is unaffected because nanoda still hard-errors if a checked declaration
# actually *uses* a non-permitted axiom.
NANODA_PERMITTED_AXIOMS = ("propext", "Classical.choice", "Quot.sound", "Lean.trustCompiler")


@dataclass
class ModuleResult:
    module: str
    export_bytes: int
    export_sha256: str
    determinism: str  # "stable" | "divergent" | "single" | "failed"
    nanoda_seconds: float | None
    nanoda_status: str  # "ok" | "timeout" | "incompatible" | "error" | "skipped"
    leanchecker_seconds: float | None
    ratio: float | None  # nanoda / leanchecker wall-clock
    pathology: bool  # ratio > PATHOLOGY_RATIO
    nanoda_stderr: str = ""  # tail of nanoda's stderr (diagnostic for non-ok status)
    nanoda_declars_checked: int | None = None  # N from "Checked N declarations" — closure size proof
    target_confirmed: bool | None = None  # the module's own theorem was in nanoda's checked env
    nc_rejected: bool | None = None  # negative control: nanoda REJECTED a swapped (ill-typed) export
    red_team: dict[str, str] | None = None  # broader red-team (§4.1): {class: rejected|ACCEPTED|n/a}


# --- pure helpers (unit-tested directly) ------------------------------------

def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def determinism_verdict(shas: Sequence[str]) -> str:
    """`single` for one run, else `stable` iff all runs hashed identically."""
    if not shas:
        return "failed"
    if len(shas) == 1:
        return "single"
    return "stable" if len(set(shas)) == 1 else "divergent"


def classify_checker(returncode: int, stderr: str) -> str:
    """Map an independent-checker exit to a status. A non-zero exit whose stderr
    reads like a format/parse rejection is `incompatible` (a Q3 finding — the
    checker can't parse this export format), otherwise a genuine `error`."""
    if returncode == 0:
        return "ok"
    low = (stderr or "").lower()
    if any(tok in low for tok in ("parse", "unsupported", "unknown", "format", "unexpected")):
        return "incompatible"
    return "error"


def nanoda_config(
    export_path: Path,
    permitted_axioms: Sequence[str] = NANODA_PERMITTED_AXIOMS,
    confirm_decls: Sequence[str] | None = None,
    unpermitted_axiom_hard_error: bool = False,
) -> dict:
    """The JSON config nanoda_bin consumes (its only argument). Points at the
    export file and permits the audit whitelist; unpermitted axioms are skipped at
    load (not a hard error) but still rejected if a declaration uses one. Set
    `unpermitted_axiom_hard_error=True` to make the mere PRESENCE of an unpermitted
    axiom fatal — the red-team `axiom-restrict` control uses this with an empty
    whitelist to confirm nanoda actually enforces the axiom set (the same path that
    rejects a sneaked `sorryAx`).

    `nat_extension` / `string_extension` MUST be enabled: they default to false in
    nanoda, but real Lean exports contain Nat/String literals, and nanoda
    hard-errors on the first such literal when the extension is off (the run-3
    finding: `Nat lit extension disallowed by checker execution config, but export
    file contains a nat literal`). These are nanoda's native support for Lean's
    GMP-backed Nat and String — required to check any non-trivial export, and the
    README's own example config sets both true.

    `confirm_decls` (the module's own theorem names) are passed as `pp_declars`
    with `unknown_pp_declar_hard_error: true`, so nanoda **hard-errors unless the
    target theorem is present in the checked environment** — guarding the
    degenerate-pass risk (a scoped export that checked only dependencies, not the
    proof). `proofs: false` keeps the pretty-print output small."""
    config = {
        "export_file_path": str(export_path),
        "use_stdin": False,
        "permitted_axioms": list(permitted_axioms),
        "unpermitted_axiom_hard_error": unpermitted_axiom_hard_error,
        "nat_extension": True,
        "string_extension": True,
        "print_success_message": True,
    }
    if confirm_decls:
        config["pp_declars"] = list(confirm_decls)
        config["pp_to_stdout"] = True
        config["unknown_pp_declar_hard_error"] = True
        config["pp_options"] = {"proofs": False}
    return config


_CHECKED_RE = re.compile(r"Checked\s+(\d+)\s+declarations")


def parse_declars_checked(stdout: str) -> int | None:
    """N from nanoda's success message `Checked N declarations with no errors`."""
    m = _CHECKED_RE.search(stdout or "")
    return int(m.group(1)) if m else None


def swap_two_theorem_values(ndjson_text: str) -> str | None:
    """Produce a well-formed-but-ILL-TYPED export by swapping the proof `value` of
    two theorems whose claimed `type` differs (NDJSON: `{"thm": {"type": <Expr>,
    "value": <Expr>, …}}`). After the swap, a theorem claims statement τ_a but is
    proved by a term of type τ_b ≠ τ_a — exactly the "claims X, proves Y" threat
    (SPEC-049-A vacuity/weakened-statement class). A sound checker MUST reject it.
    Returns the mutated NDJSON, or None if fewer than two differently-typed theorems
    exist (can't construct the control). Only the two mutated lines are re-serialised;
    every other line is byte-preserved. Differing `type` index ⇒ different statement
    (the export shares structurally-equal Exprs), so the swap is genuinely ill-typed."""
    lines = ndjson_text.split("\n")
    thms: list[tuple[int, object]] = []  # (line_index, type_index)
    for i, line in enumerate(lines):
        s = line.strip()
        if not s or '"thm"' not in s:
            continue
        try:
            obj = json.loads(s)
        except json.JSONDecodeError:
            continue
        if isinstance(obj, dict) and isinstance(obj.get("thm"), dict) and "value" in obj["thm"]:
            thms.append((i, obj["thm"].get("type")))
    if len(thms) < 2:
        return None
    base_line, base_type = thms[0]
    partner = next(((li, ty) for (li, ty) in thms[1:] if ty != base_type), None)
    if partner is None:
        return None  # all theorems share a type — cannot build an ill-typed swap
    pa, pb = base_line, partner[0]
    oa, ob = json.loads(lines[pa]), json.loads(lines[pb])
    oa["thm"]["value"], ob["thm"]["value"] = ob["thm"]["value"], oa["thm"]["value"]
    lines[pa], lines[pb] = json.dumps(oa), json.dumps(ob)
    return "\n".join(lines)


def swap_two_theorem_types(ndjson_text: str) -> str | None:
    """The TYPE-side analogue of `swap_two_theorem_values`: swap the claimed `type`
    of two differently-typed theorems while KEEPING each proof `value`. After the
    swap a theorem claims statement τ_b but is proved by a term of type τ_a ≠ τ_b —
    the "altered/weakened statement" direction (the export now asserts a statement
    the proof does not prove). A sound checker MUST reject it.

    NB this exercises the kernel's TYPE-MATCHING from the statement side; it is NOT
    a test of genuine *vacuity* — a VALID proof of a genuinely weaker statement is
    well-typed and nanoda will (correctly) ACCEPT it. Catching "valid proof of the
    wrong/weaker goal" is the ADR-011 `*Binding` gate's job (statement == goal),
    not a kernel checker's. See SPEC-096-A §4.1.

    Returns the mutated NDJSON, or None if fewer than two differently-typed theorems
    exist. Only the two mutated lines are re-serialised; all others byte-preserved."""
    lines = ndjson_text.split("\n")
    thms: list[tuple[int, object]] = []  # (line_index, type_index)
    for i, line in enumerate(lines):
        s = line.strip()
        if not s or '"thm"' not in s:
            continue
        try:
            obj = json.loads(s)
        except json.JSONDecodeError:
            continue
        if isinstance(obj, dict) and isinstance(obj.get("thm"), dict) and "type" in obj["thm"]:
            thms.append((i, obj["thm"].get("type")))
    if len(thms) < 2:
        return None
    base_line, base_type = thms[0]
    partner = next(((li, ty) for (li, ty) in thms[1:] if ty != base_type), None)
    if partner is None:
        return None  # all theorems share a type — swapping types is a no-op
    pa, pb = base_line, partner[0]
    oa, ob = json.loads(lines[pa]), json.loads(lines[pb])
    oa["thm"]["type"], ob["thm"]["type"] = ob["thm"]["type"], oa["thm"]["type"]
    lines[pa], lines[pb] = json.dumps(oa), json.dumps(ob)
    return "\n".join(lines)


# A sentinel Expr index far beyond any real export's table — a value reference to
# it cannot resolve, so the export is structurally corrupt.
_DANGLING_INDEX = 2_000_000_000


def corrupt_dangling_reference(ndjson_text: str) -> str | None:
    """Produce a STRUCTURALLY-CORRUPT export: repoint one theorem's proof `value`
    at an out-of-range Expr index (`_DANGLING_INDEX`) that no entry defines. A
    checker that genuinely resolves and type-checks the proof term MUST fail to
    resolve the reference and reject; one that rubber-stamps would pass it.

    Returns the mutated NDJSON, or None if no theorem with a `value` exists. Only
    the one mutated line is re-serialised; all others are byte-preserved."""
    lines = ndjson_text.split("\n")
    for i, line in enumerate(lines):
        s = line.strip()
        if not s or '"thm"' not in s:
            continue
        try:
            obj = json.loads(s)
        except json.JSONDecodeError:
            continue
        if isinstance(obj, dict) and isinstance(obj.get("thm"), dict) and "value" in obj["thm"]:
            obj["thm"]["value"] = _DANGLING_INDEX
            lines[i] = json.dumps(obj)
            return "\n".join(lines)
    return None


# The red-team mutation classes (SPEC-096-A §4.1). Each maps a VALID export to an
# INVALID one that a sound checker MUST reject. `axiom-restrict` is not a mutation
# but a config restriction (empty whitelist), handled separately in red_team_suite.
RED_TEAM_MUTATIONS: dict[str, Callable[[str], "str | None"]] = {
    "value-swap": swap_two_theorem_values,   # proof term ≠ claimed type (value side)
    "type-swap": swap_two_theorem_types,     # claimed type ≠ proof term (statement side)
    "dangling-ref": corrupt_dangling_reference,  # structurally-corrupt export
}


def red_team_verdict(class_name: str, constructable: bool, nanoda_status: str | None) -> str:
    """Pure: classify one red-team case.
      'rejected' → nanoda returned non-ok on the invalid input (SOUND);
      'ACCEPTED' → nanoda returned ok on the invalid input (a soundness FAILURE);
      'n/a'      → the case couldn't be constructed (e.g. <2 theorems, or an
                   axiom-free proof for axiom-restrict) — not a pass and not a fail."""
    if not constructable:
        return "n/a"
    if nanoda_status is None:
        return "n/a"
    return "rejected" if nanoda_status != "ok" else "ACCEPTED"


def red_team_suite(
    canonical_text: str,
    export_dir: Path,
    module: str,
    nanoda_cmd: Sequence[str],
    runner: Runner = subprocess.run,
    clock: Clock = time.perf_counter,
    timeout: float = 300.0,
) -> dict[str, str]:
    """Run every red-team class against THIS export and return {class: verdict}.
    For each NDJSON mutation: write the corrupted export + a plain config (no
    pp_declars — we want the type-check verdict) and require nanoda to reject. Plus
    the config-only `axiom-restrict`: run nanoda on the VALID export with an empty
    permitted-axiom set and `unpermitted_axiom_hard_error` — if the proof uses any
    axiom, nanoda must reject (the enforcement path that also stops a sneaked
    `sorryAx`); an axiom-free proof yields 'n/a'. All-`rejected`/`n/a` = sound."""
    verdicts: dict[str, str] = {}
    for name, mutate in RED_TEAM_MUTATIONS.items():
        mutated = mutate(canonical_text)
        status: str | None = None
        if mutated is not None:
            bad_export = export_dir / f"{module}.{name}.export"
            bad_export.write_text(mutated, encoding="utf-8")
            bad_config = export_dir / f"{module}.{name}.nanoda.json"
            bad_config.write_text(json.dumps(nanoda_config(bad_export)), encoding="utf-8")
            _, status, _, _ = timed_checker((*nanoda_cmd, str(bad_config)), runner, clock, timeout)
        verdicts[name] = red_team_verdict(name, mutated is not None, status)

    # axiom-restrict: VALID export, empty whitelist, presence of any axiom is fatal.
    valid_export = export_dir / f"{module}.axiomvalid.export"
    valid_export.write_text(canonical_text, encoding="utf-8")
    ax_config = export_dir / f"{module}.axiom-restrict.nanoda.json"
    ax_config.write_text(json.dumps(nanoda_config(
        valid_export, permitted_axioms=(), unpermitted_axiom_hard_error=True)), encoding="utf-8")
    _, ax_status, _, _ = timed_checker((*nanoda_cmd, str(ax_config)), runner, clock, timeout)
    # 'rejected' = enforcement confirmed; 'ACCEPTED' here means the proof is
    # axiom-FREE (nothing to enforce) — inconclusive, not a failure → 'n/a'.
    verdicts["axiom-restrict"] = "rejected" if ax_status != "ok" else "n/a"
    return verdicts


def compute_ratio(nanoda_seconds: float | None, leanchecker_seconds: float | None) -> float | None:
    if not nanoda_seconds or not leanchecker_seconds:
        return None
    return nanoda_seconds / leanchecker_seconds


def _pct(values: Sequence[float], q: float) -> float | None:
    """Simple nearest-rank percentile (q in [0,1]); None on empty input."""
    xs = sorted(v for v in values if v is not None)
    if not xs:
        return None
    if q <= 0:
        return xs[0]
    if q >= 1:
        return xs[-1]
    idx = min(len(xs) - 1, int(round(q * (len(xs) - 1))))
    return xs[idx]


def aggregate(results: Sequence[ModuleResult]) -> dict:
    """Pure summary over per-module results — the Q2/Q3 bottom line."""
    n = len(results)
    det = {k: sum(1 for r in results if r.determinism == k) for k in ("stable", "divergent", "single", "failed")}
    multi = det["stable"] + det["divergent"]  # modules exported >1× (determinism is meaningful)
    nstat = {k: sum(1 for r in results if r.nanoda_status == k) for k in ("ok", "timeout", "incompatible", "error", "skipped")}
    sizes = [r.export_bytes for r in results if r.determinism != "failed"]
    n_secs = [r.nanoda_seconds for r in results if r.nanoda_seconds is not None]
    ratios = [r.ratio for r in results if r.ratio is not None]
    pathologies = sum(1 for r in results if r.pathology)

    q2 = (det["stable"] / multi) if multi else None  # cross-run determinism rate
    # Q3 is "bounded" only with real timing evidence: at least one ok nanoda run,
    # no pathology, and no timeouts.
    q3_bounded = (nstat["ok"] > 0 and pathologies == 0 and nstat["timeout"] == 0) if n_secs else None

    # Red-team (§4.1): per-class {rejected,ACCEPTED,n/a} tallies + an overall
    # soundness flag (no class ACCEPTED an invalid input on any module). None when
    # the red-team wasn't run.
    rt_rows = [r.red_team for r in results if r.red_team]
    red_team_summary = None
    if rt_rows:
        classes = ["value-swap", "type-swap", "dangling-ref", "axiom-restrict"]
        per_class = {}
        any_accepted = False
        for c in classes:
            verds = [row.get(c) for row in rt_rows if c in row]
            rej = sum(1 for v in verds if v == "rejected")
            acc = sum(1 for v in verds if v == "ACCEPTED")
            na = sum(1 for v in verds if v == "n/a")
            any_accepted = any_accepted or acc > 0
            per_class[c] = {"rejected": rej, "ACCEPTED": acc, "n/a": na, "total": len(verds)}
        red_team_summary = {"modules": len(rt_rows), "per_class": per_class, "sound": not any_accepted}

    return {
        "modules": n,
        "determinism": {**det, "cross_run_stable_rate": q2},
        "export_bytes": {"p50": _pct(sizes, 0.5), "p95": _pct(sizes, 0.95), "max": _pct(sizes, 1.0)},
        "nanoda": {
            **nstat,
            "seconds_p50": _pct(n_secs, 0.5),
            "seconds_p95": _pct(n_secs, 0.95),
            "seconds_max": _pct(n_secs, 1.0),
        },
        "ratio": {
            "p50": _pct(ratios, 0.5),
            "p95": _pct(ratios, 0.95),
            "max": _pct(ratios, 1.0),
            "pathology_count": pathologies,
            "pathology_threshold": PATHOLOGY_RATIO,
        },
        "red_team": red_team_summary,
        "verdict": {
            "Q2_export_deterministic": (q2 == 1.0) if q2 is not None else None,
            "Q3_wall_clock_bounded": q3_bounded,
            "red_team_sound": (red_team_summary["sound"] if red_team_summary else None),
        },
    }


def render_md(results: Sequence[ModuleResult], summary: dict) -> str:
    v = summary["verdict"]
    def tri(x: bool | None) -> str:
        return "yes ✅" if x is True else ("NO ❌" if x is False else "inconclusive")
    lines = [
        "# lean4export + nanoda pilot report (ADR-093)",
        "",
        "Observe-only. Gates nothing; the authoritative leanchecker gate is unchanged.",
        "",
        f"- **modules sampled:** {summary['modules']}",
        f"- **Q2 — export deterministic across runs:** {tri(v['Q2_export_deterministic'])} "
        f"(stable {summary['determinism']['stable']} / divergent {summary['determinism']['divergent']} "
        f"of {summary['determinism']['stable'] + summary['determinism']['divergent']} multi-run; "
        f"single {summary['determinism']['single']}, failed {summary['determinism']['failed']})",
        f"- **Q3 — nanoda wall-clock bounded (no >{int(PATHOLOGY_RATIO)}× pathology):** {tri(v['Q3_wall_clock_bounded'])}",
        f"  - nanoda status: ok {summary['nanoda']['ok']}, timeout {summary['nanoda']['timeout']}, "
        f"incompatible {summary['nanoda']['incompatible']}, error {summary['nanoda']['error']}, skipped {summary['nanoda']['skipped']}",
        f"  - nanoda seconds p50/p95/max: {summary['nanoda']['seconds_p50']}/{summary['nanoda']['seconds_p95']}/{summary['nanoda']['seconds_max']}",
        f"  - nanoda/leanchecker ratio p50/p95/max: {summary['ratio']['p50']}/{summary['ratio']['p95']}/{summary['ratio']['max']} "
        f"(pathologies > {int(PATHOLOGY_RATIO)}×: {summary['ratio']['pathology_count']})",
        f"  - export bytes p50/p95/max: {summary['export_bytes']['p50']}/{summary['export_bytes']['p95']}/{summary['export_bytes']['max']}",
        "",
    ]
    confirmable = [r for r in results if r.target_confirmed is not None]
    if confirmable:
        confirmed = sum(1 for r in confirmable if r.target_confirmed)
        lines.append(
            f"- **Positive control — target theorem present in nanoda's checked env:** "
            f"{confirmed}/{len(confirmable)} confirmed "
            f"(via `pp_declars` + `unknown_pp_declar_hard_error`; a scoped export that "
            f"checked only dependencies would have hard-errored)"
        )
    nc = [r for r in results if r.nc_rejected is not None]
    if nc:
        rejected = sum(1 for r in nc if r.nc_rejected)
        ok = "✅" if rejected == len(nc) else "❌ SOUNDNESS FAILURE"
        lines.append(
            f"- **Negative control — nanoda REJECTS an ill-typed (proof-value-swapped) export:** "
            f"{rejected}/{len(nc)} rejected {ok} "
            f"(a sound checker must reject a proof whose term no longer matches its statement; "
            f"an *accept* here means nanoda is not actually type-checking)"
        )
    rt = summary.get("red_team")
    if rt:
        ok = "✅" if rt["sound"] else "❌ SOUNDNESS FAILURE"
        lines.append(
            f"- **Broader red-team (§4.1, acceptance gate 1) — nanoda REJECTS every invalid class:** "
            f"{ok} over {rt['modules']} module(s)"
        )
        labels = {
            "value-swap": "value-swap (proof term ≠ claimed type)",
            "type-swap": "type-swap (claimed type ≠ proof term)",
            "dangling-ref": "dangling-ref (structurally-corrupt export)",
            "axiom-restrict": "axiom-restrict (empty whitelist → unpermitted axiom rejected)",
        }
        for c, lab in labels.items():
            pc = rt["per_class"].get(c)
            if not pc:
                continue
            parts = [f"{pc['rejected']}/{pc['total']} rejected"]
            if pc["n/a"]:
                parts.append(f"{pc['n/a']} n/a")
            if pc["ACCEPTED"]:
                parts.append(f"{pc['ACCEPTED']} ACCEPTED ❌")
            lines.append(f"  - {lab}: " + ", ".join(parts))
        lines.append(
            "  - NB genuine *vacuity* (a VALID proof of a weaker statement matching the wrong "
            "goal) is well-typed and correctly ACCEPTED by a kernel checker — catching it is the "
            "ADR-011 `*Binding` gate's job (statement == goal), not nanoda's. See SPEC-096-A §4.1."
        )
    if confirmable or nc or rt:
        lines.append("")
    lines += [
        "| module | determinism | export_bytes | nanoda_s | nanoda | declars | target | neg-ctrl | leanchecker_s | ratio | pathology |",
        "|---|---|---|---|---|---|---|---|---|---|---|",
    ]
    for r in results:
        tgt = "" if r.target_confirmed is None else ("✓" if r.target_confirmed else "✗")
        ncc = "" if r.nc_rejected is None else ("rejected✓" if r.nc_rejected else "ACCEPTED✗")
        lines.append(
            f"| {r.module} | {r.determinism} | {r.export_bytes} | "
            f"{r.nanoda_seconds} | {r.nanoda_status} | {r.nanoda_declars_checked} | {tgt} | {ncc} | "
            f"{r.leanchecker_seconds} | {r.ratio} | {'yes' if r.pathology else ''} |"
        )
    diagnostics = [r for r in results if r.nanoda_stderr]
    if diagnostics:
        lines += ["", "## nanoda diagnostics (stderr tail for non-ok modules)", ""]
        for r in diagnostics:
            lines.append(f"- **{r.module}** ({r.nanoda_status}): `{r.nanoda_stderr}`")
    return "\n".join(lines) + "\n"


# --- orchestration (injectable runner + clock) ------------------------------

def _stdout_bytes(res: subprocess.CompletedProcess) -> bytes:
    out = res.stdout
    if out is None:
        return b""
    return out if isinstance(out, bytes) else out.encode("utf-8", "replace")


def _stderr_text(res: subprocess.CompletedProcess) -> str:
    err = res.stderr
    if err is None:
        return ""
    return err if isinstance(err, str) else err.decode("utf-8", "replace")


_DECL_RE = re.compile(r"^\s*(?:noncomputable\s+)?(?:theorem|lemma|def)\s+([A-Za-z_][A-Za-z0-9_'.]*)", re.MULTILINE)


def module_source_path(root: Path, module: str) -> Path:
    """`Unsorry.AltGeometricRatioEight` -> `library/Unsorry/AltGeometricRatioEight.lean`."""
    return root / "library" / Path(*module.split(".")).with_suffix(".lean")


def module_source_decls(root: Path, module: str) -> list[str]:
    """The declaration names a library module *defines* (its own theorems/defs),
    parsed from source. Used to declaration-SCOPE a lean4export so it emits only
    that proof's transitive *declaration* closure — not the module's whole import
    closure (which is `import Mathlib` = all of mathlib). Root-namespace names; the
    Unsorry library modules use no `namespace`, so the source name is the full name."""
    path = module_source_path(root, module)
    if not path.is_file():
        return []
    return _DECL_RE.findall(path.read_text(encoding="utf-8", errors="replace"))


def export_capture(
    module: str,
    lean4export_cmd: Sequence[str],
    runner: Runner,
    scope_decls: Sequence[str] | None = None,
) -> bytes | None:
    """Run lean4export on one module; return the export bytes, or None on failure.
    With `scope_decls`, exports only those declarations (`Module -- d1 d2 …`) and
    their transitive declaration closure, rather than the whole module."""
    argv = (*lean4export_cmd, module)
    if scope_decls:
        argv = (*argv, "--", *scope_decls)
    res = runner(argv, check=False, capture_output=True)
    if res.returncode != 0:
        return None
    return _stdout_bytes(res)


def _tail(text: str, limit: int = 600) -> str:
    """Last `limit` chars, single-lined, for a compact diagnostic in the report."""
    flat = " ".join((text or "").split())
    return flat[-limit:]


def timed_checker(
    argv: Sequence[str], runner: Runner, clock: Clock, timeout: float
) -> tuple[float | None, str, str, str]:
    """Time a checker invocation. Returns (seconds, status, stderr_tail, stdout).
    A TimeoutExpired → (None, 'timeout', '', ''); otherwise status is
    classify_checker(rc, stderr), stderr_tail is a compact tail of stderr, and
    stdout is the full stdout (nanoda's success message carries the declaration
    count, parsed for the soundness check)."""
    start = clock()
    try:
        res = runner(tuple(argv), check=False, capture_output=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return None, "timeout", "", ""
    seconds = clock() - start
    stderr = _stderr_text(res)
    out = res.stdout
    stdout = "" if out is None else (out if isinstance(out, str) else out.decode("utf-8", "replace"))
    return seconds, classify_checker(res.returncode, stderr), _tail(stderr), stdout


def run_module(
    module: str,
    runs: int,
    lean4export_cmd: Sequence[str],
    nanoda_cmd: Sequence[str],
    leanchecker_cmd: Sequence[str],
    export_dir: Path,
    runner: Runner = subprocess.run,
    clock: Clock = time.perf_counter,
    timeout: float = 300.0,
    scope_decls: Sequence[str] | None = None,
    confirm_decls: Sequence[str] | None = None,
    negative_control: bool = False,
    red_team: bool = False,
) -> ModuleResult:
    exports: list[bytes] = []
    for _ in range(max(1, runs)):
        data = export_capture(module, lean4export_cmd, runner, scope_decls)
        if data is None:
            return ModuleResult(module, 0, "", "failed", None, "skipped", None, None, False)
        exports.append(data)
    shas = [sha256_hex(b) for b in exports]
    determinism = determinism_verdict(shas)
    canonical = exports[0]
    export_path = export_dir / f"{module}.export"
    export_path.write_bytes(canonical)
    # nanoda_bin's only argument is a JSON config that points at the export and
    # lists the permitted axioms — not the export file itself. confirm_decls makes
    # nanoda hard-error unless the module's own theorem is in the checked env.
    config_path = export_dir / f"{module}.nanoda.json"
    config_path.write_text(json.dumps(nanoda_config(export_path, confirm_decls=confirm_decls)), encoding="utf-8")

    nanoda_seconds, nanoda_status, nanoda_stderr, nanoda_stdout = timed_checker(
        (*nanoda_cmd, str(config_path)), runner, clock, timeout)
    leanchecker_seconds, _, _, _ = timed_checker((*leanchecker_cmd, module), runner, clock, timeout)
    ratio = compute_ratio(nanoda_seconds, leanchecker_seconds)
    # target_confirmed: with pp_declars + unknown_pp_declar_hard_error, an 'ok' run
    # means the target theorem was present in the checked environment (else nanoda
    # would have errored). None when we didn't ask for confirmation.
    target_confirmed = (nanoda_status == "ok") if confirm_decls else None

    # NEGATIVE CONTROL: feed nanoda a swapped (ill-typed) copy of THIS export and
    # require it to REJECT — the soundness property that matters. nc_rejected is:
    #   True  → nanoda rejected the ill-typed export (sound on this case);
    #   False → nanoda ACCEPTED an ill-typed export (a soundness FAILURE);
    #   None  → not requested, or the mutation couldn't be constructed.
    nc_rejected: bool | None = None
    if negative_control and nanoda_status == "ok":  # only meaningful if the valid one passed
        mutated = swap_two_theorem_values(canonical.decode("utf-8", "replace"))
        if mutated is not None:
            bad_export = export_dir / f"{module}.bad.export"
            bad_export.write_text(mutated, encoding="utf-8")
            bad_config = export_dir / f"{module}.bad.nanoda.json"
            # No pp_declars here — we want the type-check verdict, not a presence check.
            bad_config.write_text(json.dumps(nanoda_config(bad_export)), encoding="utf-8")
            _, bad_status, _, _ = timed_checker((*nanoda_cmd, str(bad_config)), runner, clock, timeout)
            nc_rejected = bad_status != "ok"  # reject (any non-ok) = sound

    # BROADER RED-TEAM (§4.1, acceptance gate 1): run the full mutation suite —
    # value-swap, type-swap, dangling-ref, axiom-restrict — and require nanoda to
    # reject (or 'n/a') every class. Only meaningful when the valid export passed.
    red_team_results: dict[str, str] | None = None
    if red_team and nanoda_status == "ok":
        red_team_results = red_team_suite(
            canonical.decode("utf-8", "replace"), export_dir, module,
            nanoda_cmd, runner, clock, timeout)
        # Keep nc_rejected coherent with the value-swap class for back-compat.
        if nc_rejected is None and "value-swap" in red_team_results:
            nc_rejected = red_team_results["value-swap"] == "rejected"

    return ModuleResult(
        module=module,
        export_bytes=len(canonical),
        export_sha256=shas[0],
        determinism=determinism,
        nanoda_seconds=nanoda_seconds,
        nanoda_status=nanoda_status,
        leanchecker_seconds=leanchecker_seconds,
        ratio=ratio,
        pathology=bool(ratio and ratio > PATHOLOGY_RATIO),
        nanoda_stderr=nanoda_stderr if nanoda_status not in ("ok", "skipped") else "",
        nanoda_declars_checked=parse_declars_checked(nanoda_stdout),
        target_confirmed=target_confirmed,
        nc_rejected=nc_rejected,
        red_team=red_team_results,
    )


def select_modules(
    root: Path, modules: int, module_list: Sequence[str] | None, spread: bool = False
) -> list[str]:
    if module_list:
        return list(module_list)
    names = module_names(root, "library")
    n = max(0, modules)
    if not spread or n >= len(names) or n == 0:
        return names[:n]
    # Evenly-strided sample across the sorted module list — module names cluster by
    # topic/family (e.g. AltGeometricRatio*), so the first-N sample is homogeneous;
    # striding spreads the sample across families for difficulty/topic diversity.
    step = len(names) / n
    return [names[int(i * step)] for i in range(n)]


def progress_line(index: int, total: int, r: ModuleResult) -> str:
    """One-line live progress for a finished module."""
    err = f" — {r.nanoda_stderr}" if r.nanoda_stderr else ""
    extra = ""
    if r.nanoda_declars_checked is not None:
        extra += f" decls={r.nanoda_declars_checked}"
    if r.target_confirmed is not None:
        extra += f" target={'✓' if r.target_confirmed else '✗'}"
    if r.nc_rejected is not None:
        extra += f" neg-ctrl={'rejected✓' if r.nc_rejected else 'ACCEPTED✗'}"
    if r.red_team:
        marks = {"rejected": "✓", "n/a": "·", "ACCEPTED": "✗"}
        extra += " red-team=[" + " ".join(
            f"{k}:{marks.get(v, v)}" for k, v in r.red_team.items()) + "]"
    return (
        f"[{index}/{total}] {r.module}: determinism={r.determinism} "
        f"nanoda={r.nanoda_status} ({r.nanoda_seconds}s) lc={r.leanchecker_seconds}s "
        f"ratio={r.ratio} bytes={r.export_bytes}{extra}{err}"
    )


def emit_progress(index: int, total: int, r: ModuleResult) -> None:
    """Default progress sink: a flushed stdout line AND an append to
    GITHUB_STEP_SUMMARY, so a long CI run is observable per-module live (the report
    is only readable after the step ends). Each module is one heavy unit of work, so
    emitting on completion gives real-time progress without log spam."""
    line = progress_line(index, total, r)
    print(line, flush=True)
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if path:
        with Path(path).open("a", encoding="utf-8") as handle:
            handle.write(f"- {line}\n")


def run_pilot(
    root: Path,
    sample: Sequence[str],
    runs: int,
    lean4export_cmd: Sequence[str],
    nanoda_cmd: Sequence[str],
    leanchecker_cmd: Sequence[str],
    export_dir: Path,
    runner: Runner = subprocess.run,
    clock: Clock = time.perf_counter,
    timeout: float = 300.0,
    on_progress: Callable[[int, int, ModuleResult], None] = emit_progress,
    scope_decls: bool = False,
    negative_control: bool = False,
    red_team: bool = False,
) -> tuple[list[ModuleResult], dict]:
    export_dir.mkdir(parents=True, exist_ok=True)
    total = len(sample)
    results: list[ModuleResult] = []
    for index, m in enumerate(sample, 1):
        own_decls = module_source_decls(root, m)
        r = run_module(
            m, runs, lean4export_cmd, nanoda_cmd, leanchecker_cmd, export_dir, runner, clock, timeout,
            scope_decls=(own_decls if scope_decls else None),
            confirm_decls=(own_decls or None),
            negative_control=negative_control,
            red_team=red_team,
        )
        results.append(r)
        on_progress(index, total, r)
    return results, aggregate(results)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--root", type=Path, default=Path("."))
    p.add_argument("--modules", type=int, default=10, help="sample the first N library modules")
    p.add_argument("--module-list", default="", help="comma-separated explicit module names (overrides --modules)")
    p.add_argument("--runs", type=int, default=2, help="lean4export runs per module (>=2 to measure determinism)")
    p.add_argument("--timeout", type=float, default=300.0, help="per-checker timeout (seconds)")
    p.add_argument("--lean4export-cmd", default="lake env lean4export")
    p.add_argument("--nanoda-cmd", default="nanoda")
    p.add_argument("--leanchecker-cmd", default="lake env leanchecker")
    p.add_argument("--export-dir", type=Path, default=Path("pilot-exports"))
    p.add_argument("--output-json", type=Path, default=Path("pilot-report.json"))
    p.add_argument("--output-md", type=Path, default=Path("pilot-report.md"))
    p.add_argument(
        "--scope-decls",
        action="store_true",
        help="export only each module's own declarations (Module -- d1 d2 …) and "
        "their transitive declaration closure, not the whole module import closure. "
        "The experiment: does this shrink the ~5.9 GB full-mathlib export (Q4)?",
    )
    p.add_argument(
        "--spread",
        action="store_true",
        help="sample modules evenly across the sorted library (topic/difficulty "
        "diversity) instead of the first N (which cluster by name family).",
    )
    p.add_argument(
        "--negative-control",
        action="store_true",
        help="for each accepted export, ALSO feed nanoda a swapped (ill-typed) copy "
        "and require it to REJECT — the soundness test (does nanoda catch a proof "
        "whose term no longer matches its statement?).",
    )
    p.add_argument(
        "--red-team",
        action="store_true",
        help="for each accepted export, run the full red-team mutation suite "
        "(value-swap, type-swap, dangling-ref, axiom-restrict; SPEC-096-A §4.1, "
        "acceptance gate 1) and require nanoda to reject every constructable class. "
        "Implies --negative-control's value-swap class.",
    )
    args = p.parse_args(argv)

    module_list = [m.strip() for m in args.module_list.split(",") if m.strip()] or None
    sample = select_modules(args.root, args.modules, module_list, spread=args.spread)
    if not sample:
        print("no library modules to sample", flush=True)
        return 2

    results, summary = run_pilot(
        args.root,
        sample,
        args.runs,
        shlex.split(args.lean4export_cmd),
        shlex.split(args.nanoda_cmd),
        shlex.split(args.leanchecker_cmd),
        args.export_dir,
        timeout=args.timeout,
        scope_decls=args.scope_decls,
        negative_control=args.negative_control,
        red_team=args.red_team,
    )
    args.output_json.write_text(
        json.dumps({"summary": summary, "results": [asdict(r) for r in results]}, indent=2) + "\n",
        encoding="utf-8",
    )
    args.output_md.write_text(render_md(results, summary), encoding="utf-8")
    v = summary["verdict"]
    print(f"pilot: {summary['modules']} modules | Q2 deterministic={v['Q2_export_deterministic']} "
          f"Q3 bounded={v['Q3_wall_clock_bounded']} | report -> {args.output_md}")
    return 0  # observe-only: a blocker is a recorded result, never a non-zero exit


if __name__ == "__main__":
    raise SystemExit(main())
