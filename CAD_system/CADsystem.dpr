program CADsystem;

uses
  Forms,
  frmMain in 'frmMain.pas' {frmItem};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfrmItem, frmItem);
  Application.Run;
end.

