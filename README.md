# Trading Indicator

## Project overview

This repository isfor a MetaTrader 5 indicator project. DocuHub means the repository documentation hub: it keeps project intent, validated rules, and agent constraints aligned before implementation starts.

The project goal is to build a MetaTrader 5 indicator based on:

- Market Structure (HH, HL, LH, LL)
- Multi-timeframe support and resistance
- Confluence zones
- Momentum analysis
- Japanese candlestick analysis
- Acceleration zones
- Deceleration zones
- Decision zones

## Objectives

- Keep `SOT.md` as the single source of truth for validated business rules.
- Keep documentation lightweight and aligned after each approved change.
- Avoid implementation details until the corresponding rules are validated.
- Build future code from validated rules only.

## Folder structure

```text
.
├── README.md   # Project overview and workflow
├── SOT.md      # Validated business rules only
└── AGENT.md    # AI coding agent instructions
```

## Development workflow

1. Validate or update business rules in `SOT.md`.
2. Ask for clarification when a required rule is missing.
3. Implement only validated and approved scope.
4. Keep documentation aligned with each implementation or modification.
5. Run relevant checks before delivery.
