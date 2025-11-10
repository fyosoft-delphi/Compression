{$I _fsInclude.inc}

unit fs.Generic.Coder.PP.BscLzp;

interface

uses SysUtils, Classes;

const
     BSC_LZP_NO_ERROR = 0;
     BSC_LZP_NOT_COMPRESSIBLE = -1;
     BSC_LZP_NOT_ENOUGH_MEMORY = -2;
     BSC_LZP_UNEXPECTED_EOB = -3;

     LZP_MATCH_FLAG = $F2;


//==============================================================================
//            BscLzpEncode and BscLzpDecode preprocessing functions
//The bsc and libbsc is free software; you can redistribute it and/or modify
//it under the terms of the GNU Lesser General Public License as published by
//the Free Software Foundation; either version 3 of the License, or (at your
//option) any later version.
//See also the bsc and libbsc web site: http://libbsc.com/ for more information.
//       Copyright (c) 2009-2012 Ilya Grebnov <ilya.grebnov@gmail.com>
//       Copyright (c) 2012 Moinak Ghosh <moinakg@gmail.com>
//2025.11.10 First running copy.
//    -Paralel processing functions deleted.
//    -Block based processing deleted. (Instead, soft block may be implemented.)
//    -lowerbound of 4 for MinMatchLength added. Otherwise match logic may corrupt.
//    -Lowerbound of 16 for HashBitSize added.
//    -In match find, triple if checks changed, so that only necessary ones done.
//==============================================================================
function BscLzpEncode(AInputPtr: PByte; const AInputSize : NativeInt; AOutputPtr: PByte; const AOutputSize : NativeInt; AHashBitSize, MinMatchLength: byte): Integer;
function BscLzpDecode(AInputPtr: PByte; AInputSize : NativeInt; AOutputPtr: PByte; AHashBitSize: Integer; MinMatchLength: Integer): Integer;
Function BscLzpEncodeS(ASource : TMemoryStream; HashBitSize: byte; MinMatchLen: Byte) : boolean;
Procedure BscLzpDecodeS(ASource : TMemoryStream);

implementation


