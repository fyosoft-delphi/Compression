{$I _fsInclude.inc}

unit fs.Generic.Coder.PP.CzBwt;

interface

uses System.Classes, System.Math, System.SysUtils;

//==============================================================================
//                 CZ-BWT (Chen-Zheng Burrows-Wheeler Transform)
// written by using cz-bwt algorithm given in article at :
//            https://www.hindawi.com/journals/js/2018/6908760/
// Converted from strings to array usage.
// A C-source code can be found at : https://github.com/taylandogan/cz-bwt
// Alternating journal link: https://onlinelibrary.wiley.com/doi/10.1155/2018/6908760
//==============================================================================
// 2025.01.26 Simple czBwt compression algorithm redesigned as descended of
//   TExtMemoryStream. First running copy
//     -Optimum BlockSize ise (according to article) 8-16-32 MB. My tests show
//   that 8 MB enough. increasing blocksize requires much more memory, but gain
//   stays minimal. In my experiments compression times and decompresion times
//   decreased a couple of seconds. After 16MB compression ratio sometimes
//   slightly decreased. Increasing blocksize doesn't change compression ratio's
//   of smaller files. Using czBwt instead of BWT in combining with real compression
//   algorithms, following gains and looses occured :
//     1. Most important gain seen in speed: approximately 29 secs with Bwt,
//        8 secs with czBwt. This gain makes the double/triple bwt usage possible.
//     2. On text files czBwt compression loss %2.
//     3. On binary exe file czBwt compression loss %0.5 But time gain is 24 sec. vs 98 secs.
// 2025.09.11 Redesigned as a procedure, to be able to use it as a function that
//   operating on single source stream (namely its Memory variable).
// 2025.10.31 Settings saving, block-based, stream-based encode and decode
//   functions added.
//     -Newly added stream-based functions self testing procedure added.
// 2025.10.31 StartIndex now saved into encoded stream by the algoritm itself.
//   Instead blocksize parameter added, which changes (improves) compression
//   ratio up to 2%. In text file, greater values (equal to file size) gives the
//   maximum ratio, whereas in exe file smaller block size improves compression
//   ratio. The spent time to encode & decode is not affected significantly.
//
// NB:
//   1- BlockSize < 0 has a special meaning that try to encode/decode whole file
//      as a single block.
//   2- BlockSize=0 has a special meaning that use default block size.
//   3- After checking special cases of 0 and negative, algorithm checks whether
//      current blocksize < Mininum or not, if so set BlockSize to minimum value.
//   4- After checkings special cases, and minimum lower bound, algorithm further
//      checks whether current blocksize > Max or not, if so set BlockSize to
//      default value not maximum value.
//   5- Default, Minimum and Maximum values defined in procedures implementation
//      as constants, if necessary change them so that they suits your needs.
//==============================================================================

procedure CzBwtEncode(Const ASource, ADestination: PByte; Const ASize: NativeInt; var AStartIndex:NativeInt); overload;
Procedure CzBwtDecode(Const ASource, ADestination: PByte; Const ASize, AStartIndex:NativeInt); overload;
procedure CzBwtEncode(ASource: PByte; Const ASize: NativeInt; var AStartIndex:NativeInt); overload;
Procedure CzBwtDecode(ASource: PByte; Const ASize, AStartIndex:NativeInt); overload;
procedure CzBwtEncode(ASourceStream : TMemoryStream; ABlockSize: Integer); overload;
procedure CzBwtDecode(ASourceStream : TMemoryStream); overload;

implementation

