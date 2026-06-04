#property copyright "SOT TDSS"
#property link      ""
#property version   "3.00"
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
input double InpLongWickRatio           = 0.55;
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
input int    InpRetestScoreWeight       = 6;
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

#define TDSS_PREFIX "SOT_TDSS_"
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
   int      score;
   double   upper;
   double   lower;
   double   midpoint;
   datetime start_time;
   datetime end_time;
   datetime break_time;
   string   reason;
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

string          g_prefix = "";
datetime        g_last_closed_bar_time = 0;
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
   }

   IndicatorSetString(INDICATOR_SHORTNAME, "SOT TDSS Visual Market Structure");
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
   ArraySetAsSeries(rates, true);
   ArraySetAsSeries(atr, true);

   int bars_needed = MathMax(InpBarsPerTimeframe, RequiredBars());
   int copied_rates = CopyRates(_Symbol, g_timeframes[tf_index], 0, bars_needed, rates);
   if(copied_rates < RequiredBars())
      return;

   int copied_atr = CopyBuffer(g_atr_handles[tf_index], 0, 0, copied_rates, atr);
   if(copied_atr < RequiredBars())
      return;

   int scan_limit = MathMin(copied_rates - InpSwingConfirmBars - 2, InpBarsPerTimeframe - InpSwingConfirmBars - 2);
   if(scan_limit <= InpSwingConfirmBars + 2)
      return;

   SwingPoint swings[];
   ArrayResize(swings, 0);
   BuildSwings(tf_index, rates, copied_rates, scan_limit, atr, swings);
   g_context_states[tf_index] = ClassifyStructureContext(swings);

   if(InpShowStructureLabels)
      DrawStructure(tf_index, swings, atr);

   BuildLatestZones(tf_index, rates, copied_rates, scan_limit, atr, g_support_zones[tf_index], g_resistance_zones[tf_index]);

   if(InpShowStructureLines)
      DrawDynamicStructureLines(tf_index, swings, rates);

   DetectCompression(tf_index, rates, copied_rates, scan_limit, atr, g_compressions[tf_index]);
   if(InpShowCompression)
      DrawCompression(g_compressions[tf_index]);

   if(InpShowCandles && tf_index <= 2)
      DrawImportantCandles(tf_index, rates, copied_rates, scan_limit, atr);
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

void BuildLatestZones(const int tf_index,
                      const MqlRates &rates[],
                      const int total,
                      const int scan_limit,
                      const double &atr[],
                      ZoneInfo &support_zone,
                      ZoneInfo &resistance_zone)
{
   ResetZone(support_zone);
   ResetZone(resistance_zone);
   bool support_found = false;
   bool resistance_found = false;

   for(int i = InpSwingConfirmBars + 1; i <= scan_limit; ++i)
   {
      if(!support_found && IsConfirmedSwingLow(rates, total, i))
      {
         CreateZone(tf_index, ZONE_SUPPORT_TYPE, i, rates, rates[i].low, atr[i], support_zone);
         EvaluateZoneBehavior(support_zone, rates, atr);
         support_found = true;
      }

      if(!resistance_found && IsConfirmedSwingHigh(rates, total, i))
      {
         CreateZone(tf_index, ZONE_RESISTANCE_TYPE, i, rates, rates[i].high, atr[i], resistance_zone);
         EvaluateZoneBehavior(resistance_zone, rates, atr);
         resistance_found = true;
      }

      if(support_found && resistance_found)
         break;
   }
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
   zone.score = 0;
   zone.upper = midpoint + width;
   zone.lower = midpoint - width;
   zone.midpoint = midpoint;
   zone.start_time = rates[source_index].time;
   zone.end_time = 0;
   zone.break_time = 0;
   zone.reason = ZoneName(zone_type) + " " + g_tf_names[tf_index] + " from confirmed swing";
}

