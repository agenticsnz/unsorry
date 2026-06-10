"""Gate B — the in-repo deterministic validator (ADR-003, SPEC-003-A/B/C/D).

Validates the five coordination-record surfaces of a tree root:
``goals/``, ``claims/``, ``translations/``, ``decompositions/`` and
``library/index/``. Absent directories are vacuously valid; nothing else in
the tree is ever scanned. Hygiene only — Gate B can reject records, never
admit anything into the library (that is Gate A's job).
"""
from __future__ import annotations

import hashlib
import json
import re
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

from . import claims as claims_mod
from . import config
from .records import (
    EMPTY,
    Record,
    format_utc_z,
    is_id,
    is_sha256,
    parse_record,
    parse_vector,
    prose_density,
)

GOAL_PHASES = ("translate", "prove")
GOAL_STATUSES = ("open", "flagged", "translated", "blocked", "proved")
SHA_REQUIRED_STATUSES = ("translated", "proved")

_RECORD_TYPES = {
    "goal": ("goal", "unsorry.goal"),
    "claim": ("claim", "unsorry.claim"),
    "translation": ("tr", "unsorry.translation"),
    "decomposition": ("decomp", "unsorry.decomposition"),
    "index": ("lemma", "unsorry.lemma.index"),
}

_SUB_RE = re.compile(r"(?P<label>sub[^≜\s;]*)≜⟨id≜(?P<id>[^,⟩\s]+)\s*,\s*stmt≜(?P<stmt>[^⟩]*)⟩")
_EDGE_RE = re.compile(r"Post\((?P<src>[^)]*)\)\s*⊆\s*Pre\((?P<dst>[^)]*)\)")

MAX_DECOMP_SUBS = config.MAX_DECOMP_SUBS


def _has_cycle(edges: list[tuple[str, str]]) -> bool:
    """True if the directed edge set (src enables dst) contains a cycle.
    Post(A)⊆Pre(B) means A is a prerequisite of B, i.e. an edge A→B; a
    decomposition's dependency graph must be a DAG (ADR-009)."""
    adj: dict[str, list[str]] = {}
    for src, dst in edges:
        adj.setdefault(src, []).append(dst)
    WHITE, GREY, BLACK = 0, 1, 2
    colour: dict[str, int] = {}

    def visit(node: str) -> bool:
        colour[node] = GREY
        for nxt in adj.get(node, []):
            c = colour.get(nxt, WHITE)
            if c == GREY or (c == WHITE and visit(nxt)):
                return True
        colour[node] = BLACK
        return False

    return any(colour.get(n, WHITE) == WHITE and visit(n) for n in list(adj))


@dataclass(frozen=True, order=True)
class Violation:
    path: str
    code: str
    message: str


class _Report:
    def __init__(self, root: Path) -> None:
        self._root = root
        self.violations: list[Violation] = []

    def add(self, code: str, path: Path, message: str) -> None:
        rel = path.relative_to(self._root).as_posix()
        self.violations.append(Violation(rel, code, message))


# --------------------------------------------------------------------- loading


def _aisp_files(directory: Path) -> list[Path]:
    if not directory.is_dir():
        return []
    return sorted(path for path in directory.glob("*.aisp") if path.is_file())


def _read_record(path: Path, report: _Report) -> Record | None:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        report.add("GB001", path, "file is not valid UTF-8")
        return None
    return parse_record(text)


def _load_goal_records(tree_root: Path) -> dict[str, Record]:
    goals: dict[str, Record] = {}
    for path in _aisp_files(tree_root / "goals"):
        try:
            goals[path.stem] = parse_record(path.read_text(encoding="utf-8"))
        except UnicodeDecodeError:
            continue  # the owning tree's own scan reports GB001
    return goals


def _safe_relative(value: str) -> bool:
    parts = Path(value).parts
    return bool(parts) and not Path(value).is_absolute() and ".." not in parts


# ------------------------------------------------------------- shared checks


def _check_header(record: Record, path: Path, record_type: str, report: _Report) -> None:
    rtype, gamma = _RECORD_TYPES[record_type]
    header = record.header
    if header is None or header.rtype != rtype:
        report.add(
            "GB001", path, f"header must be '𝔸<ver>.{rtype}.<name>@YYYY-MM-DD'"
        )
    if record.gamma != gamma:
        report.add("GB001", path, f"missing or wrong type line 'γ≔{gamma}'")


