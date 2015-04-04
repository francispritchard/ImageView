PROGRAM ImageView;

uses
  ShareMem,
  Forms,
  ZoomPlayerUnit in 'ZoomPlayerUnit.pas' {ZoomPlayerUnitForm},
  ZoomPlayerCodes in 'ZoomPlayerCodes.pas',
  ImageViewUnit in 'ImageViewUnit.pas' {ImageViewUnitForm},
  MediaInfo in 'MediaInfo.pas' {Form1},
  ImageViewSplash in 'ImageViewSplash.pas' {ImageViewSplashForm};

{$R *.res}

VAR
  I : Integer;
  WantSplash : Boolean = True;

BEGIN
  Application.Initialize;
  Application.Title := 'FWP Explorer';
  Application.CreateForm(TImageViewUnitForm, ImageViewUnitForm);
  Application.CreateForm(TZoomPlayerUnitForm, ZoomPlayerUnitForm);
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TImageViewSplashForm, ImageViewSplashForm);
  FOR I := 1 TO ParamCount DO
    IF ParamStr(I) = '/nosplash' THEN
      WantSplash := False;

  IF WantSplash THEN BEGIN
    ImageViewSplashForm := TImageViewSplashForm.Create(Application);
    ImageViewSplashForm.Show;
    ImageViewSplashForm.Update;
  END;

  Application.Run;
END { FWPExplorer }.
