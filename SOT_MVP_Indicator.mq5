#property copyright "SOT MVP"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_plots 0

input int    InpSwingLookback      = 3;
input int    InpMaxBarsToScan      = 300;
input int    InpMaxZones           = 12;
input int    InpZoneExtendBars     = 120;
input int    InpATRPeriod          = 14;
input double InpZoneATRBuffer      = 0.25;
input int    InpCompressionBars    = 6;
input double InpCompressionFactor  = 0.70;
input double InpLargeBodyRatio     = 0.60;
input double InpSmallBodyRatio     = 0.30;
input double InpLongWickRatio      = 0.50;
input bool   InpShowStructureLines = true;
input color  InpBullishColor       = clrMediumSeaGreen;
input color  InpBearishColor       = clrTomato;
input color  InpSupportColor       = clrSeaGreen;
input color  InpResistanceColor    = clrIndianRed;
input color  InpFlippedColor       = clrDarkOrange;
input color  InpCompressionColor   = clrSlateGray;
input color  InpImportantColor     = clrGold;
input color  InpContextColor       = clrWhite;
input int    InpFillAlpha          = 45;

#define SOT_PREFIX "SOT_MVP_"
#define ZONE_SUPPORT 1
#define ZONE_RESISTANCE 2
#define CONTEXT_BULLISH 1
#define CONTEXT_BEARISH -1
#define CONTEXT_NEUTRAL 0

struct VisualZone
{
   int      type;
   double   upper;
   double   lower;
   double   midpoint;
   int      touches;
   bool     flipped;
   datetime start_time;
   datetime break_time;
};

int    g_atr_handle = INVALID_HANDLE;
string g_prefix;

int OnInit()
{
   g_prefix = SOT_PREFIX + IntegerToString((int)ChartID()) + "_";
   g_atr_handle = iATR(_Symbol, _Period, InpATRPeriod);
   if(g_atr_handle == INVALID_HANDLE)
      return INIT_FAILED;

   IndicatorSetString(INDICATOR_SHORTNAME, "SOT MVP Market Reading");
   DrawContextLabel("Context: loading");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   DeleteSOTObjects();
   if(g_atr_handle != INVALID_HANDLE)
      IndicatorRelease(g_atr_handle);
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

   double atr[];
   ArraySetAsSeries(atr, true);
   int copied = CopyBuffer(g_atr_handle, 0, 0, rates_total, atr);
   if(copied <= InpATRPeriod)
      return prev_calculated;

   DeleteSOTObjects();

   int scan_limit = MathMin(InpMaxBarsToScan, rates_total - InpSwingLookback - 2);
   VisualZone zones[];
   ArrayResize(zones, 0);

   DetectAndDrawStructure(rates_total, scan_limit, time, open, high, low, close, atr, zones);
   DrawZones(zones, time[0]);
   DetectAndDrawCompression(rates_total, scan_limit, time, open, high, low, close, atr);
   DetectAndDrawImportantCandles(rates_total, scan_limit, time, open, high, low, close, atr, zones);
   UpdateMultiTimeframeContext();

   ChartRedraw(0);
   return rates_total;
}

int RequiredBars()
{
   int value = InpATRPeriod + InpCompressionBars + InpSwingLookback * 2 + 10;
   return MathMax(value, 80);
}

void DeleteSOTObjects()
{
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; --i)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, g_prefix) == 0)
         ObjectDelete(0, name);
   }
}

color AlphaColor(const color base_color)
{
   int alpha = MathMax(0, MathMin(255, InpFillAlpha));
   return (color)ColorToARGB(base_color, (uchar)alpha);
}

bool IsSwingHigh(const int index, const int rates_total, const double &high[])
{
   if(index < InpSwingLookback || index + InpSwingLookback >= rates_total)
      return false;

   for(int offset = 1; offset <= InpSwingLookback; ++offset)
   {
      if(high[index] <= high[index - offset])
         return false;
      if(high[index] <= high[index + offset])
         return false;
   }
   return true;
}

