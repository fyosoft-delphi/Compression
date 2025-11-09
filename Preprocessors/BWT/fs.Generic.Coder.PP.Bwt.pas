{$I _fsInclude.inc}

{.$DEFINE BWT_DEBUG}

unit fs.Generic.Coder.PP.Bwt;

interface

uses System.Classes, System.SysUtils, System.Math,
     System.Generics.Defaults, System.Generics.Collections,
     fs.Core.MemStream, fs.Core.LogHelper, fs.Core.GenericSort;

Const
     BWT_MAX_BLOCKSIZE     = 1 shl 24;
     BWT_BLOCK_GRANULARITY = 2048;  // 2KB step
     MAX_BWT_MULTIPLIER    = 8192;  // 8192 * 2048 = 16MB Max value
     DEF_BWT_MULTIPLIER    =   64;  // 4096 * 2048 = 8MB
     INDEX_BYTE_COUNT      =    3;  // 24 bit index limit
     BLOCK_BYTE_COUNT      =    2;  // 16 bit Multiplier limit
     BWT_MEMORY_SAFETY_BUF =   32;  //
//==============================================================================
//                  BWT Encode & BWT Decode functions
// Main BWT transformation algorithm is taken from the link:
//         https://rosettacode.org/wiki/Burrows–Wheeler_transform#Pascal
// -First running copy date unknown (not saved).
// -Original datasize saving is removed since no need to know original data size.
// -Instead BlockSize, for each block selected BlockIndex is saved to destination.
// 2025.10.24 Converted to preprocessing funtions
//     -Since this algorithm uses string sorting logic, it is rather slow and
//   included just for reference (for comparision purposes).
//     -BwtEncode2 Experiments resulted in %36 gain on compression time. Now,
//   BwtEncode points to original algorithm, and BwtEncode2 points to optimized
//   algorithm.
// 2025.10.25 Splitted into 3 functions: ...Data, ...Block, ...Stream.
//     - EncodeData/DecodeData both takes source and destination buffer addres
//   as PByte, with size of ADataSize. EncodeData returns Index as a result.
//   DecodeData takes additional parameter named Index (that return by EncodeData).
//     - EncodeBlock/DecodeBlock both takes source and destination buffer addres
//   as PByte, with size of ADataSize. In encoding ADataSize is equal to pure
//   size of data stored in input buffer. In decoding ADataSize is equal to pure
//   data size plus stored index data size (which is equal to 3 bytes as default)
//   Index data lies at the beginning of input buffer. Both returns number of
//   bytes written to destination buffer.
//     - BlockSize limited by 24 bit. Which is more than enough. Since After some
//   point, increasing block number decreases compression ratio, and spent time
//   increases dramatically.
//
//==============================================================================
// NB:
//    AEncoded Stream Format : [BLOCK_SIZE][INDEX_1][DATA_1][INDEX_2][DATA_2]...
//    AEncoded Block Format  : [INDEX_1][DATA_1]
//==============================================================================
// Self Check Function checks only streamed based function which calls internally
// block based functions which calls internally data-based functions.
//==============================================================================

Function EncodedBwtSize(ASourceSize, ABlockSize : Cardinal) : Cardinal; inline;
Function BwtEncodeData(const input, AEncoded: PByte; const ADataSize : Cardinal) : Cardinal;
procedure BwtDecodeData(const AEncoded, ADecoded: PByte; const ADataSize, Index : Cardinal);
//Function BwtEncodeData2(const input, AEncoded: PByte; const ADataSize : Cardinal) : Cardinal;
//procedure BwtDecodeData2(const AEncoded, ADecoded: PByte; const ADataSize, Index: Cardinal);

procedure BwtEncodeBlock(const input, AEncoded: PByte; const InputSize : Cardinal; out AWritten: Cardinal); overload;
procedure BwtDecodeBlock(const AEncoded, ADecoded: PByte; InputSize : Cardinal; out AWritten : cardinal); overload;

