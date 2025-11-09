
ContextBuffer := (RotateLeft32(ContextBuffer, 7) xor (CurByte * 131)) and $7FFFFFF;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          10699372  100000000  % -6,99  1,55661  1,37327  OK   OK    OK / OK  63501754  % -6,93
NullCoder-NullM       XNull-Null                          55034335   58720195   % 6,28  0,95849  0,87291  OK   OK    OK / OK  43596477   % 7,72
NullCoder-NullM       XNull-Null                           2988032    3143185   % 4,94  0,05344  0,04558  OK   OK    OK / OK   2108002   % 3,42
NullCoder-NullM       XNull-Null                          16412341   15480545  % -6,02  0,25146  0,22439  OK   OK    OK / OK   9512353  % -5,77
NullCoder-NullM       XNull-Null                            848195     768771  % -10,3  0,01595  0,01393  OK   OK    OK / OK    435043  % -10,3
NullCoder-NullM       XNull-Null                             41592      44226   % 5,96  0,00551  0,00421  OK   OK    OK / OK     26990   % 5,96


// İki farklı hash kombinasyonu
var Hash1 := (UInt64(ContextBuffer) * 16777619 + CurByte) and $7FFFFFF;
var Hash2 := ((ContextBuffer shl 4) xor CurByte) and $FFFFFF;
Context := (Hash1 xor Hash2) and HashMask;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          10699372  100000000  % -6,99  1,49529  1,43960  OK   OK    OK / OK  63501754  % -6,93
NullCoder-NullM       XNull-Null                          55034335   58720195   % 6,28  0,90704  0,89971  OK   OK    OK / OK  43596477   % 7,72
NullCoder-NullM       XNull-Null                           2988032    3143185   % 4,94  0,04818  0,04709  OK   OK    OK / OK   2108002   % 3,42
NullCoder-NullM       XNull-Null                          16412341   15480545  % -6,02  0,23074  0,22987  OK   OK    OK / OK   9512353  % -5,77
NullCoder-NullM       XNull-Null                            848195     768771  % -10,3  0,01600  0,01549  OK   OK    OK / OK    435043  % -10,3
NullCoder-NullM       XNull-Null                             41592      44226   % 5,96  0,00577  0,00428  OK   OK    OK / OK     26990   % 5,96


ContextBuffer := ((ContextBuffer shl 4) xor (CurByte * 17)) and $FFFFFF;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          55380682  100000000  % 44,62  3,30001  3,24469  OK   OK    OK / OK  63501754  % 27,90
NullCoder-NullM       XNull-Null                          27022286   58720195  % 53,98  1,39492  1,50341  OK   OK    OK / OK  43596477  % 51,70
NullCoder-NullM       XNull-Null                           1824106    3143185  % 41,97  0,07377  0,06876  OK   OK    OK / OK   2108002  % 31,26
NullCoder-NullM       XNull-Null                           3722210   15480545  % 75,96  0,18238  0,20678  OK   OK    OK / OK   9512353  % 72,13
NullCoder-NullM       XNull-Null                            569307     768771  % 25,95  0,02213  0,02239  OK   OK    OK / OK    435043  % 20,23
NullCoder-NullM       XNull-Null                             23180      44226  % 47,59  0,00506  0,00420  OK   OK    OK / OK     26990  % 47,59


ContextBuffer := ((ContextBuffer shl 6) xor CurByte) and $3FFFFFF;  // 26-bit

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          56405816  100000000  % 43,59  2,34582  2,02242  OK   OK    OK / OK  63501754  % 37,27
NullCoder-NullM       XNull-Null                          27942389   58720195  % 52,41  1,20608  1,15842  OK   OK    OK / OK  43596477  % 50,48
NullCoder-NullM       XNull-Null                           1726559    3143185  % 45,07  0,08079  0,06368  OK   OK    OK / OK   2108002  % 38,96
NullCoder-NullM       XNull-Null                           4415178   15480545  % 71,48  0,22643  0,22834  OK   OK    OK / OK   9512353  % 69,95
NullCoder-NullM       XNull-Null                            528861     768771  % 31,21  0,02224  0,01854  OK   OK    OK / OK    435043  % 28,83
NullCoder-NullM       XNull-Null                             20869      44226  % 52,81  0,00575  0,00535  OK   OK    OK / OK     26990  % 52,81


