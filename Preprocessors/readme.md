Preprocessing functions/algorithms lies in this folder (although you may not see some of them as a preprocessor).

Test results are given to give an idea about time spent on each process.

1. BWT : Famous Burrows-Wheeler transform related algorithms.

      a. BWT :
   
128K BlockSize used
Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          21194495  211940083   % 0,00  270,380  2,82899  OK   OK    OK / OK  16854728  % -0,01
NullCoder-NullM       XNull-Null                          10000231  100000000   % 0,00  48,0226  1,27054  OK   OK    OK / OK  63501754  % -0,01
NullCoder-NullM       XNull-Null                          58721562   58720195   % 0,00  64,4360  0,72601  OK   OK    OK / OK  43596477  % -0,01
NullCoder-NullM       XNull-Null                           3143280    3143185   % 0,00  25,4692  0,04006  OK   OK    OK / OK   2108002  % -0,01
NullCoder-NullM       XNull-Null                          15480925   15480545   % 0,00  23,8511  0,19726  OK   OK    OK / OK   9512353  % -0,01
NullCoder-NullM       XNull-Null                            768812     768771  % -0,01  0,35542  0,01163  OK   OK    OK / OK    435043  % -0,01
NullCoder-NullM       XNull-Null                             44252      44226  % -0,06  0,02535  0,00066  OK   OK    OK / OK     26990  % -0,06


      b. czBWT : a fast but partial sorting algorithm. (in the following tests E89 active)
Default BlockSize = 0 selected for non-binary files. That means file is encoded as a single block.
This complicates the search algorithm and slows down the process.
For binary files 64-512K-1MB choosen automatically by file size.
In general, for binary files 512K blocksize is best. For huge text files 16 MB block size is enough.

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          21194174  211940083   % 0,00  24,1965  17,1362  OK   OK    OK / OK  16854728  % -0,01
NullCoder-NullM       XNull-Null                          10000080  100000000   % 0,00  11,4571  7,03099  OK   OK    OK / OK  63501754  % -0,01
NullCoder-NullM       XNull-Null                          58720676   58720195   % 0,00  6,80812  4,81185  OK   OK    OK / OK  43596477  % -0,01
NullCoder-NullM       XNull-Null                           3143266    3143185   % 0,00  0,48584  0,31959  OK   OK    OK / OK   2108002  % -0,01
NullCoder-NullM       XNull-Null                          15480586   15480545   % 0,00  1,46810  0,38652  OK   OK    OK / OK   9512353  % -0,01
NullCoder-NullM       XNull-Null                            768812     768771  % -0,01  0,09935  0,05971  OK   OK    OK / OK    435043  % -0,01
NullCoder-NullM       XNull-Null                             44267      44226  % -0,09  0,06266  0,04626  OK   OK    OK / OK     26990  % -0,09

   
3. E89 : Mostly known as exetransform. if applied, compression ratio increased on exe files up to ~1-2%


4. ST : a BWT like transform known as Schindler's Transform. Here only ST1 and ST2 implemented. ST3 conversion from LibBsc left unfinished. If I completed some day, it will be added here.

ST1
Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          21194010  211940083   % 0,00  1,42252  1,99879  OK   OK    OK / OK  16854728  % -0,01
NullCoder-NullM       XNull-Null                          10000001  100000000   % 0,00  0,58761  0,85681  OK   OK    OK / OK  63501754  % -0,01
NullCoder-NullM       XNull-Null                          58720213   58720195   % 0,00  0,39383  0,55848  OK   OK    OK / OK  43596477  % -0,01
NullCoder-NullM       XNull-Null                           3143203    3143185   % 0,00  0,02473  0,02691  OK   OK    OK / OK   2108002  % -0,01
NullCoder-NullM       XNull-Null                          15480563   15480545   % 0,00  0,14488  0,13948  OK   OK    OK / OK   9512353  % -0,01
NullCoder-NullM       XNull-Null                            768789     768771   % 0,00  0,00943  0,00777  OK   OK    OK / OK    435043  % -0,01
NullCoder-NullM       XNull-Null                             44244      44226  % -0,04  0,00143  0,00056  OK   OK    OK / OK     26990  % -0,04

