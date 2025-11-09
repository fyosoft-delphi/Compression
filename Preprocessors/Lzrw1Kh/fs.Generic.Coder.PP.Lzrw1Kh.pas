{$DEFINE LZRWKHDEBUG}

Unit fs.Generic.Coder.PP.Lzrw1Kh;

Interface

uses System.Classes, System.SysUtils
     {$IFDEF LZRWKHDEBUG}, fs.Core.LogHelper {$ENDIF};

//==============================================================================
//                       LZRW1KH Preprocessing Functions
// EXTREMELY FAST and EASY-TO-UNDERSTAND COMPRESSION ALGORITHM by Kurt HAENEN
// Original algorithm found in an archive named "bolt.zip", origin unknown to me.
// In the 90s, I got this algorithm from the net (a modified version by Danny Heijl
// (Danny.Heijl@cevi.be)), and I worked on it. Since the compression ratio was not
// sufficient for my needs, I left it out (stuck with lhsix). I do not know where
// it is now. This time, however, my goal is not superior compression ratios, but
// rather preprocessing before the main compression, so speed is more important
// than ratio.
// I searched the net and found nearly the same file at:
//                https://www.sac.sk/download/pack/tlzrw1.zip
// Finally, I found the original link of bolt.zip:
//       https://encode.su/attachment.php?attachmentid=10617&d=1687282734
//
// 2025.11.08 First running copy.
//     - Updated to current Pascal/Delphi conventions.
//     - Numerous range checking and integer overflow errors existed in the
//   original code. They are bypassed by turning these checks off using compiler
//   directives. These directives were removed, and the errors corrected one by one.
//     - Buffer size limit (32K, default 16K) removed.
//     - Typed buffer pointers converted to PByte.
//     - Hard-coded constants removed and defined in the const section.
//     - Global variables deleted and moved to procedures.
//     - HashTable converted to a record-class. Hash-related constants and variables
//   moved to this class. GetMatch function and Load-MatchPos-MatchLen variables
//   also moved to this class. This way, the GetMatch function became a single-
//   parameter function.
//     - Offset-Length / RLE-length saving format changed. Now compressed block
//   data is saved through LzWord. In match-saving mode, the higher 12 bits
//   represent the offset, and the lower 4 bits represent the match length. Note
//   that match length must be one-based (i.e., at least one) because length 0
//   is used to differentiate between match blocks and RLE blocks. If length bits
//   are all zero, then this LzWord block represents RLE compressed data. In this
//   case, the upper 12 bits represent the RLE character repeat count, and the
//   lower 4 bits are all zero, as mentioned. In RLE mode, there is one more
//   block that represents the repeating character. As a summary, in match mode,
//   match data size is 2 bytes, and all information is stored in a 2-byte LzWord
//   variable. In RLE mode, RLE data size is 3 bytes: 12-bit count in the higher
//   12 bits of LzWord, and the repeating character follows the LzWord. In the
//   original format, the RLE block size was 4.
// 2025.11.08 To speed up the process further, in GetMatch and in Decompress do-
//   loops, variables were converted to PByte.
// TO DO: Source and destination may also be converted to PByte.
// 2025.11.08 Static MinMatchLen, MaxMatchLen, MinRLELen, and MaxRLELen constants
//   converted to settings variables that can be changed at runtime. All of these
//   variables depend on MinMatchLength, and this flag is saved to the destination
//   file as the first byte, and later loaded during decoding. If this byte is
//   zero, the decoder knows that the file is not compressed, just copied.
//   This represents a structural change (previously, there were two flags
//   corresponding to this behavior).
// 2025.11.08 Self-compressing and decompressing stream functions added.
// 2025.11.09 In the original algorithm, the destination buffer boundary was
//   checked against the source size (assuming both have at least the same space).
//   When the original data size is very small (e.g., 5 bytes), due to at least
//   3 bytes of header, only 2 bytes of source data are processed and the rest
//   skipped, resulting in data loss. To overcome this shortcoming, the
//   destination size was added as a parameter.
// 2025.11.09 Test showed that using this as a preprocessing step is not a good
//   idea. MinMatchLen of 14–18 gave superior results but can't exceed the ~62%
//   barrier on wiki8. The complicated structure of the resulting encoded file
//   (2-byte commands + RLE blocks + LZ blocks + literals combined randomly) may
//   prevent models from learning the patterns in the file and degrade the
//   compression ratio.
// 2025.11.09 -First upload to github account.
//==============================================================================
Function LzrwKhEncode(Const Source, Dest: PByte; Const SourceSize, DestSize: Cardinal; AMinMatch : byte): Cardinal; overload;
Function LzrwKhDecode(Const Source, Dest: PByte; Const SourceSize, DestSize: Cardinal): Cardinal; overload;
Function LzrwKhEncode(Const ASource: TMemoryStream; AMinMatch : byte) : boolean; overload;
procedure LzrwKhDecode(Const ASource: TMemoryStream); overload;

