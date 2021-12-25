#property copyright "Ooreoluwa Fasawe"
#property link      "https://www.mql5.com"

extern double PERCENTAGE_RISK_PER_TRADE = 0.01;
double BALANCE =  AccountInfoDouble(ACCOUNT_BALANCE);

double calculatePriceDifference(double p1, double p2)
  {
   double priceDifference = p1 > p2 ? p1 - p2 : p2 - p1;
   
   return NormalizeDouble(priceDifference, _Digits);
  }

double calculatePipDifference(double p1, double p2)
  {
   double pipDifference = calculatePriceDifference(p1, p2) * pow(10, _Digits);

   return NormalizeDouble(pipDifference, 0);
  }

double calculateLotSize(double stopLossInPips) //currency with lower pip value should have a higher overall > 1 tick value and lower than eu/gu lotsize
{
    double maxMonetaryRisk = BALANCE * PERCENTAGE_RISK_PER_TRADE;
    double lotSizeVolume = maxMonetaryRisk / ((stopLossInPips + calculatePipDifference(SymbolInfoDouble(NULL, SYMBOL_BID), SymbolInfoDouble(NULL, SYMBOL_ASK) /*_SPREAD*/)) * SymbolInfoDouble(NULL, SYMBOL_TRADE_TICK_VALUE)) ;
    
    return NormalizeDouble(lotSizeVolume, 2);
}

double fibRetracePrice(double p1, double p2, double retracePercent)
{
    double pipAddition = NormalizeDouble(calculatePriceDifference(p1, p2) * retracePercent, _Digits);
    double priceAftRetrace = p2 > p1 ? p2 - pipAddition : p2 + pipAddition;

    return priceAftRetrace;
}

//to work on in future for security reasons to downsize and upsize apropriately
bool BadStreak()
{
    badStreakCheck = false;
    //for security
    /* 
    - Check the results of the last 5 trades and if they're all negative, 
    half the lotsize, else, if they're all positive, make the lotsize its 
    natural value if not already that value
    
    - Will need to have created Strategy code to do this
    */
    return badStreakCheck;
}