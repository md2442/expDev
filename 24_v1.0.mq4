//+------------------------------------------------------------------+
//|                                                          24_v1.0 |
//|                                                              MAD |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                           Описание                               |
//+------------------------------------------------------------------+
// Extremum () - возвращает индекс наибольшего/наименьшего найденного значения:
//    _symbol - текущее имя инструмента,
//    _tfPeriod - передаваемый тф
//    _mode 2 режима: 2 - поиск high, 3 - поиск Low, 
//    _shift - до куда искать(индекс бара)
//    _start - откуда искать(индекс бара)
//
// TrendBarsCount() - возвращает количество бар в тренде. Формализация тренда внутри функции
//    _countbars - количество бар для просмотра
//    _symbol - текущее имя инструмента
//    _tfPeriod - передаваемый тф
//    _mode 4 режима: 1 - upTrend, 2 - DownTrend, 11 - downTrend before upTrend, 22 - uptrend before downtrend
//    _shift - откуда искать(индекс бара)
//

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
datetime strStartTrade, strEndTrade;


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
//|                Объявление переменных для каналов                 |
//+------------------------------------------------------------------+
//-- up каналы
// массив для ЛТ
double LTBufferUpfd[], LTBufferUpfu[];
double qltUpfd, qltUpfu; 
// внутренние уровни
double pzUpfd, redUpfd, greenUpfd, yellowUpfd, grayUpfd, blueUpfd;
double pzUpfu, redUpfu, greenUpfu, yellowUpfu, grayUpfu, blueUpfu;
double resHUpfd, resultHUpfd, resLUpfd, resultLUpfd, res_cHUpfd, res_cLUpfd, res_tcHUpfd, res_tcLUpfd;
// индексы 
int iHUpfd, iLUpfd, tcH1Upfd, tcL1Upfd, tcH2Upfd, tcL2Upfd, mirvline5Upfd;
int iHUpfu, iLUpfu, tcH1Upfu, tcL1Upfu, tcH2Upfu, tcL2Upfu, mirvline5Upfu;
// время окончания звк и х1
datetime bzUpfd, zvkEndUpfd;

//-- down каналы
// массив для ЛТ
double LTBufferDnfu[], LTBufferDnfd[];
double qltDnfu, qltDnfd; 
// внутренние уровни
double pzDnfu, redDnfu, greenDnfu, yellowDnfu, grayDnfu, blueDnfu;
double pzDnfd, redDnfd, greenDnfd, yellowDnfd, grayDnfd, blueDnfd;
double resHDnfu, resultHDnfu, resLDnfu, resultLDnfu, res_cHDnfu, res_cLDnfu, res_tcHDnfu, res_tcLDnfu;
double resHDnfd, resultHDnfd, resLDnfd, resultLDnfd, res_cHDnfd, res_cLDnfd, res_tcHDnfd, res_tcLDnfd;
// индексы 
int iHDnfd, iLDnfd, tcH1Dnfd, tcL1Dnfd, tcH2Dnfd, tcL2Dnfd, mirvline5Dnfd;
int iHDnfu, iLDnfu, tcH1Dnfu, tcL1Dnfu, tcH2Dnfu, tcL2Dnfu, mirvline5Dnfu;
// время окончания звк и х1
datetime bzDnfd, zvkEndDnfd;

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
   
   strStartTrade = StringToTime(StartTrade);
   strEndTrade   = StringToTime(EndTrade);
// размер массива
   ArrayResize(LTBufferDnfd, 1000);
   ArrayResize(LTBufferDnfu, 1000);
   ArrayResize(LTBufferUpfd, 1000);
   ArrayResize(LTBufferUpfu, 1000);
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