implementation

// 2 byte lz saving
// 12 bit offset + 4 bit Length : Length must be > 0  to represent it is a match
// 12 bit RLE count. 4 bit flag : 4 bit flag must be zero. and must coincide with len bits

Type
    PLzrwSettings = ^TLzrwSettings;
    TLzrwSettings = record
      Public const
        MatchBitLength = 4;
        // MinMatchLength = 3;
        // MaxMatchLength = MinMatchLength + ((1 shl MatchBitLength) - 1) - 1;
        // MinRLECount    = MaxMatchLength + 1;
        // MinRLECount    = 1 shl MatchBitLength;
        // MaxRLECount    = ((1 shl OffsetBitSize) - 1) + MinRLECount;
        RLEBlockSize   = 3;
        MatchBlockSize = 2;
      Public             // for alignment purposes byte variables converted to word...
        MinMatchLen: word;
        MaxMatchLen: word;
        MinRLECount: word;
        MaxRLECount: word;
      Public
        Procedure Initialize(AMinMatchLen: byte);
      end;

Procedure TLzrwSettings.Initialize(AMinMatchLen: byte);
   begin
     MinMatchLen := AMinMatchLen;
     MaxMatchLen := MinMatchLen + ((1 shl MatchBitLength) - 1) - 1;
     MinRLECount := MaxMatchLen + 1;
     MaxRLECount := MinRLECount + ((1 shl (16-MatchBitLength)) - 1);
   end;


Type
    TLzrwHashTable = record
      private Const
        FOffsetBitSize = 12;
        FHashSize      = 1 shl FOffsetBitSize; // 4096;
        FHashMask      = (1 shl FOffsetBitSize) - 1;
      private
        FTable      : Array[0..FHashSize - 1] of integer;
        FSource     : PByte;
        FSourceSize : Cardinal;
        FSourceEnd  : PByte;
        FLoad       : Cardinal;
        FSettings   : PLzrwSettings;
      public
        FMatchPos   : Cardinal;
        FMatchLen   : Word;
        Procedure Initialize(ASource: PByte; ADataSize: Cardinal; ASettings : PLzrwSettings);
        Function GetMatch(SourcePos: Cardinal): boolean;
      end;

Procedure TLzrwHashTable.Initialize(ASource: PByte; ADataSize: Cardinal; ASettings : PLzrwSettings);
   begin
     FSource := ASource;
     FSourceEnd := FSource + ADataSize;
     FSourceSize := ADataSize;
     FillChar(FTable[0], sizeof(FTable), $FF);
     FLoad := 0;
     FSettings := ASettings;
   end;