bool IsSwingLow(const int index, const int rates_total, const double &low[])
{
   if(index < InpSwingLookback || index + InpSwingLookback >= rates_total)
      return false;

   for(int offset = 1; offset <= InpSwingLookback; ++offset)
   {
      if(low[index] >= low[index - offset])
         return false;
      if(low[index] >= low[index + offset])
         return false;
   }
   return true;
}

void DetectAndDrawStructure(const int rates_total,
                            const int scan_limit,
                            const datetime &time[],
                            const double &open[],
                            const double &high[],
                            const double &low[],
                            const double &close[],
                            const double &atr[],
                            VisualZone &zones[])
{
   double last_high = 0.0;
   double last_low = 0.0;
   datetime last_swing_time = 0;
   double last_swing_price = 0.0;
   int zone_count = 0;

   for(int i = scan_limit; i >= InpSwingLookback; --i)
   {
      bool swing_high = IsSwingHigh(i, rates_total, high);
      bool swing_low = IsSwingLow(i, rates_total, low);

      if(swing_high)
      {
         string label = (last_high <= 0.0 || high[i] > last_high) ? "HH" : "LH";
         color text_color = (label == "HH") ? InpBullishColor : InpBearishColor;
         DrawTextAtBar("MS_" + label + "_" + IntegerToString((int)time[i]), time[i], high[i] + atr[i] * 0.25, label, text_color, 8, ANCHOR_LOWER);
         DrawStructureLine(last_swing_time, last_swing_price, time[i], high[i], text_color);
         last_swing_time = time[i];
         last_swing_price = high[i];
         last_high = high[i];

         if(zone_count < InpMaxZones)
         {
            AddZone(zones, ZONE_RESISTANCE, high[i], atr[i], time[i], time, high, low, close, i);
            zone_count++;
         }
      }

      if(swing_low)
      {
         string label = (last_low <= 0.0 || low[i] > last_low) ? "HL" : "LL";
         color text_color = (label == "HL") ? InpBullishColor : InpBearishColor;
         DrawTextAtBar("MS_" + label + "_" + IntegerToString((int)time[i]), time[i], low[i] - atr[i] * 0.25, label, text_color, 8, ANCHOR_UPPER);
         DrawStructureLine(last_swing_time, last_swing_price, time[i], low[i], text_color);
         last_swing_time = time[i];
         last_swing_price = low[i];
         last_low = low[i];

         if(zone_count < InpMaxZones)
         {
            AddZone(zones, ZONE_SUPPORT, low[i], atr[i], time[i], time, high, low, close, i);
            zone_count++;
         }
      }
   }
}

void AddZone(VisualZone &zones[],
             const int zone_type,
             const double midpoint,
             const double atr_value,
             const datetime start_time,
             const datetime &time[],
             const double &high[],
             const double &low[],
             const double &close[],
             const int source_index)
{
   double width = MathMax(atr_value * InpZoneATRBuffer, _Point * 10.0);
   VisualZone zone;
   zone.type = zone_type;
   zone.upper = midpoint + width;
   zone.lower = midpoint - width;
   zone.midpoint = midpoint;
   zone.touches = 0;
   zone.flipped = false;
   zone.start_time = start_time;
   zone.break_time = 0;

   for(int i = source_index - 1; i >= 0; --i)
   {
      bool touched = (high[i] >= zone.lower && low[i] <= zone.upper);
      if(touched)
         zone.touches++;

      if(zone.type == ZONE_SUPPORT && close[i] < zone.lower - width)
      {
         zone.type = ZONE_RESISTANCE;
         zone.flipped = true;
         zone.break_time = time[i];
         zone.touches = 0;
      }
      else if(zone.type == ZONE_RESISTANCE && close[i] > zone.upper + width)
      {
         zone.type = ZONE_SUPPORT;
         zone.flipped = true;
         zone.break_time = time[i];
         zone.touches = 0;
      }
   }

   int size = ArraySize(zones);
   ArrayResize(zones, size + 1);
   zones[size] = zone;
}