def _check_required_blocks(record: Record, path: Path, report: _Report) -> None:
    if record.block("Ω") is None:
        report.add("GB017", path, "required block ⟦Ω⟧ is missing")
    if not record.has_evidence:
        report.add("GB017", path, "required evidence block ⟦Ε⟧⟨…⟩ is missing")


def _check_prose_density(record: Record, path: Path, report: _Report) -> None:
    density = prose_density(record)
    if density > config.PROSE_DENSITY_CEILING:
        report.add(
            "GB009",
            path,
            f"quoted-prose density {density:.2f} exceeds "
            f"ceiling {config.PROSE_DENSITY_CEILING:.2f}",
        )


def _check_pair_identity(
    record: Record,
    path: Path,
    record_type: str,
    field_names: tuple[str, str],
    report: _Report,
) -> None:
    """GB002 family for two-field records: filename ↔ header ↔ Ω fields."""
    name_fields = claims_mod.split_claim_filename(path.name)
    if name_fields is None:
        report.add(
            "GB002",
            path,
            f"filename must be '<{field_names[0]}-id>.<agent-id>.aisp' "
            "(exactly two dots, kebab-case ids)",
        )
    first = record.fields.get(field_names[0])
    second = record.fields.get(field_names[1])
    if name_fields is not None and (first, second) != name_fields:
        report.add(
            "GB002",
            path,
            f"⟦Ω⟧ fields ({field_names[0]}≜{first}, {field_names[1]}≜{second}) "
            f"do not match filename fields {name_fields}",
        )
    rtype = _RECORD_TYPES[record_type][0]
    header = record.header
    if header is not None and header.rtype == rtype and header.name != f"{first}.{second}":
        report.add(
            "GB002",
            path,
            f"header name '{header.name}' does not match ⟦Ω⟧ fields '{first}.{second}'",
        )


# --------------------------------------------------------------- goal records


def _validate_goal(
    root: Path, path: Path, record: Record, known_goals: set[str], report: _Report
) -> None:
    fields = record.fields
    stem = path.stem

    _check_header(record, path, "goal", report)
    _check_required_blocks(record, path, report)

    # GB002 — filename / header / id agreement
    if not is_id(stem):
        report.add("GB002", path, f"filename id '{stem}' violates the Id grammar")
    header = record.header
    if header is not None and header.rtype == "goal" and header.name != stem:
        report.add(
            "GB002", path, f"header id '{header.name}' does not match filename '{stem}'"
        )
    if fields.get("id") != stem:
        report.add(
            "GB002",
            path,
            f"id field '{fields.get('id')}' does not match filename '{stem}'",
        )

    # GB003 — enum domains
    phase = fields.get("phase")
    status = fields.get("status")
    difficulty = fields.get("difficulty")
    if phase not in GOAL_PHASES:
        report.add("GB003", path, f"phase '{phase}' not in {GOAL_PHASES}")
    if status not in GOAL_STATUSES:
        report.add("GB003", path, f"status '{status}' not in {GOAL_STATUSES}")
    if difficulty is None or len(difficulty) != 1 or difficulty not in "012345":
        report.add("GB003", path, f"difficulty '{difficulty}' not an integer in 0–5")

    # GB004 — .aisp/.lean pairing
    lean = fields.get("lean")
    if phase == "prove":
        if lean in (None, EMPTY):
            report.add("GB004", path, "phase≡prove requires a lean path")
        elif not _safe_relative(lean) or not (root / lean).is_file():
            report.add("GB004", path, f"lean file '{lean}' does not exist")
    elif phase == "translate" and lean not in (None, EMPTY):
        report.add("GB004", path, f"phase≡translate requires lean≜∅, found '{lean}'")

    # GB005 — terminal statuses carry a sha
    sha = fields.get("sha")
    if status in SHA_REQUIRED_STATUSES and (sha is None or not is_sha256(sha)):
        report.add(
            "GB005", path, f"status≡{status} requires sha as 64 lowercase hex"
        )

    # GB006 — proved goals are indexed
    if status == "proved" and sha is not None and is_sha256(sha):
        if not (root / "library" / "index" / f"{sha}.aisp").is_file():
            report.add("GB006", path, f"library/index/{sha}.aisp does not exist")

    # GB007 — dep existence
    deps_raw = fields.get("deps")
    if deps_raw is not None:
        deps = parse_vector(deps_raw)
        if deps is None:
            report.add("GB007", path, f"deps '{deps_raw}' is not a ⟨…⟩ vector")
        else:
            for dep in deps:
                if dep not in known_goals:
                    report.add("GB007", path, f"dep '{dep}' is not an existing goal id")

    # GB008 — src existence
    src = fields.get("src")
    if src is None or not _safe_relative(src) or not (root / src).is_file():
        report.add("GB008", path, f"src '{src}' does not exist in the tree")

    # GB009 — prose density
    _check_prose_density(record, path, report)


