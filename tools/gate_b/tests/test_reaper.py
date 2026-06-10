"""Reaper tests (SPEC-004-A). Written before the implementation — TDD."""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

from tools.gate_b.claims import is_expired, parse_claim

FIXTURES = Path(__file__).parent / "fixtures"
CLAIMS_VALID = FIXTURES / "claims_valid"

# claims_valid contents: nat-add-comm.agent-alpha ts=2026-06-10T00:00:00Z ttl=7200
#                        nat-add-comm.agent-beta  ts=2026-06-10T00:05:00Z ttl=7200
ALL_LIVE = "2026-06-10T01:00:00Z"
ALPHA_ONLY_EXPIRED = "2026-06-10T02:02:00Z"  # alpha expires 02:00:00, beta 02:05:00
ALL_EXPIRED = "2026-06-10T03:00:01Z"


def run_reaper(root: Path, at: str, *extra: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, "-m", "tools.gate_b.reaper", str(root), "--at", at, *extra],
        capture_output=True,
        text=True,
        cwd=Path(__file__).resolve().parents[3],
    )


@pytest.fixture()
def claims_copy(tmp_path: Path) -> Path:
    shutil.copytree(CLAIMS_VALID, tmp_path / "tree")
    return tmp_path / "tree"


def claim_files(root: Path) -> set[str]:
    return {p.name for p in (root / "claims").glob("*.aisp")}


class TestDryRun:
    def test_nothing_expired_nothing_listed(self, claims_copy: Path) -> None:
        proc = run_reaper(claims_copy, ALL_LIVE, "--dry-run", "--json")
        assert proc.returncode == 0
        report = json.loads(proc.stdout)
        assert report["reaped"] == []
        assert report["kept"] == 2
        assert claim_files(claims_copy) == {
            "nat-add-comm.agent-alpha.aisp",
            "nat-add-comm.agent-beta.aisp",
        }

    def test_dry_run_removes_nothing_even_when_expired(self, claims_copy: Path) -> None:
        proc = run_reaper(claims_copy, ALL_EXPIRED, "--dry-run", "--json")
        assert proc.returncode == 0
        report = json.loads(proc.stdout)
        assert len(report["reaped"]) == 2
        assert claim_files(claims_copy) == {
            "nat-add-comm.agent-alpha.aisp",
            "nat-add-comm.agent-beta.aisp",
        }

    def test_json_deterministic(self, claims_copy: Path) -> None:
        a = run_reaper(claims_copy, ALL_EXPIRED, "--dry-run", "--json").stdout
        b = run_reaper(claims_copy, ALL_EXPIRED, "--dry-run", "--json").stdout
        assert a == b

    def test_report_lists_relative_paths_and_ages(self, claims_copy: Path) -> None:
        proc = run_reaper(claims_copy, ALL_EXPIRED, "--dry-run", "--json")
        report = json.loads(proc.stdout)
        entries = {entry["path"]: entry for entry in report["reaped"]}
        assert "claims/nat-add-comm.agent-alpha.aisp" in entries
        alpha = entries["claims/nat-add-comm.agent-alpha.aisp"]
        # at 03:00:01 the alpha claim (ts 00:00:00, ttl 7200) is 3601 s past expiry
        assert alpha["expired_for_seconds"] == 3601
        assert alpha["goal"] == "nat-add-comm"
        assert alpha["agent"] == "agent-alpha"


class TestRealRemoval:
    def test_exactly_the_expired_claims_are_removed(self, claims_copy: Path) -> None:
        proc = run_reaper(claims_copy, ALPHA_ONLY_EXPIRED, "--json")
        assert proc.returncode == 0
        report = json.loads(proc.stdout)
        assert [entry["path"] for entry in report["reaped"]] == [
            "claims/nat-add-comm.agent-alpha.aisp"
        ]
        assert claim_files(claims_copy) == {"nat-add-comm.agent-beta.aisp"}

    def test_nothing_live_is_ever_removed(self, claims_copy: Path) -> None:
        proc = run_reaper(claims_copy, ALL_LIVE, "--json")
        assert proc.returncode == 0
        assert claim_files(claims_copy) == {
            "nat-add-comm.agent-alpha.aisp",
            "nat-add-comm.agent-beta.aisp",
        }

    def test_readme_is_never_touched(self, claims_copy: Path) -> None:
        readme = claims_copy / "claims" / "README.md"
        readme.write_text("# claims\n", encoding="utf-8")
        run_reaper(claims_copy, ALL_EXPIRED, "--json")
        assert readme.exists()


class TestVerdictAgreement:
    def test_reaper_and_claims_module_agree(self, claims_copy: Path) -> None:
        """SPEC-004-A acceptance 3: one implementation of expiry (DRY)."""
        from tools.gate_b.records import parse_utc_z

        now = parse_utc_z(ALPHA_ONLY_EXPIRED)
        assert now is not None
        expected = {
            path.name
            for path in (claims_copy / "claims").glob("*.aisp")
            if is_expired(parse_claim(path), now)
        }
        proc = run_reaper(claims_copy, ALPHA_ONLY_EXPIRED, "--dry-run", "--json")
        report = json.loads(proc.stdout)
        reaped = {Path(entry["path"]).name for entry in report["reaped"]}
        assert reaped == expected


class TestUnparsable:
    def test_unparsable_claim_reported_never_deleted(self, claims_copy: Path) -> None:
        bad = claims_copy / "claims" / "broken-goal.agent-x.aisp"
        bad.write_text("not an aisp record\n", encoding="utf-8")
        proc = run_reaper(claims_copy, ALL_EXPIRED, "--json")
        assert proc.returncode == 1
        report = json.loads(proc.stdout)
        assert report["unparsable"] == ["claims/broken-goal.agent-x.aisp"]
        assert bad.exists()


class TestErrors:
    def test_missing_claims_dir_is_internal_error(self, tmp_path: Path) -> None:
        proc = run_reaper(tmp_path, ALL_LIVE, "--json")
        assert proc.returncode == 2
