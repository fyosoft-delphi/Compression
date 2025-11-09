{$I _fsInclude.inc}

Unit fs.Generic.Coder.PP.Lzpgt;

interface

uses System.SysUtils, System.Classes,
     fs.Core.MemStream, fs.Generic.Utils.StatHelper;

//==============================================================================
//                   Predictive LZP Using Hash Tables
// Main idea is taken from Gerald R. Tamayo's (c) (2022-2023) Lzgpt7 algorithm.
//         https://github.com/grtamayo/lzpgt/blob/main/lzpgt7.c
// 2025.10.26 First Running copy.
// 2025.10.28 Experiments carried ot with various hash functions, and best of
//   them selected for general use. Detailed test results saved to readme file
//   named: readme.fs.generic.coder.pp.lzpgt_detailed hash results.txt
// 2025.10.29 Defaultchar parameter added to low level functions which is used
//   to set default value of hash table, to improve prediction (even thought it
//   is false) ratio.
// 2025.11.05 When defaultchar selected as most frequent char in dataset and set
//   as default hash value (this choice definitely increases the false positives
//   which is intended) then ratio increased and no need for adaptive functions.
//==============================================================================
procedure CompressLZP0(Const ASourceStream, ALiteralStream: TMemoryStream; const ABitStream : TExtMemStream; HashBitSize : byte; DefChar : byte = 0);
procedure DecompressLZP0(Const ABitStream : TExtMemStream; Const ALiteralStream, ADecompStream: TMemoryStream; AOriginalSize : Cardinal; HashBitSize : byte; DefChar : byte = 0);
procedure CompressLZP_P(Const ASourceStream, ALiteralStream: TMemoryStream; const ABitStream : TExtMemStream; HashBitSize : byte; DefChar : byte = 0);
procedure DecompressLZP_P(Const ABitStream : TExtMemStream; Const ALiteralStream, ADecompStream: TMemoryStream; AOriginalSize : Cardinal; HashBitSize : byte; DefChar : byte = 0);
//procedure CompressLZP_AP(Const ASourceStream, ALiteralStream: TMemoryStream; const ABitStream : TExtMemStream; HashBitSize : byte; DefChar : byte = 0);
//procedure DecompressLZP_AP(Const ABitStream : TExtMemStream; Const ALiteralStream, ADecompStream: TMemoryStream; AOriginalSize : Cardinal; HashBitSize : byte; DefChar : byte = 0);
procedure LzpgtEncode(Const ASource: TMemoryStream; HashBitSize : byte);
procedure LzpgtDecode(Const ASource: TMemoryStream);


implementation


Const
     LZPGT_ADAPTIVE_BLOCK = 1024 * 1;
     LZPGT_ADAPTIVE_RATIO = 0.63;
     LZPGT_ADAPTIVE_DECAY = 1;
     LZPGT_DEFAULT_CHAR   = 255;


//==============================================================================
//                             Stream Based Functions.
//==============================================================================
procedure LzpgtEncode(Const ASource: TMemoryStream; HashBitSize : byte);
 var PredictStm, LiteralStm : TExtMemStream;
     ASourceSize, APredictSize, ALiteralSize : Cardinal;
     ADefChar : byte;
   begin
     PredictStm := TExtMemStream.Create;
     try
       LiteralStm := TExtMemStream.Create;
       try
         ADefChar := TStatHelper.GetMostFrequentChar(ASource);
         CompressLZP_P(ASource, LiteralStm, PredictStm, HashBitSize, ADefChar);
         ASourceSize := ASource.Size;
         APredictSize := PredictStm.Size;
         ALiteralSize := LiteralStm.Size;
         ASource.Size := 0; // Clear source stream and prepare for merging
         // Save settings and merge streams
         ASource.Write(ASourceSize, sizeof(ASourceSize)); // save Source data size
         ASource.Write(APredictSize, Sizeof(APredictSize)); // save BitDataSize size
         ASource.Write(ALiteralSize, Sizeof(ALiteralSize)); // save LiteralCount
         ASource.Write(HashBitSize, Sizeof(HashBitSize)); // save HashBitSize
         ASource.Write(ADefChar, Sizeof(ADefChar)); // save HashBitSize
         ASource.Write(LiteralStm.Memory^, LiteralStm.Size); // save literal list first
         ASource.Write(PredictStm.Memory^, PredictStm.Size); // save prediction list
       finally
         LiteralStm.Free;
       end;
     finally
       PredictStm.Free;
     end;
   end;

