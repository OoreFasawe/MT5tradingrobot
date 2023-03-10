#property copyright "Ooreoluwa Fasawe"
#property link "https://www.mql5.com"

#include <riskManagementFunctions.mqh>
#include <Trade\Trade.mqh>
#include <..\Experts\OB.mqh>

CTrade trade;
MqlRates trendCandles[2];
int dailyCandles = CopyRates(NULL, PERIOD_D1, 2, 2, trendCandles); // copy daily candle data into array
double lastDailyCandleLow = iLow(NULL, PERIOD_D1, 1);
double lastDailyCandleHigh = iHigh(NULL, PERIOD_D1, 1);
double maxHeight = NormalizeDouble(fmax(trendCandles[1].high, lastDailyCandleHigh), _Digits);
double fibPriceForSells = fibRetracePrice(maxHeight, lastDailyCandleLow, 0.786);
double minHeight = NormalizeDouble(fmin(trendCandles[1].low, lastDailyCandleLow), _Digits);
double fibPriceForBuys = fibRetracePrice(minHeight, lastDailyCandleHigh, 0.786);
double lotSize;
double spread;
OB OBList[];
double orderDetails[2];

// checking if highs follo lows and vice versa
MqlDateTime timeOfDay()
{
    MqlDateTime time;
    TimeToStruct(TimeLocal(), time);

    return time;
}

bool isTradingDay()
{
    MqlDateTime day;
    TimeToStruct(TimeCurrent(), day);
    if (day.day_of_week > 0 && day.day_of_week < 6)
        return true;
    else
        return false;
}

bool peaksInMatchingOrder(MqlRates &array[])
{
    MqlRates h1candles[48];
    MqlDateTime fHigh, fLow, sHigh, sLow;
    int hourlyCandles = CopyRates(NULL, PERIOD_H1, iTime(NULL, PERIOD_D1, 1), 48, h1candles);

    for (int i = 0; i < hourlyCandles; i++)
    {
        if (h1candles[i].high == array[0].high)
            TimeToStruct(h1candles[i].time, fHigh);
        else if (h1candles[i].low == array[0].low)
            TimeToStruct(h1candles[i].time, fLow);
        else if (h1candles[i].high == array[1].high)
            TimeToStruct(h1candles[i].time, sHigh);
        else if (h1candles[i].low == array[1].low)
            TimeToStruct(h1candles[i].time, sLow);
        else
        {
        }
    }

    if ((fHigh.hour < fLow.hour && sHigh.hour < sLow.hour) || (fLow.hour < fHigh.hour && sLow.hour < sHigh.hour))
        return true;
    else
        return false;
}

int trendClassifier(MqlRates &array[])
{
    // if the highs and lows go in chronological order i.e high then a low then another high then another low
    // evens for uptrends, odds for down trends, 0's for consolidation or choppy markets
    if (peaksInMatchingOrder(array))
    {
        // if highs and lows go in increasing or decreasing order ie h l hh hl or l h lh ll
        if ((array[0].high < array[1].high) && (array[0].low < array[1].low) && (array[0].close > array[0].open) && (array[1].close > array[1].open))
            return 4; // strong uptrend
        else if ((array[0].high > array[1].high) && (array[0].low > array[1].low) && (array[0].close < array[0].open) && (array[1].close < array[1].open))
            return 3; // strong downtrend
        else if ((array[0].high < array[1].high) && (array[0].low < array[1].low))
            return 2; // uptrend
        else if ((array[0].high > array[1].high && array[0].low > array[1].low))
            return 1; // downtrend
        else
            return 0; // consolidation
    }
    else
        return 0; // not a trend
}

// checks if trend identified was broken by previous daily candle
bool trendBreak(string trendBreakType)
{
    if (trendBreakType == "TO DOWNSIDE")
        return (lastDailyCandleLow <= trendCandles[1].low && properBreak(trendBreakType));
    else if (trendBreakType == "TO UPSIDE")
        return (lastDailyCandleHigh >= trendCandles[1].high && properBreak(trendBreakType));
    else
        return false;
}

// where prrice doesn't go back to the
bool properBreak(string trendBreakType)
{
    MqlRates breakoutCandles[];
    int upBreakoutCandle = 0;
    int downBreakoutCandle = 0;

    // candles from now till opening of last day
    int candlesTillLastDay = CopyRates(NULL, PERIOD_H1, iTime(NULL, PERIOD_H1, 0), iTime(NULL, PERIOD_D1, 1), breakoutCandles);
    // candles number of max and min candle
    for (int i = 1; i < candlesTillLastDay; i++)
    {
        if (breakoutCandles[i].high == lastDailyCandleHigh)
            upBreakoutCandle = i;
        if (breakoutCandles[i].low == lastDailyCandleLow)
            downBreakoutCandle = i;
    }

    if (trendBreakType == "TO DOWNSIDE")
    {
        for (int i = downBreakoutCandle; i < candlesTillLastDay; i++)
        {
            if (breakoutCandles[i].high > fibPriceForSells)
                return false;
        }
        return true;
    }
    else if (trendBreakType == "TO UPSIDE")
    {
        for (int i = upBreakoutCandle; i < candlesTillLastDay; i++)
        {
            if (breakoutCandles[i].low < fibPriceForBuys)
                return false;
        }
        return true;
    }
    else
        return false;
}

