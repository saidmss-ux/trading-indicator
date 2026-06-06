# AI Agent Instructions

## Primary Rule

Use `SOT.md` as the only source of business logic. If implementation details or other documents conflict with `SOT.md`, the SOT prevails.

## Neutrality Rules

- Never invent trading rules.
- Never add prediction logic.
- Never add recommendation logic.
- Never describe outputs as entries, exits, targets, stop losses, trade setups, trade opportunities, probability of success, or expected outcome.
- Treat Support and Resistance as observational constructs only.
- Treat retests as interaction evidence only; do not assume that more retests automatically mean stronger or weaker zones.
- Preserve trader decision ownership in all wording.

## Implementation Rules

- Do not generate MQL5 code unless explicitly requested.
- Do not implement Phase 2 features unless explicitly approved.
- Do not modify scoring logic unless explicitly requested and SOT-aligned requirements are provided.
- Do not add speculative features.
- Keep changes atomic and limited to the current task.
- Prioritize simplicity, readability, and maintainability.

## Documentation Rules

- Keep `SOT.md` business-only and free of implementation details.
- Use `ARCHITECTURE.md` for modules, responsibilities, dependencies, and code documentation conventions.
- Use `DOMAIN_MODEL.md` for business entities, relationships, and business rules.
- Use `IMPLEMENTATION_STATUS.md` for completed features, pending features, known limitations, and readiness.
- Use `CHANGELOG.md` for historical evolution, version history, and major decisions.
- Use `MIGRATION.md` for legacy Keep / Refactor / Remove decisions.
- Keep documentation lightweight and aligned after every approved modification.

## Code Documentation Convention

When documenting implementation modules, use the standard from `ARCHITECTURE.md`:

```text
// MODULE: <module name>
// Purpose: <what this module does>
// Dependencies: <external/internal inputs it relies on>
// Inputs: <runtime data or parameters consumed>
// Outputs: <observations, scores, objects, or state produced>
// Business Notes: <neutral interpretation constraints>
// SOT References: <relevant SOT.md sections>
```

## Clarification Rule

Ask for clarification when required rules are missing from `SOT.md`, unless the current task explicitly asks only for a readiness review or documentation of the gap.
