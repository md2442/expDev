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
   green,  // Зеленый
   anylevel// Любой
  };
  
enum LevelsInPZ
  {
   grayPZ,   // Серый
   redPZ,    // Красный
   bluePZ,   // Синий
   yellowPZ, // Желтый
   greenPZ,  // Зеленый
   any       // Любой
  };

// Входные переменные
input string   ExpertOptions = "Настройка советника";       // -------------------------------------------------
input string      StartTrade = "09:00";                     // Старт торговли
input string        EndTrade = "20:00";                     // Конец торговли
input string   ChanelOptions = "Настройка диапазонов";      // -------------------------------------------------
input int          CountBars = 20;                          // Бар для поиска фракталов
input int      BarsCountLeft = 2;                           // Минимум бар в левом тренде

selectTF     input TFMode    = selectTF:: m15;              // Выбор ТФ старшего диапазона
EnumPosMode  input PosMode   = EnumPosMode::JustLevel;      // Режим для отксока
input bool   useOneLevel     = false;                       // Использовать 1 уровень для отскока. Если не выбран - то любой
Levels       input Level     = Levels::anylevel;            // Если использовать 1 уровень, то выберите уровень
input bool   usemaxlevel     = false;                       // Или выбрать максимальный уровень канала?
input bool   useGraymax      = false;                       // true  - серый, false - любой
input bool   useGraymaxZgut  = false;                       // true - жгут уровней, false - без жгута
input bool   useLevelInPz    = false;                       // Проверять наличие уровня младшего в ПЗ
LevelsInPZ   input PZMode    = LevelsInPZ::any;             // Укажите уровень
input bool   exceptLevel     = false;                       // Исключить проверку уровня в ПЗ

input string RiskOptions     = "Риск";                      // -------------------------------------------------
input int    tostop          = 40;                          // Достопа не менее
input double stopover        = 0.00005;                     // Добавлять к стопу
input bool   tAStoploss      = false;                       // Ставить стоп за т.А старшего канала
input bool   tAclosePos      = false;                       // Закрывать позицию на т.А младшего канала
input bool   zvkendsh        = false;                       // Закрывать по звк
input bool   ifuseGraymax    = false;                       // Закрывать на УПЗ, который пробили, если торговля от серого
input string MMOptions       = "ММ";                        // -------------------------------------------------
EnumRiskMode input RiskMode  = EnumRiskMode::FixedCurrency; // Режим риска
input double RiskValue       = 10;                          // Риск в деньгах


input int    Magic           = 12345;                       // Мэгик



//+------------------------------------------------------------------+
//|                Объявление переменных для советника               |
//+------------------------------------------------------------------+

//---
//текущий инструмент
string symbol;
datetime strStartTrade, strEndTrade;
int firstVisBar;
double tickSize, marginInit;
int Slippage = 10; // проскальзывание

//---
//период, цены OHLC, счетчик тренд-бар старшего канала
int tfPeriod;
int upCnt, downCnt, upDownCnt, downUpCnt;
double tfOpenModSell, tfCloseModSell, tfHighModSell, tfLowModSell, tfCurrHigh, tfCurrLow;
double tfOpenModBuy, tfCloseModBuy, tfHighModBuy, tfLowModBuy;
int tfHighModSellInd, tfLowModSellInd, tfHighModBuyInd, tfLowModBuyInd;

// время открытия бара старшего канала
datetime tfTimeOpenUpTrend, tfTimeOpenDownTrend, tfTimeLastBar;
datetime tfTimeOpenUpTrendSell, tfTimeOpenDownTrendSell, tfTimeLastBarSell;

//---
//текущее время на младщем тф
datetime currTimeUpTrend, currTimeDownTrend, timeLowModeBuy, timeHighModeSell;
// индексы старших экстремумов с младших
int openUpTrendInd, openDownTrendInd;
int openUpTrendIndSell, openDownTrendIndSell;
// индекс младших экстремума
int lowModBuyInd, highModSellInd;
// цена младшего экстремума
double lowModBuy, highModSell;
// текущий период
int periodcurrent;
// текущая цена
double currprice;

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
double resHUpfu, resultHUpfu, resLUpfu, resultLUpfu, res_cHUpfu, res_cLUpfu, res_tcHUpfu, res_tcLUpfu;

// индексы 
int iHUpfd, iLUpfd, tcH1Upfd, tcL1Upfd, tcH2Upfd, tcL2Upfd, mirvline5Upfd, mirvline5Upfd2;
int iHUpfu, iLUpfu, tcH1Upfu, tcL1Upfu, tcH2Upfu, tcL2Upfu, mirvline5Upfu, mirvline5Upfu2;
// время окончания звк и х1
datetime bzUpfd, bzUpfdx2, zvkEndUpfd, bzFixTimeUpfd, zvkEndFixTimeUpfd;
datetime bzUpfu, bzUpfux2, zvkEndUpfu, bzFixTimeUpfu, zvkEndFixTimeUpfu;
double stoppriceUpfu;

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
int iHDnfd, iLDnfd, tcH1Dnfd, tcL1Dnfd, tcH2Dnfd, tcL2Dnfd, mirvline5Dnfd, mirvline5Dnfd2;
int iHDnfu, iLDnfu, tcH1Dnfu, tcL1Dnfu, tcH2Dnfu, tcL2Dnfu, mirvline5Dnfu, mirvline5Dnfu2;
// время окончания звк и х1
datetime bzDnfd, bzDnfdx2, zvkEndDnfd, bzFixTimeDnfd, zvkEndFixTimeDnfd;
datetime bzDnfu, bzDnfux2, zvkEndDnfu, bzFixTimeDnfu, zvkEndFixTimeDnfu;
double stoppriceDnfd;

double maxvaluelevel, minvaluelevel;

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
         break;
      case selectTF::m15:
         tfPeriod = PERIOD_M15;
         break;
      case selectTF::m30:
         tfPeriod = PERIOD_M30;
         break;
      default:
         tfPeriod = PERIOD_M15;
         break;
     }

// фиксация инструмента
   symbol        = Symbol();                           // символьное имя инструмента
   periodcurrent = PERIOD_CURRENT;                     // фиксация текущего периода
   tickSize      = MarketInfo(Symbol(),MODE_TICKSIZE); // размер тика
   strStartTrade = StringToTime(StartTrade);           // старт торговли в datetime
   strEndTrade   = StringToTime(EndTrade);             // конец торговли в datetime
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
   currprice = Close[0];
   firstVisBar = WindowFirstVisibleBar();
   
