#property copyright "TDSS v2"
#property link      ""
#property version   "2.10"
#property strict
#property indicator_chart_window
#property indicator_plots 0

input int    InpSwingConfirmBars        = 3;
input int    InpBarsPerTimeframe        = 220;
input int    InpStructureLabelsPerTf    = 8;
input int    InpZoneExtendBars          = 180;
input int    InpATRPeriod               = 14;
input double InpZoneATRBuffer           = 0.30;
input int    InpCompressionBars         = 7;
input double InpCompressionATRFactor    = 0.72;
input double InpSmallBodyRatio          = 0.25;
input double InpStrongBodyRatio         = 0.62;
input double InpExtendedWickRatio       = 0.55;
input int    InpImportantCandlesMax     = 18;
input int    InpConfluenceDistancePts   = 250;
input int    InpHighScoreThreshold      = 75;
input bool   InpShowStructureLabels     = true;
input bool   InpShowStructureLines      = true;
input bool   InpShowZones               = true;
input bool   InpShowCompression         = true;
input bool   InpShowCandles             = true;
input bool   InpShowContextPanel        = true;
input int    InpM1Weight                = 1;
input int    InpM5Weight                = 2;
input int    InpM15Weight               = 4;
input int    InpH1Weight                = 10;
input int    InpH4Weight                = 20;
input int    InpInteractionScoreWeight  = 3;
input int    InpConfluenceScoreWeight   = 8;
input int    InpRecencyScoreWeight      = 12;
input int    InpCandleBaseScore         = 45;
input int    InpCompressionBaseScore    = 55;
input int    InpFillAlpha               = 38;
input color  InpM1Color                 = clrSilver;
input color  InpM5Color                 = clrDeepSkyBlue;
input color  InpM15Color                = clrMediumSeaGreen;
input color  InpH1Color                 = clrOrange;
input color  InpH4Color                 = clrViolet;
input color  InpSupportColor            = clrSeaGreen;
input color  InpResistanceColor         = clrIndianRed;
input color  InpFlipColor               = clrDarkOrange;
input color  InpCompressionColor        = clrSlateGray;
input color  InpImportantColor          = clrGold;
input color  InpPanelColor              = clrWhite;

#define TDSS_PREFIX "TDSS_V2_"
#define TDSS_LEGACY_PREFIX "SOT_TDSS_"
#define TF_COUNT 5
#define SWING_HIGH_TYPE 1
#define SWING_LOW_TYPE -1
#define ZONE_SUPPORT_TYPE 1
#define ZONE_RESISTANCE_TYPE -1
#define CONTEXT_UP 1
#define CONTEXT_DOWN -1
#define CONTEXT_FLAT 0

struct SwingPoint
{
   int      type;
   int      index;
   double   price;
   datetime time;
   string   label;
   int      score;
};

struct ZoneInfo
{
   bool     valid;
   bool     broken;
   bool     flipped;
   int      zone_type;
   int      timeframe_index;
   int      source_index;
   int      retests;
   int      interaction_observations;
   int      response_observations;
   int      pressure_observations;
   int      confluence_observations;
   int      score;
   int      structural_score;
   int      interaction_score;
   int      freshness_score;
   int      response_score;
   int      pressure_adjustment;
   int      confluence_score;
   int      compression_score;
   double   upper;
   double   lower;
   double   midpoint;
   datetime start_time;
   datetime end_time;
   datetime break_time;
   datetime last_interaction_time;
   string   identity;
   string   lifecycle_state;
   string   reason;
   string   what;
   string   why;
   string   impact;
   string   score_details;
};

struct CompressionInfo
{
   bool     valid;
   bool     expanded;
   int      timeframe_index;
   int      score;
   double   upper;
   double   lower;
   datetime start_time;
   datetime end_time;
   string   reason;
};

struct CandleMark
{
   bool     valid;
   int      score;
   double   price;
   datetime time;
   string   label;
   string   reason;
   color    mark_color;
};

struct StructureLineObservation
{
   bool     valid;
   bool     support_line;
   bool     broken;
   datetime first_time;
   double   first_price;
   datetime second_time;
   double   second_price;
   datetime break_time;
   double   break_price;
   string   tooltip;
   string   break_label;
   string   break_tooltip;
};

string          g_prefix = "";
datetime        g_last_closed_bar_time = 0;
datetime        g_last_tf_closed_bar_time[TF_COUNT];
ENUM_TIMEFRAMES g_timeframes[TF_COUNT];
string          g_tf_names[TF_COUNT];
int             g_tf_weights[TF_COUNT];
color           g_tf_colors[TF_COUNT];
int             g_atr_handles[TF_COUNT];
ZoneInfo        g_support_zones[TF_COUNT];
ZoneInfo        g_resistance_zones[TF_COUNT];
CompressionInfo g_compressions[TF_COUNT];
int             g_context_states[TF_COUNT];

int OnInit()
{
   g_prefix = TDSS_PREFIX + IntegerToString((int)ChartID()) + "_";
   DeleteObjectsByPrefix(TDSS_LEGACY_PREFIX + IntegerToString((int)ChartID()) + "_");
   DeleteObjectGroup("ZONE_FLIP_");
   ConfigureTimeframes();

   for(int i = 0; i < TF_COUNT; ++i)
   {
      g_atr_handles[i] = iATR(_Symbol, g_timeframes[i], InpATRPeriod);
      if(g_atr_handles[i] == INVALID_HANDLE)
         return INIT_FAILED;
      ResetZone(g_support_zones[i]);
      ResetZone(g_resistance_zones[i]);
      ResetCompression(g_compressions[i]);
      g_context_states[i] = CONTEXT_FLAT;
      g_last_tf_closed_bar_time[i] = 0;
   }

   IndicatorSetString(INDICATOR_SHORTNAME, "TDSS v2.1 Market Observation");
   DrawDashboard();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   DeleteAllTDSSObjects();
   for(int i = 0; i < TF_COUNT; ++i)
   {
      if(g_atr_handles[i] != INVALID_HANDLE)
         IndicatorRelease(g_atr_handles[i]);
   }
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < RequiredBars())
      return 0;

   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);

   if(prev_calculated > 0 && g_last_closed_bar_time == time[1])
   {
      DrawDashboard();
      return rates_total;
   }
   g_last_closed_bar_time = time[1];

   DeleteTransientObjects();

   for(int tf_index = 0; tf_index < TF_COUNT; ++tf_index)
      ProcessTimeframe(tf_index);

   RefreshZoneScoresAndRendering();
   DrawConfluenceAreas();
   DrawDashboard();
   ChartRedraw(0);
   return rates_total;
}

int RequiredBars()
{
   return MathMax(80, InpATRPeriod + InpCompressionBars + InpSwingConfirmBars * 2 + 20);
}

