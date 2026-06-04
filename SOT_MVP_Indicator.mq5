#property copyright "SOT MVP"
#property link      ""
#property version   "2.00"
#property strict
#property indicator_chart_window
#property indicator_plots 0

input int    InpSwingConfirmBars       = 3;
input int    InpMaxBarsToScan          = 260;
input int    InpMaxStructureLabels     = 24;
input int    InpZoneExtendBars         = 160;
input int    InpATRPeriod              = 14;
input double InpZoneATRBuffer          = 0.30;
input int    InpCompressionBars        = 7;
input double InpCompressionATRFactor   = 0.72;
input double InpSmallBodyRatio         = 0.25;
input double InpLongWickRatio          = 0.55;
input double InpImpulseBodyRatio       = 0.60;
input int    InpMaxImportantCandles    = 14;
input bool   InpShowStructureLines     = true;
input color  InpBullishColor           = clrMediumSeaGreen;
input color  InpBearishColor           = clrTomato;
input color  InpSupportColor           = clrSeaGreen;
input color  InpResistanceColor        = clrIndianRed;
input color  InpFlippedColor           = clrDarkOrange;
input color  InpCompressionColor       = clrSlateGray;
input color  InpImportantColor         = clrGold;
input color  InpContextColor           = clrWhite;
input int    InpFillAlpha              = 42;

#define SOT_PREFIX "SOT_MVP_V2_"
#define SWING_HIGH_TYPE  1
#define SWING_LOW_TYPE  -1
#define CONTEXT_BULLISH  1
#define CONTEXT_BEARISH -1
#define CONTEXT_NEUTRAL  0

struct SwingPoint
{
   int      type;
   int      index;
   double   price;
   datetime time;
   string   label;
};

struct ActiveZone
{
   bool     valid;
   bool     broken;
   bool     flipped;
   int      type;
   int      source_index;
   double   upper;
   double   lower;
   double   midpoint;
   datetime start_time;
   datetime end_time;
   datetime break_time;
};

int      g_atr_handle = INVALID_HANDLE;
string   g_prefix = "";
datetime g_last_closed_bar_time = 0;

int OnInit()
{
   g_prefix = SOT_PREFIX + IntegerToString((int)ChartID()) + "_";
   g_atr_handle = iATR(_Symbol, _Period, InpATRPeriod);
   if(g_atr_handle == INVALID_HANDLE)
      return INIT_FAILED;

   IndicatorSetString(INDICATOR_SHORTNAME, "SOT MVP Market Structure V2");
   DrawContextLabel("Neutral Context", InpContextColor);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   DeleteAllSOTObjects();
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

   if(prev_calculated > 0 && g_last_closed_bar_time == time[1])
   {
      UpdateMultiTimeframeContext();
      return rates_total;
   }
   g_last_closed_bar_time = time[1];

   double atr[];
   ArraySetAsSeries(atr, true);
   int copied = CopyBuffer(g_atr_handle, 0, 0, rates_total, atr);
   if(copied <= RequiredBars())
      return prev_calculated;

   int scan_limit = MathMin(InpMaxBarsToScan, rates_total - InpSwingConfirmBars - 2);
   if(scan_limit <= InpSwingConfirmBars + 2)
      return prev_calculated;

   DeleteObjectGroup("MS_");
   DeleteObjectGroup("LINE_");
   DeleteObjectGroup("IMP_");
   DeleteObjectGroup("BRK_");

   SwingPoint swings[];
   ActiveZone support_zone;
   ActiveZone resistance_zone;
   ActiveZone compression_zone;
   ResetZone(support_zone);
   ResetZone(resistance_zone);
   ResetZone(compression_zone);

   BuildConfirmedSwings(rates_total, scan_limit, time, high, low, swings);
   DrawMarketStructure(swings, atr);
   BuildActiveZones(scan_limit, time, high, low, close, atr, support_zone, resistance_zone);
   DrawActiveZone("SUPPORT", support_zone, time[0]);
   DrawActiveZone("RESISTANCE", resistance_zone, time[0]);
   DrawBreakoutMarker("SUPPORT", support_zone);
   DrawBreakoutMarker("RESISTANCE", resistance_zone);
   DetectCompression(scan_limit, time, open, high, low, close, atr, compression_zone);
   DrawCompressionZone(compression_zone, time[0]);
   DrawImportantCandles(scan_limit, time, open, high, low, close, atr, support_zone, resistance_zone, compression_zone);
   UpdateMultiTimeframeContext();

   ChartRedraw(0);
   return rates_total;
}

