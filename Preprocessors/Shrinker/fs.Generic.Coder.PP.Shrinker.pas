{$I _fsInclude.inc}

unit fs.Generic.Coder.PP.Shrinker;

interface

uses System.Classes, System.SysUtils;

//==============================================================================
//                               Shrinker Functions
// Downloaded and converted from original C source code taken from the link:
//         https://code.google.com/archive/p/data-shrinker/downloads
//    LICENSE: New BSD License (http://opensource.org/licenses/BSD-3-Clause)
//                    AUTHOR : Siyuan Fu, Mar. 23, 2012
// 2025.10.30 First running copy
//     -HashTable converted to open array and hashbitsize made a variable.
// 2025.11.05 since minmatchlength can't be chaged for now, using as preprocessor
//   is not so successful. Bu it has a good compression ratios.
// 2025.11.09 First upload to Github

// NB: 1-MinMatch = 4 tightly integrated into the code so left untouched for now.
//     2-BlockSize=FileSize limited to 128 MB also tightly integrated into code.
//   It will be expanded in stream mode later.
//==============================================================================
function ShrinkerEncodePtr(const ASource, ADestination: PByte; ASourceSize: Integer; HashBitSize, MinMatch : byte): Integer;
function ShrinkerDecodePtr(const ASource, ADestination: PByte; ADestSize: Integer; MinMatch : byte): Integer;
Function ShrinkerEncodeS(Const ASource: TMemoryStream; HashBitSize, AMinMatch : byte) : boolean;
procedure ShrinkerDecodeS(Const ASource: TMemoryStream);
Function ShrinkerEncode(Const ASource: TMemoryStream; HashBitSize, AMinMatch : byte) : boolean;
procedure ShrinkerDecode(Const ASource: TMemoryStream);


implementation

function HASH(const a: UInt32; Hashbits : byte): UInt32; inline;
   begin
     Result := UInt32(UInt64(a) * 21788233) shr (32 - Hashbits);
   end;

procedure MEMCPY_NOOVERLAP(var DstPtr, SrcPtr, Limit: PByte); inline;
 var Overflow : byte;
   begin
     while SrcPtr < limit do
     begin
       PUInt32(DstPtr)^ := PUInt32(SrcPtr)^;
       Inc(DstPtr, 4);
       Inc(SrcPtr, 4);
     end;
     // Adjust for any over-copy
     Overflow := SrcPtr - limit;
     Dec(DstPtr, Overflow);
     Dec(SrcPtr, Overflow);
   end;

procedure MEMCPY_NOOVERLAP_NOSURPASS(var DstPtr, SrcPtr, Limit: PByte); inline;
   begin
     Dec(limit, 4);
     while SrcPtr < limit do
     begin
       PUInt32(DstPtr)^ := PUInt32(SrcPtr)^;
       Inc(DstPtr, 4);
       Inc(SrcPtr, 4);
     end;
     Inc(limit, 4);
     while SrcPtr < limit do
     begin
       DstPtr^ := SrcPtr^;
       Inc(DstPtr);
       Inc(SrcPtr);
     end;
   end;

procedure MEMCPY(var DstPtr, SrcPtr, Limit: PByte); inline;
   begin
     if DstPtr > SrcPtr + 4 then
       MEMCPY_NOOVERLAP(DstPtr, SrcPtr, Limit)
     else
     begin
       while SrcPtr < limit do
       begin
         DstPtr^ := SrcPtr^;
         Inc(DstPtr);
         Inc(SrcPtr);
       end;
     end;
   end;

Procedure SaveLength(cpy_len : integer; var DstPtr: PByte); inline;
   begin
     while cpy_len >= 255 do
     begin
       DstPtr^ := 255;
       Inc(DstPtr);
       cpy_len := cpy_len - 255;
     end;
     DstPtr^ := cpy_len;
     Inc(DstPtr);
   end;

PRocedure LoadLength(var match_len : UInt32; var SrcPtr: PByte); inline;
   begin
     while (SrcPtr^ = 255) do // (SrcPtr < SrcEnd) and
     begin
       Inc(match_len, 255);
       Inc(SrcPtr);
     end;
     Inc(match_len, SrcPtr^);
     Inc(SrcPtr);
   end;

