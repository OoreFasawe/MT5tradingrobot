#property copyright "Copyright 2021, Ooreoluwa Fasawe"
#property link      ""
#property version   "1.00"
#property strict

#include <tradingStrategyFunctions.mqh>

static datetime timeday = 0;
static bool checkAgain = true;

void OnInit()
{
    //Alert(AccountBalance());
}
void OnTick()
{

    // Features added/ fixed:
    //- using actual pip value now
    //- Made sure all the candle lows or highs after the highest breakout stay above the 0.786 area- call it proper break
    //- Added partialling functionality- change ultimate tp to 4.92, and partial tp to 3.67R(previous high or low), if trade completed successful, should net 4.3RR
    //- Now sending messages to phone mt4 when pairs are being looked at, limits are set, orders are opened, partials are taken and orders are closed. Enable push notifications and Use SendNotification().
    //- Fixed EA to repeat after day is over
    //- make EA search two hours after market open to make sure spreads are in best shape when trades are searched for


    // Scheduled Improvements:
    //*Important and Urgent
    //*Important but not urgent
    //- Set-up vps so EA can run without terminal needing to be on
    //*Not important but urgent
    //*Not important nor urgent
    //- Different lotsizing for different trend strengths
    //- Account security by downsizing or upsizing based on win/lose streak


//note: we want it to reset at the start of the trader server day and not our time, EA was using wrong time settings for the timeday function. Although
// timelocal works just fine for other parts of the code, perhaps they ofset it automatically when used as paramters but not by themselves.

//Just remember to change offset when travelling across cities/states or figure out how to get an offset so you don't need to change
    if(timeday!=iTime(NULL,PERIOD_D1,0) + 36000)
    {
        checkAgain = true;
        timeday=iTime(NULL,PERIOD_D1,0) + 36000;
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

//remember concept of max and min lotsize regardless of calculated lot
//No trade with more than a ** pip stop
//variable should be in main like this: if orderstotal() < maxtrradesatonce, trade, else, don't trade
//Day of week is important too