int RequiredBars()
{
   return MathMax(80, InpATRPeriod + InpCompressionBars + InpSwingConfirmBars * 2 + 20);
}

void ResetZone(ActiveZone &zone)
{
   zone.valid = false;
   zone.broken = false;
   zone.flipped = false;
   zone.type = 0;
   zone.source_index = -1;
   zone.upper = 0.0;
   zone.lower = 0.0;
   zone.midpoint = 0.0;
   zone.start_time = 0;
   zone.end_time = 0;
   zone.break_time = 0;
}

void DeleteAllSOTObjects()
{
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; --i)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, g_prefix) == 0)
         ObjectDelete(0, name);
   }
}

void DeleteObjectGroup(const string group_name)
{
   string prefix = g_prefix + group_name;
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; --i)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
   }
}

color TransparentColor(const color base_color)
{
   int alpha = MathMax(0, MathMin(255, InpFillAlpha));
   return (color)ColorToARGB(base_color, (uchar)alpha);
}

bool IsConfirmedSwingHigh(const int index, const int rates_total, const double &high[])
{
   if(index <= InpSwingConfirmBars || index + InpSwingConfirmBars >= rates_total)
      return false;

   for(int offset = 1; offset <= InpSwingConfirmBars; ++offset)
   {
      if(high[index] <= high[index - offset])
         return false;
      if(high[index] <= high[index + offset])
         return false;
   }
   return true;
}

bool IsConfirmedSwingLow(const int index, const int rates_total, const double &low[])
{
   if(index <= InpSwingConfirmBars || index + InpSwingConfirmBars >= rates_total)
      return false;

   for(int offset = 1; offset <= InpSwingConfirmBars; ++offset)
   {
      if(low[index] >= low[index - offset])
         return false;
      if(low[index] >= low[index + offset])
         return false;
   }
   return true;
}

void BuildConfirmedSwings(const int rates_total,
                          const int scan_limit,
                          const datetime &time[],
                          const double &high[],
                          const double &low[],
                          SwingPoint &swings[])
{
   ArrayResize(swings, 0);
   double previous_high = 0.0;
   double previous_low = 0.0;

   for(int i = scan_limit; i >= InpSwingConfirmBars + 1; --i)
   {
      if(IsConfirmedSwingHigh(i, rates_total, high))
      {
         SwingPoint swing;
         swing.type = SWING_HIGH_TYPE;
         swing.index = i;
         swing.price = high[i];
         swing.time = time[i];
         swing.label = (previous_high <= 0.0 || high[i] > previous_high) ? "HH" : "LH";
         previous_high = high[i];
         AddSwing(swings, swing);
      }

      if(IsConfirmedSwingLow(i, rates_total, low))
      {
         SwingPoint swing;
         swing.type = SWING_LOW_TYPE;
         swing.index = i;
         swing.price = low[i];
         swing.time = time[i];
         swing.label = (previous_low <= 0.0 || low[i] > previous_low) ? "HL" : "LL";
         previous_low = low[i];
         AddSwing(swings, swing);
      }
   }
}

void AddSwing(SwingPoint &swings[], const SwingPoint &swing)
{
   int size = ArraySize(swings);
   ArrayResize(swings, size + 1);
   swings[size] = swing;
}

void DrawMarketStructure(const SwingPoint &swings[], const double &atr[])
{
   int total = ArraySize(swings);
   int first = MathMax(0, total - InpMaxStructureLabels);
   datetime previous_time = 0;
   double previous_price = 0.0;

   for(int i = first; i < total; ++i)
   {
      SwingPoint swing = swings[i];
      color label_color = (swing.label == "HH" || swing.label == "HL") ? InpBullishColor : InpBearishColor;
      double offset = MathMax(atr[swing.index] * 0.20, _Point * 20.0);
      double price = swing.price + (swing.type == SWING_HIGH_TYPE ? offset : -offset);
      ENUM_ANCHOR_POINT anchor = (swing.type == SWING_HIGH_TYPE) ? ANCHOR_LOWER : ANCHOR_UPPER;
      string name = "MS_" + swing.label + "_" + IntegerToString((int)swing.time);
      DrawTextObject(name, swing.time, price, swing.label, label_color, 8, anchor);

      if(InpShowStructureLines && previous_time > 0)
         DrawTrendLine("LINE_" + IntegerToString((int)previous_time) + "_" + IntegerToString((int)swing.time), previous_time, previous_price, swing.time, swing.price, label_color);

      previous_time = swing.time;
      previous_price = swing.price;
   }
}