void ConfigureTimeframes()
{
   g_timeframes[0] = PERIOD_M1;
   g_timeframes[1] = PERIOD_M5;
   g_timeframes[2] = PERIOD_M15;
   g_timeframes[3] = PERIOD_H1;
   g_timeframes[4] = PERIOD_H4;

   g_tf_names[0] = "M1";
   g_tf_names[1] = "M5";
   g_tf_names[2] = "M15";
   g_tf_names[3] = "H1";
   g_tf_names[4] = "H4";

   g_tf_weights[0] = InpM1Weight;
   g_tf_weights[1] = InpM5Weight;
   g_tf_weights[2] = InpM15Weight;
   g_tf_weights[3] = InpH1Weight;
   g_tf_weights[4] = InpH4Weight;

   g_tf_colors[0] = InpM1Color;
   g_tf_colors[1] = InpM5Color;
   g_tf_colors[2] = InpM15Color;
   g_tf_colors[3] = InpH1Color;
   g_tf_colors[4] = InpH4Color;
}

void ProcessTimeframe(const int tf_index)
{
   MqlRates rates[];
   double atr[];
   int copied_rates = 0;
   int scan_limit = 0;

   if(!LoadTimeframeMarketData(tf_index, rates, atr, copied_rates, scan_limit))
      return;

   SwingPoint swings[];
   CandleMark candle_marks[];
   StructureLineObservation structure_lines[];
   ArrayResize(swings, 0);
   ArrayResize(candle_marks, 0);
   ArrayResize(structure_lines, 0);

   AnalyzeMarketTimeframe(tf_index, rates, copied_rates, scan_limit, atr, swings, candle_marks, structure_lines);
   RenderTimeframeObservations(tf_index, atr, swings, candle_marks, structure_lines);
}

// MARKET ANALYSIS LAYER
bool LoadTimeframeMarketData(const int tf_index,
                             MqlRates &rates[],
                             double &atr[],
                             int &copied_rates,
                             int &scan_limit)
{
   ArraySetAsSeries(rates, true);
   ArraySetAsSeries(atr, true);

   int bars_needed = MathMax(InpBarsPerTimeframe, RequiredBars());
   copied_rates = CopyRates(_Symbol, g_timeframes[tf_index], 0, bars_needed, rates);
   if(copied_rates < RequiredBars())
      return false;

   int copied_atr = CopyBuffer(g_atr_handles[tf_index], 0, 0, copied_rates, atr);
   if(copied_atr < RequiredBars())
      return false;

   scan_limit = MathMin(copied_rates - InpSwingConfirmBars - 2, InpBarsPerTimeframe - InpSwingConfirmBars - 2);
   if(scan_limit <= InpSwingConfirmBars + 2)
      return false;

   g_last_tf_closed_bar_time[tf_index] = rates[1].time;
   return true;
}

void AnalyzeMarketTimeframe(const int tf_index,
                            const MqlRates &rates[],
                            const int copied_rates,
                            const int scan_limit,
                            const double &atr[],
                            SwingPoint &swings[],
                            CandleMark &candle_marks[],
                            StructureLineObservation &structure_lines[])
{
   BuildSwings(tf_index, rates, copied_rates, scan_limit, atr, swings);
   g_context_states[tf_index] = ClassifyStructureContext(swings);

   BuildLatestZones(tf_index, rates, copied_rates, scan_limit, atr, g_support_zones[tf_index], g_resistance_zones[tf_index]);
   DetectCompression(tf_index, rates, copied_rates, scan_limit, atr, g_compressions[tf_index]);
   BuildStructureLineObservations(tf_index, swings, rates, structure_lines);

   if(tf_index <= 2)
      BuildImportantCandles(tf_index, rates, copied_rates, scan_limit, atr, candle_marks);
}

// RENDERING LAYER
void RenderTimeframeObservations(const int tf_index,
                                 const double &atr[],
                                 const SwingPoint &swings[],
                                 const CandleMark &candle_marks[],
                                 const StructureLineObservation &structure_lines[])
{
   if(InpShowStructureLabels)
      DrawStructure(tf_index, swings, atr);

   if(InpShowStructureLines)
      RenderStructureLines(tf_index, structure_lines);

   if(InpShowCompression)
      DrawCompression(g_compressions[tf_index]);

   if(InpShowCandles && tf_index <= 2)
      RenderImportantCandles(tf_index, candle_marks);
}

void BuildSwings(const int tf_index,
                 const MqlRates &rates[],
                 const int total,
                 const int scan_limit,
                 const double &atr[],
                 SwingPoint &swings[])
{
   double previous_high = 0.0;
   double previous_low = 0.0;

   for(int i = scan_limit; i >= InpSwingConfirmBars + 1; --i)
   {
      if(IsConfirmedSwingHigh(rates, total, i))
      {
         SwingPoint swing;
         swing.type = SWING_HIGH_TYPE;
         swing.index = i;
         swing.price = rates[i].high;
         swing.time = rates[i].time;
         swing.label = (previous_high <= 0.0 || swing.price > previous_high) ? "HH" : "LH";
         swing.score = ScoreStructurePoint(tf_index, swing, atr[i], previous_high);
         previous_high = swing.price;
         AppendSwing(swings, swing);
      }

      if(IsConfirmedSwingLow(rates, total, i))
      {
         SwingPoint swing;
         swing.type = SWING_LOW_TYPE;
         swing.index = i;
         swing.price = rates[i].low;
         swing.time = rates[i].time;
         swing.label = (previous_low <= 0.0 || swing.price > previous_low) ? "HL" : "LL";
         swing.score = ScoreStructurePoint(tf_index, swing, atr[i], previous_low);
         previous_low = swing.price;
         AppendSwing(swings, swing);
      }
   }
}

bool IsConfirmedSwingHigh(const MqlRates &rates[], const int total, const int index)
{
   if(index <= InpSwingConfirmBars || index + InpSwingConfirmBars >= total)
      return false;

   for(int offset = 1; offset <= InpSwingConfirmBars; ++offset)
   {
      if(rates[index].high <= rates[index - offset].high)
         return false;
      if(rates[index].high <= rates[index + offset].high)
         return false;
   }
   return true;
}

bool IsConfirmedSwingLow(const MqlRates &rates[], const int total, const int index)
{
   if(index <= InpSwingConfirmBars || index + InpSwingConfirmBars >= total)
      return false;

   for(int offset = 1; offset <= InpSwingConfirmBars; ++offset)
   {
      if(rates[index].low >= rates[index - offset].low)
         return false;
      if(rates[index].low >= rates[index + offset].low)
         return false;
   }
   return true;
}

void AppendSwing(SwingPoint &swings[], const SwingPoint &swing)
{
   int size = ArraySize(swings);
   ArrayResize(swings, size + 1);
   swings[size] = swing;
}

int ClassifyStructureContext(const SwingPoint &swings[])
{
   double prev_high = 0.0;
   double last_high = 0.0;
   double prev_low = 0.0;
   double last_low = 0.0;

   for(int i = 0; i < ArraySize(swings); ++i)
   {
      if(swings[i].type == SWING_HIGH_TYPE)
      {
         prev_high = last_high;
         last_high = swings[i].price;
      }
      else if(swings[i].type == SWING_LOW_TYPE)
      {
         prev_low = last_low;
         last_low = swings[i].price;
      }
   }

   if(prev_high <= 0.0 || prev_low <= 0.0 || last_high <= 0.0 || last_low <= 0.0)
      return CONTEXT_FLAT;
   if(last_high > prev_high && last_low > prev_low)
      return CONTEXT_UP;
   if(last_high < prev_high && last_low < prev_low)
      return CONTEXT_DOWN;
   return CONTEXT_FLAT;
}

