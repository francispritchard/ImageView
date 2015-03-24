PROGRAM ImageView;

uses
  ShareMem,
  Forms,
  ZoomPlayerUnit in 'ZoomPlayerUnit.pas' {ZoomPlayerUnitForm},
  ZoomPlayerCodes in 'ZoomPlayerCodes.pas',
  ImageViewUnit in 'ImageViewUnit.pas' {ImageViewUnitForm},
  MediaInfo in 'MediaInfo.pas' {Form1};

{$R *.res}

BEGIN
  Application.Initialize;
  Application.Title := 'FWP Explorer';
  Application.CreateForm(TImageViewUnitForm, ImageViewUnitForm);
  Application.CreateForm(TZoomPlayerUnitForm, ZoomPlayerUnitForm);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
END { FWPExplorer }.