void BuildActiveZones(const int scan_limit,
                      const datetime &time[],
                      const double &high[],
                      const double &low[],
                      const double &close[],
                      const double &atr[],
                      ActiveZone &support_zone,
                      ActiveZone &resistance_zone)
{
   bool support_found = false;
   bool resistance_found = false;

   for(int i = InpSwingConfirmBars + 1; i <= scan_limit; ++i)
   {
      if(!support_found && IsConfirmedSwingLow(i, scan_limit + InpSwingConfirmBars + 2, low))
      {
         CreateZone(SWING_LOW_TYPE, i, time, low[i], atr[i], support_zone);
         EvaluateZoneBreak(support_zone, time, close, atr);
         support_found = true;
      }

      if(!resistance_found && IsConfirmedSwingHigh(i, scan_limit + InpSwingConfirmBars + 2, high))
      {
         CreateZone(SWING_HIGH_TYPE, i, time, high[i], atr[i], resistance_zone);
         EvaluateZoneBreak(resistance_zone, time, close, atr);
         resistance_found = true;
      }

      if(support_found && resistance_found)
         break;
   }
}

void CreateZone(const int swing_type,
                const int source_index,
                const datetime &time[],
                const double midpoint,
                const double atr_value,
                ActiveZone &zone)
{
   double width = MathMax(atr_value * InpZoneATRBuffer, _Point * 20.0);
   zone.valid = true;
   zone.broken = false;
   zone.flipped = false;
   zone.type = swing_type;
   zone.source_index = source_index;
   zone.midpoint = midpoint;
   zone.upper = midpoint + width;
   zone.lower = midpoint - width;
   zone.start_time = time[source_index];
   zone.end_time = 0;
   zone.break_time = 0;
}

void EvaluateZoneBreak(ActiveZone &zone, const datetime &time[], const double &close[], const double &atr[])
{
   if(!zone.valid)
      return;

   double break_buffer = MathMax(atr[zone.source_index] * InpZoneATRBuffer, _Point * 20.0);
   for(int i = zone.source_index - 1; i >= 1; --i)
   {
      if(zone.type == SWING_HIGH_TYPE && close[i] > zone.upper + break_buffer)
      {
         zone.broken = true;
         zone.flipped = true;
         zone.break_time = time[i];
         zone.end_time = time[i];
         return;
      }

      if(zone.type == SWING_LOW_TYPE && close[i] < zone.lower - break_buffer)
      {
         zone.broken = true;
         zone.flipped = true;
         zone.break_time = time[i];
         zone.end_time = time[i];
         return;
      }
   }
}

void DrawActiveZone(const string slot, const ActiveZone &zone, const datetime current_time)
{
   string name = g_prefix + "ZONE_" + TimeframeName(_Period) + "_" + slot;
   if(!zone.valid)
   {
      ObjectDelete(0, name);
      return;
   }

   datetime right_time = zone.broken ? zone.end_time : current_time + (datetime)(PeriodSeconds(_Period) * InpZoneExtendBars);
   color zone_color = InpFlippedColor;
   if(!zone.flipped)
      zone_color = (zone.type == SWING_LOW_TYPE) ? InpSupportColor : InpResistanceColor;

   UpsertRectangle(name, zone.start_time, zone.upper, right_time, zone.lower, zone_color, true, true, STYLE_SOLID, 1);
}

void DrawBreakoutMarker(const string slot, const ActiveZone &zone)
{
   if(!zone.valid || !zone.broken || zone.break_time <= 0)
      return;

   string name = "BRK_" + TimeframeName(_Period) + "_" + slot;
   DrawTextObject(name, zone.break_time, zone.midpoint, "BREAK", InpFlippedColor, 8, ANCHOR_CENTER);
}

