# System Of Trading

## 1. SYSTEM OVERVIEW

- System target: MetaTrader 5 indicator and automated trading engine.
- System input: OHLCV candles across M1, M5, M15, H1.
- System detects: structure state, support/resistance zones, compression, expansion, momentum, and signal validity.
- System output: BUY, SELL, or NO TRADE.
- System priority order: structure, higher timeframe alignment, support/resistance context, compression/expansion, momentum, candlestick confirmation.
- System does not predict; system classifies current market behavior from closed candles only.
- All calculations use closed candles unless explicitly marked as real-time monitoring.

## 2. CORE DATA STRUCTURES

### MarketStructure

Fields:
- timeframe: ENUM(M1, M5, M15, H1)
- last_swing_high: SwingHigh
- last_swing_low: SwingLow
- previous_swing_high: SwingHigh
- previous_swing_low: SwingLow
- trend_state: TrendState
- bos_up: BOOLEAN
- bos_down: BOOLEAN
- validity: BOOLEAN
- updated_at: DATETIME

Update conditions:
- IF new valid SwingHigh is confirmed THEN previous_swing_high = last_swing_high AND last_swing_high = new SwingHigh.
- IF new valid SwingLow is confirmed THEN previous_swing_low = last_swing_low AND last_swing_low = new SwingLow.
- IF last_swing_high.price > previous_swing_high.price AND last_swing_low.price > previous_swing_low.price THEN trend_state = UP.
- IF last_swing_high.price < previous_swing_high.price AND last_swing_low.price < previous_swing_low.price THEN trend_state = DOWN.
- IF neither UP nor DOWN condition is true THEN trend_state = RANGE.
- IF required swing fields are missing THEN validity = FALSE ELSE validity = TRUE.

### SwingHigh

Fields:
- price: DOUBLE
- time: DATETIME
- candle_index: INTEGER
- strength: INTEGER
- validity: BOOLEAN

Update conditions:
- IF high[index] > high[index - 1] AND high[index] > high[index + 1] THEN validity = TRUE ELSE validity = FALSE.
- IF validity = TRUE THEN price = high[index] AND time = time[index] AND candle_index = index.
- strength = count of consecutive neighboring candles with lower highs on both sides.

### SwingLow

Fields:
- price: DOUBLE
- time: DATETIME
- candle_index: INTEGER
- strength: INTEGER
- validity: BOOLEAN

Update conditions:
- IF low[index] < low[index - 1] AND low[index] < low[index + 1] THEN validity = TRUE ELSE validity = FALSE.
- IF validity = TRUE THEN price = low[index] AND time = time[index] AND candle_index = index.
- strength = count of consecutive neighboring candles with higher lows on both sides.

### TrendState

Fields:
- value: ENUM(UP, DOWN, RANGE)
- confidence: INTEGER
- validity: BOOLEAN
- updated_at: DATETIME

Update conditions:
- IF MarketStructure.trend_state = UP THEN value = UP.
- IF MarketStructure.trend_state = DOWN THEN value = DOWN.
- IF MarketStructure.trend_state = RANGE THEN value = RANGE.
- confidence = sum of aligned timeframe weights.
- IF confidence >= 10 THEN validity = TRUE ELSE validity = FALSE.

### SupportResistanceZone

Fields:
- id: STRING
- type: ENUM(SUPPORT, RESISTANCE)
- timeframe: ENUM(M1, M5, M15, H1)
- upper_price: DOUBLE
- lower_price: DOUBLE
- midpoint_price: DOUBLE
- touch_count: INTEGER
- strength: ENUM(STRONG, MEDIUM, WEAK, BREAKOUT_LIKELY)
- confluence_score: INTEGER
- validity: BOOLEAN
- created_at: DATETIME
- updated_at: DATETIME
- zone_width: DOUBLE

Update conditions:
- IF SwingLow.validity = TRUE THEN create or update SUPPORT zone with midpoint_price = SwingLow.price.
- IF SwingHigh.validity = TRUE THEN create or update RESISTANCE zone with midpoint_price = SwingHigh.price.
- zone_width = ATR(14) * 0.25.
- lower_price = midpoint_price - zone_width.
- upper_price = midpoint_price + zone_width.
- midpoint_price = (upper_price + lower_price) / 2.
- IF low <= upper_price AND high >= lower_price AND close >= lower_price AND close <= upper_price THEN touch_count = touch_count + 1.
- IF touch_count = 1 THEN strength = STRONG.
- IF touch_count = 2 THEN strength = MEDIUM.
- IF touch_count = 3 THEN strength = WEAK.
- IF touch_count >= 4 THEN strength = BREAKOUT_LIKELY.
- IF close < lower_price - ATR(14) * 0.25 OR close > upper_price + ATR(14) * 0.25 THEN validity = FALSE.

