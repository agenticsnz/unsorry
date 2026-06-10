"""Lean goal-statement parsing, shared by the agent loop (`swarm/agent.sh`)
and the Gate A statement-binding check (`tools/gate_a`).

A prove goal is `goals/<id>.lean` = an optional `import`, then
`theorem <name> <signature> := by sorry`. These helpers extract the parts the
swarm needs: the content-addressed statement, the theorem name, the CamelCase
module name, and — for the ADR-011 binding obligation — the goal's type as a
closed ∀-expression. Kept dependency-free (stdlib only) so any tool can import
it.
"""
from __future__ import annotations

import hashlib
import re


def camel_name(goal: str) -> str:
    """CamelCase library-module name from a goal id (Id grammar
    `[a-z0-9][a-z0-9-]*`): split on '-', capitalize each part, join.
    `nat-add-comm-thm` → `NatAddCommThm`."""
    parts = [p for p in goal.split("-") if p]
    if not parts:
        raise ValueError(f"empty goal id {goal!r}")
    return "".join(p[:1].upper() + p[1:] for p in parts)


def _decl_body(lean_text: str) -> str:
    """The source with `import`/`--`-comment lines dropped."""
    return "\n".join(
        ln for ln in lean_text.splitlines()
        if not ln.lstrip().startswith(("--", "import"))
    )


def statement(lean_text: str) -> str:
    """Canonical statement string: the `theorem`/`lemma` declaration with the
    proof (`:=` onward) cut and whitespace collapsed. This string IS the content
    the library index addresses."""
    body = _decl_body(lean_text)
    match = re.search(r"\b(?:theorem|lemma)\b", body)
    if match is None:
        raise ValueError("goal .lean has no theorem/lemma declaration")
    decl = body[match.start():]
    cut = decl.find(":=")
    if cut == -1:
        raise ValueError("goal .lean theorem has no ':=' proof separator")
    return re.sub(r"\s+", " ", decl[:cut]).strip()


def theorem_name(lean_text: str) -> str:
    """The declared name of `theorem <name> …` / `lemma <name> …`."""
    match = re.search(r"\b(?:theorem|lemma)\s+([A-Za-z_][A-Za-z0-9_']*)", lean_text)
    if match is None:
        raise ValueError("goal .lean has no named theorem/lemma")
    return match.group(1)


def statement_sha(lean_text: str) -> str:
    """Content address: sha256 (lowercase hex) of `statement`."""
    return hashlib.sha256(statement(lean_text).encode("utf-8")).hexdigest()


def foralltype(lean_text: str) -> str:
    """The goal theorem's TYPE as a closed ∀-expression (ADR-011 binding).
    `theorem <n> <binders> : <prop> := …` → `∀ <binders>, <prop>` (or `<prop>`
    with no binders). The binder/prop split is the first `:` at bracket depth 0
    — binder colons sit inside `()`/`{}`/`[]`."""
    body = _decl_body(lean_text)
    match = re.search(r"\b(?:theorem|lemma)\s+[A-Za-z_][A-Za-z0-9_']*", body)
    if match is None:
        raise ValueError("goal .lean has no named theorem/lemma")
    decl = body[match.end():]
    cut = decl.find(":=")
    if cut == -1:
        raise ValueError("goal .lean theorem has no ':=' proof separator")
    sig = decl[:cut]
    depth = 0
    split = -1
    for i, ch in enumerate(sig):
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == ":" and depth == 0:
            split = i
            break
    if split == -1:
        raise ValueError("goal theorem signature has no top-level ':'")
    binders = re.sub(r"\s+", " ", sig[:split]).strip()
    prop = re.sub(r"\s+", " ", sig[split + 1:]).strip()
    return f"∀ {binders}, {prop}" if binders else prop
