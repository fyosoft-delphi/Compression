{$I _fsInclude.inc}

unit fs.Generic.Coder.PP.Lzp54;

interface

uses System.Classes, System.SysUtils;

//==============================================================================
//                             LzpEncode & LzpDecode
// Extracted and converted from original source code taken from the link:
//         https://compressionratings.com/files/ecp-0.e.s.zip (LZP_PREP.c)
// Althought conversion carried out on the source code above, the same algorithm
// is also used in GrZipI, https://compressionratings.com/files/grzip-0.7.3.zip
// In this module you can find preprocessor algorithm, based on LZP (c) by
//   Charles Bloom. This preprocessor especially useful on so called
//   'water' data, and also it can help improve BWT speed.
// 2025.10.03 First running copy.
//     -Initial MinMatchLength changed from 38 to 7 (According to my test result.)
//     -Test results saved to ReadMe.fs.Generic.Coder.Lzp54
//     -Extra if with two comparison deleted in LzpEncode.
// 2025.10.04 MinMatchLength converted to variable and started to be taken as
//   parameter of LzpEncode & LzpDecode.
// 2025.10.05 Hash size made variable. Although algorithm has two independent
//   hash tables, only one HasBitSize parameter passed. This value represents
//   the bigger (lower context) hash size, other one (higher context hash table)
//   has size of half of the previous.
//==============================================================================
function Lzp54Encode(InData, OutData: PByte; InLength: Cardinal; HashBitSize, MinMatchLength : byte): Cardinal; overload;
function Lzp54Decode(InData, OutData: PByte; InLength, OutBufSize: Cardinal; HashBitSize, MinMatchLength : byte): Cardinal; overload;

Procedure Lzp54Encode(AStream : TMemoryStream; HashBitSize, MinMatchLength : byte); overload;
Procedure Lzp54Decode(AStream : TMemoryStream); overload;

function LzpEncodePtr(InData, OutData: PByte; InLength: Cardinal; HashBitSize, MinMatchLength : byte): Cardinal; overload;
function LzpDecodePtr(InData, OutData: PByte; InLength: Cardinal; HashBitSize, MinMatchLength : byte): Cardinal; overload;

implementation


function HashFunction4(Index, HMask: Cardinal; PTR: PByte): Cardinal; inline;
 var x: Cardinal;
   begin
     x := (Cardinal(PTR[Index - 4]) shl 24) or (Cardinal(PTR[Index - 3]) shl 16) or
          (Cardinal(PTR[Index - 2]) shl 8) or (Cardinal(PTR[Index - 1]));
     x := (x shr 15) xor x xor (x shr 3);
     Result := x and HMask;
   end;

function HashFunction5(Index, HMask: Cardinal; PTR: PByte): Cardinal; inline;
 var x: Cardinal;
   begin
     x := (Cardinal(PTR[Index - 4]) shl 24) or (Cardinal(PTR[Index - 3]) shl 16) or
          (Cardinal(PTR[Index - 2]) shl 8) or (Cardinal(PTR[Index - 1]));
     x := ((x shr 25) or (Cardinal(PTR[Index - 5]) shl 7)) xor x xor (x shl 4);
     Result := x and HMask;
   end;

Procedure HashFunction(const Index, H4Mask, H5Mask: Cardinal; const PTR: PByte; var h4, h5 : Cardinal); inline;
 var x: Cardinal;
   begin
     x := (Cardinal(PTR[Index - 4]) shl 24) or (Cardinal(PTR[Index - 3]) shl 16) or
          (Cardinal(PTR[Index - 2]) shl 8) or (Cardinal(PTR[Index - 1]));
     h4 := (x shr 15) xor x xor (x shr 3);
     h4 := h4 and H4Mask;
     h5 := ((x shr 25) or (Cardinal(PTR[Index - 5]) shl 7)) xor x xor (x shl 4);
     h5 := h5 and H5Mask;
   end;


//==============================================================================
//         LzpEncode & LzpDecode : in Delphi style indexed implementations
//==============================================================================
procedure OutPutLength(AOutPutLength: Cardinal; OutBuffer: PByte; var OutBufPtr: Cardinal); inline;
   begin
     while AOutPutLength > 254 do
     begin
       OutBuffer[OutBufPtr] := 255;
       System.Dec(AOutPutLength, 255);
       System.Inc(OutBufPtr);
     end;
     OutBuffer[OutBufPtr] := Byte(AOutPutLength);
     System.Inc(OutBufPtr);
   end;