function BscLzpEncode(AInputPtr: PByte; const AInputSize : NativeInt; AOutputPtr: PByte; const AOutputSize : NativeInt; AHashBitSize, MinMatchLength: byte): Integer;
 label LZP_MATCH_NOT_FOUND;
 var lookup: TArray<Integer>;
     HashMask, Context, index: Cardinal;
     InputStartPtr, InputEndPtr, OutputStartPtr, outputEOB: PByte;
     reference, heuristic, inputMinLenEnd: PByte;
     i, value, Len: Integer;
     next: Byte;
   begin
     if AInputSize < 16 then  // input file size must be greater than
     begin
       Result := BSC_LZP_NOT_COMPRESSIBLE;
       Exit;
     end;
     if AHashBitSize < 16  then
       AHashBitSize := 16;
     if MinMatchLength < 4 then
       MinMatchLength := 4;
     InputEndPtr := AInputPtr + AInputSize;
     SetLength(lookup, (1 shl AHashBitSize));
     if lookup <> nil then
     begin
       try
         FillChar(lookup[0], Sizeof(lookup), 0);
         HashMask := (1 shl AHashBitSize) - 1;
         InputStartPtr := AInputPtr;
         OutputStartPtr := AOutputPtr;
         outputEOB := AOutputPtr + AOutputSize - 4;
         context := 0;
         for i := 0 to 3 do
         begin
           AOutputPtr^ := AInputPtr^;
           context := (context shl 8) or AInputPtr^;
           Inc(AOutputPtr);
           Inc(AInputPtr);
         end;
         heuristic := AInputPtr;
         inputMinLenEnd := InputEndPtr - MinMatchLength - 8;
         while (AInputPtr < inputMinLenEnd) and (AOutputPtr < outputEOB) do
         begin
           index := ((context shr 15) xor context xor (context shr 3)) and HashMask;
           value := lookup[index];
           lookup[index] := Integer(AInputPtr - InputStartPtr);
           if value > 0 then  // possible match exists at this position
           begin
             reference := InputStartPtr + value; // possible match start adress
             if (PCardinal(AInputPtr + MinMatchLength - 4)^ = PCardinal(reference + MinMatchLength - 4)^) and
                (PCardinal(AInputPtr)^ = PCardinal(reference)^) then
             begin
               if (heuristic > AInputPtr) and (PCardinal(heuristic)^ <> PCardinal(reference + (heuristic - AInputPtr))^) then
               begin
                 goto LZP_MATCH_NOT_FOUND;
               end;
               len := 4;
               while (AInputPtr + len < inputMinLenEnd) do
               begin
                 if PCardinal(AInputPtr + len)^ <> PCardinal(reference + len)^ then
                   Break;
                 Inc(len, 4);
               end;
               if len < MinMatchLength then
               begin
                 if heuristic < AInputPtr + len then
                   heuristic := AInputPtr + len;
                 goto LZP_MATCH_NOT_FOUND;
               end;
               if AInputPtr[len] = reference[len] then // after integer (4 bytes block) comparisons, do up to 3 byte-based checks
               begin
                 Inc(len);
                 if AInputPtr[len] = reference[len] then
                 begin
                   Inc(len);
                   if AInputPtr[len] = reference[len] then
                     Inc(len);
                 end;
               end;
               Inc(AInputPtr, len);
               context := AInputPtr[-1] or (AInputPtr[-2] shl 8) or (AInputPtr[-3] shl 16) or (AInputPtr[-4] shl 24); // update context
               AOutputPtr^ := LZP_MATCH_FLAG;  // save match found flag
               Inc(AOutputPtr);
               Dec(len, MinMatchLength);  // save length. offset maintained by context so no need to save
               while len >= 254 do
               begin
                 Dec(len, 254);
                 AOutputPtr^ := 254;
                 Inc(AOutputPtr);
                 if AOutputPtr >= outputEOB then
                   Break;
               end;
               AOutputPtr^ := Byte(len);
               Inc(AOutputPtr);
             end
             else
             begin
LZP_MATCH_NOT_FOUND:
               next := AInputPtr^;
               AOutputPtr^ := next; // output literal
               Inc(AOutputPtr);
               Inc(AInputPtr);
               context := (context shl 8) or next;   // update context
               if next = LZP_MATCH_FLAG then  // if last outputted literal is a match flag then put an escape flag
               begin
                 AOutputPtr^ := 255;
                 Inc(AOutputPtr);
               end;
             end;
           end
           else
           begin
             context := (context shl 8) or AInputPtr^;
             AOutputPtr^ := AInputPtr^;
             Inc(AOutputPtr);
             Inc(AInputPtr);
           end;
         end;
         // previous loop process until Input-MinMatchLen-8
         while (AInputPtr < InputEndPtr) and (AOutputPtr < outputEOB) do
         begin
           index := ((context shr 15) xor context xor (context shr 3)) and HashMask;
           value := lookup[index];
           lookup[index] := Integer(AInputPtr - InputStartPtr);
           if value > 0 then
           begin
             next := AInputPtr^;
             AOutputPtr^ := next;
             Inc(AOutputPtr);
             Inc(AInputPtr);
             context := (context shl 8) or next;
             if next = LZP_MATCH_FLAG then
             begin
               AOutputPtr^ := 255;
               Inc(AOutputPtr);
             end;
           end
           else
           begin
             context := (context shl 8) or AInputPtr^;
             AOutputPtr^ := AInputPtr^;
             Inc(AOutputPtr);
             Inc(AInputPtr);
           end;
         end;
       finally
         SetLength(lookup, 0);
       end;
       if AOutputPtr >= outputEOB then
         Result := BSC_LZP_NOT_COMPRESSIBLE
       else Result := Integer(AOutputPtr - OutputStartPtr);
     end
     else Result := BSC_LZP_NOT_ENOUGH_MEMORY;
   end;

