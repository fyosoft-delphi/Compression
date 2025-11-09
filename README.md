This is a long run journey for me (from 1990 ...)

And compression one of the my first interests.

Although many algorithms (will be published here) converted-written in pascal many years ago (Turbo pascal 3.0, 5.5, Delphi 3.1, Delphi 5 times), they are redesigned-rewritten-reconvert and for ethical reasons as much as possible original sources will be given.
When examining generic structure I realized that my compression algorithm have lots of redundant codes, may be a generic coder simplifies them. And I wrote a generic coder. 
To be able to integrate my existing works, I must redisned them. For this reason created three abstract classes: TAbstractCoder, TAbstractManager & TAbstractModel.,
Generic Coders main function is carrying out preprocessing functions: E89, ST, BWT, MTF, LZP etc. and combining Coder and Model. 
Generic coder can combine any Coder derived from TAbstractCoder with any model derived from TAbstractModel (if they are compatible).
If coder and model are not compatible then generic coder raise an exception.