function GetLength(InputBuffer: PByte; var ABufPtr: Cardinal): Cardinal; inline;
   begin
     Result := 0;
     while InputBuffer[ABufPtr] = 255 do // add 255 values if any
     begin
       System.Inc(Result, 255);
       System.Inc(ABufPtr);
     end;
     System.Inc(Result, InputBuffer[ABufPtr]); // add last value not 255
     System.Inc(ABufPtr);
   end;

Procedure PrepareHashTables(HashBitSize : byte; out HashTable4, HashTable5: TArray<PByte>; out HT4Mask, Ht5Mask : Cardinal);
   begin
     Ht4Mask := (1 shl HashBitSize) - 1;
     ht5Mask := (1 shl (HashBitSize - 1)) - 1;
     SetLength(HashTable4, Ht4Mask + 1);
     SetLength(HashTable5, Ht5Mask + 1);
     for var i := 0 to Ht4Mask do
       HashTable4[i] := nil;
     for var i := 0 to Ht5Mask do
       HashTable5[i] := nil;
   end;

function Lzp54Encode(InData, OutData: PByte; InLength: Cardinal; HashBitSize, MinMatchLength : byte): Cardinal;
 var InBufPtr, i, CommonLength, OutLength, HashIndex4, HashIndex5, x: Cardinal;
     HashTable4, HashTable5: TArray<PByte>; //  of PByte;
     PastPointer: PByte;
     HT4Mask, Ht5Mask : Cardinal;
   begin
     PrepareHashTables(HashBitSize, HashTable4, HashTable5, Ht4Mask, Ht5Mask);
     OutLength := 0;
     for i := 0 to 4 do // copy first 5 bytes from source
       OutData[i] := InData[i];
     Inc(OutLength, 5);
     InBufPtr := 5;
     HashTable4[HashFunction4(4, Ht4Mask, InData)] := @InData[4];   // calculate hash4 for BufPtr=4,
     while InBufPtr < InLength do
     begin
//       HashIndex4 := HashFunction4(InBufPtr, InData);
//       HashIndex5 := HashFunction5(InBufPtr, InData);
//       HashFunction(BufPtr, InData, HashIndex4, HashIndex5);
       x := (Cardinal(InData[InBufPtr - 4]) shl 24) or (Cardinal(InData[InBufPtr - 3]) shl 16) or
            (Cardinal(InData[InBufPtr - 2]) shl 8) or (Cardinal(InData[InBufPtr - 1]));
       HashIndex4 := ((x shr 15) xor x xor (x shr 3)) and HT4Mask;
       HashIndex5 := (((x shr 25) or (Cardinal(InData[InBufPtr - 5]) shl 7)) xor x xor (x shl 4)) and HT5Mask;
       // First take old hash pointers, check them, and find PastPointer
       if HashTable5[HashIndex5] <> nil then
         PastPointer := HashTable5[HashIndex5]
       else PastPointer := HashTable4[HashIndex4];
       // Then update hash pointers with new value
       HashTable5[HashIndex5] := @InData[InBufPtr];
       HashTable4[HashIndex4] := @InData[InBufPtr];
       if (PastPointer <> nil) then
       begin
         CommonLength := 0;
         while (InBufPtr < InLength) and (InData[InBufPtr] = PastPointer[CommonLength]) do
         begin
           Inc(InBufPtr);
           Inc(CommonLength);
         end;
         if CommonLength >= MinMatchLength then
           OutPutLength(256 + CommonLength - MinMatchLength, OutData, OutLength)
         else
         begin
           Dec(InBufPtr, CommonLength); // undo the search increments
           OutPutLength(Cardinal(InData[InBufPtr]), OutData, OutLength);
           Inc(InBufPtr);
         end;
       end
       else
       begin
         OutData[OutLength] := InData[InBufPtr];
         Inc(OutLength);
         Inc(InBufPtr);
       end;
     end;
     Result := OutLength;
   end;

