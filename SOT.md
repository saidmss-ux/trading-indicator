# TDSS v2.1 — Source of Truth

## 1. Purpose

TDSS v2.1 is a market observation and contextualization system.

TDSS v2.1 exists to help a trader read a chart by organizing observable market information into a usable decision-support map.

TDSS v2.1 is not a signal generator, prediction engine, trade recommendation system, strategy engine, or automation framework. The trader remains the sole decision maker.

## 2. Core Neutrality Principle

TDSS v2.1 may:

- observe
- classify
- score activity significance
- contextualize
- visualize
- explain

TDSS v2.1 may not:

- recommend trades
- predict future price
- infer trader intent
- suggest entries
- suggest exits
- suggest targets
- suggest stop losses
- suggest direction
- estimate probability of success
- estimate expected outcome

Interpretation always belongs to the trader.

## 3. Market Philosophy

The market is viewed as a collection of participants holding, defending, exiting, entering, or adjusting positions. Price is considered a consequence of participant behavior.

TDSS v2.1 models observable participant activity areas rather than future price movement.

The objective is practical chart reading, not complete market-behavior simulation.

## 4. Support and Resistance Philosophy

Support and Resistance are observational constructs.

They represent areas where participant activity has been observed. They are not predictions, trade recommendations, or claims that price will react in a particular way.

A Support or Resistance zone may describe:

- observed historical interaction
- potential participant attention
- activity significance
- confluence with other observations
- a context area for human review

A Support or Resistance zone must not be interpreted by TDSS v2.1 as:

- a buy area
- a sell area
- a target area
- a stop-loss area
- an entry area
- an exit area
- proof that price will hold
- proof that price will break

## 5. Activity vs Outcome

TDSS v2.1 measures:

- significance
- activity
- interaction
- confluence
- recency
- contextual relevance

TDSS v2.1 does not measure:

- future direction
- probability of success
- expected outcome
- trade quality
- recommendation strength
- profit potential

The system answers this question only:

> How relevant is this observation as part of a market-activity map?

It does not answer:

> What should the trader do next?

## 6. Structure Model

Market structure is represented by:

- HH
- HL
- LH
- LL

Structure describes how price has organized through confirmed observations. Structure is contextual and is not a trading signal.

Structure context labels may include:

- bullish structure context
- bearish structure context
- neutral structure context

These labels describe observed structure only. They do not imply that future price should move in the labelled direction.

## 7. Trend Context

Trend is a contextual observation. It may influence how a trader chooses to interpret other participant-activity observations, but TDSS v2.1 must not convert trend context into decisions, recommendations, directional forecasts, or trade outputs.

A trend label is descriptive, not prescriptive.

## 8. Zones

Zones are bounded chart areas derived from observable market interaction.

A zone may be described as:

- active or inactive
- recently observed or older
- more significant or less significant from an activity perspective
- overlapping with other observations
- interacted with by price
- broken or flipped as an observed state change

A zone may not be described as:

- likely to hold
- likely to fail
- a high-probability trade location
- a place to enter
- a place to exit
- a place to target
- a place to protect risk

## 9. Retest Philosophy

A retest is evidence of market interaction.

A retest is not automatically strengthening.

A retest is not automatically weakening.

The significance of a retest depends on context and market response. Retest count alone must not create assumptions such as:

- more retests equals a stronger zone
- more retests equals a weaker zone
- fewer retests equals a stronger zone
- fewer retests equals a weaker zone

A retest may contribute to an activity-significance assessment only when documented as an observation of interaction. Any stronger interpretation requires additional observable context, such as response quality, confluence, compression, expansion, rejection, absorption, or structural change.

TDSS v2.1 must preserve neutral language when explaining retests. The preferred interpretation is:

> Price interacted with this area again; significance depends on the observed response and surrounding context.

## 10. Compression and Expansion

Compression represents reduced range, volatility contraction, or constrained price movement. Compression may indicate stored market pressure, but it does not imply direction.

Expansion represents observed range expansion or release from compression. Expansion is an observation, not a signal.

Compression and expansion must not be converted into breakout predictions, directional recommendations, or trade instructions.

## 11. Confluence

Confluence describes multiple observations appearing near the same price area or context.

Confluence may increase activity significance because more observations point to an area of participant attention.

Confluence does not imply:

- probability of success
- future direction
- trade quality
- entry validity
- target validity

## 12. Scoring Philosophy

Scores measure market-activity significance only.

Scores may consider neutral observations such as:

- timeframe context
- recency
- observed interaction
- confluence
- compression or expansion observations
- candle observations near relevant areas
- structural relevance

Scores must not measure:

- probability of profit
- trade quality
- expected success
- expected direction
- recommendation strength
- whether a zone will hold
- whether a zone will break

Scores are display aids for prioritizing chart-reading attention. They are not trading instructions.

The only question answered by a score is:

> How significant is this observation from a market-activity perspective?

## 13. Simplicity Principle

TDSS v2.1 must remain simple enough to be useful.

The objective is not to model every possible market behavior. The objective is to provide a usable decision-support map.

TDSS v2.1 should reject:

- unnecessary complexity
- metrics that do not improve practical chart reading
- speculative behavioral models
- redundant labels
- hidden assumptions
- features that imply prediction or recommendation

When a proposed feature adds complexity, it must be accepted only if it improves neutral chart interpretation and can be explained clearly.

## 14. Explainability

Every visual element must be explainable through:

- WHAT: what the element is
- WHY: why it exists
- IMPACT: how participant activity may be affected or why the observation may be relevant

Explanations must remain neutral. They must not tell the trader what to do.

## 15. Documentation Principles

Project documentation must separate business truth from implementation detail.

Required documentation roles:

- `SOT.md`: business truth only; no implementation details.
- `ARCHITECTURE.md`: system architecture, module responsibilities, and dependencies.
- `DOMAIN_MODEL.md`: business entities, relationships, and business rules.
- `IMPLEMENTATION_STATUS.md`: completed features, pending features, known limitations, and readiness notes.
- `CHANGELOG.md`: historical evolution, version history, and major decisions.
- `MIGRATION.md`: legacy mapping and Keep / Refactor / Remove decisions.

Documentation must be understandable by human developers, AI coding agents, and future maintainers.

## 16. Prohibited Outputs

TDSS v2.1 must never generate, display, infer, score, or suggest:

- BUY
- SELL
- LONG
- SHORT
- ENTRY
- EXIT
- trade setup
- trade opportunity
- expected direction
- probable direction
- target
- stop loss
- risk/reward recommendation
- high probability trade
- probability of success
- expected outcome

## 17. Final Objective

TDSS v2.1 provides a behavioral map of market participation. It reveals where participant activity may be relevant. It does not decide.
