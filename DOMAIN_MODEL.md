# TDSS v2.1 Domain Model

## Purpose

This document defines TDSS v2.1 business entities, relationships, and rules in implementation-neutral language.

Business truth remains governed by `SOT.md`. This document explains the domain vocabulary used by humans, maintainers, and AI coding agents.

## Domain Principles

- Every entity is observational.
- No entity is a trade instruction.
- No relationship predicts future direction.
- Scores represent activity significance only.
- Retests represent interaction only unless additional context is documented.
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

An observational area where support-like participant activity has been observed.

Rules:

- A support zone is not a buy area.
- A support zone is not proof price will hold.
- A support zone may be relevant for chart review because participant activity was observed there.

### Resistance Zone

An observational area where resistance-like participant activity has been observed.

Rules:

- A resistance zone is not a sell area.
- A resistance zone is not proof price will reject.
- A resistance zone may be relevant for chart review because participant activity was observed there.

### Retest

A repeated interaction between price and an observed area.

Rules:

- A retest is evidence of market interaction.
- A retest is not automatically strengthening.
- A retest is not automatically weakening.
- Retest significance depends on context and market response.
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

A period of reduced range, volatility contraction, or constrained price movement.

Rules:

- Compression does not imply direction.
- Compression may be relevant because participant activity appears constrained.
- Compression must not be explained as a guaranteed breakout setup.

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

- Confluence may increase activity significance.
- Confluence does not imply probability of success.
- Confluence does not imply future direction.

### Activity-Significance Score

A bounded display value that prioritizes observations by neutral relevance.

Rules:

- Scores measure significance, activity, interaction, confluence, recency, or contextual relevance.
- Scores do not measure profit probability, trade quality, expected direction, or expected outcome.
- Scores are chart-reading aids only.

### Visual Element

A label, line, rectangle, panel, or other chart object displayed by TDSS.

Rules:

- Every visual element must be explainable through WHAT, WHY, and IMPACT.
- Visual elements must not use prohibited signal language.

## Relationships

```text
Market Data
    → Timeframe Context
        → Structure Observations
        → Zone Observations
        → Compression / Expansion Observations
        → Candle Observations
            → Activity-Significance Scores
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
2. Support and Resistance are participant-activity observations, not predictions.
3. Retests are interactions, not automatic strength or weakness signals.
4. Scores represent activity significance only.
5. Context labels are descriptive only.
6. Confluence increases relevance, not probability.
7. Compression and expansion are non-directional observations.
8. Every displayed element must remain explainable and neutral.
9. Simplicity overrides speculative feature expansion.
10. Any unclear business rule must be clarified in `SOT.md` before implementation.