procedure BwtEncode(const ASource : TMemoryStream; const ABlockMultiplier : Word = DEF_BWT_MULTIPLIER); overload;
procedure BwtDecode(const ASource : TMemoryStream); overload;


implementation

//==============================================================================
//                                Utility functions
//==============================================================================
Function EncodedBwtSize(ASourceSize, ABlockSize : Cardinal) : Cardinal; inline;
 var BlockCount : Cardinal;
   begin
     Result := ASourceSize; // raw data size
     BlockCount := (ASourceSize + ABlockSize - 1) div ABlockSize;
     Result := Result + BlockCount * INDEX_BYTE_COUNT; // size of index saved for each block
     Result := Result + BLOCK_BYTE_COUNT;   // size of Block multiplier
   end;

Procedure SaveInteger(var Buffer : PByte; AData : Cardinal; ByteCount : byte); inline;
   begin
     for var i := 0 to ByteCount - 1 do
     begin
       Buffer^ := byte(AData and $FF);
       AData := AData shr 8;
       System.Inc(Buffer);
     end;
   end;

Function LoadInteger(var Buffer : PByte; ByteCount : byte) : Cardinal; inline;
   begin
     Result := 0;
     for var i := 0 to ByteCount - 1 do
     begin
       Result := Result or (Buffer^ shl (i * 8));
       System.Inc(Buffer);
     end;
   end;


//==============================================================================
//               Stream-based BWT Encode & BWT Decode functions
//==============================================================================
procedure BwtEncode(const ASource : TMemoryStream; const ABlockMultiplier : word = DEF_BWT_MULTIPLIER);
 var data, AEncoded : PByte;
     SourceSize, DestinationSize : Cardinal;
     AProcessed, AWritten, AReaded : Cardinal;
     ABlockSize {$IFDEF BWT_DEBUG}, BlockNumber{$ENDIF} : Cardinal;
     ADestination : TExtMemStream;
   begin
     SourceSize := ASource.Size;
     {$IFDEF BWT_DEBUG}
     TLogHelper.Start;
     TLogHelper.WriteLN(Format('BWT Encode started. FileSize: %u', [SourceSize]));
     BlockNumber := 0;
     {$ENDIF}
     Assert(ABlockMultiplier <= MAX_BWT_MULTIPLIER, 'BWT: block size out of limit');
     ADestination := TExtMemStream.Create;
     try
       ABlockSize := System.Math.Min(SourceSize, ABlockMultiplier * BWT_BLOCK_GRANULARITY); // calculate blocksize
       ADestination.Size := EncodedBwtSize(SourceSize, ABlockSize) + BWT_MEMORY_SAFETY_BUF; // calculate encoded data size & reserve memory
       AEncoded := ADestination.Memory; // Prepare destination pointer
       Data := ASource.Memory; // prepare source pointer
       DestinationSize := 0;   // initialize outputted data size
       AProcessed := 0;  // initialize AProcessed data size
       SaveInteger(AEncoded, ABlockMultiplier, BLOCK_BYTE_COUNT); // Save Block size indicator & move destination pointer
       {$IFDEF BWT_DEBUG}
       TLogHelper.WriteLN(Format('ABlockSize Identifier: %u', [ABlockMultiplier]));
       {$ENDIF}
       System.Inc(DestinationSize, BLOCK_BYTE_COUNT);  // update outpuuted data size
       while AProcessed < SourceSize do // loop until eof
       begin
         if AProcessed + ABlockSize <= SourceSize then  // detect new block size
           AReaded := ABlockSize
         else AReaded := SourceSize - AProcessed;
         {$IFDEF BWT_DEBUG}
         System.Inc(BlockNumber);
         TLogHelper.WriteLN(Format('   encoding BWT Block number: %u', [BlockNumber]));
         {$ENDIF}
         BwtEncodeBlock(Data, AEncoded, AReaded, AWritten); // encode block
         System.Inc(Data, AReaded);  // move source pointer
         System.Inc(AEncoded, AWritten);  // move destination pointer
         System.Inc(DestinationSize, AWritten); // update outputted data size
         System.Inc(AProcessed, AReaded); // update AProcessed data size
       end;
       ADestination.Size := DestinationSize; // trim destination size to real size
       ASource.Size := DestinationSize; // prepare source data size for copy
       Move(ADestination.Memory^, ASource.Memory^, DestinationSize); // overwrite source
       ASource.Position := 0; // seek to beginning
     finally
       {$IFDEF BWT_DEBUG}
       TLogHelper.WriteLN('BWT Encoding completed.');
       TLogHelper.Flush;
       {$ENDIF}
       ADestination.Free;
     end;
   end;

