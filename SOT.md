# TDSS v2.1 — Source of Truth

## 1. Purpose

TDSS v2.1 is a chart observation and contextualization system.

TDSS v2.1 exists to help a trader read a chart by organizing visible market structure, interactions, ranges, compression, expansion, and confluence into a usable decision-support map.

TDSS v2.1 is not a signal generator, prediction engine, trade recommendation system, strategy engine, automation framework, participant-psychology model, intent model, dominance model, or outcome model. The trader remains the sole decision maker.

## 2. Core Neutrality Principle

TDSS v2.1 may operate only through four categories:

- OBSERVATION: store facts directly visible on the chart
- DETECTION: detect objective chart events from observations
- COMPARISON: compare observable chart facts
- DISPLAY: show observations, detections, comparisons, and display priority

TDSS v2.1 may not:

- recommend trades
- predict future price
- infer trader intent
- infer participant psychology
- infer participant intent
- infer who is winning
- infer exhaustion, conviction, dominance, trapped participants, defense capacity, or willingness to defend
- suggest entries
- suggest exits
- suggest targets
- suggest stop losses
- suggest direction
- estimate probability of success
- estimate expected outcome

Interpretation always belongs to the trader.

## 3. Chart-First Principle

Every TDSS feature must be justified by a visible chart observation.

Allowed TDSS concepts include:

- support zone observed
- resistance zone observed
- repeated interaction observed
- price moved a measurable distance after interaction
- close location relative to a zone
- compression observed
- expansion observed
- confluence observed
- structural break observed
- HH / HL / LH / LL observed

TDSS must not store, score, display, or describe:

- buyers or sellers being exhausted
- buyers or sellers being trapped
- a defending group becoming weaker or stronger
- participant conviction
- resource consumption
- dominance
- participant intent
- who is winning
- expected outcome

These concepts may exist in a trader's interpretation, but they must not exist in TDSS business logic.

TDSS answers: “What is observable on the chart?”

TDSS does not answer: “Why are participants doing this?” or “What will happen next?”

## 4. Operating Model

All TDSS logic must fit exactly one of these categories:

| Category | Allowed purpose | Examples |
|---|---|---|
| OBSERVATION | Store facts directly visible on the chart. | price level, swing, HH / HL / LH / LL, support zone, resistance zone, zone width, zone age, interaction count, retest count, overlap count, compression duration, expansion occurrence, timeframe overlap, distance between zones. |
| DETECTION | Detect objective and repeatable chart events from observations. | new support detected, new resistance detected, retest detected, compression detected, expansion detected, overlap detected, structure change detected, zone break detected, zone flip detected. |
| COMPARISON | Compare observable chart facts without interpreting them. | older/newer, more/fewer interactions, longer/shorter compression, timeframe overlap, wider/narrower zone, closer/farther from current price. |
| DISPLAY | Present observations, detections, comparisons, and visual priority. | rectangles, labels, score, opacity, line width, ranking, context panel. |

Any concept, variable, score component, label, tooltip, or documentation text that does not fit OBSERVATION, DETECTION, COMPARISON, or DISPLAY must be simplified or removed.

The chart is the product. The score is only a display hierarchy tool.

## 5. Market Philosophy

TDSS v2.1 is chart-first. It treats price, range, structure, compression, expansion, interactions, and confluence as observable chart facts.

TDSS v2.1 maps what is visible on the chart. It does not model internal participant psychology, participant intent, dominance, exhaustion, trapped positioning, defense capacity, or who is winning.

The objective is practical chart reading, not market-behavior simulation.

## 6. Support and Resistance Philosophy

Support and Resistance are observational constructs.

They represent areas where visible chart interaction has been observed. They are not predictions, trade recommendations, or claims that price will react in a particular way.

A Support or Resistance zone may describe:

- observed historical interaction
- repeated or visible chart attention
- chart display relevance
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

## 7. Activity vs Outcome

TDSS v2.1 measures:

- significance
- visible activity
- interaction
- confluence
- recency
- contextual relevance

TDSS v2.1 does not measure:

- future direction
- probability of success
- expected outcome
- buyer/seller exhaustion
- trapped buyers or trapped sellers
- participant conviction
- participant dominance
- defense capacity
- who is winning
- trade quality
- recommendation strength
- profit potential

The system answers this question only:

> What is observable on the chart, and how visually relevant is this observation within the chart map?

It does not answer:

> What should the trader do next?

## 8. Structure Model

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

## 9. Trend Context

Trend is a contextual observation. It may influence how a trader chooses to interpret other visible chart observations, but TDSS v2.1 must not convert trend context into decisions, recommendations, directional forecasts, or trade outputs.

A trend label is descriptive, not prescriptive.