function ShrinkerEncodePtr(const ASource, ADestination: PByte; ASourceSize: Integer; HashBitSize, MinMatch : byte): Integer;
 var //HashTable: array[0..(1 shl HASH_BITS) - 1] of UInt32;
     HashTable: TArray<UInt32>;
     SrcPtr, DstPtr, SrcPtrEnd, DstPtrEnd, p_last_lit, pflag, pfind, pcur: PByte;
     cur_hash, cpy_len, match_dist, cur_u32, tmp: UInt32;
     flag, cache: Byte;
   begin
     if (ASourceSize < 32) or (ASourceSize > (1 shl 27) - 1) then
     begin
       Result := -1;
       Exit;
     end;
     SrcPtr := PByte(ASource);
     DstPtr := PByte(ADestination);
     SrcPtrEnd := SrcPtr + ASourceSize - MINMATCH - 8;
     DstPtrEnd := DstPtr + ASourceSize - MINMATCH - 8;
     p_last_lit := SrcPtr;
     SetLength(HashTable, 1 shl HashBitSize);
     FillChar(HashTable[0], SizeOf(HashTable), 0);
     while (SrcPtr < SrcPtrEnd) and (DstPtr < DstPtrEnd) do
     begin
       try
         tmp := SrcPtr - PByte(ASource);  // result is nativeint
         pcur := SrcPtr;
         cur_u32 := PUInt32(pcur)^;
         cur_hash := HASH(cur_u32, HashBitSize);
         cache := HashTable[cur_hash] shr 27;
         pfind := PByte(ASource) + (HashTable[cur_hash] and $07FFFFFF);
         HashTable[cur_hash] := tmp or (SrcPtr^ shl 27);
         if (cache = (pcur^ and $1F)) and (pfind + $FFFF >= pcur) and
                     (pfind < pcur) and (PUInt32(pfind)^ = PUInt32(pcur)^) then
         begin
           Inc(pfind, 4);
           Inc(pcur, 4);
           while (pcur < SrcPtrEnd) and (PUInt32(pfind)^ = PUInt32(pcur)^) do
           begin
             Inc(pfind, 4);
             Inc(pcur, 4);
           end;
           if pcur < SrcPtrEnd then
           begin
             if PWord(pfind)^ = PWord(pcur)^ then
             begin
               Inc(pfind, 2);
               Inc(pcur, 2);
             end;
           end;
           if pfind^ = pcur^ then
           begin
             Inc(pfind);
             Inc(pcur);
           end;
           pflag := DstPtr;  // reserve space for flag saving
           Inc(DstPtr);
           cpy_len := SrcPtr - p_last_lit;
           if cpy_len < 7 then
             flag := cpy_len shl 5
           else
           begin
             flag := 7 shl 5;
             cpy_len := cpy_len - 7;
             SaveLength(cpy_len, DstPtr);
           end;
           cpy_len := pcur - SrcPtr - MINMATCH;
           if cpy_len < 15 then
             flag := flag or cpy_len
           else
           begin
             cpy_len := cpy_len - 15;
             flag := flag or 15;
             SaveLength(cpy_len, DstPtr);
           end;
           match_dist := pcur - pfind - 1;
           pflag^ := flag;    // save flag to preserved space
           DstPtr^ := match_dist and $FF;
           Inc(DstPtr);
           if match_dist > $FF then
           begin
             pflag^ := pflag^ or 16;
             DstPtr^ := match_dist shr 8;
             Inc(DstPtr);
           end;
           MEMCPY_NOOVERLAP(DstPtr, p_last_lit, SrcPtr);
           // Update hash table for positions SrcPtr+1 and SrcPtr+3
           cur_u32 := PUInt32(SrcPtr + 1)^;
           HashTable[HASH(cur_u32, HashBitSize)] := (SrcPtr - ASource + 1) or ((SrcPtr + 1)^ shl 27);
           cur_u32 := PUInt32(SrcPtr + 3)^;
           HashTable[HASH(cur_u32, HashBitSize)] := (SrcPtr - ASource + 3) or ((SrcPtr + 3)^ shl 27);
           SrcPtr := pcur;
           p_last_lit := SrcPtr;
           Continue;
         end;
         Inc(SrcPtr);
       except on E:Exception do
         raise Exception.CreateFmt('Error %s at: %u', [E.Message, (SrcPtr - ASource - 1)]);
       end;
     end;
     if DstPtr - ADestination + 3 >= SrcPtr - ASource then
     begin
       Result := -1;
       Exit;
     end;
     SrcPtr := PByte(ASource) + ASourceSize;
     pflag := DstPtr;
     Inc(DstPtr);
     cpy_len := SrcPtr - p_last_lit;
     if cpy_len < 7 then
       flag := cpy_len shl 5
     else
     begin
       cpy_len := cpy_len - 7;
       flag := 7 shl 5;
       SaveLength(cpy_len, DstPtr);
     end;
     flag := flag or (7 + 16);
     pflag^ := flag;
     DstPtr^ := $FF;
     Inc(DstPtr);
     DstPtr^ := $FF;
     Inc(DstPtr);
     MEMCPY_NOOVERLAP_NOSURPASS(DstPtr, p_last_lit, SrcPtr);
     if DstPtr > DstPtrEnd then
       Result := -1
     else Result := DstPtr - ADestination;
   end;