procedure LzpgtDecode(Const ASource: TMemoryStream);
 var PredictStm, LiteralStm : TExtMemStream;
     ASourceSize, APredictSize, ALiteralSize : Cardinal;
     HashBitSize, ADefChar : byte;
   begin
     PredictStm := TExtMemStream.Create;
     try
       LiteralStm := TExtMemStream.Create;
       try
         ASource.Position := 0;
         ASource.Read(ASourceSize, sizeof(ASourceSize)); // load Source data size
         ASource.Read(APredictSize, Sizeof(APredictSize)); // load BitDataSize size
         ASource.Read(ALiteralSize, Sizeof(ALiteralSize)); // load LiteralCount
         ASource.Read(HashBitSize, Sizeof(HashBitSize)); // load HashBitSize
         ASource.Read(ADefChar, Sizeof(ADefChar)); // load HashBitSize
         PredictStm.Size := APredictSize;
         LiteralStm.Size := ALiteralSize;
         ASource.Read(LiteralStm.Memory^, LiteralStm.Size); // save literal list first
         ASource.Read(PredictStm.Memory^, PredictStm.Size); // save prediction list
         ASource.Size := ASourceSize;
         ASource.Position := 0;
         DecompressLZP_P(PredictStm, LiteralStm, ASource, ASourceSize, HashBitSize, ADefChar);
       finally
         LiteralStm.Free;
       end;
     finally
       PredictStm.Free;
     end;
   end;

procedure LzpgtEncode0(Const ASource: TMemoryStream; HashBitSize : byte);
 var PredictStm, LiteralStm : TExtMemStream;
     ASourceSize, APredictSize, ALiteralSize : Cardinal;
   begin
     PredictStm := TExtMemStream.Create;
     try
       LiteralStm := TExtMemStream.Create;
       try
         CompressLZP0(ASource, LiteralStm, PredictStm, HashBitSize, LZPGT_DEFAULT_CHAR);
         ASourceSize := ASource.Size;
         APredictSize := PredictStm.Size;
         ALiteralSize := LiteralStm.Size;
         ASource.Size := 0; // Clear source stream and prepare for merging
         // Save settings and merge streams
         ASource.Write(ASourceSize, sizeof(ASourceSize)); // save Source data size
         ASource.Write(APredictSize, Sizeof(APredictSize)); // save BitDataSize size
         ASource.Write(ALiteralSize, Sizeof(ALiteralSize)); // save LiteralCount
         ASource.Write(HashBitSize, Sizeof(HashBitSize)); // save HashBitSize
         ASource.Write(LiteralStm.Memory^, LiteralStm.Size); // save prediction list
         ASource.Write(PredictStm.Memory^, PredictStm.Size); // save prediction list
       finally
         LiteralStm.Free;
       end;
     finally
       PredictStm.Free;
     end;
   end;

