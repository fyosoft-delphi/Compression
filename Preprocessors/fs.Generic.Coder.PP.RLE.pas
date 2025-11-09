{$I _fsInclude.inc}

unit fs.Generic.Coder.PP.RLE;

interface

uses System.Classes, System.SysUtils;


//==============================================================================
//                            RLEEncode & RLEDecode
// Simple RLE compression algorithm redesigned as a descendant of TMemoryStream.
// 2025.01.26 -First running copy.
// 2025.06.16 -SavePrevious made a class procedure.
// 2025.10.19 -RLEMarker detection algorithm simplified.
//     -Converted to preprocessing functions to be used with a generic coder.
//     -Byte boundary of RLE repetitions removed.
// 2025.10.19 -Settings saver RleEncodeS & RleDecodeS functions and related
//   self-test procedure added.
//     -RLE0EncodeS & RLE0DecodeS functions added.
// 2025.11.01 -CalculateRLEGain function added to calculate the exact gain in bytes.
//     -CalculateGain SelfTest inserted into the stream-based self-test function.
//     -When repetition > 510 bytes (for example, 2800 or more), length saving
//   consumed 10 or more bytes. To reduce this, some tests were carried out, but
//   it turned out that only the 58 MB MyMedicine.exe had such long repetitions,
//   limited to 6 occurrences in total, resulting in a total saving of only 47
//   bytes. Wiki8 has no such repetitions. As a result of these findings, the
//   length-saving algorithm was left untouched.
//
// TO DO: Convert all algorithms to pointer-based implementations instead of
//        index–based array ones.
//==============================================================================

Function RLEEncode(const ASourceStream : TMemoryStream) : byte; overload;
Procedure RLEDecode(const ASourceStream : TMemoryStream; RLEMarker : byte); overload;

Procedure RLEEncodeS(const ASourceStream : TMemoryStream); overload;
Procedure RLEDecodeS(const ASourceStream : TMemoryStream); overload;

function CalculateRLEGain(ASource: PByte; ASrcSize: NativeInt; RLEMarker: Byte): NativeInt;
function CalculateRLEGain2(ASource: PByte; ASrcSize: NativeInt; out SuggestedMarker: Byte): NativeInt;
function DetectRLEMarker(Const ASource: PByte; Const ABufferSize: NativeInt; RLEThreshold : byte): Byte;

Procedure RLE0EncodeS(const ASourceStream : TMemoryStream); overload;
Procedure RLE0DecodeS(const ASourceStream : TMemoryStream); overload;

implementation

function DetectRLEMarker(Const ASource: PByte; Const ABufferSize: NativeInt; RLEThreshold : byte): Byte;
 var Stats: array[0..255] of record Total, Single: Integer; end;
     i, Count: NativeInt;
     CurrentByte, BestMarker: Byte;
     MinCost, Cost: Integer;
   begin
     FillChar(Stats, SizeOf(Stats), 0);
     i := 0;
     while i < ABufferSize do      // collect statistics
     begin
       CurrentByte := ASource[i];
       Count := 1;
       while (i + Count < ABufferSize) and (ASource[i + Count] = CurrentByte) do  // count repetitions
         Inc(Count);
       // update statistics
       Inc(Stats[CurrentByte].Total, Count);
       if Count < RLEThreshold then
         Inc(Stats[CurrentByte].Single, Count)
       else Inc(Stats[CurrentByte].Single, 0); // RLE'ye girecek - maliyeti yok
       Inc(i, Count);
     end;
     MinCost := MaxInt;  // Find the best marker
     BestMarker := 0;
     for i := 0 to 255 do
     begin
       if Stats[i].Total = 0 then
       begin
         BestMarker := i;  // Hiç kullanılmamış - mükemmel!
         Break;
       end;
       Cost := Stats[i].Single * 2;
       if Cost < MinCost then
       begin
         MinCost := Cost;
         BestMarker := i;
       end;
     end;
     Result := BestMarker;
   end;

Function RLEEncode(const ASourceStream : TMemoryStream) : byte;
 const RLEThreshold = 3;  // means 4 or more repetitions replaced with 3 bytes RLE block
 var ADestinationStream : TMemoryStream;
     ASource, ADestination : PByte;
     ASrcPos, ADstPos, ASrcSize : NativeInt;
     Current, RleDataMarker, RleDataByte : byte;
     RleDataRepetitions : integer;

    Procedure SavePrevious;  // check whether previous data is rle marker or not...
       begin
         if (RleDataByte = RleDataMarker) or (RleDataRepetitions > RLEThreshold) then
         begin
           ADestination[ADstPos] := RleDataMarker;
           System.Inc(ADstPos);
           ADestination[ADstPos] := RleDataByte;
           System.Inc(ADstPos);
           while RleDataRepetitions > 254 do
           begin
             ADestination[ADstPos] := 255;
             System.Inc(ADstPos);
             System.Dec(RleDataRepetitions, 255);
           end;
           ADestination[ADstPos] := RleDataRepetitions;
           System.Inc(ADstPos);
         end
         else   // save previous character as normal data
         begin
           while RleDataRepetitions > 0 do    // if less than treshold then bytewise save
           begin
             ADestination[ADstPos] := RleDataByte;
             System.Inc(ADstPos);
             System.Dec(RleDataRepetitions);
           end;
         end
       end;

   begin
     ADestinationStream := TMemoryStream.Create;
     try
       ASource := ASourceStream.Memory;
       ASrcSize := ASourceStream.Size;
       ADestinationStream.Size := round(ASrcSize * 2.1) + 1024;
       ADestination := ADestinationStream.Memory;
       // Progress.pStart(0, OriginalSize, 20, 'Encoding by RLE with parameters: ' + Parameters);
       RleDataMarker := DetectRLEMarker(ASource, ASrcSize, RLEThreshold);
       Result := RleDataMarker;
       RleDataRepetitions := 1;
       RleDataByte := ASource[0];
       ASrcPos := 1;
       ADstPos := 0;
       while ASrcPos < ASrcSize do
       begin
         //Progress.pIncx; //Current := Position;
         current := ASource[ASrcPos];
         System.Inc(ASrcPos);
         if (Current = RleDataByte) then // and (RleDataRepetitions < 255) then
           Inc(RleDataRepetitions)
         else   // repeating is interrupted...
         begin  // Write the run marker and the repeated byte
           SavePrevious();
           RleDataByte := Current;  // Start a new run
           RleDataRepetitions := 1;
         end;
       end;
       SavePrevious();  // Write the last run
       ASourceStream.Size := ADstPos;
       ASource := ASourceStream.Memory;
       for var i := 0 to ADstPos - 1 do
         ASource[i] := ADestination[i];
       //Progress.pDone;
     finally
       ADestinationStream.Free;
     end;
   end;

