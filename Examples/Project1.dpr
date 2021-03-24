program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  audio.wave.reader in '../Source/audio.wave.reader.pas';

var
  fWaveFile               : TWaveReader;
  lSourceFile             : string;
  FFirstByte              : array of Byte;
  FReadBytes              : integer;
begin
  try

    if not FindCmdLineSwitch('i', lSourceFile, True) then
    begin
      writeln(format('Usage: %s -i [WAV FILE]', [System.IOUtils.TPath.GetFileName(ParamStr(0))]));
      exit;
    end;
    lSourceFile := TPath.GetFullPath(TPath.Combine(System.IOUtils.TPath.GetDirectoryName(ParamStr(0)), lSourceFile));

    fWaveFile := TWaveReader.Create(lSourceFile);
    try
      WriteLn(Format('* Read %s: ', [lSourceFile]));
      WriteLn(Format('   Data size: %d', [fWaveFile.DataChunk.Size div fWaveFile.DataChunk.NumberOfChannel]));
      WriteLn(Format('   Channels count: %d', [fWaveFile.NumberOfChannel]));
      WriteLn(Format('   BitsPerSample: %d', [fWaveFile.BitsPerSample]));
      WriteLn(Format('   SampleRate: %d', [fWaveFile.SampleRate]));

      SetLength(FFirstByte, 64);
      Move(fWaveFile.DataChunk.ChannelData[0]^, FFirstByte[0], 64);
      FillChar(FFirstByte[0], 64, #0);
      FReadBytes := fWaveFile.DataChunk.ReadData(@FFirstByte[0], 64);


    finally
      FreeAndNil(fWaveFile);
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  WriteLn;
  Write('Press Enter to exit...');
  Readln;

end.