function BscLzpDecode(AInputPtr: PByte; AInputSize : NativeInt; AOutputPtr: PByte; AHashBitSize: Integer; MinMatchLength: Integer): Integer;
 const offset : array[0..3] of byte = (0, 3, 2, 3);
 var lookup: TArray<Integer>;
     i, value, len: Integer;
     HashMask, context, index: Cardinal;
     InputEndPtr, OutputStartPtr, reference, outputEnd: PByte;
   begin
     if AInputSize < 4 then
     begin
       Result := BSC_LZP_UNEXPECTED_EOB;
       Exit;
     end;
     if AHashBitSize < 16  then
       AHashBitSize := 16;
     if MinMatchLength < 4 then
       MinMatchLength := 4;
     SetLength(lookup, (1 shl AHashBitSize));
     if lookup <> nil then
     begin
       try
         FillChar(lookup[0], sizeof(lookup), 0);
         HashMask := (1 shl AHashBitSize) - 1;
         OutputStartPtr := AOutputPtr;
         InputEndPtr := AInputPtr + AInputSize;
         context := 0;
         for i := 0 to 3 do
         begin
           AOutputPtr^ := AInputPtr^;
           context := (context shl 8) or AOutputPtr^;
           Inc(AOutputPtr);
           Inc(AInputPtr);
         end;
         while AInputPtr < InputEndPtr do
         begin
           try
             index := ((context shr 15) xor context xor (context shr 3)) and HashMask;
             value := lookup[index];
             lookup[index] := Integer(AOutputPtr - OutputStartPtr);
             if (AInputPtr^ = LZP_MATCH_FLAG) and (value > 0) then
             begin
               Inc(AInputPtr);
               if AInputPtr^ <> 255 then // next char is not an escape flag
               begin
                 len := MinMatchLength;
                 while True do
                 begin
                   Inc(len, AInputPtr^);
                   if AInputPtr^ <> 254 then
                     Break;
                   Inc(AInputPtr);
                 end;
                 Inc(AInputPtr);
                 reference := OutputStartPtr + value;
                 outputEnd := AOutputPtr + len;
                 if (AOutputPtr - reference) < 4 then
                 begin
                   AOutputPtr^ := reference^;
                   Inc(AOutputPtr);
                   Inc(reference);
                   AOutputPtr^ := reference^;
                   Inc(AOutputPtr);
                   Inc(reference);
                   AOutputPtr^ := reference^;
                   Inc(AOutputPtr);
                   Inc(reference);
                   AOutputPtr^ := reference^;
                   Inc(AOutputPtr);
                   Inc(reference);
                   Dec(reference, offset[AOutputPtr - reference]); //  - value
                 end;
                 while AOutputPtr < outputEnd do
                 begin
                   PCardinal(AOutputPtr)^ := PCardinal(reference)^;
                   Inc(AOutputPtr, 4);
                   Inc(reference, 4);
                 end;
                 AOutputPtr := outputEnd;
                 context := AOutputPtr[-1] or (AOutputPtr[-2] shl 8) or (AOutputPtr[-3] shl 16) or (AOutputPtr[-4] shl 24);
               end
               else // escape flag detected output match flag as literal
               begin
                 Inc(AInputPtr);
                 context := (context shl 8) or LZP_MATCH_FLAG;
                 AOutputPtr^ := LZP_MATCH_FLAG;
                 Inc(AOutputPtr);
               end;
             end
             else
             begin
               AOutputPtr^ := AInputPtr^;
               context := (context shl 8) or AOutputPtr^;
               Inc(AOutputPtr);
               Inc(AInputPtr);
             end;
           except on E:Exception do
             raise Exception.CreateFmt('Error %s at: %u', [E.Message, AOutputPtr-OutputStartPtr]);
           end;
         end;
       finally
         SetLength(lookup, 0);
       end;
       Result := Integer(AOutputPtr - OutputStartPtr);
     end
     else Result := BSC_LZP_NOT_ENOUGH_MEMORY;
   end;


