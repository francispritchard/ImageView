UNIT FWPOnlyUnit;

INTERFACE

USES
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, ExtCtrls, AXCtrls, GraphUtil, StrUtils, ComCtrls, Character,
  DateUtils, ShellAPI, TLHelp32, ZoomPlayerUnit;

TYPE
  TSnapsCompareForm = CLASS(TForm)
    SnapsCompareFormImage1 : TImage;
    SnapsCompareFormImage2 : TImage;
    PROCEDURE SnapsCompareFormClose(Sender : TObject; VAR Action : TCloseAction);
    PROCEDURE SnapsCompareFormCreate(Sender : TObject);
  PRIVATE
    { Private declarations }
  PUBLIC
    { Public declarations }
  END;

  FileType = (Text_File, VideoFile, ImageFile, DatabaseFile, UnspecifiedFileType);

FUNCTION FileTypeSuffixFound{1}(TempFileName : String) : Boolean; Overload;
FUNCTION FileTypeSuffixFound{2}(TempFileName : String; OUT SuffixFoundStr : String) : Boolean; Overload;
FUNCTION FileTypeSuffixFound{3}(TempFileName : String; OUT SuffixPos, SuffixLength : Integer) : Boolean; Overload;
FUNCTION FileTypeSuffixFound{4}(TempFileName : String; SuffixToFind : String; OUT SuffixPos, SuffixLength : Integer) : Boolean; Overload;
FUNCTION FileTypeSuffixFound{5}(TempFileName : String; OUT TypeOfFile : FileType) : Boolean; Overload;
FUNCTION FileTypeSuffixFound{6}(TempFileName : String; OUT FileNameWithoutSuffix : String; OUT TypeOfFile : FileType) : Boolean; Overload;

FUNCTION IsProgramRunning(ProgramName : String) : Boolean;
{ Checks to see if a given program is running }

VAR
  SnapsCompareForm : TSnapsCompareForm;

IMPLEMENTATION

{$R *.dfm}

USES Registry, ImageViewUnit;

CONST
  FormAlignmentSectionStr = 'Form Alignment';

  SnapsCompareFormTopStr = 'Snaps Compare Form Top';
  SnapsCompareFormLeftStr = 'Snaps Compare Form Left';
  SnapsCompareFormWidthStr = 'Snaps Compare Form Width';
  SnapsCompareFormHeightStr = 'Snaps Compare Form Height';

VAR
  DefaultSnapsCompareFormTop : Integer = 0;
  DefaultSnapsCompareFormLeft : Integer = 0;
  DefaultSnapsCompareFormWidth : Integer = 508;
  DefaultSnapsCompareFormHeight : Integer = 900;

  SnapsCompareFormTop : Integer = 0;
  SnapsCompareFormLeft : Integer = 0;
  SnapsCompareFormWidth : Integer = 508;
  SnapsCompareFormHeight : Integer = 900;
  VLC : Boolean = False;
  ZoomPlayer : Boolean = False;

PROCEDURE LoadCompareImage(PathAndFileName : String; SnapNumber : Integer);
VAR
  Bitmap, NewBitmap : TBitmap;
  FileStream : TFileStream;
  OleGraphic : TOleGraphic;
  Source : TImage;
  TempDouble : Double;
  UseOriginalImage : Boolean;

