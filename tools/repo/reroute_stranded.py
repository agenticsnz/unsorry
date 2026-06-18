"""Re-route a stranded direct proof PR through the accepted queued path (ADR-058).

Direct ``prove(...)`` PRs are no longer accepted — the queued-proof cutover
(``tools/repo/pr_admission.py``) labels them ``blocked-direct-submit`` and closes
them, and pre-cutover ones flood Gate A and strand with ``gate-a-audit`` /
``gate-a-replay`` perpetually queued.

A proof already written on a blocked direct-submission branch can be recovered
**without re-proving**: the queued dispatcher (``swarm/agent.sh
--dispatch-queue``) only *re-packages* an existing branch into a PR, and Gate A
re-verifies it from scratch (no soundness is trusted from the stranded run). This
tool copies a stranded PR's proof files onto a fresh ``queued/prove/<goal>/...``
branch off the current ``origin/main``, Gate-B-validates the tree, and (with
``--push``) pushes it so the dispatcher meters it into CI under the submission
governor.

Self-contained (``import Mathlib``) proofs re-route cleanly; a proof that imports
a now-archived ``Unsorry.*`` module fails Gate A on dispatch — which is the safe
outcome (the proof genuinely no longer builds on current ``main``).

Usage:
  python3 -m tools.repo.reroute_stranded --pr 1578            # build + Gate B, no push
  python3 -m tools.repo.reroute_stranded --pr 1578 --push     # also push the queued branch
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys


QUEUE_PREFIX = "queued/prove/"

# The four file kinds a proof PR adds/changes; everything else on the stranded
# branch (e.g. a stale view of other goals from an older main) is ignored.
_PROOF_MATCHERS = (
    lambda p: p.startswith("library/Unsorry/") and p.endswith(".lean"),
    lambda p: p.startswith("library/index/") and p.endswith(".aisp"),
    lambda p: p.startswith("goals/") and p.endswith(".aisp"),
    lambda p: p.startswith("proof-runs/"),
)

_PROVE_TITLE_RE = re.compile(r"^prove\((?P<goal>[^)]+)\):\s*(?P<name>.+?)(?:\s+by\s+\S+)?\s*$")


def is_proof_file(path: str) -> bool:
    """True iff ``path`` is one of the proof-tree files a queued branch should carry."""
    return any(match(path) for match in _PROOF_MATCHERS)


def queued_branch(goal: str, token: str) -> str:
    """The accepted queued branch name for ``goal`` — admitted by pr_admission."""
    return f"{QUEUE_PREFIX}{goal}/reroute-{token}"


def parse_prove_title(title: str) -> tuple[str, str]:
    """Split a ``prove(<goal>): <name> by <who>`` title into ``(goal, name)``.

    Raises ``ValueError`` if ``title`` is not a prove title — the dispatcher only
    accepts a commit whose subject starts ``prove(...):``.
    """
    m = _PROVE_TITLE_RE.match(title.strip())
    if not m:
        raise ValueError(f"not a prove(...) title: {title!r}")
    return m.group("goal"), m.group("name")


# --------------------------------------------------------------- orchestration


def _run(args: list[str], repo: str, capture: bool = False) -> subprocess.CompletedProcess:
    return subprocess.run(
        args, cwd=repo, check=False, text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )


def _gh(args: list[str], repo: str) -> str:
    out = _run(["gh", *args], repo, capture=True)
    if out.returncode != 0:
        raise RuntimeError(f"gh {' '.join(args)} failed: {out.stderr.strip()}")
    return out.stdout.strip()


def reroute(pr: int, repo: str = ".", push: bool = False, remote: str = "origin",
            base: str = "origin/main", token: str | None = None) -> str:
    """Build a queued/prove/* branch from stranded PR ``pr``. Returns the branch name.

    Raises on a non-prove title, an empty proof set, or a Gate B failure.
    """
    token = token or os.urandom(3).hex()
    title = _gh(["pr", "view", str(pr), "--json", "title", "--jq", ".title"], repo)
    goal, _name = parse_prove_title(title)
    branch = queued_branch(goal, token)

    _run(["git", "fetch", "-q", remote], repo)
    if _run(["git", "fetch", "-q", remote, f"pull/{pr}/head"], repo).returncode != 0:
        raise RuntimeError(f"could not fetch pull/{pr}/head")
    merge_base = _run(["git", "merge-base", base, "FETCH_HEAD"], repo, capture=True).stdout.strip()

    _run(["git", "checkout", "-q", "-f", "--detach", base], repo)
    _run(["git", "clean", "-fdq", "--", "library", "goals", "proof-runs"], repo)
    _run(["git", "checkout", "-q", "-B", branch, base], repo)

    changed = _run(["git", "diff", "--name-only", merge_base, "FETCH_HEAD"], repo, capture=True).stdout.split()
    proof_files = [f for f in changed if is_proof_file(f)]
    if not proof_files:
        raise RuntimeError(f"PR #{pr} changes no proof files")
    for f in proof_files:
        _run(["git", "checkout", "-q", "FETCH_HEAD", "--", f], repo)
    _run(["git", "add", "-A"], repo)

    gb = _run([sys.executable, "-m", "tools.gate_b", "validate", "."], repo, capture=True)
    if gb.returncode != 0:
        _run(["git", "checkout", "-q", "-f", "--detach", base], repo)
        _run(["git", "branch", "-qD", branch], repo)
        raise RuntimeError(f"PR #{pr} ({goal}) fails Gate B on current {base}:\n{gb.stdout}{gb.stderr}")

    _run(["git", "commit", "-q", "-m", title], repo)
    if push:
        if _run(["git", "push", "-q", remote, branch], repo).returncode != 0:
            raise RuntimeError(f"failed to push {branch}")
    return branch


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="python3 -m tools.repo.reroute_stranded")
    p.add_argument("--pr", type=int, required=True, help="stranded direct proof PR number")
    p.add_argument("--push", action="store_true", help="push the queued branch (else build + Gate B only)")
    p.add_argument("--repo", default=".", help="repository root (default: cwd)")
    p.add_argument("--remote", default="origin")
    p.add_argument("--base", default="origin/main")
    args = p.parse_args(argv)
    try:
        branch = reroute(args.pr, repo=args.repo, push=args.push, remote=args.remote, base=args.base)
    except (RuntimeError, ValueError) as exc:
        print(f"reroute #{args.pr}: {exc}", file=sys.stderr)
        return 1
    print(f"{'pushed' if args.push else 'built'} {branch}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