{ check if this string has already been seen in the current 4 KB window }
Function TLzrwHashTable.GetMatch(SourcePos: Cardinal): boolean;
 var HashValue, TmpHash: integer;
     SourceP, SourceM : PByte;
   begin
     HashValue := (cardinal(40543)*cardinal((((cardinal(FSource[SourcePos]) shl 4) xor FSource[SourcePos+1]) shl 4) xor FSource[SourcePos+2]) shr 4) and FHashMask;
     Result := false;
     TmpHash := FTable[HashValue];
     if (TmpHash >= 0) then // hash already calculated and saved, we can try to search
     begin
       FMatchPos := TmpHash;
       if (SourcePos - FMatchPos < FHashSize) then
       begin
         FMatchLen := 0;
         SourceP := @FSource[SourcePos];
         SourceM := @FSource[FMatchPos];
         while ((FMatchLen < FSettings.MaxMatchLen) and (SourceP < FSourceEnd) and (SourceM < FSourceEnd) and (SourceP^ = SourceM^)) do
         begin
           System.Inc(FMatchLen);
           System.Inc(SourceP);
           System.Inc(SourceM);
         end;
         result := (FMatchLen >= FSettings.MinMatchLen);
         if FLoad > FHashSize div 10 then
           FTable[HashValue] := SourcePos;
       end
       else FTable[HashValue] := SourcePos;
     end
     else
     begin
       System.Inc(FLoad);
       FTable[HashValue] := SourcePos;
     end;
   end;