## 10. Zones

Zones are bounded chart areas derived from observable market interaction.

A zone may be described as:

- active or inactive
- recently observed or older
- more or less visually prominent as chart facts
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

## 11. Retest Philosophy

A retest is evidence of visible chart interaction.

A retest is not automatically strengthening.

A retest is not automatically weakening.

The significance of a retest depends on visible follow-up movement and surrounding chart context. Retest count alone must not create assumptions such as:

- more retests equals a stronger zone
- more retests equals a weaker zone
- fewer retests equals a stronger zone
- fewer retests equals a weaker zone

A retest may contribute to a display-priority assessment only when documented as an observation of interaction. Any further interpretation belongs to the trader. TDSS may record additional observable chart facts such as distance moved after interaction, confluence, compression, expansion, rejection-like wick shape, range contraction, or structural change, but it must not infer defense quality, absorption, conviction, exhaustion, dominance, or participant intent.

TDSS v2.1 must preserve neutral language when displaying retests. The preferred wording is:

> Price interacted with this area again; TDSS records the visible follow-up movement and surrounding chart context without inferring intent or outcome.

## 12. Compression and Expansion

Compression represents reduced range, volatility contraction, or constrained price movement. Compression is a visible range condition; TDSS must not infer hidden force, participant intent, or future direction from it.

Expansion represents observed range expansion or release from compression. Expansion is an observation, not a signal.

Compression and expansion must not be converted into breakout predictions, directional recommendations, or trade instructions.

## 13. Confluence

Confluence describes multiple observations appearing near the same price area or context.

Confluence may increase chart display relevance because more visible observations overlap around the same area.

Confluence does not imply:

- probability of success
- future direction
- trade quality
- entry validity
- target validity

## 14. Score Rule

The score is only a visual priority score.

The score is not:

- a trade score
- a probability score
- a quality score
- an outcome score
- a strength or weakness score

Higher score means more visible. Lower score means less visually prominent. Valid information must still remain visible.

Permitted score inputs are observable chart facts only:

- zone age
- interaction count
- retest count
- timeframe weight
- overlap count
- compression proximity
- structural relevance
- break / flip state
- close location after interaction
- distance moved after interaction

Scores must not imply:

- strength
- weakness
- conviction
- dominance
- defense quality
- exhaustion
- probability
- prediction
- expected continuation
- expected failure
- trade opportunity
- entry quality
- exit quality

Do not attach narrative market conclusions to the score. The only score question is:

> Which valid chart facts should be displayed more prominently so the chart remains readable?

## 15. Simplicity Principle

TDSS v2.1 must remain simple enough to be useful.

The objective is not to model market participants or every possible market behavior. The objective is to provide a usable chart-observation map.

TDSS v2.1 should reject:

- unnecessary complexity
- metrics that do not improve practical chart reading
- speculative behavioral models
- participant-psychology or intent models
- dominance, exhaustion, trapped-participant, defense-capacity, or winning/losing inferences
- redundant labels
- hidden assumptions
- features that imply prediction or recommendation

When a proposed feature adds complexity, it must be accepted only if it improves neutral chart reading and can be displayed simply.

## 16. Display Simplicity

The chart should stay simple.

TDSS may display:

- observations
- detections
- comparisons
- score-based visual priority

TDSS should avoid:

- long text explanations
- narrative labels
- market storytelling
- behavioral conclusions
- score explanations that sound like market conclusions

The user interprets the chart. TDSS displays chart facts clearly.

## 17. Documentation Principles

Project documentation must separate business truth from implementation detail.

Required documentation roles:

- `SOT.md`: business truth only; no implementation details.
- `ARCHITECTURE.md`: system architecture, module responsibilities, and dependencies.
- `DOMAIN_MODEL.md`: business entities, relationships, and business rules.
- `IMPLEMENTATION_STATUS.md`: completed features, pending features, known limitations, and readiness notes.
- `CHANGELOG.md`: historical evolution, version history, and major decisions.
- `MIGRATION.md`: legacy mapping and Keep / Refactor / Remove decisions.

Documentation must describe every feature through OBSERVATION, DETECTION, COMPARISON, or DISPLAY. It must remain understandable by human developers, AI coding agents, and future maintainers.

## 18. Prohibited Outputs

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
- buyer/seller exhaustion
- trapped buyers or trapped sellers
- participant conviction
- participant dominance
- defense capacity
- who is winning

## 19. Final Objective

TDSS v2.1 provides a chart-observation map using OBSERVATION → DETECTION → COMPARISON → DISPLAY. It reveals visible structure, zones, interactions, compression, expansion, confluence, and state changes. It does not infer participant psychology, intent, dominance, or future outcomes. It does not decide.