# -------------------------------------------------------- translation records


def _validate_translation(
    path: Path,
    record: Record,
    goal_phases: dict[str, str | None] | None,
    report: _Report,
) -> None:
    _check_header(record, path, "translation", report)
    _check_required_blocks(record, path, report)
    _check_pair_identity(record, path, "translation", ("goal", "agent"), report)

    stmt = record.fields.get("stmt")
    if not stmt:
        report.add("GB009", path, "stmt is missing or empty")
    _check_prose_density(record, path, report)

    if goal_phases is not None:
        goal = record.fields.get("goal") or (
            claims_mod.split_claim_filename(path.name) or (None,)
        )[0]
        if goal not in goal_phases:
            report.add("GB016", path, f"references unknown goal '{goal}'")
        elif goal_phases[goal] != "translate":
            report.add(
                "GB016", path, f"goal '{goal}' is not a translate-phase goal"
            )


# ------------------------------------------------------ decomposition records


def _validate_decomposition(
    path: Path,
    record: Record,
    known_goals: set[str] | None,
    report: _Report,
) -> None:
    _check_header(record, path, "decomposition", report)
    _check_required_blocks(record, path, report)
    _check_pair_identity(record, path, "decomposition", ("parent", "agent"), report)
    _check_prose_density(record, path, report)

    parent = record.fields.get("parent")
    if known_goals is not None and parent not in known_goals:
        report.add("GB016", path, f"references unknown parent goal '{parent}'")

    subs_block = record.block("Σ")
    subs = list(_SUB_RE.finditer(subs_block.body)) if subs_block else []
    if not 1 <= len(subs) <= MAX_DECOMP_SUBS:
        report.add(
            "GB016",
            path,
            f"decomposition must declare 1–{MAX_DECOMP_SUBS} subs, found {len(subs)}",
        )
    labels = {"parent"}
    for sub in subs:
        labels.add(sub.group("label"))
        sub_id = sub.group("id")
        if not is_id(sub_id):
            report.add("GB016", path, f"sub id '{sub_id}' violates the Id grammar")
            continue
        # GB016 — a sub may not re-emit the parent (termination guard, ADR-009):
        # a decomposition must produce strictly smaller goals.
        if sub_id == parent:
            report.add("GB016", path, f"sub '{sub_id}' re-emits the parent goal")
        elif known_goals is not None and sub_id not in known_goals:
            report.add(
                "GB016", path, f"sub '{sub_id}' has no corresponding goal record"
            )

    edges_block = record.block("Γ")
    edge_pairs: list[tuple[str, str]] = []
    for edge in _EDGE_RE.finditer(edges_block.body if edges_block else ""):
        src, dst = edge.group("src").strip(), edge.group("dst").strip()
        edge_pairs.append((src, dst))
        for endpoint in (src, dst):
            if endpoint not in labels:
                report.add(
                    "GB016",
                    path,
                    f"edge endpoint '{endpoint}' is neither 'parent' "
                    "nor a declared sub",
                )
    # GB016 — the dependency edges must form a DAG (ADR-009).
    if _has_cycle(edge_pairs):
        report.add("GB016", path, "decomposition edges contain a dependency cycle")


# -------------------------------------------------------------- index records