//+------------------------------------------------------------------+
//|                      Рассчеты для лонга                          |
//+↓↓↓↓----------------------------------------------------------↓↓↓↓+
// обновляем количество бар в тренде 1 раз за бар.
// предварительные рассчеты точек старшего ТФ
   if(tfTimeLastBar != Time[0])
     {
      downCnt = 0;
      upDownCnt = 0;
      downCnt = TrendBarsCount(CountBars, symbol, tfPeriod, 2, 1);
      
      if(downCnt > 0)
      {
       // количество бар в левой части, начиная от хая
       upDownCnt       = TrendBarsCount(CountBars, symbol, tfPeriod, 22, downCnt) - downCnt;
       
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
      tfTimeLastBar = Time[0];
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

//↑↑Рассчеты для лонга↑↑-----------Рассчеты каналов-----------//
  if(CheckExtrems(1, lowModBuy, tfHighModBuy, tfLowModBuy, tfLowModBuyInd, tfHighModBuyInd, lowModBuyInd))
  {
   // коэффициент наклона линии тренда
   qltUpfd = CalculateQlt(tfHighModBuy, tfLowModBuy, tfLowModBuyInd, tfHighModBuyInd);
   qltDnfd = CalculateQlt(tfHighModBuy, lowModBuy, tfHighModBuyInd, lowModBuyInd);
   
   // уравнение прямых ЛТ канала
   CalculateLT(1, LTBufferUpfd, tfLowModBuyInd, tfHighModBuyInd, tfLowModBuy, qltUpfd);
   CalculateLT(2, LTBufferDnfd, tfHighModBuyInd, lowModBuyInd, tfHighModBuy, qltDnfd);
   
   // индексы бар ап канала с максимальным хай/лоу относительно ЛТ
   iHUpfd = CalculateDiffMaxIndexLT(resultHUpfd, resHUpfd, tfLowModBuyInd, tfHighModBuyInd, LTBufferUpfd);
   iLUpfd = CalculateDiffMinIndexLT(resultLUpfd, resLUpfd, tfLowModBuyInd, tfHighModBuyInd, LTBufferUpfd);
   
   // индексы бар даун канала с максимальным хай/лоу относительно ЛТ
   iHDnfd = CalculateDiffMaxIndexLT(resultHDnfd, resHDnfd, tfHighModBuyInd, lowModBuyInd, LTBufferDnfd);
   iLDnfd = CalculateDiffMinIndexLT(resultLDnfd, resLDnfd, tfHighModBuyInd, lowModBuyInd, LTBufferDnfd);
   
   // рассчет дельты между ЛТ и макс. хай/лоу
   CalculateDelta(1, qltUpfd, res_cHUpfd, res_cLUpfd, res_tcHUpfd, res_tcLUpfd,
                  tcH1Upfd, tcH2Upfd, tcL1Upfd, tcL2Upfd, iHUpfd, iLUpfd,
                  tfLowModBuyInd, tfHighModBuyInd, mirvline5Upfd, mirvline5Upfd2, bzUpfd, bzUpfdx2, zvkEndUpfd, LTBufferUpfd);
   CalculateDelta(2, qltDnfd, res_cHDnfd, res_cLDnfd, res_tcHDnfd, res_tcLDnfd,
                  tcH1Dnfd, tcH2Dnfd, tcL1Dnfd, tcL2Dnfd, iHDnfd, iLDnfd,
                  lowModBuyInd, tfHighModBuyInd, mirvline5Dnfd, mirvline5Dnfd2, bzDnfd, bzDnfdx2, zvkEndDnfd, LTBufferDnfd);
                  
   // рассчет цен уровней
   CalculateLevels(1, grayUpfd, blueUpfd, yellowUpfd, redUpfd, greenUpfd, pzUpfd, tfLowModBuyInd,
                   tfHighModBuyInd, tcH1Upfd, tcL2Upfd, res_cHUpfd, res_cLUpfd, LTBufferUpfd);
   CalculateLevels(2, grayDnfd, blueDnfd, yellowDnfd, redDnfd, greenDnfd, pzDnfd, tfHighModBuyInd,
                   lowModBuyInd, tcH1Dnfd, tcL2Dnfd, res_cHDnfd, res_cLDnfd, LTBufferDnfd);
   
//↑↑Рассчеты каналов↑↑-----------Проверка условий и отправка ордера-----------//
   if(ReactOrLevel(1, grayUpfd, greenUpfd, yellowUpfd, redUpfd, blueUpfd,
      grayDnfd, greenDnfd, yellowDnfd, redDnfd, blueDnfd, pzUpfd, pzDnfd, lowModBuyInd, bzDnfd, bzUpfdx2, zvkEndUpfd, zvkEndDnfd) 
      && OrdersCount(OP_BUYSTOP) == 0 && OrdersCount(OP_BUY) == 0 && lowModBuyInd > 0 && lowModBuyInd <= 2 && downCnt > 1 && upDownCnt > BarsCountLeft)
   {
   
    //Print("УПЗ " + normalize(pzDnfd));
    //Print("СЛ " + normalize(lowModBuy - stopover));
    //Print("ТП: " + normalize(tfHighModBuy));
    //Print("Серый " + normalize(grayUpfd ));
    //Print("синий " + normalize(blueUpfd));
    //Print("желтый " + normalize(yellowUpfd));
    //Print("красный " + normalize(redUpfd));
    //Print("зеленый " + normalize(greenUpfd));
    if(zvkendsh)
    {
     if(tAclosePos){
      ProcessRiscCalc("BuyStop", normalize(pzDnfd), tAStoploss ? normalize(tfLowModBuy) : normalize(lowModBuy - stopover),
                       normalize(tfHighModBuy), 0, Magic, "");
      }
     if(ifuseGraymax){ // закрывать позицию на УПЗ старшего канала, при торговле от серого
      ProcessRiscCalc("BuyStop", normalize(pzDnfd), tAStoploss ? normalize(tfLowModBuy) : normalize(lowModBuy - stopover),
                       normalize(pzUpfd), 0, Magic, "");
      }
      
      ProcessRiscCalc("BuyStop", normalize(pzDnfd), tAStoploss ? normalize(tfLowModBuy) : normalize(lowModBuy - stopover),
                     normalize(tfHighModBuy*3), 0, Magic, "");
      bzFixTimeDnfd = bzDnfd;
      zvkEndFixTimeDnfd = zvkEndDnfd;
      stoppriceDnfd = normalize(lowModBuy);
    }  
   }
  }

   // удалить ордер, если цена обновила т.Б или не дошла до УПЗ за х1
   if(OrdersCount(OP_BUYSTOP) > 0 && (currprice < stoppriceDnfd || Time[0] > bzFixTimeDnfd /*|| lowModBuyInd > 2*/))
    DeleteOrder(OP_BUYSTOP);
   
   // закрыть позицию по окончанию ЗВК
   if(OrdersCount(OP_BUY) > 0 && Time[0] > zvkEndFixTimeDnfd )
    CloseAll(OP_BUY);
//+------------------------------------------------------------------+
//|                      Конец рассчетов лонг                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                      Рассчеты для шорта                          |
//+↓↓↓↓----------------------------------------------------------↓↓↓↓+
// обновляем количество бар в тренде 1 раз за бар.
// предварительные рассчеты точек старшего ТФ
   if(tfTimeLastBarSell != Time[0])
     {
      upCnt = 0;
      downUpCnt = 0;
      upCnt = TrendBarsCount(CountBars, symbol, tfPeriod, 1, 1);
      
      if(upCnt > 0)
      {
       // количество бар в левой части, начиная от лоу
       downUpCnt = TrendBarsCount(CountBars, symbol, tfPeriod, 11, upCnt) - upCnt;
       
       // индексы лоу и левого хай
       tfLowModSellInd  = Extremum(symbol, tfPeriod, 3, upCnt, 0);
       tfHighModSellInd = Extremum(symbol, tfPeriod, 2, downUpCnt, upCnt);
       
       // цены лоу и левого хай старшего тф
       tfLowModSell  = iLow(symbol, tfPeriod, tfLowModSellInd);
       tfHighModSell = iHigh(symbol, tfPeriod, tfHighModSellInd);
      
       // время экстремумов старших тф
       tfTimeOpenUpTrendSell   = TimeBarOpen(symbol, tfPeriod, tfLowModSellInd);
       tfTimeOpenDownTrendSell = TimeBarOpen(symbol, tfPeriod, tfHighModSellInd);
      }
      tfTimeLastBarSell = Time[0];
     }
// если тренд состоит из минимум 2-х бар (cnt > 0).
// основные рассчеты точек старшего ТФ с младшего
   if(upCnt > 0)
     {
      //Comment(upCnt + " " +  downUpCnt);
      // индексы старших точек с младших тф
      openUpTrendIndSell   = iBarShift(symbol, periodcurrent, tfTimeOpenUpTrendSell);
      openDownTrendIndSell = iBarShift(symbol, periodcurrent, tfTimeOpenDownTrendSell);

      // индекс последнего хай с младшего тф
      highModSellInd = Extremum(symbol, periodcurrent, 2, openUpTrendIndSell, 0);

      // переопределение индексов старших экстремумов с младшего тф
      tfLowModSellInd  = Extremum(symbol, periodcurrent, 3, openUpTrendIndSell, highModSellInd);
      tfHighModSellInd = Extremum(symbol, periodcurrent, 2, openDownTrendIndSell, openUpTrendIndSell);

      // переопределение времени экстремумов старших тф
      tfTimeOpenUpTrendSell   = TimeBarOpen(symbol, periodcurrent, tfLowModSellInd);
      tfTimeOpenDownTrendSell = TimeBarOpen(symbol, periodcurrent, tfHighModSellInd);

      // время и цена последнего хай младшего тф
      timeHighModeSell = TimeBarOpen(symbol, periodcurrent, highModSellInd);
      highModSell      = iHigh(symbol, periodcurrent, highModSellInd);
     }

//↑↑Рассчеты для шорта↑↑-----------Рассчеты каналов-----------//
  if(CheckExtrems(2, highModSell, tfLowModSell, tfHighModSell, tfHighModSellInd, tfLowModSellInd, lowModBuyInd))
  {
   
   // коэффициент наклона линии тренда
   qltDnfu = CalculateQlt(tfHighModSell, tfLowModSell, tfHighModSellInd, tfLowModSellInd);
   qltUpfu = CalculateQlt(highModSell, tfLowModSell, tfLowModSellInd, highModSellInd);
   
   // уравнение прямых ЛТ канала
   CalculateLT(1, LTBufferUpfu, tfLowModSellInd, highModSellInd, tfLowModSell, qltUpfu);
   CalculateLT(2, LTBufferDnfu, tfHighModSellInd, tfLowModSellInd, tfHighModSell, qltDnfu);
   
   // индексы бар ап канала с максимальным хай/лоу относительно ЛТ
   iHUpfu = CalculateDiffMaxIndexLT(resultHUpfu, resHUpfu, tfLowModSellInd, highModSellInd, LTBufferUpfu);
   iLUpfu = CalculateDiffMinIndexLT(resultLUpfu, resLUpfu, tfLowModSellInd, highModSellInd, LTBufferUpfu);

   // индексы бар даун канала с максимальным хай/лоу относительно ЛТ
   iHDnfu = CalculateDiffMaxIndexLT(resultHDnfu, resHDnfu, tfHighModSellInd, tfLowModSellInd, LTBufferDnfu);
   iLDnfu = CalculateDiffMinIndexLT(resultLDnfu, resLDnfu, tfHighModSellInd, tfLowModSellInd, LTBufferDnfu);
   
   Comment(iHDnfu + " " + iLDnfu);
   // рассчет дельты между ЛТ и макс. хай/лоу
   CalculateDelta(1, qltUpfu, res_cHUpfu, res_cLUpfu, res_tcHUpfu, res_tcLUpfu,
                  tcH1Upfu, tcH2Upfu, tcL1Upfu, tcL2Upfu, iHUpfu, iLUpfu,
                  tfLowModSellInd, highModSellInd, mirvline5Upfu, mirvline5Upfu2, bzUpfu, bzUpfux2, zvkEndUpfu, LTBufferUpfu);
   CalculateDelta(2, qltDnfu, res_cHDnfu, res_cLDnfu, res_tcHDnfu, res_tcLDnfu,
                  tcH1Dnfu, tcH2Dnfu, tcL1Dnfu, tcL2Dnfu, iHDnfu, iLDnfu,
                  tfLowModSellInd, tfHighModSellInd, mirvline5Dnfu, mirvline5Dnfu2, bzDnfu, bzDnfux2, zvkEndDnfu, LTBufferDnfu);
                 
   // рассчет цен уровней
   CalculateLevels(1, grayUpfu, blueUpfu, yellowUpfu, redUpfu, greenUpfu, pzUpfu, tfLowModSellInd,
                   highModSellInd, tcH1Upfu, tcL2Upfu, res_cHUpfu, res_cLUpfu, LTBufferUpfu);
   CalculateLevels(2, grayDnfu, blueDnfu, yellowDnfu, redDnfu, greenDnfu, pzDnfu, tfHighModSellInd,
                   tfLowModSellInd, tcH1Dnfu, tcL2Dnfu, res_cHDnfu, res_cLDnfu, LTBufferDnfu);
                   

//↑↑Рассчеты каналов↑↑-----------Проверка условий и отправка ордера-----------//
   if(ReactOrLevel(2, grayDnfu, greenDnfu, yellowDnfu, redDnfu, blueDnfu,
      grayUpfu, greenUpfu, yellowUpfu, redUpfu, blueUpfu, pzDnfu, pzUpfu, highModSellInd, bzUpfu, bzDnfux2, zvkEndDnfu, zvkEndUpfu) 
      && OrdersCount(OP_SELLSTOP) == 0 && OrdersCount(OP_SELL) == 0 && highModSellInd > 0 && highModSellInd <= 2 && upCnt > 1 && downUpCnt > BarsCountLeft)
   {
   
    //Print("УПЗ " + normalize(pzDnfd));
    //Print("СЛ " + normalize(highModSell - stopover));
    //Print("ТП: " + normalize(tfLowModSell));
    //Print("Серый " + normalize(grayUpfd ));
    //Print("синий " + normalize(blueUpfd));
    //Print("желтый " + normalize(yellowUpfd));
    //Print("красный " + normalize(redUpfd));
    //Print("зеленый " + normalize(greenUpfd));
    if(zvkendsh)
    {
     if(tAclosePos){
      ProcessRiscCalc("SellStop", normalize(pzUpfu), tAStoploss ? normalize(tfHighModSell) : normalize(highModSell - stopover),
                       normalize(tfLowModSell), 0, Magic, "");
      }
     if(ifuseGraymax){ // закрывать позицию на УПЗ старшего канала, при торговле от серого
      ProcessRiscCalc("SellStop", normalize(pzDnfd), tAStoploss ? normalize(tfHighModSell) : normalize(highModSell - stopover),
                       normalize(pzUpfd), 0, Magic, "");
      }
      
      ProcessRiscCalc("SellStop", normalize(pzDnfd), tAStoploss ? normalize(tfHighModSell) : normalize(highModSell - stopover),
                     normalize(tfLowModSell*3), 0, Magic, "");
      bzFixTimeUpfu = bzUpfu;
      zvkEndFixTimeUpfu = zvkEndUpfu;
      stoppriceUpfu = normalize(highModSell);
    }  
   }
  }

   // удалить ордер, если цена обновила т.Б или не дошла до УПЗ за х1
   if(OrdersCount(OP_SELLSTOP) > 0 && (currprice > stoppriceUpfu || Time[0] > bzFixTimeUpfu /*|| lowModBuyInd > 2*/))
    DeleteOrder(OP_SELLSTOP);
   
   // закрыть позицию по окончанию ЗВК
   if(OrdersCount(OP_SELL) > 0 && Time[0] > zvkEndFixTimeUpfu )
    CloseAll(OP_SELL);

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|              Функциональная часть советника, каналы              |
//+------------------------------------------------------------------+
//--- Индексы экстремумов
int Extremum(string _symbol, int _tfPeriod, int _mode, int _shift, int _start)
  {
   if(_mode==2)
      return iHighest(_symbol, _tfPeriod, MODE_HIGH, _shift+1, _start);
   if(_mode==3)
      return iLowest(_symbol, _tfPeriod, MODE_LOW, _shift+1, _start);
   return 0;
  }

//+------------------------------------------------------------------+
//--- Количество бар в тренде
int TrendBarsCount(int _countbars, string _symbol, int _tfPeriod, int _mode, int _shift)
  {
   int i = _shift;
   for(i; i < _countbars; i++)
     {
      // up trend clean
      if(_mode == 1)
        {
         if(Price(2, _symbol, _tfPeriod, i) > Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i) > Price(3, _symbol, _tfPeriod, i+1))
            continue;
         if(i > 0 && Price(2, _symbol, _tfPeriod, i) < Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i) > Price(3, _symbol, _tfPeriod, i+1))
            continue;
         else
            break;
        }
      // down trend before up trend
      if(_mode == 11)
        {
         if((Price(2, _symbol, _tfPeriod, i)   < Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i)   > Price(3, _symbol, _tfPeriod, i+1)  &&
             Price(2, _symbol, _tfPeriod, i+1) < Price(2, _symbol, _tfPeriod, i+2) && Price(3, _symbol, _tfPeriod, i+1) < Price(3, _symbol, _tfPeriod, i+2)) ||
            (Price(2, _symbol, _tfPeriod, i)   < Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i)   < Price(3, _symbol, _tfPeriod, i+1)) ||
            (Price(2, _symbol, _tfPeriod, i)   < Price(2, _symbol, _tfPeriod, i+1)))
            continue;
         if(i > 0 && Price(2, _symbol, _tfPeriod, i) > Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i) < Price(3, _symbol, _tfPeriod, i+1))
            continue;
         else
            break;
        }
      // down trend clean
      if(_mode == 2)
        {
         if(Price(2, _symbol, _tfPeriod, i) < Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i) < Price(3, _symbol, _tfPeriod, i+1))
            continue;
         if(i > 0 && ((Price(2, _symbol, _tfPeriod, i) < Price(2, _symbol, _tfPeriod, i+1) && Price(3, _symbol, _tfPeriod, i) > Price(3, _symbol, _tfPeriod, i+1)) ||
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

//--- Обновить цены
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

//--- Время первого бара в тренде
datetime TimeBarOpen(string _symbol, int _tfperiod, int _shift)
  {
   return iTime(_symbol, _tfperiod, _shift);
  }
//+------------------------------------------------------------------+

//--- Проверка условия расположения точек
bool CheckExtrems(int _mode, double _t1, double _t2, double _t3, int _ind1, int _ind2, int _ind3)
{
 if( _ind1 != 0 && _ind2 != 0 && _ind1 >_ind2 && _ind2 - _ind3 != 0 )
 {
  if( _mode==1 )
   if( _t1 < _t2 && _t1 > _t3 && _t2 > _t3  && TimeCurrent() >= StringToTime(StartTrade)  && TimeCurrent() < StringToTime(EndTrade) )
    return true;
  if( _mode== 2 )
   if( _t1 > _t2 && _t1 < _t3 && _t2 < _t3 && TimeCurrent() >= StringToTime(StartTrade)  && TimeCurrent() < StringToTime(EndTrade ) )
    return true;
 }
 return false;
}
//+------------------------------------------------------------------+

//--- Рассчитать коэффициент наклона ЛТ
double CalculateQlt(double _t1, double _t2, int _t1ind, int _t2ind) //tfLowModSell, tfHighModSell, tfHighModSellInd, tfLowModSellInd
{
 return _t1ind-_t2ind != 0 ? (_t1-_t2)/(_t1ind-_t2ind) : 55555;
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
  }
 }
 return _ie;
}
//+------------------------------------------------------------------+