void DetectCompression(const int scan_limit,
                       const datetime &time[],
                       const double &open[],
                       const double &high[],
                       const double &low[],
                       const double &close[],
                       const double &atr[],
                       ActiveZone &compression_zone)
{
   ResetZone(compression_zone);
   int max_index = MathMin(scan_limit, scan_limit - InpCompressionBars + 1);

   for(int i = 1; i <= max_index; ++i)
   {
      double upper = high[i];
      double lower = low[i];
      double range_sum = 0.0;
      double atr_sum = 0.0;
      bool narrowing = true;

      for(int j = i; j < i + InpCompressionBars; ++j)
      {
         double range = high[j] - low[j];
         range_sum += range;
         atr_sum += atr[j];
         upper = MathMax(upper, high[j]);
         lower = MathMin(lower, low[j]);

         if(j > i && range > (high[j - 1] - low[j - 1]) * 1.15)
            narrowing = false;
      }

      double average_range = range_sum / InpCompressionBars;
      double average_atr = atr_sum / InpCompressionBars;
      if(average_range > average_atr * InpCompressionATRFactor || !narrowing)
         continue;

      compression_zone.valid = true;
      compression_zone.type = 0;
      compression_zone.source_index = i + InpCompressionBars - 1;
      compression_zone.start_time = time[i + InpCompressionBars - 1];
      compression_zone.end_time = time[0] + (datetime)(PeriodSeconds(_Period) * 30);
      compression_zone.upper = upper;
      compression_zone.lower = lower;
      compression_zone.midpoint = (upper + lower) / 2.0;

      for(int k = i - 1; k >= 1; --k)
      {
         if(close[k] > upper || close[k] < lower)
         {
            compression_zone.broken = true;
            compression_zone.break_time = time[k];
            compression_zone.end_time = time[k];
            break;
         }
      }
      return;
   }
}

void DrawCompressionZone(const ActiveZone &compression_zone, const datetime current_time)
{
   string name = g_prefix + "COMPRESSION_ACTIVE";
   if(!compression_zone.valid)
   {
      ObjectDelete(0, name);
      return;
   }

   datetime right_time = compression_zone.broken ? compression_zone.end_time : current_time + (datetime)(PeriodSeconds(_Period) * 30);
   UpsertRectangle(name, compression_zone.start_time, compression_zone.upper, right_time, compression_zone.lower, InpCompressionColor, true, true, STYLE_DOT, 1);
}

void DrawImportantCandles(const int scan_limit,
                          const datetime &time[],
                          const double &open[],
                          const double &high[],
                          const double &low[],
                          const double &close[],
                          const double &atr[],
                          const ActiveZone &support_zone,
                          const ActiveZone &resistance_zone,
                          const ActiveZone &compression_zone)
{
   int marks = 0;
   int limit = MathMin(scan_limit, 90);

   for(int i = 1; i <= limit && marks < InpMaxImportantCandles; ++i)
   {
      if(!IsNearVisualArea(close[i], atr[i], support_zone, resistance_zone, compression_zone))
         continue;

      double range = MathMax(high[i] - low[i], _Point);
      double body = MathAbs(close[i] - open[i]);
      double body_ratio = body / range;
      double upper_wick_ratio = (high[i] - MathMax(open[i], close[i])) / range;
      double lower_wick_ratio = (MathMin(open[i], close[i]) - low[i]) / range;

      bool rejection = (upper_wick_ratio >= InpLongWickRatio || lower_wick_ratio >= InpLongWickRatio);
      bool small_after_impulse = (body_ratio <= InpSmallBodyRatio && HasRecentImpulse(i, open, high, low, close));
      bool slowdown = IsMomentumSlowdown(i, open, high, low, close);

      if(!rejection && !small_after_impulse && !slowdown)
         continue;

      string text = "!";
      color mark_color = InpImportantColor;
      double y = high[i] + MathMax(atr[i] * 0.18, _Point * 25.0);
      ENUM_ANCHOR_POINT anchor = ANCHOR_LOWER;

      if(rejection)
      {
         text = "R";
         if(lower_wick_ratio > upper_wick_ratio)
         {
            y = low[i] - MathMax(atr[i] * 0.18, _Point * 25.0);
            mark_color = InpBullishColor;
            anchor = ANCHOR_UPPER;
         }
         else
            mark_color = InpBearishColor;
      }
      else if(slowdown)
         text = "S";

      DrawTextObject("IMP_" + IntegerToString((int)time[i]), time[i], y, text, mark_color, 8, anchor);
      marks++;
   }
}

bool IsNearVisualArea(const double price,
                      const double atr_value,
                      const ActiveZone &support_zone,
                      const ActiveZone &resistance_zone,
                      const ActiveZone &compression_zone)
{
   double tolerance = MathMax(atr_value * 0.25, _Point * 20.0);
   if(IsPriceNearZone(price, tolerance, support_zone))
      return true;
   if(IsPriceNearZone(price, tolerance, resistance_zone))
      return true;
   if(IsPriceNearZone(price, tolerance, compression_zone))
      return true;
   return false;
}

