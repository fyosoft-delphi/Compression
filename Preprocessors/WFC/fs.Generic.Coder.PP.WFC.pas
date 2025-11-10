unit fs.Generic.Coder.PP.WFC;

interface

uses System.Classes, System.SysUtils, System.Math;

//==============================================================================
//      Weighted Frequency Count (WFC) Encode/Decode Preprocessing Functions
// Converted from original C source code taken from the link :
//          https://compressionratings.com/files/chile-0.5.zip (gst.c)
//          Author : Alexandru Mosoi
//                   https://alexandru.mosoi.googlepages.com/chile
// 2025.10.01 First running copy.
//     -Original codes with source-destination parameters preserved.
//     -WFCEncode2 & WFCDecode2 has only data parameter. They create a temporary
//   buffer with size equal to input data size, then they encode/decode given
//   data to this temporary buffer. When the process is finished temporary buffer
//   content copied to input data (i.e. overrite it).
//     -WFCEncode & WFCDecode which have also only data parameter, uses a temporary
//   internal buffer of window size (1Kb) named History. They save original data
//   (which will be altered during operations but also needed in further weight
//   calculations so must be preserved) to this buffer and then encode saved data.
//   Due to this additinal data save and added AND/MOD operations to calculate
//   correct circular data positions, cpu load increased but no temporary memory
//   of equal size needed. If time is important or data size is less than 1MB
//   then use WfcEncode2 & WfcDecode2, else use WfcEncode & WfcDecode.
//==============================================================================

procedure WFCEncode(Const InData: PByte; const InSize: Cardinal); overload;
procedure WfcDecode(const InData: PByte; Const InSize: Cardinal); overload;

procedure WFCEncode(const InData: PByte; InSize: Cardinal; out Output: PByte; out OutSize: Cardinal); overload;
procedure WfcDecode(const InData: PByte; InSize: Cardinal; out Output: PByte; out OutSize: Cardinal); overload;

procedure WFCEncode2(Const InData: PByte; const InSize: Cardinal);
procedure WfcDecode2(const InData: PByte; Const InSize: Cardinal);


implementation