// Son biti başa taşı
ContextBuffer := ((ContextBuffer shl 1) or (ContextBuffer shr 31)) xor CurByte;
ContextBuffer := ContextBuffer and $7FFFFFF;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          97958677  100000000   % 2,04  3,65556  3,01358  OK   OK    OK / OK  63501754  % -6,04
NullCoder-NullM       XNull-Null                          37814386   58720195  % 35,60  1,75572  1,81917  OK   OK    OK / OK  43596477  % 39,49
NullCoder-NullM       XNull-Null                           2820916    3143185  % 10,25  0,08201  0,07334  OK   OK    OK / OK   2108002   % 6,89
NullCoder-NullM       XNull-Null                           2856905   15480545  % 81,55  0,14682  0,18940  OK   OK    OK / OK   9512353  % 68,80
NullCoder-NullM       XNull-Null                            860915     768771  % -11,9  0,02535  0,02070  OK   OK    OK / OK    435043  % -12,2
NullCoder-NullM       XNull-Null                             37885      44226  % 14,34  0,00559  0,00398  OK   OK    OK / OK     26990  % 14,34


ContextBuffer := ((ContextBuffer shl 7) or (ContextBuffer shr 25)) xor CurByte;
ContextBuffer := ContextBuffer and $7FFFFFF;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          64819761  100000000  % 35,18  2,31452  2,02043  OK   OK    OK / OK  63501754  % 26,90
NullCoder-NullM       XNull-Null                          27522318   58720195  % 53,13  1,23387  1,23609  OK   OK    OK / OK  43596477  % 50,45
NullCoder-NullM       XNull-Null                           1937735    3143185  % 38,35  0,06994  0,06437  OK   OK    OK / OK   2108002  % 30,95
NullCoder-NullM       XNull-Null                           3598364   15480545  % 76,76  0,21516  0,23459  OK   OK    OK / OK   9512353  % 75,36
NullCoder-NullM       XNull-Null                            608309     768771  % 20,87  0,02319  0,01815  OK   OK    OK / OK    435043  % 17,83
NullCoder-NullM       XNull-Null                             23512      44226  % 46,84  0,00635  0,00463  OK   OK    OK / OK     26990  % 46,84


// Önce shift, sonra XOR
Temp := (ContextBuffer shl 3) or (ContextBuffer shr 29);
ContextBuffer := (Temp xor (CurByte * 131)) and $7FFFFFF;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          59529992  100000000  % 40,47  3,72325  3,90727  OK   OK    OK / OK  63501754  % 17,25
NullCoder-NullM       XNull-Null                          27916873   58720195  % 52,46  1,53245  1,59495  OK   OK    OK / OK  43596477  % 50,84
NullCoder-NullM       XNull-Null                           2051978    3143185  % 34,72  0,07474  0,07428  OK   OK    OK / OK   2108002  % 22,78
NullCoder-NullM       XNull-Null                           3760296   15480545  % 75,71  0,18224  0,21347  OK   OK    OK / OK   9512353  % 70,67
NullCoder-NullM       XNull-Null                            658774     768771  % 14,31  0,02561  0,02306  OK   OK    OK / OK    435043   % 7,63
NullCoder-NullM       XNull-Null                             25559      44226  % 42,21  0,00461  0,00459  OK   OK    OK / OK     26990  % 42,21