### CompressionZone

Fields:
- upper_price: DOUBLE
- lower_price: DOUBLE
- start_time: DATETIME
- end_time: DATETIME
- candle_count: INTEGER
- atr_ratio: DOUBLE
- density_score: INTEGER
- validity: BOOLEAN

Update conditions:
- IF ATR(14) / ATR(50) <= 0.70 for 5 consecutive candles THEN validity = TRUE.
- IF validity = TRUE THEN upper_price = highest high of compression candles.
- IF validity = TRUE THEN lower_price = lowest low of compression candles.
- IF close > upper_price OR close < lower_price THEN validity = FALSE.

### MomentumState

Fields:
- direction: ENUM(UP, DOWN, NEUTRAL)
- body_ratio: DOUBLE
- upper_wick_ratio: DOUBLE
- lower_wick_ratio: DOUBLE
- opposite_wick_ratio: DOUBLE
- breakout_score: INTEGER
- decay: BOOLEAN
- validity: BOOLEAN
- updated_at: DATETIME

Update conditions:
- body_ratio = abs(close - open) / max(high - low, point).
- upper_wick_ratio = (high - max(open, close)) / max(high - low, point).
- lower_wick_ratio = (min(open, close) - low) / max(high - low, point).
- IF close > open THEN direction = UP AND opposite_wick_ratio = upper_wick_ratio.
- IF close < open THEN direction = DOWN AND opposite_wick_ratio = lower_wick_ratio.
- IF close = open THEN direction = NEUTRAL AND opposite_wick_ratio = max(upper_wick_ratio, lower_wick_ratio).
- IF body_ratio >= 0.60 THEN validity = TRUE ELSE validity = FALSE.

### MultiTimeframeState

Fields:
- m1_trend: TrendState
- m5_trend: TrendState
- m15_trend: TrendState
- h1_trend: TrendState
- alignment_score: INTEGER
- direction: ENUM(UP, DOWN, RANGE)
- validity: BOOLEAN
- updated_at: DATETIME

Update conditions:
- alignment_score = sum of weights for timeframes matching direction.
- IF h1_trend.value = UP AND m15_trend.value = UP AND m5_trend.value = UP AND m1_trend.value = UP THEN direction = UP.
- IF h1_trend.value = DOWN AND m15_trend.value = DOWN AND m5_trend.value = DOWN AND m1_trend.value = DOWN THEN direction = DOWN.
- IF direction != UP AND direction != DOWN THEN direction = RANGE.
- IF alignment_score >= 18 THEN validity = TRUE ELSE validity = FALSE.

## 3. MARKET STRUCTURE ENGINE (RULE SET S1-S5)

### S1: HH / HL / LH / LL Variables

- IF current SwingHigh.price > previous SwingHigh.price THEN HH = TRUE ELSE HH = FALSE.
- IF current SwingHigh.price < previous SwingHigh.price THEN LH = TRUE ELSE LH = FALSE.
- IF current SwingLow.price > previous SwingLow.price THEN HL = TRUE ELSE HL = FALSE.
- IF current SwingLow.price < previous SwingLow.price THEN LL = TRUE ELSE LL = FALSE.

### S2: Trend State

- IF HH = TRUE AND HL = TRUE THEN TrendState = UP ELSE continue.
- IF LH = TRUE AND LL = TRUE THEN TrendState = DOWN ELSE continue.
- IF TrendState is not UP and not DOWN THEN TrendState = RANGE ELSE keep TrendState.

### S3: Break Of Structure

- IF close > last_swing_high.price THEN BOS_UP = TRUE ELSE BOS_UP = FALSE.
- IF close < last_swing_low.price THEN BOS_DOWN = TRUE ELSE BOS_DOWN = FALSE.
- IF BOS_UP = TRUE AND BOS_DOWN = TRUE THEN structure validity = FALSE ELSE structure validity = TRUE.

### S4: Trend Confirmation

- IF TrendState = UP AND BOS_UP = TRUE AND close > last_swing_high.price THEN trend_confirmed = TRUE ELSE trend_confirmed = FALSE.
- IF TrendState = DOWN AND BOS_DOWN = TRUE AND close < last_swing_low.price THEN trend_confirmed = TRUE ELSE trend_confirmed = FALSE.
- IF TrendState = RANGE THEN trend_confirmed = FALSE ELSE keep computed value.