procedure CzBwtEncode(Const ASource, ADestination: PByte; Const ASize: NativeInt; var AStartIndex:NativeInt);
 Type
    TWord = packed record // 2 bytes
      case word of
        0 : ( x : word);
        2 : ( Lo, Hi : byte);
      end;
    TUInt32 = packed record
      case integer of
        0 : ( u : UInt32);
        3 : ( Lo, Hi : TWord);
      end;
 Const FBucketSize  = 256 * 256 * 256;
 var link, Bucket: TArray<Integer>;
     i, j, outpos : integer;
   begin
     SetLength(link, ASize); // no need to clear link, since following loop will initialize it.
     SetLength(bucket, FBucketSize);
     for i := 0 to High(bucket) do // FillChar(bucket[0], SizeOf(Integer) * FBucketSize, $FF);
       bucket[i] := -1; // $FF;
     AStartIndex := 0;
     for i := 0 to ASize - 1 do
     begin
       TUInt32(j).Hi.Hi := 0;  // Creating 24b integer. MSByte is zero since it is 24 bit not 32.
       if i >= 2 then
       begin
         TUInt32(j).Lo.Lo := ASource[i-2];
         TUInt32(j).Lo.Hi := ASource[i-1];
         TUInt32(j).Hi.Lo := ASource[i];
       end
       else if i = 0 then
       begin
         TUInt32(j).Lo.Lo := ASource[ASize-2];
         TUInt32(j).Lo.Hi := ASource[ASize-1];
         TUInt32(j).Hi.Lo := ASource[0];
       end
       else if i = 1 then
       begin
         TUInt32(j).Lo.Lo := ASource[ASize-1];
         TUInt32(j).Lo.Hi := ASource[0];
         TUInt32(j).Hi.Lo := ASource[1];
       end;
       link[i] := bucket[j];
       bucket[j] := i;
     end;
     outpos := 0; // Phase 2: Output data also traces the start position of the block
     for j := 0 to FBucketSize - 1 do
     begin
       i := bucket[j];
       while i <> -1 do
       begin  // output a character of s
         var index := (ASize + (i+1) mod ASize) mod ASize;
         ADestination[outpos] := ASource[index];
         if i = (ASize - 1) then  // start stores the start position
           AStartIndex := OutPos;
         i := link[i];
         inc(outpos);
       end;
     end;
     SetLength(link, 0);
     SetLength(bucket, 0);
   end;

Procedure CzBwtDecode(Const ASource, ADestination: PByte; Const ASize, AStartIndex:NativeInt);
 Const FBucketASize = 256 * 256 * 256;
       FBucketBSize = 256 * 256;
 var link, Bucket_A, Bucket_B: TArray<Integer>;
     i, j, p, m: Integer;
   begin
     SetLength(link, ASize); // no need to clear link, since following loop will initialize it.
     SetLength(bucket_A, FBucketASize);
     SetLength(bucket_B, FBucketBSize);

     for i := 0 to High(bucket_A) do // for j = 0…256^3–1 do {bucket_A[j] = 0;} /∗ Initialize the data counters ∗/
       bucket_A[i] := 0;
     for i := 0 to High(bucket_B) do // for j = 0…256^2–1 do {bucket_B[j] = 0;} /∗ Initialize the data counters ∗/
       bucket_B[i] := 0;
     for i := 0 to ASize - 1 do  // for i = 0 … N − 1 do {j = s[i]; link[i] = j; bucket_A[j] = bucket_A[j] +1;} /∗ Phase 1: count Column 0 ∗/
     begin
       j := ASource[i];
       link[i] := j;
       Inc(bucket_A[j]);
     end;
     p := 0;  // p traces the current position of link
     for i := 0 to 255 do   // Initialize the data counters
     begin
       j := bucket_A[i]; //  Initialize the data counters
       bucket_A[i] := 0; // Initialize the data counters
       while j > 0 do
       begin
         m := (link[p] shl 8) or i; // m stores Column [0,7]
//         m := m and $FFFFFF;  // ? try to correct j out of bounds error
         link[p] := m and $FFFFFF;     // Phase 1: sort Column 7
         Inc(p);
         Inc(bucket_B[m]); // Phase 2: count Column [0,7]
         Dec(j);
       end;
     end;
     p := 0; // reset p
     for i := 0 to FBucketBSize - 1 do
     begin
       j := bucket_B[i];
       while j > 0 do
       begin
         m := (link[p] shl 8) or i; // m stores Column [0,7,6]
//         m := m and $FFFFFF;  // ? try to correct j out of bounds error
         link[p] := m and $FFFFFF;        // Phase 2: sort column 6
         Inc(p);
         Inc(bucket_A[m]);    // Phase 3: count column [0,7,6]
         Dec(j);
       end;
     end;
// Phase 4: calculate link headers
     m := 0; // m traces the link headers
     for i := 0 to FBucketASize - 1 do
     begin
       m := m + bucket_A[i]; 	// bucket_A stores the link headers of (7)
       bucket_A[i] := m;
     end;
