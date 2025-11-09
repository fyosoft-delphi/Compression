Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
((ContextBuffer shl 5) and $FFFFFFF + CurByte)            55006714  100000000  % 44,99  2,55324  2,28558  OK   OK    OK / OK  63501754  % 33,93
((ContextBuffer shl 5) xor CurByte)                       55164097  100000000  % 44,84  2,49975  2,21256  OK   OK    OK / OK  63501754  % 33,89
((ContextBuffer shl 4) xor (CurByte * 17)) and $FFFFFF    55380682  100000000  % 44,62  3,30001  3,24469  OK   OK    OK / OK  63501754  % 27,90
((ContextBuffer shl 4) and $FFFFFFF + CurByte)            55719472  100000000  % 44,28  2,8436   2,65318  OK   OK    OK / OK  63501754  % 27,89
((ContextBuffer shl 4) xor CurByte)                       55755727  100000000  % 44,24  2,86359  2,60037  OK   OK    OK / OK  63501754  % 27,85
((ContextBuffer shl 6) xor CurByte) and $3FFFFFF          56405816  100000000  % 43,59  2,34582  2,02242  OK   OK    OK / OK  63501754  % 37,27
((C shl 3) or (C shr 29) xor (CByte * 131)) and $7FFFFFF  59529992  100000000  % 40,47  3,72325  3,90727  OK   OK    OK / OK  63501754  % 17,25
((ContextBuffer shl 8) or CurByte)                        61120218  100000000  % 38,88  2,13833  1,83719  OK   OK    OK / OK  63501754  % 36,64
((ContextBuffer shl 5) or CurByte)                        62467911  100000000  % 37,53  2,14383  1,83355  OK   OK    OK / OK  63501754  % 32,89
((CtxBuf shl 7) or (CtxtBuf shr 25)) xor CurByte          64819761  100000000  % 35,18  2,31452  2,02043  OK   OK    OK / OK  63501754  % 26,90
(((C shl 7) or (C shr 25)) xor CurByte) and $7FFFFFF      64819761  100000000  % 35,18  2,30140  1,97480  OK   OK    OK / OK  63501754  % 26,90
(RotateLeft32(ContextBuffer,7) xor CurByte) and $7FFFFFF  64819761  100000000  % 35,18  2,59778  2,14122  OK   OK    OK / OK  63501754  % 26,90
((ContextBuffer shl 4) or CurByte)                        69674277  100000000  % 30,33  2,02112  1,74262  OK   OK    OK / OK  63501754  % 26,11


((ContextBuffer shl 4) or CurByte)                        26578408   58720195  % 54,74  1,19879  1,16620  OK   OK    OK / OK  43596477  % 52,90
((ContextBuffer shl 4) and $FFFFFFF + CurByte)            26822117   58720195  % 54,32  1,32110  1,36923  OK   OK    OK / OK  43596477  % 51,65
((ContextBuffer shl 4) xor CurByte)                       26852844   58720195  % 54,27  1,46434  1,36549  OK   OK    OK / OK  43596477  % 51,62
((ContextBuffer shl 4) xor (CurByte * 17)) and $FFFFFF	  27022286   58720195  % 53,98  1,39492  1,50341  OK   OK    OK / OK  43596477  % 51,70
((ContextBuffer shl 5) or CurByte)                        27121315   58720195  % 53,81  1,15331  1,13549  OK   OK    OK / OK  43596477  % 51,98
((ContextBuffer shl 5) and $FFFFFFF + CurByte)            27201076   58720195  % 53,68  1,26065  1,24583  OK   OK    OK / OK  43596477  % 51,36
((ContextBuffer shl 5) xor CurByte)                       27224573   58720195  % 53,64  1,26856  1,23595  OK   OK    OK / OK  43596477  % 51,32
((CtxBuf shl 7) or (CtxtBuf shr 25)) xor CurByte          27522318   58720195  % 53,13  1,23387  1,23609  OK   OK    OK / OK  43596477  % 50,45
(((C shl 7) or (C shr 25)) xor CurByte) and $7FFFFFF      27522318   58720195  % 53,13  1,23726  1,21259  OK   OK    OK / OK  43596477  % 50,45
(RotateLeft32(ContextBuffer,7) xor CurByte) and $7FFFFFF  27522318   58720195  % 53,13  1,36604  1,29121  OK   OK    OK / OK  43596477  % 50,45
((C shl 3) or (C shr 29) xor (CByte * 131)) and $7FFFFFF  27916873   58720195  % 52,46  1,53245  1,59495  OK   OK    OK / OK  43596477  % 50,84
((ContextBuffer shl 6) xor CurByte) and $3FFFFFF          27942389   58720195  % 52,41  1,20608  1,15842  OK   OK    OK / OK  43596477  % 50,48
((ContextBuffer shl 8) or CurByte)                        28721659   58720195  % 51,09  1,17903  1,15677  OK   OK    OK / OK  43596477  % 49,97


