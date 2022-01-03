#property copyright "Ooreoluwa Fasawe"
#property link "https://www.mql5.com"
#property version "1.00"

#include <riskManagementFunctions.mqh>

class OB
{
private:
  double top;
  double middle;
  double bottom;
  double height;
  datetime time;

public:
  OB();
  OB(double t, double b, datetime blockTime);
  ~OB();

  double getTop();
  double getMiddle();
  double getBottom();
  double getHeight();
  datetime getTime();
  void setTop(double t);
  void setMiddle(double m);
  void setBottom(double b);
  void draw(int i);
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
  top = t;
  bottom = b;
  middle = (t + b) / 2;
  height = calculatePipDifference(t, b);
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

void OB::setTop(double t)
{
  top = t;
}

void OB::setMiddle(double m)
{
  middle = m;
}

void OB::setBottom(double b)
{
  bottom = b;
}

void OB::draw(int i)
{
  string name = "OB" + string(i);
  ObjectCreate(
      NULL,
      name,
      OBJ_RECTANGLE,
      0,
      time,
      top,
      TimeCurrent(),
      bottom);
  ObjectSetInteger(NULL, name, OBJPROP_COLOR, clrLightSkyBlue);
  ObjectSetInteger(NULL, name, OBJPROP_FILL, true);
  ObjectSetInteger(NULL, name, OBJPROP_SELECTABLE, true);
  ObjectSetInteger(NULL, name, OBJPROP_SELECTED, true);
  ObjectSetInteger(NULL, name, OBJPROP_HIDDEN, false);
}
}