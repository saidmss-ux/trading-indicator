# TDSS v2 Migration

## Phase 1 Objective

Phase 1 begins the controlled migration from the existing TDSS indicator toward TDSS v2. This is not a greenfield rewrite. Existing behavior is retained when it aligns with the TDSS v2 SOT.

## Legacy Component Review

| Component | Decision | Rationale |
|---|---|---|
| MT5 lifecycle (`OnInit`, `OnDeinit`, `OnCalculate`) | KEEP | Required indicator shell; remains neutral when it orchestrates observation only. |
| Timeframe configuration | REFACTOR | Retained for compatibility, but treated as observation context rather than participant hierarchy. |
| HH / HL / LH / LL swing logic | KEEP | Aligns with SOT v2 structure observation and uses confirmed closed-candle swings. |
| Structure context summary | REFACTOR | Retained as neutral context; wording must avoid recommendations. |
| Support / Resistance zones | REFACTOR | Retained as observational zone foundations only; future phases may rename or extend them into activity-zone models. |
| Compression observation | KEEP | Retained as non-directional range/volatility observation. |
| Candle observations | KEEP | Retained as visual observations near active areas; no recommendation semantics. |
| Local scoring functions | REFACTOR | Retained as activity-significance scoring only; no trade quality or direction scoring. |
| Rendering helpers | KEEP | Reusable chart-object layer. |
| Signal-generation concepts from legacy SOT | REMOVE | Incompatible with TDSS v2 neutrality. |
| HPZ / advanced activity models | NEW FUTURE | Explicitly out of Phase 1 scope. |

## Removed Incompatibilities

Phase 1 documentation removes legacy signal language such as automated trading, BUY, SELL, and NO TRADE from the active SOT.

## Retained Components

- confirmed swing detection
- HH / HL / LH / LL labels
- structure context panel
- support and resistance zone rendering
- compression rendering
- candle observation labels
- chart object cleanup

## Planned Future Phases

1. Participant activity model
2. Defense/activity-zone model refinement
3. Activity resolution model with neutral terminology
4. Activity-significance scoring framework
5. Participant activity overlap model
6. High Participant Activity Zone model
7. Renderer refinement and explainability improvements
8. Performance optimization

## Neutrality Requirement

Every future phase must verify that TDSS v2 does not generate or imply signals, predictions, entries, exits, targets, stop losses, trade opportunities, or recommendations.