void CalculateDelta(int _mode, double _qlt, double &_resch, double &_rescl, double &_restch, double &_restcl, int &_tch1, int &_tch2,
                    int &_tcl1, int &_tcl2, int _ieh, int _iel, int _t1ind, int _t2ind, int &_mirvline1, int &_mirvline2, datetime &_bz, datetime &_bz2, datetime &_zvkEnd, double &buffer[] )
{
 if(_mode==1) // ап канал
 {
  _resch   = High[_ieh]-buffer[_ieh];           //дельта  м\д ЛТ и макс. хаем
  _restch  = _resch/_qlt;                       //за сколько баров ЛТ изенмтся на дельта
  _tch2    = _t1ind+NormalizeDouble(_restch,0); //номер бара где пересекутся уровень лоу Р2 и верхяя линия канала
  _tch1    = _t2ind+NormalizeDouble(_restch,0); //номер бара где пересекутся уровень хай Р1 и верхяя линия канала

  _rescl   = buffer[_iel]-Low[_iel];             //дельта  м\д ЛТ и мин. лоу
  _restcl  = _rescl/_qlt;                        //за сколько баров ЛТ изенмтся на дельта
  _tcl2    = _t1ind-NormalizeDouble(_restcl,0);  //номер бара где пересекутся уровень лоу Р2 и нижняя линия канала
  _tcl1    = _t2ind-NormalizeDouble(_restcl,0);  //номер бара где пересекутся уровень хай Р1 и нижняя линия канала
 
  _mirvline1 = 2*_tcl1-_tch2;                     //5. от tcL1 вправо на tcН2
  _mirvline2 = 2*_tcl1-_t2ind;
 }
 
 if(_mode==2) // даун канал
 {
  _resch   = High[_ieh]-buffer[_ieh];
  _restch  = _resch/_qlt;
  _tch2    = _t1ind-NormalizeDouble(_restch,0);
  _tch1    = _t2ind-NormalizeDouble(_restch,0);

  _rescl   = buffer[_iel]-Low[_iel];
  _restcl  = _rescl/_qlt;
  _tcl2    = _t1ind+NormalizeDouble(_restcl,0);
  _tcl1    = _t2ind+NormalizeDouble(_restcl,0);
 
  _mirvline1 = 2*_tch2-_tcl1;
  _mirvline2 = 2*_tch2-_t2ind;
 }
  
  //Print("mode: " + _mode + ", tch2: " + _tch2 + ", tch1: " + _tch1 + ", tcl2: " + _tcl2 + ", tcl1: " + _tcl1 + ", mirvline 1: "+ _mirvline1 + ", mirvline2: "  + _mirvline2);
  if(((_tcl1 >= 0 && _mode== 1) || (_mode==2 && _tch2 >=0 )) && _tcl1 < firstVisBar && _tch2 < firstVisBar && _mirvline2 < firstVisBar){
   _bz  = _mode == 2 ? Time[_tch2] : Time[_tcl1];
   _bz2 = _mode == 2 ? Time[0]-_mirvline2*Period()*60 : Time[0]-_mirvline2*Period()*60;
  }
  else{
   _bz  = _mode == 2 ? Time[0]-_tch2*Period()*60 : Time[0]-_tcl1*Period()*60;
   _bz2 = _mode == 2 ? Time[0]-_mirvline2*Period()*60 : Time[0]-_mirvline2*Period()*60;
   //Comment(_bz + " " + _bz2); 
  }

  if(_mirvline1>=0 && _mirvline1 < firstVisBar)
   _zvkEnd = Time[_mirvline1];
  else
   _zvkEnd = Time[0]-_mirvline1*Period()*60;
}