ContextBuffer := ((ContextBuffer shl 7) or (ContextBuffer shr 25)) xor CurByte;
ContextBuffer := ContextBuffer and $7FFFFFF;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          64819761  100000000  % 35,18  2,30140  1,97480  OK   OK    OK / OK  63501754  % 26,90
NullCoder-NullM       XNull-Null                          27522318   58720195  % 53,13  1,23726  1,21259  OK   OK    OK / OK  43596477  % 50,45
NullCoder-NullM       XNull-Null                           1937735    3143185  % 38,35  0,07659  0,06523  OK   OK    OK / OK   2108002  % 30,95
NullCoder-NullM       XNull-Null                           3598364   15480545  % 76,76  0,21512  0,23092  OK   OK    OK / OK   9512353  % 75,36
NullCoder-NullM       XNull-Null                            608309     768771  % 20,87  0,02385  0,01805  OK   OK    OK / OK    435043  % 17,83
NullCoder-NullM       XNull-Null                             23512      44226  % 46,84  0,00746  0,00463  OK   OK    OK / OK     26990  % 46,84


// Daha iyi karışım için
ContextBuffer := ContextBuffer xor (ContextBuffer shl 7);
ContextBuffer := ContextBuffer xor (ContextBuffer shr 12);
ContextBuffer := (UInt64(ContextBuffer) + CurByte) and $7FFFFFF;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          10796028  100000000  % -7,96  4,04095  3,14881  OK   OK    OK / OK  63501754  % -12,4
NullCoder-NullM       XNull-Null                          58220860   58720195   % 0,85  2,19649  2,03169  OK   OK    OK / OK  43596477  % 18,52
NullCoder-NullM       XNull-Null                           3113202    3143185   % 0,95  0,09613  0,09490  OK   OK    OK / OK   2108002   % 2,88
NullCoder-NullM       XNull-Null                          16978022   15480545  % -9,67  0,44157  0,39164  OK   OK    OK / OK   9512353  % -12,4
NullCoder-NullM       XNull-Null                            862772     768771  % -12,2  0,03538  0,02302  OK   OK    OK / OK    435043  % -12,3
NullCoder-NullM       XNull-Null                             49776      44226  % -12,5  0,00532  0,00430  OK   OK    OK / OK     26990  % -12,5


// Daha iyi karışım için
ContextBuffer := ContextBuffer xor (ContextBuffer shl 7);
ContextBuffer := ContextBuffer xor (ContextBuffer shr 12);
ContextBuffer := (ContextBuffer and $FFFFFFF + CurByte) and $7FFFFFF;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          10796028  100000000  % -7,96  3,90417  3,13702  OK   OK    OK / OK  63501754  % -12,4
NullCoder-NullM       XNull-Null                          58220860   58720195   % 0,85  2,20379  2,10074  OK   OK    OK / OK  43596477  % 18,52
NullCoder-NullM       XNull-Null                           3113202    3143185   % 0,95  0,10258  0,10275  OK   OK    OK / OK   2108002   % 2,88
NullCoder-NullM       XNull-Null                          16978022   15480545  % -9,67  0,48631  0,41561  OK   OK    OK / OK   9512353  % -12,4
NullCoder-NullM       XNull-Null                            862772     768771  % -12,2  0,02767  0,02213  OK   OK    OK / OK    435043  % -12,3
NullCoder-NullM       XNull-Null                             49776      44226  % -12,5  0,00544  0,00401  OK   OK    OK / OK     26990  % -12,5


// Byte'ları döndür: [B3][B2][B1][B0] → [B2][B1][B0][B3]
ContextBuffer := ((ContextBuffer shl 8) or (ContextBuffer shr 24)) xor CurByte;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          10789175  100000000  % -7,89  3,71798  2,91136  OK   OK    OK / OK  63501754  % -12,2
NullCoder-NullM       XNull-Null                          56622624   58720195   % 3,57  1,95194  1,71757  OK   OK    OK / OK  43596477  % 15,94
NullCoder-NullM       XNull-Null                           3009306    3143185   % 4,26  0,09104  0,07640  OK   OK    OK / OK   2108002   % 3,33
NullCoder-NullM       XNull-Null                          16679656   15480545  % -7,75  0,47357  0,37824  OK   OK    OK / OK   9512353  % -11,7
NullCoder-NullM       XNull-Null                            856640     768771  % -11,4  0,02470  0,02092  OK   OK    OK / OK    435043  % -12,0
NullCoder-NullM       XNull-Null                             47741      44226  % -7,95  0,00509  0,00401  OK   OK    OK / OK     26990  % -7,95


