//+------------------------------------------------------------------+
//|                                                          24_v1.0 |
//|                                                              MAD |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "MAD"
#property link      ""
#property version   "1.0"
#property strict


//Переключалки
enum selectTF
  {
   m5,  // м5
   m15, // м15
   m30  // м30
  };

enum EnumRiskMode
  {
   FixedLot,      // Фикс риск
   FixedCurrency, // Риск в деньгах
  };

enum EnumPosMode
  {
   Reaction, // Реакция
   JustLevel,// Наличие
  };

enum Levels
  {
   gray,   // Серый
   red,    // Красный
   blue,   // Синий
   yellow, // Желтый
   green   // Зеленый
  };

// Входные переменные
input string   ExpertOptions = "Настройка советника"; // -------------------------------------------------
input string      StartTrade = "09:00";               // Старт торговли
input string        EndTrade = "20:00";               // Конец торговли

selectTF input        TFMode = selectTF:: m15;        // Выбор ТФ старшего диапазона
input int          CountBars = 20;                    // Бар для поиска фракталов



//+------------------------------------------------------------------+
//|                Объявление переменных для советника               |
//+------------------------------------------------------------------+

//---
//текущий инструмент
string symbol;


//---
//период, цены OHLC, счетчик тренд-бар старшего канала
int tfPeriod;
int upCtn, downCnt, upDownCnt, downUpCnt;
double tfOpenModSell, tfCloseModSell, tfHighModSell, tfLowModSell, tfCurrHigh, tfCurrLow;
double tfOpenModBuy, tfCloseModBuy, tfHighModBuy, tfLowModBuy;
int tfHighModSellInd, tfLowModSellInd, tfHighModBuyInd, tfLowModBuyInd;

// время открытия бара старшего канала
datetime tfTimeOpenUpTrend, tfTimeOpenDownTrend, tfTimeLastBar;

//---
//текущее время на младщем тф
datetime currTimeUpTrend, currTimeDownTrend, timeLowModeBuy;
// индексы старших экстремумов с младших
int openUpTrendInd, openDownTrendInd;
// индекс младших экстремума
int lowModBuyInd;
// цена младшего экстремума
double lowModBuy;
// текущий период
int periodcurrent;

//+------------------------------------------------------------------+
//|                Объявление переменных для канала                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
// фиксация выбранного периода
   switch(TFMode)
     {
      case selectTF::m5:
         tfPeriod = PERIOD_M5;
      case selectTF::m15:
         tfPeriod = PERIOD_M15;
      case selectTF::m30:
         tfPeriod = PERIOD_M30;
      default:
         tfPeriod = PERIOD_M15;
     }

