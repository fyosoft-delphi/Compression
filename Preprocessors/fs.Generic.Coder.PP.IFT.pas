{$I _fsInclude.inc}

unit fs.Generic.Coder.PP.IFT;

interface

Uses System.Classes, System.SysUtils;

Type
//==============================================================================
//                             TInversionRankCoder
// It is simple Inversion (or Inversion Ranks) Coder written from the stratch.
// I heard it for the very first time in the description of BWIC (Burrows-Wheeler
// with Inversion Coder) written by Prof. Ziya Arnavut. He said sometimes IC is
// better than MTF, and I wanted to test it. I asked to chatgpt and deepseek
// about the algorithm (they are both somewhat confused). Taken clues and some
// insight resulted in this algorithm. After comparing MTF and IFT (this one) it
// can be seen that IFT is a modified version of MTF. I still do not know whether
// it is a true IC coder or not (probably not but naming not changed). I prefer
// to use the name Inversion Frequency Transform (IFT). But it has better speed
// and ratio over MTF.
//
// 2025.12.01 First running copy.
//     -Div2, Div3, Div4 rank adjusting methods compared. Best (both in terms of
//   speed and ratio) results taken from Div2.
//     -To avoid div 2 on runtime, NewRank array added.
// 2025.12.02 One & two parametered Encode & Decode functions added.
//     -NewRank converted to class var, and a class contructor added to initialize.
//     -Utility functions redesigned so that they use newly added encode & decode.
// 2026.01.09 First upload to Github account.
//==============================================================================
    TInversionRankCoder = class
      private
        RankOfSymbol : array[Byte] of Byte;      // S -> R
        SymbolOfRank : array[Byte] of Byte;      // R -> S
        class var NewRank : array[Byte] of Byte; // R -> NewR
      public
        constructor Create;
        class constructor Create;
        procedure Reset; overload;
        procedure Reset(Freqs : array of UInt32); overload;   // for hot start reset
        procedure Reset(NormFreqs : array of byte); overload; // for hot start reset
        function EncodeSymbol(S: Byte): Byte; inline; // Encoder: sembol → rank
        function DecodeRank(R: Byte): Byte; inline;   // Decoder: rank → symbol
        Procedure Encode(BufPtr : PByte; const ASize: UInt32); overload;
        Procedure Decode(BufPtr : PByte; const ASize: UInt32); overload;
        Procedure Encode(BufPtr, DestPtr : PByte; const ASize: UInt32); overload;
        Procedure Decode(BufPtr, DestPtr : PByte; const ASize: UInt32); overload;
        Procedure Encode(Source : TMemoryStream); overload;
        Procedure Decode(Source : TMemoryStream); overload;
      private
        procedure AdjustRanksDiv2(R: Byte; S: Byte); inline;   // adjust ranks by moving half half place
        {$HINTS OFF}
        procedure AdjustRanksMinus1(R: Byte; S: Byte); inline; // adjust ranks by moving up 1 place
        procedure AdjustRanksMove(R: Byte; S: Byte); inline;   // uses mem move to speed up but failed due to small loop
        {$HINTS ON}
      end;

//==============================================================================
//                              Utility Functions
//==============================================================================
procedure IFTEncode(Const Source: TMemoryStream); overload;
procedure IFTDecode(Const Source: TMemoryStream); overload;

procedure IFTEncode(const Source, Dest: TMemoryStream); overload;
procedure IFTDecode(const Source, Dest: TMemoryStream); overload;

procedure IFTEncode(const InputFile, OutputFile: string); overload;
procedure IFTDecode(const InputFile, OutputFile: string); overload;

implementation

//==============================================================================
//                              Utility Functions
//==============================================================================
procedure IFTEncode(Const Source: TMemoryStream);
 var Coder: TInversionRankCoder;
   begin
     if not Assigned(Source) or (Source.Size = 0) then
       Exit;
     Coder := TInversionRankCoder.Create;
     try
