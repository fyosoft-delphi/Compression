{$I _fsInclude.inc}

unit fs.Generic.Coder.PP.ST;

interface

uses System.SysUtils, System.Classes;

Const
     ST_ALPHABET_SIZE = 256;
//     ST_NUM_FASTBITS = 10;

     ST_NOT_ENOUGH_MEMORY = -3;
     LIBBSC_NO_ERROR = 0;
     LIBBSC_BAD_PARAMETER = -1;
     LIBBSC_NOT_SUPPORTED = -2;
     LIBBSC_NOT_ENOUGH_MEMORY = -3;

//==============================================================================
//                STEncode & STDecode preprocessing functions
// Extracted and converted from original source code taken from the link:
//                   http://eiunix.tuwien.ac.at/~michael
//                  Michael Schindler  September 25, 1996
// 2025.19.15 First running copy
//==============================================================================
function STEncode(const ASource, ADestination: PByte; const ABufferSize: NativeInt) : Byte; overload;
function STEncode(const AInPtr: PByte; const ASize : NativeInt) : byte; overload;

procedure STDecode(ASource, ADestination: PByte; ABufferSize: NativeInt; FirstChar: Byte); overload;
procedure STDecode(const AInPtr: PByte; const ASize : NativeInt; FirstChar : byte); overload;


//==============================================================================
//                ST2Encode & ST2Decode preprocessing functions
// Extracted and converted from original source code taken from the link:
//                   http://eiunix.tuwien.ac.at/~michael
//                  Michael Schindler  September 25, 1996
// 2025.19.15 First running copy
//==============================================================================
procedure ST2Encode(ASource, ADestination: PByte; ABufferSize: NativeInt; out FirstChar, SecondChar: Byte); overload;
procedure ST2Encode(const AInPtr: PByte; const ASize : NativeInt; out FirstChar, SecondChar: Byte); overload;

procedure ST2Decode(ASource, ADestination: PByte; ABufferSize: NativeInt; FirstChar, SecondChar: Byte); overload;
procedure ST2Decode(const AInPtr: PByte; const ASize : NativeInt; FirstChar, SecondChar : byte); overload;


//==============================================================================
//                ST3Encode & ST3Decode preprocessing functions
// Extracted and converted from original source code taken from the link:
//https://github.com/IlyaGrebnov/libbsc/blob/master/libbsc/st/st.cpp (bsc 3.3.6)
//           Copyright (c) 2009-2024 Ilya Grebnov <ilya.grebnov@gmail.com>
//    LICENSE : Licensed under the Apache License, Version 2.0 (the "License")
//                  http://www.apache.org/licenses/LICENSE-2.0
// 2025.19.17 First running copy
//==============================================================================
function ST3Encode(const ASource: PByte; const n : Integer): Integer;
function ST3Decode(const T: PByte; n, AIndex: Integer): Integer;


implementation

//==============================================================================
//                  STEncode & STDecode preprocessing functions
//==============================================================================
function STEncode(const ASource, ADestination: PByte; const ABufferSize: NativeInt) : Byte;
 var Count: array[0..255] of NativeInt;
     I, Sum: NativeInt;
   begin
     for I := 0 to 255 do // Count dizisini sýfýrla
       Count[I] := 0;
     for I := 0 to ABufferSize - 1 do // Frekanslarý say
       Inc(Count[ASource[I]]);
     Sum := 0;
     for I := 0 to 255 do // Kümülatif toplamý hesapla
     begin
       Inc(Sum, Count[I]);
       Count[I] := Sum - Count[I];
     end;
     for I := 1 to ABufferSize - 1 do // ST dönüþümünü uygula
     begin
       ADestination[Count[ASource[I - 1]]] := ASource[I];
       Inc(Count[ASource[I - 1]]);
     end;
     ADestination[Count[ASource[ABufferSize - 1]]] := ASource[0]; // Son elemaný iþle
     Inc(Count[ASource[ABufferSize - 1]]);
     Result := ASource[0]; // Ýlk karakteri döndür
   end;

function STEncode(const AInPtr: PByte; const ASize : NativeInt) : byte;
 var ADestination : array of byte;
   begin
     SetLength(ADestination, ASize);
     result := STEncode(AInPtr, @ADestination[0], ASize);
     Move(ADestination[0], AInPtr^, ASize);
   end;

