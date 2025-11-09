{$I _fsInclude.inc}

unit fs.Generic.Coder.PP.GrzLzp;

interface

uses System.SysUtils, System.Classes;

type
    TGRZipResult = NativeInt;

const
     GRZ_NOT_ENOUGH_MEMORY = -1;
     GRZ_NOT_COMPRESSIBLE = -2;

//==============================================================================
//           GrzLzpEncode & GrxLzpDecode preprocessing functions
// Extracted and converted from original C source code taken from the link :
// https://web.archive.org/web/20070819095130/http://magicssoft.ru/content/download/GRZipII/GRZipIISRC.zip
// 2025.10.05 First running copy.
//     -Mode parameter seperated and passed newly defined overloaded functions.
//     -Newly created parameters added to self stream Encoder & Decoder.
// 2025.10.19 Seetings saver GrzLzpEncodeS & GrzLzpDecodeS functions and related
//   selftest procedure are added.
// 2025.10.24 Stream based encoding procedure converted to functions. Returning
//   false as a result means source is not compressible and just left as is.
//==============================================================================

function GRZip_LzpEncode(Input: PByte; Size: Cardinal; Output: PByte; Mode: Byte): TGRZipResult;
function GRZip_LzpDecode(Input: PByte; Size: Cardinal; Output: PByte; Mode: Byte): TGRZipResult;

function GrzLzpEncode(Input: PByte; Size: Cardinal; Output: PByte; HashBitSize: byte; MinMatchLen: Byte): TGRZipResult; overload;
function GrzLzpDecode(Input: PByte; Size: Cardinal; Output: PByte; HashBitSize: byte; MinMatchLen: Byte): TGRZipResult; overload;

Function GrzLzpEncode(ASource : TMemoryStream; HashBitSize: byte; MinMatchLen: Byte) : boolean; overload;
Procedure GrzLzpDecode(ASource : TMemoryStream; OriSize : Cardinal; HashBitSize: byte; MinMatchLen: Byte); overload;

Function GrzLzpEncodeS(ASource : TMemoryStream; HashBitSize: byte; MinMatchLen: Byte) : boolean;
Procedure GrzLzpDecodeS(ASource : TMemoryStream);


implementation

const
     LZP_MatchFlag = $F2;
     LZP_RunFlag   = $F3;
     LZP_XorFlag   = Byte(not LZP_RunFlag);


function GrzLzpEncode(Input: PByte; Size: Cardinal; Output: PByte; HashBitSize: byte; MinMatchLen: Byte): TGRZipResult;
 var LZP_HT_Size, LZP_MinMatchLen: Cardinal;
     Contexts: array of PByte;
     InputEnd, OutputEnd: PByte;
     Ctx, HashIndex, CommonLength: Cardinal;
     LastPtr, Ptr: PByte;
     Ch: Byte;
   begin
     if HashBitSize <= 9 then   // calculate hash table size
       HashBitSize := 10;
     LZP_HT_Size := (1 shl HashBitSize) - 1;
     LZP_MinMatchLen := MinMatchLen;
     SetLength(Contexts, LZP_HT_Size + 1);  // Prepare Hash table
     for var i := 0 to LZP_HT_Size do
       Contexts[i] := nil;
     try
       InputEnd := Input + Size;
       OutputEnd := Output + Size - 1;
       PCardinal(Output)^ := PCardinal(Input)^;  // copy first 4 byte
       // initialize Context (big-endian)
       Ctx := (Input[3] + (Input[2] shl 8) + (Input[1] shl 16) + (Input[0] shl 24));
       Inc(Input, 4);
       Inc(Output, 4);
       while (Input < InputEnd) and (Output < OutputEnd) do
       begin
         // Hash index hesapla
         HashIndex := ((Ctx shr 15) xor Ctx xor (Ctx shr 3)) and LZP_HT_Size;
         LastPtr := Contexts[HashIndex];
         Contexts[HashIndex] := Input;
         if LastPtr <> nil then
         begin  // find match length
           CommonLength := 0;
           Ptr := Input;
           while (Ptr < InputEnd) do
           begin
             if Ptr^ <> LastPtr^ then
               Break;
             Inc(Ptr);
             Inc(LastPtr);
             Inc(CommonLength);
           end;
           if CommonLength < LZP_MinMatchLen then
             CommonLength := 0;
           if CommonLength > 0 then
           begin // MAtch found : encode it
             Inc(Input, CommonLength);
             Ctx := (Input[-1] + (Input[-2] shl 8) + (Input[-3] shl 16) + (Input[-4] shl 24));
             CommonLength := CommonLength - LZP_MinMatchLen + 1;
             Output^ := LZP_MatchFlag;
             Inc(Output);
             // Run-length encoding
             while CommonLength > 254 do
             begin
               Output^ := LZP_RunFlag;
               Inc(Output);
               if Output >= OutputEnd then
               begin
                 Result := GRZ_NOT_COMPRESSIBLE;
                 Exit;
               end;
               Dec(CommonLength, 255);
             end;
             Output^ := Byte(CommonLength xor LZP_XorFlag);
             Inc(Output);
           end
           else
           begin // Literal byte
             Ch := Input^;
             Output^ := Ch;
             Inc(Output);
             Inc(Input);
             Ctx := (Ctx shl 8) or Ch;
             if Ch = LZP_MatchFlag then   // Escape LZP_MatchFlag char
             begin
               Output^ := LZP_XorFlag;
               Inc(Output);
             end;
           end;
         end
         else
         begin  // no match in Hash table - literal
           Output^ := Input^;
           Ctx := (Ctx shl 8) or Input^;
           Inc(Output);
           Inc(Input);
         end;
       end;
       if Output >= OutputEnd then
         Result := GRZ_NOT_COMPRESSIBLE
       else Result := Output + Size - OutputEnd - 1;
     finally
       SetLength(Contexts, 0);
     end;
   end;