// SCORING LAYER
int ScoreStructurePoint(const int tf_index, const SwingPoint &swing, const double atr_value, const double previous_price)
{
   int score = 40 + g_tf_weights[tf_index];
   if(previous_price > 0.0)
   {
      double distance = MathAbs(swing.price - previous_price);
      if(distance >= atr_value * 0.50)
         score += 12;
      if(distance >= atr_value)
         score += 10;
   }
   score += MathMax(0, InpRecencyScoreWeight - swing.index / 10);
   return ClampScore(score);
}

// MODULE: Zone lifecycle and activity scoring v1
// Purpose: Maintains observational Support / Resistance zones, neutral interaction evidence, lifecycle state, and activity-significance score details.
// Dependencies: Confirmed swing observations, closed-candle market data, ATR values, timeframe context, compression observations, and nearby zone observations.
// Inputs: Timeframe rates, ATR values, configured score weights, and existing persisted zone state.
// Outputs: Stable zone state with WHAT / WHY / IMPACT explainability and score components used only for visual priority.
// Business Notes: Retests are interaction evidence only. Score changes must not imply direction, certainty, recommendation, or expected outcome.
// SOT References: SOT.md sections 4, 5, 8, 9, 11, 12, 13, and 14.
void BuildLatestZones(const int tf_index,
                      const MqlRates &rates[],
                      const int total,
                      const int scan_limit,
                      const double &atr[],
                      ZoneInfo &support_zone,
                      ZoneInfo &resistance_zone)
{
   ZoneInfo support_candidate;
   ZoneInfo resistance_candidate;
   ResetZone(support_candidate);
   ResetZone(resistance_candidate);

   bool support_found = false;
   bool resistance_found = false;

   for(int i = InpSwingConfirmBars + 1; i <= scan_limit; ++i)
   {
      if(!support_found && IsConfirmedSwingLow(rates, total, i))
      {
         CreateZone(tf_index, ZONE_SUPPORT_TYPE, i, rates, rates[i].low, atr[i], support_candidate);
         support_found = true;
      }

      if(!resistance_found && IsConfirmedSwingHigh(rates, total, i))
      {
         CreateZone(tf_index, ZONE_RESISTANCE_TYPE, i, rates, rates[i].high, atr[i], resistance_candidate);
         resistance_found = true;
      }

      if(support_found && resistance_found)
         break;
   }

   ReconcileZoneLifecycle(support_zone, support_candidate, rates, atr);
   ReconcileZoneLifecycle(resistance_zone, resistance_candidate, rates, atr);
}

void ReconcileZoneLifecycle(ZoneInfo &existing_zone,
                            const ZoneInfo &candidate_zone,
                            const MqlRates &rates[],
                            const double &atr[])
{
   if(!candidate_zone.valid)
   {
      if(existing_zone.valid)
         EvaluateZoneBehavior(existing_zone, rates, atr);
      return;
   }

   if(!existing_zone.valid || existing_zone.broken || !IsSameZoneObservation(existing_zone, candidate_zone))
      CopyZone(candidate_zone, existing_zone);
   else
      UpdatePersistedZone(existing_zone, candidate_zone);

   EvaluateZoneBehavior(existing_zone, rates, atr);
}

bool IsSameZoneObservation(const ZoneInfo &existing_zone, const ZoneInfo &candidate_zone)
{
   if(!existing_zone.valid || !candidate_zone.valid)
      return false;
   if(existing_zone.zone_type != candidate_zone.zone_type || existing_zone.timeframe_index != candidate_zone.timeframe_index)
      return false;

   double tolerance = MathMax((existing_zone.upper - existing_zone.lower), _Point * 20.0);
   return MathAbs(existing_zone.midpoint - candidate_zone.midpoint) <= tolerance;
}

void CopyZone(const ZoneInfo &source_zone, ZoneInfo &target_zone)
{
   target_zone = source_zone;
}

void UpdatePersistedZone(ZoneInfo &existing_zone, const ZoneInfo &candidate_zone)
{
   existing_zone.source_index = candidate_zone.source_index;
   existing_zone.upper = (existing_zone.upper + candidate_zone.upper) / 2.0;
   existing_zone.lower = (existing_zone.lower + candidate_zone.lower) / 2.0;
   existing_zone.midpoint = (existing_zone.upper + existing_zone.lower) / 2.0;
   existing_zone.end_time = 0;
   existing_zone.reason = ZoneName(existing_zone.zone_type) + " " + g_tf_names[existing_zone.timeframe_index] + " from persisted confirmed swing area";
   existing_zone.why = "WHY: derived from a confirmed swing and maintained because the refreshed observation remains near the same area.";
}

void CreateZone(const int tf_index,
                const int zone_type,
                const int source_index,
                const MqlRates &rates[],
                const double midpoint,
                const double atr_value,
                ZoneInfo &zone)
{
   double width = MathMax(atr_value * InpZoneATRBuffer, _Point * 20.0);
   zone.valid = true;
   zone.broken = false;
   zone.flipped = false;
   zone.zone_type = zone_type;
   zone.timeframe_index = tf_index;
   zone.source_index = source_index;
   zone.retests = 0;
   zone.interaction_observations = 0;
   zone.response_observations = 0;
   zone.pressure_observations = 0;
   zone.confluence_observations = 0;
   zone.score = 0;
   zone.structural_score = 0;
   zone.interaction_score = 0;
   zone.freshness_score = 0;
   zone.response_score = 0;
   zone.pressure_adjustment = 0;
   zone.confluence_score = 0;
   zone.compression_score = 0;
   zone.upper = midpoint + width;
   zone.lower = midpoint - width;
   zone.midpoint = midpoint;
   zone.start_time = rates[source_index].time;
   zone.end_time = 0;
   zone.break_time = 0;
   zone.last_interaction_time = 0;
   zone.identity = g_tf_names[tf_index] + "_" + ZoneName(zone_type) + "_" + IntegerToString((int)zone.start_time);
   zone.lifecycle_state = "Active observation";
   zone.reason = ZoneName(zone_type) + " " + g_tf_names[tf_index] + " from confirmed swing";
   zone.what = "WHAT: " + ZoneName(zone_type) + " observation zone on " + g_tf_names[tf_index] + ".";
   zone.why = "WHY: derived from a confirmed swing area where participant activity was observed.";
   zone.impact = "IMPACT: marks an area that may deserve chart-reading attention; it does not imply direction or a decision.";
   zone.score_details = "Score pending activity assessment.";
}

