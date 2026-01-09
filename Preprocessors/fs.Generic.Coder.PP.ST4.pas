{$I _fsInclude.inc}

unit fs.Generic.Coder.PP.ST4;

interface

uses System.Classes, System.SysUtils, System.Math;

//==============================================================================
//                ST4Encode & ST4Decode preprocessing functions
//                       ST Order-4 Sorting Functions
// Extracted and converted from original source code taken from the link:
//         https://compressionratings.com/files/grzip-0.7.3.zip (st4.inc)
// The same (or recent/modern) file (I think) can be found at the following link:
// https://web.archive.org/web/20070819095130if_/http://magicssoft.ru/content/download/GRZipII/GRZipIISRC.zip
//         Copyright (C) 2002-2004 Grebnov Ilya. All rights reserved.
// This library is free software; you can redistribute it and/or modify it under
// the terms of the GNU Lesser General Public License as published by the Free
// Software Foundation; either version 2.1 of the License, or any later version.
//                Grebnov Ilya, Ivanovo, Russian Federation.
//            Ilya.Grebnov@magicssoft.ru, http://magicssoft.ru/
//
// 2025.11.22 First running copy
// 2025.11.23 Streamed version redesigned so that pointer arithmetic used.
//
// NB: Original algorithm designed to work with block sizes up to 8 MB. And this
//     limitiation is still valid.
//==============================================================================
function ST4Encode(const Input: PByte; Size : Cardinal): Integer; overload;
procedure ST4Decode(const Input: PByte; Size: Cardinal; FBP: Integer); overload;

function ST4Encode(Source, Dest: PByte; SourceSize: Cardinal; out Key: Integer): Cardinal; overload;
procedure ST4Decode(Source, Dest: PByte; SourceSize: Cardinal; Key: Integer); overload;

procedure ST4Encode(Source, Dest: TMemoryStream); overload;
procedure ST4Decode(Source, Dest: TMemoryStream); overload;

Function ST4Encode(Source : TMemoryStream) : boolean; overload;
procedure ST4Decode(Source: TMemoryStream); overload;


implementation

const
     ST_MAXBYTE   = 256;
     ST_MAXWORD   = 65536;
     ST_INDIRECT  = $800000;
     ST_BLOCKSIZE = 8 * 1024 * 1024; // Can be set to any value up to 8 MB due to algorithm architecture.
     ST_MINSIZE   = 4;

Function ST4Encode(Source : TMemoryStream) : boolean;
 var Dest : TMemoryStream;
   begin
     if Source.Size > ST_MINSIZE then
     begin
       Dest := TMemoryStream.Create;
       try
         try
           ST4Encode(Source, Dest);
           Result := true;
         except
           Result := false;
         end;
         if Result then
         begin
           Source.Size := Dest.Size;
           Move(Dest.Memory^, Source.Memory^, Source.Size);
         end;
       finally
         Dest.Free;
       end;
     end
     else Result := false;
   end;

procedure ST4Decode(Source: TMemoryStream);
 var Dest : TMemoryStream;
   begin
     Dest := TMemoryStream.Create;
     try
       ST4Decode(Source, Dest);
       Source.Size := Dest.Size;
       Move(Dest.Memory^, Source.Memory^, Source.Size);
     finally
       Dest.Free;
     end;
   end;

function ST4Encode(Source, Dest: PByte; SourceSize: Cardinal; out Key: Integer): Cardinal;
   begin
     if SourceSize < 4 then
     begin
       Key := -1;
       Result := 0;
       Exit;
     end;
     if Source <> Dest then // copy data from Source to Dest for in-place transform
       Move(Source^, Dest^, SourceSize);
     Key := ST4Encode(Dest, SourceSize);
     Result := SourceSize;
   end;

procedure ST4Decode(Source, Dest: PByte; SourceSize: Cardinal; Key: Integer);
   begin
     if SourceSize = 0 then Exit;
     if Source <> Dest then // copy data from Source to Dest for in-place transform
       Move(Source^, Dest^, SourceSize);
     ST4Decode(Dest, SourceSize, Key);
   end;