{ compress a buffer of max. 32 KB }
Function LzrwKhEncode(Const Source, Dest: PByte; Const SourceSize, DestSize: Cardinal; AMinMatch : byte): Cardinal;
 var Hash : TLzrwHashTable;
     Settings : TLzrwSettings;
     SourcePos, DestPos, CommandPos, CommandBuffer {$IFDEF LZRWKHDEBUG}, DbgCounter{$ENDIF} : cardinal; // positions in file so must be cardinal
     LzWord, Command, RLECount : word; // variables limited to 4K window
     RLEChar, Bit : BYTE;
   begin
     {$IFDEF LZRWKHDEBUG}
       DbgCounter := 0;
       TLogHelper.WriteLN('Compress begins...');
       TLogHelper.WriteLN('');
     {$ENDIF}
     if AMinMatch < 3 then
       AMinMatch := 3;
     Settings.Initialize(AMinMatch);
     Hash.Initialize(Source, SourceSize, @Settings);
     Dest[0] := Settings.MinMatchLen; // means file compressed with settings of MM, previously FLAG_Compress
     SourcePos := 0;
     DestPos := 3; // data start point in destination 1 byte status, 2 byte command first data starts at 3
     CommandPos := 1; // position of command in destination
     Bit := 0;  // number of lz packets either literal or match
     CommandBuffer := 0;
     while (SourcePos < SourceSize) and (DestPos < DestSize) do
     begin
       try
         if (Bit = 16) then  // 16 packet processed so command variable is full now
         begin
           Command := Word(CommandBuffer);
           Dest[CommandPos] := byte(Command shr 8); // so save command variable
           Dest[CommandPos+1] := byte(Command);
           CommandPos := DestPos; // save next command address
           CommandBuffer := 0;
           Bit := 0;
           System.Inc(DestPos, 2)  // reserve space for next command
         end;
         RLECount := 1;
         while ((RLECount < Settings.MaxRLECount) and (SourcePos + RLECount < SourceSize)) and (Source[SourcePos] = Source[SourcePos + RLECount]) do  // RLE counter
           System.Inc(RLECount);
         if (RLECount >= Settings.MinRLECount) then       // if RLE counter founds more than 16 chars in row
         begin
           RLEChar := Source[SourcePos];         // repeating char
           LzWord := RLECount - Settings.MinRLECount;     // make size zero based
           LzWord := LzWord shl 4;               // make lowest 4 bits zero to represent it is a RLE count data
           Dest[DestPos] := byte(LzWord shr 8);  // save match count as 2 byte
           Dest[DestPos+1] := byte(LzWord);
           Dest[DestPos+2] := RLEChar; // save recurring char
           {$IFDEF LZRWKHDEBUG}
             inc(DbgCounter);
             TLogHelper.WriteLN(Format(' %5u - RLE:%3u  S:%5u,  D:%5u,  Count:%3u,  LzWord:%8u', [DbgCounter, Source[SourcePos], SourcePos, DestPos, RLECount, LzWord]));
           {$ENDIF}
           System.Inc(DestPos, Settings.RLEBlockSize);          // move destination pointer by RLEBlock
           System.Inc(SourcePos, RLECount);            // move source pointer by RLECount
           CommandBuffer := (CommandBuffer shl 1) + 1; // add flag to command saying it is a compressed block
         end
         else  { size < 16 }  // repeating blocks less than 16 saved as lz match it is more efficient
         begin
           if (Hash.GetMatch(SourcePos)) then
           begin
             LzWord := Word((SourcePos - Hash.FMatchPos) shl 4) or Word(Hash.FMatchLen - Settings.MinMatchLen + 1);  // 12 bit offset + 4 bit length
             Dest[DestPos] := byte(LzWord shr 8);    // save match count as 2 byte
             Dest[DestPos+1] := byte(LzWord);
             {$IFDEF LZRWKHDEBUG}
               inc(DbgCounter);
               TLogHelper.WriteLN(Format(' %5u - MAT:%3u  S:%5u,  D:%5u,  Count:%3u,  Pos:%5u,  LzWord:%8u', [DbgCounter, Source[SourcePos], SourcePos, DestPos, Hash.FMatchLen, Hash.FMatchPos, LzWord]));
             {$ENDIF}
             System.Inc(DestPos, Settings.MatchBlockSize);         // move destination pointer
             System.Inc(SourcePos, Hash.FMatchLen);       // move source pointer
             CommandBuffer := (CommandBuffer shl 1) + 1;  // add flag to command saying the it is a compressed block
           end
           else   // process as literal
           begin
             Dest[DestPos] := Source[SourcePos];
             {$IFDEF LZRWKHDEBUG}
               inc(DbgCounter);
               TLogHelper.WriteLN(Format(' %5u - LIT:%3u  S:%5u,  D:%5u', [DbgCounter, Source[SourcePos], SourcePos, DestPos]));
             {$ENDIF}
             System.Inc(DestPos);
             System.Inc(SourcePos);
             CommandBuffer := CommandBuffer shl 1;  // add flag to command saying it is a literal
           end;
         end;
         System.Inc(Bit)
       except on E: exception do
         raise Exception.CreateFmt('Error %s at: %u-%u', [E.Message, SourcePos, DestPos]);
       end;
     end; { while x <= sourcesize }
     CommandBuffer := CommandBuffer shl (16-Bit); // fill/complement command to 16 bit
     Command := Word(CommandBuffer);
     Dest[CommandPos] := byte(Command shr 8);     // update last command value on destination
     Dest[CommandPos+1] := byte(Command);
     if (DestPos > SourceSize) then               // if compression failed i.e. bigger encoded file, then copy original
     begin
       MOVE(Source[0], Dest[1], SourceSize);
       Dest[0] := 0;                // means file not compressed, previously Settings.FLAG_Copied;
       DestPos := SUCC(SourceSize)
     end;
     {$IFDEF LZRWKHDEBUG}
       TLogHelper.WriteLN('');
       TLogHelper.WriteLN('Compress ends...');
       TLogHelper.WriteLN('');
       TLogHelper.WriteLN('');
     {$ENDIF}
     LzrwKhEncode := DestPos
   end;  { compression }