void EvaluateZoneBehavior(ZoneInfo &zone, const MqlRates &rates[], const double &atr[])
{
   if(!zone.valid)
      return;

   double break_buffer = MathMax(atr[zone.source_index] * InpZoneATRBuffer, _Point * 20.0);
   for(int i = zone.source_index - 1; i >= 1; --i)
   {
      bool touched = (rates[i].high >= zone.lower && rates[i].low <= zone.upper);
      if(touched)
         zone.retests++;

      if(zone.zone_type == ZONE_SUPPORT_TYPE && rates[i].close < zone.lower - break_buffer)
      {
         zone.broken = true;
         zone.flipped = true;
         zone.break_time = rates[i].time;
         zone.end_time = rates[i].time;
         zone.reason = zone.reason + "; clean break; flipped context";
         return;
      }

      if(zone.zone_type == ZONE_RESISTANCE_TYPE && rates[i].close > zone.upper + break_buffer)
      {
         zone.broken = true;
         zone.flipped = true;
         zone.break_time = rates[i].time;
         zone.end_time = rates[i].time;
         zone.reason = zone.reason + "; clean break; flipped context";
         return;
      }
   }
}

void ScoreZone(ZoneInfo &zone)
{
   if(!zone.valid)
      return;

   int score = 35 + g_tf_weights[zone.timeframe_index];
   score += MathMin(24, zone.retests * InpRetestScoreWeight);
   score += MathMax(0, InpRecencyScoreWeight - zone.source_index / 10);
   score += CountZoneConfluence(zone) * InpConfluenceScoreWeight;
   if(zone.flipped)
      score -= 10;
   zone.score = ClampScore(score);
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

void DrawDynamicStructureLines(const int tf_index, const SwingPoint &swings[], const MqlRates &rates[])
{
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
      string tooltip = "Dynamic support context " + g_tf_names[tf_index] + " from recent low structure";
      DrawTrend("DYN_SUP_" + g_tf_names[tf_index], second_low.time, second_low.price, first_low.time, first_low.price, g_tf_colors[tf_index], STYLE_SOLID, tooltip);
      MarkLineBreak(tf_index, "DYN_SUP_BRK_", second_low, first_low, rates, true);
   }

   if(have_first_high && have_second_high)
   {
      string tooltip = "Dynamic resistance context " + g_tf_names[tf_index] + " from recent high structure";
      DrawTrend("DYN_RES_" + g_tf_names[tf_index], second_high.time, second_high.price, first_high.time, first_high.price, g_tf_colors[tf_index], STYLE_DASH, tooltip);
      MarkLineBreak(tf_index, "DYN_RES_BRK_", second_high, first_high, rates, false);
   }
}

void MarkLineBreak(const int tf_index,
                   const string prefix,
                   const SwingPoint &older_point,
                   const SwingPoint &newer_point,
                   const MqlRates &rates[],
                   const bool support_line)
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
         DrawText(prefix + g_tf_names[tf_index], rates[i].time, rates[i].close, "Structure change " + g_tf_names[tf_index], InpFlipColor, 8, ANCHOR_CENTER, "Dynamic support line broken | " + g_tf_names[tf_index]);
         return;
      }
      if(!support_line && rates[i].close > projected)
      {
         DrawText(prefix + g_tf_names[tf_index], rates[i].time, rates[i].close, "Structure change " + g_tf_names[tf_index], InpFlipColor, 8, ANCHOR_CENTER, "Dynamic resistance line broken | " + g_tf_names[tf_index]);
         return;
      }
   }
}

