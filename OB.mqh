#property copyright "Ooreoluwa Fasawe"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <riskManagementFunctions.mqh>

class OB
  {
private:
   double            top;
   double            middle;
   double            bottom;
   double            height;
   datetime          time;
public:
                     OB();
                     OB(double t, double b, datetime blockTime);
                    ~OB();

   double            getTop();
   double            getMiddle();
   double            getBottom();
   double            getHeight();
   datetime          getTime();
   void              draw(int i);

  };

OB::OB()
  {
   top = 0;
   bottom = 0;
   middle = 0;
   height = 0;
   time = 0;
  }

OB::OB(double t, double b, datetime blockTime)
  {
   top =  t;
   bottom = b;
   middle = (t + b) / 2;
   height =  calculatePipDifference(t, b);
   time = blockTime;
  }

OB::~OB()
  {
  }


double OB::getTop()
  {
   return top;
  }


double OB::getMiddle()
  {
   return middle;
  }


double OB::getBottom()
  {
   return bottom;
  }


double OB::getHeight()
  {
   return height;
  }


datetime OB::getTime()
  {
   return time;
  }


void OB::draw(int i)
  {
   ObjectCreate(
      NULL,
      "OB" + string(i),
      OBJ_RECTANGLE,
      0,
      time,
      top,
      TimeCurrent(),
      bottom
   );
   
  }