procedure STDecode(ASource, ADestination: PByte; ABufferSize: NativeInt; FirstChar: Byte);
 var Count: array[0..255] of NativeInt;
     I, Sum: NativeInt;
   begin
     for I := 0 to 255 do // Count dizisini sýfýrla
       Count[I] := 0;
     for I := 0 to ABufferSize - 1 do // Frekanslarý say
       Inc(Count[ASource[I]]);
     Sum := 0;
     for I := 0 to 255 do // Kümülatif toplamý hesapla
     begin
       Inc(Sum, Count[I]);
       Count[I] := Sum - Count[I];
     end;
     ADestination[0] := FirstChar; // Ýlk karakteri yerleþtir
     for I := 1 to ABufferSize - 1 do  // Ters ST dönüþümünü uygula
     begin
       ADestination[I] := ASource[Count[ADestination[I - 1]]];
       Inc(Count[ADestination[I - 1]]);
     end;
   end;

procedure STDecode(const AInPtr: PByte; const ASize : NativeInt; FirstChar : byte);
 var ADestination : array of byte;
   begin
     SetLength(ADestination, ASize);
     STDecode(AInPtr, @ADestination[0], ASize, FirstChar);
     Move(ADestination[0], AInPtr^, ASize);
   end;


//==============================================================================
//                  ST2Encode & ST2Decode preprocessing functions
//==============================================================================
procedure ST2Encode(ASource, ADestination: PByte; ABufferSize: NativeInt; out FirstChar, SecondChar: Byte);
 var Count: array[0..255, 0..255] of NativeInt;
     I, J, Sum: NativeInt;
   begin
     for I := 0 to 255 do   // Count matrisini sýfýrla
       for J := 0 to 255 do
         Count[I, J] := 0;
     for I := 1 to ABufferSize - 1 do // Frekanslarý say (2. derece context)
       Inc(Count[ASource[I], ASource[I - 1]]);
     Inc(Count[ASource[0], ASource[ABufferSize - 1]]);
     Sum := 0;
     for I := 0 to 255 do // Kümülatif toplamý hesapla
       for J := 0 to 255 do
       begin
         Inc(Sum, Count[I, J]);
         Count[I, J] := Sum - Count[I, J];
       end;
     for I := 2 to ABufferSize - 1 do // ST2 dönüþümünü uygula
     begin
       ADestination[Count[ASource[I - 1], ASource[I - 2]]] := ASource[I];
       Inc(Count[ASource[I - 1], ASource[I - 2]]);
     end;
     // Son iki elemaný iþle
     ADestination[Count[ASource[ABufferSize - 1], ASource[ABufferSize - 2]]] := ASource[0];
     Inc(Count[ASource[ABufferSize - 1], ASource[ABufferSize - 2]]);

     ADestination[Count[ASource[0], ASource[ABufferSize - 1]]] := ASource[1];
     Inc(Count[ASource[0], ASource[ABufferSize - 1]]);
     // Ýlk iki karakteri döndür
     FirstChar := ASource[0];
     SecondChar := ASource[1];
   end;

procedure ST2Encode(const AInPtr: PByte; const ASize : NativeInt; out FirstChar, SecondChar: Byte);
 var ADestination : array of byte;
   begin
     SetLength(ADestination, ASize);
     ST2Encode(AInPtr, @ADestination[0], ASize, FirstChar, SecondChar);
     Move(ADestination[0], AInPtr^, ASize);
   end;

procedure ST2Decode(ASource, ADestination: PByte; ABufferSize: NativeInt; FirstChar, SecondChar: Byte);
 var Count: array[0..255, 0..255] of NativeInt;
     I, J, Sum: NativeInt;
   begin
     for I := 0 to 255 do   // Count matrisini sýfýrla
       for J := 0 to 255 do
         Count[I, J] := 0;
     for I := 0 to ABufferSize - 1 do  // Frekanslarý say (ilk aþama)
       Inc(Count[0, ASource[I]]);
     Sum := 0;
     for I := 0 to 255 do  // Context count'larýný hesapla
     begin
       J := Sum;
       Inc(Sum, Count[0, I]);
       Count[0, I] := 0;
       while J < Sum do    // Context count'larýný doldur
       begin
         Inc(Count[ASource[J], I]);
         Inc(J);
       end;
     end;
     Sum := 0;
     for I := 0 to 255 do  // Kümülatif toplamý hesapla
       for J := 0 to 255 do
       begin
         Inc(Sum, Count[I, J]);
         Count[I, J] := Sum - Count[I, J];
       end;
     // Ýlk iki karakteri yerleþtir
     ADestination[0] := FirstChar;
     ADestination[1] := SecondChar;
     for I := 2 to ABufferSize - 1 do  // Ters ST2 dönüþümünü uygula
     begin
       ADestination[I] := ASource[Count[ADestination[I - 1], ADestination[I - 2]]];
       Inc(Count[ADestination[I - 1], ADestination[I - 2]]);
     end;
   end;