procedure LzpgtDecode0(Const ASource: TMemoryStream);
 var PredictStm, LiteralStm : TExtMemStream;
     ASourceSize, APredictSize, ALiteralSize : Cardinal;
     HashBitSize : byte;
   begin
     PredictStm := TExtMemStream.Create;
     try
       LiteralStm := TExtMemStream.Create;
       try
         ASource.Position := 0;
         ASource.Read(ASourceSize, sizeof(ASourceSize)); // load Source data size
         ASource.Read(APredictSize, Sizeof(APredictSize)); // load BitDataSize size
         ASource.Read(ALiteralSize, Sizeof(ALiteralSize)); // load LiteralCount
         ASource.Read(HashBitSize, Sizeof(HashBitSize)); // load HashBitSize
         PredictStm.Size := APredictSize;
         LiteralStm.Size := ALiteralSize;
         ASource.Read(LiteralStm.Memory^, LiteralStm.Size); // save prediction list
         ASource.Read(PredictStm.Memory^, PredictStm.Size); // save prediction list
         ASource.Size := ASourceSize;
         ASource.Position := 0;
         DecompressLZP0(PredictStm, LiteralStm, ASource, ASourceSize, HashBitSize, LZPGT_DEFAULT_CHAR);
       finally
         LiteralStm.Free;
       end;
     finally
       PredictStm.Free;
     end;
   end;


//==============================================================================
//                             Base (Original) Functions.
//==============================================================================
procedure CompressLZP0(Const ASourceStream, ALiteralStream: TMemoryStream; const ABitStream : TExtMemStream; HashBitSize : byte; DefChar : byte = 0);
 var AOriginalSize, HashMask, HashSize, ContextBuffer, Context, Cached, Processed, LiteralCount : Cardinal;
     HashTable : TArray<Byte>;
     ADataPtr, LiteralPtr : PByte;
     CurByte, Match : byte;
   begin
     AOriginalSize := ASourceStream.Size;
     ADataPtr := ASourceStream.Memory;
     ABitStream.Size := (AOriginalSize + 7) div 8;
     ABitStream.Position := 0;
     ALiteralStream.Size := AOriginalSize;  // reserve space assuming no right prediction will be made
     LiteralPtr := ALiteralStream.Memory;
     HashSize := 1 shl HashBitSize;
     SetLength(HashTable, HashSize);
     FillChar(HashTable[0], HashSize, DefChar);
     HashMask := HashSize - 1;
     ContextBuffer := 0;
     Context := 0;
     Processed := 0;
     LiteralCount := 0;
     while Processed < AOriginalSize do
     begin
       CurByte := ADataPtr[Processed];
       // Branchless version
       Cached := HashTable[Context];
       Match := Ord(Cached = CurByte);
       ABitStream.WriteToBit(Match);
       if Match = 0 then
       begin
         HashTable[Context] := CurByte;
         LiteralPtr[LiteralCount] := CurByte;
         Inc(LiteralCount);
       end;
       // original version
       {if HashTable[Context] = CurByte then
       begin // tahmin doğru
         ABitStream.WriteToBit(1);
       end
       else
       begin
         ABitStream.WriteToBit(0);
         HashTable[Context] := CurByte;
         LiteralPtr[LiteralCount] := CurByte;
         System.Inc(LiteralCount);
       end;}
       if AOriginalSize <= 1024 * 1024 then  // 1 MB
         ContextBuffer := ((ContextBuffer shl 6) xor CurByte) // and $3FFFFFF
       else ContextBuffer := (UInt64(ContextBuffer shl 5) + CurByte); //  else ContextBuffer := ((ContextBuffer shl 5) and $FFFFFFF + CurByte);
       Context := ContextBuffer and HashMask;
       System.Inc(Processed);
     end;
     ABitStream.FlushBitBuffer();  // flush bits left in the bit buffer to stream
     ALiteralStream.Size := LiteralCount;
   end;