const
  Window = 1024;
  WindowMask = 1023;
  Lookup: array[0..Window] of UInt32 = (
	     0, 131072,  41764,  21392,  13957,  13307,  11511,   9741,   9208,   8408,   7370,   6542,   5868,   5309,   4840,   4440,
	  4096,   3797,   3535,   3304,   3099,   2915,   2750,   2602,   2467,   2344,   2232,   2129,   2034,   1947,   1866,   1791,
	  1722,   1657,   1596,   1539,   1486,   1436,   1389,   1344,   1302,   1263,   1225,   1190,   1156,   1124,   1094,   1065,
	  1037,   1011,    985,    961,    938,    916,    895,    875,    855,    836,    818,    801,    784,    768,    753,    738,
	   724,    710,    696,    683,    671,    659,    647,    635,    624,    614,    603,    593,    584,    574,    565,    556,
	   547,    539,    531,    523,    515,    507,    500,    493,    486,    479,    472,    466,    460,    453,    447,    441,
	   436,    430,    425,    419,    414,    409,    404,    399,    394,    389,    385,    380,    376,    372,    367,    363,
	   359,    355,    351,    348,    344,    340,    337,    333,    330,    326,    323,    319,    316,    313,    310,    307,
	   304,    301,    298,    295,    292,    290,    287,    284,    282,    279,    277,    274,    272,    269,    267,    265,
	   262,    260,    258,    256,    253,    251,    249,    247,    245,    243,    241,    239,    237,    235,    233,    232,
	   230,    228,    226,    225,    223,    221,    219,    218,    216,    215,    213,    211,    210,    208,    207,    205,
	   204,    203,    201,    200,    198,    197,    196,    194,    193,    192,    190,    189,    188,    187,    185,    184,
	   183,    182,    181,    179,    178,    177,    176,    175,    174,    173,    172,    171,    170,    168,    167,    166,
	   165,    164,    163,    162,    162,    161,    160,    159,    158,    157,    156,    155,    154,    153,    152,    152,
	   151,    150,    149,    148,    147,    147,    146,    145,    144,    143,    143,    142,    141,    140,    140,    139,
	   138,    138,    137,    136,    135,    135,    134,    133,    133,    132,    131,    131,    130,    129,    129,    128,
	   128,    127,    126,    126,    125,    124,    124,    123,    123,    122,    122,    121,    120,    120,    119,    119,
	   118,    118,    117,    117,    116,    115,    115,    114,    114,    113,    113,    112,    112,    111,    111,    110,
	   110,    109,    109,    109,    108,    108,    107,    107,    106,    106,    105,    105,    104,    104,    104,    103,
	   103,    102,    102,    101,    101,    101,    100,    100,     99,     99,     99,     98,     98,     97,     97,     97,
	    96,     96,     96,     95,     95,     94,     94,     94,     93,     93,     93,     92,     92,     92,     91,     91,
	    91,     90,     90,     90,     89,     89,     89,     88,     88,     88,     87,     87,     87,     86,     86,     86,
	    85,     85,     85,     85,     84,     84,     84,     83,     83,     83,     83,     82,     82,     82,     81,     81,
	    81,     81,     80,     80,     80,     79,     79,     79,     79,     78,     78,     78,     78,     77,     77,     77,
	    77,     76,     76,     76,     76,     75,     75,     75,     75,     74,     74,     74,     74,     73,     73,     73,
	    73,     73,     72,     72,     72,     72,     71,     71,     71,     71,     71,     70,     70,     70,     70,     69,
	    69,     69,     69,     69,     68,     68,     68,     68,     68,     67,     67,     67,     67,     67,     66,     66,
	    66,     66,     66,     65,     65,     65,     65,     65,     65,     64,     64,     64,     64,     64,     63,     63,
	    63,     63,     63,     63,     62,     62,     62,     62,     62,     62,     61,     61,     61,     61,     61,     61,
	    60,     60,     60,     60,     60,     60,     59,     59,     59,     59,     59,     59,     58,     58,     58,     58,
	    58,     58,     58,     57,     57,     57,     57,     57,     57,     56,     56,     56,     56,     56,     56,     56,
	    55,     55,     55,     55,     55,     55,     55,     55,     54,     54,     54,     54,     54,     54,     54,     53,
	    53,     53,     53,     53,     53,     53,     53,     52,     52,     52,     52,     52,     52,     52,     52,     51,
	    51,     51,     51,     51,     51,     51,     51,     50,     50,     50,     50,     50,     50,     50,     50,     50,
	    49,     49,     49,     49,     49,     49,     49,     49,     48,     48,     48,     48,     48,     48,     48,     48,
	    48,     48,     47,     47,     47,     47,     47,     47,     47,     47,     47,     46,     46,     46,     46,     46,
	    46,     46,     46,     46,     46,     45,     45,     45,     45,     45,     45,     45,     45,     45,     45,     44,
	    44,     44,     44,     44,     44,     44,     44,     44,     44,     44,     43,     43,     43,     43,     43,     43,
	    43,     43,     43,     43,     43,     42,     42,     42,     42,     42,     42,     42,     42,     42,     42,     42,
	    42,     41,     41,     41,     41,     41,     41,     41,     41,     41,     41,     41,     41,     40,     40,     40,
	    40,     40,     40,     40,     40,     40,     40,     40,     40,     40,     39,     39,     39,     39,     39,     39,
	    39,     39,     39,     39,     39,     39,     39,     38,     38,     38,     38,     38,     38,     38,     38,     38,
	    38,     38,     38,     38,     38,     37,     37,     37,     37,     37,     37,     37,     37,     37,     37,     37,
	    37,     37,     37,     36,     36,     36,     36,     36,     36,     36,     36,     36,     36,     36,     36,     36,
	    36,     36,     36,     35,     35,     35,     35,     35,     35,     35,     35,     35,     35,     35,     35,     35,
	    35,     35,     35,     34,     34,     34,     34,     34,     34,     34,     34,     34,     34,     34,     34,     34,
	    34,     34,     34,     34,     33,     33,     33,     33,     33,     33,     33,     33,     33,     33,     33,     33,
	    33,     33,     33,     33,     33,     33,     32,     32,     32,     32,     32,     32,     32,     32,     32,     32,
	    32,     32,     32,     32,     32,     32,     32,     32,     32,     31,     31,     31,     31,     31,     31,     31,
	    31,     31,     31,     31,     31,     31,     31,     31,     31,     31,     31,     31,     31,     30,     30,     30,
	    30,     30,     30,     30,     30,     30,     30,     30,     30,     30,     30,     30,     30,     30,     30,     30,
	    30,     30,     29,     29,     29,     29,     29,     29,     29,     29,     29,     29,     29,     29,     29,     29,
	    29,     29,     29,     29,     29,     29,     29,     29,     28,     28,     28,     28,     28,     28,     28,     28,
	    28,     28,     28,     28,     28,     28,     28,     28,     28,     28,     28,     28,     28,     28,     28,     28,
	    27,     27,     27,     27,     27,     27,     27,     27,     27,     27,     27,     27,     27,     27,     27,     27,
	    27,     27,     27,     27,     27,     27,     27,     27,     27,     27,     26,     26,     26,     26,     26,     26,
	    26,     26,     26,     26,     26,     26,     26,     26,     26,     26,     26,     26,     26,     26,     26,     26,
	    26,     26,     26,     26,     26,     25,     25,     25,     25,     25,     25,     25,     25,     25,     25,     25,
	    25,     25,     25,     25,     25,     25,     25,     25,     25,     25,     25,     25,     25,     25,     25,     25,
	    25,     25,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
	    24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
	    24,     23,     23,     23,     23,     23,     23,     23,     23,     23,     23,     23,     23,     23,     23,     23,
	    23,     23,     23,     23,     23,     23,     23,     23,     23,     23,     23,     23,     23,     23,     23,     23,
	    23,     23,     23,     22,     22,     22,     22,     22,     22,     22,     22,     22,     22,     22,     22,     22,
	    22);


