PROGRAM ImageView;

uses
  Forms,
  ZoomPlayerUnit in 'ZoomPlayerUnit.pas' {ZoomPlayerUnitForm},
  ZoomPlayerCodes in 'ZoomPlayerCodes.pas',
  FWPOnlyUnit in 'FWPOnlyUnit.pas' {SnapsCompareForm},
  ImageViewUnit in 'ImageViewUnit.pas' {ImageViewUnitForm},
  MediaInfo in 'MediaInfo.pas' {Form1};

{$R *.res}

BEGIN
  Application.Initialize;
  Application.Title := 'FWP Explorer';
  Application.CreateForm(TImageViewUnitForm, ImageViewUnitForm);
  Application.CreateForm(TZoomPlayerUnitForm, ZoomPlayerUnitForm);
  Application.CreateForm(TSnapsCompareForm, SnapsCompareForm);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
END { FWPExplorer }.