procedure ST4Encode(Source, Dest: TMemoryStream);
 var SourcePtr, DestPtr, KeysPtr: PByte;
     BytesRemaining, EstimatedSize, OriginalSize, DestSize : Int64;
     Key, CurrentBlockSize, MaxBlockCount: Integer;
     EncodedSize: UInt32;
   begin
     Source.Position := 0;
     Dest.Position := 0;
     OriginalSize := Source.Size;
     DestSize := 0;
     MaxBlockCount := (OriginalSize + ST_BLOCKSIZE - 1) div ST_BLOCKSIZE; // calculate number of block
     // calculate necessary space needed on dest stream: Header + Keys + Data
     EstimatedSize := SizeOf(UInt32) +                    // OriginalSize
                      SizeOf(Word) +                      // BlockCount
                      (MaxBlockCount * SizeOf(Integer)) + // Keys
                      OriginalSize +                      // Data
                      (1024 * 4);                         // Extra buffer (4KB) for safety
     Dest.Size := EstimatedSize; // Reserve memory on Destination stream
     DestPtr := Dest.Memory;
     PUInt32(DestPtr)^ := UInt32(OriginalSize); // Header: Original Size
     Inc(DestPtr, Sizeof(UInt32));
     Inc(DestSize, Sizeof(UInt32));

     PWord(DestPtr)^ := Word(MaxBlockCount);  // number of blocks as a word type value
     Inc(DestPtr, Sizeof(Word));
     Inc(DestSize, Sizeof(Word));

     KeysPtr := DestPtr; // keys will be saved here
     Inc(DestPtr, MaxBlockCount * Sizeof(integer));  // reserve space for keys
     Inc(DestSize, MaxBlockCount * Sizeof(integer));

     SourcePtr := Source.Memory;
     BytesRemaining := OriginalSize;
     while BytesRemaining > 0 do
     begin
       CurrentBlockSize := Min(ST_BLOCKSIZE, BytesRemaining);
       EncodedSize := ST4Encode(SourcePtr, DestPtr, CurrentBlockSize, Key);
       PInteger(KeysPtr)^ := Key; // Save Key to header
       Inc(PInteger(KeysPtr));  // move to next key position
       Inc(SourcePtr, CurrentBlockSize); // move pointers
       Inc(DestPtr, EncodedSize);   // move pointers
       Inc(DestSize, EncodedSize);  // update actual destination size
       Dec(BytesRemaining, CurrentBlockSize);
     end;
     Dest.Size := DestSize; // update destination data size
   end;

procedure ST4Decode(Source, Dest: TMemoryStream);
 var SourcePtr, DestPtr, KeysPtr: PByte;
     OriginalSize: UInt32;
     MaxBlockCount: Word;
     Key, CurrentBlockSize, i: Integer;
     BytesProcessed: Int64;
   begin
     Source.Position := 0;
     SourcePtr := Source.Memory;
     OriginalSize := PUInt32(SourcePtr)^;  // read header: original filesize
     Inc(SourcePtr, SizeOf(UInt32));
     MaxBlockCount := PWord(SourcePtr)^;  // read header: block count
     Inc(SourcePtr, SizeOf(Word));
     KeysPtr := SourcePtr;  // save adress of the keys pointer for later loading
     Inc(SourcePtr, MaxBlockCount * SizeOf(Integer));  // skip to data
     Dest.Size := OriginalSize; // prepare space for decoding on destination
     DestPtr := Dest.Memory;
     BytesProcessed := 0;
     for i := 0 to MaxBlockCount - 1 do
     begin
       CurrentBlockSize := Min(ST_BLOCKSIZE, OriginalSize - BytesProcessed);
       Key := PInteger(KeysPtr)^;  // read key of current block
       Inc(KeysPtr, SizeOf(Integer));
       ST4Decode(SourcePtr, DestPtr, CurrentBlockSize, Key);
       Inc(SourcePtr, CurrentBlockSize);
       Inc(DestPtr, CurrentBlockSize);
       Inc(BytesProcessed, CurrentBlockSize);
     end;
   end;

