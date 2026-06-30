#!/usr/bin/env bash
# swarm/lib/ensure_cc.sh — make a C linker (`cc`) available, best-effort
# installing a minimal C toolchain via the system package manager if it is
# missing. Sibling of ensure_lake.sh (ADR-100) and setup.sh's `ensure_cargo`.
#
# Why this exists: the independent-check bootstrap (ADR-096,
# tools/independent_check/setup.sh) self-installs elan (`lake`) and rustup
# (`cargo`), but then builds lean4export (Lean's `leanc`) and nanoda
# (`cargo build`) — and BOTH shell out to `cc` to link. A box with elan + cargo
# but no C compiler therefore fails deep inside the build with a cryptic
# `linker `cc` not found`, and the independent check is silently skipped. This
# closes that gap so the bootstrap is genuinely self-contained.
#
# Source this file and call `ensure_cc` before any build that links via `cc`.
#
# Behaviour (idempotent, safe to call repeatedly):
#   1. If `cc` resolves on PATH, return 0 — nothing to do.
#   2. Otherwise best-effort install a minimal C toolchain NON-INTERACTIVELY, but
#      only where it can be done cleanly: Linux with a known package manager and
#      either root or PASSWORDLESS sudo (`sudo -n`). It never prompts for a
#      password and never hangs — if sudo would prompt, it gives up rather than
#      stall an unattended swarm run.
#   3. macOS / unknown package manager / no privileges ⇒ no install is attempted;
#      it prints the exact OS-specific command to run and returns 1.
#   4. Re-probe; return 0 iff `cc` is now resolvable.
#
# All progress output goes to stderr so a caller that captures stdout
# (e.g. `eval "$(setup.sh)"`) is unaffected. The side-effecting install step is
# isolated in `_ensure_cc_install` so the self-tests stub it hermetically.

# Is a C linker driver (`cc`) on PATH? rustc and leanc invoke `cc` by name to
# link, so `cc` specifically — not merely `gcc`/`clang` — is what must resolve.
_ensure_cc_present() {
  command -v cc >/dev/null 2>&1
}

# Print the precise manual install command for the current OS (stderr). Used when
# auto-install is impossible (macOS, no package manager, no privileges) or failed.
_ensure_cc_hint() {
  case "$(uname -s 2>/dev/null)" in
    Darwin)
      echo "[ensure_cc] install the C toolchain manually: xcode-select --install" >&2
      ;;
    Linux)
      echo "[ensure_cc] install a C toolchain manually, e.g. one of:" >&2
      echo "[ensure_cc]   sudo apt-get install build-essential   # Debian/Ubuntu" >&2
      echo "[ensure_cc]   sudo dnf install gcc                    # Fedora/RHEL" >&2
      echo "[ensure_cc]   sudo pacman -S gcc                      # Arch" >&2
      echo "[ensure_cc]   sudo apk add build-base                 # Alpine" >&2
      ;;
    *)
      echo "[ensure_cc] install a C compiler/linker (cc) manually for your OS" >&2
      ;;
  esac
}

# The one side-effecting step: install a minimal C toolchain via the system
# package manager. Isolated so the self-tests can stub it hermetically. Returns 0
# only if it ran an installer to completion; returns 1 (no-op) on macOS, an
# unknown package manager, or missing privileges — leaving the caller to hint.
_ensure_cc_install() {
  # Linux-only auto-install: the macOS Command Line Tools install
  # (`xcode-select --install`) is an interactive GUI prompt, so we never attempt
  # it — the chosen policy is best-effort on Linux, instruct everywhere else.
  [ "$(uname -s 2>/dev/null)" = "Linux" ] || return 1

  # Privilege prefix: nothing as root, else PASSWORDLESS sudo only (`sudo -n`).
  # If sudo would prompt for a password we bail rather than hang an unattended
  # run — the caller then prints the manual command to run once by hand.
  local -a sudo=()
  if [ "$(id -u)" != "0" ]; then
    if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
      sudo=(sudo -n)
    else
      return 1
    fi
  fi

  if command -v apt-get >/dev/null 2>&1; then
    "${sudo[@]}" env DEBIAN_FRONTEND=noninteractive apt-get update >&2 \
      && "${sudo[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential >&2
  elif command -v dnf >/dev/null 2>&1; then
    "${sudo[@]}" dnf install -y gcc >&2
  elif command -v yum >/dev/null 2>&1; then
    "${sudo[@]}" yum install -y gcc >&2
  elif command -v pacman >/dev/null 2>&1; then
    "${sudo[@]}" pacman -Sy --noconfirm gcc >&2
  elif command -v zypper >/dev/null 2>&1; then
    "${sudo[@]}" zypper --non-interactive install gcc >&2
  elif command -v apk >/dev/null 2>&1; then
    "${sudo[@]}" apk add --no-cache build-base >&2
  else
    return 1
  fi
}

# Ensure `cc` is on PATH, best-effort installing a C toolchain if necessary.
# Returns 0 on success, 1 if `cc` could not be made available (the caller decides
# whether that is fatal — for the independent-check bootstrap it is).
ensure_cc() {
  _ensure_cc_present && return 0

  echo "[ensure_cc] no C linker (cc) found — lean4export/nanoda need one to build; attempting install…" >&2
  if _ensure_cc_install && _ensure_cc_present; then
    echo "[ensure_cc] C toolchain installed — cc is now available" >&2
    return 0
  fi

  echo "[ensure_cc] could not install a C toolchain automatically" >&2
  _ensure_cc_hint
  return 1
}