//       Coder.Encode(Source);  // hot started decode
       Coder.Encode(Source.Memory, Source.Size);
     finally
       Coder.Free;
     end;
   end;

procedure IFTDecode(Const Source: TMemoryStream);
 var Coder: TInversionRankCoder;
   begin
     if not Assigned(Source) or (Source.Size = 0) then
       Exit;
     Coder := TInversionRankCoder.Create;
     try
//       Coder.Decode(Source); // hot started decode
       Coder.Decode(Source.Memory, Source.Size);
     finally
       Coder.Free;
     end;
   end;

procedure IFTEncode(Const Source, Dest: TMemoryStream);
 var Coder: TInversionRankCoder;
   begin
     if not Assigned(Source) or not Assigned(Dest) then
       Exit;
     Dest.Size := Source.Size;
     if Source.Size = 0 then
       Exit;
     Coder := TInversionRankCoder.Create;
     try
       Coder.Encode(Source.Memory, Dest.Memory, Source.Size);
     finally
       Coder.Free;
     end;
   end;

procedure IFTDecode(const Source, Dest: TMemoryStream);
 var Coder: TInversionRankCoder;
   begin
     if not Assigned(Source) or not Assigned(Dest) then
       Exit;
     Dest.Size := Source.Size;
     if Source.Size = 0 then
       Exit;
     Coder := TInversionRankCoder.Create;
     try
       Coder.Decode(Source.Memory, Dest.Memory, Source.Size);
     finally
       Coder.Free;
     end;
   end;

procedure IFTEncode(const InputFile, OutputFile: string);
 var InputStream, OutputStream: TMemoryStream;
   begin
     if not FileExists(InputFile) then
       raise Exception.Create('Input file not found: ' + InputFile);
     InputStream := TMemoryStream.Create;
     try
       OutputStream := TMemoryStream.Create;
       try
         InputStream.LoadFromFile(InputFile);
         IFTEncode(InputStream, OutputStream);
         OutputStream.SaveToFile(OutputFile);
       finally
         OutputStream.Free;
       end;
     finally
       InputStream.Free;
     end;
   end;

procedure IFTDecode(const InputFile, OutputFile: string);
 var InputStream, OutputStream: TMemoryStream;
   begin
     if not FileExists(InputFile) then
       raise Exception.Create('Input file not found: ' + InputFile);
     InputStream := TMemoryStream.Create;
     try
       OutputStream := TMemoryStream.Create;
       try
         InputStream.LoadFromFile(InputFile);
         IFTDecode(InputStream, OutputStream);
         OutputStream.SaveToFile(OutputFile);
       finally
         OutputStream.Free;
       end;
     finally
       InputStream.Free;
     end;
   end;


//==============================================================================
//                                TInversionRankCoder
//==============================================================================
class constructor TInversionRankCoder.Create;
   begin
     for var i := 0 to 255 do
       NewRank[Byte(i)] := i div 2;
   end;

constructor TInversionRankCoder.Create;
   begin
     Reset;
   end;

procedure TInversionRankCoder.Reset;
   begin
     for var i := 0 to 255 do
     begin
       RankOfSymbol[Byte(i)] := Byte(i);
       SymbolOfRank[Byte(i)] := Byte(i);
     end;
   end;

procedure TInversionRankCoder.Reset(Freqs : array of UInt32);
 var SortedSymbols: array of record
         Symbol: Byte;
         Count: Integer;
       end;
   begin
     SetLength(SortedSymbols, 256); // Sembolleri frekansa göre sırala
     Assert(Length(Freqs) >= 256, 'Freqs table has fewer elements');
     for var i := 0 to 255 do
     begin
       SortedSymbols[i].Symbol := i;
       SortedSymbols[i].Count := Freqs[i];
     end;
     for var i := 0 to 254 do // Bubble sort (küçük array için yeterli)
       for var j := i + 1 to 255 do
         if SortedSymbols[j].Count > SortedSymbols[i].Count then
         begin
           var Temp := SortedSymbols[i];
           SortedSymbols[i] := SortedSymbols[j];
           SortedSymbols[j] := Temp;
         end;
     for var Rank := 0 to 255 do // Rank tablolarını frekans sırasına göre doldur
     begin
       var S := SortedSymbols[Rank].Symbol;
       SymbolOfRank[Rank] := S;
       RankOfSymbol[S] := Rank;
     end;
   end;