Function BscLzpEncodeS(ASource : TMemoryStream; HashBitSize: byte; MinMatchLen: Byte) : boolean;
 var Temp : TMemoryStream;
     AEncodedSize : NativeInt;
     AOriginalSize : Cardinal; // NativeInt;
   begin
     Temp := TMemoryStream.Create;
     try
       Temp.Size := ASource.Size + 512; //  round(ASource.Size * 1.2) + 4096;
       AEncodedSize := BscLzpEncode(ASource.Memory, ASource.Size, Temp.Memory, Temp.Size, HashBitSize, MinMatchLen);
       if (AEncodedSize > 0) and (AEncodedSize < ASource.Size) then
       begin
         Temp.Size := AEncodedSize;
         AOriginalSize := ASource.Size;
         ASource.Position := 0;
         ASource.Write(AOriginalSize, sizeof(AOriginalSize));
         ASource.Write(HashBitSize, sizeof(HashBitSize));
         ASource.Write(MinMatchLen, sizeof(MinMatchLen));
         ASource.Size := ASource.Position + Temp.Size;
         Move(Temp.Memory^, (PByte(ASource.Memory) + ASource.Position)^, Temp.Size);
         ASource.Position := 0; // restore position after write operations
         Result := true;
       end
       else Result := false;
     finally
       Temp.Free;
     end;
   end;

Procedure BscLzpDecodeS(ASource : TMemoryStream);
 var Temp : TMemoryStream;
     AOriginalSize : Cardinal; // NativeInt;
     DecodedSize : NativeInt;
     HashBitSize, MinMatchLen : byte;
   begin
     Temp := TMemoryStream.Create;
     try
       ASource.Position := 0;
       ASource.Read(AOriginalSize, sizeof(AOriginalSize));
       ASource.Read(HashBitSize, sizeof(HashBitSize));
       ASource.Read(MinMatchLen, sizeof(MinMatchLen));
       Temp.Size := AOriginalSize;
       DecodedSize := BscLzpDecode(PByte(ASource.Memory)+ASource.Position, ASource.Size-ASource.Position, Temp.Memory, HashBitSize, MinMatchLen);
       if DecodedSize > 0 then
       begin
         ASource.Size := Temp.Size;
         Move(Temp.Memory^, ASource.Memory^, ASource.Size);
         ASource.Position := 0; // restore position after read operations
       end
       else raise Exception.Create('BscLzp: Error on decoding, file may corrupt.');
     finally
       Temp.Free;
     end;
   end;


Const
     TestFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';

Procedure TestLzpPtr;
 var S, D : TMemoryStream;
     EncodedSize, DecodedSize, OriginalSize : Cardinal;
     HashBitSize, MinMatch : byte;
   begin
     HashBitSize := 19;
     MinMatch := 6;
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(TestFileName);
         OriginalSize := s.Size;
         d.Size := OriginalSize + 4096;
         EncodedSize := BscLzpEncode(s.Memory, s.Size, D.Memory, d.Size, HashBitSize, MinMatch);
         d.Size := EncodedSize;
         d.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-bsclzp-z.txt');
         s.Size := 0;
         s.Size := OriginalSize + 4096;
         DecodedSize := BscLzpDecode(D.Memory, D.Size, S.Memory, HashBitSize, MinMatch);
         s.Size := DecodedSize;
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-bsclzp.txt');
         d.Size := 0;
         d.LoadFromFile(TestFileName);
         if (d.Size <> s.Size) or (CompareMem(S.Memory, d.Memory, S.Size) = false) then
           raise Exception.Create('BscLzpPtr: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;

Procedure TestLzpStmS;
 var S, D : TMemoryStream;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(TestFileName);
         BscLzpEncodeS(S, 21, 4);
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-Bsclzp_z.txt');
         BscLzpDecodeS(S);
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-Bsclzp.txt');
         d.Size := 0;
         d.LoadFromFile(TestFileName);
         if (d.Size <> s.Size) or (CompareMem(S.Memory, d.Memory, S.Size) = false) then
           raise Exception.Create('BscLzpStmS: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;


{$IFDEF SELFTESTDEBUGMODE}
initialization
   TestLzpStmS;
   TestLzpPtr;
{$ENDIF}

end.