function Lzp54Decode(InData, OutData: PByte; InLength, OutBufSize: Cardinal; HashBitSize, MinMatchLength : byte): Cardinal;
 var InBufPtr, i, j, CommonLength, OutLength, HashIndex4, HashIndex5, x: Cardinal;
     HashTable4, HashTable5: TArray<PByte>;
     PastPointer: PByte;
     HT4Mask, Ht5Mask : Cardinal;
   begin
     PrepareHashTables(HashBitSize, HashTable4, HashTable5, Ht4Mask, Ht5Mask);
     OutLength := 0;
     for i := 0 to 4 do // copy first 5 bytes from source
       OutData[i] := InData[i];
     Inc(OutLength, 5);
     InBufPtr := 5;
     HashTable4[HashFunction4(4, Ht4Mask, OutData)] := @OutData[4];  // calculate hash4 for BufPtr=4,
     while (InBufPtr < InLength) and (OutLength < OutBufSize) do
     begin
//       HashIndex4 := HashFunction4(OutLength, OutData);
//       HashIndex5 := HashFunction5(OutLength, OutData);
//       HashFunction(OutLength, OutData, HashIndex4, HashIndex5);
       x := (Cardinal(OutData[OutLength - 4]) shl 24) or (Cardinal(OutData[OutLength - 3]) shl 16) or
            (Cardinal(OutData[OutLength - 2]) shl 8) or (Cardinal(OutData[OutLength - 1]));
       HashIndex4 := ((x shr 15) xor x xor (x shr 3)) and Ht4Mask;
       HashIndex5 := (((x shr 25) or (Cardinal(OutData[OutLength - 5]) shl 7)) xor x xor (x shl 4)) and Ht5Mask;
       // First take old hash pointers, check them, and find PastPointer
       if HashTable5[HashIndex5] <> nil then
         PastPointer := HashTable5[HashIndex5]
       else PastPointer := HashTable4[HashIndex4];
       // Then update hash pointers with new value
       HashTable5[HashIndex5] := @OutData[OutLength];
       HashTable4[HashIndex4] := @OutData[OutLength];
       if (PastPointer <> nil) then
       begin
         CommonLength := GetLength(InData, InBufPtr);
         if CommonLength < 256 then
         begin
           OutData[OutLength] := Byte(CommonLength);
           Inc(OutLength);
         end
         else
         begin
           CommonLength := (CommonLength + MinMatchLength) - 256;
           j := 0;
           while (CommonLength > 0) and (OutLength < OutBufSize) do
           begin
             OutData[OutLength] := PastPointer[j];
             Inc(OutLength);
             Inc(j);
             Dec(CommonLength);
           end;
         end;
       end
       else
       begin
         OutData[OutLength] := InData[InBufPtr];
         Inc(OutLength);
         Inc(InBufPtr);
       end;
     end;
     Result := OutLength;
   end;

Procedure Lzp54Encode(AStream : TMemoryStream; HashBitSize, MinMatchLength : byte);
 var Temp : TMemoryStream;
     OriSize, EncodedSize : Cardinal;
   begin
     Temp := TMemoryStream.Create;
     try
       OriSize := AStream.Size;
       Temp.Size := Round(OriSize * 1.5) + 4 * 1024;
       EncodedSize := Lzp54Encode(AStream.Memory, Temp.Memory, AStream.Size, HashBitSize, MinMatchLength);
       Temp.Position := 0;
       AStream.Position := 0; // prepare destination
       AStream.Write(OriSize, SizeOf(OriSize));
       AStream.Write(HashBitSize, SizeOf(HashBitSize));
       AStream.Write(MinMatchLength, SizeOf(MinMatchLength));
       AStream.Size := EncodedSize + AStream.Position;
       Move(Temp.Memory^, PByte(PByte(AStream.Memory)+AStream.Position)^, EncodedSize);
       AStream.Position := 0; // it is a new stream so seek to beginning
     finally
       Temp.Free;
     end;
   end;

