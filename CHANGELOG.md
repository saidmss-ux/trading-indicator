# TDSS Changelog

## Purpose

This document records historical evolution, version history, and major decisions for TDSS.

Business truth remains in `SOT.md`.

## Version History

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
| Scores measure activity significance only | Active | Prevents score misuse as trade-quality or probability measure. |
| Retests are interaction evidence only | Active in SOT v2.1 | Prevents unsupported strength/weakness assumptions. |
| Simplicity is a design constraint | Active in SOT v2.1 | Keeps the project practical for chart reading. |
| Phase 2 is not ready | Active | Alignment and documentation work remains before coding. |