//     p := 0;  // reset p
     j := AStartIndex;  // j traces the position
     for i := 0 to ASize - 1  do  // Phase 4: output decoded data
     begin
       Assert((j >= 0) and (j <= ASize-1), Format('j=%u must be in [%u,%u]. (si:%u, p:%u, BS:%u)', [j, 0, ASize-1, AStartIndex, p, ASize]));
       p := link[j]; // link keeps Column [0,7,6] after phase 2
       ADestination[i] := Byte((p shr 16) and $FF);  // s stores the decoded block string in Column 0
       j := bucket_A[p] - 1;  // seek the next position j with Column [0,7,6]: fetch & decrease
       bucket_A[p] := j;  // update the current link header of (8)
     end;
     SetLength(link, 0);
     SetLength(bucket_A, 0);
     SetLength(bucket_B, 0);
   end;

procedure CzBwtEncode(ASource: PByte; Const ASize: NativeInt; var AStartIndex:NativeInt);
 var Destination : TArray<Byte>;
     ADest : PByte;
   begin
     SetLength(Destination, ASize);
     ADest := @Destination[0];
     CzBwtEncode(ASource, ADest, ASize, AStartIndex);
     if AStartIndex >= 0 then
       Move(ADest^, ASource^, ASize);
   end;

Procedure CzBwtDecode(ASource: PByte; Const ASize, AStartIndex:NativeInt);
 var Destination : TArray<Byte>;
     ADest : PByte;
   begin
     if AStartIndex >= 0 then
     begin
       SetLength(Destination, ASize);
       ADest := @Destination[0];
       CzBwtDecode(ASource, ADest, ASize, AStartIndex);
       Move(ADest^, ASource^, ASize);
     end;
   end;


Type
    TczBwtBlockInfo = packed record
      BlockSize   : Cardinal;
      StartIndex  : integer;
    end;

procedure CzBwtEncode(ASourceStream: TMemoryStream; ABlockSize: Integer);
 const czBWT_MAX_BLOCKSIZE = 1 * 1024 * 1024 * 1024; // 1GB - practical upper bound
       czBWT_MIN_BLOCKSIZE = 8 * 1024; // 8KB - practical lower bound
       czBWT_DEF_BLOCKSIZE = 8 * 1024 * 1024; // 8MB - practical default blocksize
       czBWT_TREAT_SINGLE_BLOCK = -1;
       czBWT_USE_DEF_BLOCKSIZE = 0;
 var ADestStream: TMemoryStream;
     BlockDataPtr, SourceBuffer, DestBuffer: PByte;
     StartIndexNative, SourceDataSize, DestDataSize: NativeInt;
     BlockCount: Cardinal;
     ABlockInfo: TczBwtBlockInfo;
     BlockIndex: Integer;
   begin
     SourceDataSize := ASourceStream.Size;
//     if (ABlockSize <= 8 * 1024) or (ABlockSize > High(Int32) div 2) then  // min 8KB, max 1 gb blocksize
//       ABlockSize := 8 * 1024 * 1024; // 8MB default blocksize
     if ABlockSize < 0 then  //  czBWT_TREAT_SINGLE_BLOCK
       ABlockSize := SourceDataSize;
     if ABlockSize = czBWT_USE_DEF_BLOCKSIZE then
       ABlockSize := czBWT_DEF_BLOCKSIZE;
     if (ABlockSize <= czBWT_MIN_BLOCKSIZE) then
       ABlockSize := czBWT_MIN_BLOCKSIZE; // 8KB minimum default blocksize
     if (ABlockSize > czBWT_MAX_BLOCKSIZE) then  // min 8KB, max 1 gb blocksize
       ABlockSize := czBWT_DEF_BLOCKSIZE; // 16MB default blocksize
     ASourceStream.Position := 0;
     BlockCount := (SourceDataSize + ABlockSize - 1) div ABlockSize;
     DestDataSize := SourceDataSize + SizeOf(SourceDataSize) + SizeOf(BlockCount) +
                     BlockCount * SizeOf(TczBwtBlockInfo) + 2048;  // 2K spare space
     ADestStream := TMemoryStream.Create;
     try
       ADestStream.Size := DestDataSize;
       SourceBuffer := ASourceStream.Memory;
       DestBuffer := ADestStream.Memory;
       // Save header : Save original data size + Number of Blocks
       Move(SourceDataSize, DestBuffer^, SizeOf(SourceDataSize));  // Save original data size
       System.Inc(DestBuffer, SizeOf(SourceDataSize));
       Move(BlockCount, DestBuffer^, SizeOf(BlockCount)); // Save block count
       System.Inc(DestBuffer, SizeOf(BlockCount));
       // Save block info table
       BlockDataPtr := DestBuffer;  // reserve space for entire blockinfo table
       System.Inc(DestBuffer, BlockCount * SizeOf(TczBwtBlockInfo));
       FillChar(ABlockInfo, SizeOf(ABlockInfo), 0);
       for BlockIndex := 0 to BlockCount - 1 do // process blocks
       begin
         ABlockInfo.BlockSize := System.Math.Min(Cardinal(ABlockSize), Cardinal(SourceDataSize));
         if ABlockInfo.BlockSize = 0 then
           Break;
         ABlockInfo.StartIndex := -1; // Invalid marker means failed encoding
         // Try to encode, Need to use NativeInt for the algorithm
         StartIndexNative := -1;
         CzBwtEncode(SourceBuffer, DestBuffer, ABlockInfo.BlockSize, StartIndexNative);
         // Check if encoding was successful
         if (StartIndexNative >= 0) and (StartIndexNative < ABlockInfo.BlockSize) then // successful encoding
           ABlockInfo.StartIndex := integer(StartIndexNative)  // typecast StartIndex for proper saving
         else // encoding is not successful so save the original data block
           Move(SourceBuffer^, DestBuffer^, ABlockInfo.BlockSize);
         // Save block info
         Move(ABlockInfo, BlockDataPtr^, SizeOf(TczBwtBlockInfo));
         System.Inc(BlockDataPtr, SizeOf(TczBwtBlockInfo));
         // update pointers and data left
         System.Inc(SourceBuffer, ABlockInfo.BlockSize);
         System.Inc(DestBuffer, ABlockInfo.BlockSize);
         Dec(SourceDataSize, ABlockInfo.BlockSize);
       end;
       // Finalize
       ADestStream.Size := NativeUInt(DestBuffer) - NativeUInt(ADestStream.Memory);
       ASourceStream.Size := ADestStream.Size;
       Move(ADestStream.Memory^, ASourceStream.Memory^, ADestStream.Size);
     finally
       ADestStream.Free;
     end;
   end;