function GrzLzpDecode(Input: PByte; Size: Cardinal; Output: PByte; HashBitSize: byte; MinMatchLen: Byte): TGRZipResult;
 var LZP_HT_Size, LZP_MinMatchLen: Cardinal;
     Contexts: array of PByte;
     InputEnd, OutputBeg: PByte;
     Ctx, HashIndex, CommonLength: Cardinal;
     LastPtr: PByte;
   begin
     if HashBitSize <= 9 then   // calculate hash table size
       HashBitSize := 10;
     LZP_HT_Size := (1 shl HashBitSize) - 1;
     LZP_MinMatchLen := MinMatchLen;
     SetLength(Contexts, LZP_HT_Size + 1);  // Prepare Hash table
     for var i := 0 to LZP_HT_Size do
       Contexts[i] := nil;
     try
       InputEnd := Input + Size;
       OutputBeg := Output;
       PCardinal(Output)^ := PCardinal(Input)^;
       // Context'i ilkle
       Ctx := (Input[3] + (Input[2] shl 8) + (Input[1] shl 16) + (Input[0] shl 24));
       Inc(Input, 4);
       Inc(Output, 4);
       while Input < InputEnd do
       begin
         HashIndex := ((Ctx shr 15) xor Ctx xor (Ctx shr 3)) and LZP_HT_Size;
         LastPtr := Contexts[HashIndex];
         Contexts[HashIndex] := Output;
         if LastPtr <> nil then
         begin
           if Input^ <> LZP_MatchFlag then
           begin // Literal byte
             Ctx := (Ctx shl 8) or Input^;
             Output^ := Input^;
             Inc(Output);
             Inc(Input);
           end
           else
           begin // decode a match
             Inc(Input);
             CommonLength := 0;
             while Input^ = LZP_RunFlag do  // Run-length decoding
             begin
               Inc(CommonLength, Input^ xor LZP_XorFlag);
               Inc(Input);
             end;
             Inc(CommonLength, Input^ xor LZP_XorFlag);
             Inc(Input);
             if CommonLength > 0 then
             begin
               CommonLength := CommonLength + LZP_MinMatchLen - 1;
               for var i := 1 to CommonLength do // Byte'larý kopyala
               begin
                 Output^ := LastPtr^;
                 Inc(Output);
                 Inc(LastPtr);
               end;
               Ctx := (Output[-1] + (Output[-2] shl 8) + (Output[-3] shl 16) + (Output[-4] shl 24));
             end
             else
             begin // Single LZP_MatchFlag char
               Ctx := (Ctx shl 8) or LZP_MatchFlag;
               Output^ := LZP_MatchFlag;
               Inc(Output);
             end;
           end;
         end
         else
         begin // Literal byte
           Ctx := (Ctx shl 8) or Input^;
           Output^ := Input^;
           Inc(Output);
           Inc(Input);
         end;
       end;
       Result := Output - OutputBeg;
     finally
       SetLength(Contexts, 0);
     end;
   end;

function GRZip_LzpEncode(Input: PByte; Size: Cardinal; Output: PByte; Mode: Byte): TGRZipResult;
   begin
     result := GrzLzpEncode(Input, Size, Output, 3 + (Mode and $F), 2 + 3 * (Mode shr 4));
   end;

function GRZip_LzpDecode(Input: PByte; Size: Cardinal; Output: PByte; Mode: Byte): TGRZipResult;
   begin
     result := GrzLzpDecode(Input, Size, Output, 3 + (Mode and $F), 2 + 3 * (Mode shr 4));
   end;

