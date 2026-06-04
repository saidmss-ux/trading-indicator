# TDSS v2 Architecture

## Purpose

This document describes the Phase 1 TDSS v2 architecture. It defines responsibilities and dependencies only; business rules remain in `SOT.md`.

## Layers

### Market Analysis Layer

Responsibilities:

- load closed-candle market data for configured timeframes
- classify HH / HL / LH / LL structure observations
- classify structure context as bullish, bearish, or neutral observation
- prepare support and resistance zone foundations
- detect compression observations
- prepare candle observations used by the renderer

The Market Analysis Layer must not draw chart objects and must not create trade recommendations.

### Scoring Layer

Responsibilities:

- calculate activity-significance scores for structure observations
- calculate activity-significance scores for zones
- calculate activity-significance scores for compression and candle observations
- clamp scores to a bounded display range

The Scoring Layer measures market activity significance only. It must not score trade quality, direction, probability, entries, exits, targets, or stop losses.

### Rendering Layer

Responsibilities:

- create and update chart text, labels, rectangles, and trend lines
- display structure, zones, compression, confluence, candle observations, and context summaries
- preserve existing visual behavior where it remains SOT-aligned

The Rendering Layer must consume analysis results. It must not calculate business meaning.

### Context Layer

Responsibilities:

- summarize observed timeframe structure context
- present neutral contextual labels
- display activity-significance context without recommending action

The Context Layer must not produce signals or automated conclusions.

## Dependencies

```text
MT5 market data
    ↓
Market Analysis Layer
    ↓
Scoring Layer
    ↓
Rendering Layer
    ↓
Context Layer display
```

Rendering may depend on analysis and score outputs. Analysis and scoring must not depend on rendering.

## Phase 1 Boundaries

Implemented in Phase 1:

- TDSS v2 identity
- neutral documentation foundation
- logical separation of analysis, scoring, rendering, and context responsibilities
- stabilized structure observation from closed candles
- reusable support/resistance zone foundation

Out of scope in Phase 1:

- HPZ logic
- advanced confluence models
- participant models
- acceleration zones
- slowdown zones
- predictive features
- signal systems
- trade recommendations
