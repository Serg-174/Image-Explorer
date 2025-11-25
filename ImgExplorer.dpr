program ImgExplorer;

uses
  Vcl.Forms,
  Main in 'Main.pas' {fmMain},
  Common in 'Common.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Image Explorer';
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