procedure TInversionRankCoder.Reset(NormFreqs : array of byte);
 var Freqs : array of UInt32;
   begin
     SetLength(Freqs, 256);
     Assert(Length(NormFreqs) >= 256, 'Freqs table has fewer elements');
     for var i := 0 to 255 do
       Freqs[i] := NormFreqs[i];
     Reset(Freqs);
   end;

// Encoder: teke the rank and update the table
function TInversionRankCoder.EncodeSymbol(S: Byte): Byte;
 var R: Byte;
   begin
     R := RankOfSymbol[S];
     Result := R;
     if R <> 0 then
       AdjustRanksDiv2(R, S);
   end;

// Decoder: rank al ve tabloyu güncelle
function TInversionRankCoder.DecodeRank(R: Byte): Byte;
 var S: Byte;
   begin
     S := SymbolOfRank[R];
     Result := S;
     if R <> 0 then
       AdjustRanksDiv2(R, S);
   end;

procedure TInversionRankCoder.AdjustRanksMinus1(R: Byte; S: Byte);
 var PrevSym: Byte;
   begin
     if R = 0 then Exit;
     PrevSym := SymbolOfRank[R - 1]; // Symbol at the previous rank slot
     SymbolOfRank[R - 1] := S;       // Swap symbol slots
     SymbolOfRank[R] := PrevSym;
     RankOfSymbol[S] := R - 1;       // Update inverse mapping
     RankOfSymbol[PrevSym] := R;
   end;

procedure TInversionRankCoder.AdjustRanksDiv2(R: Byte; S: Byte);
 var NewR, Sym : byte;
   begin
     NewR := NewRank[R];
     for var i := R downto NewR + 1 do
     begin
       Sym := SymbolOfRank[i - 1];
       SymbolOfRank[i] := Sym;
       RankOfSymbol[Sym] := i;
     end;
     SymbolOfRank[NewR] := S;
     RankOfSymbol[S] := NewR;
   end;

procedure TInversionRankCoder.AdjustRanksMove(R: Byte; S: Byte);
 var NewR, Shift : byte;
   begin
     NewR := NewRank[R];
     Shift := R - NewR;
     if Shift > 0 then
     begin
       Move(SymbolOfRank[NewR], SymbolOfRank[NewR + 1], Shift); // SymbolOfRank[Target+1 .. R] = SymbolOfRank[Target .. R-1]
       for var i := NewR + 1 to R do // RankOfSymbol güncelle (kaydırılan semboller)
         RankOfSymbol[SymbolOfRank[i]] := i;
       SymbolOfRank[NewR] := S;  // Yeni sembolü yerleştir
       RankOfSymbol[S] := NewR;
     end;
   end;

Procedure TInversionRankCoder.Encode(BufPtr : PByte; const ASize: UInt32);
 var EndPtr : PByte;
     S, R : Byte;
   begin
     if (ASize = 0) then
       Exit;
     EndPtr := BufPtr + ASize;
     while BufPtr < EndPtr do
     begin
       S := BufPtr^;
       R := RankOfSymbol[S];
       BufPtr^ := R;
       if R <> 0 then
         AdjustRanksDiv2(R, S);
       Inc(BufPtr);
     end;
   end;