//+------------------------------------------------------------------+
//--- Рассчет уровней
void CalculateLevels(int _mode, double &_gray, double &_blue, double &_yellow, double &_red, double &_green, double &_upz,
                     int _t1ind, int _t2ind, int _tch12, int _tcl12, double _resch, double _rescl, double &buffer[])
{
 if(_mode==1 && _t1ind < 1000 && _tcl12 < 1000 && _tch12 < 1000 && _t2ind < 1000
    && _t1ind < firstVisBar && _tcl12 < firstVisBar && _tch12 < firstVisBar && _t2ind < firstVisBar
    && _tch12 > 0 && _tcl12 > 0) // проверки нужны чтобы не выходить за пределы массива
 {
  _gray   = Low[_t1ind] + _resch;
  _blue   = buffer[_tcl12];
  _yellow = buffer[_tcl12] + _resch;
  _red    = buffer[_tch12];
  _green  = buffer[_tch12] - _rescl;
  _upz    = High[_t2ind] - _rescl;
  
 }
 if(_mode==2 && _t1ind < 1000 && _tch12 < 1000 && _tcl12 < 1000 && _t2ind < 1000
    && _t1ind < firstVisBar && _tch12 < firstVisBar && _tcl12 < firstVisBar && _t2ind < firstVisBar
    && _tch12 > 0 && _tcl12 > 0)
 {
  _gray   = High[_t1ind] - _rescl;
  _blue   = buffer[_tch12];
  _yellow = buffer[_tch12] - _rescl;
  _red    = buffer[_tcl12];
  _green  = buffer[_tcl12] + _resch;
  _upz    = Low[_t2ind] + _resch;
 }
}
//+------------------------------------------------------------------+
//--- Проверить соразмерность каналов
bool CalculateSize(int _tcH1, int _tcH2, int _tcL1, int _tcH12)
{
 return _tcH2 - _tcH1 <= _tcL1 - _tcH12;
}
//+------------------------------------------------------------------+
//| Функциональная часть советника, проверка условий отправки ордера |
//+------------------------------------------------------------------+
//--- Реакция или наличие
bool ReactOrLevel(int _trademode, double _graytf, double _greentf, double _yellowtf, double _redtf, double _bluetf,
                  double _gray, double _green, double _yellow, double _red, double _blue, double _upztf, double _upz, int _t0ind, datetime _pzend, datetime _pzendx2, datetime _zvkendtf, datetime _zvkend)
{
 int _submode   = 0;
 int _reactmode = 0;
 
 switch(PosMode)
 {
  case EnumPosMode::Reaction:
  {
    _reactmode = 1;
    _submode = ReturnSubMode(_trademode);
    break;
  }
  case EnumPosMode::JustLevel:
  {
   _reactmode = 2;
   _submode = ReturnSubMode(_trademode);
   break;
  }
 }
 //Comment(_reactmode + " " +  _submode);
 
 if(useOneLevel)
   {
    switch(Level)
    {
     case Levels::red:
      return ReactOrLevelCheck(_trademode, _reactmode, _submode, _redtf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend);break;
     case Levels::gray:
      return ReactOrLevelCheck(_trademode, _reactmode, _submode, _graytf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend);break;
     case Levels::blue:
      return ReactOrLevelCheck(_trademode, _reactmode, _submode, _bluetf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend);break;
     case Levels::green:
      return ReactOrLevelCheck(_trademode, _reactmode, _submode, _greentf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend);break;
     case Levels::yellow:
      return ReactOrLevelCheck(_trademode, _reactmode, _submode, _yellowtf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend);break;
     case Levels::anylevel:
      return (ReactOrLevelCheck(_trademode, _reactmode, _submode, _redtf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend)     ||
              ReactOrLevelCheck(_trademode, _reactmode, _submode, _graytf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend)    ||
              ReactOrLevelCheck(_trademode, _reactmode, _submode, _bluetf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend)    ||
              ReactOrLevelCheck(_trademode, _reactmode, _submode, _greentf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend)   ||
              ReactOrLevelCheck(_trademode, _reactmode, _submode, _yellowtf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend));break;
    }
   }
   
 if(usemaxlevel)
 {
  double _difflevel = _trademode == 1 ? MathMin(_graytf, MathMin(_bluetf, MathMin(_yellowtf, MathMin(_redtf, _greentf)))):
                                        MathMax(_graytf, MathMax(_bluetf, MathMax(_yellowtf, MathMax(_redtf, _greentf))));
  if(useGraymax)
   return _difflevel == _graytf ? ReactOrLevelCheck(_trademode, _reactmode, _submode, _difflevel, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend):
         false;
  else
   return ReactOrLevelCheck(_trademode, _reactmode, _submode, _difflevel, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend);
 }
 
 else
  return (ReactOrLevelCheck(_trademode, _reactmode, _submode, _redtf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend)     ||
          ReactOrLevelCheck(_trademode, _reactmode, _submode, _graytf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend)    ||
          ReactOrLevelCheck(_trademode, _reactmode, _submode, _bluetf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend)    ||
          ReactOrLevelCheck(_trademode, _reactmode, _submode, _greentf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend)   ||
          ReactOrLevelCheck(_trademode, _reactmode, _submode, _yellowtf, _gray, _green, _yellow, _red, _blue, _upztf, _upz, _t0ind, _pzend, _pzendx2, _zvkendtf, _zvkend));
         
 return false;
}
//--- 
bool ReactOrLevelCheck(int _trademode, int _reactmode, int __submode, double __leveltf, double __level1, double __level2,
                       double __level3, double __level4, double __level5,  double __upztf, double __upz,  int __t0ind, datetime __pzend, datetime __pzendx2, datetime __zvkendtf, datetime __zvkend)
{
// _trademode - что будем торговать:
//    1 - лонг, 2 - шорт
// __submode  - учитывать уровень в пз младшего или нет:
//    1 - лонг с уровнем, 2 шорт с уровнем,
//    11 - лонг без уровня, 22 - шорт без уровня,
//    101 - лонг без проверок уровня, 102 - шорт без проверок уровня
// _reactmode: 
//    1 - реакция, 2 - наличие уровня

//--- если включен конретный уровень в пз младшего
 double _levelInpz = 0;
 if(useLevelInPz){
  switch(PZMode)
  {
   case LevelsInPZ::grayPZ:
    _levelInpz = __level1;
    break;
   case LevelsInPZ::redPZ:
    _levelInpz = __level4;
    break;
   case LevelsInPZ::bluePZ: 
    _levelInpz = __level5;
    break;
   case LevelsInPZ::yellowPZ:
    _levelInpz = __level3;
    break;
   case LevelsInPZ::greenPZ:
    _levelInpz = __level2;
    break;
   case LevelsInPZ::any:
    _levelInpz = -24;
    break;
  }
 }

 if(CheckTime(__pzend) && /*Time[0] >= __pzendx2 &&*/ CheckTime(__zvkendtf) && CheckTime(__zvkend)){
//--- лонг
 if(_trademode == 1 && _reactmode == 1 && __submode == 1 ){ // реакция лонг с уровнем в пз младшего
  //Print("1 " + Low[__t0ind] + " " + _levelInpz + " "+__upz);
  return __leveltf < __upztf  &&  __leveltf < __upz && __upz > Low[__t0ind] && Low[__t0ind] < __leveltf && Close[__t0ind] >= __leveltf && Open[__t0ind] > __leveltf &&
         (_levelInpz > 0  ? _levelInpz < __upz : ( __level1 < __upz || __level2 < __upz || __level3 < __upz || __level4 < __upz || __level5 < __upz));}
  
 if(_trademode == 1 && _reactmode == 2 && __submode == 1){ // наличие лонг с уровнем в пз младшего
  //Print("2 " + Low[__t0ind] + " " + _levelInpz + " "+__upz);
  return __leveltf < __upztf  &&  __leveltf < __upz && __upz > Low[__t0ind] && Low[__t0ind] < __leveltf && (
         _levelInpz > 0  ? _levelInpz < __upz : ( __level1 < __upz || __level2 < __upz || __level3 < __upz || __level4 < __upz || __level5 < __upz));}
  
 if(_trademode == 1 && _reactmode == 1 && __submode == 11 ) // реакция лонг без уровня в пз младшего
  return __leveltf < __upztf &&  __leveltf < __upz && __upz > Low[__t0ind] && Low[__t0ind] < __leveltf && Close[__t0ind] >= __leveltf && Open[__t0ind] > __leveltf && 
         __level1 > __upz && __level2 > __upz && __level3 > __upz && __level4 > __upz && __level5 > __upz;
         
 if(_trademode == 1 && _reactmode == 2 && __submode == 11 ) // наличие лонг без уровня в пз младшего
  return __leveltf < __upztf &&  __leveltf < __upz && __upz > Low[__t0ind] && Low[__t0ind] < __leveltf && __level1 > __upz && __level2 > __upz && __level3 > __upz && __level4 > __upz && __level5 > __upz;
  
 if(_trademode == 1 && _reactmode == 1 && __submode == 101 ) // реакция лонг без проверки уровня в пз младшего
  return __leveltf < __upztf  &&  __leveltf < __upz && __upz > Low[__t0ind] && Low[__t0ind] < __leveltf && Close[__t0ind] >= __leveltf && Open[__t0ind] > __leveltf;
  
 if(_trademode == 1 && _reactmode == 2 && __submode == 101 ) // наличие лонг без проверки уровня в пз младшего
  return __leveltf < __upztf  &&  __leveltf < __upz && __upz > Low[__t0ind] && Low[__t0ind] < __leveltf;
//--- шорт
 if(_trademode == 2 && _reactmode == 1 && __submode == 2) // реакция шорт с уровнем в пз младшего
  return __leveltf > __upztf  &&  __leveltf > __upz && __upz < High[__t0ind] && High[__t0ind] > __leveltf && Close[__t0ind] <= __leveltf && Open[__t0ind] < __leveltf &&
         _levelInpz != 0 && _levelInpz != 24 ? _levelInpz > __upz : ( __level1 > __upz || __level2 > __upz || __level3 > __upz || __level4 > __upz || __level5 > __upz);
  
 if(_trademode == 2 && _reactmode == 2 && __submode == 2) // наличие шорт с уровнем в пз младшего
  return __leveltf > __upztf  &&  __leveltf > __upz && __upz < High[__t0ind] && High[__t0ind] > __leveltf &&
         _levelInpz != 0 && _levelInpz != 24 ? _levelInpz > __upz : ( __level1 > __upz || __level2 > __upz || __level3 > __upz || __level4 > __upz || __level5 > __upz);
  
 if(_trademode == 2 && _reactmode == 1 && __submode == 22) // реакция шорт без уровня в пз младшего
  return __leveltf > __upztf  &&  __leveltf > __upz && __upz < High[__t0ind] && High[__t0ind] > __leveltf && Close[__t0ind] <= __leveltf && Open[__t0ind] < __leveltf &&
         __level1 < __upz && __level2 < __upz && __level3 < __upz && __level4 < __upz && __level5 < __upz;
         
 if(_trademode == 2 && _reactmode == 2 && __submode == 22) // наличие шорт без уровня в пз младшего
  return __leveltf > __upztf  &&  __leveltf > __upz && __upz < High[__t0ind] && High[__t0ind] > __leveltf && __level1 < __upz && __level2 < __upz && __level3 < __upz && __level4 < __upz && __level5 < __upz;}
 
 if(_trademode == 2 && _reactmode == 1 && __submode == 102 ) // реакция шорт без проверки уровня в пз младшего
  return __leveltf > __upztf  &&  __leveltf > __upz && __upz < High[__t0ind] && High[__t0ind] > __leveltf && Close[__t0ind] <= __leveltf && Open[__t0ind] < __leveltf;
 
 if(_trademode == 2 && _reactmode == 2 && __submode == 102) // наличие шорт без проверки уровня в пз младшего
  return __leveltf > __upztf  &&  __leveltf > __upz && __upz < High[__t0ind] && High[__t0ind] > __leveltf;
  
 return false;
}
//--- Устанавливает дополнительный мод на торговлю, смотрит на useLevelInPz
int ReturnSubMode(int _reactmode)
{
 if(_reactmode == 1 && exceptLevel)   // торговля лонг без проверки уровня в пз
  return 101;
 if(_reactmode == 2 && exceptLevel)   // торговля шорт без проверки уровня в пз
  return 102;
 if(_reactmode == 1 && useLevelInPz)  // торговля лонг с уровнем в пз младшего
  return 1;
 if(_reactmode == 2 && useLevelInPz)  // торговля шорт с уровнем в пз младшего
  return 2;
 if(_reactmode == 1 && !useLevelInPz) // торговля лонг без уровня в пз
  return 11;
 if(_reactmode == 2 && !useLevelInPz) // торговля шорт без уровня в пз
  return 22;
 return 0;
}
//--- Проверка окончания времени ЗВК или ПЗ
bool CheckTime(datetime _endtime)
{
 return Time[0] < _endtime;
}
//+------------------------------------------------------------------+
//|              Функциональная часть советника, ордера              |
//+------------------------------------------------------------------+
//--- Нормализировать цену
double normalize(double value)
  {
   return NormalizeDouble(value,_Digits);
  }