procedure BwtDecode(const ASource : TMemoryStream);
 var data, ADecoded : PByte;
     SourceSize, DestinationSize : Cardinal;
     ABlockSize {$IFDEF BWT_DEBUG}, ABlockMultiplier, BlockNumber{$ENDIF} : Cardinal;
     AProcessed, AWritten, AReaded : Cardinal;
     ADestination : TExtMemStream;
   begin
     SourceSize := ASource.Size;
     {$IFDEF BWT_DEBUG}
     TLogHelper.Start;
     TLogHelper.WriteLN(Format('BWT Decode started. FileSize: %u', [SourceSize]));
     BlockNumber := 0;
     {$ENDIF}
     ADestination := TExtMemStream.Create;
     try
       DestinationSize := 0; // initialize destination data size
       AProcessed := 0; // initialize AProcessed data size
       ADestination.Size := SourceSize; // reserve memory for destination NB:decoded size will be smaller
       ADecoded := ADestination.Memory; // prepare destination pointer
       Data := ASource.Memory;          // prepare source pointer
       {$IFDEF BWT_DEBUG}
       ABlockMultiplier := LoadInteger(data, BLOCK_BYTE_COUNT);  // load blocksize multiplier & move source pointer
       ABlockSize := ABlockMultiplier * BWT_BLOCK_GRANULARITY; // calculate blocksize
       TLogHelper.WriteLN(Format('ABlockSize Identifier: %u', [ABlockMultiplier]));
       {$ELSE}
       ABlockSize := LoadInteger(data, BLOCK_BYTE_COUNT) * BWT_BLOCK_GRANULARITY; // load blocksize multiplier & move source pointer
       {$ENDIF}
       System.Inc(AProcessed, BLOCK_BYTE_COUNT);  // update AProcessed data counter
       ABlockSize := ABlockSize + INDEX_BYTE_COUNT;  // Block based Bwt decoder takes this amount of data
       while AProcessed < SourceSize do
       begin
         if AProcessed + ABlockSize <= SourceSize then
           AReaded := ABlockSize
         else AReaded := SourceSize - AProcessed;
         {$IFDEF BWT_DEBUG}
         System.Inc(BlockNumber);
         TLogHelper.WriteLN(Format('   decoding BWT Block number: %u', [BlockNumber]));
         {$ENDIF}
         BwtDecodeBlock(data, ADecoded, AReaded, AWritten);
         System.Inc(data, AReaded); // move source pointer
         System.Inc(ADecoded, AWritten); // move destination pointer
         System.Inc(DestinationSize, AWritten); // update outputted data size
         System.Inc(AProcessed, AReaded);       // update AProcessed data size
       end;
       ASource.Size := DestinationSize;
       ADestination.Size := DestinationSize;
       Move(ADestination.Memory^, ASource.Memory^, DestinationSize);
       ASource.Position := 0;
     finally
       {$IFDEF BWT_DEBUG}
       TLogHelper.WriteLN('BWT Decoding completed.');
       //TLogHelper.finish;
       TLogHelper.Flush;
       {$ENDIF}
       ADestination.Free;
     end;
   end;