function ST4Encode(const Input: PByte; Size : Cardinal): Integer;
 var Counter: TArray<integer>;
     Context: TArray<UInt32>;
     FBP, i: Integer;
     W: UInt32;
     c: byte;
   begin
//     if Size < 0 then
//     begin
//       Result := -1;
//       Exit;
//     end;
     if Size = 0 then
       Exit(0);
     SetLength(Counter, ST_MAXWORD);
     SetLength(Context, Size);
     FillChar(Counter[0], ST_MAXWORD * SizeOf(integer), 0);
     W := UInt32(Input[Size - 1]) shl 8;
     for i := 0 to Size - 1 do
     begin
       W := (W shr 8) or (UInt32(Input[i]) shl 8);
       Inc(Counter[W and $FFFF]);
     end;
     W := 0;
     for i := 0 to ST_MAXWORD - 1 do
     begin
       Inc(W, Counter[i]);
       Counter[i] := W - Counter[i];
     end;
     W := (UInt32(Input[Size - 4]) shl 8) or UInt32(Input[Size - 5]);
     if W = $FFFF then
       FBP := Size - 1
     else FBP := Counter[W + 1] - 1;
     W := (UInt32(Input[Size - 1]) shl 24) or (UInt32(Input[Size - 2]) shl 16) or
          (UInt32(Input[Size - 3]) shl 8) or UInt32(Input[Size - 4]);
     for i := 0 to Size - 1 do
     begin
       c := Input[i];
       var idx := Counter[W and $FFFF];
       Context[idx] := (W and $FFFF0000) or UInt32(c);
       Inc(Counter[W and $FFFF]);
       W := (W shr 8) or (UInt32(c) shl 24);
     end;
     for i := Size - 1 downto FBP do
     begin
       Dec(Counter[Context[i] shr 16]);              // --Counter[...]
       Input[Counter[Context[i] shr 16]] := Byte(Context[i] and $FF); // Context[i] & 0xFF
     end;
     Result := Counter[Context[FBP] shr 16];
     i := FBP - 1;
     while i >= 0 do
     begin
       Dec(Counter[Context[i] shr 16]);
       Input[Counter[Context[i] shr 16]] := Byte(Context[i] and $FF);
       Dec(i);
     end;
     SetLength(Context, 0);
     SetLength(Counter, 0);
   end;

// helpers for bitset
procedure ST_SetBit(var Flag: TBytes; Bit: Integer); inline;
   begin
     Flag[Bit shr 3] := Flag[Bit shr 3] or (1 shl (Bit and 7));
   end;

function ST_GetBit(const Flag: TBytes; Bit: Integer): Boolean; inline;
   begin
     Result := (Flag[Bit shr 3] and (1 shl (Bit and 7))) <> 0;
   end;