Procedure RLEDecode(const ASourceStream : TMemoryStream; RLEMarker : byte);
 var ADestinationStream : TMemoryStream;
     ASource, ADestination : PByte;
     ASrcPos, ADstPos, ASrcSize : NativeInt;
     Current : byte;
     Repetitions: integer;
   begin
     ADestinationStream := TMemoryStream.Create;
     try
       ASource := ASourceStream.Memory;
       ASrcSize := ASourceStream.Size;
       ADestinationStream.Size := round(ASrcSize * 3.1) + 1024;
       ADestination := ADestinationStream.Memory;
       //Progress.pStart(0, ASize, 20, 'Decoding by RLE with parameters: ' + Parameters);
       ASrcPos := 0;
       ADstPos := 0;
       while ASrcPos < ASrcSize do
       begin
         Current := ASource[ASrcPos]; // ReadFromByte;
         System.Inc(ASrcPos);
         //Progress.pIncx; //Current := Position;
         if Current = RLEMarker then
         begin // This byte indicates a run
           Current := ASource[ASrcPos]; // ReadFromByte;
           System.Inc(ASrcPos);
           repetitions := 0;
           while ASource[ASrcPos] = 255 do
           begin
             System.Inc(Repetitions, 255);
             System.Inc(ASrcPos);
           end;
           System.Inc(Repetitions, ASource[ASrcPos]);
           System.Inc(ASrcPos);
           //Progress.pIncx; //Current := Position;
           while Repetitions > 0 do
           begin
             ADestination[ADstPos] := Current;
             System.Inc(ADstPos);
             System.Dec(Repetitions);
           end;
         end
         else
         begin // This byte is not a marker, just copy it
           ADestination[ADstPos] := Current;
           System.Inc(ADstPos);
         end;
       end;
       ASourceStream.Size := ADstPos;
       ASource := ASourceStream.Memory;
       for var i := 0 to ADstPos - 1 do
         ASource[i] := ADestination[i];
       // Progress.pDone;
     finally
       ADestinationStream.Free;
     end;
   end;

//==============================================================================
//                Settings Saving RLE Encode/Decode Functions
//==============================================================================
Procedure RLEEncodeS(const ASourceStream : TMemoryStream);
 const RLEThreshold = 3;  // means 4 or more repetitions replaced with 3 bytes RLE block
 var ADestinationStream : TMemoryStream;
     ASource, ADestination : PByte;
     ASrcPos, ADstPos, ASrcSize : NativeInt;
     Current, RleDataMarker, RleDataByte : byte;
     RleDataRepetitions : integer;

    Procedure SavePrevious;  // check whether previous data is rle marker or not...
       begin
         if (RleDataByte = RleDataMarker) or (RleDataRepetitions > RLEThreshold) then
         begin
           ADestination[ADstPos] := RleDataMarker;
           System.Inc(ADstPos);
           ADestination[ADstPos] := RleDataByte;
           System.Inc(ADstPos);
           while RleDataRepetitions > 254 do
           begin
             ADestination[ADstPos] := 255;
             System.Inc(ADstPos);
             System.Dec(RleDataRepetitions, 255);
           end;
           ADestination[ADstPos] := RleDataRepetitions;
           System.Inc(ADstPos);
         end
         else   // save previous character as normal data
         begin
           while RleDataRepetitions > 0 do    // if less than treshold then bytewise save
           begin
             ADestination[ADstPos] := RleDataByte;
             System.Inc(ADstPos);
             System.Dec(RleDataRepetitions);
           end;
         end
       end;

   begin
     ADestinationStream := TMemoryStream.Create;
     try
       ASource := ASourceStream.Memory;
       ASrcSize := ASourceStream.Size;
       ADestinationStream.Size := round(ASrcSize * 2.1) + 1024;
       ADestination := ADestinationStream.Memory;
       // Progress.pStart(0, OriginalSize, 20, 'Encoding by RLE with parameters: ' + Parameters);
       RleDataMarker := DetectRLEMarker(ASource, ASrcSize, RLEThreshold);
       ADestination[0] := RleDataMarker;
       PCardinal(@ADestination[1])^ := Cardinal(ASrcSize);
       ADstPos := 5; // 1 byte marker + 4 byte size
//       ADestinationStream.Write(RleDataMarker, 1);
//       ADestinationStream.Write(ASrcSize, Sizeof(ASrcSize));
//       ADstPos := ADestinationStream.Position;
       RleDataRepetitions := 1;
       RleDataByte := ASource[0];
       ASrcPos := 1;
       while ASrcPos < ASrcSize do
       begin
         //Progress.pIncx; //Current := Position;
         current := ASource[ASrcPos];
         System.Inc(ASrcPos);
         if (Current = RleDataByte) then // and (RleDataRepetitions < 255) then
           Inc(RleDataRepetitions)
         else   // repeating is interrupted...
         begin  // Write the run marker and the repeated byte
           SavePrevious();
           RleDataByte := Current;  // Start a new run
           RleDataRepetitions := 1;
         end;
       end;
       SavePrevious();  // Write the last run
       ASourceStream.Size := ADstPos;
//       ASourceStream.SetSize(ADstPos);
       if ADstPos > 0 then
         Move(ADestination^, ASourceStream.Memory^, ADstPos);
       //Progress.pDone;
     finally
       ADestinationStream.Free;
     end;
   end;

Procedure RLEDecodeS(const ASourceStream : TMemoryStream);
 var ADestinationStream : TMemoryStream;
     ASource, ADestination : PByte;
     ASrcPos, ADstPos, ASrcSize, ADstSize : NativeInt;
     RLEMarker, Current : byte;
     Repetitions: integer;
   begin
     ADestinationStream := TMemoryStream.Create;
     try
       //Progress.pStart(0, ASize, 20, 'Decoding by RLE with parameters: ' + Parameters);
       ASource := ASourceStream.Memory;
       ASrcSize := ASourceStream.Size;
       RLEMarker := ASource[0];
       ADstSize := PCardinal(@ASource[1])^;
       ASrcPos := 5;
//       ASourceStream.Read(RLEMarker, 1);
//       ASourceStream.Read(ADstSize, Sizeof(ADstSize));
//       ASrcPos := ASourceStream.Position;
       ADestinationStream.Size := ADstSize;
       ADestination := ADestinationStream.Memory;
       ADstPos := 0;
       while (ASrcPos < ASrcSize) and (ADstPos < ADstSize) do
       begin
         Current := ASource[ASrcPos]; // ReadFromByte;
         System.Inc(ASrcPos);
         //Progress.pIncx; //Current := Position;
         if Current = RLEMarker then
         begin // This byte indicates a run
           Current := ASource[ASrcPos]; // ReadFromByte;
           System.Inc(ASrcPos);
           repetitions := 0;
           while ASource[ASrcPos] = 255 do
           begin
             System.Inc(Repetitions, 255);
             System.Inc(ASrcPos);
           end;
           System.Inc(Repetitions, ASource[ASrcPos]);
           System.Inc(ASrcPos);
           //Progress.pIncx; //Current := Position;
           while Repetitions > 0 do
           begin
             ADestination[ADstPos] := Current;
             System.Inc(ADstPos);
             System.Dec(Repetitions);
           end;
         end
         else
         begin // This byte is not a marker, just copy it
           ADestination[ADstPos] := Current;
           System.Inc(ADstPos);
         end;
       end;
       ASourceStream.Size := ADstPos;