ContextBuffer := (RotateLeft32(ContextBuffer, 7) xor CurByte) and $7FFFFFF;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          64819761  100000000  % 35,18  2,59778  2,14122  OK   OK    OK / OK  63501754  % 26,90
NullCoder-NullM       XNull-Null                          27522318   58720195  % 53,13  1,36604  1,29121  OK   OK    OK / OK  43596477  % 50,45
NullCoder-NullM       XNull-Null                           1937735    3143185  % 38,35  0,07950  0,06988  OK   OK    OK / OK   2108002  % 30,95
NullCoder-NullM       XNull-Null                           3598364   15480545  % 76,76  0,23470  0,23661  OK   OK    OK / OK   9512353  % 75,36
NullCoder-NullM       XNull-Null                            608309     768771  % 20,87  0,02554  0,01996  OK   OK    OK / OK    435043  % 17,83
NullCoder-NullM       XNull-Null                             23512      44226  % 46,84  0,00595  0,00458  OK   OK    OK / OK     26990  % 46,84


ContextBuffer := ((ContextBuffer and $FF) * 257) or CurByte;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          10699372  100000000  % -6,99  1,44753  1,30920  OK   OK    OK / OK  63501754  % -6,93
NullCoder-NullM       XNull-Null                          55034334   58720195   % 6,28  0,86154  0,82106  OK   OK    OK / OK  43596477   % 7,72
NullCoder-NullM       XNull-Null                           2988031    3143185   % 4,94  0,04960  0,04415  OK   OK    OK / OK   2108002   % 3,42
NullCoder-NullM       XNull-Null                          16412341   15480545  % -6,02  0,23341  0,20754  OK   OK    OK / OK   9512353  % -5,77
NullCoder-NullM       XNull-Null                            848195     768771  % -10,3  0,01537  0,01355  OK   OK    OK / OK    435043  % -10,3
NullCoder-NullM       XNull-Null                             41592      44226   % 5,96  0,00576  0,00448  OK   OK    OK / OK     26990   % 5,96


ContextBuffer := ((ContextBuffer and $FF) * 257) + CurByte;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          97766667  100000000   % 2,23  1,63311  1,49488  OK   OK    OK / OK  63501754   % 1,11
NullCoder-NullM       XNull-Null                          47214685   58720195  % 19,59  1,04215  0,96165  OK   OK    OK / OK  43596477  % 18,10
NullCoder-NullM       XNull-Null                           2695222    3143185  % 14,25  0,05311  0,04939  OK   OK    OK / OK   2108002  % 11,85
NullCoder-NullM       XNull-Null                          11337045   15480545  % 26,77  0,32667  0,28160  OK   OK    OK / OK   9512353  % 24,12
NullCoder-NullM       XNull-Null                            753313     768771   % 2,01  0,01696  0,01588  OK   OK    OK / OK    435043   % 1,57
NullCoder-NullM       XNull-Null                             40157      44226   % 9,20  0,00557  0,00438  OK   OK    OK / OK     26990   % 9,20


ContextBuffer := ((ContextBuffer and $FFFF) * 257) + CurByte;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          10045309  100000000  % -0,45  4,01602  3,15475  OK   OK    OK / OK  63501754  % -11,4
NullCoder-NullM       XNull-Null                          53414543   58720195   % 9,04  2,27059  1,97337  OK   OK    OK / OK  43596477  % 15,92
NullCoder-NullM       XNull-Null                           2966310    3143185   % 5,63  0,09570  0,09841  OK   OK    OK / OK   2108002   % 2,71
NullCoder-NullM       XNull-Null                          12969615   15480545  % 16,22  0,48658  0,50677  OK   OK    OK / OK   9512353  % -10,0
NullCoder-NullM       XNull-Null                            840999     768771  % -9,40  0,02678  0,02527  OK   OK    OK / OK    435043  % -10,9
NullCoder-NullM       XNull-Null                             49419      44226  % -11,7  0,00584  0,00403  OK   OK    OK / OK     26990  % -11,7


