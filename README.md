# TDSS v2.1 Market Observation Indicator

## Project Overview

This repository is the documentation hub and implementation workspace for TDSS v2.1, a MetaTrader 5 market observation and contextualization indicator.

TDSS v2.1 is a decision-support system. It observes, classifies, scores activity significance, visualizes, and explains market context. It does not generate signals, predictions, trade recommendations, entries, exits, targets, stop-loss guidance, probability of success, or expected outcome. The trader remains the sole decision maker.

## Current Phase

Current status: **SOT v2.1 refresh and documentation standardization completed; Phase 2 is not ready**.

The current work establishes:

- revised SOT v2.1 business truth
- clarified retest philosophy
- clarified Support / Resistance interpretation
- clarified activity-significance scoring philosophy
- simplicity principle
- project-wide documentation standard
- Phase 2 readiness review

No new features were implemented and no scoring logic was modified as part of the v2.1 documentation refresh.

## Documentation Standard

Each project document has a distinct role:

| Document | Role |
|---|---|
| `SOT.md` | Business truth only. No implementation details. |
| `ARCHITECTURE.md` | System architecture, modules, responsibilities, dependencies, and code documentation conventions. |
| `DOMAIN_MODEL.md` | Business entities, relationships, and business rules. |
| `IMPLEMENTATION_STATUS.md` | Current implementation state, completed features, pending features, known limitations, and readiness. |
| `CHANGELOG.md` | Historical evolution, version history, and major decisions. |
| `MIGRATION.md` | Legacy mapping and Keep / Refactor / Remove decisions. |
| `AGENT.md` | Instructions for AI coding agents working in the repository. |

## Source of Truth

`SOT.md` is the business source of truth. If implementation details or other documents conflict with the SOT, the SOT prevails.

## Folder Structure

```text
.
├── README.md                   # Project overview and workflow
├── SOT.md                      # TDSS v2.1 business source of truth
├── ARCHITECTURE.md             # Architecture, responsibilities, dependencies, documentation conventions
├── DOMAIN_MODEL.md             # Business entities, relationships, and rules
├── IMPLEMENTATION_STATUS.md    # Implementation status, limitations, and readiness
├── CHANGELOG.md                # Version history and major decisions
├── MIGRATION.md                # Legacy mapping and migration decisions
├── SOT_MVP_Indicator.mq5       # TDSS v2 MT5 indicator implementation; legacy filename retained for compatibility
└── AGENT.md                    # AI coding agent instructions
```

## Development Workflow

1. Validate business rules in `SOT.md` before implementation.
2. Check `IMPLEMENTATION_STATUS.md` for current limitations and readiness.
3. Keep changes limited to the approved phase.
4. Preserve existing behavior only when it aligns with TDSS v2.1 neutrality.
5. Keep documentation aligned with approved implementation changes.
6. Verify that no output becomes a trade signal, prediction, expected outcome, probability statement, or recommendation.

## Phase 2 Readiness

Phase 2 is currently **not ready**.

Before Phase 2 coding begins, the project must resolve retest-scoring alignment, audit displayed terminology, add code documentation headers where needed, and document the approved Phase 2 scope.