Procedure Lzp54Decode(AStream : TMemoryStream);
 var Temp : TMemoryStream;
     OriginalSize, DecodedSize : Cardinal;
     HashBitSize, MinMatchLength : byte;
   begin
     Temp := TMemoryStream.Create;
     try
       AStream.Position := 0;
       AStream.Read(OriginalSize, sizeof(OriginalSize));
       AStream.Read(HashBitSize, sizeof(HashBitSize));
       AStream.Read(MinMatchLength, sizeof(MinMatchLength));
       Temp.Size := OriginalSize; //  + 4 * 1024; // we know the original size exactly, just for mem safety 4K buffer added.
       DecodedSize := Lzp54Decode(PByte(AStream.Memory) + AStream.Position, Temp.Memory, AStream.Size, OriginalSize, HashBitSize, MinMatchLength);
       if (DecodedSize = OriginalSize) then
       begin
         AStream.Size := DecodedSize;
         Move(Temp.Memory^, AStream.Memory^, DecodedSize);
         AStream.Position := 0;
       end
       else raise Exception.CreateFmt('Lzp: size mismatch in encoded & decoded data (%u-%u).', [OriginalSize, DecodedSize]);
     finally
       Temp.Free;
     end;
   end;

Procedure LzpEncode0(AStream : TMemoryStream; HashBitSize, MinMatchLength : byte);
 var Dst : TMemoryStream;
   begin
     Dst := TMemoryStream.Create;
     try
       Dst.Size := Round(AStream.Size * 1.5) + 4 * 1024;
       Dst.Size := Lzp54Encode(AStream.Memory, Dst.Memory, AStream.Size, HashBitSize, MinMatchLength);
       AStream.Size := Dst.Size;
       Dst.Position := 0;
       Move(Dst.Memory^, AStream.Memory^, Dst.Size);
     finally
       Dst.Free;
     end;
   end;

Procedure LzpDecode0(AStream : TMemoryStream; OriginalSize : Int64; HashBitSize, MinMatchLength : byte);
 var Dst : TMemoryStream;
   begin
     Dst := TMemoryStream.Create;
     try
       Dst.Size := OriginalSize; //  + 4 * 1024; // we know the original size exactly, just for mem safety 4K buffer added.
       Dst.Size := Lzp54Decode(AStream.Memory, Dst.Memory, AStream.Size, Dst.Size, HashBitSize, MinMatchLength);
       if (Dst.Size >= OriginalSize) and (Dst.Size < OriginalSize) then
       begin
         if Dst.Size <> OriginalSize then
           Dst.Size := OriginalSize;
         AStream.Size := Dst.Size;
         Move(Dst.Memory^, AStream.Memory^, Dst.Size);
       end
       else raise Exception.CreateFmt('Lzp: size mismatch in encoded & decoded data (%u-%u).', [OriginalSize, Dst.Size]);
     finally
       Dst.Free;
     end;
   end;


//==============================================================================
//           LzpEncodePtr & LzpDecodePtr:Lzp with pointer operations
//==============================================================================
procedure OutPutLengthPtr(AOutPutLength: Cardinal; var OutBuffer: PByte); inline;
   begin
     while AOutPutLength > 254 do
     begin
       OutBuffer^ := 255;
       System.Dec(AOutPutLength, 255);
       System.Inc(OutBuffer);
     end;
     OutBuffer^ := Byte(AOutPutLength);
     System.Inc(OutBuffer);
   end;

function GetLengthPtr(var InputBuffer: PByte): Cardinal; inline;
   begin
     Result := 0;
     while InputBuffer^ = 255 do // add 255 values if any
     begin
       System.Inc(Result, 255);
       System.Inc(InputBuffer);
     end;
     System.Inc(Result, InputBuffer^); // add last value not 255
     System.Inc(InputBuffer);
   end;