void DrawZones(const VisualZone &zones[], const datetime current_time)
{
   int total = ArraySize(zones);
   datetime future_time = current_time + (datetime)(PeriodSeconds(_Period) * InpZoneExtendBars);

   for(int i = 0; i < total; ++i)
   {
      string name = g_prefix + "ZONE_" + IntegerToString(i) + "_" + IntegerToString((int)zones[i].start_time);
      color zone_color = InpSupportColor;
      if(zones[i].type == ZONE_RESISTANCE)
         zone_color = InpResistanceColor;
      if(zones[i].flipped)
         zone_color = InpFlippedColor;

      if(ObjectCreate(0, name, OBJ_RECTANGLE, 0, zones[i].start_time, zones[i].upper, future_time, zones[i].lower))
      {
         ObjectSetInteger(0, name, OBJPROP_COLOR, AlphaColor(zone_color));
         ObjectSetInteger(0, name, OBJPROP_FILL, true);
         ObjectSetInteger(0, name, OBJPROP_BACK, true);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, MathMin(3, 1 + zones[i].touches));
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      }

      if(zones[i].flipped && zones[i].break_time > 0)
      {
         string mark = g_prefix + "BROKEN_" + IntegerToString(i) + "_" + IntegerToString((int)zones[i].break_time);
         DrawTextAtBarRaw(mark, zones[i].break_time, zones[i].midpoint, "FLIP", InpFlippedColor, 7, ANCHOR_CENTER);
      }
   }
}

void DetectAndDrawCompression(const int rates_total,
                              const int scan_limit,
                              const datetime &time[],
                              const double &open[],
                              const double &high[],
                              const double &low[],
                              const double &close[],
                              const double &atr[])
{
   int boxes_drawn = 0;
   int max_index = MathMin(scan_limit, rates_total - InpCompressionBars - 1);

   for(int i = max_index; i >= 1 && boxes_drawn < 5; --i)
   {
      bool compressed = true;
      double upper = high[i];
      double lower = low[i];

      for(int j = i; j < i + InpCompressionBars; ++j)
      {
         double candle_range = high[j] - low[j];
         if(candle_range > atr[j] * InpCompressionFactor)
         {
            compressed = false;
            break;
         }
         upper = MathMax(upper, high[j]);
         lower = MathMin(lower, low[j]);
      }

      if(!compressed)
         continue;

      datetime end_time = time[0] + (datetime)(PeriodSeconds(_Period) * 20);
      for(int k = i - 1; k >= 0; --k)
      {
         if(close[k] > upper || close[k] < lower)
         {
            end_time = time[k];
            break;
         }
      }

      string name = g_prefix + "COMP_" + IntegerToString((int)time[i + InpCompressionBars - 1]);
      if(ObjectCreate(0, name, OBJ_RECTANGLE, 0, time[i + InpCompressionBars - 1], upper, end_time, lower))
      {
         ObjectSetInteger(0, name, OBJPROP_COLOR, AlphaColor(InpCompressionColor));
         ObjectSetInteger(0, name, OBJPROP_FILL, true);
         ObjectSetInteger(0, name, OBJPROP_BACK, true);
         ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      }
      boxes_drawn++;
      i -= InpCompressionBars - 1;
   }
}