((ContextBuffer shl 6) xor CurByte) and $3FFFFFF           1726559    3143185  % 45,07  0,08079  0,06368  OK   OK    OK / OK   2108002  % 38,96
((ContextBuffer shl 5) and $FFFFFFF + CurByte)             1735287    3143185  % 44,79  0,07478  0,06705  OK   OK    OK / OK   2108002  % 36,26
((ContextBuffer shl 5) xor CurByte)                        1736364    3143185  % 44,76  0,0733   0,06508  OK   OK    OK / OK   2108002  % 36,28
((ContextBuffer shl 8) or CurByte)                         1818622    3143185  % 42,14  0,06872  0,06060  OK   OK    OK / OK   2108002  % 38,65
((ContextBuffer shl 4) xor CurByte)                        1820820    3143185  % 42,07  0,07958  0,07351  OK   OK    OK / OK   2108002  % 31,45
((ContextBuffer shl 4) and $FFFFFFF + CurByte)             1823435    3143185  % 41,99  0,07860  0,07444  OK   OK    OK / OK   2108002  % 31,36
((ContextBuffer shl 4) xor (CurByte * 17)) and $FFFFFF     1824106    3143185  % 41,97  0,07377  0,06876  OK   OK    OK / OK   2108002  % 31,26
((ContextBuffer shl 5) or CurByte)                         1839837    3143185  % 41,47  0,06755  0,05850  OK   OK    OK / OK   2108002  % 36,18
((CtxBuf shl 7) or (CtxtBuf shr 25)) xor CurByte           1937735    3143185  % 38,35  0,06994  0,06437  OK   OK    OK / OK   2108002  % 30,95
(RotateLeft32(ContextBuffer,7) xor CurByte) and $7FFFFFF   1937735    3143185  % 38,35  0,07950  0,06988  OK   OK    OK / OK   2108002  % 30,95
(((C shl 7) or (C shr 25)) xor CurByte) and $7FFFFFF       1937735    3143185  % 38,35  0,07659  0,06523  OK   OK    OK / OK   2108002  % 30,95
((ContextBuffer shl 4) or CurByte)                         2003103    3143185  % 36,27  0,06709  0,05912  OK   OK    OK / OK   2108002  % 30,90
((C shl 3) or (C shr 29) xor (CByte * 131)) and $7FFFFFF   2051978    3143185  % 34,72  0,07474  0,07428  OK   OK    OK / OK   2108002  % 22,78


((CtxBuf shl 7) or (CtxtBuf shr 25)) xor CurByte           3598364   15480545  % 76,76  0,21516  0,23459  OK   OK    OK / OK   9512353  % 75,36
(((C shl 7) or (C shr 25)) xor CurByte) and $7FFFFFF       3598364   15480545  % 76,76  0,21512  0,23092  OK   OK    OK / OK   9512353  % 75,36
(RotateLeft32(ContextBuffer,7) xor CurByte) and $7FFFFFF   3598364   15480545  % 76,76  0,23470  0,23661  OK   OK    OK / OK   9512353  % 75,36
((ContextBuffer shl 4) xor (CurByte * 17)) and $FFFFFF     3722210   15480545  % 75,96  0,18238  0,20678  OK   OK    OK / OK   9512353  % 72,13
((ContextBuffer shl 4) and $FFFFFFF + CurByte)             3732185   15480545  % 75,89  0,23238  0,25662  OK   OK    OK / OK   9512353  % 72,15
((C shl 3) or (C shr 29) xor (CByte * 131)) and $7FFFFFF   3760296   15480545  % 75,71  0,18224  0,21347  OK   OK    OK / OK   9512353  % 70,67
((ContextBuffer shl 4) or CurByte)                         3808979   15480545  % 75,40  0,22110  0,22802  OK   OK    OK / OK   9512353  % 73,96
((ContextBuffer shl 4) xor CurByte)                        3919558   15480545  % 74,68  0,23132  0,25202  OK   OK    OK / OK   9512353  % 70,94
((ContextBuffer shl 5) xor CurByte)                        4156003   15480545  % 73,15  0,22868  0,22478  OK   OK    OK / OK   9512353  % 70,45
((ContextBuffer shl 5) and $FFFFFFF + CurByte)             4156003   15480545  % 73,15  0,22851  0,23240  OK   OK    OK / OK   9512353  % 70,45
((ContextBuffer shl 5) or CurByte)                         4159035   15480545  % 73,13  0,22895  0,22863  OK   OK    OK / OK   9512353  % 71,59
((ContextBuffer shl 6) xor CurByte) and $3FFFFFF           4415178   15480545  % 71,48  0,22643  0,22834  OK   OK    OK / OK   9512353  % 69,95
((ContextBuffer shl 8) or CurByte)                         5357335   15480545  % 65,39  0,22668  0,22736  OK   OK    OK / OK   9512353  % 64,97