void EvaluateZoneBehavior(ZoneInfo &zone, const MqlRates &rates[], const double &atr[])
{
   if(!zone.valid)
      return;

   zone.broken = false;
   zone.flipped = false;
   zone.retests = 0;
   zone.interaction_observations = 0;
   zone.response_observations = 0;
   zone.pressure_observations = 0;
   zone.last_interaction_time = 0;
   zone.lifecycle_state = "Active observation";
   zone.end_time = 0;
   zone.break_time = 0;

   double break_buffer = MathMax(atr[zone.source_index] * InpZoneATRBuffer, _Point * 20.0);
   bool in_touch_sequence = false;

   for(int i = zone.source_index - 1; i >= 1; --i)
   {
      bool touched = (rates[i].high >= zone.lower && rates[i].low <= zone.upper);
      if(touched && !in_touch_sequence)
      {
         RegisterZoneInteraction(zone, rates, atr, i);
         in_touch_sequence = true;
      }
      else if(!touched)
         in_touch_sequence = false;

      if(zone.zone_type == ZONE_SUPPORT_TYPE && rates[i].close < zone.lower - break_buffer)
      {
         zone.broken = true;
         zone.flipped = true;
         zone.break_time = rates[i].time;
         zone.end_time = rates[i].time;
         zone.lifecycle_state = "Inactive after observed break";
         zone.reason = ZoneName(zone.zone_type) + " " + g_tf_names[zone.timeframe_index] + " from confirmed swing; observed break changed lifecycle state";
         return;
      }

      if(zone.zone_type == ZONE_RESISTANCE_TYPE && rates[i].close > zone.upper + break_buffer)
      {
         zone.broken = true;
         zone.flipped = true;
         zone.break_time = rates[i].time;
         zone.end_time = rates[i].time;
         zone.lifecycle_state = "Inactive after observed break";
         zone.reason = ZoneName(zone.zone_type) + " " + g_tf_names[zone.timeframe_index] + " from confirmed swing; observed break changed lifecycle state";
         return;
      }
   }

   if(zone.pressure_observations > zone.response_observations && zone.interaction_observations > 0)
      zone.lifecycle_state = "Active with pressure observations";
   else if(zone.response_observations > 0)
      zone.lifecycle_state = "Active with response observations";
}

void RegisterZoneInteraction(ZoneInfo &zone, const MqlRates &rates[], const double &atr[], const int index)
{
   zone.retests++;
   zone.interaction_observations++;
   zone.last_interaction_time = rates[index].time;

   double response_buffer = MathMax(atr[index] * 0.20, _Point * 20.0);
   bool response_observed = false;
   bool pressure_observed = false;

   if(zone.zone_type == ZONE_SUPPORT_TYPE)
   {
      response_observed = (rates[index].close > zone.upper + response_buffer);
      pressure_observed = (rates[index].close <= zone.midpoint);
   }
   else if(zone.zone_type == ZONE_RESISTANCE_TYPE)
   {
      response_observed = (rates[index].close < zone.lower - response_buffer);
      pressure_observed = (rates[index].close >= zone.midpoint);
   }

   if(response_observed)
      zone.response_observations++;
   else if(pressure_observed)
      zone.pressure_observations++;
}

void ScoreZone(ZoneInfo &zone)
{
   if(!zone.valid)
      return;

   zone.structural_score = 35 + g_tf_weights[zone.timeframe_index];
   zone.interaction_score = MathMin(12, zone.interaction_observations * InpInteractionScoreWeight);
   zone.freshness_score = MathMax(0, InpRecencyScoreWeight - zone.source_index / 10);
   zone.response_score = MathMin(18, zone.response_observations * 6);
   zone.pressure_adjustment = MathMin(18, zone.pressure_observations * 5);
   zone.confluence_observations = CountZoneConfluence(zone);
   zone.confluence_score = zone.confluence_observations * InpConfluenceScoreWeight;
   zone.compression_score = IsZoneNearCompression(zone) ? 8 : 0;

   int score = zone.structural_score;
   score += zone.interaction_score;
   score += zone.freshness_score;
   score += zone.response_score;
   score += zone.confluence_score;
   score += zone.compression_score;
   score -= zone.pressure_adjustment;
   if(zone.broken)
      score -= 20;

   zone.score = ClampScore(score);
   zone.score_details = "Score detail: structure " + IntegerToString(zone.structural_score) +
                        ", interaction " + IntegerToString(zone.interaction_score) +
                        ", freshness " + IntegerToString(zone.freshness_score) +
                        ", response " + IntegerToString(zone.response_score) +
                        ", pressure adjustment -" + IntegerToString(zone.pressure_adjustment) +
                        ", confluence " + IntegerToString(zone.confluence_score) +
                        ", compression " + IntegerToString(zone.compression_score) + ".";
   zone.impact = "IMPACT: score controls visual priority for chart reading only; it does not describe future direction, certainty, or a decision.";
}

bool IsZoneNearCompression(const ZoneInfo &zone)
{
   if(!zone.valid)
      return false;

   double tolerance = InpConfluenceDistancePts * _Point;
   for(int i = 0; i < TF_COUNT; ++i)
   {
      if(g_compressions[i].valid && zone.upper >= g_compressions[i].lower - tolerance && zone.lower <= g_compressions[i].upper + tolerance)
         return true;
   }
   return false;
}

int CountZoneConfluence(const ZoneInfo &zone)
{
   if(!zone.valid)
      return 0;

   int count = 0;
   double tolerance = InpConfluenceDistancePts * _Point;
   for(int i = 0; i < TF_COUNT; ++i)
   {
      if(i == zone.timeframe_index)
         continue;
      if(g_support_zones[i].valid && MathAbs(g_support_zones[i].midpoint - zone.midpoint) <= tolerance)
         count++;
      if(g_resistance_zones[i].valid && MathAbs(g_resistance_zones[i].midpoint - zone.midpoint) <= tolerance)
         count++;
   }
   return count;
}

void RefreshZoneScoresAndRendering()
{
   for(int i = 0; i < TF_COUNT; ++i)
   {
      ScoreZone(g_support_zones[i]);
      ScoreZone(g_resistance_zones[i]);
   }

   if(!InpShowZones)
      return;

   for(int i = 0; i < TF_COUNT; ++i)
   {
      DrawZone(i, "SUPPORT", g_support_zones[i]);
      DrawZone(i, "RESISTANCE", g_resistance_zones[i]);
   }
}

