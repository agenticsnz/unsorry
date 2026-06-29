"""Suite-scoped Lean verifier context (ADR-099 / SPEC-099-A §1).

A benchmark suite is authored against its *own* mathlib (miniF2F/CombiBench are
natively v4.24), so re-elaborating it under the repo-wide pin (v4.30) silently
quarantines every statement that hit an API rename in between. This module
materialises a **suite-scoped lake project** pinned to the suite's declared
``(toolchain, mathlib rev)``, so ingestion (and, later, verification) can run
``lake env lean`` / ``lake build`` under the suite's own pin instead of the repo's.

It is the benchmark analogue of ``tools.archive.apply.cut`` (which scaffolds a
self-contained per-block lake project for a proof archive, ADR-041): same
``lakefile.toml`` template, same ``lean-toolchain`` file, same copied
``lake-manifest.json``, same ``lake exe cache get`` warmup. The single external
seam (``lake exe cache get``) is an injectable ``runner`` so tests never touch lake.

The context lives at ``targets/<suite>/_verify`` — a leading-underscore dir that is
inert to the repo ``lakefile.toml`` globs (``goals.+`` / ``Unsorry.+``) and to
``skeleton-validate``'s ``validate_package`` (which only reads ``skeleton.aisp`` /
``goals/`` / ``decompositions/``). Its built ``.lake/`` is gitignored.
"""
from __future__ import annotations

import re
import shutil
import subprocess
from collections.abc import Callable
from pathlib import Path

Runner = Callable[..., "subprocess.CompletedProcess[str]"]


class VerifierContextError(Exception):
    """The suite-scoped verifier context could not be prepared (e.g. cache warmup failed)."""


def _camel(suite_id: str) -> str:
    """``minif2f-v1`` → ``Minif2fV1`` — a valid Lean lib identifier from a suite id."""
    return "".join(part[:1].upper() + part[1:] for part in re.split(r"[-_]", suite_id) if part)


def verifier_dir(root: Path, suite_id: str) -> Path:
    """The suite-scoped verifier-context directory ``<root>/targets/<suite>/_verify``."""
    return Path(root) / "targets" / suite_id / "_verify"


def _lakefile(suite_id: str, mathlib: str) -> str:
    """The suite ``lakefile.toml`` — the ``tools.archive.apply.cut`` template with the
    mathlib ``rev`` pinned to the suite's native rev and a name derived from ``suite_id``."""
    camel = _camel(suite_id)
    return (
        f'name = "{camel[0].lower() + camel[1:]}"\n'
        'version = "0.1.0"\n'
        'keywords = ["math", "benchmark", "unsorry"]\n'
        f'defaultTargets = ["{camel}"]\n\n'
        "[leanOptions]\n"
        "pp.unicode.fun = true\n"
        "autoImplicit = false\n"
        "relaxedAutoImplicit = false\n\n"
        "[[require]]\n"
        'name = "mathlib"\n'
        'scope = "leanprover-community"\n'
        f'rev = "{mathlib}"\n\n'
        "[[lean_lib]]\n"
        f'name = "{camel}"\n'
        'srcDir = "library"\n'
        'globs = ["Unsorry.+"]\n'
    )


def scaffold(root: Path, suite_id: str, *, toolchain: str, mathlib: str, manifest_src: Path) -> Path:
    """Write ``_verify/{lean-toolchain, lakefile.toml, lake-manifest.json}`` for the suite.

    Idempotent and deterministic: the same ``(toolchain, mathlib, manifest_src)`` yields
    byte-identical files, so a re-run is a no-op on content. ``manifest_src`` is the
    suite's native ``lake-manifest.json`` (operator-supplied; ADR-099 decision A) and is
    copied verbatim so the transitive dependency revs resolve.
    """
    vctx = verifier_dir(root, suite_id)
    vctx.mkdir(parents=True, exist_ok=True)
    (vctx / "lean-toolchain").write_text(toolchain.rstrip("\n") + "\n", encoding="utf-8")
    (vctx / "lakefile.toml").write_text(_lakefile(suite_id, mathlib), encoding="utf-8")
    shutil.copyfile(manifest_src, vctx / "lake-manifest.json")
    return vctx


def warm_cache(vctx: Path, *, runner: Runner) -> int:
    """``lake exe cache get`` in the suite project — fetch the suite pin's mathlib oleans
    from the FRO binary cache. Returns the process return code. The sole subprocess seam."""
    result = runner(
        ("lake", "exe", "cache", "get"),
        cwd=str(vctx), capture_output=True, text=True,
    )
    return result.returncode


def ensure_verifier_context(
    root: Path,
    suite_id: str,
    *,
    toolchain: str,
    mathlib: str,
    manifest_src: Path,
    runner: Runner,
    warm: bool = True,
) -> Path:
    """Scaffold the suite verifier context and (unless ``warm=False``) warm its mathlib
    cache. A failed warmup raises :class:`VerifierContextError` — a benchmark suite must
    never silently fall back to the repo pin (that is the bug ADR-099 fixes)."""
    vctx = scaffold(root, suite_id, toolchain=toolchain, mathlib=mathlib, manifest_src=manifest_src)
    if warm:
        rc = warm_cache(vctx, runner=runner)
        if rc != 0:
            raise VerifierContextError(
                f"`lake exe cache get` failed (rc={rc}) in {vctx} — cannot verify "
                f"suite {suite_id!r} at its pin {mathlib!r}"
            )
    return vctx
