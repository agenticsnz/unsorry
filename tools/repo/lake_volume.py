"""Survey — and, with ``--apply``, reclaim — the persistent Namespace ``.lake``
cache volume Gate A relies on (ADR-046).

The ``.lake`` volume caches mathlib oleans + the library build across runs on a
FIXED-size Namespace volume (observed 50 GB, sitting at its cap). Nothing evicts
it, so it grows until full; ``lake exe cache get`` then ENOSPCs when it must
decompress mathlib into a volume with no room — the batch-run failure mode (a
``replay`` shard that lands cold on a full volume dies with ``No space left on
device``).

This is the missing hygiene. It is **REPORT-ONLY by default** (like
``swarm/cleanup.sh`` and ``stale-branch-janitor``): it surveys the volume and
frees nothing. The survey reports capacity in **bytes AND inodes** — ENOSPC is
whichever hits 100% first, and mathlib olean trees are millions of tiny files, so
inodes usually exhaust before bytes — plus the ``du`` composition, the live
toolchain pins, and the reclaimable candidates.

``--apply`` performs a CONSERVATIVE reclaim, and only when free space is below
``--min-free-gb`` (a watermark) unless ``--force``:

  * ``.lake/mathlib-cache/*.ltar`` — the COMPRESSED archives. Once ``cache get``
    has decompressed them the oleans are resident and the ``.ltar`` are dead
    weight (re-fetchable on demand), i.e. pure duplicate storage — the safest big
    reclaim.
  * loose git objects — ``git gc`` packs them (every fetch / queued branch leaves
    some behind, one inode each).

It NEVER removes the decompressed oleans of a live pin (that is the warm cache we
want), the ``nanoda``/``lean4export`` binaries, or anything outside ``.lake``.

SAFETY: the volume is SHARED with in-flight Gate A runs. Reporting is a safe
concurrent read; ``--apply`` MUTATES and must not race a running gate-a, so the
janitor workflow runs it report-only on a schedule and gates ``--apply`` behind a
manual, operator-validated dispatch. Advisory / non-gating: exit 0 always.

CLI::

  python3 -m tools.repo.lake_volume [--root .] [--lake .lake]
      [--apply] [--min-free-gb 8] [--force] [--json]
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import re
import subprocess
import sys
from pathlib import Path

GB = 1024**3
_PIN_RE = re.compile(r"leanprover/lean4:\S+")


# --------------------------------------------------------------------------
# Pure core (unit-tested) — no filesystem, no subprocess.
# --------------------------------------------------------------------------
def parse_pin(text):
    """The ``leanprover/lean4:vX`` pin in a lean-toolchain file's text, or None."""
    m = _PIN_RE.search(text or "")
    return m.group(0) if m else None


def stale_toolchains(present, pinned):
    """Toolchain ids present on disk but not in the live pin set (evictable)."""
    return sorted(set(present) - set(pinned))


def needs_reclaim(free_gb, min_free_gb, force):
    """Watermark: ``--apply`` should act only below the free-space floor, or forced."""
    return bool(force) or float(free_gb) < float(min_free_gb)


def pct_used(free, total):
    """Percent USED given free and total of the same unit (0 when total is 0)."""
    total = float(total)
    return 100.0 * (total - float(free)) / total if total else 0.0


def human(n):
    """Human-readable byte count (1.5G, 900M, 512B …)."""
    n = float(n)
    for unit in ("B", "K", "M", "G", "T"):
        if abs(n) < 1024 or unit == "T":
            return f"{int(n)}{unit}" if unit == "B" else f"{n:.1f}{unit}"
        n /= 1024


# --------------------------------------------------------------------------
# I/O shell.
# --------------------------------------------------------------------------
def live_pins(root):
    """Map each live pin to the toolchain files that declare it: the repo's own
    ``lean-toolchain`` plus every ``targets/<suite>/_verify/lean-toolchain``."""
    root = Path(root)
    files = [root / "lean-toolchain", *sorted(root.glob("targets/*/_verify/lean-toolchain"))]
    pins = {}
    for f in files:
        try:
            pin = parse_pin(f.read_text(encoding="utf-8"))
        except OSError:
            continue
        if pin:
            pins.setdefault(pin, []).append(str(f))
    return pins


def fs_stats(path):
    """(bytes_total, bytes_free, inodes_total, inodes_free) for the fs holding path."""
    st = os.statvfs(str(path))
    return (
        st.f_blocks * st.f_frsize,
        st.f_bavail * st.f_frsize,
        st.f_files,
        st.f_favail,
    )


def _du(flags, path):
    try:
        out = subprocess.run(
            ["du", *flags, str(path)], capture_output=True, text=True, timeout=300
        )
        parts = out.stdout.split()
        return int(parts[0]) if parts else 0
    except Exception:
        return 0


def ltar_archives(lake):
    """The compressed mathlib archives under ``<lake>/mathlib-cache/*.ltar``."""
    return sorted(Path(p) for p in glob.glob(str(Path(lake) / "mathlib-cache" / "*.ltar")))