bool IsPriceNearZone(const double price, const double tolerance, const ActiveZone &zone)
{
   if(!zone.valid)
      return false;
   return (price >= zone.lower - tolerance && price <= zone.upper + tolerance);
}

bool HasRecentImpulse(const int index,
                      const double &open[],
                      const double &high[],
                      const double &low[],
                      const double &close[])
{
   int direction = 0;
   int impulse_count = 0;

   for(int j = index + 1; j <= index + 3; ++j)
   {
      double range = MathMax(high[j] - low[j], _Point);
      double body_ratio = MathAbs(close[j] - open[j]) / range;
      int candle_direction = (close[j] > open[j]) ? 1 : ((close[j] < open[j]) ? -1 : 0);

      if(body_ratio >= InpImpulseBodyRatio && candle_direction != 0)
      {
         if(direction == 0)
            direction = candle_direction;
         if(direction == candle_direction)
            impulse_count++;
      }
   }
   return (impulse_count >= 2);
}

bool IsMomentumSlowdown(const int index,
                        const double &open[],
                        const double &high[],
                        const double &low[],
                        const double &close[])
{
   double body_0 = MathAbs(close[index] - open[index]);
   double body_1 = MathAbs(close[index + 1] - open[index + 1]);
   double body_2 = MathAbs(close[index + 2] - open[index + 2]);
   double range_0 = high[index] - low[index];
   double range_1 = high[index + 1] - low[index + 1];
   double range_2 = high[index + 2] - low[index + 2];

   return (body_0 < body_1 && body_1 < body_2 && range_0 <= range_1 && range_1 <= range_2);
}

void UpdateMultiTimeframeContext()
{
   int m5_context = GetTimeframeContext(PERIOD_M5);
   int m15_context = GetTimeframeContext(PERIOD_M15);

   if(m5_context == CONTEXT_BULLISH && m15_context == CONTEXT_BULLISH)
      DrawContextLabel("Bullish Context", InpBullishColor);
   else if(m5_context == CONTEXT_BEARISH && m15_context == CONTEXT_BEARISH)
      DrawContextLabel("Bearish Context", InpBearishColor);
   else
      DrawContextLabel("Neutral Context", InpContextColor);
}

int GetTimeframeContext(const ENUM_TIMEFRAMES timeframe)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, timeframe, 0, 140, rates);
   if(copied < 50)
      return CONTEXT_NEUTRAL;

   double previous_high = 0.0;
   double last_high = 0.0;
   double previous_low = 0.0;
   double last_low = 0.0;
   int confirm = 2;

   for(int i = copied - confirm - 1; i >= confirm + 1; --i)
   {
      if(IsRateSwingHigh(rates, copied, i, confirm))
      {
         previous_high = last_high;
         last_high = rates[i].high;
      }

      if(IsRateSwingLow(rates, copied, i, confirm))
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

bool IsRateSwingHigh(const MqlRates &rates[], const int total, const int index, const int confirm)
{
   if(index <= confirm || index + confirm >= total)
      return false;

   for(int offset = 1; offset <= confirm; ++offset)
   {
      if(rates[index].high <= rates[index - offset].high)
         return false;
      if(rates[index].high <= rates[index + offset].high)
         return false;
   }
   return true;
}

bool IsRateSwingLow(const MqlRates &rates[], const int total, const int index, const int confirm)
{
   if(index <= confirm || index + confirm >= total)
      return false;

   for(int offset = 1; offset <= confirm; ++offset)
   {
      if(rates[index].low >= rates[index - offset].low)
         return false;
      if(rates[index].low >= rates[index + offset].low)
         return false;
   }
   return true;
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
                     const int width)
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
}

void DrawTextObject(const string suffix,
                    const datetime object_time,
                    const double price,
                    const string text,
                    const color text_color,
                    const int font_size,
                    const ENUM_ANCHOR_POINT anchor)
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
}

void DrawTrendLine(const string suffix,
                   const datetime first_time,
                   const double first_price,
                   const datetime second_time,
                   const double second_price,
                   const color line_color)
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
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void DrawContextLabel(const string text, const color text_color)
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

string TimeframeName(const ENUM_TIMEFRAMES timeframe)
{
   switch(timeframe)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      default:         return IntegerToString((int)timeframe);
   }
}