ContextBuffer := ((ContextBuffer and $FFF) * 257) + CurByte;

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          99264784  100000000   % 0,74  1,73237  1,48480  OK   OK    OK / OK  63501754  % -5,45
NullCoder-NullM       XNull-Null                          50790416   58720195  % 13,50  1,14905  0,98562  OK   OK    OK / OK  43596477  % 12,91
NullCoder-NullM       XNull-Null                           2794517    3143185  % 11,09  0,05790  0,04940  OK   OK    OK / OK   2108002   % 6,23
NullCoder-NullM       XNull-Null                          11529273   15480545  % 25,52  0,34241  0,29499  OK   OK    OK / OK   9512353   % 7,00
NullCoder-NullM       XNull-Null                            778259     768771  % -1,23  0,01890  0,01536  OK   OK    OK / OK    435043  % -3,33
NullCoder-NullM       XNull-Null                             46619      44226  % -5,41  0,00593  0,00469  OK   OK    OK / OK     26990  % -5,41



ContextBuffer := ((ContextBuffer shl 8) or CurByte); 

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          61120218  100000000  % 38,88  2,13833  1,83719  OK   OK    OK / OK  63501754  % 36,64
NullCoder-NullM       XNull-Null                          28721659   58720195  % 51,09  1,17903  1,15677  OK   OK    OK / OK  43596477  % 49,97
NullCoder-NullM       XNull-Null                           1818622    3143185  % 42,14  0,06872  0,06060  OK   OK    OK / OK   2108002  % 38,65
NullCoder-NullM       XNull-Null                           5357335   15480545  % 65,39  0,22668  0,22736  OK   OK    OK / OK   9512353  % 64,97
NullCoder-NullM       XNull-Null                            561040     768771  % 27,02  0,02080  0,01784  OK   OK    OK / OK    435043  % 26,00
NullCoder-NullM       XNull-Null                             20062      44226  % 54,64  0,00572  0,00432  OK   OK    OK / OK     26990  % 54,64



ContextBuffer := ((ContextBuffer shl 5) or CurByte);

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          62467911  100000000  % 37,53  2,14383  1,83355  OK   OK    OK / OK  63501754  % 32,89
NullCoder-NullM       XNull-Null                          27121315   58720195  % 53,81  1,15331  1,13549  OK   OK    OK / OK  43596477  % 51,98
NullCoder-NullM       XNull-Null                           1839837    3143185  % 41,47  0,06755  0,05850  OK   OK    OK / OK   2108002  % 36,18
NullCoder-NullM       XNull-Null                           4159035   15480545  % 73,13  0,22895  0,22863  OK   OK    OK / OK   9512353  % 71,59
NullCoder-NullM       XNull-Null                            577152     768771  % 24,93  0,02171  0,01752  OK   OK    OK / OK    435043  % 22,96
NullCoder-NullM       XNull-Null                             21282      44226  % 51,88  0,00635  0,00429  OK   OK    OK / OK     26990  % 51,88


ContextBuffer := ((ContextBuffer shl 5) xor CurByte);

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          55164097  100000000  % 44,84  2,49975  2,21256  OK   OK    OK / OK  63501754  % 33,89
NullCoder-NullM       XNull-Null                          27224573   58720195  % 53,64  1,26856  1,23595  OK   OK    OK / OK  43596477  % 51,32
NullCoder-NullM       XNull-Null                           1736364    3143185  % 44,76  0,0733   0,06508  OK   OK    OK / OK   2108002  % 36,28
NullCoder-NullM       XNull-Null                           4156003   15480545  % 73,15  0,22868  0,22478  OK   OK    OK / OK   9512353  % 70,45
NullCoder-NullM       XNull-Null                            535350     768771  % 30,36  0,02619  0,02040  OK   OK    OK / OK    435043  % 26,40
NullCoder-NullM       XNull-Null                             21659      44226  % 51,03  0,00569  0,00537  OK   OK    OK / OK     26990  % 51,03