void getOBs(double &tradePoints[], string trendBreakType)
{
    OB OBList[];
    MqlRates OBCandles[];
    int leftBound = 0;
    int rightBound = 0;
    int OBCount = 0;

    // candles from now till opening of last day
    int candlesFromMaxOrMin = CopyRates(NULL, PERIOD_M15, iTime(NULL, PERIOD_H1, 0), iTime(NULL, PERIOD_D1, 3), OBCandles);

    for (int i = 1; i < candlesFromMaxOrMin; i++)
    {
        if (trendBreakType == "FOR BUYS")
        {
            if (OBCandles[i].low == minHeight)
                leftBound = i;
            if (OBCandles[i].high == lastDailyCandleHigh)
                rightBound = i;
        }
        else if (trendBreakType == "FOR SELLS")
        {
            if (OBCandles[i].high == maxHeight)
                leftBound = i;
            if (OBCandles[i].low == lastDailyCandleLow)
                rightBound = i;
        }
    }

    for (int i = leftBound; i < rightBound; i++)
    {
        if (trendBreakType == "FOR BUYS")
        {
            if (OBCandles[i - 1].low > OBCandles[i].low && OBCandles[i].low < OBCandles[i + 1].low && OBCandles[i].low < fibPriceForBuys)
            {

                OBCount += 1;
                ArrayResize(OBList, OBCount);
                OBList[OBCount - 1] = OB(OBCandles[i].high, OBCandles[i].low, OBCandles[i].time);
            }
        }
        else if (trendBreakType == "FOR SELLS")
        {
            if (OBCandles[i - 1].high < OBCandles[i].high && OBCandles[i].high > OBCandles[i + 1].high && OBCandles[i].high > fibPriceForSells)
            {
                OBCount += 1;
                ArrayResize(OBList, OBCount);
                OBList[OBCount - 1] = OB(OBCandles[i].high, OBCandles[i].low, OBCandles[i].time);
            }
        }
    }

    // Move oversized OBs out of the way
    for (int i = 0; i < OBCount; i++)
    {
        if (trendBreakType == "FOR BUYS")
        {
            if (OBList[i].getHeight() >= calculatePipDifference(minHeight, fibPriceForBuys))
            {
                OBList[i].setTop(lastDailyCandleHigh);
                OBList[i].setBottom(lastDailyCandleHigh);
                OBList[i].setMiddle(lastDailyCandleHigh);
            }
        }
        else if (trendBreakType == "FOR SELLS")
        {
            if (OBList[i].getHeight() >= calculatePipDifference(maxHeight, fibPriceForSells))
            {
                OBList[i].setTop(lastDailyCandleLow);
                OBList[i].setBottom(lastDailyCandleLow);
                OBList[i].setMiddle(lastDailyCandleLow);
            }
        }
    }

    // Move tested OBs out of the way
    for (int i = 0; i < OBCount - 1; i++)
    {
        for (int j = i + 1; j < OBCount; j++)
        {
            if (trendBreakType == "FOR BUYS")
            {
                if (OBList[i].getMiddle() > OBList[j].getBottom())
                {
                    OBList[i].setTop(lastDailyCandleHigh);
                    OBList[i].setBottom(lastDailyCandleHigh);
                    OBList[i].setMiddle(lastDailyCandleHigh);
                }
            }
            else if (trendBreakType == "FOR SELLS")
            {
                if (OBList[i].getMiddle() < OBList[j].getTop())
                {
                    OBList[i].setTop(lastDailyCandleLow);
                    OBList[i].setBottom(lastDailyCandleLow);
                    OBList[i].setMiddle(lastDailyCandleLow);
                }
            }
        }
    }

    // Delete all Obs that are out of the way
    int OBsRemoved = 0;
    double value = trendBreakType == "FOR BUYS" ? lastDailyCandleHigh : lastDailyCandleLow;
    for (int i = 0; i < OBCount; i++)
    {
        for (int j = 0; j < OBCount - OBsRemoved; j++)
        {
            if (OBList[j].getMiddle() == value)
            {
                ArrayRemove(OBList, j, 1);
                OBsRemoved += 1;
                break;
            }
        }
    }

    int closest = 0;
    if (OBCount - OBsRemoved > 0)
    {

        for (int i = 0; i < OBCount - OBsRemoved; i++)
        {
            if (trendBreakType == "FOR BUYS")
            {
                if (calculatePipDifference(OBList[i].getBottom(), fibPriceForBuys) < calculatePipDifference(OBList[closest].getBottom(), fibPriceForBuys))
                    closest = i;
            }
            else
            {
                if (calculatePipDifference(OBList[i].getTop(), fibPriceForSells) < calculatePipDifference(OBList[closest].getTop(), fibPriceForSells))
                    closest = i;
            }
        }
    }
    else
    {
        closest = -1;
    }

    if (OBCount - OBsRemoved > 0)
    {
        double minOBHeight = trendBreakType == "FOR BUYS" ? calculatePipDifference(fibRetracePrice(minHeight, lastDailyCandleHigh, 0.89), fibPriceForBuys) : calculatePipDifference(fibRetracePrice(maxHeight, lastDailyCandleLow, 0.89), fibPriceForSells)
        for (int i = 0; i < OBCount - OBsRemoved; i++)
        {
            if(OBList[i].getHeight() < minOBHeight)
                OBList[i].resize(minOBHeight - OBList[i].getHeight());
            OBList[i].draw(i);
        }
        tradePoints[0] = OBList[closest].getTop();
        tradePoints[1] = OBList[closest].getBottom();
    }




    ArrayFree(OBList);
    Alert(closest);
}