procedure WFCEncode(const InData: PByte; const InSize: Cardinal);
var WFC: array[0..255] of UInt32;
    Table: array[0..255] of Byte;
    History: array[0..Window - 1] of Byte;  // Sabit boyut - 1024
    i, j, k, HistoryIndex: Cardinal;
    OriginalByte: Byte;
   begin
     // History buffer'ýný sýfýrla
     FillChar(History[0], SizeOf(History), 0);
     HistoryIndex := 0;
     for i := 0 to 255 do
       Table[i] := i;
     for i := 0 to InSize - 1 do
     begin
       FillChar(WFC, SizeOf(WFC), 0);
       // Geçmiþ buffer'ýndan frekans hesapla - BIT MASK ile!
       j := HistoryIndex;
       for k := 1 to Min(i, Window) do
       begin
         j := (integer(j) - 1) and WindowMask;  // j mod 1024 yerine j & 1023 - ÇOK DAHA HIZLI!
         WFC[History[j]] := WFC[History[j]] + Lookup[k];
       end;
       // Tabloyu sýrala
       for j := 0 to 255 do
       begin
         var Symbol := Table[j];
         k := j;
         while (k > 0) and (WFC[Symbol] > WFC[Table[k-1]]) do
         begin
           Table[k] := Table[k-1];
           Dec(k);
         end;
         Table[k] := Symbol;
       end;
       // Orijinal byte'ý sakla ve kodla
       OriginalByte := InData[i];
       j := 0;
       while Table[j] <> OriginalByte do
         Inc(j);
       InData[i] := j;  // Kodlanmýþ deðeri yaz
       // Geçmiþ buffer'ýný güncelle - BIT MASK ile!
       History[HistoryIndex] := OriginalByte;
       HistoryIndex := (HistoryIndex + 1) and WindowMask;  // HistoryIndex mod 1024 yerine
     end;
   end;