{ decompress a buffer of max 32 KB }
Function LzrwKhDecode(Const Source, Dest: PByte; Const SourceSize, DestSize: Cardinal): Cardinal;
 var SourcePos, DestPos, MatchPos, CommandBuffer {$IFDEF LZRWKHDEBUG}, DbgCounter {$ENDIF} : Cardinal;
     DestP, DestM : PByte;
     k, LzWord, Offset, RLECount, MatchLen : word;
     Settings : TLzrwSettings;
     Bit, RLEChar : BYTE;
   begin
     {$IFDEF LZRWKHDEBUG}
       DbgCounter := 0;
       TLogHelper.WriteLN('Decompress begins...');
       TLogHelper.WriteLN('');
     {$ENDIF}
     if (SourceSize <= 1) then
       DestPos := 0 { * dh * only the flag is present }
     else if (Source[0] = 0) then    // processed first byte  // means file not compressed, previously Settings.FLAG_Copied;
     begin
       MOVE(Source[1], Dest[0], PRED(SourceSize));
       DestPos := PRED(SourceSize)
     end
     else
     begin
       Settings.Initialize(Source[0]);  // first byte contains MinMatchlength of encoding
       DestPos := 0;
       SourcePos := 1;
       Bit := 0; // order that first read command word
       CommandBuffer := 0; // to silence compiler warning
       while (SourcePos < SourceSize) and (DestPos < DestSize) do
       begin
         try
           if (Bit = 0) then
           begin
             CommandBuffer := (word(Source[SourcePos]) shl 8) or Source[SourcePos+1];
             System.Inc(SourcePos, 2);
             Bit := 16
           end;
           if ((word(CommandBuffer) and $8000) = 0) then  // process literal
           begin
             Dest[DestPos] := Source[SourcePos];
             {$IFDEF LZRWKHDEBUG}
               inc(DbgCounter);
               TLogHelper.WriteLN(Format(' %5u - LIT:%u  S:%u,  D:%u', [DbgCounter, Source[SourcePos], DestPos, SourcePos]));
             {$ENDIF}
             System.Inc(DestPos);
             System.Inc(SourcePos)
           end
           else
           begin  { command and $8000 > 0 }
             LzWord := (Word(Source[SourcePos]) shl 8) or Source[SourcePos+1];
             if ((LzWord and $0F) = 0) then   // means it is a RLE count data
             begin
               RLECount := (LzWord shr 4)  + Settings.MinRLECount;  // extract RLE count data
               RLEChar := Source[SourcePos + Settings.MatchBlockSize];
               {$IFDEF LZRWKHDEBUG}
                 inc(DbgCounter);
                 TLogHelper.WriteLN(Format(' %5u - RLE:%u  S:%u,  D:%u,  Count:%u,  LzWord:%u', [DbgCounter, Source[SourcePos], DestPos, SourcePos, RLECount, LzWord]));
               {$ENDIF}
               DestP := Dest + DestPos; //@Dest[DestPos];
               for K := 0 to RLECount - 1 do
               begin
                 DestP^ := RLEChar;
                 System.Inc(DestP);
               end;
               System.Inc(SourcePos, Settings.RLEBlockSize);
               System.Inc(DestPos, RLECount)
             end
             else
             begin  { pos > 0 }  // means it is a Lz packed data
               Offset := LzWord shr 4;       // extract offset from Lzword
               MatchPos := DestPos - Offset; // convert offset to position
               MatchLen := (LzWord and $0F) + Settings.MinMatchLen - 1;  // extract length from Lzword, since it is saved as one based
               {$IFDEF LZRWKHDEBUG}
                 inc(DbgCounter);
                 TLogHelper.WriteLN(Format(' %5u - MAT:%u  S:%u,  D:%u,  Count:%u,  Pos: %u,  LzWord:%u', [DbgCounter, Dest[DestPos-MatchPos], DestPos, SourcePos, MatchLen, Offset, LzWord]));
               {$ENDIF}
               DestP := @Dest[DestPos];
               DestM := @Dest[MatchPos];
               for K := 0 to MatchLen - 1 do
               begin
                 DestP^ := DestM^;
                 System.Inc(DestP);
                 System.Inc(DestM);
               end;
               System.Inc(SourcePos, Settings.MatchBlockSize);
               System.Inc(DestPos, MatchLen)
             end;
           end;
           CommandBuffer := CommandBuffer shl 1;
           DEC(Bit)
         except on E: exception do
           raise Exception.CreateFMT('Error %s at: %u-%u', [E.Message, SourcePos, DestPos]);
         end;
       end { while x < sourcesize }
     end;
     {$IFDEF LZRWKHDEBUG}
       TLogHelper.WriteLN('');
       TLogHelper.WriteLN('Decompress ends...');
       TLogHelper.WriteLN('');
     {$ENDIF}
     LzrwKhDecode := DestPos
   end;  { decompression }