void trade()
{
    if (trendClassifier(trendCandles) == 0) // consolidation
    {
    }
    else if (trendClassifier(trendCandles) % 2 == 0 && trendBreak("TO DOWNSIDE")) // uptrend
    {
        lotSize = calculateLotSize(calculatePipDifference(fibPriceForSells, maxHeight));
        spread = calculatePipDifference(SymbolInfoDouble(NULL, SYMBOL_BID), SymbolInfoDouble(NULL, SYMBOL_ASK) /*_SPREAD*/);
        if (lotSize >= 0.01 && spread < 50)
        {
            trade.SellLimit(calculateLotSize(calculatePipDifference(fibPriceForSells, maxHeight)), fibPriceForSells, NULL, maxHeight, fibRetracePrice(maxHeight, lastDailyCandleLow, -0.27), ORDER_TIME_DAY, 0, NULL);
            checkAgain = false;
        }
    }
    else if (trendClassifier(trendCandles) % 2 != 0 && trendBreak("TO UPSIDE")) // downtrend
    {
        lotSize = calculateLotSize(calculatePipDifference(fibPriceForBuys, minHeight));
        spread = calculatePipDifference(SymbolInfoDouble(NULL, SYMBOL_BID), SymbolInfoDouble(NULL, SYMBOL_ASK) /*_SPREAD*/);
        if (lotSize >= 0.01 && spread < 50)
        {
            trade.BuyLimit(calculateLotSize(calculatePipDifference(fibPriceForBuys, minHeight)), fibPriceForBuys, NULL, minHeight, fibRetracePrice(minHeight, lastDailyCandleHigh, -0.27), ORDER_TIME_DAY, 0, NULL);
            checkAgain = false;
        }
    }
}

void checkForPartials()
{
    if (PositionsTotal())
    {
        for (int i = 0; i < PositionsTotal(); i++)
        {
            ulong posTicket = PositionGetTicket(i);

            if (PositionSelectByTicket(posTicket))
            {
                double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                double posSl = PositionGetDouble(POSITION_SL);
                double posCurrentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
                double posTp = PositionGetDouble(POSITION_TP);
                ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                double posLots = PositionGetDouble(POSITION_VOLUME);

                if (posType == POSITION_TYPE_BUY && posSl != posOpenPrice)
                {
                    if (posCurrentPrice >= fibRetracePrice(posSl, posOpenPrice, -3.67))
                    {
                        trade.PositionClosePartial(posTicket, NormalizeDouble(posLots / 2, 2));
                        trade.PositionModify(posTicket, posOpenPrice, posTp);
                    }
                    // modify order by closing half and moving sl to openPrice, set partialled to false
                }
                else if (posType == POSITION_TYPE_SELL && posSl != posOpenPrice)
                {
                    if (posCurrentPrice <= fibRetracePrice(posSl, posOpenPrice, -3.67))
                    {
                        trade.PositionClosePartial(posTicket, NormalizeDouble(posLots / 2, 2));
                        trade.PositionModify(posTicket, posOpenPrice, posTp);
                    }
                }
            }
        }
    }
}

// Extra functions that may be helpful for optimization in the future
// better implementation of peaksInMatchingOrder, more reusable.
bool highBeforeLow(int daysBeforeCurrent)
{
    MqlRates dayH1Candles;

    candleLength = CopyRates(NULL, PERIOD_H1, daysBeforeCurrent, 1, dayH1Candles);

    int dayHigh int dayLow;

    for (int i = 0; i < candleLength; i++)
    {
        if (dayH1Candles(i).high == iHigh(NULL, PERIOD_D1, daysBeforeCurrent))
            dayHigh = i;
        if (dayH1Candles(i).low == iLow(NULL, PERIOD_D1, daysBeforeCurrent))
            dayLow = i;
    }

    return (dayHigh < dayLow);
}

bool lowbeforeHigh(int daysBeforeCurrent)
{

    return (!highBeforeLow(daysBeforeCurrent));
}
