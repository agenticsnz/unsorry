"""Seedkit import-safety and generator/writer agreement regression tests.

Two invariants the family split must keep:

1. **Import-safety.** A writer imports its generator only to reuse the family
   tables/helpers (`FAMILIES`, `sides`, …); importing a module must therefore
   have *no* side effects — in particular it must not run the enumeration and
   print to stdout. The original `gen_hard` ran its body at import, so
   `mkfiles_hard` importing it leaked generator lines into the writer's output
   and corrupted the batch. Every module now guards its CLI behind
   ``if __name__ == "__main__":``; this test fails if any module regresses.

2. **Generator/writer statement agreement.** The generator emits the content
   address (sha) of the goal statement; the writer independently rebuilds that
   statement to mint the artifact. If the two ever drift, the index would
   address a statement the goal file does not contain. This checks they agree.
"""

from __future__ import annotations

import os
import subprocess
import sys

import pytest

from conftest import REPO_ROOT, SEEDKIT

import tools.lean_sig as LS  # noqa: E402

# Every importable seedkit module (scripts + shared helpers), discovered so new
# families are covered automatically.
MODULES = sorted(
    p.stem for p in SEEDKIT.glob("*.py") if not p.stem.startswith("__")
)


@pytest.mark.parametrize("module", MODULES)
def test_module_imports_silently(module: str) -> None:
    """Importing any seedkit module prints nothing and exits 0 (no main-on-import)."""
    proc = subprocess.run(
        [sys.executable, "-c", f"import {module}"],
        cwd=REPO_ROOT,
        env={**os.environ, "PYTHONPATH": f"{REPO_ROOT}{os.pathsep}{SEEDKIT}"},
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0, proc.stderr
    assert proc.stdout == "", f"{module} printed on import:\n{proc.stdout}"


# One representative goal per family: (generator module, writer module, call).
# Each entry resolves a concrete candidate, then asserts the sha the generator
# would publish equals the sha the writer embeds and the statement it writes.
def _residue_sample():
    import gen_residue
    import mkfiles_residue
    fam = "sum-two-squares"
    m, r = gen_residue.candidates(fam, 24, 1, set())[0]
    name = gen_residue.goal_id(fam, m, r).replace("-", "_")
    gen_sha = LS.statement_sha(gen_residue.statement_lean(fam, m, r, name))
    return gen_sha, lambda: mkfiles_residue.write_goal(fam, m, r)


def _telescoping_sample():
    import gen_telescoping
    import mkfiles_telescoping
    shape, a = "cube", 1
    name = gen_telescoping.goal_id(shape, a).replace("-", "_")
    gen_sha = LS.statement_sha(gen_telescoping.statement_lean(shape, a, name))
    return gen_sha, lambda: mkfiles_telescoping.write_goal(shape, a)


def _faulhaber_sample():
    import gen_faulhaber
    import mkfiles_faulhaber
    fam, v = "faulhaber-cube", 2
    name = gen_faulhaber.sides(fam, v)[0].replace("-", "_")
    gen_sha = LS.statement_sha(gen_faulhaber.statement_lean(fam, v, name))
    return gen_sha, lambda: mkfiles_faulhaber.write_goal(fam, v)


def _gzmod_sample():
    import gen_gzmod
    import mkfiles
    M, a, b = 156, 7, 3
    name = gen_gzmod.goal_id(M, a, b).replace("-", "_")
    gen_sha = LS.statement_sha(gen_gzmod.statement_lean(M, a, b, name))
    return gen_sha, lambda: mkfiles.write_goal(M, a, b)


def _single_param_sample(gen_mod_name, mk_mod_name, param):
    """Shared shape for the single-parameter closed-form/divisibility families:
    the generator's `goal_id`/`statement_lean` and the writer's `write_goal` all
    take one integer parameter."""
    import importlib
    gen = importlib.import_module(gen_mod_name)
    mk = importlib.import_module(mk_mod_name)
    name = gen.goal_id(param).replace("-", "_")
    gen_sha = LS.statement_sha(gen.statement_lean(param, name))
    return gen_sha, lambda: mk.write_goal(param)


def _arith_sample():
    return _single_param_sample("gen_arith", "mkfiles_arith", 61)


def _shiftsq_sample():
    return _single_param_sample("gen_shiftsq", "mkfiles_shiftsq", 61)


def _oddsq_sample():
    return _single_param_sample("gen_oddsq", "mkfiles_oddsq", 61)


def _altgeom_sample():
    return _single_param_sample("gen_altgeom", "mkfiles_altgeom", 61)


def _factdvd_sample():
    return _single_param_sample("gen_factdvd", "mkfiles_factdvd", 4)


@pytest.mark.parametrize(
    "sample",
    [_gzmod_sample, _residue_sample, _telescoping_sample, _faulhaber_sample,
     _arith_sample, _shiftsq_sample, _oddsq_sample, _altgeom_sample,
     _factdvd_sample],
    ids=["gzmod", "residue", "telescoping", "faulhaber",
         "arith", "shiftsq", "oddsq", "altgeom", "factdvd"],
)
def test_generator_writer_agree(sample, tmp_path, monkeypatch) -> None:
    """Generator-published sha == writer-embedded sha == written statement's sha."""
    gen_sha, write = sample()
    monkeypatch.chdir(tmp_path)
    line = write()
    gid, _name, _mod, writer_sha = line.split("|")
    assert writer_sha == gen_sha
    written = (tmp_path / "goals" / f"{gid}.lean").read_text(encoding="utf-8")
    assert LS.statement_sha(written) == gen_sha