ST2
Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          21194010  211940083   % 0,00  1,83887  4,17603  OK   OK    OK / OK  16854728  % -0,01
NullCoder-NullM       XNull-Null                          10000001  100000000   % 0,00  0,70999  1,41847  OK   OK    OK / OK  63501754  % -0,01
NullCoder-NullM       XNull-Null                          58720214   58720195   % 0,00  0,52064  1,12440  OK   OK    OK / OK  43596477  % -0,01
NullCoder-NullM       XNull-Null                           3143204    3143185   % 0,00  0,03037  0,04141  OK   OK    OK / OK   2108002  % -0,01
NullCoder-NullM       XNull-Null                          15480564   15480545   % 0,00  0,15933  0,21542  OK   OK    OK / OK   9512353  % -0,01
NullCoder-NullM       XNull-Null                            768790     768771   % 0,00  0,00864  0,01039  OK   OK    OK / OK    435043  % -0,01
NullCoder-NullM       XNull-Null                             44245      44226  % -0,04  0,00169  0,00082  OK   OK    OK / OK     26990  % -0,04


5. MTF: Famous Move To Front algorithm. I got two version. Only the faster one uploaded here. (do not change files size but some overhead added by Generic Coder)  (in the following tests E89 active)

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          21194010  211940083   % 0,00  9,60575  8,12375  OK   OK    OK / OK  16854728  % -0,01
NullCoder-NullM       XNull-Null                          10000001  100000000   % 0,00  3,25319  2,81373  OK   OK    OK / OK  63501754  % -0,01
NullCoder-NullM       XNull-Null                          58720212   58720195   % 0,00  2,66089  2,27583  OK   OK    OK / OK  43596477  % -0,01
NullCoder-NullM       XNull-Null                           3143202    3143185   % 0,00  0,10985  0,08818  OK   OK    OK / OK   2108002  % -0,01
NullCoder-NullM       XNull-Null                          15480562   15480545   % 0,00  0,55670  0,43435  OK   OK    OK / OK   9512353  % -0,01
NullCoder-NullM       XNull-Null                            768788     768771   % 0,00  0,02821  0,02065  OK   OK    OK / OK    435043  % -0,01
NullCoder-NullM       XNull-Null                             44243      44226  % -0,04  0,00293  0,00145  OK   OK    OK / OK     26990  % -0,04


5. RLE: Run Length Encoding, if you want you can use it as a preprocessor. (in the following tests E89 active)

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          20067252  211940083   % 5,32  2,07686  1,25809  OK   OK    OK / OK  16854728   % 5,96
NullCoder-NullM       XNull-Null                          99519327  100000000   % 0,48  0,97540  0,54780  OK   OK    OK / OK  63501754   % 0,65
NullCoder-NullM       XNull-Null                          54236984   58720195   % 7,63  0,58658  0,35628  OK   OK    OK / OK  43596477   % 8,88
NullCoder-NullM       XNull-Null                           2700611    3143185  % 14,08  0,03347  0,01693  OK   OK    OK / OK   2108002  % 12,36
NullCoder-NullM       XNull-Null                          15407529   15480545   % 0,47  0,20473  0,08570  OK   OK    OK / OK   9512353   % 0,52
NullCoder-NullM       XNull-Null                            768671     768771   % 0,01  0,01049  0,00413  OK   OK    OK / OK    435043   % 0,01
NullCoder-NullM       XNull-Null                             38916      44226  % 12,01  0,00159  0,00048  OK   OK    OK / OK     26990  % 12,01


6. Lzp54: Double hash Lz variant. If min match length is choosen wisely, increses compression ratio. (in the following tests E89 active)

MinMatch = 3
Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          11308289  211940083  % 46,64  3,66593  2,62370  OK   OK    OK / OK  16854728  % 34,04
NullCoder-NullM       XNull-Null                          70227136  100000000  % 29,77  2,19832  1,23508  OK   OK    OK / OK  63501754  % 27,11
NullCoder-NullM       XNull-Null                          26432856   58720195  % 54,99  1,02057  0,73345  OK   OK    OK / OK  43596477  % 52,39
NullCoder-NullM       XNull-Null                           2006425    3143185  % 36,17  0,06513  0,04237  OK   OK    OK / OK   2108002  % 30,57
NullCoder-NullM       XNull-Null                           2069766   15480545  % 86,63  0,13409  0,08191  OK   OK    OK / OK   9512353  % 83,27
NullCoder-NullM       XNull-Null                            662872     768771  % 13,78  0,02015  0,01405  OK   OK    OK / OK    435043  % 12,65
NullCoder-NullM       XNull-Null                             20513      44226  % 53,62  0,00442  0,00282  OK   OK    OK / OK     26990  % 53,62