procedure ST2Decode(const AInPtr: PByte; const ASize : NativeInt; FirstChar, SecondChar : byte);
 var ADestination : array of byte;
   begin
     SetLength(ADestination, ASize);
     ST2Decode(AInPtr, @ADestination[0], ASize, FirstChar, SecondChar);
     Move(ADestination[0], AInPtr^, ASize);
   end;


//==============================================================================
//                  ST3Encode & ST3Decode preprocessing functions
//==============================================================================
function ST3Encode(const ASource: PByte; const n : Integer): Integer;
 var count: array[0..ST_ALPHABET_SIZE - 1] of LongWord;
     bucket: TArray<Integer>; //PInteger;
     T : TArray<byte>; // PWord;
     P : TArray<Word>; // PWord;
     i, sum, tmp, pos: Integer;
     C0, C1: Byte;
     W: LongWord;
   begin
     SetLength(P, n); // P := bsc_malloc(n * SizeOf(Word));
     if P = nil then
       Exit(ST_NOT_ENOUGH_MEMORY);
     for i := 0 to High(P) do
       P[i] := 0;

     SetLength(bucket, ST_ALPHABET_SIZE * ST_ALPHABET_SIZE); // bucket := bsc_zero_malloc(ALPHABET_SIZE * ALPHABET_SIZE * SizeOf(Integer));
     if bucket = nil then
       Exit(ST_NOT_ENOUGH_MEMORY);
     for i := 0 to High(Bucket) do
       Bucket[i] := 0;
     //    FillChar(count[0], ALPHABET_SIZE * SizeOf(LongWord), 0);
     for i := 0 to high(count) - 1 do
       count[i] := 0;
     // Create circular data buffer
     SetLength(T, n + 2);
     if T = nil then
       Exit(ST_NOT_ENOUGH_MEMORY);
     for i := 0 to n - 1 do
       T[i] := ASource[i];
     T[n] := T[0];
     T[n+1] := T[1];

     C0 := T[n - 1];
     for i := 0 to n - 1 do
     begin
       C1 := T[i];
       Inc(count[C1]);
       Inc(bucket[(C0 shl 8) or C1]);
       C0 := C1;
     end;

     sum := 0;
     for i := 0 to ST_ALPHABET_SIZE * ST_ALPHABET_SIZE - 1 do
     begin
       tmp := sum;
       Inc(sum, bucket[i]);
       bucket[i] := tmp;
     end;

     sum := 0;
     for i := 0 to ST_ALPHABET_SIZE - 1 do
     begin
       tmp := sum;
       Inc(sum, count[i]);
       count[i] := tmp;
     end;

     pos := bucket[(T[1] shl 8) or T[2]];

     W := (T[n - 1] shl 16) or (T[0] shl 8) or T[1];
     for i := 0 to n - 1 do
     begin
       W := (W shl 8) or T[i + 2];
       P[bucket[W and $0000ffff]] := word(W shr 16);
       Inc(bucket[W and $0000ffff]);
     end;

     for i := 0 to pos - 1  do
     begin
       ASource[count[P[i] and $00ff]] := byte(P[i] shr 8);
       Inc(count[P[i] and $00ff]);
     end;

     Result := count[P[pos] and $00ff];

     for i := pos to n - 1 do
     begin
       ASource[count[P[i] and $00ff]] := byte(P[i] shr 8);
       Inc(count[P[i] and $00ff]);
     end;

//     for i := 0 to n - 1 do
//       ASource[i] := T[i];
   end;


type
    TWordArray = TArray<Word>;
    TIntArray  = TArray<Integer>;
    TCardinalArray = TArray<Cardinal>;
    PCardinalArray = ^TCardinalArray;
    TCountArray =  array[0..ST_ALPHABET_SIZE - 1] of Cardinal;

