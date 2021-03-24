(*

Offset  Size  Name             Description

The canonical WAVE format starts with the RIFF header:

0         4   ChunkID          Contains the letters "RIFF" in ASCII form
                               (0x52494646 big-endian form).
4         4   ChunkSize        36 + SubChunk2Size, or more precisely:
                               4 + (8 + SubChunk1Size) + (8 + SubChunk2Size)
                               This is the size of the rest of the chunk
                               following this number.  This is the size of the
                               entire file in bytes minus 8 bytes for the
                               two fields not included in this count:
                               ChunkID and ChunkSize.
8         4   Format           Contains the letters "WAVE"
                               (0x57415645 big-endian form).

The "WAVE" format consists of two subchunks: "fmt " and "data":
The "fmt " subchunk describes the sound data's format:

12        4   Subchunk1ID      Contains the letters "fmt "
                               (0x666d7420 big-endian form).
16        4   Subchunk1Size    16 for PCM.  This is the size of the
                               rest of the Subchunk which follows this number.
20        2   AudioFormat      PCM = 1 (i.e. Linear quantization)
                               Values other than 1 indicate some
                               form of compression.
22        2   NumChannels      Mono = 1, Stereo = 2, etc.
24        4   SampleRate       8000, 44100, etc.
28        4   ByteRate         == SampleRate * NumChannels * BitsPerSample/8
32        2   BlockAlign       == NumChannels * BitsPerSample/8
                               The number of bytes for one sample including
                               all channels. I wonder what happens when
                               this number isn't an integer?
34        2   BitsPerSample    8 bits = 8, 16 bits = 16, etc.
          2   ExtraParamSize   if PCM, then doesn't exist
          X   ExtraParams      space for extra parameters

The "data" subchunk contains the size of the data and the actual sound:

36        4   Subchunk2ID      Contains the letters "data"
                               (0x64617461 big-endian form).
40        4   Subchunk2Size    == NumSamples * NumChannels * BitsPerSample/8
                               This is the number of bytes in the data.
                               You can also think of this as the size
                               of the read of the subchunk following this
                               number.
44        *   Data             The actual sound data.


*)

unit audio.wave.reader;

interface
uses
  System.Classes, System.SysUtils,
  System.Generics.Collections;