function LzpEncodePtr(InData, OutData: PByte; InLength: Cardinal; HashBitSize, MinMatchLength: Byte): Cardinal;
 var InEnd, OutPtr, BasePtr, PastPointer: PByte;
     HashTable4, HashTable5: TArray<PByte>;
     CommonLength, x, HashIndex4, HashIndex5: Cardinal;
     HT4Mask, Ht5Mask : Cardinal;
   begin
     PrepareHashTables(HashBitSize, HashTable4, HashTable5, Ht4Mask, Ht5Mask);
     BasePtr := InData;
     OutPtr := OutData;
     InEnd := InData + InLength;
     Move(InData^, OutPtr^, 5);
     Inc(InData, 5);
     Inc(OutPtr, 5);
     HashTable4[HashFunction4(4, Ht4Mask, BasePtr)] := BasePtr + 4;
     while InData < InEnd do
     begin
       x := (Cardinal((InData - 4)^) shl 24) or (Cardinal((InData - 3)^) shl 16) or
            (Cardinal((InData - 2)^) shl 8)  or Cardinal((InData - 1)^);
       HashIndex4 := ((x shr 15) xor x xor (x shr 3)) and Ht4Mask;
       HashIndex5 := (((x shr 25) or (Cardinal((InData - 5)^) shl 7)) xor x xor (x shl 4)) and Ht5Mask;
       if HashTable5[HashIndex5] <> nil then
         PastPointer := HashTable5[HashIndex5]
       else PastPointer := HashTable4[HashIndex4];
       HashTable5[HashIndex5] := InData;
       HashTable4[HashIndex4] := InData;
       if PastPointer <> nil then
       begin
         CommonLength := 0;
         while (InData < InEnd) and (PastPointer < InEnd) and (InData^ = PastPointer^) do
         begin
           Inc(InData);
           Inc(PastPointer);
           Inc(CommonLength);
         end;
         if CommonLength >= MinMatchLength then
           OutPutLengthPtr(256 + CommonLength - MinMatchLength, OutPtr)
         else
         begin
           Dec(InData, CommonLength);
           OutPtr^ := InData^;
           Inc(OutPtr);
           Inc(InData);
         end;
       end
       else
       begin
         OutPtr^ := InData^;
         Inc(OutPtr);
         Inc(InData);
       end;
     end;
     Result := Cardinal(OutPtr - OutData);
   end;

function LzpDecodePtr(InData, OutData: PByte; InLength: Cardinal; HashBitSize, MinMatchLength: Byte): Cardinal;
 var InEnd, OutPtr, BasePtr, PastPointer: PByte;
     HashTable4, HashTable5: TArray<PByte>;
     CommonLength, x, HashIndex4, HashIndex5: Cardinal;
     HT4Mask, Ht5Mask : Cardinal;
   begin
     PrepareHashTables(HashBitSize, HashTable4, HashTable5, Ht4Mask, Ht5Mask);
     BasePtr := OutData;
     OutPtr := OutData;
     InEnd := InData + InLength;
     Move(InData^, OutPtr^, 5);
     Inc(InData, 5);
     Inc(OutPtr, 5);
     HashTable4[HashFunction4(4, Ht4Mask, BasePtr)] := BasePtr + 4;
     while InData < InEnd do
     begin
       x := (Cardinal((OutPtr - 4)^) shl 24) or (Cardinal((OutPtr - 3)^) shl 16) or
            (Cardinal((OutPtr - 2)^) shl 8)  or Cardinal((OutPtr - 1)^);

       HashIndex4 := ((x shr 15) xor x xor (x shr 3)) and Ht4Mask;
       HashIndex5 := (((x shr 25) or (Cardinal((OutPtr - 5)^) shl 7)) xor x xor (x shl 4)) and Ht5Mask;

       if HashTable5[HashIndex5] <> nil then
         PastPointer := HashTable5[HashIndex5]
       else PastPointer := HashTable4[HashIndex4];
       // Hash tablolarýný güncelle
       HashTable5[HashIndex5] := OutPtr;
       HashTable4[HashIndex4] := OutPtr;
       if PastPointer <> nil then
       begin
         CommonLength := GetLengthPtr(InData); // isteðe göre deðiþtirilebilir
         if CommonLength < 256 then
         begin
           OutPtr^ := Byte(CommonLength);
           Inc(OutPtr);
         end
         else
         begin
           CommonLength := (CommonLength + MinMatchLength) - 256;
           while (CommonLength > 0) do //  and (PastPointer < OutEnd) and (OutPtr < OutEnd) do
           begin
             OutPtr^ := PastPointer^;
             Inc(OutPtr);
             Inc(PastPointer);
             Dec(CommonLength);
           end;
         end;
       end
       else
       begin
         OutPtr^ := InData^;
         Inc(OutPtr);
         Inc(InData);
       end;
     end;
     Result := Cardinal(OutPtr - OutData);
   end;