### S5: Invalidation

- IF TrendState = UP AND close < last_swing_low.price THEN invalidated = TRUE ELSE invalidated = FALSE.
- IF TrendState = DOWN AND close > last_swing_high.price THEN invalidated = TRUE ELSE keep invalidated value.
- IF invalidated = TRUE THEN TrendState = RANGE ELSE keep TrendState.

## 4. SUPPORT & RESISTANCE ENGINE (SR1-SR7)

### SR1: Zone Creation

- IF SwingLow.validity = TRUE THEN create SUPPORT zone with midpoint = SwingLow.price.
- IF SwingHigh.validity = TRUE THEN create RESISTANCE zone with midpoint = SwingHigh.price.
- zone_width = ATR(14) * 0.25.
- lower_price = midpoint - zone_width.
- upper_price = midpoint + zone_width.

### SR2: Zone Merge

- IF abs(zone_a.midpoint_price - zone_b.midpoint_price) <= max(zone_a.zone_width, zone_b.zone_width) THEN merge zones.
- merged lower_price = min(zone_a.lower_price, zone_b.lower_price).
- merged upper_price = max(zone_a.upper_price, zone_b.upper_price).
- merged touch_count = zone_a.touch_count + zone_b.touch_count.

### SR3: Zone Strength

- IF touch_count = 1 THEN strength = STRONG.
- IF touch_count = 2 THEN strength = MEDIUM.
- IF touch_count = 3 THEN strength = WEAK.
- IF touch_count >= 4 THEN strength = BREAKOUT_LIKELY.

### SR4: Zone Weakening

- IF candle low <= zone.upper_price AND candle high >= zone.lower_price THEN zone_touched = TRUE ELSE zone_touched = FALSE.
- IF zone_touched = TRUE AND close remains outside opposite boundary THEN touch_count = touch_count + 1.
- IF touch_count increases THEN recalculate strength.

### SR5: Support To Resistance Flip

- IF zone.type = SUPPORT AND close < zone.lower_price AND zone.lower_price - close >= ATR(14) * 0.25 THEN zone.type = RESISTANCE.
- IF zone.type changed THEN touch_count = 0.
- IF zone.type changed THEN updated_at = current candle time.

### SR6: Resistance To Support Flip

- IF zone.type = RESISTANCE AND close > zone.upper_price AND close - zone.upper_price >= ATR(14) * 0.25 THEN zone.type = SUPPORT.
- IF zone.type changed THEN touch_count = 0.
- IF zone.type changed THEN updated_at = current candle time.

### SR7: Multi-Timeframe Confluence

- timeframe_weight: M1 = 1, M5 = 2, M15 = 4, H1 = 10.
- IF zones overlap across timeframes THEN confluence_score = sum of overlapping timeframe weights.
- IF confluence_score >= 10 THEN zone validity = TRUE ELSE zone validity = FALSE.

## 5. MULTI-TIMEFRAME ENGINE (TF1-TF5)

### TF1: Hierarchy Weights

- M1 weight = 1.
- M5 weight = 2.
- M15 weight = 4.
- H1 weight = 10.

### TF2: Alignment Score

- bullish_alignment_score = sum weights where TrendState = UP.
- bearish_alignment_score = sum weights where TrendState = DOWN.
- range_alignment_score = sum weights where TrendState = RANGE.

### TF3: Confirmation Pipeline

- IF M1 direction matches M5 direction THEN pipeline_step_1 = TRUE ELSE pipeline_step_1 = FALSE.
- IF pipeline_step_1 = TRUE AND M5 direction matches M15 direction THEN pipeline_step_2 = TRUE ELSE pipeline_step_2 = FALSE.
- IF pipeline_step_2 = TRUE AND M15 direction matches H1 direction THEN pipeline_confirmed = TRUE ELSE pipeline_confirmed = FALSE.

### TF4: Valid Signal Condition

- IF pipeline_confirmed = TRUE AND alignment_score >= 18 THEN valid_signal = TRUE ELSE valid_signal = FALSE.
- IF H1 TrendState conflicts with signal direction THEN valid_signal = FALSE ELSE keep valid_signal.

### TF5: Invalid Signal Condition

- IF H1 TrendState = RANGE THEN invalid_signal = TRUE ELSE invalid_signal = FALSE.
- IF M15 TrendState conflicts with H1 TrendState THEN invalid_signal = TRUE ELSE keep invalid_signal.
- IF alignment_score < 18 THEN invalid_signal = TRUE ELSE keep invalid_signal.