type
  TCompressionCode = (
    WAVE_FORMAT_UNKNOWN = $0000, (* Microsoft Corporation *)
    WAVE_FORMAT_PCM = $0001, (* Microsoft Corporation *)
    WAVE_FORMAT_ADPCM = $0002, (* Microsoft Corporation *)
    WAVE_FORMAT_IEEE_FLOAT = $0003, (* Microsoft Corporation *)
    WAVE_FORMAT_VSELP = $0004, (* Compaq Computer Corp. *)
    WAVE_FORMAT_IBM_CVSD = $0005, (* IBM Corporation *)
    WAVE_FORMAT_ALAW = $0006, (* Microsoft Corporation *)
    WAVE_FORMAT_MULAW = $0007, (* Microsoft Corporation *)
    WAVE_FORMAT_DTS = $0008, (* Microsoft Corporation *)
    WAVE_FORMAT_DRM = $0009, (* Microsoft Corporation *)
    WAVE_FORMAT_OKI_ADPCM = $0010, (* OKI *)
    WAVE_FORMAT_DVI_ADPCM = $0011, (* Intel Corporation *)
    WAVE_FORMAT_IMA_ADPCM = (WAVE_FORMAT_DVI_ADPCM), (* Intel Corporation *)
    WAVE_FORMAT_MEDIASPACE_ADPCM = $0012, (* Videologic *)
    WAVE_FORMAT_SIERRA_ADPCM = $0013, (* Sierra Semiconductor Corp *)
    WAVE_FORMAT_G723_ADPCM = $0014, (* Antex Electronics Corporation *)
    WAVE_FORMAT_DIGISTD = $0015, (* DSP Solutions, Inc. *)
    WAVE_FORMAT_DIGIFIX = $0016, (* DSP Solutions, Inc. *)
    WAVE_FORMAT_DIALOGIC_OKI_ADPCM = $0017, (* Dialogic Corporation *)
    WAVE_FORMAT_MEDIAVISION_ADPCM = $0018, (* Media Vision, Inc. *)
    WAVE_FORMAT_CU_CODEC = $0019, (* Hewlett-Packard Company *)
    WAVE_FORMAT_YAMAHA_ADPCM = $0020, (* Yamaha Corporation of America *)
    WAVE_FORMAT_SONARC = $0021, (* Speech Compression *)
    WAVE_FORMAT_DSPGROUP_TRUESPEECH = $0022, (* DSP Group, Inc *)
    WAVE_FORMAT_ECHOSC1 = $0023, (* Echo Speech Corporation *)
    WAVE_FORMAT_AUDIOFILE_AF36 = $0024, (* Virtual Music, Inc. *)
    WAVE_FORMAT_APTX = $0025, (* Audio Processing Technology *)
    WAVE_FORMAT_AUDIOFILE_AF10 = $0026, (* Virtual Music, Inc. *)
    WAVE_FORMAT_PROSODY_1612 = $0027, (* Aculab plc *)
    WAVE_FORMAT_LRC = $0028, (* Merging Technologies S.A. *)
    WAVE_FORMAT_DOLBY_AC2 = $0030, (* Dolby Laboratories *)
    WAVE_FORMAT_GSM610 = $0031, (* Microsoft Corporation *)
    WAVE_FORMAT_MSNAUDIO = $0032, (* Microsoft Corporation *)
    WAVE_FORMAT_ANTEX_ADPCME = $0033, (* Antex Electronics Corporation *)
    WAVE_FORMAT_CONTROL_RES_VQLPC = $0034, (* Control Resources Limited *)
    WAVE_FORMAT_DIGIREAL = $0035, (* DSP Solutions, Inc. *)
    WAVE_FORMAT_DIGIADPCM = $0036, (* DSP Solutions, Inc. *)
    WAVE_FORMAT_CONTROL_RES_CR10 = $0037, (* Control Resources Limited *)
    WAVE_FORMAT_NMS_VBXADPCM = $0038, (* Natural MicroSystems *)
    WAVE_FORMAT_CS_IMAADPCM = $0039, (* Crystal Semiconductor IMA ADPCM *)
    WAVE_FORMAT_ECHOSC3 = $003A, (* Echo Speech Corporation *)
    WAVE_FORMAT_ROCKWELL_ADPCM = $003B, (* Rockwell International *)
    WAVE_FORMAT_ROCKWELL_DIGITALK = $003C, (* Rockwell International *)
    WAVE_FORMAT_XEBEC = $003D, (* Xebec Multimedia Solutions Limited *)
    WAVE_FORMAT_G721_ADPCM = $0040, (* Antex Electronics Corporation *)
    WAVE_FORMAT_G728_CELP = $0041, (* Antex Electronics Corporation *)
    WAVE_FORMAT_MSG723 = $0042, (* Microsoft Corporation *)
    WAVE_FORMAT_MPEG = $0050, (* Microsoft Corporation *)
    WAVE_FORMAT_RT24 = $0052, (* InSoft, Inc. *)
    WAVE_FORMAT_PAC = $0053, (* InSoft, Inc. *)
    WAVE_FORMAT_MPEGLAYER3 = $0055, (* ISO/MPEG Layer3 Format Tag *)
    WAVE_FORMAT_LUCENT_G723 = $0059, (* Lucent Technologies *)
    WAVE_FORMAT_CIRRUS = $0060, (* Cirrus Logic *)
    WAVE_FORMAT_ESPCM = $0061, (* ESS Technology *)
    WAVE_FORMAT_VOXWARE = $0062, (* Voxware Inc *)
    WAVE_FORMAT_CANOPUS_ATRAC = $0063, (* Canopus, co., Ltd. *)
    WAVE_FORMAT_G726_ADPCM = $0064, (* APICOM *)
    WAVE_FORMAT_G722_ADPCM = $0065, (* APICOM *)
    WAVE_FORMAT_DSAT_DISPLAY = $0067, (* Microsoft Corporation *)
    WAVE_FORMAT_VOXWARE_BYTE_ALIGNED = $0069, (* Voxware Inc *)
    WAVE_FORMAT_VOXWARE_AC8 = $0070, (* Voxware Inc *)
    WAVE_FORMAT_VOXWARE_AC10 = $0071, (* Voxware Inc *)
    WAVE_FORMAT_VOXWARE_AC16 = $0072, (* Voxware Inc *)
    WAVE_FORMAT_VOXWARE_AC20 = $0073, (* Voxware Inc *)
    WAVE_FORMAT_VOXWARE_RT24 = $0074, (* Voxware Inc *)
    WAVE_FORMAT_VOXWARE_RT29 = $0075, (* Voxware Inc *)
    WAVE_FORMAT_VOXWARE_RT29HW = $0076, (* Voxware Inc *)
    WAVE_FORMAT_VOXWARE_VR12 = $0077, (* Voxware Inc *)
    WAVE_FORMAT_VOXWARE_VR18 = $0078, (* Voxware Inc *)
    WAVE_FORMAT_VOXWARE_TQ40 = $0079, (* Voxware Inc *)
    WAVE_FORMAT_SOFTSOUND = $0080, (* Softsound, Ltd. *)
    WAVE_FORMAT_VOXWARE_TQ60 = $0081, (* Voxware Inc *)
    WAVE_FORMAT_MSRT24 = $0082, (* Microsoft Corporation *)
    WAVE_FORMAT_G729A = $0083, (* AT&amp;T Labs, Inc. *)
    WAVE_FORMAT_MVI_MVI2 = $0084, (* Motion Pixels *)
    WAVE_FORMAT_DF_G726 = $0085, (* DataFusion Systems (Pty) (Ltd) *)
    WAVE_FORMAT_DF_GSM610 = $0086, (* DataFusion Systems (Pty) (Ltd) *)
    WAVE_FORMAT_ISIAUDIO = $0088, (* Iterated Systems, Inc. *)
    WAVE_FORMAT_ONLIVE = $0089, (* OnLive! Technologies, Inc. *)
    WAVE_FORMAT_SBC24 = $0091, (* Siemens Business Communications Sys *)
    WAVE_FORMAT_DOLBY_AC3_SPDIF = $0092, (* Sonic Foundry *)
    WAVE_FORMAT_MEDIASONIC_G723 = $0093, (* MediaSonic *)
    WAVE_FORMAT_PROSODY_8KBPS = $0094, (* Aculab plc *)
    WAVE_FORMAT_ZYXEL_ADPCM = $0097, (* ZyXEL Communications, Inc. *)
    WAVE_FORMAT_PHILIPS_LPCBB = $0098, (* Philips Speech Processing *)
    WAVE_FORMAT_PACKED = $0099, (* Studer Professional Audio AG *)
    WAVE_FORMAT_MALDEN_PHONYTALK = $00A0, (* Malden Electronics Ltd. *)
    WAVE_FORMAT_RHETOREX_ADPCM = $0100, (* Rhetorex Inc. *)
    WAVE_FORMAT_IRAT = $0101, (* BeCubed Software Inc. *)
    WAVE_FORMAT_VIVO_G723 = $0111, (* Vivo Software *)
    WAVE_FORMAT_VIVO_SIREN = $0112, (* Vivo Software *)
    WAVE_FORMAT_DIGITAL_G723 = $0123, (* Digital Equipment Corporation *)
    WAVE_FORMAT_SANYO_LD_ADPCM = $0125, (* Sanyo Electric Co., Ltd. *)
    WAVE_FORMAT_SIPROLAB_ACEPLNET = $0130, (* Sipro Lab Telecom Inc. *)
    WAVE_FORMAT_SIPROLAB_ACELP4800 = $0131, (* Sipro Lab Telecom Inc. *)
    WAVE_FORMAT_SIPROLAB_ACELP8V3 = $0132, (* Sipro Lab Telecom Inc. *)
    WAVE_FORMAT_SIPROLAB_G729 = $0133, (* Sipro Lab Telecom Inc. *)
    WAVE_FORMAT_SIPROLAB_G729A = $0134, (* Sipro Lab Telecom Inc. *)
    WAVE_FORMAT_SIPROLAB_KELVIN = $0135, (* Sipro Lab Telecom Inc. *)
    WAVE_FORMAT_G726ADPCM = $0140, (* Dictaphone Corporation *)
    WAVE_FORMAT_QUALCOMM_PUREVOICE = $0150, (* Qualcomm, Inc. *)
    WAVE_FORMAT_QUALCOMM_HALFRATE = $0151, (* Qualcomm, Inc. *)
    WAVE_FORMAT_TUBGSM = $0155, (* Ring Zero Systems, Inc. *)
    WAVE_FORMAT_MSAUDIO1 = $0160, (* Microsoft Corporation *)
    WAVE_FORMAT_UNISYS_NAP_ADPCM = $0170, (* Unisys Corp. *)
    WAVE_FORMAT_UNISYS_NAP_ULAW = $0171, (* Unisys Corp. *)
    WAVE_FORMAT_UNISYS_NAP_ALAW = $0172, (* Unisys Corp. *)
    WAVE_FORMAT_UNISYS_NAP_16K = $0173, (* Unisys Corp. *)
    WAVE_FORMAT_CREATIVE_ADPCM = $0200, (* Creative Labs, Inc *)
    WAVE_FORMAT_CREATIVE_FASTSPEECH8 = $0202, (* Creative Labs, Inc *)
    WAVE_FORMAT_CREATIVE_FASTSPEECH10 = $0203, (* Creative Labs, Inc *)
    WAVE_FORMAT_UHER_ADPCM = $0210, (* UHER informatic GmbH *)
    WAVE_FORMAT_QUARTERDECK = $0220, (* Quarterdeck Corporation *)
    WAVE_FORMAT_ILINK_VC = $0230, (* I-link Worldwide *)
    WAVE_FORMAT_RAW_SPORT = $0240, (* Aureal Semiconductor *)
    WAVE_FORMAT_ESST_AC3 = $0241, (* ESS Technology, Inc. *)
    WAVE_FORMAT_IPI_HSX = $0250, (* Interactive Products, Inc. *)
    WAVE_FORMAT_IPI_RPELP = $0251, (* Interactive Products, Inc. *)
    WAVE_FORMAT_CS2 = $0260, (* Consistent Software *)
    WAVE_FORMAT_SONY_SCX = $0270, (* Sony Corp. *)
    WAVE_FORMAT_FM_TOWNS_SND = $0300, (* Fujitsu Corp. *)
    WAVE_FORMAT_BTV_DIGITAL = $0400, (* Brooktree Corporation *)
    WAVE_FORMAT_QDESIGN_MUSIC = $0450, (* QDesign Corporation *)
    WAVE_FORMAT_VME_VMPCM = $0680, (* AT&amp;T Labs, Inc. *)
    WAVE_FORMAT_TPC = $0681, (* AT&amp;T Labs, Inc. *)
    WAVE_FORMAT_OLIGSM = $1000, (* Ing C. Olivetti &amp; C., S.p.A. *)
    WAVE_FORMAT_OLIADPCM = $1001, (* Ing C. Olivetti &amp; C., S.p.A. *)
    WAVE_FORMAT_OLICELP = $1002, (* Ing C. Olivetti &amp; C., S.p.A. *)
    WAVE_FORMAT_OLISBC = $1003, (* Ing C. Olivetti &amp; C., S.p.A. *)
    WAVE_FORMAT_OLIOPR = $1004, (* Ing C. Olivetti &amp; C., S.p.A. *)
    WAVE_FORMAT_LH_CODEC = $1100, (* Lernout &amp; Hauspie *)
    WAVE_FORMAT_NORRIS = $1400, (* Norris Communications, Inc. *)
    WAVE_FORMAT_SOUNDSPACE_MUSICOMPRESS = $1500, (* AT&amp;T Labs, Inc. *)
    WAVE_FORMAT_DVM = $2000 (* FAST Multimedia AG *)
  );