def _validate_index(path: Path, record: Record, report: _Report) -> None:
    _check_header(record, path, "index", report)
    _check_required_blocks(record, path, report)

    stem = path.stem
    if not is_sha256(stem):
        report.add("GB006", path, "index filename must be a 64-hex sha stem")
        return
    sha = record.fields.get("sha")
    if sha != stem:
        report.add(
            "GB006", path, f"sha field '{sha}' does not match index filename stem"
        )
    stmt = (record.fields.get("stmt") or "").strip()
    if not stmt:
        report.add("GB006", path, "index entry has no stmt to hash")
        return
    digest = hashlib.sha256(stmt.encode("utf-8")).hexdigest()
    if digest != stem:
        report.add(
            "GB006",
            path,
            f"SHA-256(stmt) = {digest} does not match index filename stem",
        )


# -------------------------------------------------------------- claim records


def _validate_claims(
    root: Path,
    now: datetime,
    goal_phases: dict[str, str | None] | None,
    report: _Report,
) -> None:
    claims_dir = root / "claims"
    parsed: list[tuple[Path, claims_mod.Claim]] = []

    for path in sorted(claims_dir.iterdir()):
        if not path.is_file() or path.name == "README.md":
            continue
        if path.suffix != ".aisp":
            report.add(
                "GB010", path, "unexpected non-claim file in claims/ (not <Id>.<Id>.aisp)"
            )
            continue
        try:
            claim = claims_mod.parse_claim(path)
        except UnicodeDecodeError:
            report.add("GB001", path, "file is not valid UTF-8")
            continue
        parsed.append((path, claim))
        _validate_one_claim(path, claim, now, goal_phases, report)

    _check_claim_cardinality(parsed, now, goal_phases, report)


def _validate_one_claim(
    path: Path,
    claim: claims_mod.Claim,
    now: datetime,
    goal_phases: dict[str, str | None] | None,
    report: _Report,
) -> None:
    record = claim.record
    _check_required_blocks(record, path, report)

    # GB010 — filename grammar
    if claim.filename_goal is None:
        report.add(
            "GB010",
            path,
            "claim filename must be '<goal-id>.<agent-id>.aisp' (exactly two dots)",
        )

    # GB011 — header/body schema agreement and ts parse
    _check_header(record, path, "claim", report)
    header = record.header
    body_name = f"{claim.goal}.{claim.agent}"
    if header is not None and header.rtype == "claim" and header.name != body_name:
        report.add(
            "GB011",
            path,
            f"header name '{header.name}' does not match ⟦Ω⟧ fields '{body_name}'",
        )
    if claim.filename_goal is not None and (
        (claim.goal, claim.agent) != (claim.filename_goal, claim.filename_agent)
    ):
        report.add(
            "GB011",
            path,
            f"⟦Ω⟧ fields (goal≜{claim.goal}, agent≜{claim.agent}) do not match "
            f"filename fields ({claim.filename_goal}, {claim.filename_agent})",
        )
    if claim.ts is None:
        report.add("GB011", path, "ts is missing or not ISO-8601 UTC with Z suffix")

    # GB012 — ttl bounds
    if claim.ttl is None:
        report.add("GB012", path, "ttl is missing or not a non-negative integer")
    elif not config.TTL_MIN_SECONDS <= claim.ttl <= config.TTL_MAX_SECONDS:
        report.add(
            "GB012",
            path,
            f"ttl {claim.ttl} outside bounds "
            f"{config.TTL_MIN_SECONDS}≤ttl≤{config.TTL_MAX_SECONDS}",
        )

    # GB013 — freshness
    if claims_mod.is_expired(claim, now):
        expiry = claims_mod.expires_at(claim)
        report.add(
            "GB013",
            path,
            f"claim expired at {format_utc_z(now)} "
            f"(ts+ttl = {format_utc_z(expiry)})",
        )

    # GB016 — goal reference (only when a goals root is supplied)
    if goal_phases is not None:
        goal = claim.goal or claim.filename_goal
        if goal not in goal_phases:
            report.add("GB016", path, f"references unknown goal '{goal}'")