//==============================================================================
//               Block-based BWT Encode & BWT Decode functions
//==============================================================================
procedure BwtEncodeBlock(const input, AEncoded: PByte; const InputSize : Cardinal; out AWritten: Cardinal);
 var IndexPos, DataPos : PByte;
     Index: Cardinal;
   begin
     AWritten := 0;
     if InputSize = 0 then
       Exit;
     IndexPos := AEncoded;
     DataPos := AEncoded;
     SaveInteger(DataPos, 0, INDEX_BYTE_COUNT); // reserve space and move source Pointer
     System.Inc(AWritten, INDEX_BYTE_COUNT);
     Index := BwtEncodeData(input, DataPos, InputSize);
     System.Inc(AWritten, InputSize);
     SaveInteger(IndexPos, Index, INDEX_BYTE_COUNT); // save real index value at the beginning
     {$IFDEF BWT_DEBUG}
     TLogHelper.WriteLN(Format('      BWT EncodeBlock: Size: %u', [InputSize]));
     TLogHelper.WriteLN(Format('      BWT EncodeBlock: index: %u', [Index]));
     {$ENDIF}
   end;

procedure BwtDecodeBlock(const AEncoded, ADecoded: PByte; InputSize : Cardinal; out AWritten: Cardinal);
 var DataPos : PByte;
     Index : Cardinal;
   begin
     AWritten := 0;
     if InputSize = 0 then
       Exit;
     DataPos := AEncoded;
     Index := LoadInteger(DataPos, INDEX_BYTE_COUNT); // Get Index and move DataPos pointer
     System.Dec(InputSize, INDEX_BYTE_COUNT);  // calculate real data size
     BwtDecodeData(DataPos, ADecoded, InputSize, Index);
     AWritten := InputSize;
     {$IFDEF BWT_DEBUG}
     TLogHelper.WriteLN(Format('      BWT EncodeBlock: Size: %u', [InputSize]));
     TLogHelper.WriteLN(Format('      BWT DecodeBlock: index: %u', [Index]));
     {$ENDIF}
   end;


//==============================================================================
//               Data-based BWT Encode & BWT Decode functions
//==============================================================================
function BwtEncodeData(const input, AEncoded: PByte; const ADataSize : Cardinal) : Cardinal;
 var perm: TArray<Cardinal>;
     i, j, k, incr, v: Cardinal;
   begin
     Result := 0;
     if ADataSize = 0 then
       Exit;
     SetLength(perm, ADataSize);
     if ADataSize <= 64 then // Küçük bloklar için farklý algoritma
     begin // Küçük veriler için insertion sort daha hýzlý
       for i := 0 to ADataSize - 1 do
         perm[i] := i;
       for i := 1 to ADataSize - 1 do // Insertion sort
       begin
         v := perm[i];
         j := i;  // i-1
         while j > 0 do     // j >= 0
         begin
           var a := perm[j - 1]; // permit[j]
           var b := v;
           var cmp := 0;
           var p := a;
           var q := b;
           for var step := 0 to ADataSize - 1 do
           begin
             Inc(p); if p = ADataSize then p := 0;
             Inc(q); if q = ADataSize then q := 0;
             if Input[p] <> Input[q] then
             begin
               cmp := Ord(Input[p]) - Ord(Input[q]);
               Break;
             end;
           end;
           if cmp <= 0 then Break;
           perm[j] := perm[j - 1]; // perm[j + 1] := perm[j];
           Dec(j);
         end;
         perm[j] := v; // perm[j + 1] := v;
       end;
     end
     else
     begin // Büyük veriler için Shell Sort
       for j := 0 to ADataSize - 1 do
         perm[j] := j;
       incr := 1;
       while incr < ADataSize do
         incr := 3 * incr + 1;
       while incr > 1 do
       begin
         incr := incr div 3;
         for i := incr to ADataSize - 1 do
         begin
           v := perm[i];
           j := i;
           while (j >= incr) do
           begin
             var a := perm[j - incr];
             var cmp := 0;
             var p := a;
             var q := v;
             for var step := 0 to ADataSize - 1 do
             begin
               Inc(p); if p = ADataSize then p := 0;
               Inc(q); if q = ADataSize then q := 0;
               if Input[p] <> Input[q] then
               begin
                 cmp := Ord(Input[p]) - Ord(Input[q]);
                 Break;
               end;
             end;
             if cmp <= 0 then Break;
             perm[j] := perm[j - incr];
             Dec(j, incr);
           end;
           perm[j] := v;
         end;
       end;
     end;
     for j := 0 to ADataSize - 1 do
     begin
       k := perm[j];
       AEncoded[j] := Input[k];
       if k = ADataSize - 1 then
         Result := j;
     end;
   end;