type
  TFourCC = record
  case integer of
    1:  (Int32      : cardinal);
    2:  (ArrChar    : array[0..3] of AnsiChar);
    3:  (ArrByte    : array[0..3] of byte);
  end;

type
  ENoFMTChunk = class(Exception)
  public
    constructor Create;
  end;

  THeaderChunk = class(TObject)
  private
    FIOStream          : TBinaryReader;
    FOffset            : Int64;      // box position in io_stream
    FIdentify          : TFourCC;
    FSize              : int64;

    function GetSize: int64;
    procedure SetSize(AValue: int64);
    function Read(): boolean; virtual;
  public
    Constructor Create(IOStream: TBinaryReader); overload;
    Destructor  Destroy; override;

    property Offset            : Int64  read FOffset;
    property Size              : int64 read GetSize write SetSize;
    property Identify          : TFourCC read FIdentify;
    property IOStream          : TBinaryReader read FIOStream;
  end;

  TChunk = class(THeaderChunk)
  private
    FOwner : TChunk;
    function Read(): boolean; override;
  public
    constructor Create(Owner: TChunk; IOStream: TBinaryReader); overload;
    constructor Create(Identify: TFourCC; IOStream: TBinaryReader); overload;
    destructor Destroy;
    property Owner: TChunk read FOwner write FOwner;
  end;

