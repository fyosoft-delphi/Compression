unit fs.Generic.Coder.PP.Mtf;

interface

uses System.Classes;

//==============================================================================
//           FastMtfEncode & FastMtfDecode preprocessing functions
// 2025.01.26 Simple MTF compression algorithm redesigned as descended of
//   TExtMemoryStream. First running copy
// 2025.09.11 Redesigned as a procedure, to be able to use it as a function that
//   operating on single source stream (namely its Memory variable).
//==============================================================================
procedure FastMTFEncode(AInPtr, AOutPtr: PByte; ASize : NativeInt); overload;
procedure FastMTFEncode(AInPtr: PByte; ASize : NativeInt); overload;

procedure FastMTFDecode(AInPtr, AOutPtr: PByte; ASize : NativeInt); overload;
procedure FastMTFDecode(AInPtr : PByte; ASize : NativeInt); overload;


implementation


procedure FastMTFEncode(AInPtr, AOutPtr: PByte; ASize : NativeInt);
 var FAlphabet: array[0..255] of Byte;  // Alfabe listesi (0..255)
     FCharToIndex: array[0..255] of Integer;  // Karakterlerin indekslerini saklar
     Index: NativeInt;
     CurrentChar: Byte;
   begin
     for var i := 0 to 255 do // Alfabeyi baþlat (0..255)
     begin
       FAlphabet[i] := Byte(i);
       FCharToIndex[i] := i;  // Her karakterin baþlangýç pozisyonu
     end;
     Dec(ASize);
     for var i := 0 to ASize do
     begin
       CurrentChar := AInPtr[i];
       Index := FCharToIndex[CurrentChar]; // Karakterin indeksini doðrudan diziden al
       AOutPtr[i] := Byte(Index); // MTF deðerini kaydet
       if Index > 0 then      // Karakteri listenin baþýna taþý
       begin // Karakteri baþa taþý (System.Move ile optimize edilmiþ)
         System.Move(FAlphabet[0], FAlphabet[1], Index);  // Kaydýrma iþlemi
         FAlphabet[0] := CurrentChar;
         for Index := Index downto 1 do // Karakter indekslerini güncelle
           FCharToIndex[FAlphabet[Index]] := Index;
         FCharToIndex[CurrentChar] := 0;
       end;
     end;
   end;

procedure FastMTFEncode(AInPtr: PByte; ASize : NativeInt);
   begin
     FastMTFEncode(AInPtr, AInPtr, ASize);
   end;

procedure FastMTFDecode(AInPtr, AOutPtr: PByte; ASize : NativeInt);
 var FAlphabet: array[0..255] of Byte;  // Alfabe listesi (0..255)
     FCharToIndex: array[0..255] of Integer;  // Karakterlerin indekslerini saklar
     Index: NativeInt;
     CurrentChar: Byte;
   begin
     for var i := 0 to 255 do // Alfabeyi baþlat (0..255)
     begin
       FAlphabet[i] := Byte(i);
       FCharToIndex[i] := i;  // Her karakterin baþlangýç pozisyonu
     end;
     Dec(ASize);
     for var i := 0 to ASize do
     begin
       Index := AInPtr[i]; // MTF deðerini al
       CurrentChar := FAlphabet[Index];    // Alfabe listesindeki karakteri bul
       AOutPtr[i] := CurrentChar; // Orijinal karakteri kaydet
       if Index > 0 then // Karakteri listenin baþýna taþý
       begin // Karakteri baþa taþý (System.Move ile optimize edilmiþ)
         System.Move(FAlphabet[0], FAlphabet[1], Index);  // Kaydýrma iþlemi
         FAlphabet[0] := CurrentChar;
         for Index := Index downto 1 do // Karakter indekslerini güncelle
           FCharToIndex[FAlphabet[Index]] := Index;
         FCharToIndex[CurrentChar] := 0;
       end;
     end;
   end;

procedure FastMTFDecode(AInPtr : PByte; ASize : NativeInt);
   begin
     FastMTFDecode(AInPtr, AInPtr, ASize);
   end;



end.