// обновляем количество бар в тренде 1 раз за бар.
// предварительные рассчеты точек старшего ТФ
   if(tfTimeLastBar != iTime(symbol, tfPeriod, 0))
     {
      downCnt = TrendBarsCount(CountBars, symbol, tfPeriod, 2, 1);
      
      if(downCnt > 0)
      {
       // количество бар в левой части, начиная от хая
       upDownCnt       = TrendBarsCount(CountBars, symbol, tfPeriod, 22, downCnt+1);
       
       // индексы хай и левого лоу
       tfHighModBuyInd = Extremum(symbol, tfPeriod, 2, downCnt, 0);
       tfLowModBuyInd  = Extremum(symbol, tfPeriod, 3, upDownCnt, downCnt);
       
       // цены хай и левого лоу старшего тф
       tfHighModBuy    = iHigh(symbol, tfPeriod, tfHighModBuyInd);
       tfLowModBuy     = iLow(symbol, tfPeriod, tfLowModBuyInd);
      
       // время экстремумов старших тф
       tfTimeOpenDownTrend = TimeBarOpen(symbol, tfPeriod, tfHighModBuyInd);
       tfTimeOpenUpTrend   = TimeBarOpen(symbol, tfPeriod, tfLowModBuyInd);
      
      }
      
      tfTimeLastBar = iTime(symbol, tfPeriod, 0);
     }
     
// если тренд состоит из минимум 2-х бар (cnt > 0).
// основные рассчеты точек старшего ТФ с младшего
   if(downCnt > 0)
     {
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

      // время и цена последнего лоу младшего тф
      timeLowModeBuy   = TimeBarOpen(symbol, periodcurrent, lowModBuyInd);
      lowModBuy        = iLow(symbol, periodcurrent, lowModBuyInd);
     }

//++----------------------РАССЧЕТЫ КАНАЛОВ----------------------++
  if(CheckExtrems(1, lowModBuy, tfHighModBuy, tfLowModBuy, tfLowModBuyInd, tfHighModBuyInd, lowModBuyInd) )
  {
   // коэффициент наклона линии тренда
   qltUpfd = CalculateQlt(tfHighModBuy, tfLowModBuy, tfLowModBuyInd, tfHighModBuyInd);
   qltDnfd = CalculateQlt(tfHighModBuy, lowModBuy, tfHighModBuyInd, lowModBuyInd);
   
   // уравнение прямых ЛТ канала
   CalculateLT(1, LTBufferUpfd, tfLowModBuyInd, tfHighModBuyInd, tfLowModBuy, qltUpfd);
   CalculateLT(2, LTBufferDnfd, tfHighModBuyInd, lowModBuyInd, tfHighModBuy, qltDnfd);
   
   // индексы бар с максимальным хай/лоу относительно ЛТ
   iHUpfd = CalculateDiffMaxIndexLT(resultHUpfd, resHUpfd, tfLowModBuyInd, tfHighModBuyInd, LTBufferUpfd);
   iLUpfd = CalculateDiffMinIndexLT(resultLUpfd, resLUpfd, tfLowModBuyInd, tfHighModBuyInd, LTBufferUpfd);
   
   
   // рассчет дельты между ЛТ и макс. хай/лоу
   CalculateDelta(1, qltUpfd, res_cHUpfd, res_cLUpfd, res_tcHUpfd, res_tcLUpfd,
                  tcH1Upfd, tcH2Upfd, tcL1Upfd, tcL2Upfd, iHUpfd, iLUpfd,
                  tfLowModBuyInd, tfHighModBuyInd, mirvline5Upfd, bzUpfd, zvkEndUpfd, LTBufferUpfd);
   Comment("zvkEndUpfd " + zvkEndUpfd);                         
   // рассчет цен уровней
   CalculateLevels(1, grayUpfd, blueUpfd, yellowUpfd, redUpfd, greenUpfd, pzUpfd, tfLowModBuyInd,
                   tfHighModBuyInd, tcH1Upfd, tcL2Upfd, res_cHUpfd, res_cLUpfd, LTBufferUpfd);
   /*CalculateLevels(2, grayDnfd, blueDnfd, yellowDnfd, redDnfd, greenDnfd, pzDnfd, tfLowModBuyInd,
                   tfHighModBuyInd, tcH1Dnfd, tcL2Dnfd, res_cHDnfd, res_cLDnfd, LTBufferDnfd);*/
   
   //Print("УПЗ " + normalize(pzUpfd));
   //Print("Серый " + normalize(grayUpfd ));
   //Print("синий " + normalize(blueUpfd));
   //Print("желтый " + normalize(yellowUpfd));
   //Print("красный " + normalize(redUpfd));
   //Print("зеленый " + normalize(greenUpfd));
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
         if(Price(2, _symbol, _tfPeriod, i+1) > Price(2, _symbol, _tfPeriod, i+2) && Price(3, _symbol, _tfPeriod, i+1) > Price(3, _symbol, _tfPeriod, i+2))
            continue;
         if(i > 0 && Price(2, _symbol, _tfPeriod, i+1) < Price(2, _symbol, _tfPeriod, i+2) && Price(3, _symbol, _tfPeriod, i+1) > Price(3, _symbol, _tfPeriod, i+2))
            continue;
         else
            break;
        }
      // down trend clean
      if(_mode == 2)
        {
         if(Price(2, _symbol, _tfPeriod, i) < Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i) < Price(3, _symbol, _tfPeriod, i+1))
            continue;
         if(i > 0 && ((Price(2, _symbol, _tfPeriod, i) < Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i+1) > Price(3, _symbol, _tfPeriod, i+1)) ||
                      (Price(2, _symbol, _tfPeriod, i) < Price(2, _symbol, _tfPeriod, i+1))))
            continue;
         else
            break;
        }
      // up trend before down trend
      if(_mode == 22)
        {
         if((Price(2, _symbol, _tfPeriod, i)   > Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i)   < Price(3, _symbol, _tfPeriod, i+1)  &&
             Price(2, _symbol, _tfPeriod, i+1) > Price(2, _symbol, _tfPeriod, i+2) && Price(3, _symbol, _tfPeriod, i+1) > Price(3, _symbol, _tfPeriod, i+2)) ||
            (Price(2, _symbol, _tfPeriod, i)   > Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i)   > Price(3, _symbol, _tfPeriod, i+1)) ||
            (Price(2, _symbol, _tfPeriod, i)   > Price(2, _symbol, _tfPeriod, i+1)))
            continue;
         if(i > 0 && Price(2, _symbol, _tfPeriod, i) < Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i) > Price(3, _symbol, _tfPeriod, i+1))
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
//+------------------------------------------------------------------+