type
  TChunkCollection = class(TObjectList<TChunk>)

  end;

  TFMTChunk = class(TChunk)
  private
    FCompressionCode: TCompressionCode;
    FNumberOfChannel: Word;
    FSampleRate: Cardinal;
    FAverageSamplePerSecond: Cardinal;
    FBlockAlign: Word;   // nChannels * (bitsPerSample / 8)
    FBitsPerSample: Word;
    FExtraBytes: Word;

    function Read(): boolean; override;
  public
    property CompressionCode: TCompressionCode read FCompressionCode;
    property SampleRate: Cardinal read FSampleRate;
    property NumberOfChannels: Word read FNumberOfChannel;
    property BitsPerSample: Word read FBitsPerSample;

    constructor Create(IOStream: TBinaryReader); overload;
    destructor Destroy;
  end;

  TFactChunk = class(TChunk)
  private
    FBytesInChunk: TArray<Byte>;
    function Read(): boolean; override;
  public
    property BytesInChunk: TArray<Byte> read FBytesInChunk;    
    constructor Create(IOStream: TBinaryReader); overload;
    destructor Destroy;
  end;

  TDataChunk = class(TChunk)
  private
    FBitsPerSample : Integer;
    FChannelCount  : Integer;
    FChannelsData  : array of PByte;
    FDataOffset    : Int64;
    function Read(): boolean; override;
    function GetChannelData (Index: Integer): PByte;
    procedure SetPosition(const Offset: Int64);
    function GetPosition: Int64;
  public
    property ChannelData [Index: Integer]: PByte read GetChannelData;
    property NumberOfChannel: Integer read FChannelCount;

    function ReadData(Buffer: PByte; Size: Cardinal): Cardinal; overload;
    function ReadData(Buffer: PByte; Offset, Size: Cardinal): Cardinal; overload;

    constructor Create(IOStream: TBinaryReader; BitsPerSample, ChannelCount: Integer); overload;
    destructor Destroy;

    property Possition: Int64 read GetPosition write  SetPosition;
    
  end;

  TWavlChunk = class(TChunk)
  private
    BitsPerSample, ChannelCount: Integer;
    DataChunk: TDataChunk;
    function Read(): boolean; override;
  public
    constructor Create(IOStream: TBinaryReader; BitsPerSample, ChannelCount: Integer);
    destructor Destroy;

  end;

  TSlntChunk = class (TChunk)
  private
    FLength: Integer;
    function Read(): boolean; override;
  public
    property Length: Integer read FLength;
    
    constructor Create(IOStream: TBinaryReader); overload;
    destructor Destroy;
    
  end;

  TCuePoint = class(TObject)
  private
    FIOStream: TBinaryReader;
    FIdentifier: Cardinal;
    FPosition: Cardinal;
    FDataChunkID: Cardinal;
    FChunkStart: Cardinal;
    FBlockStart: Cardinal;
    FSampleOffset: Cardinal;

    function Read(): boolean; virtual;
  public
    property Identifier: Cardinal read FIdentifier;
    property Position: Cardinal read FPosition;
    property DataChunkID: Cardinal read FDataChunkID;
    property ChunkStart: Cardinal read FChunkStart;
    property BlockStart: Cardinal read FBlockStart;
    property SampleOffset: Cardinal read FSampleOffset;
        
    constructor Create(IOStream: TBinaryReader); overload;
    destructor Destroy;

  end;