procedure WFCDecode(const InData: PByte; const InSize: Cardinal);
 var WFC: array[0..255] of UInt32;
     Table: array[0..255] of Byte;
     History: array[0..Window - 1] of Byte;  // Sabit boyut - 1024
     i, j, k, HistoryIndex: Cardinal;
     DecodedByte: Byte;
   begin
     FillChar(History[0], SizeOf(History), 0);
     HistoryIndex := 0;
     for i := 0 to 255 do
       Table[i] := i;
     for i := 0 to InSize - 1 do
     begin
       FillChar(WFC, SizeOf(WFC), 0);
       j := HistoryIndex; // Geçmiþ buffer'ýndan frekans hesapla - BIT MASK ile!
       for k := 1 to Min(i, Window) do
       begin
         j := (integer(j) - 1) and WindowMask;  // j mod 1024 yerine j & 1023
         WFC[History[j]] := WFC[History[j]] + Lookup[k];
       end;
       for j := 0 to 255 do // Tabloyu sýrala
       begin
         var Symbol := Table[j];
         k := j;
         while (k > 0) and (WFC[Symbol] > WFC[Table[k-1]]) do
         begin
           Table[k] := Table[k-1];
           Dec(k);
         end;
         Table[k] := Symbol;
       end;
       // Byte'ý çöz
       DecodedByte := Table[InData[i]];
       InData[i] := DecodedByte;
       // Geçmiþ buffer'ýný güncelle - BIT MASK ile!
       History[HistoryIndex] := DecodedByte;
       HistoryIndex := (HistoryIndex + 1) and WindowMask;
     end;
   end;


procedure WFCEncode(const InData: PByte; InSize: Cardinal; out Output: PByte; out OutSize: Cardinal);
 var WFC: array[0..255] of UInt32;
     Table: array[0..255] of Byte;
     i, j, k: Cardinal;
   begin
     for i := 0 to 255 do
       Table[i] := i;
     for i := 0 to InSize - 1 do
     begin
       FillChar(WFC, SizeOf(WFC), 0);
       j := i;
       while (i - j < Window) and (j > 0) do
       begin
         Dec(j);
         WFC[InData[j]] := WFC[InData[j]] + Lookup[i - j];
       end;
       for j := 0 to 255 do
       begin
         var Symbol := Table[j];
         k := j;
         while (k > 0) and (WFC[Symbol] > WFC[Table[k-1]]) do
         begin
           Table[k] := Table[k-1];
           Dec(k);
         end;
         Table[k] := Symbol;
       end;
       j := 0;
       while Table[j] <> InData[i] do
         Inc(j);
       Output[i] := j;
     end;
   end;

procedure WfcDecode(const InData: PByte; InSize: Cardinal; out Output: PByte; out OutSize: Cardinal);
 var WFC: array[0..255] of UInt32;
     Table: array[0..255] of Byte;
     i, j, k: Cardinal;
   begin
     for i := 0 to 255 do
       Table[i] := i;
     for i := 0 to InSize - 1 do
     begin
       FillChar(WFC, SizeOf(WFC), 0);
       j := i;
       while (i - j < Window) and (j > 0) do
       begin
         Dec(j);
         WFC[Output[j]] := WFC[Output[j]] + Lookup[i - j];
       end;
       for j := 0 to 255 do
       begin
         var Symbol := Table[j];
         k := j;
         while (k > 0) and (WFC[Symbol] > WFC[Table[k-1]]) do
         begin
           Table[k] := Table[k-1];
           Dec(k);
         end;
         Table[k] := Symbol;
       end;
       Output[i] := Table[InData[i]];
     end;
   end;


procedure WfcEncode2(const InData: PByte; Const InSize: Cardinal);
 var Output: PByte;
     OutSize: Cardinal;
   begin
     GetMem(Output, InSize);
     try
       WfcEncode(InData, InSize, Output, OutSize);
     finally
       Move(OutPut^, InData^, InSize);
       FreeMem(Output, InSize);
     end;
   end;

procedure WFCDecode2(Const InData: PByte; const InSize: Cardinal);
 var Output: PByte;
     OutSize: Cardinal;
   begin
     GetMem(Output, InSize);
     try
       WfcDecode(InData, InSize, Output, OutSize);
     finally
       Move(OutPut^, InData^, InSize);
       FreeMem(Output, InSize);
     end;
   end;



end.