function ShrinkerDecodePtr(const ASource, ADestination: PByte; ADestSize: Integer; MinMatch : byte): Integer;
 var SrcPtr, DstPtr, DstPtrEnd, pcpy, pend: PByte;
     flag, long_dist_flag: Byte;
     literal_len, match_len, match_dist: UInt32;
   begin
     SrcPtr := ASource;
     DstPtr := ADestination;
     DstPtrEnd := DstPtr + ADestSize;
     while True do
     begin
       flag := SrcPtr^;
       Inc(SrcPtr);
       literal_len := flag shr 5;
       match_len := flag and $F;
       long_dist_flag := flag and $10;
       if literal_len = 7 then // Decode literal length
         LoadLength(literal_len, SrcPtr);
       if match_len = 15 then  // Decode match length
         LoadLength(Match_len, SrcPtr);
       match_dist := SrcPtr^;  // Decode match distance
       Inc(SrcPtr);
       if long_dist_flag > 0 then
       begin
         match_dist := match_dist or (SrcPtr^ shl 8);
         Inc(SrcPtr);
         if match_dist = $FFFF then // Check for end marker
         begin
           pend := SrcPtr + literal_len;
           if (DstPtr + literal_len) > DstPtrEnd then // destination buffer overrun
             Exit(-1);
           MEMCPY_NOOVERLAP_NOSURPASS(DstPtr, SrcPtr, pend);
           Break;
         end;
       end;
       // Copy literal bytes
       Pend := SrcPtr + Literal_Len;
       if (DstPtr + Literal_Len) > DstPtrEnd then  // destination buffer overrun
         Exit(-1);
       MEMCPY_NOOVERLAP(DstPtr, SrcPtr, Pend);
       PCpy := DstPtr - Match_Dist - 1;
       Pend := PCpy + Match_Len + MINMATCH;
       if (PCpy < ADestination) or ((DstPtr + Match_Len + MINMATCH) > DstPtrEnd) then
         Exit(-1);
       MEMCPY(DstPtr, PCpy, Pend);
     end;
     Result := (DstPtr - ADestination);  // decoded file size (or -1 on error)
   end;


//==============================================================================
//                             Stream Based Functions.
//==============================================================================
Function ShrinkerEncodeS(Const ASource: TMemoryStream; HashBitSize, AMinMatch : byte) : boolean;
 var DestStm : TMemoryStream;
     ASourceSize, EncodedSize : Cardinal;
   begin
     DestStm := TMemoryStream.Create;
     try
       Result := false;
//       if AMinMatch < 4 then  // values smaller then this threshold hurts compression ratio
       AMinMatch := 4;          // LzpShrinker minmatch value integrated into its code so incoming parameter discarded here for a while
       ASourceSize := ASource.Size;
       DestStm.Size := ASourceSize + 2048;  // 2K temp
       DestStm.Write(ASourceSize, Sizeof(ASourceSize));
//       DestStm.Write(AMinMatch, Sizeof(AMinMatch)); // save minmatch disabled for now
       EncodedSize := ShrinkerEncodePtr(ASource.Memory, PByte(DestStm.Memory)+DestStm.Position, ASource.Size, HashBitSize, AMinMatch);
       if EncodedSize > 0 then
       begin
         DestStm.Size := EncodedSize + DestStm.Position;
         ASource.Size := DestStm.Size;
         Move(DestStm.Memory^, ASource.Memory^, DestStm.Size);
         Result := true;
       end;
       ASource.Position := 0;
     finally
       DestStm.Free;
     end;
   end;

procedure ShrinkerDecodeS(Const ASource: TMemoryStream);
 var DestStm : TMemoryStream;
     DecodedSize, OriginalSize : Cardinal;
     MinMatch : byte;
   begin
     DestStm := TMemoryStream.Create;
     try
       ASource.Position := 0;
       ASource.Read(OriginalSize, sizeof(OriginalSize)); // load Source data size