Function GrzLzpEncode(ASource : TMemoryStream; HashBitSize: byte; MinMatchLen: Byte) : boolean;
 var Temp : TMemoryStream;
     NewSize : NativeInt;
   begin
     Temp := TMemoryStream.Create;
     try
       Temp.Size := ASource.Size;
       NewSize := GrzLzpEncode(ASource.Memory, ASource.Size, Temp.Memory, HashBitSize, MinMatchLen);
       if NewSize > 0 then
       begin
         Result := true;
         Temp.Size := NewSize;
         ASource.Size := Temp.Size;
         Move(Temp.Memory^, ASource.Memory^, ASource.Size);
       end
       else Result := false;
     finally
       Temp.Free;
     end;
   end;

Procedure GrzLzpDecode(ASource : TMemoryStream; OriSize : Cardinal; HashBitSize: byte; MinMatchLen: Byte);
 var Temp : TMemoryStream;
   begin
     Temp := TMemoryStream.Create;
     try
       Temp.Size := OriSize;
       Temp.Size := GrzLzpDecode(ASource.Memory, ASource.Size, Temp.Memory, HashBitSize, MinMatchLen);
       ASource.Size := Temp.Size;
       Move(Temp.Memory^, ASource.Memory^, ASource.Size);
     finally
       Temp.Free;
     end;
   end;

Function GrzLzpEncodeS(ASource : TMemoryStream; HashBitSize: byte; MinMatchLen: Byte) : boolean;
 var Temp : TMemoryStream;
     ANewSize : NativeInt;
     AOriginalSize : Cardinal; // NativeInt;
   begin
     Temp := TMemoryStream.Create;
     try
       Temp.Size := ASource.Size + 512; //  round(ASource.Size * 1.2) + 4096;
       ANewSize := GrzLzpEncode(ASource.Memory, ASource.Size, Temp.Memory, HashBitSize, MinMatchLen);
       if (ANewSize > 0) and (ANewSize < ASource.Size) then
       begin
         Temp.Size := ANewSize;
         AOriginalSize := ASource.Size;
         ASource.Position := 0;
         ASource.Write(AOriginalSize, sizeof(AOriginalSize));
         ASource.Write(HashBitSize, sizeof(HashBitSize));
         ASource.Write(MinMatchLen, sizeof(MinMatchLen));
         ASource.Size := Temp.Size + ASource.Position;
         Move(Temp.Memory^, (PByte(ASource.Memory) + ASource.Position)^, Temp.Size);
         ASource.Position := 0; // restore position after write operations
         Result := true;
       end
       else Result := false;
     finally
       Temp.Free;
     end;
   end;

Procedure GrzLzpDecodeS(ASource : TMemoryStream);
 var Temp : TMemoryStream;
     AOriginalSize : Cardinal; // NativeInt;
     HashBitSize, MinMatchLen : byte;
   begin
     Temp := TMemoryStream.Create;
     try
       ASource.Position := 0;
       ASource.Read(AOriginalSize, sizeof(AOriginalSize));
       ASource.Read(HashBitSize, sizeof(HashBitSize));
       ASource.Read(MinMatchLen, sizeof(MinMatchLen));
       Temp.Size := AOriginalSize;
       Temp.Size := GrzLzpDecode(PByte(ASource.Memory)+ASource.Position, ASource.Size-ASource.Position, Temp.Memory, HashBitSize, MinMatchLen);
       ASource.Size := Temp.Size;
       Move(Temp.Memory^, ASource.Memory^, ASource.Size);
       ASource.Position := 0; // restore position after read operations
     finally
       Temp.Free;
     end;
   end;


Const
     TestFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';

Procedure TestLzpStmS;
 var S, D : TMemoryStream;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(TestFileName);
         GrzLzpEncodeS(S, 19, 3);
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-Grzlzp_z.pas');
         GrzLzpDecodeS(S);
         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-Grzlzp.pas');
         d.Size := 0;
         d.LoadFromFile(TestFileName);
         if (d.Size <> s.Size) or (CompareMem(S.Memory, d.Memory, S.Size) = false) then
           raise Exception.Create('GrzLzpStmS: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;

Procedure TestLzpPtr;
 var S, D : TMemoryStream;
     Mode : byte;
   begin
     Mode := 13;
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(TestFileName);
         d.Size := S.Size;
         d.Size := GRZip_LzpEncode(s.Memory, S.Size, D.Memory, Mode);
         s.Size := GRZip_LzpDecode(D.Memory, D.Size, S.Memory, Mode);
//         s.SaveToFile('D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-lzpbit.pas');
         d.Size := 0;
         d.LoadFromFile(TestFileName);
         if (d.Size <> s.Size) or (CompareMem(S.Memory, d.Memory, S.Size) = false) then
           raise Exception.Create('GrzLzpPtr: Integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;

{$IFDEF SELFTESTDEBUGMODE}
initialization
   TestLzpStmS;
   TestLzpPtr;
{$ENDIF}
end.