procedure CzBwtDecode(ASourceStream: TMemoryStream);
 var ADestStream: TMemoryStream;
     SourceBuffer, DestBuffer, BlockInfoPtr: PByte;
     SourceDataSize: NativeUInt;
     BlockCount, i: Cardinal;
     ABlockInfo: TczBwtBlockInfo;
   begin
     ASourceStream.Position := 0;
     SourceBuffer := ASourceStream.Memory;
     // Read header
     Move(SourceBuffer^, SourceDataSize, SizeOf(SourceDataSize));  // read original data size
     System.Inc(SourceBuffer, SizeOf(SourceDataSize));
     Move(SourceBuffer^, BlockCount, SizeOf(BlockCount));  // rean number of blocks
     System.Inc(SourceBuffer, SizeOf(BlockCount));
     BlockInfoPtr := SourceBuffer;   // Get a pointer to BlockInfo table
     System.Inc(SourceBuffer, BlockCount * SizeOf(TczBwtBlockInfo));
     ADestStream := TMemoryStream.Create;
     try
       ADestStream.Size := SourceDataSize;
       DestBuffer := ADestStream.Memory;
       for i := 0 to BlockCount - 1 do
       begin
         Move(BlockInfoPtr^, ABlockInfo, SizeOf(TczBwtBlockInfo)); // Get current BlockInfo from BlockInfo table
         System.Inc(BlockInfoPtr, SizeOf(TczBwtBlockInfo));
         if ABlockInfo.StartIndex = -1 then  // block is not encoded i.e. Raw block - copy as is
           Move(SourceBuffer^, DestBuffer^, ABlockInfo.BlockSize)
         else // Encoded block - decode
           CzBwtDecode(SourceBuffer, DestBuffer, ABlockInfo.BlockSize, ABlockInfo.StartIndex);
         System.Inc(SourceBuffer, ABlockInfo.BlockSize);
         System.Inc(DestBuffer, ABlockInfo.BlockSize);
       end;
       // Finalize
       ASourceStream.Size := SourceDataSize;
       Move(ADestStream.Memory^, ASourceStream.Memory^, SourceDataSize);
     finally
       ADestStream.Free;
     end;
   end;



