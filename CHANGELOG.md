# TDSS Changelog

## Purpose

This document records historical evolution, version history, and major decisions for TDSS.

Business truth remains in `SOT.md`.

## Version History

### TDSS v2.1 — Operating Model Alignment

Date: 2026-06-07

Major decisions:

- Formalized the TDSS operating model as Observation → Detection → Comparison → Display.
- Reaffirmed that the chart is the product and the score is only a display hierarchy tool.
- Simplified Phase 2 zone terminology from interpretive follow-up wording to close-away and inside-zone close observations.
- Replaced narrative zone language with concise Observation / Detection / Display text.
- Confirmed that no new feature, HPZ model, behavioral model, predictive model, or scoring system is approved by this alignment.

Implementation note:

- Renamed Phase 2 zone fields and displayed text to use close-away and inside-zone close wording.
- Scoring formula behavior remains unchanged; score meaning is restricted to display priority.

### TDSS v2.1 — Market Observation Re-Centering

Date: 2026-06-06

Major decisions:

- Re-centered TDSS business documentation on the chart-first principle: TDSS maps visible chart behavior only.
- Clarified that TDSS does not model participant psychology, participant intent, dominance, exhaustion, trapped participants, defense capacity, or who is winning.
- Classified Phase 2 follow-up terminology as observable close-away and inside-zone close facts, not behavioral conclusions.
- Reaffirmed that scores are display priority only, not strength, weakness, probability, expected outcome, or behavioral explanation.
- Confirmed that no HPZ, behavioral model, new scoring system, predictive model, or scope expansion is approved by this re-centering.

Implementation note:

- Documentation only. No indicator logic was changed.

### TDSS v2.1 Phase 2 Start — Zone Engine Foundation

Date: 2026-06-06

Major decisions:

- Began Phase 2 with a controlled implementation focused only on observational support/resistance zone lifecycle.
- Added persisted zone lifecycle reconciliation to reduce unnecessary recreation across recalculations.
- Reworked retest handling so retests are neutral interaction observations, separated from close-away and inside-zone close observations.
- Added display-priority score v1 components for structure, interaction visibility, freshness, close-away observations, inside-zone close adjustment, confluence observation, and compression proximity.
- Added concise zone display text for visible zones.
- Used score for visual hierarchy only through line style and width.
- Avoided HPZ, advanced confluence, participant inference, prediction, automation, and recommendation behavior.

Implementation note:

- Indicator logic changed only inside the Phase 2 zone-engine scope.
- Existing non-zone primitives were preserved where SOT-aligned.

### TDSS v2.1 — SOT Refresh and Documentation Standardization

Date: 2026-06-06

Major decisions:

- Clarified that retests are evidence of interaction only.
- Rejected assumptions that more retests automatically mean stronger or weaker zones.
- Reaffirmed Support and Resistance as observational constructs only.
- Clarified that TDSS measures significance, activity, interaction, and confluence.
- Clarified that TDSS does not measure future direction, probability of success, or expected outcome.
- Added the simplicity principle to reject unnecessary complexity.
- Added project-wide documentation roles for SOT, architecture, domain model, implementation status, changelog, and migration mapping.
- Added code documentation conventions for module headers and SOT-sensitive functions.
- Marked Phase 2 as not ready pending retest-alignment, documentation, neutrality audit, and scope definition.

Implementation note:

- No new features were implemented.
- No scoring logic was modified.
- Documentation was updated to prepare for future aligned development.

### TDSS v2.0 — Neutral Foundation

Major decisions:

- Established TDSS v2 as a market observation and contextualization system.
- Removed active SOT support for legacy signal language.
- Defined neutrality rules prohibiting trade recommendations, predictions, entries, exits, targets, stop losses, and trade opportunities.
- Established analysis, scoring, rendering, and context layers.
- Preserved compatible legacy indicator behavior where it aligned with neutrality.

### Legacy TDSS / MVP Indicator

Major decisions:

- Existing MT5 indicator shell retained for migration.
- Confirmed swing logic retained as a valid observation foundation.
- Support and resistance rendering retained as observational zone foundation.
- Legacy signal-generation concepts removed from the active business truth.

## Major Decision Log

| Decision | Status | Rationale |
|---|---|---|
| TDSS is observation-only | Active | Preserves trader decision ownership. |
| SOT governs business logic | Active | Prevents implementation drift. |
| Support/Resistance are observational | Active | Avoids prediction and recommendation semantics. |
| Scores are display-priority only | Active | Prevents score misuse as trade-quality, probability, behavioral, or outcome measure. |
| Retests are interaction evidence only | Active in SOT v2.1 | Prevents unsupported strength/weakness assumptions. |
| Simplicity is a design constraint | Active in SOT v2.1 | Keeps the project practical for chart reading. |
| Phase 2 is ready only for controlled validation | Active | Operating-model alignment and chart-level validation must continue before scope expansion. |