// Проверка условия расположения точек
bool CheckExtrems(int _mode, double _t1, double _t2, double _t3, int _ind1, int _ind2, int _ind3)
{
 if( _ind1 != 0 && _ind2 != 0 && _ind1 >_ind2 && _ind2 - _ind3 != 0 )
 {
  if( _mode==1 )
   if( _t1 < _t2 && _t1 > _t3 && _t2 > _t3  /*&& TimeCurrent() >= strStartTrade  && TimeCurrent() < StringToTime(EndTrade)*/ )
    return true;
  if( _mode== 2 )
   if( _t1 > _t2 && _t1 < _t3 && _t2 < _t3 /*&& TimeCurrent() >= SstrStartTrade  && TimeCurrent() < StringToTime(EndTrade)*/ )
    return true;
 }
 return false;
}
//+------------------------------------------------------------------+

//--- Рассчитать коэффициент наклона ЛТ
double CalculateQlt(double _t1, double _t2, int _t1ind, int _t2ind)
{
 return (_t1-_t2)/(_t1ind-_t2ind);
}
//+------------------------------------------------------------------+

//--- Рассчитать прямую ЛТ
void CalculateLT(int _mode, double &buffer[], int _ind1, int _ind2, double _ind1price, double _qlt)
{
 // уравнение прямой ЛТ ап канала
 if(_mode == 1)
  for( int sh = _ind1; sh >= _ind2; sh--)
   buffer[sh] = _ind1price + _qlt * (_ind1 - sh);
 // уравнение прямой ЛТ даун канала
 if(_mode == 2)
  for( int sh = _ind1; sh >= _ind2; sh--)
   buffer[sh] = _ind1price - _qlt * (_ind1 - sh);
}
//+------------------------------------------------------------------+

//--- Поиск баров с макс отклонениями от ЛТ
int CalculateDiffMaxIndexLT(double &_result, double &_res, int _t1ind, int _t2ind, double &buffer[])
{
 _result = 0;
 int _ie     = 0;
 int _sh  = _t1ind;
 // поиск бара с макс. хаем относительно ЛТ
 for(_result, _ie, _sh; _sh>=_t2ind; _sh--)
 {
  _res=High[_sh]-buffer[_sh];
  if(_res>=_result)
  {
   _result=_res;
   _ie=_sh;
  }
 }
 return _ie;
}
int CalculateDiffMinIndexLT(double &_result, double &_res, int _t1ind, int _t2ind, double &buffer[])
{
 _result = 0;
 int _ie     = 0;
 int _sh  = _t1ind;

 // поиск бара с макс. лоу относительно ЛТ
 for(_result, _ie, _sh; _sh>=_t2ind; _sh--)
 {
  _res=buffer[_sh]-Low[_sh];
  if(_res>=_result)
  {
   _result=_res;
   _ie=_sh;
   //Comment(_ie);
  }
 }
 return _ie;
}
//+------------------------------------------------------------------+