//--- Количество открытых ордеров, позиций. Передать параметром
int OrdersCount(const int _order_type)
  {
   RefreshRates();
   int orders = 0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         if(OrderSymbol() == Symbol() && OrderType()==_order_type && OrderMagicNumber() == Magic)
            orders++;
        }
     }
   return(orders);
  }
//--- Тикет отложенного ордера
int TicketNumber(const int _order_type)
  {
   RefreshRates();
   int ticket = 0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         if(OrderSymbol() == Symbol() && OrderType()==_order_type && OrderMagicNumber() == Magic)
            ticket = OrderTicket();
        }
     }
   return(ticket);
  }
//--- Цена стоп-лосс отложенного ордера
double LastStopLoss(const int _order_type)
  {
   RefreshRates();
   double stoploss = 0.0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         if(OrderSymbol() == Symbol() && OrderType()==_order_type && OrderMagicNumber() == Magic)
            stoploss = OrderStopLoss();
        }
     }
   return(stoploss);
  }
//--- Удалить отложенный ордер
bool DeleteOrder(const int _order_type)
  {
   if(_order_type == _order_type)
   {
    int ticketnum = TicketNumber(_order_type);
    if(!OrderDelete(ticketnum))
    {
     Print("Ошибка удаления отложенного ордера _ " + string(GetLastError()));
     return false;
    }
    return true;
   }
   return false;
  }
