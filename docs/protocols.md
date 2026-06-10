# Protocols

These protocols must be followed when using plan mode. They are non-negotiable.

## 1. Architecture Decision Records (ADRs)

**Always create or update an ADR when a decision is made.**

- Every architectural, technical, or significant design decision must be captured as an ADR in `/docs/adrs/`
- ADRs follow the enhanced WH(Y) format as defined in [ADR-001](./adrs/ADR-001-Enhanced-ADR-Format.md)
- ADRs are immutable once approved — create a new ADR to supersede a previous one rather than modifying it
- Include rejected alternatives and the rationale for rejecting them
- Track dependencies between ADRs

## 2. Specifications

**Always create or update a spec that links/references an ADR or ADRs.**

- Every ADR that involves implementation details must have a corresponding specification in `/docs/adrs/specs/`
- Specs are the living documents — they evolve with the implementation
- ADRs remain stable decision records; specs capture the "how"
- Spec filenames follow the pattern: `SPEC-{ADR-number}-{letter}-{Title}.md`
- Each spec must reference the ADR(s) it implements

## 3. Test-Driven Development (TDD)

**Always follow TDD.**

- Write tests before writing implementation code
- Red → Green → Refactor cycle for every feature and bug fix
- Tests must cover the acceptance criteria defined in the relevant spec
- No code is merged without passing tests
- Test coverage must not decrease with any change

## 4. Feature Branches

**Always create a new feature branch for any changes.**

- Branch from `main` for every change, no matter how small
- Branch naming convention: `feature/{description}`, `fix/{description}`, `docs/{description}`
- No direct commits to `main`
- Each branch corresponds to a single logical change
- Clean up branches after merge

## 5. Changelog

**Maintain a changelog with versions.**

- Maintain `CHANGELOG.md` in the project root following [Keep a Changelog](https://keepachangelog.com/) format
- Every user-facing change must be recorded under the appropriate category (Added, Changed, Deprecated, Removed, Fixed, Security)
- Unreleased changes go under an `[Unreleased]` heading
- Version numbers follow [Semantic Versioning](https://semver.org/)

## 6. Releases

**Release versions as appropriate when changes are made.**

- Tag releases with semantic version numbers
- Move unreleased changelog entries to the new version heading
- Each release must pass all tests and quality checks
- Release notes reference the relevant ADRs and specs

## 7. Context7 MCP for Language Research

**Use the Context7 MCP to research appropriate language syntax and usage.**

- Before writing code in an unfamiliar library, framework, or API, use the Context7 MCP to fetch current documentation
- Append "use context7" to prompts when you need up-to-date syntax, API signatures, or usage patterns
- This ensures code follows the latest conventions and avoids deprecated patterns
- Applies to every library, framework, and API used in the project

## 8. Production-Ready Code Only

**No mocks, stubs, or placeholder implementations. Only fully working production-ready code.**

- Every line of code written must be real, functional, and production-ready
- No mock implementations, fake data layers, placeholder functions, or "TODO: implement later" stubs
- If a dependency is not yet built, wait for it — do not mock it
- Tests use proper test fixtures and factories, not mocks of the system under test
- External dependencies (e.g., database, filesystem) may use test doubles in tests only — never in application code
- If something cannot be fully implemented yet, do not write it at all — defer it to the appropriate phase

## 9. Claude Agent Teams

**Use Claude agent teams where suitable to get work done efficiently.**

- When tasks can be parallelised, use Claude sub-agents (Task tool) to work on independent items concurrently
- Use specialised agents (Explore, Plan, general-purpose) matched to the task type
- Research and exploration tasks should use Explore agents to avoid polluting the main context window
- Independent code changes across different files or modules can be delegated to parallel agents working in isolated worktrees
- Agent results should be verified before integration — trust but verify

## 10. Latest Stable Dependencies

**Always check for the latest available stable dependency and use that.**

- When adding any new dependency to the project (backend or frontend), check for the latest stable release before installing
- Do not assume pinned versions from documentation or examples are current — verify against the package registry (PyPI, npm)
- Use stable releases only — no alpha, beta, release candidate, or pre-release versions unless explicitly approved
- When updating existing dependencies, prefer the latest stable version compatible with the project's constraints
- Document the version chosen and the date it was verified in the relevant commit message

## 11. README Accuracy

**The README must be kept up to date and must accurately reflect the implementation.**

- Every feature described in the README must exist in the codebase — no aspirational claims
- When a feature is added, changed, or removed, update the README in the same branch
- Technical descriptions (algorithms, libraries, architecture) must match the actual implementation
- If a capability is planned but not yet implemented, it must not appear in the README
- README review is part of every release checklist

## 12. Don't Repeat Yourself (DRY)

**Eliminate duplication — every piece of knowledge must have a single, authoritative representation.**

- Before writing new code, check for existing implementations that solve the same problem — reuse rather than duplicate
- Extract shared logic into functions, utilities, or modules when the same pattern appears in more than one place
- Shared constants, types, and configuration values must be defined once and imported everywhere they are used
- When fixing a bug or changing behaviour, identify all locations where the same logic exists — fix them all or extract the common code
- Components with identical or near-identical structure should be refactored into a single parameterised component
- Backend and frontend must not independently re-implement the same validation rules — share the source of truth or derive one from the other
- Test helpers and fixtures used across multiple test files must live in shared modules, not be copy-pasted
- Duplication in ADRs and specs is acceptable — documentation may restate for clarity, but code must not

---

## Optional Protocols

The protocols below are conditional. Apply them only when the listed condition is met.

## 13. Frontend Security — `{@html}` Protocol *(Svelte projects only)*

**Applies when:** the project uses Svelte or SvelteKit. Skip this protocol entirely for non-Svelte projects.

**Never use Svelte's `{@html}` directive without DOMPurify sanitisation.**

- Svelte escapes HTML by default in `{expressions}` — this is the safe default
- `{@html}` renders raw HTML and bypasses Svelte's escaping — this is a stored XSS vector
- Any use of `{@html}` must pass content through DOMPurify (or equivalent sanitisation library) before rendering
- This applies to all user-generated content: entity names, descriptions, comments, model metadata, search results
- Code review must flag any `{@html}` usage without a corresponding sanitisation call
- Content Security Policy (CSP) headers must be configured to block inline script execution as a defence-in-depth measure
- This protocol addresses NZISM control 14.5.6.C.01 (web content security) and 14.5.8.C.01 (web application security)