type
  TCueCollection = TObjectList<TCuePoint>;


  TCueChunk = class(TChunk)
  private
    FCuePointCollection: TCueCollection;
    function Read(): boolean; override;
  public
    property CuePointCollection: TCueCollection read FCuePointCollection;
    
    constructor Create(IOStream: TBinaryReader); overload;
    destructor Destroy;
    
  end;

  TOtherChunks = class (TChunk)
  private
    function Read(): boolean; override;
  public
    constructor Create(IOStream: TBinaryReader; Identify: TFourCC); overload;
    destructor Destroy;
  end;

  TWaveReader = class(TChunkCollection)
  private
    FIOStream : TBinaryReader;
    FCuePoints: TCueCollection;
    function GetFMTChunk: TFMTChunk;
    function GetChunkByID(Identify: cardinal): TChunkCollection;
    function GetDataChunk: TDataChunk;
  public
    property ChunkByID [ChunkID: cardinal]: TChunkCollection read GetChunkByID;
    property FMTChunk: TFMTChunk read GetFMTChunk;
    property DataChunk: TDataChunk read GetDataChunk;
    property CuePoints: TCueCollection read FCuePoints;

    constructor Create (FileName: String);
    destructor Destroy;
    
  end;

implementation

(* Header atom class *)
constructor THeaderChunk.Create(IOStream: TBinaryReader);
begin
  inherited Create;
  FIOStream := IOStream;
  
  FOffset := 0;
  FSize := 0;
  FIdentify.Int32 := 0;
end;

destructor THeaderChunk.Destroy;
begin
  inherited;
end;

function THeaderChunk.Read(): boolean;
var
  LIdentify : TFourCC;
begin
  if FIdentify.Int32 = 0 then
  begin
    FOffset := FIOStream.BaseStream.Position;
    FIdentify.Int32 := FIOStream.ReadCardinal;
  end else 
  begin
    FIOStream.BaseStream.Position := FIOStream.BaseStream.Position - 4;
    FOffset := FIOStream.BaseStream.Position;
    LIdentify.Int32 := FIOStream.ReadCardinal;
    if FIdentify.Int32 <> LIdentify.Int32 then
      raise Exception.Create('Error Message');
  end;
  FSize := FIOStream.ReadCardinal;
  result := true;
end;

function THeaderChunk.GetSize: int64;
begin
  result := FSize;
end;

Procedure THeaderChunk.SetSize(AValue: int64);
begin
  FSize := AValue;
end;


(* TChunk *)
constructor TChunk.Create(Owner: TChunk; IOStream: TBinaryReader);
begin
  inherited Create(IOStream);
  FOwner:= Owner;
end;

constructor TChunk.Create(Identify: TFourCC; IOStream: TBinaryReader);
begin
  inherited Create(IOStream);
  Self.FIdentify := Identify;
end;

destructor TChunk.Destroy;
begin
  inherited;
end;

function TChunk.Read(): boolean;
begin
  result := inherited Read;
end;