void CalculateDelta(int _mode, double _qlt, double &_resch, double &_rescl, double &_restch, double &_restcl, int &_tch1, int &_tch2,
                    int &_tcl1, int &_tcl2, int _ieh, int _iel, int _t1ind, int _t2ind, int &_mirvline, datetime &_bz, datetime &_zvkEnd, double &buffer[] )
{
 if(_mode==1)
 {
  _resch   = High[_ieh]-buffer[_ieh];           //дельта  м\д ЛТ и макс. хаем
  _restch  = _resch/_qlt;                       //за сколько баров ЛТ изенмтся на дельта
  _tch2    = _t1ind+NormalizeDouble(_restch,0); //номер бара где пересекутся уровень лоу Р2 и верхяя линия канала
  _tch1    = _t2ind+NormalizeDouble(_restch,0); //номер бара где пересекутся уровень хай Р1 и верхяя линия канала

  _rescl   = buffer[_iel]-Low[_iel];             //дельта  м\д ЛТ и мин. лоу
  _restcl  = _rescl/_qlt;                        //за сколько баров ЛТ изенмтся на дельта
  _tcl2    = _t1ind-NormalizeDouble(_restcl,0);  //номер бара где пересекутся уровень лоу Р2 и нижняя линия канала
  _tcl1    = _t2ind-NormalizeDouble(_restcl,0);  //номер бара где пересекутся уровень хай Р1 и нижняя линия канала
 
  _mirvline = 2*_tcl1-_tch2;                     //5. от tcL1 вправо на tcН2
 }
 
 if(_mode==2)
 {
  _resch   = High[_ieh]-buffer[_ieh];
  _restch  = _resch/_qlt;
  _tch2    = _t1ind-NormalizeDouble(_restch,0);
  _tch1    = _t2ind-NormalizeDouble(_restch,0);

  _rescl   = buffer[_iel]-Low[_iel];
  _restcl  = _rescl/_qlt;
  _tcl2    = _t1ind+NormalizeDouble(_restcl,0);
  _tcl1    = _t2ind+NormalizeDouble(_restcl,0);
 
  _mirvline = 2*_tcl1-_tcl2;
 }
  if(_tcl1 >= 0)
   _bz     = Time[_tcl1];
  else
   _bz     = Time[0]-_tcl1*Period()*60;

  if(_mirvline>=0)
   _zvkEnd = Time[_mirvline];
  else
   _zvkEnd = Time[0]-_mirvline*Period()*60;
}

//+------------------------------------------------------------------+
//--- Рассчет уровней
void CalculateLevels(int _mode, double &_gray, double &_blue, double &_yellow, double &_red, double &_green, double &_upz,
                     int _t1ind, int _t2ind, int _tch12, int _tcl12, double _resch, double _rescl, double &buffer[])
{
 if(_mode==1 && _t1ind < 1000 && _tcl12 < 1000 && _tch12 < 1000 && _t2ind < 1000) // проверки нужны чтобы не выходить за пределы массива
 {
  _gray   = Low[_t1ind] + _resch;
  _blue   = buffer[_tcl12];
  _yellow = buffer[_tcl12] + _resch;
  _red    = buffer[_tch12];
  _green  = buffer[_tch12] - _rescl;
  _upz    = High[_t2ind] - _rescl;
 }
 if(_mode==2 && _t1ind < 1000 && _tch12 < 1000 && _tch12 < 1000 && _t2ind < 1000)
 {
  _gray   = High[_t1ind] - _rescl;
  _blue   = buffer[_tch12];
  _yellow = buffer[_tch12] - _rescl;
  _red    = buffer[_tcl12];
  _green  = buffer[_tcl12] + _resch;
  _upz    = Low[_t2ind] + _resch;
 }
}