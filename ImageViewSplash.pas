UNIT ImageViewSplash;

INTERFACE

USES
  SysUtils, Windows, Messages, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, ExtCtrls;

TYPE
  TImageViewSplashForm = CLASS(TForm)
    ImageViewSplashCopyrightLabel: TLabel;
    ImageViewSplashImage: TImage;
    ImageViewSplashLoadingLabel: TLabel;
    ImageViewSplashPanel: TPanel;
    ImageViewSplashRailwayProgramLabel: TLabel;
    ImageViewSplashRightsReservedLabel: TLabel;
    PROCEDURE ImageViewSplashLoadingLabelClick(Sender: TObject);
    PROCEDURE ImageViewSplashPanelCreate(Sender: TObject);
    PROCEDURE ImageViewSplashPanelMouseDown(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    PROCEDURE ImageViewSplashRailwayProgramLabelMouseDown(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  END;

VAR
  LoadingLabelClicked : Boolean = False;
  ImageViewSplashForm: TImageViewSplashForm;

PROCEDURE HideSplashForm;
{ Allows the main program to hide the splash form once it's no longer needed }

FUNCTION IsSplashFormVisible : Boolean;
{ Returns whether or not the splash form is visible }

PROCEDURE WriteSplashLoadingLabel(Str : String);
{ Write out how many files have been loaded so far }

IMPLEMENTATION

{$R *.dfm}

USES ImageViewUnit;

PROCEDURE TImageViewSplashForm.ImageViewSplashLoadingLabelClick(Sender: TObject);
BEGIN
  IF NOT LoadinglabelClicked THEN
    LoadinglabelClicked := True
  ELSE
    StopFileLoading;
END; { ImageViewSplashLoadingLabelClick }

PROCEDURE TImageViewSplashForm.ImageViewSplashPanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
BEGIN
  ImageViewSplashForm.Hide;
END; { ImageViewSplashPanelMouseDown }

PROCEDURE TImageViewSplashForm.ImageViewSplashRailwayProgramLabelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
BEGIN
  ImageViewSplashForm.Hide;
END; { ImageViewSplashRailwayProgramLabelMouseDown }

PROCEDURE TImageViewSplashForm.ImageViewSplashPanelCreate(Sender: TObject);
BEGIN
  ImageViewSplashCopyrightLabel.Caption := 'Copyright © 2015 F.W. Pritchard';
END;

PROCEDURE HideSplashForm;
{ Allows the main program to hide the splash form once it's no longer needed }
BEGIN
  ImageViewSplashForm.Hide;
END;

FUNCTION IsSplashFormVisible : Boolean;
{ Returns whether or not the splash form is visible }
BEGIN
  IF (ImageViewSplashForm <> NIL) AND (ImageViewSplashForm.Visible) THEN
    Result := True
  ELSE
    Result := False;
END;

PROCEDURE WriteSplashLoadingLabel(Str : String);
{ Write out how many files have been loaded so far }
BEGIN
  IF NOT LoadinglabelClicked THEN
    ImageViewSplashForm.ImageViewSplashLoadingLabel.Caption := Str
  ELSE
    ImageViewSplashForm.ImageViewSplashLoadingLabel.Caption := Str + ' - click label again to terminate ImageView';
END; { WriteSplashLoadingLabel }

END { Splash }.