function ST3Decode(const T: PByte; n, AIndex: Integer): Integer;
 var group: array[0..ST_ALPHABET_SIZE-1] of Integer;
     P: TArray<LongWord>;
     bucket: TArray<LongWord>;
     index, count: TCountArray; //array[0..ALPHABET_SIZE-1] of LongWord;
     i, c, d, w, sum, tmp: Integer;
     failBack: Boolean;

     g, pIndex: Integer;
     ch: Byte;
     u: LongWord;
   begin
     if (T = nil) or (n < 0) then
       Exit(LIBBSC_BAD_PARAMETER);
     if (AIndex < 0) or (AIndex >= n) then
       Exit(LIBBSC_BAD_PARAMETER);
     if n <= 1 then
       Exit(0);
     SetLength(P, n);
     FillChar(P[0], n * SizeOf(LongWord), 0);
     SetLength(bucket, ST_ALPHABET_SIZE * ST_ALPHABET_SIZE);
     FillChar(bucket[0], ST_ALPHABET_SIZE * ST_ALPHABET_SIZE * SizeOf(LongWord), 0);
     FillChar(count[0], ST_ALPHABET_SIZE * SizeOf(LongWord), 0);
      //   failBack := bsc_unst_sort_serial(T, P, count, bucket, n, k);
     failBack := False;
     // 1. Count frequencies and calculate cumulative counts
     for i := 0 to n - 1 do
       Inc(count[T[i]]);
     sum := 0;
     for c := 0 to ST_ALPHABET_SIZE - 1 do
     begin
       if count[c] >= $800000 then // if the freq of an symbol is to high go to safer method
         failBack := True;
       tmp := sum;
       Inc(sum, count[c]);
       count[c] := tmp;
       if Integer(count[c]) <> sum then
         for i := count[c] to sum - 1 do
           Inc(bucket[c * 256 + T[i]]);
     end;
     // 2. Swap bucket entries
     for c := 0 to ST_ALPHABET_SIZE - 1 do
     begin
       for d := 0 to c - 1 do
       begin
         tmp := bucket[(d shl 8) or c];
         bucket[(d shl 8) or c] := bucket[(c shl 8) or d];
         bucket[(c shl 8) or d] := tmp;
       end;
     end;
     sum := 0;
     for w := 0 to ST_ALPHABET_SIZE * ST_ALPHABET_SIZE - 1 do
     begin
       if bucket[w] > 0 then
       begin
         P[sum] := 1;
         Inc(sum, bucket[w]);
       end;
     end;
     //    bsc_unst_reconstruct_serial(T, P, count, n, index, failBack);
     // Initialize index array with count values
      index := Count; // Move(count^, index[0], ALPHABET_SIZE * SizeOf(LongWord));

      // Initialize group array with -1
      for i := 0 to ST_ALPHABET_SIZE - 1 do
        group[i] := -1;

      // Build P array
      g := 0;
      for i := 0 to n - 1 do
      begin
        if P[i] > 0 then
          g := i;

        ch := T[i];
        if group[ch] < g then
        begin
          group[ch] := i;
          P[i] := (ch shl 24) or index[ch];
        end
        else
        begin
          P[i] := (ch shl 24) or $800000 or group[ch];
          Inc(P[group[ch]]);
        end;
        Inc(index[ch]);
      end;

      // Reconstruct original data
      pIndex := AIndex;
      for i := n - 1 downto 0 do
      begin
        u := P[pIndex];
        if (u and $800000) <> 0 then
        begin
          pIndex := u and $7fffff;
          u := P[pIndex];
        end;
        T[i] := u shr 24;
        Dec(P[pIndex]);
        pIndex := u and $7fffff;
     end;
   end;


//==============================================================================
//                     ST1, ST2 & ST3 testing functions
//==============================================================================
Procedure TestST;
 var S, D : TMemoryStream;
     FirstChar : byte;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas');
         d.Size := S.Size;
         FirstChar := STEncode(PByte(s.Memory), PByte(D.Memory), S.Size);
         STDecode(D.Memory, D.Size, FirstChar);
         d.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-ST.txt');
         if (d.Size <> s.Size) or (CompareMem(S.Memory, d.Memory, S.Size) = false) then
           raise Exception.Create('ST: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;

Procedure TestST2;
 var S, D : TMemoryStream;
     FirstChar, SecondChar : byte;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas');
         d.Size := S.Size;
         ST2Encode(PByte(s.Memory), PByte(D.Memory), S.Size, FirstChar, SecondChar);
         ST2Decode(D.Memory, D.Size, FirstChar, SecondChar);
         d.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-ST2.txt');
         if (d.Size <> s.Size) or (CompareMem(S.Memory, d.Memory, S.Size) = false) then
           raise Exception.Create('ST2: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;

Procedure TestST3;
 var S, D : TMemoryStream;
     AIndex : integer;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas');
         d.LoadFromFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas');
         AIndex := ST3Encode(D.Memory, D.Size);
         d.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-ST3encoded.txt');
         ST3Decode(D.Memory, D.Size, AIndex);
         d.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-ST3decoded.txt');
         if (d.Size <> s.Size) or (CompareMem(S.Memory, d.Memory, S.Size) = false) then
           raise Exception.Create('ST3: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;


{$IFDEF SELFTESTDEBUGMODE}
initialization
//  TestST;
//  TestST2;
//  TestST3;
{$ENDIF}
end.
