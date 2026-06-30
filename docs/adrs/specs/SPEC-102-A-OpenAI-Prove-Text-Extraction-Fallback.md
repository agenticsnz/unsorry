# SPEC-102-A: OpenAI `--prove` Text-Extraction Fallback

Implements: [ADR-102](../ADR-102-OpenAI-Prove-Text-Extraction-Fallback.md) · Relates to: [ADR-025](../ADR-025-OpenAI-Compatible-Endpoints-and-Pi-Config.md), [ADR-006](../ADR-006-Gate-A-Soundness-Enforcement.md), [ADR-016](../ADR-016-Infrastructure-Failure-Guard.md) · Status: Living · Updated: 2026-06-14

Lets a model that answers `--prove` in **text** (Lean as a fenced block or bare
source) instead of an OpenAI `Write` tool call still produce the target module.
Entirely inside `tools/llm_providers/openai_cli.py`; `swarm/agent.sh` orchestration
is unchanged (it already verifies the written file via `prove_local_verify`).

## 1. Extraction (`extract_lean_module(content) -> str`)

Derive the module from the model's final text, in preference order:

1. the first ```` ```lean ```` fenced block (case-insensitive language tag);
2. else the first fenced block of **any** (or no) language;
3. else the whole content.

The chosen text is `.strip()`ped and returned with a single trailing newline;
empty/whitespace-only content returns `""` (nothing is written). Soundness does
not rest on this parse — Gate A re-checks whatever is written (ADR-006).

## 2. Target resolution (`target_from_prompt(prompt) -> str | None`)

The fallback must know where to write. Resolution precedence:

- explicit `--target` (workdir-relative), else
- the path parsed from the prove prompt's stable contract line
  `^Target module file \(relative to repo root\):\s*(\S+)` (emitted by
  `swarm/prompts/prove.md` / `swarm/agent.sh`), else
- `None` → no fallback (non-prove use is unaffected).

Parsing the prompt is what keeps `agent.sh` untouched; the coupling is a single
regex localised here and documented as the prove contract.

## 3. Loop changes (`process_conversation(provider, prompt, model, workdir, target=None, max_turns=10)`)

- On a request/HTTP failure (`requests` raising, incl. `raise_for_status()` on
  4xx/5xx) **raise `OpenAIError`** instead of returning an error string. `main()`
  maps `OpenAIError` to `sys.exit(1)` — so ADR-016's classifier sees a real
  failure, not exit 0 (no partial file is written: extraction runs only after a
  clean loop).
- A turn with **no** `tool_calls` breaks the loop (instead of returning content),
  retaining the last non-empty assistant `content` as `last_content`.
- After the loop (no-tool break **or** `max_turns` exhausted): if `target` is set
  and `os.path.join(workdir, target)` does **not** exist, write
  `extract_lean_module(last_content)` there (creating parent dirs) when non-empty.
- **Tool path wins, no double-write:** `agent.sh`'s `prepare_proof_attempt()` `rm`s
  the target before every attempt, so the target existing after the loop means a
  `Write`/`Edit` tool call created it → extraction is skipped.

## 4. CLI / prompt

- `openai_cli.py` gains `--target`; the `--prove` branch resolves
  `args.target or target_from_prompt(args.prompt)` and passes it through.
- `swarm/prompts/prove.md` rule 1 (DRY, single file) instructs models without
  tool calls to return exactly one fenced ```` ```lean ```` block; tool-capable
  models are told to keep using `Write`/`Edit`.

## Acceptance criteria

1. No `tool_calls` + a ```` ```lean ```` block → target written with the block's contents.
2. No fence → the trimmed content written verbatim to the target.
3. Model used the `Write` tool → unchanged behaviour: the tool content stands, extraction does not override (no double-write).
4. 4xx/5xx HTTP error or transport failure → `openai_cli.py` exits non-zero and no partial/garbage file is written.
5. End-to-end: a non-tool-calling model emitting a valid module passes `lake build UnsorryLibrary --wfail` + `axiom_audit` via the existing `prove_local_verify`; an invalid one fails verification (no soundness regression).
6. Tests live under `tools/llm_providers/tests/test_openai_cli.py` and run green in `python3 -m pytest tools -q`.