void DetectAndDrawImportantCandles(const int rates_total,
                                   const int scan_limit,
                                   const datetime &time[],
                                   const double &open[],
                                   const double &high[],
                                   const double &low[],
                                   const double &close[],
                                   const double &atr[],
                                   const VisualZone &zones[])
{
   int max_marks = 60;
   int marks = 0;

   for(int i = MathMin(scan_limit, rates_total - 5); i >= 1 && marks < max_marks; --i)
   {
      double range = MathMax(high[i] - low[i], _Point);
      double body = MathAbs(close[i] - open[i]);
      double body_ratio = body / range;
      double upper_wick = high[i] - MathMax(open[i], close[i]);
      double lower_wick = MathMin(open[i], close[i]) - low[i];
      double upper_wick_ratio = upper_wick / range;
      double lower_wick_ratio = lower_wick / range;

      bool small_body = (body_ratio <= InpSmallBodyRatio);
      bool long_wick = (upper_wick_ratio >= InpLongWickRatio || lower_wick_ratio >= InpLongWickRatio);
      bool contracting = ((high[i] - low[i]) < (high[i + 1] - low[i + 1]) && (high[i + 1] - low[i + 1]) < (high[i + 2] - low[i + 2]));
      bool after_impulse = IsAfterImpulse(i, open, close, high, low);
      bool near_zone = IsNearAnyZone(close[i], atr[i], zones);
      bool breakout_bar = IsBreakoutBar(i, open, high, low, close, atr, zones);

      if(!(small_body || long_wick || contracting || (after_impulse && small_body) || near_zone || breakout_bar))
         continue;

      string text = "•";
      color mark_color = InpImportantColor;
      double y = high[i] + atr[i] * 0.18;
      ENUM_ANCHOR_POINT anchor = ANCHOR_LOWER;

      if(long_wick)
      {
         text = "R";
         mark_color = (upper_wick_ratio > lower_wick_ratio) ? InpBearishColor : InpBullishColor;
         if(lower_wick_ratio > upper_wick_ratio)
         {
            y = low[i] - atr[i] * 0.18;
            anchor = ANCHOR_UPPER;
         }
      }
      else if(breakout_bar)
      {
         text = "BO";
         mark_color = InpFlippedColor;
      }
      else if(contracting)
      {
         text = "C";
      }
      else if(small_body)
      {
         text = "I";
      }

      DrawTextAtBar("IC_" + IntegerToString((int)time[i]), time[i], y, text, mark_color, 8, anchor);
      marks++;
   }
}

bool IsAfterImpulse(const int index,
                    const double &open[],
                    const double &close[],
                    const double &high[],
                    const double &low[])
{
   int direction = 0;
   int large_count = 0;

   for(int j = index + 1; j <= index + 3; ++j)
   {
      double range = MathMax(high[j] - low[j], _Point);
      double body = MathAbs(close[j] - open[j]);
      int candle_direction = 0;
      if(close[j] > open[j])
         candle_direction = 1;
      else if(close[j] < open[j])
         candle_direction = -1;

      if(body / range >= InpLargeBodyRatio)
      {
         if(direction == 0)
            direction = candle_direction;
         if(direction == candle_direction && candle_direction != 0)
            large_count++;
      }
   }

   return (large_count >= 2);
}

bool IsNearAnyZone(const double price, const double atr_value, const VisualZone &zones[])
{
   int total = ArraySize(zones);
   double tolerance = MathMax(atr_value * 0.20, _Point * 10.0);

   for(int i = 0; i < total; ++i)
   {
      if(price >= zones[i].lower - tolerance && price <= zones[i].upper + tolerance)
         return true;
   }
   return false;
}

bool IsBreakoutBar(const int index,
                   const double &open[],
                   const double &high[],
                   const double &low[],
                   const double &close[],
                   const double &atr[],
                   const VisualZone &zones[])
{
   int total = ArraySize(zones);
   double range = MathMax(high[index] - low[index], _Point);
   double body_ratio = MathAbs(close[index] - open[index]) / range;
   if(body_ratio < InpLargeBodyRatio)
      return false;

   for(int i = 0; i < total; ++i)
   {
      double buffer = MathMax(atr[index] * InpZoneATRBuffer, _Point * 10.0);
      if(close[index] > zones[i].upper + buffer || close[index] < zones[i].lower - buffer)
         return true;
   }
   return false;
}

void DrawStructureLine(const datetime start_time,
                       const double start_price,
                       const datetime end_time,
                       const double end_price,
                       const color line_color)
{
   if(!InpShowStructureLines || start_time <= 0 || start_price <= 0.0)
      return;

   string name = g_prefix + "LINE_" + IntegerToString((int)start_time) + "_" + IntegerToString((int)end_time);
   if(ObjectCreate(0, name, OBJ_TREND, 0, start_time, start_price, end_time, end_price))
   {
      ObjectSetInteger(0, name, OBJPROP_COLOR, line_color);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }
}