Procedure TInversionRankCoder.Decode(BufPtr : PByte; const ASize: UInt32);
 var EndPtr : PByte;
     S, R : Byte;
   begin
     if (ASize = 0) then
       Exit;
     EndPtr := BufPtr + ASize;
     while BufPtr < EndPtr do
     begin
       R := BufPtr^;
       S := SymbolOfRank[R];
       BufPtr^ := S;
       if R <> 0 then
         AdjustRanksDiv2(R, S);
       Inc(BufPtr);
     end;
   end;

Procedure TInversionRankCoder.Encode(BufPtr, DestPtr : PByte; const ASize: UInt32);
 var EndPtr : PByte;
     S, R : Byte;
   begin
     if (ASize = 0) then
       Exit;
     EndPtr := BufPtr + ASize;
     while BufPtr < EndPtr do
     begin
       S := BufPtr^;
       R := RankOfSymbol[S];
       DestPtr^ := R;
       if R <> 0 then
         AdjustRanksDiv2(R, S);
       Inc(BufPtr);
       Inc(DestPtr);
     end;
   end;

Procedure TInversionRankCoder.Decode(BufPtr, DestPtr : PByte; const ASize: UInt32);
 var EndPtr : PByte;
     S, R : Byte;
   begin
     if (ASize = 0) then
       Exit;
     EndPtr := BufPtr + ASize;
     while BufPtr < EndPtr do
     begin
       R := BufPtr^;
       S := SymbolOfRank[R];
       DestPtr^ := S;
       if R <> 0 then
         AdjustRanksDiv2(R, S);
       Inc(BufPtr);
       Inc(DestPtr);
     end;
   end;

Procedure TInversionRankCoder.Encode(Source : TMemoryStream);
 var Freqs : array[byte] of UInt32;
     NormFreq : array[byte] of byte;
     BufPtr, EndPtr : PByte;
     Dest : TMemoryStream;
   begin
     if not assigned(Source) or (Source.Size = 0) then
       Exit;
     FillChar(Freqs, Sizeof(Freqs), 0);
     BufPtr := Source.Memory;
     EndPtr := BufPtr + Source.Size;
     while BufPtr < EndPtr do
     begin
       Inc(Freqs[BufPtr^]);
       Inc(BufPtr);
     end;
     Reset(Freqs);
     for var i := 0 to 255 do
       NormFreq[i] := 255 - RankOfSymbol[i];
     Dest := TMemoryStream.Create;
     try
       Dest.Size := 256 + Source.Size;
       Dest.WriteBuffer(NormFreq, Sizeof(NormFreq));
       Encode(PByte(Source.Memory), PByte(Dest.Memory)+256, Source.Size);
       Source.Size := Dest.Size;
       Move(Dest.Memory^, Source.Memory^, Dest.Size);
     finally
       Dest.Free;
     end;
   end;

Procedure TInversionRankCoder.Decode(Source : TMemoryStream);
 var NormFreq : array[byte] of byte;
   begin
     if not assigned(Source) or (Source.Size = 0) then
       Exit;
     Source.ReadBuffer(NormFreq, Sizeof(NormFreq));
     Reset(NormFreq);
     Decode(PByte(Source.Memory)+256, PByte(Source.Memory), Source.Size-256);
     Source.Size := Source.Size - 256;
   end;


//==============================================================================
//                              Self-Testing Functions
//==============================================================================
Procedure TestIFTStm;
 const
//      AFileName = 'D:\ZipAlgorithmTests\MyMedicine\_MyMedicines.exe';
      AFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';
 var S, D : TMemoryStream;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(AFileName);
         d.LoadFromFile(AFileName);
//         s.WriteBuffer([65,65,65,66,67,65,65,65,65,68], 10);
//         d.WriteBuffer([65,65,65,66,67,65,65,65,65,68], 10);
         IFTEncode(D);
         D.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-IFT-enc.txt');
         IFTDecode(D);
         D.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-IFT-dec.txt');
         if (d.Size <> s.Size) or (CompareMem(S.Memory, D.Memory, S.Size) = false) then
           raise Exception.Create('RLE: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;


initialization
//TestIFTStm;
end.