//       ASource.Read(MinMatch, Sizeof(MinMatch)); // load minmatch
       MinMatch := 4;  // LzpShrinker minmatch value integrated into its code
       DestStm.Size := OriginalSize + 2048; // 2K temp
       DecodedSize := ShrinkerDecodePtr(PByte(ASource.Memory)+ASource.Position, DestStm.Memory, DestStm.Size, MinMatch);
       if DecodedSize = OriginalSize then
       begin
         ASource.Size := DecodedSize;
         Move(DestStm.Memory^, ASource.Memory^, DecodedSize);
         ASource.Position := 0;
       end;
     finally
       DestStm.Free;
     end;
   end;

const
//     MAX_BLOCK_SIZE     = 32 * 1024 * 1024; // (1 shl 27) - 1;  // 128 MB - original boundary
     MAX_BLOCK_SIZE     = (1 shl 27) - 1;  // 128 MB - original boundary
     DEFAULT_BLOCK_SIZE = 16 * 1024 * 1024;  // 16 MB blocks

function ShrinkerEncodeBlockBased(const ASource: TMemoryStream; HashBitSize: Byte): Boolean;
 var DestStm, TempStm: TMemoryStream;
     ASourceSize, BlockSize, Remaining, CurrentBlockSize, EncodedSize: Cardinal;
     SourcePtr: PByte; // , DestPtr
     BlockHeader: array[0..3] of Byte;  // [encoded_size, is_compressed]
   begin
     DestStm := TMemoryStream.Create;
     TempStm := TMemoryStream.Create;
     try
       Result := False;
       ASourceSize := ASource.Size;
       // Header: Original data size
       DestStm.Write(ASourceSize, SizeOf(ASourceSize));
       // Header: Block count (optional just for debugging purposes)
       BlockSize := DEFAULT_BLOCK_SIZE;
       if BlockSize > MAX_BLOCK_SIZE then
         BlockSize := MAX_BLOCK_SIZE;
       SourcePtr := ASource.Memory;
       Remaining := ASourceSize;
       while Remaining > 0 do
       begin
         // Determine Block size
         if Remaining > BlockSize then
           CurrentBlockSize := BlockSize
         else CurrentBlockSize := Remaining;
         // prepare temp buffer
         TempStm.Size := CurrentBlockSize + 1024;  // Overhead için ekstra
         // Encode Block
         EncodedSize := ShrinkerEncodePtr(SourcePtr, PByte(TempStm.Memory), CurrentBlockSize, HashBitSize, 4);
         // Write Block header [encoded_size (3 byte), is_compressed (1 byte)]
         if (EncodedSize > 0) and (EncodedSize < CurrentBlockSize) then
         begin // successful encoding
           BlockHeader[0] := EncodedSize and $FF;
           BlockHeader[1] := (EncodedSize shr 8) and $FF;
           BlockHeader[2] := (EncodedSize shr 16) and $FF;
           BlockHeader[3] := 1;  // compressed
           DestStm.Write(BlockHeader[0], 4);
           DestStm.Write(TempStm.Memory^, EncodedSize);
         end
         else
         begin // failed  - save original data
           BlockHeader[0] := CurrentBlockSize and $FF;
           BlockHeader[1] := (CurrentBlockSize shr 8) and $FF;
           BlockHeader[2] := (CurrentBlockSize shr 16) and $FF;
           BlockHeader[3] := 0;  // uncompressed
           DestStm.Write(BlockHeader[0], 4);
           DestStm.Write(SourcePtr^, CurrentBlockSize);
         end;
         // update Pointers
         Inc(SourcePtr, CurrentBlockSize);
         Dec(Remaining, CurrentBlockSize);
       end;
       // save result
       if DestStm.Size < ASourceSize then
       begin
         ASource.Size := DestStm.Size;
         Move(DestStm.Memory^, ASource.Memory^, DestStm.Size);
         Result := True;
       end;
       ASource.Position := 0;
     finally
       DestStm.Free;
       TempStm.Free;
     end;
   end;