//       ASourceStream.SetSize(ADstPos);
       if ADstPos > 0 then
         Move(ADestination^, ASourceStream.Memory^, ADstPos);
       // Progress.pDone;
     finally
       ADestinationStream.Free;
     end;
   end;


//==============================================================================
//                       RLE0 Encode/Decode Functions
//==============================================================================
procedure RLE0EncodeS(const ASourceStream: TMemoryStream);
 const RLEThreshold = 1;
 var ADestinationStream: TMemoryStream;
     ASource, ADestination: PByte;
     ASrcPos, ADstPos, ASrcSize: NativeInt;
     RleDataRepetitions: Cardinal;
     CurrentByte: Byte;
   begin
     ADestinationStream := TMemoryStream.Create;
     try
       ASource := ASourceStream.Memory;
       ASrcSize := ASourceStream.Size;
       ADestinationStream.Size := ASrcSize + 1024;
       ADestination := ADestinationStream.Memory;
       PCardinal(@ADestination[0])^ := Cardinal(ASrcSize);
       ADstPos := 4;
       ASrcPos := 0;
       while ASrcPos < ASrcSize do
       begin
         CurrentByte := ASource[ASrcPos];
         if CurrentByte = 0 then
         begin // Null serisi başladı - uzunluğunu bul
           RleDataRepetitions := 1;
           Inc(ASrcPos);
           // Null serisinin sonunu bul (daha hızlı)
           while (ASrcPos < ASrcSize) and (ASource[ASrcPos] = 0) do
           begin
             Inc(RleDataRepetitions);
             Inc(ASrcPos);
           end;
           // RLE0 kaydını yaz
           ADestination[ADstPos] := 0; // Marker
           Inc(ADstPos);
           // Değişken uzunluklu sayı kodlama
           while RleDataRepetitions > 254 do
           begin
             ADestination[ADstPos] := 255;
             Inc(ADstPos);
             Dec(RleDataRepetitions, 255);
           end;
           ADestination[ADstPos] := RleDataRepetitions;
           Inc(ADstPos);
         end
         else
         begin // Normal byte
           ADestination[ADstPos] := CurrentByte;
           Inc(ADstPos);
           Inc(ASrcPos);
         end;
       end;
       // Stream'i güncelle
       ASourceStream.Size := ADstPos;
       if ADstPos > 0 then
         Move(ADestination^, ASourceStream.Memory^, ADstPos);
     finally
       ADestinationStream.Free;
     end;
   end;

procedure RLE0DecodeS(const ASourceStream: TMemoryStream);
 var ADestinationStream: TMemoryStream;
     ASource, ADestination: PByte;
     ASrcPos, ADstPos, ASrcSize, ADstSize: NativeInt;
     Repetitions: Cardinal;
   begin
     ADestinationStream := TMemoryStream.Create;
     try
       ASource := ASourceStream.Memory;
       ASrcSize := ASourceStream.Size;
       if ASrcSize < 4 then
         raise Exception.Create('Invalid RLE0 stream');
       ADstSize := PCardinal(@ASource[0])^;
       ASrcPos := 4;
       ADestinationStream.Size := ADstSize;
       ADestination := ADestinationStream.Memory;
       ADstPos := 0;
       while (ASrcPos < ASrcSize) and (ADstPos < ADstSize) do
       begin
         if ASource[ASrcPos] = 0 then
         begin // RLE0 kaydı
           Inc(ASrcPos);
           if ASrcPos >= ASrcSize then
             Break;
           Repetitions := 0;
           // Count'u decode et
           while (ASrcPos < ASrcSize) and (ASource[ASrcPos] = 255) do
           begin
             Inc(Repetitions, 255);
             Inc(ASrcPos);
           end;
           if ASrcPos < ASrcSize then
           begin
             Inc(Repetitions, ASource[ASrcPos]);
             Inc(ASrcPos);
           end;
           // Null byte'ları yaz (daha hızlı - FillChar)
           if (Repetitions > 0) and (ADstPos + Repetitions <= ADstSize) then
           begin
             FillChar(ADestination[ADstPos], Repetitions, 0);
             Inc(ADstPos, Repetitions);
           end;
         end
         else
         begin // Normal byte
           ADestination[ADstPos] := ASource[ASrcPos];
           Inc(ADstPos);
           Inc(ASrcPos);
         end;
       end;
       ASourceStream.Size := ADstSize;
       if ADstSize > 0 then
         Move(ADestination^, ASourceStream.Memory^, ADstSize);
     finally
       ADestinationStream.Free;
     end;
   end;


