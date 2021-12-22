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


    // Scheduled Improvements:
    //- Use actual pip value for stopLossInPips
    //- Partialling functionality
    //- Different lotsizing for different trend strengths
    //- Account security by downsizing or upsizing based on win/ lose streak
    //- forget trade if spread is greater than 10 pips/ need a way to set trades to check again later

    //change ordersTotal to appropriate variable
    if(timeday!=iTime(NULL,PERIOD_D1,0))
    {
        checkAgain = true;
        timeday=iTime(NULL,PERIOD_D1,0);
    }

    if(isTradingDay() && checkAgain)
        {
            if((OrdersTotal() + PositionsTotal()) < 10)
            {
                trade();
            }
        }
        


    if(PositionsTotal())
    {  
        //checkForPartials();


        //go through each order in orderstotal 
        //if trade is running
        //check if partials need to be taken or sl modified
        //check if full tp needs to be taken
        //do nothing if nothing needs to be done
    }
    
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