// Закрыть позиции
bool CloseAll(const int _order_type)
{
 RefreshRates();
 for(int i=0; i<OrdersTotal(); i++)
 {
  if(OrderSelect(i, SELECT_BY_POS))
  {
   if(OrderSymbol() == Symbol() && OrderType()==_order_type && OrderMagicNumber() == Magic)
    if(!OrderClose(OrderTicket(), OrderLots(), Close[0], 10))
    {
     Print("Ошибка закрытия позиции "+ string(OrderTicket()) + ": " + string(GetLastError()));
     return false;
    }
    Print("Позиция #" + string(OrderTicket()) + " закрыта по окончанию ЗВК");
  }
 }
 return true;
}
//+------------------------------------------------------------------+
double GetTickValue()
  {
   static double value = 0.0;
   if(value == 0.0)
      value=MarketInfo(Symbol(),MODE_TICKVALUE);
   return value;
  }
//+------------------------------------------------------------------+
double CalcLot(int slTicks)
  {
   switch(RiskMode)
     {
      case EnumRiskMode::FixedLot:
         return RiskValue;
      case EnumRiskMode::FixedCurrency:
        {
         if(slTicks<=0)
            return 0.0;
         double tickValue= GetTickValue(); 
         if(slTicks*tickValue==0)
            return 0.0;
         double v=MathFloor(100*RiskValue/(slTicks*tickValue))/100.0;
         return NormalizeDouble(v,2);
        }
      default:
         return -1.0;
     }
  }
