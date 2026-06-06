# TDSS v2.1 Migration

## Purpose

This document maps legacy system elements to TDSS v2.1 decisions.

It records what to keep, refactor, remove, or defer so future development remains aligned with `SOT.md`.

## Migration Objective

TDSS v2.1 continues the controlled migration from the existing TDSS indicator toward a neutral market observation and contextualization system.

This is not a greenfield rewrite. Existing behavior may be retained only when it aligns with TDSS v2.1 neutrality, retest philosophy, scoring philosophy, and simplicity principle.

## Legacy Component Review

| Component | Decision | Rationale |
|---|---|---|
| MT5 lifecycle (`OnInit`, `OnDeinit`, `OnCalculate`) | KEEP | Required indicator shell; remains neutral when it orchestrates observation only. |
| Timeframe configuration | REFACTOR | Retained for compatibility, but treated as observation context rather than participant hierarchy or prediction hierarchy. |
| HH / HL / LH / LL swing logic | KEEP | Aligns with structure observation using confirmed closed-candle swings. |
| Structure context summary | REFACTOR | Retained as neutral context; wording must avoid recommendations and directional forecasts. |
| Support / Resistance zones | REFACTOR | Retained as observational participant-activity areas only. They must not be treated as buy/sell, target, stop, hold, or break predictions. |
| Retest counting | REFACTORED IN PHASE 2 START | Retests are tracked as neutral interaction evidence and separated from response and pressure observations. Count alone does not imply zone strength or weakness. |
| Zone break / flip observations | REFACTOR | Retained as observed state changes only; must not imply continuation, reversal, entry, or exit. |
| Compression observation | KEEP | Retained as non-directional range/volatility observation. |
| Expansion observation | KEEP | Retained as observed release/range expansion only; must not imply breakout direction or continuation. |
| Candle observations | KEEP | Retained as visual observations near relevant areas; no recommendation semantics. |
| Confluence rendering | REFACTOR | Retained as activity-overlap context; must not imply probability of success. |
| Local scoring functions | REFACTORED IN PHASE 2 START | Zone activity-score v1 is decomposed and used for visual priority only. |
| Rendering helpers | KEEP | Reusable chart-object layer. Rendering must not create business meaning. |
| Context panel | REFACTOR | Retained as neutral context display. Must preserve observation-only language. |
| Signal-generation concepts from legacy SOT | REMOVE | Incompatible with TDSS v2.1 neutrality. |
| HPZ / advanced activity models | DEFER | Future scope only if they satisfy neutrality and simplicity principles. |

## Removed Incompatibilities

Active documentation removes or prohibits legacy signal language such as:

- automated trading instructions
- BUY
- SELL
- LONG
- SHORT
- ENTRY
- EXIT
- NO TRADE as a directive
- trade setup
- trade opportunity
- target
- stop loss
- high probability trade
- expected direction
- probability of success

## Retained Components

- confirmed swing detection
- HH / HL / LH / LL labels
- structure context panel
- support and resistance zone rendering
- zone touch observations
- zone break and flipped-context observations
- compression rendering
- expansion observation after compression
- candle observation labels
- confluence-area rendering
- chart object cleanup

## Refactor Priorities After Phase 2 Start

1. Validate zone persistence and lifecycle behavior during live chart refreshes.
2. Continue auditing displayed wording and tooltips for neutrality.
3. Add module and function documentation headers beyond the zone engine.
4. Decide whether single-file implementation remains acceptable or requires modularization.
5. Avoid expanding into HPZ or advanced models until activity-score v1 is validated.

## Future Phase Candidates

Future phases may be considered only after Phase 2 readiness criteria are met:

1. Activity-zone model refinement.
2. Neutral activity-response observations.
3. Activity-significance scoring framework alignment.
4. Participant activity overlap model.
5. High Participant Activity Zone model, if still justified by the simplicity principle.
6. Renderer refinement and explainability improvements.
7. Performance optimization.

## Neutrality Requirement

Every future phase must verify that TDSS v2.1 does not generate or imply signals, predictions, entries, exits, targets, stop losses, trade opportunities, probability of success, expected outcome, or recommendations.
