// 2025.01.26 Simple MTF compression algorithm redesigned as descended of
//   TExtMemoryStream. First running copy
// 2025.09.11 Redesigned as a procedure, to be able to use it as a function that
//   operating on single source stream (namely its Memory variable).

unit fs.Generic.Coder.PP.E89;

interface

uses System.Classes;

{Algorithm             Level                               Zip Size   Ori Size  C. Rate  ZipTime  UnZTime  CRC  BYTE  FLAGS    Expected  P. Rate
--------------------  ----------------------------------  --------  ---------  -------  -------  -------  ---  ----  -------  --------  -------
NullCoder-Lazy3 E8    XNull-L3[3](L1,1)(O10,3)(i2,1)D1    20112382   58720195  % 65,75  2,58961  1,19735  OK   OK    OK / OK  43596477  % 63,41
NullCoder-Lazy3 E89   XNull-L3[3](L1,1)(O10,3)(i2,1)D1    20120124   58720195  % 65,74  2,59603  1,21366  OK   OK    OK / OK  43596477  % 64,12
}

//==============================================================================
//             E8 Executable file preprocessing functions
// Converted from original C source code taken from the link:
//   http://www.ezcodesample.com/binarycoder/BALZnoROLZ.txt
// You can use ExeTransform function, to encode (AMode=1) and to decode (AMode=0)
// ExeTransform splitted into Encode-Decode counterparts for easy usage.
// 2025.10.25 When file too small error occured. Resolved by adding filesize
//   control to check if it is greater than 25.
//==============================================================================
procedure ExeTransform(const AMode: Integer; const AData: PByte; const ASize: NativeInt);
procedure E8Encode(const AData: PByte; const ASize: NativeInt);
procedure E8Decode(const AData: PByte; const ASize: NativeInt);

//==============================================================================
//             E89 Executable file preprocessing functions
// Converted from original C source code taken from the link:
//   https://github.com/moinakg/pcompress/blob/master/filters/dispack/dis.cpp
// E8 E9 Call/Jmp transform routines. Convert relative Call and Jmp addresses
// to absolute values to improve compression. A couple of tricks are employed:
//   1) Avoid transforming zero adresses or where adding the current offset to
//      to the presumed address results in a zero result. This avoids a bunch of
//      false positives.
//   2) Store transformed values in big-endian format. This improves compression.
//==============================================================================
function E89Encode(const src: PByte; const sz: UInt64): Integer;
function E89Decode(const src: PByte; const sz: UInt64): Integer;


implementation


//==============================================================================
//             E8 Executable file preprocessing functions
//==============================================================================
procedure E8Encode(const AData: PByte; const ASize: NativeInt);
 var i, endPos: Integer;
     addr: PInteger;
   begin
     if (ASize < 25) or (ASize > High(UInt32)) then
       Exit;
     endPos := ASize - 8;
     i := 0;
     while (PInteger(@AData[i])^ <> $4550) and (i < endPos) do
       System.Inc(i);
     while i < endPos do
     begin
       if (AData[i] and $FE) = $E8 then
       begin
         addr := @AData[i + 1];
         if (addr^ >= -i) and (addr^ < (ASize - i)) then
           addr^ := addr^ + i
         else if (addr^ > 0) and (addr^ < ASize) then
           addr^ := addr^ - ASize;
         System.Inc(i, 5);
       end
       else System.Inc(i);
     end;
   end;

procedure E8Decode(const AData: PByte; const ASize: NativeInt);
 var i, endPos: Integer;
     addr: PInteger;
   begin
     if (ASize < 25) or (ASize > High(UInt32)) then
       Exit;
     endPos := ASize - 8;
     i := 0;
     while (PInteger(@AData[i])^ <> $4550) and (i < endPos) do
       System.Inc(i);
     while i < endPos do
     begin
       if (AData[i] and $FE) = $E8 then
       begin
         addr := @AData[i + 1];
         if addr^ < 0 then
         begin
           if (addr^ + i) >= 0 then
             addr^ := addr^ + ASize;
         end
         else if addr^ < ASize then
           addr^ := addr^ - i;
         System.Inc(i, 5);
       end
       else System.Inc(i);
     end;
   end;

procedure ExeTransform(const AMode: Integer; const AData: PByte; const ASize: NativeInt);
 var i, endPos: Integer;
     addr: PInteger;
   begin
     if (ASize < 25) or (ASize > High(UInt32)) then
       Exit;
     endPos := ASize - 8;
     i := 0;
     while (PInteger(@AData[i])^ <> $4550) and (i < endPos) do
       System.Inc(i);
     while i < endPos do
     begin
       if (AData[i] and $FE) = $E8 then
       begin
         addr := @AData[i + 1];
         if AMode <> 0 then
         begin
           if (addr^ >= -i) and (addr^ < (ASize - i)) then
             addr^ := addr^ + i
           else if (addr^ > 0) and (addr^ < ASize) then
             addr^ := addr^ - ASize;
         end
         else
         begin
           if addr^ < 0 then
           begin
             if (addr^ + i) >= 0 then
               addr^ := addr^ + ASize;
           end
           else if addr^ < ASize then
             addr^ := addr^ - i;
         end;
         System.Inc(i, 5);
       end
       else System.Inc(i);
     end;
   end;


//==============================================================================
//             E89 Executable file preprocessing functions
//==============================================================================
function E89Encode(const src: PByte; const sz: UInt64): Integer;
 var i, size, conversions: UInt32;
     off: UInt32;
   begin
     if (sz > High(UInt32)) or (sz < 25) then
       Exit(-1);
     size := UInt32(sz);
     i := 0;
     conversions := 0;

     while i < size - 4 do
     begin
       if ((src[i] and $FE) = $E8) and ((src[i+4] = 0) or (src[i+4] = $FF)) then
       begin
         off := src[i+1] or (src[i+2] shl 8) or (src[i+3] shl 16);

         if off > 0 then
         begin
           off := off + i;
           off := off and $FFFFFF;

           if off > 0 then
           begin
             src[i+1] := Byte(off shr 16);
             src[i+2] := Byte(off shr 8);
             src[i+3] := Byte(off);
             Inc(conversions);
           end;
         end;
       end;
       Inc(i);
     end;

     if conversions < 5 then
       Result := -1
     else Result := 0;
   end;

function E89Decode(const src: PByte; const sz: UInt64): Integer;
 var i, size: UInt32;
     val: Int32;
   begin
     if sz > High(UInt32) then
       Exit(-1);

     size := UInt32(sz);
     i := size - 5;

     while i > 0 do
     begin
       if ((src[i] and $FE) = $E8) and ((src[i+4] = 0) or (src[i+4] = $FF)) then
       begin
         val := src[i+3] or (src[i+2] shl 8) or (src[i+1] shl 16);

         if val > 0 then
         begin
           val := val - integer(i);
           val := val and $FFFFFF;

           if val > 0 then
           begin
             src[i+1] := Byte(val);
             src[i+2] := Byte(val shr 8);
             src[i+3] := Byte(val shr 16);
           end;
         end;
       end;
       Dec(i);
     end;

     Result := 0;
   end;


end.