//+------------------------------------------------------------------+
void ProcessRiscCalc(string _cmd, double p1, double p2, double p3, double _lot, int _mgc, string _comment)
  {
   double tpDelta = MathAbs(p3-p1);
   double slDelta = MathAbs(p2-p1);
   double delta   = MathAbs(p3-p2);
   double volume  = 0;
   //Print("enter: " + p1);
   //Print("exit: " + p2);
   //Print("tp: " + p3);
   //Print(MathAbs(p3-p1) + " " + MathAbs(p2-p1) + " " + MathAbs(p3-p2));
   if(delta>=tpDelta && delta>=slDelta)
     {
      string tpDivSl="inf";
      if(slDelta>0.0)
         tpDivSl=DoubleToString(tpDelta/slDelta,2);

      int tpTicks=(int)(tpDelta/tickSize);
      int slTicks=(int)(slDelta/tickSize);
      double lot=CalcLot(slTicks);
      if(lot<0.0)
         lot=0.0;

      double open = normalize(p1);
      double sl   = normalize(p2);
      double tp   = normalize(p3);

      if(_lot>0)
         volume = NormalizeDouble(_lot,2);
      else
         volume=NormalizeDouble(lot,2);
      if(_cmd=="BuyStop" && open != 0 &&  slTicks > tostop && tpTicks > tostop && tpDelta / slDelta > 1)
        {
         Print("Цены до отправки: " + string(open) + ", " + string(sl) + ", " + string(tp) + ", режим: " + _cmd);
         int res = OrderOpenx(_Symbol,OP_BUYSTOP,volume,sl,tp,0,_mgc,open,_comment);
        }
      if(_cmd=="SellStop" && open != 0 &&  slTicks > tostop && tpTicks > tostop /*&& tpDelta / slDelta > 1*/)
        {
         Print("Цены до отправки: " + string(open) + ", " + string(sl) + ", " + string(tp) + ", режим: " + _cmd);
         int res = OrderOpenx(_Symbol,OP_SELLSTOP,volume,sl,tp,0,_mgc,open,_comment);
        }

     }
   //else
   //   Print("Плохая ориентация ключевых цен");
  }