procedure DecompressLZP0(Const ABitStream : TExtMemStream; Const ALiteralStream, ADecompStream: TMemoryStream; AOriginalSize : Cardinal; HashBitSize : byte; DefChar : byte = 0);
 var HashSize, HashMask, ContextBuffer, Context, Processed, LiteralPos, LiteralCount : Cardinal;
     HashTable : TArray<Byte>;
     ADataPtr, LiteralPtr : PByte;
     CurByte, Prediction : byte;
   begin
     ADecompStream.Size := AOriginalSize;
     ADataPtr := ADecompStream.Memory;
     ABitStream.Position := 0;
     LiteralPtr := ALiteralStream.Memory;
     LiteralCount := ALiteralStream.Size;
     HashSize := 1 shl HashBitSize;
     SetLength(HashTable, HashSize);
     FillChar(HashTable[0], HashSize, DefChar);
     HashMask := HashSize - 1;
     ContextBuffer := 0;
     Context := 0;
     Processed := 0;
     LiteralPos := 0;
     while Processed < AOriginalSize do
     begin
       Prediction := ABitStream.ReadFromBit;
       if Prediction = 0 then // at least %60 percent of predictions are false so to speed up check it first
       begin
         if LiteralPos < LiteralCount then
         begin
           CurByte := LiteralPtr[LiteralPos];
           System.Inc(LiteralPos);
         end
         else
         begin
//           CurByte := 32; // if error occured fill it with space or raise an exception
           raise Exception.Create('Lzp: not enough literals. File may corrupt.');
         end;
         HashTable[Context] := CurByte;
       end
       else CurByte := HashTable[Context];
       if AOriginalSize <= 1024 * 1024 then  // 1 MB
         ContextBuffer := ((ContextBuffer shl 6) xor CurByte) // and $3FFFFFF
       else ContextBuffer := (UInt64(ContextBuffer shl 5) + CurByte); //  else ContextBuffer := ((ContextBuffer shl 5) and $FFFFFFF + CurByte);
       Context := ContextBuffer and HashMask;
       ADataPtr[processed] := Curbyte;
       System.Inc(Processed);
     end;
   end;


//==============================================================================
//                   Adaptive & Pointer based Functions.
//==============================================================================
procedure CompressLZP_P(Const ASourceStream, ALiteralStream: TMemoryStream; const ABitStream : TExtMemStream; HashBitSize : byte; DefChar : byte = 0);
 var AOriginalSize, HashMask, HashSize, ContextBuffer, Context : Cardinal;
     HashTable : TArray<byte>;
     ADataPtr, ADataPtrEnd, LiteralPtr, LiteralPtrEnd, BitPtr, BitPtrEnd : PByte;
     CurByte, Match, CurBits, BitCount : byte;
   begin
     AOriginalSize := ASourceStream.Size;
     ADataPtr := ASourceStream.Memory;
     ADataPtrEnd := ADataPtr + AOriginalSize;
     ABitStream.Size := (AOriginalSize + 7) div 8 + 8; // leave 32 bit extra space
     BitPtr := ABitStream.Memory;
     BitPtrEnd := BitPtr + ABitStream.Size;
     ALiteralStream.Size := AOriginalSize;  // reserve space assuming no right prediction will be made
     LiteralPtr := ALiteralStream.Memory;
     LiteralPtrEnd := LiteralPtr + ALiteralStream.Size;
     HashSize := 1 shl HashBitSize;
     SetLength(HashTable, HashSize);
     FillChar(HashTable[0], HashSize, DefChar);
     HashMask := HashSize - 1;
     ContextBuffer := 0;
     Context := 0;
     CurBits := 0;
     BitCount := 0;
     while ADataPtr < ADataPtrEnd do
     begin
       CurByte := ADataPtr^;
       System.Inc(ADataPtr);
       Match := Ord(HashTable[Context] = CurByte);
       CurBits := (CurBits shl 1) or Match;
       if Match = 0 then
       begin
         LiteralPtr^ := CurByte;
         if LiteralPtr < LiteralPtrEnd  then
           System.Inc(LiteralPtr);
         HashTable[Context] := CurByte;
       end;
       System.Inc(BitCount);
       if BitCount >= 8 then
       begin
         if BitPtr < BitPtrEnd then
         begin
           BitPtr^ := CurBits;
           System.Inc(BitPtr);
         end;
         CurBits := 0; // reset any way
         BitCount := 0;
       end;
       if AOriginalSize <= 1024 * 1024 then  // 1 MB
         ContextBuffer := ((ContextBuffer shl 6) xor CurByte) // and $3FFFFFF
       else ContextBuffer := (UInt64(ContextBuffer shl 5) + CurByte); //  else ContextBuffer := ((ContextBuffer shl 5) and $FFFFFFF + CurByte);
       Context := ContextBuffer and HashMask;
     end;
     if BitCount > 0 then
     begin
       CurBits := CurBits shl (8 - BitCount);  // sola tamamla
       if BitPtr < BitPtrEnd then
       begin
         BitPtr^ := CurBits;
         System.Inc(BitPtr);
       end;
     end;
     ABitStream.Size := BitPtr - PByte(ABitStream.Memory);  // flush bits left in the bit buffer to stream
     ALiteralStream.Size := LiteralPtr - PByte(ALiteralStream.Memory);
   end;