function CalculateRLEGain2(ASource: PByte; ASrcSize: NativeInt; out SuggestedMarker: Byte): NativeInt;
 const RLEThreshold = 3; // 4 veya daha fazla tekrar için
 var Stats: array[0..255] of record
         TotalCount: Integer;      // Toplam byte sayısı
         SingleCount: Integer;     // Tekil ve kısa tekrarlar (RLE'ye girmeyecek)
         RepeatBlocks: Integer;    // RLE bloğu olacak tekrar sayısı
         RepeatBytes: Integer;     // RLE bloklarındaki toplam byte
       end;
     i, CurrentPos: NativeInt;
     RepeatLength: Integer;
     MinCost, CurrentCost: Integer;
     TotalGain, TotalLoss: Integer;
     BestMarker, CurrentByte: Byte;
   begin
     Result := 0;
     if ASrcSize = 0 then Exit;
     // İstatistikleri topla
     FillChar(Stats, SizeOf(Stats), 0);
     CurrentPos := 0;
     while CurrentPos < ASrcSize do
     begin
       CurrentByte := ASource[CurrentPos];
       RepeatLength := 1;
       // Tekrar uzunluğunu bul
       while (CurrentPos + RepeatLength < ASrcSize) and (ASource[CurrentPos + RepeatLength] = CurrentByte) do //and (RepeatLength < 255) do
         Inc(RepeatLength);
       // İstatistikleri güncelle
       Inc(Stats[CurrentByte].TotalCount, RepeatLength);
       if RepeatLength > RLEThreshold then
       begin // RLE bloğu olacak
         Inc(Stats[CurrentByte].RepeatBlocks);
         Inc(Stats[CurrentByte].RepeatBytes, RepeatLength);
       end
       else // Tekil veya kısa tekrar
       begin
         Inc(Stats[CurrentByte].SingleCount, RepeatLength);
       end;
       Inc(CurrentPos, RepeatLength);
     end;
     // En iyi marker'ı bul ve kazancı hesapla
     BestMarker := 0;
     MinCost := MaxInt;
     TotalGain := 0;
     TotalLoss := 0;
     for i := 0 to 255 do
     begin
       if Stats[i].TotalCount = 0 then
       begin // Hiç kullanılmamış byte - mükemmel marker
         BestMarker := i;
         MinCost := 0;
         Break;
       end;
       // Maliyet hesabı:
       // - SingleCount: Her biri 2 byte ek yük (1 → 3 byte) = SingleCount * 2
       // - RepeatBytes: 0 ek yük (zaten 3 byte olacak) = 0
       // - RepeatBlocks: Marker'ın kendisi repeat block olursa kazanç kaybı
       CurrentCost := Stats[i].SingleCount * 2;
       if CurrentCost < MinCost then
       begin
         MinCost := CurrentCost;
         BestMarker := i;
       end;
     end;
     SuggestedMarker := BestMarker;
     // Toplam kazanç/kayıp hesapla
     if MinCost = 0 then
     begin // Hiç kullanılmamış marker - sadece kazanç
       for i := 0 to 255 do
       begin
         if Stats[i].RepeatBytes > 0 then
         begin  // Kazanç: (n - 3) byte (n: tekrar uzunluğu)
           TotalGain := TotalGain + (Stats[i].RepeatBytes - (Stats[i].RepeatBlocks * 3));
         end;
       end;
     end
     else
     begin  // Marker kullanılıyor - hem kazanç hem kayıp
       for i := 0 to 255 do
       begin
         if i = BestMarker then
         begin // Marker byte'ı için kayıp
           TotalLoss := TotalLoss + (Stats[i].SingleCount * 2);
           // Marker'ın kendi repeat blokları için nötr (zaten 3 byte)
           // Kazanç: 0
         end
         else
         begin // Diğer byte'lar için kazanç
           if Stats[i].RepeatBytes > 0 then
           begin
             TotalGain := TotalGain + (Stats[i].RepeatBytes - (Stats[i].RepeatBlocks * 3));
           end;
         end;
       end;
     end;
     // Net kazanç yüzdesi
     Result := (TotalGain - TotalLoss); // / ASrcSize * 100.0;
   end;

function CalculateRLEGain(ASource: PByte; ASrcSize: NativeInt; RLEMarker: Byte): NativeInt;
 const RLEThreshold = 3;  // means 4 or more repetitions replaced with 3 bytes RLE block
 var EncodedSize, RleDataRepetitions : Cardinal;
//     BigBlocks : Cardinal;
     PrevByte : byte;
     BufferEnd : PByte;
   begin
     BufferEnd := ASource + ASrcSize;
     RleDataRepetitions := 1;
     PrevByte := ASource^;
     System.Inc(ASource);
     EncodedSize := 0;
//     BigBlocks := 0;
     while ASource < BufferEnd do
     begin
       if (ASource^ = PrevByte) then
         Inc(RleDataRepetitions)
       else   // repeating is interrupted...
       begin
//         if RleDataRepetitions > 510 then
//           BigBlocks := BigBlocks + Ord(RleDataRepetitions > 510);
         if (PrevByte = RleMarker) or (RleDataRepetitions > RLEThreshold) then
           System.Inc(EncodedSize, 3 + RleDataRepetitions div 255) // 3 byte header
         else System.Inc(EncodedSize, RleDataRepetitions);
         PrevByte := ASource^;  // Start a new run
         RleDataRepetitions := 1;
       end;
       System.Inc(ASource);  // move to next character
     end;
     if (PrevByte = RleMarker) or (RleDataRepetitions > RLEThreshold) then
       System.Inc(EncodedSize, 3 + RleDataRepetitions div 255) // 3 byte header
     else System.Inc(EncodedSize, RleDataRepetitions);
//     Result := ASrcSize - EncodedSize + BigBlocks;
     Result := ASrcSize - EncodedSize;
   end;

function CalculateRLEGain3(ASource: PByte; ASrcSize: NativeInt; RLEMarker: Byte): NativeInt;
 const RLEThreshold = 3;  // means 4 or more repetitions replaced with 3 bytes RLE block
 var Current, RleDataByte : byte;
     ASrcPos, EncodedSize, RleDataRepetitions : Cardinal;
   begin
     RleDataRepetitions := 1;
     RleDataByte := ASource[0];
     ASrcPos := 1;
     EncodedSize := 0;
     while ASrcPos < ASrcSize do
     begin
       current := ASource[ASrcPos];
       System.Inc(ASrcPos);
       if (Current = RleDataByte) then // and (RleDataRepetitions < 255) then
         Inc(RleDataRepetitions)
       else   // repeating is interrupted...
       begin
         if (RleDataByte = RleMarker) or (RleDataRepetitions > RLEThreshold) then
           System.Inc(EncodedSize, 3 + RleDataRepetitions div 255) // 3 byte header
         else System.Inc(EncodedSize, RleDataRepetitions);
         RleDataByte := Current;  // Start a new run
         RleDataRepetitions := 1;
       end;
     end;
     if (RleDataByte = RleMarker) or (RleDataRepetitions > RLEThreshold) then
       System.Inc(EncodedSize, 3 + RleDataRepetitions div 255) // 3 byte header
     else System.Inc(EncodedSize, RleDataRepetitions);
     Result := ASrcSize - EncodedSize;
   end;


