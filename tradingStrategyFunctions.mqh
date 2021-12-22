#property copyright "Ooreoluwa Fasawe"
#property link      "https://www.mql5.com"

#include <riskManagementFunctions.mqh>
#include <Trade\Trade.mqh>

CTrade trade;
MqlRates trendCandles[2];
int dailyCandles = CopyRates(NULL, PERIOD_D1, 2, 2, trendCandles); //copy daily candle data into array
double lastDailyCandleLow = iLow(NULL, PERIOD_D1, 1);
double lastDailyCandleHigh = iHigh(NULL, PERIOD_D1, 1);
double maxHeight = NormalizeDouble(fmax(trendCandles[1].high, lastDailyCandleHigh), _Digits);
double fibPriceForSells = fibRetracePrice(maxHeight, lastDailyCandleLow, 0.786);
double minHeight = NormalizeDouble(fmin(trendCandles[1].low, lastDailyCandleLow), _Digits);
double fibPriceForBuys = fibRetracePrice(minHeight, lastDailyCandleHigh, 0.786);
double lotSize;
double spread;
static bool checkAgain = true;

//checking if highs follo lows and vice versa
bool peaksInMatchingOrder(MqlRates &array[]) 
{
    MqlRates h1candles[48];
    MqlDateTime fHigh, fLow, sHigh, sLow;
    int hourlyCandles = CopyRates(NULL, PERIOD_H1, iTime(NULL, PERIOD_D1, 1), 48, h1candles);

    for(int i = 0; i < hourlyCandles; i++)
    {
        if(h1candles[i].high == array[0].high)
            TimeToStruct(h1candles[i].time, fHigh);
        else if(h1candles[i].low == array[0].low)
            TimeToStruct(h1candles[i].time, fLow);
        else if(h1candles[i].high == array[1].high)
            TimeToStruct(h1candles[i].time, sHigh);
        else if(h1candles[i].low == array[1].low)
            TimeToStruct(h1candles[i].time, sLow);
        else {}
    }

    if((fHigh.hour < fLow.hour && sHigh.hour < sLow.hour) || (fLow.hour < fHigh.hour && sLow.hour < sHigh.hour))
        return true;
    else
        return false;
}

int trendClassifier(MqlRates& array[])
{
    //if the highs and lows go in chronological order i.e high then a low then another high then another low
    //evens for uptrends, odds for down trends, 0's for consolidation or choppy markets
    if(peaksInMatchingOrder(array))
    {
        //if highs and lows go in increasing or decreasing order ie h l hh hl or l h lh ll
        if((array[0].high < array[1].high) && (array[0].low < array[1].low) && (array[0].close > array[0].open) && (array[1].close > array[1].open) )
            return 4; //strong uptrend 
        else if((array[0].high > array[1].high) && (array[0].low > array[1].low) && (array[0].close < array[0].open) && (array[1].close < array[1].open))
            return 3; //strong downtrend
        else if((array[0].high < array[1].high) && (array[0].low < array[1].low))
            return 2; //uptrend
        else if((array[0].high > array[1].high && array[0].low > array[1].low))
            return 1; //downtrend
        else
            return 0; //consolidation
    }
    else
        return 0; //not a trend
}

//checks if trend identified was broken by previous daily candle
bool trendBreak(string trendBreakType)
{
    if(trendBreakType ==  "TO DOWNSIDE")
        return (lastDailyCandleLow <= trendCandles[1].low && SymbolInfoDouble(NULL, SYMBOL_BID) < fibPriceForSells /*0.786 area of chart*/);
    else if (trendBreakType == "TO UPSIDE")
        return (lastDailyCandleHigh >= trendCandles[1].high && SymbolInfoDouble(NULL, SYMBOL_ASK) > fibPriceForBuys /*0.786 area of char */);
    else
        return false;
}

void trade()
{
    if(trendClassifier(trendCandles) == 0) // consolidation
        {}
    else if (trendClassifier(trendCandles) % 2 == 0 && trendBreak("TO DOWNSIDE")) // uptrend
    {
        lotSize = calculateLotSize(calculatePipDifference(fibPriceForSells, maxHeight));
        spread = calculatePipDifference(SymbolInfoDouble(NULL, SYMBOL_BID), SymbolInfoDouble(NULL, SYMBOL_ASK) /*_SPREAD*/) ;
        if(lotSize >= 0.01 && spread < 100)
        {
            trade.SellLimit(calculateLotSize(calculatePipDifference(fibPriceForSells, maxHeight)), fibPriceForSells, NULL, maxHeight, lastDailyCandleLow, ORDER_TIME_DAY, 0, NULL);
            checkAgain = false;
        }
    }
    else if(trendClassifier(trendCandles) % 2 != 0 && trendBreak("TO UPSIDE")) // downtrend
    {
        lotSize = calculateLotSize(calculatePipDifference(fibPriceForBuys, minHeight));
        spread = calculatePipDifference(SymbolInfoDouble(NULL, SYMBOL_BID), SymbolInfoDouble(NULL, SYMBOL_ASK) /*_SPREAD*/) ;
        if(lotSize >= 0.01 && spread < 100)
            {
            trade.BuyLimit(calculateLotSize(calculatePipDifference(fibPriceForBuys, minHeight)), fibPriceForBuys, NULL, minHeight, lastDailyCandleHigh, ORDER_TIME_DAY, 0, NULL);
            checkAgain = false;
            }
    }
}



















































    // Print("Current bar for USDCHF H1: ",iTime("USDCHF",PERIOD_H1,0),", ",  iOpen("USDCHF",PERIOD_H1,0),", ",
    //                                       iHigh("USDCHF",PERIOD_H1,0),", ",  iLow("USDCHF",PERIOD_H1,0),", ",
    //                                       iClose("USDCHF",PERIOD_H1,0),", ", iVolume("USDCHF",PERIOD_H1,0));


    // for(int i = 0; i < copied; i++)
    // {
    //     Alert(StringFormat("Start of daily candle at %d: %s",i, TimeToString(trendCandles[i].time)));
    //     Alert(StringFormat("Open for daily candle %d: %G",i, trendCandles[i].open));
    //     Alert(StringFormat("High for daily candle %d: %G",i,  trendCandles[i].high));
    //     Alert(StringFormat("Low for daily candle %d: %G",i,  trendCandles[i].low));
    //     Alert(StringFormat("Close for daily candle %d: %G",i,  trendCandles[i].close));
    //     Alert(StringFormat("Tick volume for daily candle %d: %d",i, trendCandles[i].tick_volume));
    // }

    // Alert("First day high: " + TimeToString(StructToTime(fHigh)));
    // Alert("First day low: " + TimeToString(StructToTime(fLow)));
    // Alert("Second day high: " + TimeToString(StructToTime(sHigh)));
    // Alert("Second day low: " + TimeToString(StructToTime(sLow)));