procedure ST4Decode(const Input: PByte; Size: Cardinal; FBP: Integer);
 var LastSeen: array[0..ST_MAXBYTE-1] of integer;
     TArr, S: array[0..ST_MAXBYTE-1] of integer;
     Context2: TArray<Integer>;
     Table: TArray<UInt32>;
     Flag: TBytes;
     CStart, Sum, i, j: Integer;
     idx, SumTable: UInt32;
     c: byte;
   begin
     if Size = 0 then Exit;
     SetLength(Context2, ST_MAXWORD);
     SetLength(Flag, ((Size + 8) shr 3));
     SetLength(Table, Size + 1);
     FillChar(Context2[0], ST_MAXWORD * SizeOf(integer), 0);
     FillChar(Flag[0], Length(Flag) * SizeOf(byte), 0);
     FillChar(TArr[0], ST_MAXBYTE * SizeOf(integer), 0);
     FillChar(LastSeen[0], ST_MAXBYTE * SizeOf(integer), $FF); // 0xFF = -1 for Integer
     for i := 0 to Size - 1 do  //   for (i=0;i<Size;i++) T[Input[i]]++;
       Inc(TArr[Input[i]]);
     j := 0;
     Sum := 0;
     for i := 0 to ST_MAXBYTE - 1 do
     begin
       Sum := Sum + Tarr[i];
       Tarr[i] := Sum - Tarr[i]; //oldT;
       while j < Sum do
       begin
         Context2[(Input[j] shl 8) or i] := Context2[(Input[j] shl 8) or i] + 1;
         Inc(j);
       end;
     end;
     Move(TArr[0], S[0], ST_MAXBYTE * SizeOf(integer));
     j := 0;
     Sum := 0;
     for i := 0 to ST_MAXWORD - 1 do
     begin
       CStart := Sum;              // önceki birikmiþ toplam
       Sum := Sum + Context2[i];   // bu baðlamýn frekans miktarý
       while j < Sum do
       begin
         c := Input[j];
         if LastSeen[c] <> CStart then
         begin
           LastSeen[c] := CStart;
           ST_SetBit(Flag, TArr[c]);
         end;
         Inc(Tarr[c]);
         Inc(j);
       end;
     end;
     FillChar(LastSeen[0], ST_MAXBYTE * SizeOf(integer), $FF); // reset LastSeen to zero now for next phase
     CStart := 0;
     for i := 0 to Size - 1 do
     begin
       c := Input[i];
       if ST_GetBit(Flag, i) then
         CStart := i;
       if LastSeen[c] <= CStart then
       begin
         Table[i] := Cardinal(S[c]); // start index for char c
         LastSeen[c] := i + 1;
       end
       else Table[i] := Cardinal((LastSeen[c] - 1) or ST_INDIRECT);
       Inc(S[c]);
       Table[i] := Table[i] or (Cardinal(c) shl 24);
     end;
     Table[Size] := ST_INDIRECT;
     SetLength(Context2, 0);
     SetLength(Flag, 0);
     // Follow chain starting from FBP to reconstruct original Input (overwrite)
     j := FBP;
     SumTable := Table[FBP];
     for i := 0 to Size - 1 do
     begin
       if (SumTable and ST_INDIRECT) <> 0 then
       begin
         idx := SumTable and (ST_INDIRECT - 1);
         j := Integer(Table[idx] and (ST_INDIRECT - 1));
         Table[idx] := Table[idx] + 1;
         SumTable := Table[j];
         Input[i] := Byte(SumTable shr 24);
       end
       else
       begin
         Table[j] := Table[j] + 1;
         j := Integer(SumTable and (ST_INDIRECT - 1));
         SumTable := Table[j];
         Input[i] := Byte(SumTable shr 24);
       end;
     end;
     SetLength(Table, 0);
   end;


Procedure TestST4;
 const TestFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';
// const TestFileName = 'D:\ZipAlgorithmTests\MyMedicine\_MyMedicines.exe';
 var S, D : TMemoryStream;
     AIndex : integer;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(TestFileName);
         d.LoadFromFile(TestFileName);
         AIndex := ST4Encode(D.Memory, D.Size);
         d.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-ST4encoded.txt');
         ST4Decode(D.Memory, D.Size, AIndex);
         d.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-ST4decoded.txt');
         if (d.Size <> s.Size) or (CompareMem(S.Memory, d.Memory, S.Size) = false) then
           raise Exception.Create('ST4: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;

Procedure TestST4Stm;
// const TestFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';
 const TestFileName = 'D:\ZipAlgorithmTests\MyMedicine\_MyMedicines.exe';
 var S, D : TMemoryStream;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(TestFileName);
         ST4Encode(S, D);
         s.Size := 0;
         d.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-ST4encoded.txt');
         D.Position := 0;
         ST4Decode(D, S);
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-ST4decoded.txt');
         d.LoadFromFile(TestFileName);
         if (d.Size <> s.Size) or (CompareMem(S.Memory, d.Memory, S.Size) = false) then
           raise Exception.Create('ST4: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;


initialization
//  TestST4Stm;
end.