void DetectCompression(const int tf_index,
                       const MqlRates &rates[],
                       const int total,
                       const int scan_limit,
                       const double &atr[],
                       CompressionInfo &compression)
{
   ResetCompression(compression);
   int max_index = MathMin(scan_limit, total - InpCompressionBars - 1);

   for(int i = 1; i <= max_index; ++i)
   {
      double upper = rates[i].high;
      double lower = rates[i].low;
      double range_sum = 0.0;
      double atr_sum = 0.0;
      int small_body_count = 0;
      bool narrowing = true;

      for(int j = i; j < i + InpCompressionBars; ++j)
      {
         double range = MathMax(rates[j].high - rates[j].low, _Point);
         double body = MathAbs(rates[j].close - rates[j].open);
         range_sum += range;
         atr_sum += atr[j];
         upper = MathMax(upper, rates[j].high);
         lower = MathMin(lower, rates[j].low);
         if(body / range <= InpSmallBodyRatio)
            small_body_count++;
         if(j > i && range > (rates[j - 1].high - rates[j - 1].low) * 1.20)
            narrowing = false;
      }

      double avg_range = range_sum / InpCompressionBars;
      double avg_atr = atr_sum / InpCompressionBars;
      if(avg_range > avg_atr * InpCompressionATRFactor || !narrowing || small_body_count < InpCompressionBars / 2)
         continue;

      compression.valid = true;
      compression.expanded = false;
      compression.timeframe_index = tf_index;
      compression.upper = upper;
      compression.lower = lower;
      compression.start_time = rates[i + InpCompressionBars - 1].time;
      compression.end_time = rates[0].time + (datetime)(PeriodSeconds(g_timeframes[tf_index]) * InpZoneExtendBars);
      compression.reason = "Compression " + g_tf_names[tf_index] + ": ATR contraction and narrowing ranges";

      for(int k = i - 1; k >= 1; --k)
      {
         double range = rates[k].high - rates[k].low;
         if((rates[k].close > upper || rates[k].close < lower) && range >= atr[k] * InpStrongBodyRatio)
         {
            compression.expanded = true;
            compression.end_time = rates[k].time;
            compression.reason = compression.reason + "; expansion observed";
            break;
         }
      }

      compression.score = ScoreCompression(compression, small_body_count);
      return;
   }
}

int ScoreCompression(const CompressionInfo &compression, const int small_body_count)
{
   int score = InpCompressionBaseScore + g_tf_weights[compression.timeframe_index] + small_body_count * 3;
   if(compression.expanded)
      score += 8;
   return ClampScore(score);
}

// RENDERING LAYER DETAILS
void DrawStructure(const int tf_index, const SwingPoint &swings[], const double &atr[])
{
   int total = ArraySize(swings);
   int first = MathMax(0, total - InpStructureLabelsPerTf);
   for(int i = first; i < total; ++i)
   {
      SwingPoint swing = swings[i];
      double offset = MathMax(atr[swing.index] * 0.20, _Point * 20.0);
      double price = swing.price + (swing.type == SWING_HIGH_TYPE ? offset : -offset);
      ENUM_ANCHOR_POINT anchor = (swing.type == SWING_HIGH_TYPE) ? ANCHOR_LOWER : ANCHOR_UPPER;
      string text = swing.label + " " + g_tf_names[tf_index] + " " + IntegerToString(swing.score);
      string tooltip = "Structure " + g_tf_names[tf_index] + " | " + swing.label + " | Score " + IntegerToString(swing.score) + " | Confirmed swing";
      DrawText("STRUCT_" + g_tf_names[tf_index] + "_" + IntegerToString((int)swing.time), swing.time, price, text, g_tf_colors[tf_index], 8, anchor, tooltip);
   }
}

// MARKET ANALYSIS LAYER - STRUCTURE LINE OBSERVATIONS
void BuildStructureLineObservations(const int tf_index,
                                    const SwingPoint &swings[],
                                    const MqlRates &rates[],
                                    StructureLineObservation &structure_lines[])
{
   ArrayResize(structure_lines, 0);

   SwingPoint first_low;
   SwingPoint second_low;
   SwingPoint first_high;
   SwingPoint second_high;
   bool have_first_low = false;
   bool have_second_low = false;
   bool have_first_high = false;
   bool have_second_high = false;

   for(int i = ArraySize(swings) - 1; i >= 0; --i)
   {
      if(swings[i].type == SWING_LOW_TYPE && (swings[i].label == "HL" || swings[i].label == "LL"))
      {
         if(!have_first_low)
         {
            first_low = swings[i];
            have_first_low = true;
         }
         else if(!have_second_low)
         {
            second_low = swings[i];
            have_second_low = true;
         }
      }

      if(swings[i].type == SWING_HIGH_TYPE && (swings[i].label == "LH" || swings[i].label == "HH"))
      {
         if(!have_first_high)
         {
            first_high = swings[i];
            have_first_high = true;
         }
         else if(!have_second_high)
         {
            second_high = swings[i];
            have_second_high = true;
         }
      }
   }

   if(have_first_low && have_second_low)
   {
      StructureLineObservation line;
      BuildStructureLineObservation(tf_index, second_low, first_low, rates, true, line);
      AppendStructureLineObservation(structure_lines, line);
   }

   if(have_first_high && have_second_high)
   {
      StructureLineObservation line;
      BuildStructureLineObservation(tf_index, second_high, first_high, rates, false, line);
      AppendStructureLineObservation(structure_lines, line);
   }
}

void BuildStructureLineObservation(const int tf_index,
                                   const SwingPoint &older_point,
                                   const SwingPoint &newer_point,
                                   const MqlRates &rates[],
                                   const bool support_line,
                                   StructureLineObservation &line)
{
   ResetStructureLineObservation(line);
   line.valid = true;
   line.support_line = support_line;
   line.first_time = older_point.time;
   line.first_price = older_point.price;
   line.second_time = newer_point.time;
   line.second_price = newer_point.price;
   line.tooltip = (support_line ? "Dynamic support context " : "Dynamic resistance context ") + g_tf_names[tf_index] + " from recent structure observation";
   DetectStructureLineBreak(tf_index, older_point, newer_point, rates, support_line, line);
}

void DetectStructureLineBreak(const int tf_index,
                              const SwingPoint &older_point,
                              const SwingPoint &newer_point,
                              const MqlRates &rates[],
                              const bool support_line,
                              StructureLineObservation &line)
{
   double dt = (double)(newer_point.time - older_point.time);
   if(dt == 0.0)
      return;

   double slope = (newer_point.price - older_point.price) / dt;
   int start_index = MathMin(older_point.index, newer_point.index) - 1;
   for(int i = start_index; i >= 1; --i)
   {
      double projected = older_point.price + slope * (double)(rates[i].time - older_point.time);
      if(support_line && rates[i].close < projected)
      {
         line.broken = true;
         line.break_time = rates[i].time;
         line.break_price = rates[i].close;
         line.break_label = "Structure change " + g_tf_names[tf_index];
         line.break_tooltip = "Dynamic support line observation changed | " + g_tf_names[tf_index];
         return;
      }
      if(!support_line && rates[i].close > projected)
      {
         line.broken = true;
         line.break_time = rates[i].time;
         line.break_price = rates[i].close;
         line.break_label = "Structure change " + g_tf_names[tf_index];
         line.break_tooltip = "Dynamic resistance line observation changed | " + g_tf_names[tf_index];
         return;
      }
   }
}

void AppendStructureLineObservation(StructureLineObservation &structure_lines[], const StructureLineObservation &line)
{
   if(!line.valid)
      return;

   int size = ArraySize(structure_lines);
   ArrayResize(structure_lines, size + 1);
   structure_lines[size] = line;
}