(* TFMTChunk *)
constructor TFMTChunk.Create(IOStream: TBinaryReader);
begin
  inherited Create(nil, IOStream);
  Self.FIdentify.Int32 := $20746D66;
end;

destructor TFMTChunk.Destroy;
begin
  inherited;
end;

function TFMTChunk.Read(): boolean;
var
  i: Integer;

begin
  result := inherited Read;
  
  FCompressionCode:= TCompressionCode(IOStream.ReadWord);
  FNumberOfChannel:= IOStream.ReadWord;
  FSampleRate:= IOStream.ReadCardinal;
  FAverageSamplePerSecond:= IOStream.ReadCardinal;
  FBlockAlign:= IOStream.ReadWord;
  FBitsPerSample:= IOStream.ReadWord;
  if not (FBitsPerSample in [8, 16, 24, 32]) then
    raise Exception.Create ('Invalid SignificantBitPerSample!');
    
  if CompressionCode <> TCompressionCode.WAVE_FORMAT_PCM then
  begin
    FExtraBytes:= IOStream.ReadWord;
    for i:= 1 to FExtraBytes do
      IOStream.ReadByte;
  end;

  // skip footer
  if IOStream.BaseStream.Position <> Self.Offset + self.Size + SizeOf(self.Size)  then
    IOStream.BaseStream.Position  := Self.Offset + self.Size + SizeOf(self.Size);
end;

(* TWaveReader *)
constructor TWaveReader.Create(FileName: String);
var
  FileSize    : Cardinal;
  Identify    : TFourCC;
  NewChunk    : TChunk;
begin
  inherited Create;

  FIOStream:= TBinaryReader.Create(FileName);
  FCuePoints:= TCueCollection.Create;

  Identify.Int32 := FIOStream.ReadCardinal;
  if not SameText(Format('%.4s', [PAnsiChar(@Identify.Int32)]), 'RIFF') then
    raise Exception.Create('Error read RIFF header');

  FileSize:= FIOStream.ReadCardinal;
  if FileSize + 8 <> FIOStream.BaseStream.Size then
    raise Exception.Create ('Invalid Size');

  Identify.Int32 := FIOStream.ReadCardinal;
  if not SameText(Format('%.4s', [PAnsiChar(@Identify.Int32)]), 'WAVE') then
    raise Exception.Create('Error read WAVE header');

  while FIOStream.BaseStream.Position< FIOStream.BaseStream.Size do
  begin
    Identify.Int32 := FIOStream.ReadCardinal;
    case Identify.Int32 of
      $20746D66: //fmt .
        begin
          Self.Add(TFMTChunk.Create(FIOStream));
          if not assigned(Self.FMTChunk) or not Self.FMTChunk.Read then
            raise Exception.Create('Error Message');
        end;
      $20657563://cue .
        begin
          NewChunk:= TCueChunk.Create(FIOStream);
          if not NewChunk.Read() then
            raise Exception.Create('Error read cue chunk');
          Add(NewChunk);
          FCuePoints.Free;
          FCuePoints:= TCueChunk(NewChunk).CuePointCollection;
        end;
      $66616374://fact.
        begin
          NewChunk:= TFactChunk.Create;
          if not NewChunk.Read() then
            raise Exception.Create('Error Message');
          Add(NewChunk);
        end;
      $61746164://data.
        begin
          NewChunk:= TDataChunk.Create(FIOStream, FMTChunk.BitsPerSample, FMTChunk.NumberOfChannels);
          if not TDataChunk(NewChunk).Read() then
            raise Exception.Create('Error Message');
          Add(NewChunk);
        end;
      $5761766c://Wavl.
        begin
          NewChunk:= TWavlChunk.Create(FIOStream, FMTChunk.BitsPerSample, FMTChunk.FNumberOfChannel);
          if not NewChunk.Read() then
            raise Exception.Create('Error Message');
          Add(NewChunk);
        end;
      else
        begin
          NewChunk:= TOtherChunks.Create(FIOStream, Identify);
          if not NewChunk.Read() then
            raise Exception.Create('Error Message');
          Add(NewChunk);
        end;
    end;
  end;
end;

destructor TWaveReader.Destroy;
begin
  FreeAndNil(FIOStream);
  FreeAndNil(FCuePoints);
  inherited;
end;

function TWaveReader.GetChunkByID(Identify: cardinal): TChunkCollection;
var
  i: Integer;
begin
  Result:= TChunkCollection.Create;

  for i:= 0 to Self.Count - 1 do
  begin
    if Self.Items[i].FIdentify.Int32 = Identify then
      result.Add(Self.Items[i]);
  end;
end;

function TWaveReader.GetDataChunk: TDataChunk;
begin
  Result:= (ChunkByID[$61746164].Items[0]) as TDataChunk;
end;

