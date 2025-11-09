Preprocessing functions/algorithms lies in this folder (although you may not see some of them as a preprocessor).

1. BWT : Famous Burrows-Wheeler transform related algorithms.
      a. BWT : 
      b. czBWT : a fast but partial sorting algorithm.
2. E89 : Mostly known as exetransform. if applied, compression ratio increased on exe files ~1-2%
3. ST : a BWT like transform known as Schindler's Transform. Here only ST1 and ST2 implemented. ST3 conversion from LibBsc left unfinished. If I completed some day, it will be added here.
4. MTF: Famous Move To Front algorithm. I got two version. Only the faster one uploaded here.
5. RLE: Run Length Encoding, if you want you can use it as a preprocessor.
6. Lzp54: Double hash Lz variant. If min match length is choosen wisely, increses compression ratio.
7. GrZipIILzp: A lzp preprocessing algorithm used in GrZipII.
8. Lzrw1Kh: Kurt Heanen's Lzrw1 implementation with internal RLE adaptation.
9. LzpGT: Logic that used in Gerard Tamayo's Lzgpt7 applied here. It is a predictor. In low level functions returns two streams one for bits that represent prediction status, and one for unpredicted literals. Then you can compress them accordingly...
10. Shrinker: Very effective Lz variant.