// --- Обработчик открытия ордеров
int OrderOpenx(string Symb,int cmdx,double lotsx,double sl,double tp,datetime expir,int magic,double price, string comment = "")
  {
   RefreshRates();
   int err = 0;
   bool exit_loop = false;
   int answer = -1;
   int Retry = 10;
   int cnt   = 0;
   string pref = "";
   string suf = "";

   if(cmdx == OP_BUY)
     {
      Print("Попытка открыть ордер ",pref+Symb+suf," на BUY по цене ",SymbolInfoDouble(Symb,SYMBOL_ASK),"; sl- ",sl,"; tp- ",tp,"... ");
      answer = (int)OrderSend(pref+Symb+suf,cmdx,lotsx,SymbolInfoDouble(Symb,SYMBOL_ASK),Slippage,sl,tp,comment,magic,expir,clrNONE);
     }
   if(cmdx == OP_SELL)
     {
      Print("Попытка открыть ордер ",pref+Symb+suf," на SELL по цене ",SymbolInfoDouble(Symb,SYMBOL_BID),"; sl- ",sl,"; tp- ",tp,"... ");
      answer = (int)OrderSend(pref+Symb+suf,cmdx,lotsx,SymbolInfoDouble(Symb,SYMBOL_BID),Slippage,sl,tp,comment,magic,expir,clrNONE);
     }
   if(cmdx == OP_BUYLIMIT)
     {
      Print("Попытка выставить ордер ",pref+Symb+suf,"  BUYLIMIT по цене ",price,"; sl- ",sl,"; tp- ",tp,"... ");
      answer = (int)OrderSend(pref+Symb+suf,cmdx,lotsx,price,Slippage,sl,tp,comment,magic,expir,clrNONE);
     }
   if(cmdx == OP_SELLLIMIT)
     {
      Print("Попытка выставить ордер ",pref+Symb+suf," SELLLIMIT по цене ",price,"; sl- ",sl,"; tp- ",tp,"... ");
      answer = (int)OrderSend(pref+Symb+suf,cmdx,lotsx,price,Slippage,sl,tp,comment,magic,expir,clrNONE);
     }
   if(cmdx == OP_BUYSTOP)
     {
      Print("Попытка выставить ордер ",pref+Symb+suf," BUYSTOP по цене ",price,"; sl- ",sl,"; tp- ",tp,"... ");
      answer = (int)OrderSend(pref+Symb+suf,cmdx,lotsx,price,Slippage,sl,tp,comment,magic,expir,clrNONE);
     }
   if(cmdx == OP_SELLSTOP)
     {
      Print("Попытка выставить ордер ",pref+Symb+suf," SELLSTOP по цене ",price,"; sl- ",sl,"; tp- ",tp,"... ");
      answer = (int)OrderSend(pref+Symb+suf,cmdx,lotsx,price,Slippage,sl,tp,comment,magic,expir,clrNONE);
     }
   err = GetLastError();

   if(cnt>Retry)
     {
      exit_loop = true;
      Print("Ошибка открытия ордера после ", cnt, " попыток");
     }
   return(answer);
  }