function TWaveReader.GetFMTChunk: TFMTChunk;
var
  Temp: TChunkCollection;
begin
  Temp:= ChunkByID[$20746d66];
  if Temp.Count = 0 then
    raise ENoFMTChunk.Create;
  Result:= Temp.Items[0] as TFMTChunk;
end;

(* ENoFMTChunk *)
constructor ENoFMTChunk.Create;
begin
  inherited Create ('No chunk file is in the wave file!');
end;

(* TFactChunk *)
constructor TFactChunk.Create(IOStream: TBinaryReader);
begin
  inherited Create(nil, IOStream);
  Self.FIdentify.Int32 := $46616374;
end;

destructor TFactChunk.Destroy;
begin
  inherited;
end;

function TFactChunk.Read(): boolean;
var
  i: Integer;
begin
  result := inherited Read;

  SetLength(FBytesInChunk, Self.FSize);
  for i:= 0 to Self.FSize - 1 do
    FBytesInChunk[i] := IOStream.ReadByte;
end;

(* TDataChunk *)
constructor TDataChunk.Create(IOStream: TBinaryReader; BitsPerSample, ChannelCount: Integer);
begin
  inherited Create(nil, IOStream);
  Self.FIdentify.Int32 := $61746164;
  Self.FBitsPerSample:= BitsPerSample;
  Self.FChannelCount:= ChannelCount;
end;

destructor TDataChunk.Destroy;
begin
  FreeAndNil(FChannelsData);
  inherited;
end;

function TDataChunk.GetChannelData(Index: Integer): PByte;
begin
  Result:= FChannelsData[Index];
end;

function TDataChunk.ReadData(Buffer: PByte; Offset, Size: Cardinal): Cardinal;
begin
  if FDataOffset = 0 then
    Exit(0);

  Self.FIOStream.BaseStream.Position := FDataOffset + Offset;
  result := Self.FIOStream.BaseStream.Read(Buffer^, Size);
end;

function TDataChunk.ReadData(Buffer: PByte; Size: Cardinal): Cardinal;
begin
  if FDataOffset = 0 then
    Exit(0);

  result := Self.FIOStream.BaseStream.Read(Buffer^, Size);
end;

procedure TDataChunk.SetPosition(const Offset: Int64);
begin
  Self.FIOStream.BaseStream.Position := FDataOffset + Offset;;
end;

function TDataChunk.GetPosition: Int64;
begin
  result := Self.FIOStream.BaseStream.Position;
end;

function TDataChunk.Read(): boolean;
var
  i, j, k: Integer;
  Buffer: PByte;
  Ptr : PByte;
  SampleCount: Integer;
  EachSampleSize : integer;
  LChannelsData : array of PByte;
begin
  inherited Read;

  //if (Self.FSize) mod (FChannelCount * FBitsPerSample) <> 0 then
  //  raise Exception.Create ('Invalid Data Size in DataChunk!');

  // set data offset
  FDataOffset := IOStream.BaseStream.Position;

  SampleCount:= (Self.FSize) div (FChannelCount * (FBitsPerSample div 8));

  SetLength(FChannelsData, FChannelCount);
  SetLength(LChannelsData, FChannelCount);
  for I := 0 to Length(FChannelsData) - 1 do
  begin
    FChannelsData[i] := AllocMem(Self.FSize div FChannelCount);
    LChannelsData[I]:= FChannelsData[i];
  end;

  EachSampleSize := FBitsPerSample div 8;

  // alloc 1024 sample
  Buffer := AllocMem(1024 * EachSampleSize * FChannelCount);
  try

    for i:= 1 to SampleCount div 1024 do
    begin
      IOStream.BaseStream.ReadData(Buffer, 1024 * EachSampleSize * FChannelCount);
      Ptr := Buffer;
      for j:= 1 to 1024 do
      begin
        for k:= 0 to FChannelCount - 1 do
        begin
          case EachSampleSize of
            1: PByte(LChannelsData[k])^:= PByte(Ptr)^;
            2: PSmallInt(LChannelsData[k])^:= PSmallInt(Ptr)^;
            3: PInteger(LChannelsData[k])^:= PInteger(Ptr)^;
            4: PInteger(LChannelsData[k])^:= PInteger(Ptr)^;
          end;
          Inc(Ptr, EachSampleSize);
          Inc(LChannelsData[k], EachSampleSize);
        end;
      end;
    end;

    if SampleCount mod 1024 <> 0 then
    begin
      IOStream.BaseStream.ReadData(Buffer, (SampleCount mod 1024) * EachSampleSize * FChannelCount);
      Ptr := Buffer;
      for j:= 1 to (SampleCount mod 1024) do
        for k:= 0 to FChannelCount - 1 do
        begin
          case EachSampleSize of
            1: PByte(LChannelsData[k])^:= PByte(Ptr)^;
            2: PSmallInt(LChannelsData[k])^:= PSmallInt(Ptr)^;
            3: PInteger(LChannelsData[k])^:= PInteger(Ptr)^;
            4: PInteger(LChannelsData[k])^:= PInteger(Ptr)^;
          end;
          Inc(Ptr, EachSampleSize);
          Inc(LChannelsData[k], EachSampleSize);
        end;
    end;
  finally
    FreeMem(Buffer);
  end;

  result := true;