// RENDERING LAYER DETAILS
void RenderStructureLines(const int tf_index, const StructureLineObservation &structure_lines[])
{
   for(int i = 0; i < ArraySize(structure_lines); ++i)
   {
      StructureLineObservation line = structure_lines[i];
      string suffix = (line.support_line ? "DYN_SUP_" : "DYN_RES_") + g_tf_names[tf_index];
      ENUM_LINE_STYLE style = STYLE_SOLID;
      if(!line.support_line)
         style = STYLE_DASH;
      DrawTrend(suffix, line.first_time, line.first_price, line.second_time, line.second_price, g_tf_colors[tf_index], style, line.tooltip);

      if(line.broken)
      {
         string break_suffix = (line.support_line ? "DYN_SUP_BRK_" : "DYN_RES_BRK_") + g_tf_names[tf_index];
         DrawText(break_suffix, line.break_time, line.break_price, line.break_label, InpFlipColor, 8, ANCHOR_CENTER, line.break_tooltip);
      }
   }
}

void DrawZone(const int tf_index, const string slot, const ZoneInfo &zone)
{
   string object_name = g_prefix + "ZONE_" + g_tf_names[tf_index] + "_" + slot;
   string label_name = "ZONE_LABEL_" + g_tf_names[tf_index] + "_" + slot;
   string lifecycle_label_name = "ZONE_STATE_" + g_tf_names[tf_index] + "_" + slot;

   if(!zone.valid)
   {
      ObjectDelete(0, object_name);
      ObjectDelete(0, g_prefix + label_name);
      ObjectDelete(0, g_prefix + lifecycle_label_name);
      return;
   }

   datetime right_time = zone.broken ? zone.end_time : TimeCurrent() + (datetime)(PeriodSeconds(g_timeframes[tf_index]) * InpZoneExtendBars);
   color zone_color = zone.flipped ? InpFlipColor : ((zone.zone_type == ZONE_SUPPORT_TYPE) ? InpSupportColor : InpResistanceColor);
   string tooltip = BuildZoneTooltip(zone);
   UpsertRectangle(object_name, zone.start_time, zone.upper, right_time, zone.lower, BlendTimeframeColor(zone_color, g_tf_colors[tf_index]), true, true, ZoneStyleByScore(zone.score), ZoneWidthByScore(zone.score), tooltip);

   string text = ZoneName(zone.zone_type) + " " + g_tf_names[tf_index] + " activity " + IntegerToString(zone.score);
   DrawText(label_name, zone.start_time, zone.midpoint, text, g_tf_colors[tf_index], 8, ANCHOR_CENTER, tooltip);

   if(zone.broken)
      DrawText(lifecycle_label_name, zone.break_time, zone.midpoint, "State change " + g_tf_names[tf_index] + " " + IntegerToString(zone.score), InpFlipColor, 8, ANCHOR_CENTER, tooltip);
   else
      ObjectDelete(0, g_prefix + lifecycle_label_name);
}

string BuildZoneTooltip(const ZoneInfo &zone)
{
   return zone.what + "\n" +
          zone.why + "\n" +
          zone.impact + "\n" +
          "Lifecycle: " + zone.lifecycle_state + ".\n" +
          "Interactions: " + IntegerToString(zone.interaction_observations) +
          "; response observations: " + IntegerToString(zone.response_observations) +
          "; pressure observations: " + IntegerToString(zone.pressure_observations) + ".\n" +
          zone.score_details;
}

void DrawCompression(const CompressionInfo &compression)
{
   int tf_index = compression.timeframe_index;
   string object_name = g_prefix + "COMPRESSION_" + g_tf_names[tf_index];
   string label_name = "COMPRESSION_LABEL_" + g_tf_names[tf_index];

   if(!compression.valid)
   {
      ObjectDelete(0, object_name);
      ObjectDelete(0, g_prefix + label_name);
      return;
   }

   string tooltip = compression.reason + " | Score " + IntegerToString(compression.score);
   UpsertRectangle(object_name, compression.start_time, compression.upper, compression.end_time, compression.lower, InpCompressionColor, true, true, STYLE_DOT, ZoneWidthByScore(compression.score), tooltip);
   DrawText(label_name, compression.start_time, (compression.upper + compression.lower) / 2.0, "Compression " + g_tf_names[tf_index] + " " + IntegerToString(compression.score), g_tf_colors[tf_index], 8, ANCHOR_CENTER, tooltip);
}

void BuildImportantCandles(const int tf_index,
                          const MqlRates &rates[],
                          const int total,
                          const int scan_limit,
                          const double &atr[],
                          CandleMark &candle_marks[])
{
   ArrayResize(candle_marks, 0);
   int marks = 0;
   int limit = MathMin(scan_limit, 90);
   for(int i = 1; i <= limit && marks < InpImportantCandlesMax; ++i)
   {
      CandleMark mark;
      ResetCandleMark(mark);
      AnalyzeCandle(tf_index, i, rates, total, atr, mark);
      if(!mark.valid)
         continue;

      AppendCandleMark(candle_marks, mark);
      marks++;
   }
}

void AppendCandleMark(CandleMark &candle_marks[], const CandleMark &mark)
{
   int size = ArraySize(candle_marks);
   ArrayResize(candle_marks, size + 1);
   candle_marks[size] = mark;
}

void RenderImportantCandles(const int tf_index, const CandleMark &candle_marks[])
{
   for(int i = 0; i < ArraySize(candle_marks); ++i)
   {
      CandleMark mark = candle_marks[i];
      string suffix = "CANDLE_" + g_tf_names[tf_index] + "_" + IntegerToString((int)mark.time);
      string text = mark.label + " " + g_tf_names[tf_index] + " " + IntegerToString(mark.score);
      DrawText(suffix, mark.time, mark.price, text, mark.mark_color, 8, ANCHOR_CENTER, mark.reason);
   }
}

