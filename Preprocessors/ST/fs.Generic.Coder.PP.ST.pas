{$I _fsInclude.inc}

unit fs.Generic.Coder.PP.ST;

interface

uses System.SysUtils, System.Classes;

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


{$IFDEF SELFTESTDEBUGMODE}
initialization
//  TestST;
//  TestST2;
{$ENDIF}
end.