BEGIN
  TRY
    FileStream := TFileStream.Create(PathAndFileName, fmOpenRead Or fmSharedenyNone);

    IF FileStream <> NIL THEN BEGIN
      OleGraphic := TOleGraphic.Create;

      TRY
        OleGraphic.LoadFromStream(FileStream);
      EXCEPT
        ON E : Exception DO
          { do nothing }; //ShowMessage('OleGraphic.LoadFromStream: ' + E.ClassName +' error raised with message: ' + E.Message);
      END;

      Source := TImage.Create(NIL);
      Source.Picture.Assign(OleGraphic);

      Bitmap := TBitmap.Create; { Converting to bitmap }
      Bitmap.Width := Source.Picture.Width;
      Bitmap.Height := Source.Picture.Height;
      Bitmap.Canvas.Draw(0, 0, Source.Picture.Graphic);

      NewBitMap := TBitmap.Create; { Converting to bitmap }

      UseOriginalImage := False;

      IF SnapNumber = 1 THEN BEGIN
        IF BitMap.Width = 0 THEN
          SnapsCompareForm.SnapsCompareFormImage1.Picture.Bitmap := Bitmap
        ELSE BEGIN
          TempDouble := SnapsCompareForm.SnapsCompareFormImage1.Width / Bitmap.Width;
          TRY
            ScaleImage(Bitmap, NewBitMap, TempDouble);
          EXCEPT
            ON E : Exception DO BEGIN
              { do nothing } ; // ShowMessage('ScaleImage: ' + E.ClassName +' error raised with message: ' + E.Message);
              UseOriginalImage := True;
            END;
          END;

          IF UseOriginalImage THEN
            SnapsCompareForm.SnapsCompareFormImage1.Picture.Bitmap := Bitmap
          ELSE
            SnapsCompareForm.SnapsCompareFormImage1.Picture.Bitmap := NewBitmap;
        END;
      END ELSE BEGIN
        IF BitMap.Width = 0 THEN
          SnapsCompareForm.SnapsCompareFormImage2.Picture.Bitmap := Bitmap
        ELSE BEGIN
          TempDouble := SnapsCompareForm.SnapsCompareFormImage2.Width / Bitmap.Width;
          TRY
            ScaleImage(Bitmap, NewBitMap, TempDouble);
          EXCEPT
            ON E : Exception DO BEGIN
              { do nothing } ; // ShowMessage('ScaleImage: ' + E.ClassName +' error raised with message: ' + E.Message);
              UseOriginalImage := True;
            END;
          END;

          IF UseOriginalImage THEN
            SnapsCompareForm.SnapsCompareFormImage2.Picture.Bitmap := Bitmap
          ELSE
            SnapsCompareForm.SnapsCompareFormImage2.Picture.Bitmap := NewBitmap;
        END;
      END;
      FileStream.Free;
      OleGraphic.Free;
      Source.Free;
      Bitmap.Free;
      NewBitmap.Free;
    END;
  EXCEPT
    ON E : Exception DO
      ShowMessage('LoadImage: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END; {TRY}
END; { LoadCompareImage }

FUNCTION FileTypeSuffixFoundMainProc(TempFileName : String; OUT FileNameWithoutSuffix : String; SuffixToFind : String; OUT SuffixFoundStr : String;
                                     OUT SuffixPos, SuffixLength : Integer; OUT TypeOfFile : FileType) : Boolean;

  FUNCTION GetPos(Str : String; TempTypeOfFile : FileType) : Boolean;
  BEGIN
    SuffixLength := Length(Str);
    SuffixPos := Pos(UpperCase(Str), UpperCase(TempFileName));
    IF SuffixPos = 0 THEN BEGIN
      Result := False;
      SuffixFoundStr := '';
      FileNameWithoutSuffix := TempFileName;
    END ELSE
//      IF Pos('.DB', UpperCase(TempFileName)) > 0 THEN BEGIN
//        { exclude files with .db wherever it appears in a filename }
//        Result := True;
//        FileNameWithoutSuffix := Copy(TempFileName, 1, SuffixPos - 1);
//        TypeOfFile := TempTypeOfFile;
//        SuffixFoundStr := '';
//        SuffixPos := 0;
//      END ELSE
      BEGIN
        Result := True;
        SuffixFoundStr := Str;
        TypeOfFile := TempTypeOfFile;
        FileNameWithoutSuffix := Copy(TempFileName, 1, SuffixPos - 1);
      END;
  END; { GetPos }

BEGIN
  IF SuffixToFind <> '' THEN
    GetPos(SuffixToFind, UnspecifiedFileType)
  ELSE BEGIN
    { the image files are deliberately first in this list, as snaps are in the format .avi.jpg and otherwise are not identified as image files }
    IF NOT GetPos('.jpg', ImageFile) THEN
      IF NOT GetPos('.jpeg', ImageFile) THEN
        IF NOT GetPos('.gif', ImageFile) THEN
          IF NOT GetPos('.pcx', ImageFile) THEN
            IF NOT GetPos('.gif', ImageFile) THEN
              IF NOT GetPos('.png', ImageFile) THEN
                IF NOT GetPos('.bmp', ImageFile) THEN
                  IF NOT GetPos('.tif', ImageFile) THEN
                    IF NOT GetPos('.txt', Text_File) THEN
                      IF NOT GetPos('.3gp', VideoFile) THEN
                        IF NOT GetPos('.asf', VideoFile) THEN
                          IF NOT GetPos('.avi', VideoFile)  THEN
                            IF NOT GetPos('.divx', VideoFile) THEN
                              IF NOT GetPos('.flv', VideoFile) THEN
                                IF NOT GetPos('.mlv', VideoFile) THEN
                                  IF NOT GetPos('.mp4', VideoFile) THEN
                                    IF NOT GetPos('.mpeg', VideoFile) THEN
                                      IF NOT GetPos('.mpg', VideoFile) THEN
                                        IF NOT GetPos('.ram', VideoFile) THEN
                                          IF NOT GetPos('.rm', VideoFile) THEN
                                            IF NOT GetPos('.m1v', VideoFile) THEN
                                              IF NOT GetPos('.m4v', VideoFile) THEN
                                                IF NOT GetPos('.vlc', VideoFile) THEN
                                                    IF NOT GetPos('.wmv', VideoFile) THEN
                                                        GetPos('.db', DatabaseFile);
  END;

  IF SuffixPos = 0 THEN
    Result := False
  ELSE
    Result := True;
END; { FileTypeSuffixFound }

FUNCTION FileTypeSuffixFound{1}(TempFileName : String) : Boolean; Overload;
VAR
  FileNameWithoutSuffix : String;
  SuffixPos : Integer;
  SuffixLength : Integer;
  SuffixFoundStr : String;
  TypeOfFile : FileType;

BEGIN
  SuffixFoundStr := '';
  IF FileTypeSuffixFoundMainProc(TempFileName, FileNameWithoutSuffix, '', SuffixFoundStr, SuffixPos, SuffixLength, TypeOfFile) THEN
    Result := True
  ELSE
    Result := False;
END; { FileTypeSuffixFound-1 }

FUNCTION FileTypeSuffixFound{2}(TempFileName : String; OUT SuffixFoundStr : String) : Boolean; Overload;
VAR
  FileNameWithoutSuffix : String;
  SuffixPos : Integer;
  SuffixLength : Integer;
  TypeOfFile : FileType;

BEGIN
  SuffixFoundStr := '';
  IF FileTypeSuffixFoundMainProc(TempFileName, FileNameWithoutSuffix, '', SuffixFoundStr, SuffixPos, SuffixLength, TypeOfFile) THEN
    Result := True
  ELSE
    Result := False;
END; { FileTypeSuffixFound-2 }

FUNCTION FileTypeSuffixFound{3}(TempFileName : String; OUT SuffixPos, SuffixLength : Integer) : Boolean; Overload;
VAR
  FileNameWithoutSuffix : String;
  SuffixFoundStr : String;
  TypeOfFile : FileType;

BEGIN
  IF FileTypeSuffixFoundMainProc(TempFileName, FileNameWithoutSuffix, '', SuffixFoundStr, SuffixPos, SuffixLength, TypeOfFile) THEN
    Result := True
  ELSE
    Result := False;
END; { FileTypeSuffixFound-3 }

FUNCTION FileTypeSuffixFound{4}(TempFileName : String; SuffixToFind : String; OUT SuffixPos, SuffixLength : Integer) : Boolean; Overload;
VAR
  FileNameWithoutSuffix : String;
  SuffixFoundStr : String;
  TypeOfFile : FileType;

BEGIN
  IF FileTypeSuffixFoundMainProc(TempFileName, FileNameWithoutSuffix, SuffixToFind, SuffixFoundStr, SuffixPos, SuffixLength, TypeOfFile) THEN
    Result := True
  ELSE
    Result := False;
END; { FileTypeSuffixFound-4 }

FUNCTION FileTypeSuffixFound{5}(TempFileName : String; OUT TypeOfFile : FileType) : Boolean; Overload;
VAR
  FileNameWithoutSuffix : String;
  SuffixPos : Integer;
  SuffixLength : Integer;
  SuffixFoundStr : String;

BEGIN
  IF FileTypeSuffixFoundMainProc(TempFileName, FileNameWithoutSuffix, '', SuffixFoundStr, SuffixPos, SuffixLength, TypeOfFile) THEN
    Result := True
  ELSE
    Result := False;
END; { FileTypeSuffixFound-5 }

FUNCTION FileTypeSuffixFound{6}(TempFileName : String; OUT FileNameWithoutSuffix : String; OUT TypeOfFile : FileType) : Boolean; Overload;
VAR
  SuffixPos : Integer;
  SuffixLength : Integer;
  SuffixFoundStr : String;

BEGIN
  IF FileTypeSuffixFoundMainProc(TempFileName, FileNameWithoutSuffix, '', SuffixFoundStr, SuffixPos, SuffixLength, TypeOfFile) THEN
    Result := True
  ELSE
    Result := False;
END; { FileTypeSuffixFound-6 }

FUNCTION IsProgramRunning(ProgramName : String) : Boolean;
{ Checks to see if a given program is running }
VAR
  ProcHandle : THandle;
  AProcEntry : TProcessEntry32;
  TempStr : String;

BEGIN
  Result := False;

  TRY
    TempStr := '';
    ProcHandle := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS,0);
    IF ProcHandle = INVALID_HANDLE_VALUE THEN
      Exit;

    AprocEntry.dwSize :=SizeOf(TProcessEntry32);
    IF Process32First(ProcHandle, AProcEntry) THEN BEGIN
      TempStr := TempStr + (AProcEntry.szExeFile);

      WHILE Process32Next(ProcHandle,AProcEntry) DO
        TempStr := TempStr + (AProcEntry.szExeFile);
    END;

    IF Pos(UpperCase(ProgramName), UpperCase(TempStr)) > 0 THEN
      Result := True;

    CloseHandle(ProcHandle);
  EXCEPT
    ON E : Exception DO
      ShowMessage('IsProgramRunning: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END; {TRY}
END; { IsProgramRunning }

PROCEDURE TSnapsCompareForm.SnapsCompareFormCreate(Sender : TObject);
VAR
  IniFile : TRegistryIniFile;

BEGIN
  TRY
    IniFile := TRegistryIniFile.Create('FWPExplorer');

    WITH IniFile DO BEGIN
      SnapsCompareFormTop := ReadInteger(FormAlignmentSectionStr, SnapsCompareFormTopStr, DefaultSnapsCompareFormTop);
      SnapsCompareFormLeft := ReadInteger(FormAlignmentSectionStr, SnapsCompareFormLeftStr, DefaultSnapsCompareFormLeft);
      SnapsCompareFormWidth := ReadInteger(FormAlignmentSectionStr, SnapsCompareFormWidthStr, DefaultSnapsCompareFormWidth);
      SnapsCompareFormHeight := ReadInteger(FormAlignmentSectionStr, SnapsCompareFormHeightStr, DefaultSnapsCompareFormHeight);
    END; {WITH}

    IniFile.Free;

  EXCEPT
    ON E : Exception DO
      ShowMessage('EG SnapsCompareFormCreate: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END; {TRY}
END; { SnapsCompareFormCreate }

PROCEDURE TSnapsCompareForm.SnapsCompareFormClose(Sender : TObject; VAR Action : TCloseAction);
VAR
  IniFile : TRegistryIniFile;

BEGIN
  TRY
    IniFile := TRegistryIniFile.Create('FWPExplorer');

    WITH IniFile DO BEGIN
      WriteInteger(FormAlignmentSectionStr, SnapsCompareFormWidthStr, SnapsCompareForm.Width);
      WriteInteger(FormAlignmentSectionStr, SnapsCompareFormHeightStr, SnapsCompareForm.Height);
      WriteInteger(FormAlignmentSectionStr, SnapsCompareFormTopStr, SnapsCompareForm.Top);
      WriteInteger(FormAlignmentSectionStr, SnapsCompareFormLeftStr, SnapsCompareForm.Left);
    END; {WITH}

    IniFile.Free;

  EXCEPT
    ON E : Exception DO
      ShowMessage('EG SnapsCompareFormClose: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END; {TRY}
END; { SnapsCompareFormClose }

END { FWPOnlyUnit }.