end;

(* TWavlChunk *)
constructor TWavlChunk.Create(IOStream: TBinaryReader; BitsPerSample, ChannelCount: Integer);
begin
  inherited Create(nil, IOStream);
  Self.FIdentify.Int32 := $7761766c;
  Self.BitsPerSample:= BitsPerSample;
  Self.ChannelCount:= ChannelCount;
  DataChunk:= TDataChunk.Create(IOStream, BitsPerSample, ChannelCount);
end;

destructor TWavlChunk.Destroy;
begin
  FreeAndNil(DataChunk);
  inherited;
end;

function TWavlChunk.Read(): boolean;
var
  l, i, j         : Integer;
  Identify         : TFourCC;
  SLNTChunk       : TSlntChunk;
  LastValue       : Cardinal;
begin
  result := inherited Read;

  if BitsPerSample = 1 then
    LastValue:= 127
  else
    LastValue:= 0;

  l:= 0;
  while l < Self.FSize do
  begin
    Identify.Int32:= IOStream.ReadCardinal;

    if Identify.Int32 = $736c6e74 then
    begin
      SLNTChunk:= TSlntChunk.Create;
      SLNTChunk.Read;

      for i:= 1 to SLNTChunk.Length do
      begin
        for j:= 0 to ChannelCount- 1 do
        begin
          DataChunk.ChannelData[j][i] := LastValue;
        end;
      end;

      WriteLn ('In Wavl! this method is not tested completely!');
      SLNTChunk.Free;

    end
    else if Identify.Int32 = $61746164 then
    begin
      DataChunk.Read;
    end;
  end;
end;

(* TSlntChunk *)
constructor TSlntChunk.Create(IOStream: TBinaryReader);
begin
  inherited Create(nil, IOStream);
  Self.FIdentify.Int32 := $736c6e74;
end;

destructor TSlntChunk.Destroy;
begin
  inherited;
end;

function TSlntChunk.Read(): boolean;
begin
  result := inherited Read;
  FLength:= IOStream.ReadCardinal;
end;

{ TCuePoint }

constructor TCuePoint.Create(IOStream: TBinaryReader);
begin
  inherited Create;
  FIOStream := IOStream;
end;

destructor TCuePoint.Destroy;
begin
  inherited;
end;

function TCuePoint.Read(): boolean;
begin
  FIdentifier:= FIOStream.ReadCardinal;
  FPosition:= FIOStream.ReadCardinal;
  FDataChunkID:= FIOStream.ReadCardinal;
  FChunkStart:= FIOStream.ReadCardinal;
  FBlockStart:= FIOStream.ReadCardinal;
  FSampleOffset:= FIOStream.ReadCardinal;
  result := true;
end;

{ TCueChunk }

constructor TCueChunk.Create(IOStream: TBinaryReader);
begin
  inherited Create(nil, IOStream);
  Self.FIdentify.Int32 := $637565;
  FCuePointCollection := TCueCollection.Create();
end;

destructor TCueChunk.Destroy;
begin
  FCuePointCollection.Clear;
  FreeAndNil(FCuePointCollection);
  inherited;
end;

function TCueChunk.Read(): boolean;
var
  LCuePoints: Int64;
  LCuePoint: TCuePoint;
begin
  result := inherited Read;

  LCuePoints:= IOStream.ReadInteger;

  while 0 < LCuePoints do
  begin
    LCuePoint:= TCuePoint.Create(IOStream);
    LCuePoint.Read;
    FCuePointCollection.Add(LCuePoint);
    Dec(LCuePoints);
  end;
end;

{ TOtherChunks }

constructor TOtherChunks.Create(IOStream: TBinaryReader; Identify: TFourCC);
begin
  inherited Create(nil, IOStream);
  Self.FIdentify.Int32 := Identify.Int32;
end;

destructor TOtherChunks.Destroy;
begin
  inherited;
end;

function TOtherChunks.Read(): boolean;
const
{$J+}
  Buffer: array of Integer = nil;
{$J-}

begin
  result := inherited Read;

  if Buffer = nil then
    SetLength (Buffer, Self.FSize + 1)
  else if Length (Buffer)< Self.FSize then
    SetLength (Buffer, Self.FSize+ 1);

//  for i:= 1 to FDataSize do
    IOStream.BaseStream.Read(Buffer[0], Self.FSize);
end;

end.
