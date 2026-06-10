# tools/fidelity — statement-fidelity normalizer + differ

Implements the normalization half of the statement-fidelity gate
([ADR-003](../../docs/adrs/ADR-003-AISP-Coordination-Format.md),
[SPEC-003-C §Normalization](../../docs/adrs/specs/SPEC-003-C-Translation-and-Decomposition-Records.md),
design doc §5). Two agents independently translate an English theorem
statement into AISP notation; this tool normalizes both and diffs them.
Byte-identical ⇒ match (the goal becomes `translated` and the sha is
recorded); different ⇒ the goal is flagged for human review.

Python 3.12, stdlib only (pytest is test-only). Run from the repository root.

## Pipeline

`normalize(stmt)` applies, in this exact order:

1. **NFC Unicode normalization.**
2. **Canonical symbol table** ([`symbols.py`](symbols.py)): alias glyphs are
   rewritten to one representative in a single left-to-right, longest-match
   pass (so `!=` wins over `!`, and the `∃!` binder is protected from the
   `!` → `¬` rewrite).
3. **Whitespace removal** — all whitespace is removed. The statement grammar
   is symbolic; spaces are never significant in our statement subset. (This
   is the conservative reading of SPEC-003-C's "collapse to none (symbols) or
   single space (where significant)": the subset has no significant spaces.)
4. **α-renaming** of bound variables to `x₁,x₂,…` in binding-occurrence
   order. Binders in the statement subset: `∀vars∈Set:`, `∀vars:`, `∃vars:`
   (with or without `∈Set`), `∃!var:` (with or without `∈Set`), `λvars.`,
   where `vars` is a comma-separated list of identifiers (a single Unicode
   letter optionally with subscript digits, or an ASCII letter sequence).
   Scope is respected: a binder's scope extends to the end of its innermost
   enclosing bracket group (binders have lowest precedence), an inner binder
   of the same name shadows the outer one, and the set expression of an
   `∈`-binder is rendered in the scope *outside* the binder. Free
   identifiers (`ℕ`, `0`, `+`, named constants/sets/functions) are untouched.
   A malformed binder head is left as-is rather than guessed at.
5. **Output:** a single UTF-8 line.

`sha` is the SHA-256 (lowercase hex) of the UTF-8 bytes of that line. The
same sha is the content address keying `library/index/<sha>.aisp`.

## Alias-table policy — conservative, typographic variants only

An alias is admitted only when it is an unambiguous typographical or ASCII
variant of exactly one glyph of the statement subset. When in doubt, a glyph
is left out: a false MISMATCH costs one human review; a false MATCH corrupts
the content-addressed library.

| Alias | Representative | Note |
|-------|----------------|------|
| `⟶` (U+27F6) | `→` | length-only variant of the function arrow |
| `⇾` (U+21FE) | `→` | head-style variant of the function arrow |
| `≝` (U+225D) | `≜` | "equal to by definition" = AISP defas |
| `:=` | `≔` | ASCII assignment digraph |
| `*` | `·` | multiplication; representative is the AISP Σ₅₁₂ glyph U+00B7 |
| `&&` | `∧` | C-family conjunction |
| `\|\|` | `∨` | C-family disjunction |
| `!` | `¬` | C-family negation (`∃!` and `!=` are matched first) |
| `<=` | `≤` | ASCII digraph |
| `>=` | `≥` | ASCII digraph |
| `!=` | `≠` | ASCII digraph for **inequality** |

Deliberately **not** aliased (different meanings, kept distinct):

- `≠` vs `≢` — inequality of values vs non-equivalence;
- `→` vs `⇒` — function arrow vs implication;
- `·` vs `×` — multiplication vs product/Cartesian product;
- `↔` vs `⇔` — kept distinct pending evidence they are used interchangeably.

## CLI

```sh
python3 -m tools.fidelity normalize <stmt-or-file>   # print normalized line
python3 -m tools.fidelity sha <stmt-or-file>         # print 64-hex sha
python3 -m tools.fidelity diff <a> <b> [--json]      # compare two statements
```

`<stmt-or-file>` is a raw statement, a file path (`.aisp` translation records
have their `stmt≜…` auto-extracted; other files are read as raw statements),
or `-` for stdin.

`diff` exits 0 and prints `MATCH sha=<sha>` when the normalized forms are
byte-identical; otherwise it exits 1 and prints a character-level pointer to
the first divergence plus both normalized lines and shas (paste-ready for
flagged-goal reviews). `--json` emits a machine-readable object instead.
Exit code 2 means a usage or input error.

```text
$ python3 -m tools.fidelity diff '∀n∈ℕ:0+n≡n' '∀n∈ℤ:n+0≡n'
MISMATCH at char 4: a has 'ℕ', b has 'ℤ'
a: ∀x₁∈ℕ:0+x₁≡x₁
b: ∀x₁∈ℤ:x₁+0≡x₁
   ····^
sha a=73026be9…
sha b=8de7d1bc…
```

## Tests

```sh
python3 -m pytest tools/fidelity -q
```

Planted pairs live in `tests/pairs/equivalent/` (must normalize
byte-identical) and `tests/pairs/distinct/` (must not). The false-positive
rate on such pairs is the metric the Phase-0 trial watches (>20% ⇒ fallback
per the swarm contract).

## Known limitations (by design or accepted)

- **No semantic equivalence reasoning.** Associativity, commutativity,
  definitional unfolding, `n+1` vs `succ(n)` — all out of scope by design.
  Two semantically equal but syntactically different statements will
  MISMATCH; that is exactly what the human-flag path is for.
- **Canonical-name capture.** A *free* identifier literally named `x₁`,
  `x₂`, … can collide with the canonical bound names. Backlog statements
  must not use `x<subscript>` as free names (the convention reserves them
  for bound variables).
- **Aliases are matched textually before whitespace removal** (pipeline
  order is normative), so a digraph split by a space (`: =`) or a spaced
  `∃ !` is not recognised. Statements are machine-written; this does not
  occur in practice.
- **ASCII-digit variable suffixes** (`x1`) are not identifiers in the
  grammar — use subscript digits (`x₁`).
- **Display-width caret.** The human `diff` caret aligns by character count;
  with double-width glyphs rely on the printed character index, which is
  authoritative.
