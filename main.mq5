#property copyright "Copyright 2021, Ooreoluwa Fasawe"
#property link      ""
#property version   "1.00"
#property strict

#include <tradingStrategyFunctions.mqh>

static datetime timeday = 0;

void OnInit()
{
    //Alert(AccountBalance());
}
void OnTick()
{
    //thinking set variable check again to true at beginning and then false in if statement that places trade also set to true on isNewDay()
    // Fixed:
    //- using actual pip value now
    //- Made sure all the candle lows or highs after the highest breakout stay above the 0.786 area- call it proper break
        //- Partialling functionality- change ultimate tp to 4.92, and partial tp to 3.67R(previous high or low), if trade completed successful, should net 4.3RR

    // Scheduled Improvements:
    //*Important and Urgent
    
    //*Important but not urgent
    //- Send messages to phone mt4 when pairs are beign looked at, limits are set, orders are opened, partials are taken and orders are closed
    //*Not important but urgent
    //*Not important nor urgent
    //- Different lotsizing for different trend strengths
    //- Account security by downsizing or upsizing based on win/lose streak

    //change ordersTotal to appropriate variable
    if(timeday!=iTime(NULL,PERIOD_D1,0))
    {
        checkAgain = true;
        timeday=iTime(NULL,PERIOD_D1,0);
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

void OnDeInit()
{
    //Alert(AccountBalance());
}

bool isTradingDay()
{
    MqlDateTime day;
    TimeToStruct(TimeCurrent(), day);
    if(day.day_of_week > 0 && day.day_of_week < 6)
        return true;
    else 
        return false;
}

//remember concept of max and min lotsize regardless of calculated lot
//No trade with more than a ** pip stop
//variable should be in main like this: if orderstotal() < maxtrradesatonce, trade, else, don't trade
//Day of week is important too