ContextBuffer := ((ContextBuffer shl 5) and $FFFFFFF + CurByte);

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          55006714  100000000  % 44,99  2,55324  2,28558  OK   OK    OK / OK  63501754  % 33,93
NullCoder-NullM       XNull-Null                          27201076   58720195  % 53,68  1,26065  1,24583  OK   OK    OK / OK  43596477  % 51,36
NullCoder-NullM       XNull-Null                           1735287    3143185  % 44,79  0,07478  0,06705  OK   OK    OK / OK   2108002  % 36,26
NullCoder-NullM       XNull-Null                           4156003   15480545  % 73,15  0,22851  0,23240  OK   OK    OK / OK   9512353  % 70,45
NullCoder-NullM       XNull-Null                            535055     768771  % 30,40  0,02357  0,01962  OK   OK    OK / OK    435043  % 26,41
NullCoder-NullM       XNull-Null                             21654      44226  % 51,04  0,00609  0,00464  OK   OK    OK / OK     26990  % 51,04



ContextBuffer := ((ContextBuffer shl 4) or CurByte);

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          69674277  100000000  % 30,33  2,02112  1,74262  OK   OK    OK / OK  63501754  % 26,11
NullCoder-NullM       XNull-Null                          26578408   58720195  % 54,74  1,19879  1,16620  OK   OK    OK / OK  43596477  % 52,90
NullCoder-NullM       XNull-Null                           2003103    3143185  % 36,27  0,06709  0,05912  OK   OK    OK / OK   2108002  % 30,90
NullCoder-NullM       XNull-Null                           3808979   15480545  % 75,40  0,22110  0,22802  OK   OK    OK / OK   9512353  % 73,96
NullCoder-NullM       XNull-Null                            638260     768771  % 16,98  0,01976  0,01717  OK   OK    OK / OK    435043  % 15,07
NullCoder-NullM       XNull-Null                             22519      44226  % 49,08  0,00568  0,00420  OK   OK    OK / OK     26990  % 49,08


ContextBuffer := ((ContextBuffer shl 4) xor CurByte);

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          55755727  100000000  % 44,24  2,86359  2,60037  OK   OK    OK / OK  63501754  % 27,85
NullCoder-NullM       XNull-Null                          26852844   58720195  % 54,27  1,46434  1,36549  OK   OK    OK / OK  43596477  % 51,62
NullCoder-NullM       XNull-Null                           1820820    3143185  % 42,07  0,07958  0,07351  OK   OK    OK / OK   2108002  % 31,45
NullCoder-NullM       XNull-Null                           3919558   15480545  % 74,68  0,23132  0,25202  OK   OK    OK / OK   9512353  % 70,94
NullCoder-NullM       XNull-Null                            570067     768771  % 25,85  0,02549  0,02199  OK   OK    OK / OK    435043  % 20,20
NullCoder-NullM       XNull-Null                             23219      44226  % 47,50  0,00633  0,00486  OK   OK    OK / OK     26990  % 47,50


ContextBuffer := ((ContextBuffer shl 4) and $FFFFFFF + CurByte);

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          55719472  100000000  % 44,28  2,8436   2,65318  OK   OK    OK / OK  63501754  % 27,89
NullCoder-NullM       XNull-Null                          26822117   58720195  % 54,32  1,32110  1,36923  OK   OK    OK / OK  43596477  % 51,65
NullCoder-NullM       XNull-Null                           1823435    3143185  % 41,99  0,07860  0,07444  OK   OK    OK / OK   2108002  % 31,36
NullCoder-NullM       XNull-Null                           3732185   15480545  % 75,89  0,23238  0,25662  OK   OK    OK / OK   9512353  % 72,15
NullCoder-NullM       XNull-Null                            570317     768771  % 25,81  0,02629  0,02120  OK   OK    OK / OK    435043  % 20,12
NullCoder-NullM       XNull-Null                             23175      44226  % 47,60  0,00571  0,00433  OK   OK    OK / OK     26990  % 47,60