void AnalyzeCandle(const int tf_index,
                   const int index,
                   const MqlRates &rates[],
                   const int total,
                   const double &atr[],
                   CandleMark &mark)
{
   ResetCandleMark(mark);
   if(index + 4 >= total)
      return;
   if(!IsNearRelevantArea(rates[index].close, atr[index]))
      return;

   double range = MathMax(rates[index].high - rates[index].low, _Point);
   double body = MathAbs(rates[index].close - rates[index].open);
   double body_ratio = body / range;
   double upper_wick_ratio = (rates[index].high - MathMax(rates[index].open, rates[index].close)) / range;
   double lower_wick_ratio = (MathMin(rates[index].open, rates[index].close) - rates[index].low) / range;
   double wick_body_ratio = MathMax(upper_wick_ratio, lower_wick_ratio) / MathMax(body_ratio, 0.05);

   bool rejection = (upper_wick_ratio >= InpExtendedWickRatio || lower_wick_ratio >= InpExtendedWickRatio);
   bool strong_impulse = (body_ratio >= InpStrongBodyRatio && range >= atr[index] * 0.80);
   bool small_body = (body_ratio <= InpSmallBodyRatio && HasDirectionalPush(index, rates));
   bool tightening = IsTightening(index, rates);
   bool slowdown = IsMomentumSlowdown(index, rates);
   bool nearby_tightening = tightening && IsNearRelevantArea(rates[index].close, atr[index] * 0.5);

   if(!rejection && !strong_impulse && !small_body && !tightening && !slowdown && !nearby_tightening)
      return;

   int score = InpCandleBaseScore + g_tf_weights[tf_index];
   string label = "Candle";
   string reason = "Candle " + g_tf_names[tf_index] + ": ";
   color mark_color = InpImportantColor;
   double y = rates[index].high + MathMax(atr[index] * 0.18, _Point * 20.0);

   if(rejection)
   {
      score += (int)MathMin(28.0, wick_body_ratio * 5.0);
      label = "Rejection";
      reason += "large wick rejection";
      mark_color = (lower_wick_ratio > upper_wick_ratio) ? InpSupportColor : InpResistanceColor;
      if(lower_wick_ratio > upper_wick_ratio)
         y = rates[index].low - MathMax(atr[index] * 0.18, _Point * 20.0);
   }
   else if(strong_impulse)
   {
      score += 18;
      label = "Impulse";
      reason += "strong body expansion";
   }
   else if(small_body)
   {
      score += 16;
      label = "Small body";
      reason += "small body after directional push";
   }
   else if(slowdown)
   {
      score += 14;
      label = "Slowdown";
      reason += "momentum slowdown";
   }
   else if(nearby_tightening)
   {
      score += 12;
      label = "Tightening near zone";
      reason += "range contraction near observed zone";
   }
   else if(tightening)
   {
      score += 10;
      label = "Tightening";
      reason += "range contraction";
   }

   mark.valid = true;
   mark.score = ClampScore(score);
   mark.price = y;
   mark.time = rates[index].time;
   mark.label = label;
   mark.reason = reason + " | Score " + IntegerToString(mark.score);
   mark.mark_color = mark_color;
}

bool HasDirectionalPush(const int index, const MqlRates &rates[])
{
   int direction = 0;
   int count = 0;
   for(int i = index + 1; i <= index + 3; ++i)
   {
      double range = MathMax(rates[i].high - rates[i].low, _Point);
      double body_ratio = MathAbs(rates[i].close - rates[i].open) / range;
      int candle_direction = rates[i].close > rates[i].open ? 1 : (rates[i].close < rates[i].open ? -1 : 0);
      if(body_ratio >= InpStrongBodyRatio && candle_direction != 0)
      {
         if(direction == 0)
            direction = candle_direction;
         if(direction == candle_direction)
            count++;
      }
   }
   return count >= 2;
}

bool IsTightening(const int index, const MqlRates &rates[])
{
   double r0 = rates[index].high - rates[index].low;
   double r1 = rates[index + 1].high - rates[index + 1].low;
   double r2 = rates[index + 2].high - rates[index + 2].low;
   return (r0 < r1 && r1 < r2);
}

bool IsMomentumSlowdown(const int index, const MqlRates &rates[])
{
   double b0 = MathAbs(rates[index].close - rates[index].open);
   double b1 = MathAbs(rates[index + 1].close - rates[index + 1].open);
   double b2 = MathAbs(rates[index + 2].close - rates[index + 2].open);
   return (b0 < b1 && b1 < b2 && IsTightening(index, rates));
}

bool IsNearRelevantArea(const double price, const double tolerance)
{
   double t = MathMax(tolerance, _Point * 20.0);
   for(int i = 0; i < TF_COUNT; ++i)
   {
      if(IsNearZone(price, t, g_support_zones[i]))
         return true;
      if(IsNearZone(price, t, g_resistance_zones[i]))
         return true;
      if(g_compressions[i].valid && price >= g_compressions[i].lower - t && price <= g_compressions[i].upper + t)
         return true;
   }
   return false;
}

bool IsNearZone(const double price, const double tolerance, const ZoneInfo &zone)
{
   if(!zone.valid)
      return false;
   return (price >= zone.lower - tolerance && price <= zone.upper + tolerance);
}

void DrawConfluenceAreas()
{
   DeleteObjectGroup("CONFLUENCE_");
   int group_id = 0;
   for(int i = 0; i < TF_COUNT; ++i)
   {
      DrawZoneConfluence(group_id, g_support_zones[i]);
      DrawZoneConfluence(group_id, g_resistance_zones[i]);
   }
}

void DrawZoneConfluence(int &group_id, const ZoneInfo &base_zone)
{
   if(!base_zone.valid)
      return;

   int confluence_count = CountZoneConfluence(base_zone);
   if(confluence_count <= 0 || base_zone.score < InpHighScoreThreshold)
      return;

   double upper = base_zone.upper;
   double lower = base_zone.lower;
   for(int i = 0; i < TF_COUNT; ++i)
   {
      ExpandConfluenceBounds(base_zone, g_support_zones[i], upper, lower);
      ExpandConfluenceBounds(base_zone, g_resistance_zones[i], upper, lower);
   }

   string name = g_prefix + "CONFLUENCE_" + IntegerToString(group_id);
   string label = "CONFLUENCE_LABEL_" + IntegerToString(group_id);
   datetime right_time = TimeCurrent() + (datetime)(PeriodSeconds(_Period) * InpZoneExtendBars);
   string tooltip = "Confluence observation | Activity score " + IntegerToString(base_zone.score) + " | Overlapping observations " + IntegerToString(confluence_count) + " | visual priority only";
   UpsertRectangle(name, TimeCurrent() - (datetime)(PeriodSeconds(_Period) * 20), upper, right_time, lower, InpImportantColor, true, true, STYLE_DASHDOT, 2, tooltip);
   DrawText(label, TimeCurrent(), (upper + lower) / 2.0, "Confluence observation " + IntegerToString(base_zone.score), InpImportantColor, 8, ANCHOR_CENTER, tooltip);
   group_id++;
}

void ExpandConfluenceBounds(const ZoneInfo &base_zone, const ZoneInfo &candidate, double &upper, double &lower)
{
   if(!candidate.valid || candidate.timeframe_index == base_zone.timeframe_index)
      return;
   double tolerance = InpConfluenceDistancePts * _Point;
   if(MathAbs(candidate.midpoint - base_zone.midpoint) <= tolerance)
   {
      upper = MathMax(upper, candidate.upper);
      lower = MathMin(lower, candidate.lower);
   }
}

