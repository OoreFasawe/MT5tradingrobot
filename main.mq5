#property copyright "Copyright 2021, Ooreoluwa Fasawe"
#property link      ""
#property version   "1.00"
#property strict

#include <tradingStrategyFunctions.mqh>

static datetime timeday = 0;
static bool checkAgain = true;

void OnTick()
{
    if(timeday!=iTime(NULL,PERIOD_D1,0) + 21600)
    {
        checkAgain = true;
        timeday=iTime(NULL,PERIOD_D1,0) + 21600;
    }

    if(isTradingDay() && checkAgain)
    {
        if(OrdersTotal() + PositionsTotal() < 10)
        {
            trade();
        }
    }
        
    checkForPartials();
}