## 6. COMPRESSION / EXPANSION ENGINE (CE1-CE6)

### CE1: ATR Compression

- atr_fast = ATR(14).
- atr_slow = ATR(50).
- atr_ratio = atr_fast / max(atr_slow, point).
- IF atr_ratio <= 0.70 for 5 consecutive closed candles THEN compression = TRUE ELSE compression = FALSE.

### CE2: Compression Zone Bounds

- IF compression = TRUE THEN compression_upper = highest high of last 5 candles.
- IF compression = TRUE THEN compression_lower = lowest low of last 5 candles.
- compression_range = compression_upper - compression_lower.

### CE3: Zone Density

- density_score = count of active SupportResistanceZone objects where zone overlaps current price range.
- IF density_score >= 3 THEN dense_zone = TRUE ELSE dense_zone = FALSE.

### CE4: Breakout Detection

- IF close > compression_upper AND candle body_ratio >= 0.60 THEN breakout_up = TRUE ELSE breakout_up = FALSE.
- IF close < compression_lower AND candle body_ratio >= 0.60 THEN breakout_down = TRUE ELSE breakout_down = FALSE.

### CE5: Expansion Trigger

- IF breakout_up = TRUE AND ATR(14) > ATR(50) THEN expansion_up = TRUE ELSE expansion_up = FALSE.
- IF breakout_down = TRUE AND ATR(14) > ATR(50) THEN expansion_down = TRUE ELSE expansion_down = FALSE.

### CE6: Compression Invalidation

- IF expansion_up = TRUE OR expansion_down = TRUE THEN compression = FALSE.
- IF compression_range > ATR(50) THEN compression = FALSE.

## 7. CANDLESTICK ENGINE (C1-C7)

### C1: Candle Range

- range = max(high - low, point).
- body = abs(close - open).
- body_ratio = body / range.

### C2: Wick Ratios

- upper_wick = high - max(open, close).
- lower_wick = min(open, close) - low.
- upper_wick_ratio = upper_wick / range.
- lower_wick_ratio = lower_wick / range.

### C3: Large Body

- IF body_ratio >= 0.60 THEN large_body = TRUE ELSE large_body = FALSE.

### C4: Small Body

- IF body_ratio <= 0.30 THEN small_body = TRUE ELSE small_body = FALSE.

### C5: Rejection

- IF upper_wick_ratio >= 0.50 AND close < open THEN bearish_rejection = TRUE ELSE bearish_rejection = FALSE.
- IF lower_wick_ratio >= 0.50 AND close > open THEN bullish_rejection = TRUE ELSE bullish_rejection = FALSE.

### C6: Acceleration

- IF large_body = TRUE for 3 consecutive candles in same direction THEN acceleration = TRUE ELSE acceleration = FALSE.

### C7: Momentum Weakening

- IF body size decreases for 3 consecutive candles in same direction THEN momentum_weakening = TRUE ELSE momentum_weakening = FALSE.

## 8. MOMENTUM ENGINE (M1-M5)

### M1: Breakout Strength Score

- breakout_score = 0.
- IF body_ratio >= 0.60 THEN breakout_score = breakout_score + 1.
- IF opposite_wick_ratio <= 0.20 THEN breakout_score = breakout_score + 1.
- IF close > open AND close >= high - range * 0.20 THEN breakout_score = breakout_score + 1.
- IF close < open AND close <= low + range * 0.20 THEN breakout_score = breakout_score + 1.

### M2: Strong Breakout

- IF breakout_score >= 3 THEN strong_breakout = TRUE ELSE strong_breakout = FALSE.

### M3: Weak Breakout

- IF body_ratio <= 0.30 THEN weak_breakout = TRUE ELSE weak_breakout = FALSE.
- IF max(upper_wick_ratio, lower_wick_ratio) >= 0.50 THEN weak_breakout = TRUE ELSE keep weak_breakout.

### M4: Fake Breakout

- IF close[1] > zone.upper_price AND close[0] >= zone.lower_price AND close[0] <= zone.upper_price THEN fake_breakout = TRUE ELSE fake_breakout = FALSE.
- IF close[1] < zone.lower_price AND close[0] >= zone.lower_price AND close[0] <= zone.upper_price THEN fake_breakout = TRUE ELSE keep fake_breakout.
- IF fake_breakout = TRUE THEN strong_breakout = FALSE.

### M5: Momentum Decay