def _rm(path):
    try:
        os.remove(path)
        return True
    except OSError:
        return False


def survey(root, lake):
    """Gather the report (pure data) for a given root + lake dir. All I/O here."""
    lake = Path(lake)
    rep = {"lake": str(lake), "exists": lake.is_dir(), "pins": live_pins(root)}
    if not lake.is_dir():
        return rep
    b_total, b_free, i_total, i_free = fs_stats(lake)
    rep["bytes"] = {"total": b_total, "free": b_free, "used_pct": round(pct_used(b_free, b_total), 1)}
    rep["inodes"] = {"total": i_total, "free": i_free, "used_pct": round(pct_used(i_free, i_total), 1)}
    rep["du"] = {}
    for name, sub in (("lake", lake), ("packages", lake / "packages"), ("build", lake / "build"),
                      ("mathlib-cache", lake / "mathlib-cache")):
        if Path(sub).exists():
            rep["du"][name] = {"bytes": _du(["-sb"], sub), "inodes": _du(["-s", "--inodes"], sub)}
    ltars = ltar_archives(lake)
    rep["reclaimable"] = {
        "ltar_count": len(ltars),
        "ltar_bytes": sum((p.stat().st_size for p in ltars if p.exists()), 0),
    }
    return rep


def print_report(rep):
    lake = rep["lake"]
    if not rep.get("exists"):
        print(f"lake-volume: {lake} does not exist (no Namespace volume mounted?) — nothing to survey")
        return
    b, i = rep["bytes"], rep["inodes"]
    print(f"lake-volume: {lake}")
    print(f"  bytes : {human(b['total'] - b['free'])} / {human(b['total'])} used  ({b['used_pct']}%)  free={human(b['free'])}")
    print(f"  inodes: {i['total'] - i['free']} / {i['total']} used  ({i['used_pct']}%)  free={i['free']}")
    if b["used_pct"] >= 90 or i["used_pct"] >= 90:
        which = "inodes" if i["used_pct"] >= b["used_pct"] else "bytes"
        print(f"  ::warning:: volume >=90% full on {which} — Gate A can ENOSPC on cold mathlib decompression")
    for name, d in rep.get("du", {}).items():
        print(f"  du {name:14s} {human(d['bytes']):>8s}  {d['inodes']:>10d} inodes")
    print(f"  live pins ({len(rep['pins'])}): {', '.join(sorted(rep['pins'])) or '(none)'}")
    rc = rep.get("reclaimable", {})
    print(f"  reclaimable now: {rc.get('ltar_count', 0)} *.ltar = {human(rc.get('ltar_bytes', 0))} "
          f"(compressed dupes, re-fetchable) + loose git objects via gc")


def apply_reclaim(root, lake, rep):
    """Conservative reclaim: delete decompressed-then-redundant .ltar archives and
    gc loose git objects. Returns a dict of what was freed. I/O."""
    lake = Path(lake)
    freed_bytes = 0
    removed = 0
    for p in ltar_archives(lake):
        try:
            sz = p.stat().st_size
        except OSError:
            sz = 0
        if _rm(p):
            removed += 1
            freed_bytes += sz
    gc_ok = False
    try:
        subprocess.run(["git", "-C", str(root), "gc", "--prune=now", "--quiet"],
                       capture_output=True, timeout=600)
        gc_ok = True
    except Exception:
        gc_ok = False
    print(f"lake-volume: reclaimed {removed} *.ltar ({human(freed_bytes)}); git gc {'ok' if gc_ok else 'skipped'}")
    return {"ltar_removed": removed, "ltar_bytes_freed": freed_bytes, "git_gc": gc_ok}


def main(argv=None):
    ap = argparse.ArgumentParser(description="Survey/reclaim the persistent Namespace .lake cache volume.")
    ap.add_argument("--root", default=".", help="repo root (for lean-toolchain pins + git gc)")
    ap.add_argument("--lake", default=None, help="the .lake dir to survey (default: <root>/.lake)")
    ap.add_argument("--apply", action="store_true", help="perform the reclaim (default: report only)")
    ap.add_argument("--min-free-gb", type=float, default=8.0, help="apply only when free bytes < this (watermark)")
    ap.add_argument("--force", action="store_true", help="apply regardless of the watermark")
    ap.add_argument("--json", action="store_true", help="emit the survey as JSON")
    args = ap.parse_args(argv)

    root = Path(args.root)
    lake = Path(args.lake) if args.lake else root / ".lake"
    rep = survey(root, lake)

    if args.json:
        print(json.dumps(rep, indent=2, sort_keys=True))
    else:
        print_report(rep)

    if args.apply and rep.get("exists"):
        free_gb = rep["bytes"]["free"] / GB
        if needs_reclaim(free_gb, args.min_free_gb, args.force):
            apply_reclaim(root, lake, rep)
        else:
            print(f"lake-volume: {free_gb:.1f}G free >= --min-free-gb {args.min_free_gb}G — nothing reclaimed "
                  f"(use --force to override)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