procedure DecompressLZP_P(Const ABitStream : TExtMemStream; Const ALiteralStream, ADecompStream: TMemoryStream; AOriginalSize : Cardinal; HashBitSize : byte; DefChar : byte = 0);
 var HashSize, HashMask, ContextBuffer, Context: Cardinal;
     HashTable : TArray<byte>;
     ADataPtr, ADataPtrEnd, BitPtr, BitPtrEnd, LiteralPtr, LiteralPtrEnd : PByte;
     CurByte, Prediction, LocalBits, CurBits : byte;
   begin
     ADecompStream.Size := AOriginalSize;
     ADataPtr := ADecompStream.Memory;
     ADataPtrEnd := ADataPtr + AOriginalSize;
     LiteralPtr := ALiteralStream.Memory;
     LiteralPtrEnd := LiteralPtr + ALiteralStream.Size;
     BitPtr := ABitStream.Memory;
     BitPtrEnd := BitPtr + ABitStream.Size;
     HashSize := 1 shl HashBitSize;
     SetLength(HashTable, HashSize);
     FillChar(HashTable[0], HashSize, DefChar);
     HashMask := HashSize - 1;
     ContextBuffer := 0;
     Context := 0;
     LocalBits := 0;
     CurBits := 0;
     while ADataPtr < ADataPtrEnd do
     begin
       if LocalBits = 0 then
       begin
         if BitPtr < BitPtrEnd then
         begin
           CurBits := BitPtr^;
           System.Inc(BitPtr);
         end
         else ;
         LocalBits := 8;  // Load bits anyway
       end;
       Prediction := (CurBits shr (LocalBits - 1)) and 1;
       System.Dec(LocalBits);
       if Prediction = 0 then
       begin
         if LiteralPtr < LiteralPtrEnd then
         begin
           CurByte := LiteralPtr^;
           System.Inc(LiteralPtr);
         end
         else
         begin
           CurByte := 32; // if error occured fill it with space
//           raise Exception.Create('Lzp: not enough literals. File may corrupt.');
         end;
         HashTable[Context] := CurByte;
       end
       else CurByte := HashTable[Context];
       ADataPtr^ := Curbyte;
       System.Inc(ADataPtr);
       if AOriginalSize <= 1024 * 1024 then  // 1 MB
         ContextBuffer := ((ContextBuffer shl 6) xor CurByte) // and $3FFFFFF
       else ContextBuffer := (UInt64(ContextBuffer shl 5) + CurByte); //  else ContextBuffer := ((ContextBuffer shl 5) and $FFFFFFF + CurByte);
       Context := ContextBuffer and HashMask;
     end;
   end;