function BwtEncodeData2(const input, AEncoded: PByte; const ADataSize : Cardinal) : Cardinal;
 var Helper: TMergeSortHelper<Integer>;
     Adapter: TCyclicBwtCompareAdapter;
     Indices: TArray<Integer>;
     I, J : integer;
   begin
     Result := 0;
     if (ADataSize <= 0) then
       Exit;
     SetLength(Indices, ADataSize);            // 1. create indexes
     for I := 0 to ADataSize - 1 do
       Indices[I] := I;
     Adapter := TCyclicBwtCompareAdapter.Create(Input, ADataSize);
     try
       Helper.Sort(Indices, Adapter.Compare); // 2. Sort indices
       for I := 0 to ADataSize - 1 do      // 3. find start index
         if Indices[I] = 0 then
         begin
           Result := I;
           Break;
         end;
       for I := 0 to ADataSize - 1 do      // 5. copy sorted data to temp buffer
       begin
         J := Indices[I];
         AEncoded[I] := Input[J];
       end;
     finally
       Adapter.Free;
     end;
   end;

procedure BwtDecodeData2(const AEncoded, ADecoded: PByte; const ADataSize, Index: Cardinal);
 var OriginalData: TArray<Byte>;
   begin
     SetLength(OriginalData, ADataSize);
     TGenericSorter.InverseBWT(AEncoded, ADataSize, Index, OriginalData);
     Move(OriginalData[0], ADecoded^, ADataSize);
   end;

procedure BwtDecodeData(const AEncoded, ADecoded: PByte; const ADataSize, Index: Cardinal);
 var charInfo: array [byte] of Cardinal;
     perm: TArray<Cardinal>;
     j, k, total, prev: Cardinal;
     c: byte;
   begin
     if ADataSize = 0 then
       Exit;
     // Count occurrences - daha hýzlý pointer eriþimi
     FillChar(charInfo, SizeOf(charInfo), 0);
     for j := 0 to ADataSize - 1 do
       Inc(charInfo[AEncoded[j]]);
     // Cumulate counts
     total := 0;
     prev := 0;
     for c := 0 to Byte.MaxValue do
     begin
       Inc(total, prev);
       prev := charInfo[c];
       charInfo[c] := total;
     end;
     // Build permutation array
     SetLength(perm, ADataSize);
     for j := 0 to ADataSize - 1 do
     begin
       c := AEncoded[j];
       k := charInfo[c];
       perm[k] := j;
       Inc(charInfo[c]);
     end;
     // Rebuild original string
     k := 0;
     j := index;
     repeat
       j := perm[j];
       ADecoded[k] := AEncoded[j];
       Inc(k);
     until (j = index);
     // Handle repeated substrings
     if k < ADataSize then
     begin
       for j := k to ADataSize - 1 do
         ADecoded[j] := ADecoded[j - k];
     end;
   end;


//==============================================================================
//               Self Check Functions.
// Checks only streamed based function which calls internally block based
// functions which calls internally data-based functions.
//==============================================================================
Procedure TestBwtStmS;
 Const
     TestFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';
 var S, D : TMemoryStream;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(TestFileName);
         BwtEncode(S, 16);
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-bwtz.txt');
         BwtDecode(S);
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-bwt.txt');
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


initialization
//TestBwtStmS;
end.