{
Procedure RLE0EncodeS(const ASourceStream : TMemoryStream);
 const RLEThreshold = 1;  // means all null chars must be replaced with rle block
 var ADestinationStream : TMemoryStream;
     ASource, ADestination : PByte;
     ASrcPos, ADstPos, ASrcSize : NativeInt;
     RleDataRepetitions : Cardinal; // prevent negative values
   begin
     ADestinationStream := TMemoryStream.Create;
     try
       ASource := ASourceStream.Memory;
       ASrcSize := ASourceStream.Size;
       ADestinationStream.Size := round(ASrcSize * 2.1) + 1024;
       ADestination := ADestinationStream.Memory;
       // Progress.pStart(0, OriginalSize, 20, 'Encoding by RLE with parameters: ' + Parameters);
       PCardinal(@ADestination[0])^ := Cardinal(ASrcSize);
       ADstPos := 4; // 1 byte marker + 4 byte size
//       ADestinationStream.Write(RleDataMarker, 1);
//       ADestinationStream.Write(ASrcSize, Sizeof(ASrcSize));
//       ADstPos := ADestinationStream.Position;
       ASrcPos := 0;
       RleDataRepetitions := 0;
       while ASrcPos < ASrcSize do
       begin
         //Progress.pIncx; //Current := Position;
         while (ASource[ASrcPos] = 0) and (ASrcPos < ASrcSize) do
         begin
           System.Inc(ASrcPos);
           System.Inc(RleDataRepetitions);
         end;
         if RleDataRepetitions = 0 then  // the most likely case first, save current byte to destination
         begin
           ADestination[ADstPos] := ASource[ASrcPos];
           System.Inc(ADstPos);
           System.Inc(ASrcPos);
         end
         else
         begin
           ADestination[ADstPos] := 0; // save marker
           System.Inc(ADstPos);
           while RleDataRepetitions > 254 do
           begin
             ADestination[ADstPos] := 255;
             System.Inc(ADstPos);
             System.Dec(RleDataRepetitions, 255);
           end;
           ADestination[ADstPos] := RleDataRepetitions;
           System.Inc(ADstPos);
           RleDataRepetitions := 0;
         end;
       end;
       ASourceStream.Size := ADstPos;
//       ASourceStream.SetSize(ADstPos);
       if ADstPos > 0 then
         Move(ADestination^, ASourceStream.Memory^, ADstPos);
       //Progress.pDone;
     finally
       ADestinationStream.Free;
     end;
   end;

Procedure RLE0DecodeS(const ASourceStream : TMemoryStream);
 var ADestinationStream : TMemoryStream;
     ASource, ADestination : PByte;
     ASrcPos, ADstPos, ASrcSize, ADstSize : NativeInt;
     Repetitions: Cardinal;
   begin
     ADestinationStream := TMemoryStream.Create;
     try
       //Progress.pStart(0, ASize, 20, 'Decoding by RLE with parameters: ' + Parameters);
       ASource := ASourceStream.Memory;
       ASrcSize := ASourceStream.Size;
       ADstSize := PCardinal(@ASource[0])^;
       ASrcPos := 4;
//       ASourceStream.Read(RLEMarker, 1);
//       ASourceStream.Read(ADstSize, Sizeof(ADstSize));
//       ASrcPos := ASourceStream.Position;
       ADestinationStream.Size := ADstSize;
       ADestination := ADestinationStream.Memory;
       ADstPos := 0;
       while (ASrcPos < ASrcSize) and (ADstPos < ADstSize) do
       begin
         //Progress.pIncx; //Current := Position;
         if ASource[ASrcPos] = 0 then
         begin // This byte indicates a run
           System.Inc(ASrcPos);
           repetitions := 0;
           while ASource[ASrcPos] = 255 do
           begin
             System.Inc(Repetitions, 255);
             System.Inc(ASrcPos);
           end;
           System.Inc(Repetitions, ASource[ASrcPos]);
           System.Inc(ASrcPos);
           //Progress.pIncx; //Current := Position;
           while Repetitions > 0 do
           begin
             ADestination[ADstPos] := 0;
             System.Inc(ADstPos);
             System.Dec(Repetitions);
           end;
         end
         else
         begin // This byte is not a marker, just copy it
           ADestination[ADstPos] := ASource[ASrcPos];
           System.Inc(ASrcPos);
           System.Inc(ADstPos);
         end;
       end;
       ASourceStream.Size := ADstPos;
//       ASourceStream.SetSize(ADstPos);
       if ADstPos > 0 then
         Move(ADestination^, ASourceStream.Memory^, ADstPos);
       // Progress.pDone;
     finally
       ADestinationStream.Free;
     end;
   end;

}


