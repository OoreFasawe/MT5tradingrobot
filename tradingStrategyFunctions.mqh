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


//checking if highs follo lows and vice versa
bool isTradingDay()
{
    MqlDateTime day;
    TimeToStruct(TimeCurrent(), day);
    if(day.day_of_week > 0 && day.day_of_week < 6)
        return true;
    else 
        return false;
}

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
        return (lastDailyCandleLow <= trendCandles[1].low && properBreak(trendBreakType));
    else if (trendBreakType == "TO UPSIDE")
        return (lastDailyCandleHigh >= trendCandles[1].high && properBreak(trendBreakType));
    else
        return false;
}

//where prrice doesn't go back to the 
bool properBreak(string trendBreakType)
{
    MqlRates breakoutCandles[];
    int upBreakoutCandle = 0;
    int downBreakoutCandle = 0;

    //candles from now till opening of last day
    int candlesTillLastDay = CopyRates(NULL, PERIOD_H1, iTime(NULL, PERIOD_H1, 0), iTime(NULL, PERIOD_D1, 1), breakoutCandles);
    //candles number of max and min candle 
    for( int i = 1; i < candlesTillLastDay; i ++)
    {
        if(breakoutCandles[i].high == lastDailyCandleHigh)
            upBreakoutCandle = i;
        if(breakoutCandles[i].low == lastDailyCandleLow)
            downBreakoutCandle = i;
    }

    if(trendBreakType == "TO DOWNSIDE")
    {
        for(int i = downBreakoutCandle; i < candlesTillLastDay; i++)
        {
            if(breakoutCandles[i].high > fibPriceForSells)
                return false;
        }
        return true; 
    }
    else if(trendBreakType == "TO UPSIDE")
    {
        for(int i = upBreakoutCandle; i < candlesTillLastDay; i++)
        {
            if(breakoutCandles[i].low < fibPriceForBuys)
                return false;
        }
        return true;
    }
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
        if(lotSize >= 0.01 && spread < 50)
        {
            trade.SellLimit(calculateLotSize(calculatePipDifference(fibPriceForSells, maxHeight)), fibPriceForSells, NULL, maxHeight, fibRetracePrice(maxHeight, lastDailyCandleLow, -0.27), ORDER_TIME_DAY, 0, NULL);
            checkAgain = false;
        }
    }
    else if(trendClassifier(trendCandles) % 2 != 0 && trendBreak("TO UPSIDE")) // downtrend
    {
        lotSize = calculateLotSize(calculatePipDifference(fibPriceForBuys, minHeight));
        spread = calculatePipDifference(SymbolInfoDouble(NULL, SYMBOL_BID), SymbolInfoDouble(NULL, SYMBOL_ASK) /*_SPREAD*/) ;
        if(lotSize >= 0.01 && spread < 50)
        {
            trade.BuyLimit(calculateLotSize(calculatePipDifference(fibPriceForBuys, minHeight)), fibPriceForBuys, NULL, minHeight, fibRetracePrice(minHeight, lastDailyCandleHigh, -0.27), ORDER_TIME_DAY, 0, NULL);
            checkAgain = false;
        }
    }
}

void checkForPartials()
{
    if(PositionsTotal())
    {  
        for(int i = 0; i < PositionsTotal(); i++)
        {
            ulong posTicket = PositionGetTicket(i);

            if(PositionSelectByTicket(posTicket))
            {
                double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                double posSl = PositionGetDouble(POSITION_SL);
                double posCurrentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
                double posTp = PositionGetDouble(POSITION_TP);
                ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                double posLots = PositionGetDouble(POSITION_VOLUME);

                if(posType == POSITION_TYPE_BUY && posSl != posOpenPrice)
                {
                    if(posCurrentPrice >= fibRetracePrice(posSl, posOpenPrice, -3.67))
                    {
                        trade.PositionClosePartial(posTicket, NormalizeDouble(posLots / 2, 2));
                        trade.PositionModify(posTicket, posOpenPrice, posTp);
                    }
                            //modify order by closing half and moving sl to openPrice, set partialled to false
                }
                else if(posType == POSITION_TYPE_SELL && posSl != posOpenPrice)
                {
                    if(posCurrentPrice <= fibRetracePrice(posSl, posOpenPrice, -3.67))
                    {
                        trade.PositionClosePartial(posTicket, NormalizeDouble(posLots / 2, 2));
                        trade.PositionModify(posTicket, posOpenPrice, posTp);
                    }
                }
            }

        }
    }
}






//Extra functions that may be helpful for optimization in the future

//better implementation of peaksInMatchingOrder, more reusable.
bool highBeforeLow(int daysBeforeCurrent)
{
    MqlRates dayH1Candles;

    candleLength = CopyRates(NULL, PERIOD_H1,daysBeforeCurrent, 1, dayH1Candles);

    int dayHigh
    int dayLow;

    for(int i = 0; i < candleLength; i++)
    {
        if(dayH1Candles(i).high == iHigh(NULL, PERIOD_D1, daysBeforeCurrent))
            dayHigh = i;
        if(dayH1Candles(i).low == iLow(NULL, PERIOD_D1, daysBeforeCurrent))
            dayLow = i;
    }

    return (dayHigh < dayLow);
}

bool lowbeforeHigh(int daysBeforeCurrent)
{

    return (!highBeforeLow(daysBeforeCurrent));
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