{
// Algorithm 1: (CZ-BWT encoding (k = 3))
function encode(s) //* s is the BWT block data string (original data)  */
  link = array(0 … N − 1);    //  N is the length of string s  ∗/
  bucket = array(0 … 256^3–1);  // bucket stores the link headers of (3)  ∗/
  for j = 0…256^3–1 do        // Initialize the link headers  ∗/
     bucket[j] = null;  
  for i = 0 … N − 1 do        // Phase 1: build links of (4)  
     j = s[i − 2 … i]; 
     link[i] = bucket[j]; 
     bucket[j] = i; 
  count = 0;  // count traces the start position of the block  ∗/
  for j = 0 … 256^3–1 do // Phase 2: output data  ∗/
    i = bucket[j];
    while i is not null do
       output(s[i + 1]); 
       i = link[i]; 
       count = count+ 1;  
       if i = N − 1 do  // ∗ start stores the start position  ∗/
          start = count; 
  output(start);  // finally output the start position  ∗/


// Algorithm 2: (CZ-BWT decoding (k = 3)).
function decode(s) // s is the BWT block data string (BWT encoded data)  ∗/
  link = array(0 … N − 1);  // link stores the Column [0,7,6,5] of the decoding matrix. N is the length of string s.  ∗/
  bucket_A = array(0 … 256^3–1);  // bucket_A stores the data counters  ∗/
  for j = 0 … 256^3–1 do   // Initialize the data counters  ∗/
      bucket_A[j] = 0;
  bucket_B = array(0 … 256^2–1);  // bucket_B stores the data counters  ∗/
  for j = 0 … 256^2–1 do   // Initialize the data counters  ∗/
      bucket_B[j] = 0;
  for i = 0 … N − 1 do   // Phase 1: count Column 0  ∗/
      j = s[i]; 
      link[i] = j; 
      bucket_A[j] = bucket_A[j] + 1;
  p = 0;  // p traces the current position of link  ∗/
  for i = 0 … 256–1 do
      j = bucket_A[i];   // Initialize the data counters  ∗/
      bucket_A[i] = 0;
      while j > 0 do
         m = (link[p] < <8) | i;  // m stores Column [0,7]  ∗/
         link[p] = m; p = p + 1;  // Phase 1: sort Column 7  ∗/
         bucket_B[m] = bucket_B[m] + 1; j = j − 1;  // Phase 2: count Column [0,7]  ∗/
  p = 0;  // reset p  ∗/
  for i = 0 … 256^2–1 do
      j = bucket_B[i];
      while j > 0 do
         m = (link[p] < <8) | i;  // m stores Column [0,7,6]  ∗/
         link[p] = m; p = p + 1;  // Phase 2: sort Column 6  ∗/
         bucket_A[m] = bucket_A[m] +1; j = j − 1;  // Phase 3: count Column [0,7,6]  ∗/
  p = 0;  // reset p  ∗/
  m = 0;  // m traces the link headers  ∗/
  for i = 0 … 256^3–1 do   // Phase 4: calculate link headers  ∗/
      m = m + bucket_A[i]; bucket_A[i] = m;  // bucket_A stores the link headers of (7)  ∗/
  input(start);  // input the start position of the block  ∗/
  j = start;  // j traces the position  ∗/
  for i = 0 … N − 1 do // Phase 4: output decoded data  ∗/
      p = link[j];  // link keeps Column [0,7,6] after phase 2  ∗/
      s[i] = (p > > 16) & 255;  // s stores the decoded block string in Column 0  ∗/
      j = bucket_A[p] − 1;  // seek the next position j with Column [0,7,6]: fetch & decrease  ∗/
      bucket_A[p] = j;  // update the current link header of (8)  ∗/
  output(s[0 … N − 1]);  // finally output the block string  ∗/
}


//==============================================================================
//                                 Self Test Routines
//==============================================================================
Procedure TestCzBwtStm;
 const TestFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix.pas';
       EncodedFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-czBwtz.pas';
       DecodedFileName = 'D:\ZipAlgorithmTests\fsLhSix\_fsLhSix-czBwt.pas';
 var S, D : TMemoryStream;
   begin
     s := TMemoryStream.Create;
     try
       d := TMemoryStream.Create;
       try
         s.LoadFromFile(TestFileName);
         d.LoadFromFile(TestFileName);
         s.Position := 0;
         d.Position := 0;
         czBwtEncode(s, 16*1024);  // 16K
         s.SaveToFile(EncodedFileName);
         czBwtDecode(s);
         s.SaveToFile(DecodedFileName);
         if (d.Size <> s.Size) or (CompareMem(S.Memory, d.Memory, S.Size) = false) then
           raise Exception.Create('czBwt: Stream mode integrity check failed.');
       finally
         d.Free;
       end;
     finally
       s.Free;
     end;
   end;

{$IFDEF SELFTESTDEBUGMODE}
initialization
  TestCzBwtStm;
{$ENDIF}
end.