// CONTEXT LAYER
void DrawDashboard()
{
   if(!InpShowContextPanel)
      return;

   int up_score = 0;
   int down_score = 0;
   string rows = "TDSS v2 Context\n";
   for(int i = 0; i < TF_COUNT; ++i)
   {
      string state = "Neutral";
      if(g_context_states[i] == CONTEXT_UP)
      {
         state = "Bullish";
         up_score += g_tf_weights[i];
      }
      else if(g_context_states[i] == CONTEXT_DOWN)
      {
         state = "Bearish";
         down_score += g_tf_weights[i];
      }
      rows += g_tf_names[i] + ": " + state + "\n";
   }

   string headline = "Neutral context";
   color panel_color = InpPanelColor;
   if(up_score > down_score && up_score >= InpM15Weight)
   {
      headline = "Bullish context";
      panel_color = InpSupportColor;
   }
   else if(down_score > up_score && down_score >= InpM15Weight)
   {
      headline = "Bearish context";
      panel_color = InpResistanceColor;
   }

   rows += "Context score: " + IntegerToString(MathMax(up_score, down_score)) + "\n";
   rows += "Mode: market observation only";
   DrawPanel("DASHBOARD", 12, 18, headline + "\n" + rows, panel_color);
}

void ResetZone(ZoneInfo &zone)
{
   zone.valid = false;
   zone.broken = false;
   zone.flipped = false;
   zone.zone_type = 0;
   zone.timeframe_index = 0;
   zone.source_index = -1;
   zone.retests = 0;
   zone.interaction_observations = 0;
   zone.response_observations = 0;
   zone.pressure_observations = 0;
   zone.confluence_observations = 0;
   zone.score = 0;
   zone.structural_score = 0;
   zone.interaction_score = 0;
   zone.freshness_score = 0;
   zone.response_score = 0;
   zone.pressure_adjustment = 0;
   zone.confluence_score = 0;
   zone.compression_score = 0;
   zone.upper = 0.0;
   zone.lower = 0.0;
   zone.midpoint = 0.0;
   zone.start_time = 0;
   zone.end_time = 0;
   zone.break_time = 0;
   zone.last_interaction_time = 0;
   zone.identity = "";
   zone.lifecycle_state = "";
   zone.reason = "";
   zone.what = "";
   zone.why = "";
   zone.impact = "";
   zone.score_details = "";
}

void ResetCompression(CompressionInfo &compression)
{
   compression.valid = false;
   compression.expanded = false;
   compression.timeframe_index = 0;
   compression.score = 0;
   compression.upper = 0.0;
   compression.lower = 0.0;
   compression.start_time = 0;
   compression.end_time = 0;
   compression.reason = "";
}

void ResetCandleMark(CandleMark &mark)
{
   mark.valid = false;
   mark.score = 0;
   mark.price = 0.0;
   mark.time = 0;
   mark.label = "";
   mark.reason = "";
   mark.mark_color = InpImportantColor;
}

void ResetStructureLineObservation(StructureLineObservation &line)
{
   line.valid = false;
   line.support_line = false;
   line.broken = false;
   line.first_time = 0;
   line.first_price = 0.0;
   line.second_time = 0;
   line.second_price = 0.0;
   line.break_time = 0;
   line.break_price = 0.0;
   line.tooltip = "";
   line.break_label = "";
   line.break_tooltip = "";
}

int ClampScore(const int value)
{
   return MathMax(0, MathMin(100, value));
}

int ZoneWidthByScore(const int score)
{
   if(score >= 85)
      return 3;
   if(score >= InpHighScoreThreshold)
      return 2;
   return 1;
}

ENUM_LINE_STYLE ZoneStyleByScore(const int score)
{
   if(score >= InpHighScoreThreshold)
      return STYLE_SOLID;
   if(score >= 45)
      return STYLE_DASH;
   return STYLE_DOT;
}

string ZoneName(const int zone_type)
{
   if(zone_type == ZONE_SUPPORT_TYPE)
      return "Support";
   if(zone_type == ZONE_RESISTANCE_TYPE)
      return "Resistance";
   return "Zone";
}

color TransparentColor(const color base_color)
{
   int alpha = MathMax(0, MathMin(255, InpFillAlpha));
   return (color)ColorToARGB(base_color, (uchar)alpha);
}

color BlendTimeframeColor(const color base_color, const color timeframe_color)
{
   int base_value = (int)base_color;
   int tf_value = (int)timeframe_color;
   int r = ((base_value & 0x0000FF) + (tf_value & 0x0000FF)) / 2;
   int g = (((base_value >> 8) & 0x0000FF) + ((tf_value >> 8) & 0x0000FF)) / 2;
   int b = (((base_value >> 16) & 0x0000FF) + ((tf_value >> 16) & 0x0000FF)) / 2;
   return (color)((b << 16) | (g << 8) | r);
}

void UpsertRectangle(const string name,
                     const datetime left_time,
                     const double upper_price,
                     const datetime right_time,
                     const double lower_price,
                     const color rectangle_color,
                     const bool fill,
                     const bool back,
                     const ENUM_LINE_STYLE style,
                     const int width,
                     const string tooltip)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, left_time, upper_price, right_time, lower_price);
   else
   {
      ObjectMove(0, name, 0, left_time, upper_price);
      ObjectMove(0, name, 1, right_time, lower_price);
   }

   ObjectSetInteger(0, name, OBJPROP_COLOR, TransparentColor(rectangle_color));
   ObjectSetInteger(0, name, OBJPROP_FILL, fill);
   ObjectSetInteger(0, name, OBJPROP_BACK, back);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
}

void DrawText(const string suffix,
              const datetime object_time,
              const double price,
              const string text,
              const color text_color,
              const int font_size,
              const ENUM_ANCHOR_POINT anchor,
              const string tooltip)
{
   string name = g_prefix + suffix;
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TEXT, 0, object_time, price);
   else
      ObjectMove(0, name, 0, object_time, price);

   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
   ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
}

void DrawTrend(const string suffix,
               const datetime first_time,
               const double first_price,
               const datetime second_time,
               const double second_price,
               const color line_color,
               const ENUM_LINE_STYLE style,
               const string tooltip)
{
   string name = g_prefix + suffix;
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, first_time, first_price, second_time, second_price);
   else
   {
      ObjectMove(0, name, 0, first_time, first_price);
      ObjectMove(0, name, 1, second_time, second_price);
   }

   ObjectSetInteger(0, name, OBJPROP_COLOR, line_color);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
}

void DrawPanel(const string suffix, const int x, const int y, const string text, const color text_color)
{
   string name = g_prefix + suffix;
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, "Context panel | timeframe observation | no action instruction");
}

void DeleteTransientObjects()
{
   DeleteObjectGroup("STRUCT_");
   DeleteObjectGroup("DYN_SUP_");
   DeleteObjectGroup("DYN_RES_");
   DeleteObjectGroup("DYN_SUP_BRK_");
   DeleteObjectGroup("DYN_RES_BRK_");
   DeleteObjectGroup("CANDLE_");
   DeleteObjectGroup("CONFLUENCE_");
   DeleteObjectGroup("CONFLUENCE_LABEL_");
}

void DeleteObjectGroup(const string group_name)
{
   DeleteObjectsByPrefix(g_prefix + group_name);
}

void DeleteObjectsByPrefix(const string object_prefix)
{
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; --i)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, object_prefix) == 0)
         ObjectDelete(0, name);
   }
}

void DeleteAllTDSSObjects()
{
   DeleteObjectsByPrefix(g_prefix);
}