{
//==============================================================================
//                                    Trashcan
//==============================================================================
Function DetectRLEMarker1(ASource: PByte; ABufferSize : NativeInt) : byte;
 type
     TDups = Record
       Freq     : integer;
       DupCount : integer;
       DupFreq  : integer;
     End;
 var FDups : Array[0..Byte.MaxValue] of TDups;
     Marker : byte;
     Prev, Next : byte;
     DupCount, ACost : integer;
     FMinCost : NativeInt;
   begin
     FillChar(FDups, Sizeof(FDups), #0);
     Prev := ASource[0];
     DupCount := 1;
     for var i := 1 to ABufferSize-1 do
     begin
       Next := ASource[i];
       Inc(FDups[Next].Freq);
       if Prev = Next then
         inc(DupCount)
       else
       begin
         if DupCount >= RLEThreshold then
         begin
           Inc(FDups[Prev].DupFreq, DupCount);
           inc(FDups[Prev].DupCount);
         end;
         DupCount := 1;
       end;
       Prev := Next;
     end;
     if DupCount >= RLEThreshold then
     begin
       Inc(FDups[Prev].DupFreq, DupCount);
       inc(FDups[Prev].DupCount);
     end;

     FMinCost := Integer.MaxValue;
     Marker := 0;
     For var i := 0 to High(FDups) do
     begin
       if FDups[i].Freq = 0 then   // no cost means zero cost then use it
       begin
         Marker := i;
         FMinCost := 0;
         Break;
       end;
       ACost := (FDups[i].Freq - FDups[i].DupFreq) * 2;
       if ACost < FMinCost then
       begin
         FMinCost := ACost;
         Marker := i;
       end;
     end;
//     FStat := CalcAsciiFreqs;
//     MinFreq := 0;
//     for var i := 0 to Byte.MaxValue do
//       if FStat[i] < FStat[MinFreq] then
//         MinFreq := i;
//     RLEMarker := MinFreq;
     Result := Marker;
   end;

Function RLEEncodeX(const ASource : PByte; const ASourceSize: NativeInt; out ADstSize : NativeInt) : byte;
 var ADest : TArray<Byte>;
     ASrcPos, ADstPos : NativeInt;
     AData : TRleRecord;   // will be filled
     Current : Byte;

Procedure SavePrevious(AData : TRleRecord);  // check whether previous data is rle marker or not...
   begin
     if (AData.Data = AData.marker) or (AData.repetitions > RLEThreshold) then
     begin
       ADest[ADstPos] := AData.marker;
       System.Inc(ADstPos);
       ADest[ADstPos] := AData.repetitions;
       System.Inc(ADstPos);
       ADest[ADstPos] := AData.data;
       System.Inc(ADstPos);
     end
     else   // save previous character as normal data
     begin
       while AData.repetitions > 0 do    // if less than treshold then bytewise save
       begin
         ADest[ADstPos] := AData.data;
         System.Inc(ADstPos);
         System.Dec(AData.repetitions);
       end;
     end
   end;

   begin
//     Progress.pStart(0, OriginalSize, 20, 'Encoding by RLE with parameters: ' + Parameters);
     AData.marker := DetectRLEMarker(ASource, ASourceSize);
     if AData.marker = 32 then  // incompressible file flag
       AData.marker := 33;
     Result := AData.marker;
     AData.repetitions := 1;
     AData.Data := ASource[0];
     ASrcPos := 1;
     ADstPos := 0;
     ADstSize := round(ASourceSize * 1.2) + 1024;
     SetLength(ADest, ADstSize);
     while ASrcPos < ASourceSize - 1 do
     begin
//       Progress.pIncx; //Current := Position;
       current := ASource[ASrcPos];
       System.Inc(ASrcPos);
       if (current = AData.Data) and (AData.repetitions < 255) then
         Inc(AData.repetitions)
       else   // repeating is interrupted...
       begin  // Write the run marker and the repeated byte
         SavePrevious(AData);
         AData.Data := current;  // Start a new run
         AData.repetitions := 1;
       end;
     end;
     SavePrevious(AData);  // Write the last run
     ADstSize := ADstPos;
     for var i := 0 to ADstSize - 1 do
       ASource[i] := ADest[i];
//     Progress.pDone;
   end;

Procedure RLEDecodeX(const ASource : PByte; ASourceSize: NativeInt; RLEMarker : byte);
 var ASrcPos, ADstPos : NativeInt;
     current, repetitions: Byte;
     ADstBuf : PByte;
   begin
//     Progress.pStart(0, ASize, 20, 'Decoding by RLE with parameters: ' + Parameters);
     ASrcPos := 0;
     while ASrcPos < ASourceSize do
     begin
        Current := ASource[ASrcPos]; // ReadFromByte;
        System.Inc(ASrcPos);
//        Progress.pIncx; //Current := Position;
        if Current = RLEMarker then
        begin // This byte indicates a run
          repetitions := ASource[ASrcPos]; // ReadFromByte;
          System.Inc(ASrcPos);
          Current := ASource[ASrcPos]; // ReadFromByte;
          System.Inc(ASrcPos);
//          Progress.pIncx; //Current := Position;
          while repetitions > 0 do
          begin
            ADstBuf[ADstPos] := Current;
            System.Inc(ADstPos);
            System.Dec(repetitions);
          end;
        end
        else
        begin // This byte is not a marker, just copy it
          ADstBuf[ADstPos] := Current;
          System.Inc(ADstPos);
        end;
     end;
//     Progress.pDone;
   end;


//==============================================================================
//                         Bitwise RLE Encode / Decode
//==============================================================================
function RLEEncodeBit(const Data: TBytes): TBytes;
var
  InputPos, OutputPos: Integer;
  DataLen: Integer;
  Count: Integer;
  Output: TBytes;
  CurrentByte: Byte;
begin
  SetLength(Output, Length(Data) * 2); // Maksimum boyut
  InputPos := 0;
  OutputPos := 0;
  DataLen := Length(Data);

  while InputPos < DataLen do
  begin
    // Aynı byte'ları say
    Count := 1;
    CurrentByte := Data[InputPos];

    while (InputPos + Count < DataLen) and
          (Data[InputPos + Count] = CurrentByte) and
          (Count < 32767) do
    begin
      Inc(Count);
    end;

    if Count > 2 then
    begin
      // RLE kaydı - 3 veya daha fazla tekrar
      if Count <= 127 then
      begin
        // Kısa format: [1ccccccc] [dddddddd]
        if OutputPos + 2 >= Length(Output) then
          SetLength(Output, Length(Output) * 2);

        Output[OutputPos] := $80 or (Count and $7F); // MSB=1 + count
        Output[OutputPos + 1] := CurrentByte;
        Inc(OutputPos, 2);
      end
      else
      begin
        // Uzun format: [11111111] [cccccccc] [cccccccc] [dddddddd]
        if OutputPos + 4 >= Length(Output) then
          SetLength(Output, Length(Output) * 2);

        Output[OutputPos] := $FF; // Uzun format marker
        Output[OutputPos + 1] := (Count shr 8) and $FF; // Yüksek byte
        Output[OutputPos + 2] := Count and $FF;         // Düşük byte
        Output[OutputPos + 3] := CurrentByte;
        Inc(OutputPos, 4);
      end;
      Inc(InputPos, Count);
    end
    else
    begin
      // Normal veri veya kısa tekrarlar
      if (CurrentByte and $80) <> 0 then
      begin
        // MSB=1 olan byte - ön ek gerekiyor
        if OutputPos + 2 >= Length(Output) then
          SetLength(Output, Length(Output) * 2);

        Output[OutputPos] := $00; // Ön ek
        Output[OutputPos + 1] := CurrentByte;
        Inc(OutputPos, 2);
      end
      else
      begin
        // MSB=0 olan byte - direkt yaz
        if OutputPos + 1 >= Length(Output) then
          SetLength(Output, Length(Output) * 2);

        Output[OutputPos] := CurrentByte;
        Inc(OutputPos);
      end;
      Inc(InputPos);
    end;
  end;

  // Çıktıyı kes
  SetLength(Result, OutputPos);
  if OutputPos > 0 then
    Move(Output[0], Result[0], OutputPos);
end;

function RLEDecodeBit(const CompressedData: TBytes): TBytes;
var
  InputPos, OutputPos: Integer;
  CompressedLen: Integer;
  Output: TBytes;
  CurrentByte: Byte;
  Count: Integer;
  i: Integer;
begin
  SetLength(Output, Length(CompressedData) * 4); // Maksimum boyut
  InputPos := 0;
  OutputPos := 0;
  CompressedLen := Length(CompressedData);

  while InputPos < CompressedLen do
  begin
    CurrentByte := CompressedData[InputPos];
    Inc(InputPos);

    if CurrentByte = $FF then
    begin
      // Uzun format RLE: [FF] [count_high] [count_low] [data]
      if InputPos + 3 <= CompressedLen then
      begin
        Count := (CompressedData[InputPos] shl 8) or CompressedData[InputPos + 1];
        CurrentByte := CompressedData[InputPos + 2];

        // Çıktı boyutunu kontrol et
        if OutputPos + Count >= Length(Output) then
          SetLength(Output, Length(Output) + Count * 2);

        for i := 1 to Count do
        begin
          Output[OutputPos] := CurrentByte;
          Inc(OutputPos);
        end;

        Inc(InputPos, 3);
      end;
    end
    else if (CurrentByte and $80) <> 0 then
    begin
      // Kısa format RLE: [1ccccccc] [data]
      if InputPos < CompressedLen then
      begin
        Count := CurrentByte and $7F; // 7 bit count
        CurrentByte := CompressedData[InputPos];

        // Çıktı boyutunu kontrol et
        if OutputPos + Count >= Length(Output) then
          SetLength(Output, Length(Output) + Count * 2);

        for i := 1 to Count do
        begin
          Output[OutputPos] := CurrentByte;
          Inc(OutputPos);
        end;

        Inc(InputPos);
      end;
    end
    else if CurrentByte = $00 then
    begin
      // Ön ekli normal veri: [00] [data]
      if InputPos < CompressedLen then
      begin
        // Çıktı boyutunu kontrol et
        if OutputPos + 1 >= Length(Output) then
          SetLength(Output, Length(Output) * 2);

        Output[OutputPos] := CompressedData[InputPos];
        Inc(OutputPos);
        Inc(InputPos);
      end;
    end
    else
    begin
      // Normal veri (MSB=0)
      // Çıktı boyutunu kontrol et
      if OutputPos + 1 >= Length(Output) then
        SetLength(Output, Length(Output) * 2);

      Output[OutputPos] := CurrentByte;
      Inc(OutputPos);
    end;
  end;

  // Çıktıyı kes
  SetLength(Result, OutputPos);
  if OutputPos > 0 then
    Move(Output[0], Result[0], OutputPos);
end;


//==============================================================================
//                              TRLEOptimized
//==============================================================================
function RLEEncodeOptimized(const Data: TBytes): TBytes;
var
  InputPos, OutputPos: Integer;
  DataLen: Integer;
  Count: Integer;
  Output: TBytes;
  CurrentByte: Byte;
  RawStart, RawCount: Integer;

  procedure FlushRawData;
  var
    j: Integer;
  begin
    if RawCount > 0 then
    begin
      if RawCount = 1 then
      begin
        // Tekil byte
        CurrentByte := Data[RawStart];
        if (CurrentByte and $80) <> 0 then
        begin
          // MSB=1 -> [00][data]
          Output[OutputPos] := $00;
          Output[OutputPos + 1] := CurrentByte;
          Inc(OutputPos, 2);
        end
        else if CurrentByte = $00 then
        begin
          // 0x00 -> [00][00]
          Output[OutputPos] := $00;
          Output[OutputPos + 1] := $00;
          Inc(OutputPos, 2);
        end
        else
        begin
          // Normal byte
          Output[OutputPos] := CurrentByte;
          Inc(OutputPos);
        end;
      end
      else
      begin
        // Raw data bloğu: [01][length][data...]
        Output[OutputPos] := $01;
        Output[OutputPos + 1] := RawCount;
        Inc(OutputPos, 2);

        for j := 0 to RawCount - 1 do
        begin
          Output[OutputPos] := Data[RawStart + j];
          Inc(OutputPos);
        end;
      end;
    end;
  end;

begin
  if Length(Data) = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  SetLength(Output, Length(Data) + 1024); // Buffer
  InputPos := 0;
  OutputPos := 0;
  DataLen := Length(Data);
  RawStart := 0;
  RawCount := 0;

  while InputPos < DataLen do
  begin
    // Minimum 4 byte tekrar arıyoruz
    Count := 1;
    CurrentByte := Data[InputPos];

    // Uzun tekrarları kontrol et (en az 4 byte)
    while (InputPos + Count < DataLen) and
          (Data[InputPos + Count] = CurrentByte) and
          (Count < 255) do
    begin
      Inc(Count);
    end;

    if Count >= 4 then
    begin
      // Önceki raw datayı yaz
      FlushRawData;
      RawCount := 0;

      // RLE kaydı: [1xxxxxxx][data]
      if OutputPos + 2 >= Length(Output) then
        SetLength(Output, Length(Output) * 2);

      Output[OutputPos] := $80 or (Count and $7F);
      Output[OutputPos + 1] := CurrentByte;
      Inc(OutputPos, 2);

      Inc(InputPos, Count);
    end
    else
    begin
      // Raw data'ya ekle
      if RawCount = 0 then
        RawStart := InputPos;
      Inc(RawCount);
      Inc(InputPos);

      // Raw data bloğu doldu veya sona ulaştı
      if (RawCount = 255) or (InputPos >= DataLen) then
      begin
        FlushRawData;
        RawCount := 0;
      end;
    end;
  end;

  // Kalan raw datayı yaz
  FlushRawData;

  SetLength(Result, OutputPos);
  if OutputPos > 0 then
    Move(Output[0], Result[0], OutputPos);
end;

function RLEDecodeOptimized(const CompressedData: TBytes): TBytes;
var
  InputPos, OutputPos: Integer;
  CompressedLen: Integer;
  Output: TBytes;
  CurrentByte: Byte;
  Count: Integer;
  i, j: Integer;
begin
  if Length(CompressedData) = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  SetLength(Output, Length(CompressedData) * 3);
  InputPos := 0;
  OutputPos := 0;
  CompressedLen := Length(CompressedData);

  while InputPos < CompressedLen do
  begin
    CurrentByte := CompressedData[InputPos];
    Inc(InputPos);

    case CurrentByte of
      $00:
        begin // Ön ekli byte veya 0x00
          if InputPos < CompressedLen then
          begin
            if OutputPos >= Length(Output) then
              SetLength(Output, Length(Output) * 2);

            Output[OutputPos] := CompressedData[InputPos];
            Inc(OutputPos);
            Inc(InputPos);
          end;
        end;

      $01:
        begin // Raw data bloğu
          if InputPos < CompressedLen then
          begin
            Count := CompressedData[InputPos];
            Inc(InputPos);

            if InputPos + Count <= CompressedLen then
            begin
              if OutputPos + Count >= Length(Output) then
                SetLength(Output, Length(Output) + Count * 2);

              for j := 0 to Count - 1 do
              begin
                Output[OutputPos] := CompressedData[InputPos + j];
                Inc(OutputPos);
              end;
              Inc(InputPos, Count);
            end;
          end;
        end;

      $80..$FF:
        begin // RLE kaydı
          if InputPos < CompressedLen then
          begin
            Count := CurrentByte and $7F;
            CurrentByte := CompressedData[InputPos];
            Inc(InputPos);

            if OutputPos + Count >= Length(Output) then
              SetLength(Output, Length(Output) + Count * 2);

            for i := 1 to Count do
            begin
              Output[OutputPos] := CurrentByte;
              Inc(OutputPos);
            end;
          end;
        end;

    else
      // Normal byte (0x02-0x7F)
      if OutputPos >= Length(Output) then
        SetLength(Output, Length(Output) * 2);

      Output[OutputPos] := CurrentByte;
      Inc(OutputPos);
    end;
  end;

  SetLength(Result, OutputPos);
  if OutputPos > 0 then
    Move(Output[0], Result[0], OutputPos);
end;


//==============================================================================
//                          Variable Length Codes
//==============================================================================
function VarIntEncode(Value: Cardinal): TBytes;
 var Buffer: array[0..4] of Byte; // Max 5 byte
     i, Count: Integer;
     Temp: Cardinal;
   begin
     Count := 0;
     Temp := Value;
     repeat
       Buffer[Count] := Temp and $7F; // 7 bit al
       Temp := Temp shr 7;
       if Temp > 0 then
         Buffer[Count] := Buffer[Count] or $80; // Devam biti
       Inc(Count);
     until Temp = 0;
     SetLength(Result, Count);
     for i := 0 to Count - 1 do
       Result[i] := Buffer[i];
   end;

function VarIntDecode(const Data: TBytes; var Position: Integer): Cardinal;
 var Shift: Integer;
     B: Byte;
   begin
     Result := 0;
     Shift := 0;
     repeat
       if Position >= Length(Data) then
         raise Exception.Create('VarInt decode error: insufficient data');
       B := Data[Position];
       Inc(Position);
       Result := Result or (Cardinal(B and $7F) shl Shift);
       Shift := Shift + 7;
       // 32 bit sınırı (max 5 byte)
       if Shift > 35 then
         raise Exception.Create('VarInt decode error: too many bytes');
     until (B and $80) = 0;
   end;

function VarIntDecodeSingle(const Data: TBytes): Cardinal;
 var Pos: Integer;
   begin
     Pos := 0;
     Result := VarIntDecode(Data, Pos);
   end;

function RLEVarIntCompress(const Data: TBytes): TBytes;
 var InputPos, OutputPos, DataLen, Count: Integer;
     Output: TBytes;
     CurrentByte: Byte;
     EncodedCount: TBytes;
   begin
     if Length(Data) = 0 then
     begin
       SetLength(Result, 0);
       Exit;
     end;
     SetLength(Output, Length(Data) * 2);
     InputPos := 0;
     OutputPos := 0;
     DataLen := Length(Data);
     while InputPos < DataLen do
     begin // Tekrar sayısını bul
       Count := 1;
       CurrentByte := Data[InputPos];
       while (InputPos + Count < DataLen) and (Data[InputPos + Count] = CurrentByte) do
         System.Inc(Count);
       if Count > 1 then
       begin // RLE kaydı: [data_byte] [varint_count]
         if OutputPos + 1 >= Length(Output) then
           SetLength(Output, Length(Output) * 2);
         // Data byte
         Output[OutputPos] := CurrentByte;
         System.Inc(OutputPos);
         // VarInt count
         EncodedCount := VarIntEncode(Count);
         if OutputPos + Length(EncodedCount) >= Length(Output) then
           SetLength(Output, Length(Output) + Length(EncodedCount));
         Move(EncodedCount[0], Output[OutputPos], Length(EncodedCount));
         System.Inc(OutputPos, Length(EncodedCount));
         System.Inc(InputPos, Count);
       end
       else
       begin // Normal veri: [0x00] [data_byte]
         if OutputPos + 2 >= Length(Output) then
           SetLength(Output, Length(Output) * 2);
         Output[OutputPos] := $00; // Normal data marker
         Output[OutputPos + 1] := CurrentByte;
         System.Inc(OutputPos, 2);
         System.Inc(InputPos);
       end;
     end;
     SetLength(Result, OutputPos);
     if OutputPos > 0 then
       Move(Output[0], Result[0], OutputPos);
   end;

function RLEVarIntDecompress(const CompressedData: TBytes): TBytes;
var
  InputPos, OutputPos: Integer;
  CompressedLen: Integer;
  Output: TBytes;
  CurrentByte: Byte;
  Count: Cardinal;
begin
  if Length(CompressedData) = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  SetLength(Output, Length(CompressedData) * 4);
  InputPos := 0;
  OutputPos := 0;
  CompressedLen := Length(CompressedData);

  while InputPos < CompressedLen do
  begin
    CurrentByte := CompressedData[InputPos];
    System.Inc(InputPos);

    if CurrentByte = $00 then
    begin
      // Normal veri
      if InputPos < CompressedLen then
      begin
        if OutputPos >= Length(Output) then
          SetLength(Output, Length(Output) * 2);

        Output[OutputPos] := CompressedData[InputPos];
        System.Inc(OutputPos);
        System.Inc(InputPos);
      end;
    end
    else
    begin
      // RLE kaydı
      if InputPos < CompressedLen then
      begin
        // VarInt count'u decode et
        Count := VarIntDecode(CompressedData, InputPos);

        if OutputPos + Count >= Length(Output) then
          SetLength(Output, Length(Output) + Count * 2);

        while Count > 0 do
        begin
          Output[OutputPos] := CurrentByte;
          System.Inc(OutputPos);
          System.Dec(Count);
        end;
      end;
    end;
  end;

  SetLength(Result, OutputPos);
  if OutputPos > 0 then
    Move(Output[0], Result[0], OutputPos);
end;







Procedure TestRLEBit;
 const
      AFileName = 'D:\ZipAlgorithmTests\MyMedicine\_MyMedicines.exe';
//      AFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';
 var S, D : TMemoryStream;
     Compressed : integer;
     Def, Encoded, Decoded : TBytes;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(AFileName);
         DetectRLEMarker1(S.Memory, S.Size);
         DetectRLEMarker(S.Memory, S.Size);
         SetLength(Def, s.Size);
         Move(S.Memory^, Def[0], s.Size);
         Encoded := RLEVarIntCompress(Def);
         Compressed := Length(Encoded);
         Decoded := RLEVarIntDecompress(Encoded);
         if (length(Decoded) <> s.Size) or (CompareMem(S.Memory, @Decoded[0], S.Size) = false) then
           raise Exception.Create('RLE: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;
}

Procedure TestRLEStm;
 const
      AFileName = 'D:\ZipAlgorithmTests\enwik8\_enwik8.txt';
//      AFileName = 'D:\ZipAlgorithmTests\MyMedicine\_MyMedicines.exe';
//      AFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';
 var S, D : TMemoryStream;
     RLEMarker : byte;
     RLEGain, RealGain : NativeInt;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(AFileName);
         d.LoadFromFile(AFileName);
         RLEMarker := RLEEncode(D);
         RLEGain := CalculateRLEGain(S.Memory, S.Size, RLEMarker);
         RealGain := s.Size - d.Size;
         RLEDecode(D, RLEMarker);
         if (d.Size <> s.Size) or (CompareMem(S.Memory, D.Memory, S.Size) = false) then
           raise Exception.Create('RLE: Integrity check failed.');
         if (RLEGain <> RealGain) then
           raise Exception.Create('RLEGain: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;

Procedure TestRLEStmS;
 const
      AFileName = 'D:\ZipAlgorithmTests\MyMedicine\_MyMedicines.exe';
//      AFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';
 var S, D : TMemoryStream;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(AFileName);
         d.LoadFromFile(AFileName);
         RLEEncodeS(D);
         RLEDecodeS(D);
         if (d.Size <> s.Size) or (CompareMem(S.Memory, D.Memory, S.Size) = false) then
           raise Exception.Create('RLE: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;


{$IFDEF SELFTESTDEBUGMODE}
initialization
   TestRLEStm;
   TestRLEStmS;
{$ENDIF}
end.