//==============================================================================
//                             Stream Based Functions.
//==============================================================================
Function LzrwKhEncode(Const ASource: TMemoryStream; AMinMatch : byte) : boolean;
 var DestStm : TMemoryStream;
     ASourceSize, EncodedSize : Cardinal;
   begin
     DestStm := TMemoryStream.Create;
     try
       Result := false;
       ASourceSize := ASource.Size;
       DestStm.Size := ASourceSize + 2048;  // 2K temp
       DestStm.Write(ASourceSize, Sizeof(ASourceSize));
       EncodedSize := LzrwKhEncode(ASource.Memory, PByte(DestStm.Memory)+DestStm.Position, ASource.Size, DestStm.Size, AMinMatch);
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

procedure LzrwKhDecode(Const ASource: TMemoryStream);
 var DestStm : TMemoryStream;
     DecodedSize, OriginalSize : Cardinal;
   begin
     DestStm := TMemoryStream.Create;
     try
       ASource.Position := 0;
       ASource.Read(OriginalSize, sizeof(OriginalSize)); // load Source data size
       DestStm.Size := OriginalSize + 2048; // 2K temp
       DecodedSize := LzrwKhDecode(PByte(ASource.Memory)+ASource.Position, DestStm.Memory, ASource.Size - ASource.Position, DestStm.Size);
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


//==============================================================================
//               Self Check Functions.
// Checks only streamed based function which calls internally block based
// functions which calls internally data-based functions.
//==============================================================================
Procedure TestLzrw1KhPtr;
 Const
//     TestFileName = 'D:\ZipAlgorithmTests\enwik8\_enwik8.txt';
     TestFileName = 'D:\ZipAlgorithmTests\MyMedicine\_MyMedicines.exe';
//     TestFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';
 var S, D : TMemoryStream;
     OriFileSize: Cardinal;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(TestFileName);
         OriFileSize := s.Size;
         d.Size := s.Size + 4096;
         d.Size := LzrwKhEncode(S.Memory, D.Memory, s.Size, d.Size, 3);
         d.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-lzrwkhz.txt');
         s.Size := 0;
         s.Size := OriFileSize + 4096;
         s.Size := LzrwKhDecode(D.Memory, S.Memory, D.Size, S.Size);
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-lzrwkh.txt');
         d.Size := 0;
         d.LoadFromFile(TestFileName);
         if (d.Size <> s.Size) or (CompareMem(S.Memory, d.Memory, S.Size) = false) then
           raise Exception.Create('LzrwKH: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;

Procedure TestLzrw1KhStm;
 Const
//     TestFileName = 'D:\ZipAlgorithmTests\enwik8\_enwik8.txt';
//     TestFileName = 'D:\ZipAlgorithmTests\MyMedicine\_MyMedicines.exe';
     TestFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';
//     TestFileName = 'D:\ZipAlgorithmTests\debug\_debug.txt';
 var S, D : TMemoryStream;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(TestFileName);
         LzrwKhEncode(S, 10);
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-lzrwkhz.txt');
         LzrwKhDecode(S);
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-lzrwkh.txt');
         d.LoadFromFile(TestFileName);
         if (d.Size <> s.Size) or (CompareMem(S.Memory, d.Memory, S.Size) = false) then
           raise Exception.Create('LzrwKH: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;


initialization
//  TestLzrw1KhStm;
//  TestLzrw1KhPtr;
end.