def _check_claim_cardinality(
    parsed: list[tuple[Path, claims_mod.Claim]],
    now: datetime,
    goal_phases: dict[str, str | None] | None,
    report: _Report,
) -> None:
    groups: dict[str, list[tuple[Path, claims_mod.Claim]]] = {}
    for path, claim in parsed:
        goal = claim.goal or claim.filename_goal
        if goal is not None and claims_mod.is_live(claim, now):
            groups.setdefault(goal, []).append((path, claim))

    for goal, live in sorted(groups.items()):
        # GB014 — per-goal cap. Phase-aware with a goals root; otherwise the
        # weaker bound ≤ 2 plus agent distinctness (SPEC-003-B).
        cap = config.TRANSLATE_CLAIM_CAP
        if goal_phases is not None and goal_phases.get(goal) == "prove":
            cap = config.PROVE_CLAIM_CAP
        if len(live) > cap:
            for path, _ in live:
                report.add(
                    "GB014",
                    path,
                    f"{len(live)} live claims for goal '{goal}' exceed cap {cap}",
                )
        # GB015 — agent distinctness among live claims
        agent_counts = Counter(
            claim.agent or claim.filename_agent or "" for _, claim in live
        )
        for path, claim in live:
            agent = claim.agent or claim.filename_agent or ""
            if agent and agent_counts[agent] > 1:
                report.add(
                    "GB015",
                    path,
                    f"agent '{agent}' holds {agent_counts[agent]} live claims "
                    f"on goal '{goal}'",
                )


# ------------------------------------------------------------------ top level


def validate_tree(
    root: Path | str,
    *,
    at: datetime | None = None,
    goals_root: Path | str | None = None,
) -> list[Violation]:
    """Validate one tree root; returns sorted violations (empty ⇒ clean).

    ``at`` injects the validation clock; it defaults to the current UTC time
    only when absent (the single place the wall clock is ever consulted).
    """
    root = Path(root)
    if not root.is_dir():
        raise NotADirectoryError(f"tree root '{root}' is not a directory")
    now = at if at is not None else datetime.now(timezone.utc)
    if now.tzinfo is None:
        now = now.replace(tzinfo=timezone.utc)
    report = _Report(root)

    own_goals = _load_goal_records(root)
    known: dict[str, Record] = dict(own_goals)
    if goals_root is not None:
        for goal_id, record in _load_goal_records(Path(goals_root)).items():
            known.setdefault(goal_id, record)
    goals_available = (root / "goals").is_dir() or goals_root is not None
    known_goals = set(known)
    goal_phases: dict[str, str | None] = {
        goal_id: record.fields.get("phase") for goal_id, record in known.items()
    }

    for path in _aisp_files(root / "goals"):
        record = _read_record(path, report)
        if record is not None:
            _validate_goal(root, path, record, known_goals, report)

    for path in _aisp_files(root / "translations"):
        record = _read_record(path, report)
        if record is not None:
            _validate_translation(
                path, record, goal_phases if goals_available else None, report
            )

    for path in _aisp_files(root / "decompositions"):
        record = _read_record(path, report)
        if record is not None:
            _validate_decomposition(
                path, record, known_goals if goals_available else None, report
            )

    for path in _aisp_files(root / "library" / "index"):
        record = _read_record(path, report)
        if record is not None:
            _validate_index(path, record, report)

    claims_dir = root / "claims"
    if claims_dir.is_dir():
        if (root / "goals").is_dir():
            # Main-shaped tree (ADR-004): claims live only on the claims
            # branch; anything but README.md under claims/ is a violation.
            for path in sorted(claims_dir.iterdir()):
                if path.is_file() and path.name != "README.md":
                    report.add(
                        "GB018",
                        path,
                        "claims live only on the claims branch; "
                        "main keeps claims/README.md alone",
                    )
        else:
            # Claims-branch-shaped tree: validate claims normally. Goal
            # references need --goals-root and are skipped without it.
            _validate_claims(
                root, now, goal_phases if goals_root is not None else None, report
            )

    return sorted(report.violations)


# ------------------------------------------------------------------ reporting


def render_human(violations: list[Violation]) -> str:
    return "".join(f"{v.code} {v.path}: {v.message}\n" for v in violations)


def render_json(violations: list[Violation], *, root: str, at: datetime) -> str:
    payload = {
        "at": format_utc_z(at),
        "ok": not violations,
        "root": root,
        "count": len(violations),
        "violations": [
            {"code": v.code, "path": v.path, "message": v.message} for v in violations
        ],
    }
    return json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
