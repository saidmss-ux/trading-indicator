# TDSS v2.1 Domain Model

## Purpose

This document defines TDSS v2.1 business entities, relationships, and rules through the operating model: Observation, Detection, Comparison, and Display.

Business truth remains governed by `SOT.md`. This document explains the domain vocabulary used by humans, maintainers, and AI coding agents.

## Domain Principles

- Every entity must fit OBSERVATION, DETECTION, COMPARISON, or DISPLAY.
- No entity is a trade instruction.
- No relationship predicts future direction.
- No entity infers participant psychology, intent, dominance, exhaustion, trapped positioning, defense capacity, or who is winning.
- Scores are display-priority values only.
- Retests represent interaction only; additional fields must describe observable chart facts, not participant motives.
- Simplicity is preferred over exhaustive market modeling.

## Entities

### Trader

The human decision maker.

Rules:

- The trader owns interpretation.
- TDSS must not decide for the trader.
- TDSS must not infer trader intent.

### Market Data

Closed-candle price, time, and range data used for observation.

Rules:

- Closed-candle data is preferred for confirmed observations.
- Market data is input, not a recommendation source.

### Timeframe Context

A configured chart timeframe used as an observation lens.

Rules:

- Timeframes provide context and weighting only.
- Higher or lower timeframe presence does not create a trade instruction.

### Structure Observation

A confirmed market-structure point classified as HH, HL, LH, or LL.

Rules:

- Structure describes past organization of price.
- Structure labels are contextual observations.
- Structure labels must not imply future movement.

### Structure Context

A summary label derived from recent structure observations.

Allowed labels:

- bullish structure context
- bearish structure context
- neutral structure context

Rules:

- Labels are descriptive, not prescriptive.
- A bullish or bearish context is not a long or short recommendation.

### Support Zone

An observational area where support-like chart interaction has been observed.

Rules:

- A support zone is not a buy area.
- A support zone is not proof price will hold.
- A support zone may be relevant for chart review because visible chart interaction was observed there.

### Resistance Zone

An observational area where resistance-like chart interaction has been observed.

Rules:

- A resistance zone is not a sell area.
- A resistance zone is not proof price will reject.
- A resistance zone may be relevant for chart review because visible chart interaction was observed there.

### Retest

A repeated interaction between price and an observed area.

Rules:

- A retest is evidence of visible chart interaction.
- A retest is not automatically strengthening.
- A retest is not automatically weakening.
- Retest significance depends on visible follow-up movement and surrounding chart context.
- Retest count alone must not be treated as a prediction or outcome measure.

### Break

An observed close beyond a zone or structure reference according to defined observation criteria.

Rules:

- A break is an observed state change.
- A break is not a signal to enter, exit, or reverse.
- A break does not guarantee continuation.

### Flip

An observed state in which a prior support-like or resistance-like zone has been broken and may be tracked as changed context.

Rules:

- A flip is a context observation.
- A flip is not a trade instruction.
- A flip does not imply that the area must act in the opposite role in the future.

### Compression Observation

A visible period of reduced range, volatility contraction, or constrained price movement.

Rules:

- Compression does not imply direction.
- Compression may be relevant because price range appears constrained on the chart.
- Compression must not be described as a guaranteed breakout setup.

### Expansion Observation

An observed range expansion or release from compression.

Rules:

- Expansion is descriptive.
- Expansion is not a signal.
- Expansion does not imply continuation.

### Candle Observation

A neutral candle-level event selected because it appears near a relevant area or has notable range/body/wick behavior.

Rules:

- Candle observations are visual context only.
- Candle observations must not be labeled as entries, exits, triggers, or setups.

### Confluence Area

An area where multiple observations overlap or appear near each other.

Rules:

- Confluence may increase visible chart display relevance.
- Confluence does not imply probability of success.
- Confluence does not imply future direction.

### Display-Priority Score

A bounded display value that controls visual hierarchy only.

Rules:

- Scores use observable inputs such as age, interaction count, overlap count, timeframe weight, compression proximity, structural relevance, break / flip state, close location, or distance moved after interaction.
- Scores do not measure strength, weakness, probability, trade quality, expected direction, expected outcome, participant intent, dominance, exhaustion, defense capacity, or who is winning.
- Scores are display-ranking aids only; higher means more visible, not better.

### Visual Element

A label, line, rectangle, panel, or other chart object displayed by TDSS.

Rules:

- Every visual element must display concise Observation, Detection, Comparison, or Display facts.
- Visual elements must not use prohibited signal language or narrative market-storytelling language.

## Feature Classification

| Concept | Operating category | Required interpretation |
|---|---|---|
| Price data, levels, ranges, ATR-sized zone width | OBSERVATION | Facts visible or derived mechanically from chart data. |
| HH / HL / LH / LL swings | DETECTION | Confirmed structure events detected from closed candles. |
| Support / Resistance zones | DETECTION | Zones detected from confirmed swing areas. |
| Zone age / freshness | COMPARISON | Newer or older source observations compared by chart index. |
| Interaction count / retest count | OBSERVATION / COMPARISON | Price range overlapped the zone; counts can be compared, not interpreted as strength or weakness. |
| Close-away count | OBSERVATION / COMPARISON | Close moved away from the zone by threshold; chart fact only. |
| Inside-zone close count | OBSERVATION / COMPARISON | Close remained inside/deep in the zone by threshold; chart fact only. |
| Confluence / overlap count | COMPARISON | Other timeframe zones are nearby; not probability. |
| Compression proximity | DETECTION / COMPARISON | Zone overlaps or sits near a detected compression range. |
| Break / flip state | DETECTION | Close moved beyond a zone threshold; not continuation or reversal expectation. |
| Display-priority score | DISPLAY | Visual hierarchy only; higher means more visible. |
| Rectangles, labels, line width, opacity, context panel | DISPLAY | Readability aids only. |

## Concepts Outside the Operating Model

| Concept | Classification | Required action |
|---|---|---|
| Defense capacity, dominance, exhaustion, trapped participants, conviction, who is winning | OUTSIDE MODEL | Remove from TDSS business logic; these belong only to trader interpretation. |
| Likely breakout, probable failure, expected continuation | OUTSIDE MODEL / PREDICTIVE | Remove from TDSS outputs. |
| Score as strength, weakness, quality, probability, or outcome | OUTSIDE MODEL | Replace with display-priority wording only. |
| Long narrative labels or market storytelling | OUTSIDE MODEL | Simplify to Observation / Detection / Comparison / Display facts. |

## Relationships

```text
Market Data
    → Timeframe Context
        → Structure Observations
        → Zone Observations
        → Compression / Expansion Observations
        → Candle Observations
            → Comparisons
                → Display-Priority Scores
                    → Visual Elements
                    → Trader Interpretation
```

Additional relationships:

- Zone observations may have retests, breaks, or flips.
- Multiple zones or observations may form confluence.
- Structure observations may inform structure context.
- Scores may help prioritize visual attention.

## Business Rules Summary

1. TDSS observes; the trader decides.
2. Support and Resistance are visible chart-interaction observations, not predictions.
3. Retests are interactions, not automatic strength or weakness signals.
4. Scores represent display priority only.
5. Context labels are descriptive only.
6. Confluence increases relevance, not probability.
7. Compression and expansion are non-directional observations.
8. Every displayed element must remain concise, factual, and neutral.
9. Simplicity overrides speculative feature expansion.
10. Any unclear business rule must be clarified in `SOT.md` before implementation.
11. TDSS stores chart facts, not behavioral conclusions.
12. Every feature must fit Observation, Detection, Comparison, or Display.