MinMatch = 4
Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          11542796  211940083  % 45,54  3,83375  2,46760  OK   OK    OK / OK  16854728  % 32,95
NullCoder-NullM       XNull-Null                          72152907  100000000  % 27,85  2,05560  1,22438  OK   OK    OK / OK  63501754  % 25,23
NullCoder-NullM       XNull-Null                          26972705   58720195  % 54,07  1,03119  0,68334  OK   OK    OK / OK  43596477  % 51,34
NullCoder-NullM       XNull-Null                           2056506    3143185  % 34,57  0,08435  0,04073  OK   OK    OK / OK   2108002  % 29,03
NullCoder-NullM       XNull-Null                           2091546   15480545  % 86,49  0,13296  0,08170  OK   OK    OK / OK   9512353  % 83,01
NullCoder-NullM       XNull-Null                            683298     768771  % 11,12  0,02135  0,01365  OK   OK    OK / OK    435043  % 10,15
NullCoder-NullM       XNull-Null                             20975      44226  % 52,57  0,00454  0,00297  OK   OK    OK / OK     26990  % 52,57


7. GrZipIILzp: A lzp preprocessing algorithm used in GrZipII. (in the following tests E89 active)

MinMatch=3
Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          11193075  211940083  % 47,19  4,69734  2,45249  OK   OK    OK / OK  16854728  % 33,78
NullCoder-NullM       XNull-Null                          67503676  100000000  % 32,50  2,03259  1,05393  OK   OK    OK / OK  63501754  % 28,18
NullCoder-NullM       XNull-Null                          26554294   58720195  % 54,78  1,33032  0,74962  OK   OK    OK / OK  43596477  % 50,41
NullCoder-NullM       XNull-Null                           1965812    3143185  % 37,46  0,06746  0,04188  OK   OK    OK / OK   2108002  % 31,35
NullCoder-NullM       XNull-Null                           2315873   15480545  % 85,04  0,14528  0,08046  OK   OK    OK / OK   9512353  % 81,86
NullCoder-NullM       XNull-Null                            655427     768771  % 14,74  0,02375  0,01566  OK   OK    OK / OK    435043  % 13,48
NullCoder-NullM       XNull-Null                             20751      44226  % 53,08  0,00908  0,00761  OK   OK    OK / OK     26990  % 53,08

MinMatch=4
Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          11496075  211940083  % 45,76  4,77082  2,46845  OK   OK    OK / OK  16854728  % 32,39
NullCoder-NullM       XNull-Null                          69644546  100000000  % 30,36  2,13938  1,00690  OK   OK    OK / OK  63501754  % 26,31
NullCoder-NullM       XNull-Null                          27399467   58720195  % 53,34  1,37924  0,75152  OK   OK    OK / OK  43596477  % 48,89
NullCoder-NullM       XNull-Null                           2020411    3143185  % 35,72  0,06557  0,04162  OK   OK    OK / OK   2108002  % 29,79
NullCoder-NullM       XNull-Null                           2448549   15480545  % 84,18  0,15026  0,08839  OK   OK    OK / OK   9512353  % 81,36
NullCoder-NullM       XNull-Null                            677217     768771  % 11,91  0,02445  0,01431  OK   OK    OK / OK    435043  % 10,86
NullCoder-NullM       XNull-Null                             21273      44226  % 51,90  0,00923  0,00759  OK   OK    OK / OK     26990  % 51,90


8. Lzrw1Kh: Kurt Heanen's Lzrw1 implementation with internal RLE adaptation.  (in the following tests E89 active)

  Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          11204798  211940083  % 47,13  2,24782  1,43591  OK   OK    OK / OK  16854728  % 42,51