procedure ShrinkerDecodeBlockBased(const ASource: TMemoryStream);
 var DestStm, TempStm: TMemoryStream;
     OriginalSize, TotalDecoded, BlockEncodedSize, BlockDecodedSize: Cardinal;
     SourcePtr, DestPtr: PByte;
     BlockHeader: array[0..3] of Byte;
     IsCompressed: Boolean;
   begin
     DestStm := TMemoryStream.Create;
     TempStm := TMemoryStream.Create;
     try
       ASource.Position := 0;
       // Header: Original data size
       ASource.Read(OriginalSize, SizeOf(OriginalSize));
       DestStm.Size := OriginalSize + 2048;
       SourcePtr := PByte(ASource.Memory) + ASource.Position;
       DestPtr := DestStm.Memory;
       TotalDecoded := 0;
       while TotalDecoded < OriginalSize do
       begin
         // read Block header
         Move(SourcePtr^, BlockHeader[0], 4);
         Inc(SourcePtr, 4);
         // extract Block info
         BlockEncodedSize := BlockHeader[0] or (BlockHeader[1] shl 8) or (BlockHeader[2] shl 16);
         IsCompressed := (BlockHeader[3] = 1);
         if IsCompressed then
         begin // decode, encoded block
           TempStm.Size := BlockEncodedSize + 1024;
           Move(SourcePtr^, TempStm.Memory^, BlockEncodedSize);
           BlockDecodedSize := ShrinkerDecodePtr(TempStm.Memory, DestPtr, OriginalSize - TotalDecoded, 4);
           if BlockDecodedSize = 0 then
             raise Exception.Create('Decompression error in block');
           Inc(DestPtr, BlockDecodedSize);
           Inc(TotalDecoded, BlockDecodedSize);
         end
         else
         begin // uncompressed - copied block - direct copy
           if TotalDecoded + BlockEncodedSize > OriginalSize then
             raise Exception.Create('Block size exceeds original size');
           Move(SourcePtr^, DestPtr^, BlockEncodedSize);
           Inc(DestPtr, BlockEncodedSize);
           Inc(TotalDecoded, BlockEncodedSize);
         end;
         Inc(SourcePtr, BlockEncodedSize);
       end;
       // save result
       if TotalDecoded = OriginalSize then
       begin
         ASource.Size := OriginalSize;
         Move(DestStm.Memory^, ASource.Memory^, OriginalSize);
         ASource.Position := 0;
       end
       else raise Exception.Create('Decompressed size mismatch');
     finally
       DestStm.Free;
       TempStm.Free;
     end;
   end;

// protect Orijinal functions for backward compatability
function ShrinkerEncode(const ASource: TMemoryStream; HashBitSize, AMinMatch: Byte): Boolean;
   begin
     if ASource.Size <= MAX_BLOCK_SIZE then // for small files original code
       Result := ShrinkerEncodeS(ASource, HashBitSize, AMinMatch)
     else // for large files use block-based algorithm
       Result := ShrinkerEncodeBlockBased(ASource, HashBitSize);
   end;

procedure ShrinkerDecode(const ASource: TMemoryStream);
 var OriginalSize: Cardinal;
   begin
     ASource.Position := 0;
     // check format (block-based or not)
     if ASource.Size >= SizeOf(OriginalSize) then
     begin
       ASource.Read(OriginalSize, SizeOf(OriginalSize));
       ASource.Position := 0;
       if OriginalSize <= MAX_BLOCK_SIZE then
         ShrinkerDecodeS(ASource)  // Orijinal format
       else
         ShrinkerDecodeBlockBased(ASource); // Block-based format
     end;
   end;


//==============================================================================
//               Self Check Functions.
// Checks only streamed based function which calls internally block based
// functions which calls internally data-based functions.
//==============================================================================
Procedure TestShrinkerPtr;
 Const
     TestFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';
 var S, D, E : TMemoryStream;
     ASize : Int64;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         e := TMemoryStream.Create;
         try
           s.LoadFromFile(TestFileName);
           d.Size := s.Size * 2;
           e.Size := s.Size * 2;
           d.Size := ShrinkerEncodePtr(s.Memory, d.Memory, s.Size, 16, 4);
           d.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-Shrinker_z.pas');
           ASize := ShrinkerDecodePtr(d.Memory, e.Memory, e.Size, 4);
           e.Size := ASize;
           e.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-Shrinker.pas');
           if (e.Size <> s.Size) or (CompareMem(S.Memory, e.Memory, S.Size) = false) then
             raise Exception.Create('Shrinker: Integrity check failed.');
         finally
           e.Free;
         end;
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;

Procedure TestShrinkerStm;
 Const
     TestFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';
 var S, D : TMemoryStream;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(TestFileName);
         d.LoadFromFile(TestFileName);
         ShrinkerEncode(s, 19, 4);
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-Shrinker_z.pas');
         ShrinkerDecode(S);
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-Shrinker.pas');
         if (s.Size <> d.Size) or (CompareMem(S.Memory, d.Memory, d.Size) = false) then
           raise Exception.Create('Shrinker: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;

{$IFDEF SELFTESTDEBUGMODE}
initialization
  TestShrinkerPtr;
  TestShrinkerStm;
{$ENDIF}
end.