//==============================================================================
//                                 Self Test Functions
//==============================================================================
Procedure TestLzp;
 var S, D, O : TMemoryStream;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         o := TMemoryStream.Create;
         try
           s.LoadFromFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas');
           d.Size := s.Size * 2; // create room for encoding;
           d.Size := Lzp54Encode(S.Memory, D.Memory, S.Size, 19, 7);
           o.Size := s.Size * 2; // create room for decoding
           o.Size := Lzp54Decode(D.Memory, o.Memory, D.Size, o.Size, 19, 7);
           if (o.Size <> s.Size) or (CompareMem(S.Memory, O.Memory, S.Size) = false) then
             raise Exception.Create('Lzp: Integrity check failed.');
         finally
           FreeAndNil(o);
         end;
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;

Procedure TestLzpPtr;
 var S, D, O : TMemoryStream;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         o := TMemoryStream.Create;
         try
           s.LoadFromFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas');
           d.Size := s.Size * 2; // create room for encoding;
           d.Size := LzpEncodePtr(S.Memory, D.Memory, S.Size, 19, 7);
           o.Size := s.Size * 2; // create room for decoding
           o.Size := LzpDecodePtr(D.Memory, o.Memory, D.Size, 19, 7);
           if (o.Size <> s.Size) or (CompareMem(S.Memory, O.Memory, S.Size) = false) then
             raise Exception.Create('Lzp: Integrity check failed.');
         finally
           FreeAndNil(o);
         end;
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;

