# TDSS v2.1 Architecture

## Purpose

This document describes TDSS v2.1 system architecture, module responsibilities, dependencies, and documentation conventions.

Business rules remain in `SOT.md`. If this document conflicts with `SOT.md`, the SOT prevails.

## Architectural Principles

- Keep business truth separate from implementation detail.
- Preserve neutrality in every layer.
- Prefer simple modules with clear inputs and outputs.
- Keep analysis, scoring, rendering, and context responsibilities separate.
- Prevent rendering code from creating business meaning.
- Prevent scoring code from implying prediction, trade quality, or recommendation strength.
- Document each module so a human developer or AI coding agent can understand it quickly.

## System Layers

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

## Market Analysis Layer

### Purpose

The Market Analysis Layer converts closed-candle market data into neutral observations.

### Responsibilities

- Load closed-candle market data for configured timeframes.
- Classify HH / HL / LH / LL structure observations.
- Classify structure context as bullish, bearish, or neutral observation.
- Prepare support and resistance zone foundations.
- Detect compression observations.
- Prepare candle observations used by the renderer.
- Prepare dynamic structure-line observations.

### Prohibited Responsibilities

The Market Analysis Layer must not:

- draw chart objects
- create trade recommendations
- predict direction
- infer expected outcome
- assign recommendation meaning to observations

## Scoring Layer

### Purpose

The Scoring Layer converts neutral observations into bounded activity-significance values.

### Responsibilities

- Calculate activity-significance scores for structure observations.
- Calculate activity-significance scores for zones.
- Calculate activity-significance scores for compression observations.
- Calculate activity-significance scores for candle observations.
- Clamp scores to a bounded display range.

### Scoring Constraints

Scores measure market-activity significance only.

Scores must not represent:

- trade quality
- future direction
- probability of success
- expected outcome
- entry validity
- exit validity
- target validity
- stop-loss validity
- recommendation strength

### Retest Constraint

Retests are observations of interaction. A scoring implementation must not assume that retest count alone means a zone is stronger or weaker. If retests affect a displayed activity-significance value, the documentation and explanation must frame them as interaction evidence only.

## Rendering Layer

### Purpose

The Rendering Layer presents already-derived observations on the chart.

### Responsibilities

- Create and update chart text, labels, rectangles, and trend lines.
- Display structure observations, zones, compression, confluence, candle observations, and context summaries.
- Preserve existing visual behavior where it remains SOT-aligned.
- Attach neutral explanations or tooltips when possible.

### Prohibited Responsibilities

The Rendering Layer must not:

- calculate business meaning
- convert observations into recommendations
- use prohibited signal language
- add directional implications beyond the supplied observation labels

## Context Layer

### Purpose

The Context Layer summarizes observations across timeframes without recommending action.

### Responsibilities

- Summarize observed timeframe structure context.
- Present neutral contextual labels.
- Display activity-significance context without recommending action.
- Remind users that the system is in market-observation mode only.

### Prohibited Responsibilities

The Context Layer must not:

- produce signals
- produce automated conclusions
- state what the trader should do
- imply likely future direction

## Current Implementation Modules

The current implementation is contained in `SOT_MVP_Indicator.mq5`. It is organized with named sections that correspond to the architecture layers:

| Implementation Area | Architectural Layer | Responsibility |
|---|---|---|
| MT5 lifecycle functions | Orchestration | Initialize indicator state, process closed bars, clean up chart objects. |
| Timeframe configuration | Orchestration / Market Analysis | Define observed timeframes, labels, weights, and colors. |
| Market data loading | Market Analysis | Copy rates and ATR values for each timeframe. |
| Swing classification | Market Analysis | Build confirmed HH / HL / LH / LL observations. |
| Structure context classification | Market Analysis / Context | Classify observed structure context as bullish, bearish, or neutral. |
| Zone foundation | Market Analysis | Build support and resistance observation zones from confirmed swings. |
| Zone lifecycle engine | Market Analysis / Scoring | Reconcile persisted zones, track neutral interactions, classify response and pressure observations, and maintain lifecycle state. |
| Zone behavior evaluation | Market Analysis | Record interactions, observed breaks, and changed lifecycle context as observations. |
| Activity scoring v1 | Scoring | Decompose zone score into structural, interaction, freshness, response, pressure, confluence-observation, and compression-proximity components. |
| Compression detection | Market Analysis | Identify range contraction and observed expansion. |
| Candle observation detection | Market Analysis | Mark selected candle observations near relevant areas. |
| Score functions | Scoring | Produce bounded activity-significance values. |
| Rendering helpers | Rendering | Draw labels, rectangles, lines, and panels. |
| Dashboard | Context | Summarize neutral multi-timeframe context. |

## Dependencies

### External Dependencies

- MetaTrader 5 indicator runtime.
- MQL5 chart object APIs.
- MQL5 market data APIs.
- MQL5 ATR indicator handle and buffer APIs.

### Internal Dependencies

- Analysis depends on loaded market data.
- Scoring depends on neutral observations and configured weights.
- Rendering depends on analysis and scoring outputs.
- Dashboard/context display depends on context state and configured timeframe weights.

## Documentation Conventions for Code

Each major module or function group should have a concise header using this pattern:

```text
// MODULE: <module name>
// Purpose: <what this module does>
// Dependencies: <external/internal inputs it relies on>
// Inputs: <runtime data or parameters consumed>
// Outputs: <observations, scores, objects, or state produced>
// Business Notes: <neutral interpretation constraints>
// SOT References: <relevant SOT.md sections>
```

### Function-Level Documentation

Use function comments when a function encodes business meaning, non-obvious dependencies, or SOT-sensitive language.

Preferred format:

```text
// Purpose: <single sentence>
// Inputs: <key inputs>
// Output: <return value or state mutation>
// SOT: <section reference when applicable>
```

### Naming Guidelines

- Use `Observation`, `Context`, `Activity`, and `Significance` terminology where possible.
- Avoid `Signal`, `Setup`, `Trade`, `Entry`, `Exit`, `Target`, `Stop`, `Probability`, and `Outcome` terminology unless documenting prohibited behavior.
- Use `score` only for activity-significance values.

### Documentation Maintenance Rule

Any code change that changes business behavior, module responsibility, displayed terminology, or scoring interpretation must update the relevant project documentation in the same change set.

## Phase Boundaries

### Completed Foundation Scope

- TDSS v2 identity.
- Neutral documentation foundation.
- Logical separation of analysis, scoring, rendering, and context responsibilities.
- Stabilized structure observation from closed candles.
- Reusable support/resistance zone foundation.

### Phase 2 Started Scope

- Persisted support/resistance zone lifecycle reconciliation.
- Neutral interaction tracking for retests.
- Response and pressure observations separated from retest count.
- Activity-score v1 with decomposed score details.
- WHAT / WHY / IMPACT explainability for visible zones.
- Score-based visual hierarchy for chart priority only.

### Out of Scope Until Explicitly Approved

- New feature implementation for Phase 2.
- HPZ logic.
- Advanced confluence models.
- Participant models beyond neutral observations.
- Acceleration zones.
- Slowdown zones beyond existing observation markers.
- Predictive features.
- Signal systems.
- Trade recommendations.