void DrawTextAtBar(const string suffix,
                   const datetime bar_time,
                   const double price,
                   const string text,
                   const color text_color,
                   const int font_size,
                   const ENUM_ANCHOR_POINT anchor)
{
   DrawTextAtBarRaw(g_prefix + suffix, bar_time, price, text, text_color, font_size, anchor);
}

void DrawTextAtBarRaw(const string name,
                      const datetime bar_time,
                      const double price,
                      const string text,
                      const color text_color,
                      const int font_size,
                      const ENUM_ANCHOR_POINT anchor)
{
   if(ObjectCreate(0, name, OBJ_TEXT, 0, bar_time, price))
   {
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
      ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }
}

void UpdateMultiTimeframeContext()
{
   int m5_context = GetTimeframeContext(PERIOD_M5);
   int m15_context = GetTimeframeContext(PERIOD_M15);

   string text = "M5: " + ContextName(m5_context) + " | M15: " + ContextName(m15_context) + " | Context: neutral";
   color label_color = InpContextColor;

   if(m5_context == CONTEXT_BULLISH && m15_context == CONTEXT_BULLISH)
   {
      text = "M5: bullish | M15: bullish | Context: bullish";
      label_color = InpBullishColor;
   }
   else if(m5_context == CONTEXT_BEARISH && m15_context == CONTEXT_BEARISH)
   {
      text = "M5: bearish | M15: bearish | Context: bearish";
      label_color = InpBearishColor;
   }

   DrawContextLabel(text, label_color);
}

void DrawContextLabel(const string text, const color text_color = clrWhite)
{
   string name = g_prefix + "CONTEXT_LABEL";
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 12);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 18);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

string ContextName(const int context)
{
   if(context == CONTEXT_BULLISH)
      return "bullish";
   if(context == CONTEXT_BEARISH)
      return "bearish";
   return "neutral";
}

int GetTimeframeContext(const ENUM_TIMEFRAMES timeframe)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, timeframe, 0, 120, rates);
   if(copied < 40)
      return CONTEXT_NEUTRAL;

   double previous_high = 0.0;
   double last_high = 0.0;
   double previous_low = 0.0;
   double last_low = 0.0;
   int lookback = 2;

   for(int i = copied - lookback - 1; i >= lookback; --i)
   {
      if(IsRateSwingHigh(rates, copied, i, lookback))
      {
         previous_high = last_high;
         last_high = rates[i].high;
      }
      if(IsRateSwingLow(rates, copied, i, lookback))
      {
         previous_low = last_low;
         last_low = rates[i].low;
      }
   }

   if(previous_high <= 0.0 || previous_low <= 0.0 || last_high <= 0.0 || last_low <= 0.0)
      return CONTEXT_NEUTRAL;

   if(last_high > previous_high && last_low > previous_low)
      return CONTEXT_BULLISH;
   if(last_high < previous_high && last_low < previous_low)
      return CONTEXT_BEARISH;
   return CONTEXT_NEUTRAL;
}

bool IsRateSwingHigh(const MqlRates &rates[], const int total, const int index, const int lookback)
{
   if(index < lookback || index + lookback >= total)
      return false;

   for(int offset = 1; offset <= lookback; ++offset)
   {
      if(rates[index].high <= rates[index - offset].high)
         return false;
      if(rates[index].high <= rates[index + offset].high)
         return false;
   }
   return true;
}

bool IsRateSwingLow(const MqlRates &rates[], const int total, const int index, const int lookback)
{
   if(index < lookback || index + lookback >= total)
      return false;

   for(int offset = 1; offset <= lookback; ++offset)
   {
      if(rates[index].low >= rates[index - offset].low)
         return false;
      if(rates[index].low >= rates[index + offset].low)
         return false;
   }
   return true;
}