void DrawZone(const int tf_index, const string slot, const ZoneInfo &zone)
{
   string object_name = g_prefix + "ZONE_" + g_tf_names[tf_index] + "_" + slot;
   string label_name = "ZONE_LABEL_" + g_tf_names[tf_index] + "_" + slot;

   if(!zone.valid)
   {
      ObjectDelete(0, object_name);
      ObjectDelete(0, g_prefix + label_name);
      return;
   }

   datetime right_time = zone.broken ? zone.end_time : TimeCurrent() + (datetime)(PeriodSeconds(g_timeframes[tf_index]) * InpZoneExtendBars);
   color zone_color = zone.flipped ? InpFlipColor : ((zone.zone_type == ZONE_SUPPORT_TYPE) ? InpSupportColor : InpResistanceColor);
   string tooltip = zone.reason + " | Score " + IntegerToString(zone.score) + " | Retests " + IntegerToString(zone.retests);
   UpsertRectangle(object_name, zone.start_time, zone.upper, right_time, zone.lower, BlendTimeframeColor(zone_color, g_tf_colors[tf_index]), true, true, STYLE_SOLID, ZoneWidthByScore(zone.score), tooltip);

   string text = ZoneName(zone.zone_type) + " " + g_tf_names[tf_index] + " " + IntegerToString(zone.score);
   DrawText(label_name, zone.start_time, zone.midpoint, text, g_tf_colors[tf_index], 8, ANCHOR_CENTER, tooltip);

   if(zone.broken)
      DrawText("ZONE_FLIP_" + g_tf_names[tf_index] + "_" + slot, zone.break_time, zone.midpoint, "Flip " + g_tf_names[tf_index] + " " + IntegerToString(zone.score), InpFlipColor, 8, ANCHOR_CENTER, tooltip);
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

void DrawImportantCandles(const int tf_index,
                          const MqlRates &rates[],
                          const int total,
                          const int scan_limit,
                          const double &atr[])
{
   int marks = 0;
   int limit = MathMin(scan_limit, 90);
   for(int i = 1; i <= limit && marks < InpImportantCandlesMax; ++i)
   {
      CandleMark mark;
      ResetCandleMark(mark);
      AnalyzeCandle(tf_index, i, rates, total, atr, mark);
      if(!mark.valid)
         continue;

      string suffix = "CANDLE_" + g_tf_names[tf_index] + "_" + IntegerToString((int)mark.time);
      string text = mark.label + " " + g_tf_names[tf_index] + " " + IntegerToString(mark.score);
      DrawText(suffix, mark.time, mark.price, text, mark.mark_color, 8, ANCHOR_CENTER, mark.reason);
      marks++;
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

   bool rejection = (upper_wick_ratio >= InpLongWickRatio || lower_wick_ratio >= InpLongWickRatio);
   bool strong_impulse = (body_ratio >= InpStrongBodyRatio && range >= atr[index] * 0.80);
   bool small_body = (body_ratio <= InpSmallBodyRatio && HasDirectionalPush(index, rates));
   bool tightening = IsTightening(index, rates);
   bool slowdown = IsMomentumSlowdown(index, rates);
   bool pre_break = tightening && IsNearRelevantArea(rates[index].close, atr[index] * 0.5);

   if(!rejection && !strong_impulse && !small_body && !tightening && !slowdown && !pre_break)
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
   else if(pre_break)
   {
      score += 12;
      label = "Pre-break";
      reason += "tightening near active zone";
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
   string tooltip = "High confluence area | Score " + IntegerToString(base_zone.score) + " | Overlaps " + IntegerToString(confluence_count);
   UpsertRectangle(name, TimeCurrent() - (datetime)(PeriodSeconds(_Period) * 20), upper, right_time, lower, InpImportantColor, true, true, STYLE_DASHDOT, 2, tooltip);
   DrawText(label, TimeCurrent(), (upper + lower) / 2.0, "Confluence " + IntegerToString(base_zone.score), InpImportantColor, 8, ANCHOR_CENTER, tooltip);
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

void DrawDashboard()
{
   if(!InpShowContextPanel)
      return;

   int up_score = 0;
   int down_score = 0;
   string rows = "SOT TDSS Context\n";
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
   rows += "Mode: visual ranking only";
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
   zone.score = 0;
   zone.upper = 0.0;
   zone.lower = 0.0;
   zone.midpoint = 0.0;
   zone.start_time = 0;
   zone.end_time = 0;
   zone.break_time = 0;
   zone.reason = "";
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
   ObjectSetString(0, name, OBJPROP_TOOLTIP, "Context panel | timeframe alignment | visual ranking only");
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
   string object_prefix = g_prefix + group_name;
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
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; --i)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, g_prefix) == 0)
         ObjectDelete(0, name);
   }
}