// фиксация инструмента
   symbol        = Symbol();
   periodcurrent = PERIOD_CURRENT;
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  //+------------------------------------------------------------------+
  //|                      Рассчеты для лонга                          |
  //+------------------------------------------------------------------+
  
   // обновляем количество бар в тренде 1 раз за бар 
   if( tfTimeLastBar != iTime(symbol, tfPeriod, 0) )
     {
      downCnt = TrendBarsCount(CountBars, symbol, tfPeriod, 2, 1);
      
      tfTimeLastBar = Time[0];
     }
   // если тренд состоит из минимум 2-х бар (cnt > 0)
   if( downCnt > 0 )
     {
      // количество бар в левой части, начиная от хая
      upDownCnt       = TrendBarsCount(CountBars, symbol, tfPeriod, 3, downCnt+1);
      
      // индексы хай и левого лоу от нуля до суммы бар в трендах
      tfHighModBuyInd = Extremum(symbol, tfPeriod, 2, downCnt, 0);
      tfLowModBuyInd  = Extremum(symbol, tfPeriod, 3, upDownCnt, downCnt);
      
      // цены хай и левого лоу старшего тф
      tfHighModBuy    = iHigh(symbol, tfPeriod, tfHighModBuyInd);
      tfLowModBuy     = iLow(symbol, tfPeriod, tfLowModBuyInd);
      
      // время экстремумов старших тф
      tfTimeOpenDownTrend = TimeBarOpen(symbol, tfPeriod, tfHighModBuyInd);
      tfTimeOpenUpTrend   = TimeBarOpen(symbol, tfPeriod, tfLowModBuyInd);
      
      // индексы старших точек с младших тф
      openDownTrendInd = iBarShift(symbol, periodcurrent, tfTimeOpenDownTrend);
      openUpTrendInd   = iBarShift(symbol, periodcurrent, tfTimeOpenUpTrend);
      
      // индекс последнего лоу с младшего тф
      lowModBuyInd     = Extremum(symbol, periodcurrent, 3, openDownTrendInd, 0);
      
      // переопределение индексов старших экстремумов с младшего тф
      tfHighModBuyInd  = Extremum(symbol, periodcurrent, 2, openDownTrendInd, 0);
      tfLowModBuyInd   = Extremum(symbol, periodcurrent, 3, openUpTrendInd, openDownTrendInd);
      
      // переопределение времени экстремумов старших тф
      tfTimeOpenDownTrend = TimeBarOpen(symbol, periodcurrent, tfHighModBuyInd);
      tfTimeOpenUpTrend   = TimeBarOpen(symbol, periodcurrent, tfLowModBuyInd);
      
      // время и цена последнего лоу с младшего тф
      timeLowModeBuy   = TimeBarOpen(symbol, periodcurrent, lowModBuyInd);
      lowModBuy        = iLow(symbol, periodcurrent, lowModBuyInd);
      
      Comment("Время лоу: " + tfTimeOpenUpTrend + " индекс: "+ tfLowModBuyInd + " цена: " + tfLowModBuy + 
              ";;;Время хай: " + tfTimeOpenDownTrend + " индекс: "+ tfHighModBuyInd +  ", цена:" + tfHighModBuy + 
              ";;;Время последнего лоу: " + timeLowModeBuy +  " индекс: "+ lowModBuyInd +  ", цена: " + lowModBuy);
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                  Функциональная часть советника                  |
//+------------------------------------------------------------------+
// Нормализировать цену
double normalize(double value)
  {
   return NormalizeDouble(value,_Digits);
  }
// Индексы экстремумов
int Extremum(string _symbol, int _tfPeriod, int _mode, int _shift, int _start)
  {
   if(_mode==2)
      return iHighest(_symbol, _tfPeriod, MODE_HIGH, _shift+1, _start);
   if(_mode==3)
      return iLowest(_symbol, _tfPeriod, MODE_LOW, _shift+1, _start);
   return 0;
  }

//+------------------------------------------------------------------+
// Количество бар в тренде
int TrendBarsCount(int _countbars, string _symbol, int _tfPeriod, int _mode, int _shift)
  {
   int i = _shift;
   for(i; i < _countbars; i++)
     {
      // up trend clean
      if(_mode == 1)
        {
         if( Price(2, _symbol, _tfPeriod, i+1) > Price(2, _symbol, _tfPeriod, i+2) && Price(3, _symbol, _tfPeriod, i+1) > Price(3, _symbol, _tfPeriod, i+2) )
            continue;
         if( i > 0 && Price(2, _symbol, _tfPeriod, i+1) < Price(2, _symbol, _tfPeriod, i+2) && Price(3, _symbol, _tfPeriod, i+1) > Price(3, _symbol, _tfPeriod, i+2) )
            continue;
         else
            break;
        }
      // down trend clean
      if(_mode == 2)
        {
         if( Price(2, _symbol, _tfPeriod, i) < Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i) < Price(3, _symbol, _tfPeriod, i+1) )
            continue;
         if( i > 0 && ((Price(2, _symbol, _tfPeriod, i) < Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i+1) > Price(3, _symbol, _tfPeriod, i+1)) ||
            (Price(2, _symbol, _tfPeriod, i) < Price(2, _symbol, _tfPeriod, i+1))) )
            continue;
         else
            break;
        }
      // up trend before down trend
      if(_mode == 3)
        {
         if( (Price(2, _symbol, _tfPeriod, i)   > Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i)   < Price(3, _symbol, _tfPeriod, i+1)  &&
              Price(2, _symbol, _tfPeriod, i+1) < Price(2, _symbol, _tfPeriod, i+2) && Price(3, _symbol, _tfPeriod, i+1) > Price(3, _symbol, _tfPeriod, i+2)) ||
             (Price(2, _symbol, _tfPeriod, i)   > Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i)   > Price(3, _symbol, _tfPeriod, i+1)) ||
             (Price(2, _symbol, _tfPeriod, i)   > Price(2, _symbol, _tfPeriod, i+1) ))
            continue;
         if( i > 0 && Price(2, _symbol, _tfPeriod, i) < Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i) > Price(3, _symbol, _tfPeriod, i+1))
            continue;
         else
            break;
        }
     }
   return i;
  }
//+------------------------------------------------------------------+
// Обновить цены
double Price(int _mode, string _symbol,int _period, int _shift)
  {
   RefreshRates();
   if(_mode == 1) // open
      return iOpen(_symbol, _period, _shift);
   if(_mode == 2) // high
      return iHigh(_symbol, _period, _shift);
   if(_mode == 3) // low
      return iLow(_symbol, _period, _shift);
   if(_mode == 4) // close
      return iClose(_symbol, _period, _shift);

   return 0;
  }
//+------------------------------------------------------------------+
// Время первого бара в тренде
datetime TimeBarOpen(string _symbol, int _tfperiod, int _shift)
{
   return iTime(_symbol, _tfperiod, _shift);
}
