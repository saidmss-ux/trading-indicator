# TDSS v2 Market Observation Indicator

## Project overview

This repository is the DocuHub and implementation workspace for TDSS v2, a MetaTrader 5 market observation and contextualization indicator.

TDSS v2 is a Decision Support System. It observes, classifies, scores, visualizes, and explains market context. It does not generate signals, predictions, trade recommendations, entries, exits, targets, or stop-loss guidance. The trader remains the sole decision maker.

## Current Phase

Phase 1 establishes the TDSS v2 foundation:

- official TDSS v2 identity
- SOT-aligned documentation
- architectural separation between analysis, scoring, rendering, and context layers
- stabilized HH / HL / LH / LL structure observation
- reusable support and resistance zone foundation for future TDSS activity-zone models

## Source of Truth

`SOT.md` is the business source of truth. If implementation details conflict with the SOT, the SOT prevails.

## Folder structure

```text
.
├── README.md               # Project overview and workflow
├── SOT.md                  # TDSS v2 business source of truth
├── ARCHITECTURE.md         # Layer responsibilities and dependencies
├── MIGRATION.md            # Phase 1 migration decisions and future phases
├── SOT_MVP_Indicator.mq5   # TDSS v2 MT5 indicator implementation; legacy filename retained for compatibility
└── AGENT.md                # AI coding agent instructions
```

## Development workflow

1. Validate business rules in `SOT.md` before implementation.
2. Keep changes limited to the active phase.
3. Preserve existing behavior when it aligns with TDSS v2 neutrality.
4. Keep documentation aligned with approved implementation changes.
5. Verify that no output becomes a trade signal, prediction, or recommendation.
