# ADR-102: OpenAI `--prove` Text-Extraction Fallback

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-102 |
| **Initiative** | unsorry swarm provider portability |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-14 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** the OpenAI provider's `--prove` path, which reimplements its own tool-call loop in `process_conversation()` (`tools/llm_providers/openai_cli.py`) and only ever writes the target `library/Unsorry/<Camel>.lean` module when the model returns a structured `Write`/`Edit` **function call** — the limitation ADR-025 already booked in its *accepting that* clause ("local models that lack OpenAI function-calling cannot drive the `--prove` tool loop"),

**facing** the fact that the proof-specialised models we most want to point `-pi` at (Leanstral and similar, behind an OpenAI-compatible llama.cpp/vLLM endpoint) emit the Lean module as **plain text** — a fenced ```` ```lean ```` block or bare source — and narrate *about* the tool instead of emitting a `tool_calls` array; the loop then `return`s the content, the CLI exits `0`, the `.lean` file is never created, and `agent.sh` logs `prover did not write <target>` on every attempt — and, separately, that a real 4xx/5xx or transport failure is swallowed into a returned string with exit `0`, so ADR-016's classifier cannot tell genuine infrastructure failure apart from "model produced no usable file",

**we decided for** a **text-extraction fallback** on the prove path: when the tool loop ends without the target file having been written, derive the module from the model's final text content — first a ```` ```lean ```` fenced block, else any fenced block, else the whole trimmed content — and write it to the target the prover was told to use (recovered from `--target` or, absent that, parsed from the prompt's `Target module file (relative to repo root): …` contract line, so **`agent.sh` orchestration is unchanged**); and we make `process_conversation()` **raise** on transport/HTTP failure so the CLI exits non-zero, with the prove prompt (`swarm/prompts/prove.md`) extended in place (DRY, one file) to tell non-tool-calling models to return exactly one fenced ```` ```lean ```` block,

**and neglected** detecting the target write by inspecting tool-call arguments (the worktree's `prepare_proof_attempt()` already `rm`s the target before each attempt, so the file's mere presence after the loop is the simpler, robust "tool path won" signal — no double-write); threading a new `--target` through `agent.sh`'s `call_provider_prove` chain (the prompt already carries the path, so prompt-parse keeps the orchestration untouched); a second non-tool prompt **variant** file (duplicates the prove contract — it would drift); and loosening any soundness gate to admit text-emitted proofs,

**to achieve** `--prove` that works on proof-specialised models which speak Lean-as-text rather than as function calls — the exact models `-pi` exists to serve — against the **same** Gate A kernel-verification bar, and an honest exit code that lets ADR-016 see real infra failures,

**accepting that** extraction is a best-effort parse (a model that emits no usable text still writes nothing and fails the existing missing-target check); the target is recovered by matching a stable prompt line when `--target` is absent (a coupling documented in SPEC-102-A and localised to one regex); and that trust still rests solely on Gate A re-checking every proof — a bad extraction fails `lake build UnsorryLibrary --wfail` + `axiom_audit` identically to a bad tool-written proof, so admitting text-emitted proofs introduces **no** soundness regression (ADR-006).

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | OpenAI prove text-extraction fallback | Specification | specs/SPEC-102-A-OpenAI-Prove-Text-Extraction-Fallback.md |
| REF-2 | OpenAI-compatible endpoints and pi-config (the constraint this lifts) | ADR | ADR-025-OpenAI-Compatible-Endpoints-and-Pi-Config.md |
| REF-3 | Gate A soundness enforcement (why text-extracted proofs stay sound) | ADR | ADR-006-Gate-A-Soundness-Enforcement.md |
| REF-4 | Infrastructure-failure guard (the classifier the non-zero exit feeds) | ADR | ADR-016-Infrastructure-Failure-Guard.md |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-14 |
| Accepted | unsorry maintainers | 2026-06-14 |