NullCoder-NullM       XNull-Null                          59540448  100000000  % 40,46  1,15812  0,75274  OK   OK    OK / OK  63501754  % 41,13
NullCoder-NullM       XNull-Null                          26807121   58720195  % 54,35  0,56177  0,37249  OK   OK    OK / OK  43596477  % 56,37
NullCoder-NullM       XNull-Null                           1690704    3143185  % 46,21  0,03879  0,02251  OK   OK    OK / OK   2108002  % 44,09
NullCoder-NullM       XNull-Null                           3635414   15480545  % 76,52  0,15020  0,08012  OK   OK    OK / OK   9512353  % 76,03
NullCoder-NullM       XNull-Null                            522180     768771  % 32,08  0,01302  0,00700  OK   OK    OK / OK    435043  % 31,84
NullCoder-NullM       XNull-Null                             17895      44226  % 59,54  0,00161  0,00053  OK   OK    OK / OK     26990  % 59,54


10. LzpGT: Logic that used in Gerard Tamayo's Lzgpt7 applied here. It is a predictor. In low level functions returns two streams one for bits that represent prediction status, and one for unpredicted literals. Then you can compress them accordingly...  (in the following tests E89 active)

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          10619846  211940083  % 49,89  2,83307  2,53938  OK   OK    OK / OK  16854728  % 35,24
NullCoder-NullM       XNull-Null                          54448028  100000000  % 45,55  1,49007  1,36044  OK   OK    OK / OK  63501754  % 38,51
NullCoder-NullM       XNull-Null                          26955146   58720195  % 54,10  0,80032  0,77576  OK   OK    OK / OK  43596477  % 50,57
NullCoder-NullM       XNull-Null                           1740568    3143185  % 44,62  0,05421  0,04027  OK   OK    OK / OK   2108002  % 38,85
NullCoder-NullM       XNull-Null                           4098234   15480545  % 73,53  0,16945  0,11314  OK   OK    OK / OK   9512353  % 70,57
NullCoder-NullM       XNull-Null                            523219     768771  % 31,94  0,01859  0,01317  OK   OK    OK / OK    435043  % 30,05
NullCoder-NullM       XNull-Null                             19728      44226  % 55,39  0,00808  0,00630  OK   OK    OK / OK     26990  % 55,39


11. Shrinker: Very effective Lz variant.  (in the following tests E89 active)

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          92063661  211940083  % 56,56  2,07810  1,05675  OK   OK    OK / OK  16854728  % 47,67
NullCoder-NullM       XNull-Null                          50845715  100000000  % 49,15  1,01932  0,51750  OK   OK    OK / OK  63501754  % 48,58
NullCoder-NullM       XNull-Null                          22528465   58720195  % 61,63  0,55776  0,27215  OK   OK    OK / OK  43596477  % 61,22
NullCoder-NullM       XNull-Null                           1463607    3143185  % 53,44  0,03724  0,01639  OK   OK    OK / OK   2108002  % 49,03
NullCoder-NullM       XNull-Null                           2372221   15480545  % 84,68  0,11913  0,06525  OK   OK    OK / OK   9512353  % 83,69
NullCoder-NullM       XNull-Null                            462350     768771  % 39,86  0,01286  0,00485  OK   OK    OK / OK    435043  % 39,26
NullCoder-NullM       XNull-Null                             15397      44226  % 65,19  0,00284  0,00040  OK   OK    OK / OK     26990  % 65,19

12. WFC : Weighted Frequency Count Transformation. It may give better compression ratios over MTF for some file types. (in the following tests E89 active)

Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-NullM       XNull-Null                          10000001  100000000   % 0,00  239,373  231,569  OK   OK    OK / OK  63501754  % -0,01
NullCoder-NullM       XNull-Null                          58720212   58720195   % 0,00  141,723  138,317  OK   OK    OK / OK  43596477  % -0,01
NullCoder-NullM       XNull-Null                           3143202    3143185   % 0,00  7,43302  7,19293  OK   OK    OK / OK   2108002  % -0,01
NullCoder-NullM       XNull-Null                          15480562   15480545   % 0,00  36,7545  35,5187  OK   OK    OK / OK   9512353  % -0,01
NullCoder-NullM       XNull-Null                            768788     768771   % 0,00  1,82123  1,75398  OK   OK    OK / OK    435043  % -0,01
NullCoder-NullM       XNull-Null                             44243      44226  % -0,04  0,10541  0,10158  OK   OK    OK / OK     26990  % -0,04


    
14. 

    