- IF body size decreases for 3 consecutive candles THEN momentum_decay = TRUE ELSE momentum_decay = FALSE.
- IF ATR(14) decreases for 3 consecutive candles THEN momentum_decay = TRUE ELSE keep momentum_decay.

## 9. MARKET ZONE CLASSIFICATION (Z1-Z6)

### Z1: Zone Density Formula

- active_zone_count = count of valid SupportResistanceZone objects within ATR(14) * 2 of current close.
- zone_density = active_zone_count / max(ATR(14) * 2, point).

### Z2: Free Zone

- IF active_zone_count <= 1 THEN market_zone = FREE.

### Z3: Dense Zone

- IF active_zone_count >= 3 THEN market_zone = DENSE.

### Z4: Decision Zone

- IF confluence_score >= 10 AND active_zone_count >= 2 THEN market_zone = DECISION.

### Z5: Trade Avoidance

- IF market_zone = DENSE AND strong_breakout = FALSE THEN trade_allowed = FALSE ELSE trade_allowed = TRUE.
- IF market_zone = DECISION AND strong_breakout = FALSE AND bullish_rejection = FALSE AND bearish_rejection = FALSE THEN trade_allowed = FALSE ELSE keep trade_allowed.

### Z6: Zone Priority

- IF market_zone = DECISION THEN zone_priority = 3.
- IF market_zone = DENSE THEN zone_priority = 2.
- IF market_zone = FREE THEN zone_priority = 1.

## 10. SCENARIO STATE MACHINE (G1-G5)

### G1: States

- ScenarioState = ENUM(BULLISH, BEARISH, WAIT, INVALID).

### G2: BULLISH Transition

- IF TrendState = UP AND pipeline_confirmed = TRUE AND momentum direction = UP THEN ScenarioState = BULLISH.

### G3: BEARISH Transition

- IF TrendState = DOWN AND pipeline_confirmed = TRUE AND momentum direction = DOWN THEN ScenarioState = BEARISH.

### G4: WAIT Transition

- IF TrendState = RANGE THEN ScenarioState = WAIT.
- IF pipeline_confirmed = FALSE THEN ScenarioState = WAIT.
- IF trade_allowed = FALSE THEN ScenarioState = WAIT.

### G5: INVALID Transition And Reset

- IF structure invalidated = TRUE THEN ScenarioState = INVALID.
- IF fake_breakout = TRUE THEN ScenarioState = INVALID.
- IF ScenarioState = INVALID AND (BOS_UP = TRUE OR BOS_DOWN = TRUE) AND structure validity = TRUE THEN ScenarioState = WAIT.

## 11. CORE PRINCIPLE ENGINE

### Participant Flow

- participant_flow = tick_volume * candle_direction.
- candle_direction = 1 when close > open.
- candle_direction = -1 when close < open.
- candle_direction = 0 when close = open.

### Continuation Condition

- IF m5_trend.value = m15_trend.value AND m15_trend.value = h1_trend.value AND m5_trend.value != RANGE AND strong_breakout = TRUE THEN continuation = TRUE ELSE continuation = FALSE.

### Exhaustion Condition

- IF momentum_decay = TRUE AND alignment_score < 18 THEN exhaustion = TRUE ELSE exhaustion = FALSE.

### Reversal Condition

- IF TrendState = UP AND BOS_DOWN = TRUE AND momentum_state.direction = DOWN THEN reversal = TRUE ELSE reversal = FALSE.
- IF TrendState = DOWN AND BOS_UP = TRUE AND momentum_state.direction = UP THEN reversal = TRUE ELSE keep reversal.

## 12. FINAL SIGNAL GENERATION RULE

FUNCTION GenerateSignal(structure_state, sr_zones, compression_state, momentum_state, multi_timeframe_state):

1. IF structure_state.validity = FALSE THEN RETURN NO TRADE.
2. IF multi_timeframe_state.validity = FALSE THEN RETURN NO TRADE.
3. IF trade_allowed = FALSE THEN RETURN NO TRADE.
4. IF fake_breakout = TRUE THEN RETURN NO TRADE.
5. IF compression_state.validity = TRUE AND expansion_up = FALSE AND expansion_down = FALSE THEN RETURN NO TRADE.
6. IF ScenarioState = BULLISH AND TrendState = UP AND strong_breakout = TRUE AND pipeline_confirmed = TRUE THEN RETURN BUY.
7. IF ScenarioState = BEARISH AND TrendState = DOWN AND strong_breakout = TRUE AND pipeline_confirmed = TRUE THEN RETURN SELL.
8. RETURN NO TRADE.