((ContextBuffer shl 6) xor CurByte) and $3FFFFFF            528861     768771  % 31,21  0,02224  0,01854  OK   OK    OK / OK    435043  % 28,83
((ContextBuffer shl 5) and $FFFFFFF + CurByte)              535055     768771  % 30,40  0,02357  0,01962  OK   OK    OK / OK    435043  % 26,41
((ContextBuffer shl 5) xor CurByte)                         535350     768771  % 30,36  0,02619  0,02040  OK   OK    OK / OK    435043  % 26,40
((ContextBuffer shl 8) or CurByte)                          561040     768771  % 27,02  0,02080  0,01784  OK   OK    OK / OK    435043  % 26,00
((ContextBuffer shl 4) xor (CurByte * 17)) and $FFFFFF      569307     768771  % 25,95  0,02213  0,02239  OK   OK    OK / OK    435043  % 20,23
((ContextBuffer shl 4) xor CurByte)                         570067     768771  % 25,85  0,02549  0,02199  OK   OK    OK / OK    435043  % 20,20
((ContextBuffer shl 4) and $FFFFFFF + CurByte)              570317     768771  % 25,81  0,02629  0,02120  OK   OK    OK / OK    435043  % 20,12
((ContextBuffer shl 5) or CurByte)                          577152     768771  % 24,93  0,02171  0,01752  OK   OK    OK / OK    435043  % 22,96
((CtxBuf shl 7) or (CtxtBuf shr 25)) xor CurByte            608309     768771  % 20,87  0,02319  0,01815  OK   OK    OK / OK    435043  % 17,83
(((C shl 7) or (C shr 25)) xor CurByte) and $7FFFFFF        608309     768771  % 20,87  0,02385  0,01805  OK   OK    OK / OK    435043  % 17,83
(RotateLeft32(ContextBuffer,7) xor CurByte) and $7FFFFFF    608309     768771  % 20,87  0,02554  0,01996  OK   OK    OK / OK    435043  % 17,83
((ContextBuffer shl 4) or CurByte)                          638260     768771  % 16,98  0,01976  0,01717  OK   OK    OK / OK    435043  % 15,07
((C shl 3) or (C shr 29) xor (CByte * 131)) and $7FFFFFF    658774     768771  % 14,31  0,02561  0,02306  OK   OK    OK / OK    435043   % 7,63


((ContextBuffer shl 8) or CurByte)                           20062      44226  % 54,64  0,00572  0,00432  OK   OK    OK / OK     26990  % 54,64
((ContextBuffer shl 6) xor CurByte) and $3FFFFFF             20869      44226  % 52,81  0,00575  0,00535  OK   OK    OK / OK     26990  % 52,81
((ContextBuffer shl 5) or CurByte)                           21282      44226  % 51,88  0,00635  0,00429  OK   OK    OK / OK     26990  % 51,88
((ContextBuffer shl 5) and $FFFFFFF + CurByte)               21654      44226  % 51,04  0,00609  0,00464  OK   OK    OK / OK     26990  % 51,04
((ContextBuffer shl 5) xor CurByte)                          21659      44226  % 51,03  0,00569  0,00537  OK   OK    OK / OK     26990  % 51,03
((ContextBuffer shl 4) or CurByte)                           22519      44226  % 49,08  0,00568  0,00420  OK   OK    OK / OK     26990  % 49,08
((ContextBuffer shl 4) and $FFFFFFF + CurByte)               23175      44226  % 47,60  0,00571  0,00433  OK   OK    OK / OK     26990  % 47,60
((ContextBuffer shl 4) xor (CurByte * 17)) and $FFFFFF       23180      44226  % 47,59  0,00506  0,00420  OK   OK    OK / OK     26990  % 47,59
((ContextBuffer shl 4) xor CurByte)                          23219      44226  % 47,50  0,00633  0,00486  OK   OK    OK / OK     26990  % 47,50
((CtxBuf shl 7) or (CtxtBuf shr 25)) xor CurByte             23512      44226  % 46,84  0,00635  0,00463  OK   OK    OK / OK     26990  % 46,84
(((C shl 7) or (C shr 25)) xor CurByte) and $7FFFFFF         23512      44226  % 46,84  0,00746  0,00463  OK   OK    OK / OK     26990  % 46,84
(RotateLeft32(ContextBuffer,7) xor CurByte) and $7FFFFFF     23512      44226  % 46,84  0,00595  0,00458  OK   OK    OK / OK     26990  % 46,84
((C shl 3) or (C shr 29) xor (CByte * 131)) and $7FFFFFF     25559      44226  % 42,21  0,00461  0,00459  OK   OK    OK / OK     26990  % 42,21