//==============================================================================
//                   Adaptive & Pointer based Functions.
//==============================================================================
{procedure CompressLZP_AP(Const ASourceStream, ALiteralStream: TMemoryStream; const ABitStream : TExtMemStream; HashBitSize : byte; DefChar : byte = 0);
 var AOriginalSize, HashMask, HashSize, ContextBuffer, Context : Cardinal;
     HashTable : TArray<byte>;
     ADataPtr, ADataPtrEnd, LiteralPtr, LiteralPtrEnd, BitPtr, BitPtrEnd : PByte;
     CurByte, CurBits, BitCount : byte;
     HitCount, MissCount : Cardinal;
   begin
     AOriginalSize := ASourceStream.Size;
     ADataPtr := ASourceStream.Memory;
     ADataPtrEnd := ADataPtr + AOriginalSize;
     ABitStream.Size := (AOriginalSize + 7) div 8 + 8; // leave 32 bit extra space
     BitPtr := ABitStream.Memory;
     BitPtrEnd := BitPtr + ABitStream.Size;
     ALiteralStream.Size := AOriginalSize;  // reserve space assuming no right prediction will be made
     LiteralPtr := ALiteralStream.Memory;
     LiteralPtrEnd := LiteralPtr + ALiteralStream.Size;
     HashSize := 1 shl HashBitSize;
     SetLength(HashTable, HashSize);
     FillChar(HashTable[0], HashSize, DefChar);
     HashMask := HashSize - 1;
     ContextBuffer := 0;
     Context := 0;
     HitCount := 1;
     MissCount := 1;
     CurBits := 0;
     BitCount := 0;
     while ADataPtr < ADataPtrEnd do
     begin
       CurByte := ADataPtr^;
       System.Inc(ADataPtr);
       if HashTable[Context] = CurByte then
       begin // tahmin doğru
         CurBits := (CurBits shl 1) or 1;
         System.Inc(HitCount);
       end
       else
       begin
         CurBits := (CurBits shl 1);
         System.Inc(MissCount);
         LiteralPtr^ := CurByte;
         System.Inc(LiteralPtr);
         HashTable[Context] := CurByte;
       end;
       System.Inc(BitCount);
       if BitCount >= 8 then
       begin
         if BitPtr < BitPtrEnd then
         begin
           BitPtr^ := CurBits;
           System.Inc(BitPtr);
         end;
         CurBits := 0; // reset any way
         BitCount := 0;
       end;
       if AOriginalSize <= 1024 * 1024 then  // 1 MB
         ContextBuffer := ((ContextBuffer shl 6) xor CurByte) // and $3FFFFFF
       else ContextBuffer := (UInt64(ContextBuffer shl 5) + CurByte); //  else ContextBuffer := ((ContextBuffer shl 5) and $FFFFFFF + CurByte);
       Context := ContextBuffer and HashMask;
       if HitCount + MissCount > LZPGT_ADAPTIVE_BLOCK then
       begin
         if HitCount / (HitCount + MissCount) < LZPGT_ADAPTIVE_RATIO then
         begin
           FillChar(HashTable[0], HashSize, DefChar);
           HitCount := 1;
           MissCount := 1;
         end
         else
         begin
           System.Dec(Hitcount, HitCount shr LZPGT_ADAPTIVE_DECAY);
           System.Dec(MissCount, MissCount shr LZPGT_ADAPTIVE_DECAY);
         end;
       end;
     end;
     if BitCount > 0 then
     begin
       CurBits := CurBits shl (8 - BitCount);  // sola tamamla
       if BitPtr < BitPtrEnd then
       begin
         BitPtr^ := CurBits;
         System.Inc(BitPtr);
       end;
     end;
     ABitStream.Size := BitPtr - PByte(ABitStream.Memory);  // flush bits left in the bit buffer to stream
     ALiteralStream.Size := LiteralPtr - PByte(ALiteralStream.Memory);
   end;

procedure DecompressLZP_AP(Const ABitStream : TExtMemStream; Const ALiteralStream, ADecompStream: TMemoryStream; AOriginalSize : Cardinal; HashBitSize : byte; DefChar : byte = 0);
 var HashSize, HashMask, ContextBuffer, Context: Cardinal;
     HashTable : TArray<byte>;
     ADataPtr, ADataPtrEnd, BitPtr, BitPtrEnd, LiteralPtr, LiteralPtrEnd : PByte;
     CurByte, Prediction, LocalBits, CurBits : byte;
     HitCount, MissCount : Cardinal;
   begin
     ADecompStream.Size := AOriginalSize;
     ADataPtr := ADecompStream.Memory;
     ADataPtrEnd := ADataPtr + AOriginalSize;
     LiteralPtr := ALiteralStream.Memory;
     LiteralPtrEnd := LiteralPtr + ALiteralStream.Size;
     BitPtr := ABitStream.Memory;
     BitPtrEnd := BitPtr + ABitStream.Size;
     HashSize := 1 shl HashBitSize;
     SetLength(HashTable, HashSize);
     FillChar(HashTable[0], HashSize, DefChar);
     HashMask := HashSize - 1;
     ContextBuffer := 0;
     Context := 0;
     HitCount := 1;
     MissCount := 1;
     LocalBits := 0;
     CurBits := 0;
     while ADataPtr < ADataPtrEnd do
     begin
       if LocalBits = 0 then
       begin
         if BitPtr < BitPtrEnd then
         begin
           CurBits := BitPtr^;
           System.Inc(BitPtr);
         end
         else ;
         LocalBits := 8;  // Load bits anyway
       end;
       Prediction := (CurBits shr (LocalBits - 1)) and 1;
       System.Dec(LocalBits);
       if Prediction = 1 then
       begin
         CurByte := HashTable[Context];
         System.Inc(HitCount);
       end
       else
       begin
         if LiteralPtr < LiteralPtrEnd then
         begin
           CurByte := LiteralPtr^;
           System.Inc(LiteralPtr);
         end
         else
         begin
           CurByte := 32; // if error occured fill it with space
//           raise Exception.Create('Lzp: not enough literals. File may corrupt.');
         end;
         System.Inc(MissCount);
         HashTable[Context] := CurByte;
       end;
       if AOriginalSize <= 1024 * 1024 then  // 1 MB
         ContextBuffer := ((ContextBuffer shl 6) xor CurByte) // and $3FFFFFF
       else ContextBuffer := (UInt64(ContextBuffer shl 5) + CurByte); //  else ContextBuffer := ((ContextBuffer shl 5) and $FFFFFFF + CurByte);
       Context := ContextBuffer and HashMask;
       ADataPtr^ := Curbyte;
       System.Inc(ADataPtr);
       if HitCount + MissCount > LZPGT_ADAPTIVE_BLOCK then
       begin
         if HitCount / (HitCount + MissCount) < LZPGT_ADAPTIVE_RATIO then
         begin
           FillChar(HashTable[0], HashSize, DefChar);
           HitCount := 1;
           MissCount := 1;
         end
         else
         begin
           System.Dec(Hitcount, HitCount shr LZPGT_ADAPTIVE_DECAY);
           System.Dec(MissCount, MissCount shr LZPGT_ADAPTIVE_DECAY);
         end;
       end;
     end;
   end;
}

//==============================================================================
//                           Self Check Functions.
// Checks only streamed based function which calls internally block based
// functions which calls internally data-based functions.
//==============================================================================
Procedure TestLzpgt;
 Const
     TestFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';
 var S, D : TMemoryStream;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(TestFileName);
         LzpgtEncode(S, 21);
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-Lzgpt_z.pas');
         LzpgtDecode(S);
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-Lzgpt.pas');
         d.Size := 0;
         d.LoadFromFile(TestFileName);
         if (d.Size <> s.Size) or (CompareMem(S.Memory, d.Memory, S.Size) = false) then
           raise Exception.Create('Bwt: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;


{$IFDEF SELFTESTDEBUGMODE}
initialization
TestLzpgt;
{$ENDIF}
end.
