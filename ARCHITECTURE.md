# TDSS v2.1 Architecture

## Purpose

This document describes TDSS v2.1 system architecture, module responsibilities, dependencies, and documentation conventions.

Business rules remain in `SOT.md`. If this document conflicts with `SOT.md`, the SOT prevails.

## Architectural Principles

- Keep business truth separate from implementation detail.
- Every module responsibility must fit OBSERVATION, DETECTION, COMPARISON, or DISPLAY.
- Preserve neutrality and chart-first observation in every layer.
- Map visible chart behavior only; do not model participant psychology, intent, dominance, exhaustion, defense capacity, or who is winning.
- Prefer simple modules with clear inputs and outputs.
- Keep analysis, scoring, rendering, and context responsibilities separate.
- Prevent rendering code from creating business meaning.
- Prevent scoring code from implying prediction, trade quality, recommendation strength, participant state, or outcome expectation.
- Document each module so a human developer or AI coding agent can understand it quickly.

## System Layers

```text
MT5 market data
    ↓
Observation / Detection Layer
    ↓
Comparison / Display-Priority Layer
    ↓
Display Layer
    ↓
Context Panel Display
```

Display may depend on observation, detection, comparison, and display-priority outputs. Observation, detection, and comparison must not depend on display.

## Observation / Detection Layer

### Purpose

The Observation / Detection Layer stores visible chart facts and detects objective chart events from closed-candle market data.

### Responsibilities

- Load closed-candle market data for configured timeframes.
- Classify HH / HL / LH / LL structure observations.
- Classify structure context as bullish, bearish, or neutral observation.
- Prepare support and resistance zone foundations.
- Detect compression observations.
- Prepare candle observations used by the renderer.
- Prepare dynamic structure-line observations.

### Prohibited Responsibilities

The Observation / Detection Layer must not:

- draw chart objects
- create trade recommendations
- predict direction
- infer expected outcome
- infer participant intent, psychology, dominance, exhaustion, trapped participants, defense capacity, or who is winning
- assign recommendation meaning to observations

## Comparison / Display-Priority Layer

### Purpose

The Comparison / Display-Priority Layer compares visible chart facts and produces bounded display-priority values.

### Responsibilities

- Calculate display-priority values for structure observations.
- Calculate display-priority values for zones.
- Calculate display-priority values for compression observations.
- Calculate display-priority values for candle observations.
- Clamp scores to a bounded display range.

### Scoring Constraints

Scores are display hierarchy values only. Higher score means more visible; lower score means less visually prominent. Valid information must still remain visible.

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
- participant conviction
- participant weakness or strength
- quality
- outcome
- dominance
- who is winning

### Retest Constraint

Retests are observations of interaction. A display-priority implementation must not assume that retest count alone means a zone is stronger or weaker. If retests affect display priority, labels and tooltips must frame them as interaction counts only. Follow-up movement must be described as observable chart facts such as close location or distance moved after interaction, not as defense quality, conviction, exhaustion, absorption, or dominance.

## Display Layer

### Purpose

The Display Layer presents observations, detections, comparisons, and display priority on the chart.

### Responsibilities

- Create and update chart text, labels, rectangles, and trend lines.
- Display structure observations, zones, compression, confluence, candle observations, and context summaries.
- Preserve existing visual behavior where it remains SOT-aligned.
- Keep labels and tooltips concise and factual.

### Prohibited Responsibilities

The Display Layer must not:

- calculate business meaning
- convert observations into recommendations
- use prohibited signal language
- add directional implications beyond the supplied observation labels
- add participant-psychology, participant-intent, dominance, exhaustion, defense-capacity, or who-is-winning language

## Display Context Layer

### Purpose

The Display Context Layer summarizes observations across timeframes without recommending action.

### Responsibilities

- Summarize observed timeframe structure context.
- Present neutral contextual labels.
- Display chart context and visual priority without recommending action.
- Remind users that the system is in market-observation mode only.

### Prohibited Responsibilities

The Display Context Layer must not:

- produce signals
- produce automated conclusions
- state what the trader should do
- imply likely future direction
- infer participant state, intent, psychology, dominance, or who is winning

## Current Implementation Modules

The current implementation is contained in `SOT_MVP_Indicator.mq5`. It is organized with named sections that correspond to the architecture layers:

| Implementation Area | Operating Category | Responsibility |
|---|---|---|
| MT5 lifecycle functions | DISPLAY / DETECTION orchestration | Initialize indicator state, process closed bars, clean up chart objects. |
| Timeframe configuration | OBSERVATION / DISPLAY | Define observed timeframes, labels, weights, and colors. |
| Market data loading | OBSERVATION | Copy rates and ATR values for each timeframe. |
| Swing classification | DETECTION | Build confirmed HH / HL / LH / LL observations. |
| Structure context classification | COMPARISON / DISPLAY | Classify observed structure context as bullish, bearish, or neutral. |
| Zone foundation | DETECTION | Build support and resistance observation zones from confirmed swings. |
| Zone lifecycle engine | OBSERVATION / DETECTION / COMPARISON | Reconcile persisted zones, track neutral interactions, classify observable follow-up close-location / movement-after-interaction facts, and maintain lifecycle state. Current implementation uses chart-fact names for close-away and inside-zone close observations. |
| Zone behavior evaluation | DETECTION / COMPARISON | Record interactions, observed breaks, and changed lifecycle context as observations. |
| Activity scoring v1 | DISPLAY | Decompose zone display priority into observable inputs: structural relevance, interaction count, freshness, close-away count, inside-zone close count, confluence count, and compression proximity. No score wording may imply market conclusions. |
| Compression detection | DETECTION | Identify range contraction and observed expansion. |
| Candle observation detection | DETECTION | Mark selected candle observations near relevant areas. |
| Score functions | DISPLAY | Produce bounded display-priority values only. |
| Rendering helpers | DISPLAY | Draw labels, rectangles, lines, and panels. |
| Dashboard | DISPLAY | Summarize neutral multi-timeframe context. |

## Dependencies

### External Dependencies

- MetaTrader 5 indicator runtime.
- MQL5 chart object APIs.
- MQL5 market data APIs.
- MQL5 ATR indicator handle and buffer APIs.

### Internal Dependencies

- Observation and detection depend on loaded market data.
- Comparison depends on neutral observations and configured weights.
- Display depends on observation, detection, comparison, and display-priority outputs.
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

- Use `Observation`, `Detection`, `Comparison`, `Display`, `Interaction`, `CloseLocation`, and `DistanceMoved` terminology where possible.
- Avoid `Signal`, `Setup`, `Trade`, `Entry`, `Exit`, `Target`, `Stop`, `Probability`, and `Outcome` terminology unless documenting prohibited behavior.
- Use `score` only for display-priority values.

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
- Observable close-away and inside-zone close counts separated from retest count.
- Activity-score v1 treated as display-priority inputs only.
- Concise zone display text organized as Observation / Detection / Comparison / Display.
- Score-based display hierarchy for chart readability only.

### Out of Scope Until Explicitly Approved

- New feature implementation for Phase 2.
- HPZ logic.
- Advanced confluence models.
- Participant models of any kind.
- Acceleration zones.
- Slowdown zones beyond existing observation markers.
- Predictive features.
- Signal systems.
- Trade recommendations.