Procedure TestLzpStm;
 var S, D : TMemoryStream;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas');
         d.LoadFromFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas');
         Lzp54Encode(D, 19, 7);
         d.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-lzp54z.pas');
         Lzp54Decode(D);
         d.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-lzp54.pas');
         if (d.Size <> s.Size) or (CompareMem(S.Memory, d.Memory, S.Size) = false) then
           raise Exception.Create('Lzp: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;


//==============================================================================
//                              First running versions
//==============================================================================
{function LzpEncode(InData, OutData: PByte; InLength: Cardinal): Cardinal;
 var BufPtr, i, CommonLength, OutLength, HashIndex4, HashIndex5: Cardinal;
     HashTable4, HashTable5: TArray<PByte>; //  of PByte;
     PastPointer: PByte;
   begin
     SetLength(HashTable4, HTSIZE4);
     SetLength(HashTable5, HTSIZE5);
     for i := 0 to HTSIZE4 - 1 do
       HashTable4[i] := nil;
     for i := 0 to HTSIZE5 - 1 do
       HashTable5[i] := nil;
     OutLength := 0;
     for i := 0 to 4 do // copy first 5 bytes from source
       OutData[i] := InData[i];
     Inc(OutLength, 5);
     BufPtr := 5;
     HashTable4[HashFunction4(4, InData)] := @InData[4];   // calculate hash4 for BufPtr=4,
     while BufPtr < InLength do
     begin
       HashIndex4 := HashFunction4(BufPtr, InData);
       HashIndex5 := HashFunction5(BufPtr, InData);
       // First take old hash pointers, check them, and find PastPointer
       if HashTable5[HashIndex5] <> nil then
         PastPointer := HashTable5[HashIndex5]
       else PastPointer := HashTable4[HashIndex4];
       // Then update hash pointers with new value
       HashTable5[HashIndex5] := @InData[BufPtr];
       HashTable4[HashIndex4] := @InData[BufPtr];
       if (PastPointer <> nil) then
       begin
         CommonLength := 0;
         while (BufPtr < InLength) and (InData[BufPtr] = PastPointer[CommonLength]) do
         begin
           Inc(BufPtr);
           Inc(CommonLength);
         end;
         if (CommonLength > 0) and (CommonLength < MinMatchLength) then
         begin
           Dec(BufPtr, CommonLength);
           CommonLength := 0;
         end;
         if CommonLength > 0 then
           OutPutLength(256 + CommonLength - MinMatchLength, OutData, OutLength)
         else
         begin
           OutPutLength(Cardinal(InData[BufPtr]), OutData, OutLength);
           Inc(BufPtr);
         end;
       end
       else
       begin
         OutData[OutLength] := InData[BufPtr];
         Inc(OutLength);
         Inc(BufPtr);
       end;
     end;
     Result := OutLength;
   end;

function LzpDecode(InData, OutData: PByte; InLength: Cardinal): Cardinal;
 var BufPtr, i, j, CommonLength, OutLength, HashIndex4, HashIndex5: Cardinal;
     HashTable4, HashTable5: TArray<PByte>;
     PastPointer: PByte;
   begin
     SetLength(HashTable4, HTSIZE4);
     SetLength(HashTable5, HTSIZE5);
     for i := 0 to HTSIZE4 - 1 do
       HashTable4[i] := nil;
     for i := 0 to HTSIZE5 - 1 do
       HashTable5[i] := nil;
     OutLength := 0;
     for i := 0 to 4 do // Ýlk 5 byte'ý kopyala
       OutData[i] := InData[i];
     Inc(OutLength, 5);
     BufPtr := 5;
     HashTable4[HashFunction4(4, OutData)] := @OutData[4];
     while BufPtr < InLength do
     begin
       HashIndex4 := HashFunction4(OutLength, OutData);
       HashIndex5 := HashFunction5(OutLength, OutData);
       // First take old hash pointers, check them, and find PastPointer
       if HashTable5[HashIndex5] <> nil then
         PastPointer := HashTable5[HashIndex5]
       else PastPointer := HashTable4[HashIndex4];
       // Then update hash pointers with new value
       HashTable5[HashIndex5] := @OutData[OutLength];
       HashTable4[HashIndex4] := @OutData[OutLength];
       if (PastPointer <> nil) then
       begin
         CommonLength := GetLength(InData, BufPtr);
         if CommonLength < 256 then
         begin
           OutData[OutLength] := Byte(CommonLength);
           Inc(OutLength);
         end
         else
         begin
           CommonLength := (CommonLength + MinMatchLength) - 256;
           j := 0;
           while CommonLength > 0 do
           begin
             OutData[OutLength] := PastPointer[j];
             Inc(OutLength);
             Inc(j);
             Dec(CommonLength);
           end;
         end;
       end
       else
       begin
         OutData[OutLength] := InData[BufPtr];
         Inc(OutLength);
         Inc(BufPtr);
       end;
     end;
     Result := OutLength;
   end;


function LzpDecode(InData, OutData: PByte; InLength: Cardinal): Cardinal;
 var BufPtr, i, j, CommonLength, OutLength, HashIndex4, HashIndex5: Cardinal;
     HashTable4, HashTable5: array of PByte;
     PastPointer: PByte;
   begin
     SetLength(HashTable4, HTSIZE4);
     SetLength(HashTable5, HTSIZE5);
     for i := 0 to HTSIZE4 - 1 do
       HashTable4[i] := nil;
     for i := 0 to HTSIZE5 - 1 do
       HashTable5[i] := nil;
     OutLength := 0;
     for i := 0 to 4 do // Ýlk 5 byte'ý kopyala
       OutData[i] := InData[i];
     Inc(OutLength, 5);
     BufPtr := 5;
     HashTable4[HashFunction4(4, OutData)] := @OutData[4];
     while BufPtr < InLength do
     begin
       HashIndex4 := HashFunction4(OutLength, OutData);
       HashIndex5 := HashFunction5(OutLength, OutData);
       // First take old hash pointers, check them, and find PastPointer
       if HashTable5[HashIndex5] <> nil then
         PastPointer := HashTable5[HashIndex5]
       else PastPointer := HashTable4[HashIndex4];
       // Then update hash pointers with new value
       HashTable5[HashIndex5] := @OutData[OutLength];
       HashTable4[HashIndex4] := @OutData[OutLength];
       if (PastPointer <> nil) then
       begin
         CommonLength := GetLength(InData, BufPtr);
         if CommonLength < 256 then
         begin
           OutData[OutLength] := Byte(CommonLength);
           Inc(OutLength);
         end
         else
         begin
           CommonLength := (CommonLength + MinMatchLength) - 256;
           j := 0;
           while CommonLength > 0 do
           begin
             OutData[OutLength] := PastPointer[j];
             Inc(OutLength);
             Inc(j);
             Dec(CommonLength);
           end;
         end;
       end
       else
       begin
         OutData[OutLength] := InData[BufPtr];
         Inc(OutLength);
         Inc(BufPtr);
       end;
     end;
     Result := OutLength;
   end;
}


{$IFDEF SELFTESTDEBUGMODE}
initialization
  TestLzp;
  TestLzpPtr;
  TestLzpStm;
{$ENDIF}
end.





