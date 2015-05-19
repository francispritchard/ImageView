UNIT ImageViewUnit;

{ Note : KeyPreview is set to True on the form as images and labels cannot receive focus and we want to spot certain keypresses }
INTERFACE

USES
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, ExtCtrls, AxCtrls, GraphUtil, Jpeg, StdCtrls;

TYPE
  TImageViewUnitForm = CLASS(TForm)
    ImageViewUnitEditPanel: TPanel;
    ImageViewUnitFileNameEdit: TEdit;
    ImageViewUnitFileNameNumbersEdit: TEdit;
    ImageViewUnitFindDialog: TFindDialog;
    ImageViewUnitStopButton: TButton;
    PROCEDURE ImageViewUnitFileNameEditEnter(Sender : TObject);
    PROCEDURE ImageViewUnitFileNameEditExit(Sender : TObject);
    PROCEDURE ImageViewUnitFileNameEditKeyDown(Sender : TObject; VAR Key : Word; ShiftState : TShiftState);
    PROCEDURE ImageViewUnitFileNameNumbersEditEnter(Sender : TObject);
    PROCEDURE ImageViewUnitFileNameNumbersEditExit(Sender : TObject);
    PROCEDURE ImageViewUnitFileNameNumbersEditKeyDown(Sender : TObject; VAR Key : Word; ShiftState : TShiftState);
    PROCEDURE ImageViewUnitFileNameNumbersEditKeyPress(Sender : TObject; VAR Key : Char);
    PROCEDURE ImageViewUnitFindDialogFind(Sender : TObject);
    PROCEDURE ImageViewUnitFormClick(Sender : TObject);
    PROCEDURE ImageViewUnitFormClose(Sender: TObject; VAR Action: TCloseAction);
    PROCEDURE ImageViewUnitFormCreate(Sender: TObject);
    PROCEDURE ImageViewUnitFormKeyDown(Sender : TObject; VAR Key : Word; ShiftState : TShiftState);
    PROCEDURE ImageViewUnitFormMouseWheel(Sender : TObject; Shift : TShiftState; WheelDelta : Integer; MousePos : TPoint; VAR Handled : Boolean);
    PROCEDURE ImageViewUnitFormShow(Sender : TObject);
    PROCEDURE ImageViewUnitStopButtonClick(Sender: TObject);
  PRIVATE
    { Private declarations }

    PROCEDURE WMVScroll(VAR Msg :TMessage); MESSAGE WM_VSCROLL;

  PUBLIC
    { Public declarations }
    PROCEDURE AppDeactivate(Sender : TObject);
    PROCEDURE MouseDownEvent(Sender : TObject; Button : TMouseButton; ShiftState : TShiftState; X, Y : Integer);
  END;

TYPE
  FileType = (Text_File, VideoFile, ImageFile, DatabaseFile, UnspecifiedFileType);

  SelectedFile_Type = RECORD
                        SelectedFile_Name : String;

                        SelectedFile_IsImageFile : Boolean;
                        SelectedFile_IsTextFile : Boolean;
                        SelectedFile_IsVideoFile : Boolean;

                        SelectedFile_HHSTR : String;
                        SelectedFile_MMSTR : String;
                        SelectedFile_SSSTR : String;

                        SelectedFile_LastMoveFrom : String;
                        SelectedFile_LastMoveTo : String;
                        SelectedFile_LastRenameFrom : String;
                        SelectedFile_LastRenameTo : String;
                        SelectedFile_NumberStr : String;
                      END;
VAR
  ImageViewUnitForm : TImageViewUnitForm;
  PathName : String;
  SelectedFileRec : SelectedFile_Type;

PROCEDURE CloseOutputFile(VAR OutputFile : Text; Filename : String); External 'ListFilesDLLProject.dll';
{ Close an output file, capturing the error message if any }

FUNCTION SnapFileNumberRename(FileName, NewNumberStr : String) : Boolean;
{ Routine for snap file renaming }

PROCEDURE StopFileLoading;
{ Allows the splash screen to interrupt the loading process }

FUNCTION OpenOutputFileOK(VAR OutputFilename : Text; Filename : String; OUT ErrorMsg : String; AppendToFile : Boolean) : Boolean; External 'ListFilesDLLProject.dll';
{ Open (and create if necessary) a file }

PROCEDURE WriteToDebugFile(DebugStr : String);
{ Open the file, write to it and then close it }

IMPLEMENTATION

{$R *.dfm}
{$WARN SYMBOL_PLATFORM OFF }

USES System.UItypes, ZoomPlayerUnit, ShellAPI, StrUtils, Registry, ImageViewSplash, System.Types, DateUtils;

FUNCTION IsProgramRunning(ProgramName : String) : Boolean; External 'ListFilesDLLProject.dll'
{ Checks to see if a given program is running }

TYPE
  SortOrderType = (Ascending, Descending);
  TypeOfSort = (SortByFileName, SortByDate, SortByLastAccess, SortByNumericSuffix, SortByType, UnknownSortType);

CONST
  AndSnapFile = True;
  ArchiveDirectoryStr = 'Archive Directory';
  DefaultUserIncrement = 200;
  DirectoriesSectionStr = 'Directories';
  HideImagesWhenMoviesPlayedTodayStr = 'Hide Images When Movies Played Today';
  MoveDirectory1Str = 'Move Directory 1';
  MoveDirectory2Str = 'Move Directory 2';
  OptionsSectionStr = 'Options';
  RedrawImages = True;

VAR
  ArchiveDirectory : String = '';
  CustomSortType : TypeOfSort;
  Editing : Boolean = False;
  EligibleFiles : Integer = 0;
  FindNextFlag : Boolean = False;
  FirstUse : Boolean = True;
  HideImagesWhenMoviesPlayedToday : Boolean = True;
  Initialised : Boolean = False;
  LastSort : TypeOfSort = UnknownSortType;
  MoveDirectory1 : String = '';
  MoveDirectory2 : String = '';
  PositionImagesFlag : Boolean = False;
  SaveFileFoundPosition : Integer;
  SaveVertSCrollBarRange : Integer = 2000;
  SortOrder : SortOrderType;
  SortStr : String = '';
  StopLoading : Boolean = False;
  TestCount : Integer = 0;
  TotalFileCount : Integer = 0;
  UserIncrement : Integer = 200;
  VLC : Boolean = False;
  WritingToDebugFile : Boolean = False;
  ZoomPlayer : Boolean = False;

PROCEDURE WriteToDebugFile(DebugStr : String);
{ Open the file, write to it and then close it }
CONST
  AppendToFile = True;

VAR
  ErrorMsg : String;
  TempFile : Text;
  TempFilename : String;

BEGIN
  IF WritingToDebugFile THEN BEGIN
    TempFilename := 'C:\temp\test file.txt';
    OpenOutputFileOK(TempFile, TempFilename, ErrorMsg, AppendToFile);
    WriteLn(TempFile, DebugStr);
    CloseOutputFile(TempFile, TempFileName);
  END;
END; { WriteToDebugFile }

PROCEDURE InitialiseSelectedFileVariables;
{ Initalisation }
BEGIN
  WITH SelectedFileRec DO BEGIN
    SelectedFile_Name := '';
    SelectedFile_NumberStr := '';
    SelectedFile_IsTextFile := False;
    SelectedFile_IsVideoFile := False;
    SelectedFile_HHSTR := '';
    SelectedFile_MMSTR := '';
    SelectedFile_SSSTR := '';
    SelectedFile_LastMoveFrom := '';
    SelectedFile_LastMoveTo := '';
    SelectedFile_LastRenameFrom := '';
    SelectedFile_LastRenameTo := '';
  END; { WITH}
END; { InitialiseSelectedFileVariables }

FUNCTION GetImageViewCaptionFileNumbers : String;
BEGIN
  Result := ' [' + IntToStr(TotalFileCount) + ' files, ' + IntToStr(EligibleFiles) + ' video files]';
END; { GetImageViewCaptionFileNumbers }

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
    END ELSE BEGIN
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

FUNCTION FindSpecificImageOnImageViewUnitForm(FileName : String) : TImage;
VAR
  Done : Boolean;
  I : Integer;

BEGIN
  Result := NIL;

  TRY
    I := 0;
    Done := False;
    WHILE (I < ImageViewUnitForm.ControlCount) AND NOT Done DO BEGIN
      IF ImageViewUnitForm.Controls[I] IS TImage THEN BEGIN
        IF TImage(ImageViewUnitForm.Controls[I]).Hint = FileName THEN BEGIN
          Result := TImage(ImageViewUnitForm.Controls[I]);
          Done := True;
        END;
      END;
      Inc(I);
    END; {WHILE}
  EXCEPT
    ON E : Exception DO
      ShowMessage('FindSpecificImageOnImageViewUnitForm: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { FindSpecificImageOnImageViewUnitForm }

FUNCTION FindSpecificLabelOnImageViewUnitForm(FileName : String) : TLabel;
VAR
  Done : Boolean;
  I : Integer;

BEGIN
  Result := NIL;

  TRY
    I := 0;
    Done := False;
    WHILE (I < ImageViewUnitForm.ControlCount) AND NOT Done DO BEGIN
      IF ImageViewUnitForm.Controls[I] IS TLabel THEN BEGIN
        IF TLabel(ImageViewUnitForm.Controls[I]).Caption = FileName THEN BEGIN
          Result := TLabel(ImageViewUnitForm.Controls[I]);
          Done := True;
        END;
      END;
      Inc(I);
    END; {WHILE}
  EXCEPT
    ON E : Exception DO
      ShowMessage('FindSpecificLabelOnImageViewUnitForm }: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { FindSpecificLabelOnImageViewUnitForm }

FUNCTION FindSpecificRectangleAroundImageViewUnitForm(FileName : String) : TShape;
VAR
  Done : Boolean;
  I : Integer;

BEGIN
  Result := NIL;

  TRY
    I := 0;
    Done := False;
    WHILE (I < ImageViewUnitForm.ControlCount) AND NOT Done DO BEGIN
      IF ImageViewUnitForm.Controls[I] IS TShape THEN BEGIN
        IF TShape(ImageViewUnitForm.Controls[I]).Hint = FileName THEN BEGIN
          Result := TShape(ImageViewUnitForm.Controls[I]);
          Done := True;
        END;
      END;
      Inc(I);
    END; {WHILE}
  EXCEPT
    ON E : Exception DO
      ShowMessage('FindSpecificRectangleAroundImageViewUnitForm: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { FindSpecificRectangleAroundImageViewUnitForm }

PROCEDURE OpenImageViewUnitEditPanel(X, Y : Integer);
{ Opens an edit panel for file renaming }
BEGIN
  TRY
    WITH SelectedFileRec DO BEGIN
      WITH ImageViewUnitForm DO BEGIN
        ImageViewUnitEditPanel.Visible := True;
        ImageViewUnitEditPanel.Left := X;
        ImageViewUnitEditPanel.Top := Y;
        ImageViewUnitEditPanel.Width := Canvas.TextWidth(SelectedFile_Name + '12345');

        ImageViewUnitFileNameEdit.Width := Canvas.TextWidth(SelectedFile_Name + '123') ;
        ImageViewUnitFileNameNumbersEdit.Width := ImageViewUnitFileNameEdit.Width;

        ImageViewUnitFileNameEdit.Visible := True;
        ImageViewUnitFileNameEdit.Text := SelectedFile_Name;
        ImageViewUnitFileNameEdit.SelStart := Length(ImageViewUnitFileNameEdit.Text);

        ImageViewUnitFileNameNumbersEdit.Text := '';
        ImageViewUnitFileNameNumbersEdit.Visible := True;

        ImageViewUnitFileNameNumbersEdit.SetFocus;

        Editing := True;
      END; {WITH}
    END; {WITH}
  EXCEPT
    ON E : Exception DO
      ShowMessage('OpenImageViewUnitPanel: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { OpenImageViewUnitEditPanel }

FUNCTION GetFileNumberSuffixFromSnapFile{1}(FileName : String; OUT IsJPEG : Boolean; OUT NumberStr : String) : Boolean; Overload;
{ Return the suffix (if any) found in an associated snap file }
VAR
  LastDotPos : Integer;
  SearchRec : TSearchRec;
  TempInt : Integer;

BEGIN
  IsJPEG := False;
  Result := False;

  IF FindFirst(PathName + 'Snaps\' + FileName + '*.*', FaAnyFile, SearchRec) = 0 THEN BEGIN
    { Find the last dot - if there are numbers after it, then we want to copy them }
    LastDotPos := LastDelimiter('.', SearchRec.Name);
    NumberStr := Copy(SearchRec.Name, LastDotPos + 1);
    IF NOT TryStrToInt(NumberStr, TempInt) THEN
      NumberStr := '';

    IF Pos('.jpg', SearchRec.Name) > 0 THEN
      IsJPEG := True;

    Result := True;
  END;
END; { GetFileNumberSuffixFromSnapFile-1 }

FUNCTION GetFileNumberSuffixFromSnapFile{2}(FileName : String; OUT NumberStr : String) : Boolean; Overload;
{ Return the suffix (if any) found in an associated snap file. This version does't return whether we've found a jpeg or not. }
VAR
  IsJPEG : Boolean;

BEGIN
  Result := GetFileNumberSuffixFromSnapFile(FileName, IsJPEG, NumberStr);
END; { GetFileNumberSuffixFromSnapFile-2 }

PROCEDURE LoadAndConvertImage(TempFileName : String; OUT Image : TImage);
VAR
  FileStream : TFileStream;
  OleGraphic : TOleGraphic;

BEGIN
  TRY
    FileStream := NIL;
    OleGraphic := NIL;

    TRY
      OleGraphic := TOleGraphic.Create;
      FileStream := TFileStream.Create(TempFileName, fmOpenRead OR fmSharedenyNone);
      OleGraphic.LoadFromStream(FileStream);
      Image.Picture.Assign(OleGraphic);
    FINALLY
      FileStream.Free;
      OleGraphic.Free
    END; {TRY}
  EXCEPT
    ON E : Exception DO
      ShowMessage('LoadAndConvertImage: ' + E.ClassName +' error raised, with message "' + E.Message + '" converting ' + TempFileName);
  END; {TRY}
END; { LoadAndConvertImage }

//PROCEDURE oldLoadAndConvertImage(TempFileName : String; OUT Image : TImage);
//VAR
//  Bitmap, NewBitmap : TBitmap;
//  FileStream : TFileStream;
//  OleGraphic : TOleGraphic;
//  Source : TImage;
//  TempDouble : Double;
//  UseOriginalImage : Boolean;
//
//BEGIN
//  TRY
//    FileStream := TFileStream.Create(TempFileName, {fmOpenRead Or} fmSharedenyNone);
//    IF FileStream <> NIL THEN BEGIN
//      OleGraphic := TOleGraphic.Create;
//
//      TRY
//        OleGraphic.LoadFromStream(FileStream);
//      EXCEPT
//        ON E : Exception DO
//          { do nothing }; //ShowMessage('OleGraphic.LoadFromStream: ' + E.ClassName +' error raised with message: ' + E.Message);
//      END;
//
//      Source := TImage.Create(NIL);
//      Source.Picture.Assign(OleGraphic);
//
//      Bitmap := TBitmap.Create; { Converting to bitmap }
//      Bitmap.Width := Source.Picture.Width;
//      Bitmap.Height := Source.Picture.Height;
//      Bitmap.Canvas.Draw(0, 0, Source.Picture.Graphic);
//      Bitmap.Modified := True;
//
//      NewBitMap := TBitmap.Create; { Converting to bitmap }
//
//      UseOriginalImage := False;
//      IF BitMap.Width = 0 THEN
//        Image.Picture.Bitmap := Bitmap
//      ELSE BEGIN
//        TempDouble := Image.Width / Bitmap.Width;
//        TRY
//          ScaleImage(Bitmap, NewBitMap, TempDouble);
//        EXCEPT
//          ON E : Exception DO BEGIN
//            { do nothing } ; // ShowMessage('ScaleImage: ' + E.ClassName +' error raised with message: ' + E.Message);
//            UseOriginalImage := True;
//          END;
//        END; {TRY}
//      END;
//
//      IF UseOriginalImage THEN
//        Image.Picture.Bitmap := Bitmap
//      ELSE
//        Image.Picture.Bitmap := NewBitmap;
//
//      FileStream.Free;
//      OleGraphic.Free;
//      Source.Free;
//      Bitmap.Free;
//      NewBitmap.Free;
//    END;
//  EXCEPT
//    ON E : Exception DO
//      ShowMessage('LoadAndConvertImage: ' + E.ClassName +' error raised, with message: ' + E.Message);
//  END;
//END; { oldLoadAndConvertImage }
//
PROCEDURE CheckImagesInView;
{ Do any images neeed to be added? }
//VAR
//  I : Integer;
//  IsJPEG : Boolean;
//  Done : Boolean;
//  Image : TImage;
//  NumberStr : String;

BEGIN
//  WITH ImageViewUnitForm DO BEGIN
//    I := 0;
//    WHILE (I < ImageViewUnitForm.ControlCount) DO BEGIN
//      IF Controls[I] IS TImage THEN BEGIN
//        WITH TImage(ImageViewUnitForm.Controls[I]) DO BEGIN
//          IF NOT Visible THEN BEGIN
//            IF PtInRect(Screen.WorkAreaRect, Point(Left, Top))
//            OR PtInRect(Screen.WorkAreaRect, Point(Left + Width, Top + Height))
//            THEN BEGIN
//              IF GetFileNumberSuffixFromSnapFile(Hint, IsJPEG, NumberStr) THEN BEGIN
//                IF IsJPEG THEN BEGIN
//                  IF NumberStr = '' THEN
//                    LoadAndConvertImage(PathName + 'Snaps\' + Hint + '.jpg', Image)
//                  ELSE;
//                    LoadAndConvertImage(PathName + 'Snaps\' + Hint + '.jpg.' + NumberStr, Image);
//                END;
//                Visible := True;
//              END;
//            END;
//          END;
//        END; {WITH}
//      END;
//      Inc(I);
//    END; {WHILE}
//  END; {WITH}
END; { CheckImagesInView }

PROCEDURE TImageViewUnitForm.ImageViewUnitFormMouseWheel(Sender : TObject; Shift : TShiftState; WheelDelta : Integer; MousePos : TPoint; VAR Handled : Boolean);
BEGIN
  WITH VertScrollBar DO BEGIN
    IF WheelDelta > 0 THEN
      Position := Position - (Increment * 2)
    ELSE
      Position := Position + (Increment * 2)
  END; {WITH}

  CheckImagesInView;
END; { ImageViewUnitFormMouseWheel }

PROCEDURE TImageViewUnitForm.ImageViewUnitFormCreate(Sender: TObject);

  PROCEDURE CheckParameter(Parameter : String; ParameterPos : Integer; OUT Str : String);
  VAR
    StrPos : Integer;

  BEGIN
    StrPos := Pos(UpperCase(Parameter), UpperCase(ParamStr(ParameterPos)));
    IF StrPos > 0 THEN
      Str := UpperCase(Copy(ParamStr(ParameterPos), Length(Parameter) + 1))
    ELSE BEGIN
      ShowMessage('No ' + Parameter + ' parameter specified in command line "' + CmdLine + '" - press OK to exit');
      Application.Terminate;
    END;
  END; { CheckParameter }

VAR
  IniFile : TRegistryIniFile;
  UserIncrementStr : String;

BEGIN
  TRY
    CheckParameter('/DIR=', 1, PathName);
    CheckParameter('/ARCHIVE=', 2, ArchiveDirectory);
    CheckParameter('/MOVE1=', 3, MoveDirectory1);
    CheckParameter('/MOVE2=', 4, MoveDirectory2);
    CheckParameter('/SORT=', 5, SortStr);
    CheckParameter('/INCREMENT=', 6, UserIncrementStr);

// for AQTime only
//PathName := 'C:\TEMP5\';
//ArchiveDirectory := 'C:\TEMP';
//MoveDirectory1 := '';
//MoveDirectory2 := '';
//SortStr := 'TYPESORT'; { needs to be u/c }

    IF UserIncrementStr = '' THEN
      UserIncrement := DefaultUserIncrement
    ELSE
      IF NOT TryStrToInt(UserIncrementStr, UserIncrement) THEN BEGIN
        ShowMessage('"' + UserIncrementStr + '" is not a valid increment - increment set to default ' + IntToStr(DefaultUserIncrement));
        UserIncrement := DefaultUserIncrement;
      END;

    { Note - we use the FWPEXplorer registry entry to share directory information }
    IniFile := TRegistryIniFile.Create('FWPExplorer');

    WITH IniFile DO BEGIN
      { Directories }
      IF ArchiveDirectory = '' THEN
        ArchiveDirectory := ReadString(DirectoriesSectionStr, ArchiveDirectoryStr, '');
      IF MoveDirectory1 = '' THEN
        MoveDirectory1 := ReadString(DirectoriesSectionStr, MoveDirectory1Str, '');
      IF MoveDirectory2 = '' THEN
        MoveDirectory2 := ReadString(DirectoriesSectionStr, MoveDirectory2Str, '');
      HideImagesWhenMoviesPlayedToday := ReadBool(OptionsSectionStr, HideImagesWhenMoviesPlayedTodayStr, False);
    END; {WITH}
  EXCEPT
    ON E : Exception DO
      ShowMessage('ImageViewUnitFormCreate: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { ImageViewUnitFormCreate }

PROCEDURE TImageViewUnitForm.ImageViewUnitFormClose(Sender: TObject; VAR Action: TCloseAction);
VAR
  IniFile : TRegistryIniFile;

BEGIN
  TRY
    { Note - we use the FWPEXplorer registry entry to share directory information }
    IniFile := TRegistryIniFile.Create('FWPExplorer');

    WITH IniFile DO BEGIN
      { Directories }
      WriteString(DirectoriesSectionStr, ArchiveDirectoryStr, ArchiveDirectory);
      WriteString(DirectoriesSectionStr, MoveDirectory1Str, MoveDirectory1);
      WriteString(DirectoriesSectionStr, MoveDirectory2Str, MoveDirectory2);
      WriteBool(OptionsSectionStr, HideImagesWhenMoviesPlayedTodayStr, HideImagesWhenMoviesPlayedToday);
    END; {WITH}
    IniFile.Free;

    Action := caFree;
  EXCEPT
    ON E : Exception DO
      ShowMessage('ExplorerFormClose: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END; {TRY}
END; { ImageViewUnitFormClose }

PROCEDURE TImageViewUnitForm.ImageViewUnitFileNameEditEnter(Sender : TObject);
BEGIN
  { this is added to get rid of the annoying beep }
  ImageViewUnitFileNameEdit.ReadOnly := False;
END; { ImageViewUnitFileNameEditEnter }

PROCEDURE TImageViewUnitForm.ImageViewUnitFileNameEditExit(Sender : TObject);
BEGIN
  { this is added to get rid of the annoying beep }
  ImageViewUnitFileNameEdit.ReadOnly := True;
END; { ImageViewUnitFileNameEditExit }

FUNCTION SnapFileNumberRename(FileName, NewNumberStr : String) : Boolean;
{ Routine for snap file renaming }
VAR
  Done : Boolean;
  I : Integer;
  OK : Boolean;
  OldNumberStr : String;

BEGIN
  Result := False;

  TRY
    IF NOT GetFileNumberSuffixFromSnapFile(FileName, OldNumberStr) THEN
      { we need to create a .txt file +++ }
      ShowMessage('No snaps file found to match "' + FileName + '"')
    ELSE BEGIN
      IF NewNumberStr = '0' THEN
        NewNumberStr := '';

      OK := False;

      IF FileExists(PathName + 'Snaps\' + FileName + '.txt.' + OldNumberStr) THEN
        IF RenameFile(PathName + 'Snaps\' + FileName + '.txt.' + OldNumberStr, PathName + 'Snaps\' + FileName + '.txt.' + NewNumberStr) THEN
          OK := True
        ELSE
          ShowMessage('Error ' + IntToStr(GetLastError) + ' in renaming file ''' + PathName + 'Snaps\' + FileName + '.txt.' + OldNumberStr
                      + ''' to ''' + PathName + 'Snaps\' + FileName + '.txt.' + NewNumberStr);

      IF FileExists(PathName + 'Snaps\' + FileName + '.jpg.' + OldNumberStr) THEN
        IF RenameFile(PathName + 'Snaps\' + FileName + '.jpg.' + OldNumberStr, PathName + 'Snaps\' + FileName + '.jpg.' + NewNumberStr) THEN
          OK := True
        ELSE
          ShowMessage('Error ' + IntToStr(GetLastError) + ' in renaming file ''' + PathName + 'Snaps\' + FileName + '.jpg.' + OldNumberStr
                      + ''' to ''' + PathName + 'Snaps\' + FileName + '.jpg.' + NewNumberStr);

      IF OK THEN BEGIN
        Result := True;

        WITH ImageViewUnitForm DO BEGIN
          { and change the image's label }
          I := 0;
          Done := False;
          WHILE (I < ImageViewUnitForm.ControlCount) AND NOT Done DO BEGIN
            IF Controls[I] IS TLabel THEN BEGIN
              IF (TLabel(ImageViewUnitForm.Controls[I]).Caption = FileName)
              OR (TLabel(ImageViewUnitForm.Controls[I]).Caption = FileName + '.' + OldNumberStr)
              THEN BEGIN
                Done := True;
                IF NewNumberStr = '' THEN
                  TLabel(ImageViewUnitForm.Controls[I]).Caption := FileName
                ELSE
                  TLabel(ImageViewUnitForm.Controls[I]).Caption := FileName + '.' + NewNumberStr;
              END;
            END;
            Inc(I);
          END; {WHILE}
        END; {WITH}
      END;
    END;
  EXCEPT
    ON E : Exception DO
      ShowMessage('FileNameRename: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { SnapFileNumberRename }

FUNCTION FileRenameProc(NewPathName, NewFileName : String) : Boolean;
{ Main routine for file renaming }
VAR
  Done : Boolean;
  I : Integer;
  IsJPEG : Boolean;
  JpgOrTxtStr : String;
  NumberStr : String;
  OldSnapFileName : String;

BEGIN
  Result := False;

  TRY
    WITH SelectedFileRec DO BEGIN
      IF NOT GetFileNumberSuffixFromSnapFile(SelectedFile_Name, IsJPEG, NumberStr) THEN
        ShowMessage('No corresponding snap file found for ' + SelectedFile_Name + ' - cannot rename file')
      ELSE BEGIN
        IF NOT RenameFile(PathName + SelectedFile_Name, NewPathName + NewFileName) THEN
          ShowMessage('Error ' + IntToStr(GetLastError) + ' in renaming file ''' + PathName + SelectedFile_Name
                      + ''' to ''' + NewPathName + NewFileName + ''' - ' + SysErrorMessage(GetLastError))
        ELSE BEGIN
          SelectedFile_LastRenameTo := NewPathName + NewFileName;
          SelectedFile_LastRenameFrom := PathName + SelectedFile_Name;

          OldSnapFileName := SelectedFile_Name;
          SelectedFile_Name := NewFileName;

          { The snap file needs to be renamed too }
          GetFileNumberSuffixFromSnapFile(OldSnapFileName, IsJPEG, NumberStr);

          IF IsJPEG THEN
            JpgOrTxtStr := 'jpg'
          ELSE
            JpgOrTxtStr := 'txt';

          IF NumberStr = '' THEN BEGIN
            IF NOT RenameFile(PathName + 'Snaps\' + OldSnapFileName + '.' + JpgORTxtStr,
                              NewPathName + 'Snaps\' + NewFileName  + '.' + JpgORTxtStr)
            THEN
              ShowMessage('Error ' + IntToStr(GetLastError) + ' in renaming file ''' + PathName + 'Snaps\' + OldSnapFileName + '.' + JpgORTxtStr
                          + ''' to ''' + NewPathName + 'Snaps\' + NewFileName  + '.' + JpgORTxtStr);
          END ELSE BEGIN
            IF NOT RenameFile(PathName + 'Snaps\' + OldSnapFileName + '.' + JpgORTxtStr + '.' + NumberStr,
                              NewPathName + 'Snaps\' + NewFileName  + '.' + JpgORTxtStr + '.' + NumberStr)
            THEN
              ShowMessage('Error ' + IntToStr(GetLastError) + ' in renaming file ''' + PathName + 'Snaps\' + OldSnapFileName + '.' + JpgORTxtStr + '.' + NumberStr
                          + ''' to ''' + NewPathName + 'Snaps\' + NewFileName  + '.' + JpgORTxtStr + '.' + NumberStr);
          END;

          { Finally, see if the filename behind the image in the ImageViewUnitForm needs to be renamed too }
          IF Assigned(ImageViewUnitForm) AND ImageViewUnitForm.Visible THEN BEGIN
            WITH ImageViewUnitForm DO BEGIN
              I := 0;
              Done := False;
              WHILE (I < ImageViewUnitForm.ControlCount) AND NOT Done DO BEGIN
                IF Controls[I] IS TImage THEN BEGIN
                  IF TImage(ImageViewUnitForm.Controls[I]).Hint = OldSnapFileName THEN BEGIN
                    Done := True;
                    TImage(ImageViewUnitForm.Controls[I]).Hint := NewFileName;
                  END;
                END;
                Inc(I);
              END; {WHILE}

              { and the image's label }
              I := 0;
              Done := False;
              WHILE (I < ImageViewUnitForm.ControlCount) AND NOT Done DO BEGIN
                IF Controls[I] IS TLabel THEN BEGIN
                  IF TLabel(ImageViewUnitForm.Controls[I]).Caption = OldSnapFileName THEN BEGIN
                    Done := True;
                    TLabel(ImageViewUnitForm.Controls[I]).Caption := NewFileName;
                  END ELSE
                    IF TLabel(ImageViewUnitForm.Controls[I]).Caption = OldSnapFileName + '.' + NumberStr THEN BEGIN
                      Done := True;
                      TLabel(ImageViewUnitForm.Controls[I]).Caption := NewFileName + '.' + NumberStr;
                    END;
                END;
                Inc(I);
              END; {WHILE}

              { and also the image's focus rectangle }
              I := 0;
              Done := False;
              WHILE (I < ImageViewUnitForm.ControlCount) AND NOT Done DO BEGIN
                IF Controls[I] IS TShape THEN BEGIN
                  IF TShape(ImageViewUnitForm.Controls[I]).Hint = OldSnapFileName THEN BEGIN
                    Done := True;
                    TShape(ImageViewUnitForm.Controls[I]).Hint := NewFileName;
                  END;
                END;
                Inc(I);
              END; {WHILE}
            END; {WITH}
          END;

          Result := True;
        END;
      END;
    END; {WITH}
  EXCEPT
    ON E : Exception DO
      ShowMessage('FileRenameProc: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { FileRenameProc }

PROCEDURE TImageViewUnitForm.ImageViewUnitFileNameEditKeyDown(Sender : TObject; VAR Key : Word; ShiftState : TShiftState);
BEGIN
  TRY
    WITH SelectedFileRec DO BEGIN
      IF Key = vk_Return THEN BEGIN
        IF ImageViewUnitFileNameEdit.Text = SelectedFile_Name THEN
          ShowMessage('File name is the same')
        ELSE
          FileRenameProc(PathName, ImageViewUnitFileNameEdit.Text);
      END;

      IF (Key = vk_Escape) OR (Key = vk_Return) THEN BEGIN
        ImageViewUnitEditPanel.Visible := False;

        ImageViewUnitFileNameEdit.Visible := False;
        ImageViewUnitFileNameEdit.Text := '';

        ImageViewUnitFileNameNumbersEdit.Text := '';
        ImageViewUnitFileNameNumbersEdit.Visible := False;

        Editing := False;
      END;
    END; {WITH}
  EXCEPT
    ON E : Exception DO
      ShowMessage('ImageViewUnitFileNameEditKeyDown: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { ImageViewUnitFileNameEditKeyDown }

PROCEDURE TImageViewUnitForm.ImageViewUnitFileNameNumbersEditEnter(Sender : TObject);
BEGIN
  { this is added to get rid of the annoying beep }
  ImageViewUnitFileNameNumbersEdit.ReadOnly := False;
END; { ImageViewUnitFileNameNumbersEditEnter }

PROCEDURE TImageViewUnitForm.ImageViewUnitFileNameNumbersEditExit(Sender : TObject);
BEGIN
  { this is added to get rid of the annoying beep }
  ImageViewUnitFileNameNumbersEdit.ReadOnly := True;
END; { ImageViewUnitFileNameNumbersEditExit }

PROCEDURE TImageViewUnitForm.ImageViewUnitFileNameNumbersEditKeyDown(Sender : TObject; VAR Key : Word; ShiftState : TShiftState);
VAR
  OldNumberStr : String;

BEGIN
  TRY
    WITH SelectedFileRec DO BEGIN
      IF Key = vk_Return THEN BEGIN
        IF ImageViewUnitFileNameNumbersEdit.Text = '' THEN
          { do nothing }
        ELSE BEGIN
          IF ImageViewUnitFileNameNumbersEdit.Text = '0' THEN
            { remove the numbers }
            SnapFileNumberRename(SelectedFile_Name, '')
          ELSE BEGIN
            GetFileNumberSuffixFromSnapFile(SelectedFile_Name, OldNumberStr);
            IF PathName + 'Snaps\' + SelectedFile_Name + '.jpg.' + OldNumberStr = PathName + 'Snaps\' + SelectedFile_Name + '.jpg.' + ImageViewUnitFileNameNumbersEdit.Text
            THEN
              ShowMessage('File name is the same')
            ELSE
              SnapFileNumberRename(SelectedFile_Name, ImageViewUnitFileNameNumbersEdit.Text);
          END;
        END;
      END;

      IF (Key = vk_Escape) OR (Key = vk_Return) THEN BEGIN
        ImageViewUnitEditPanel.Visible := False;

        ImageViewUnitFileNameNumbersEdit.Visible := False;
        ImageViewUnitFileNameNumbersEdit.Text := '';

        ImageViewUnitFileNameEdit.Visible := False;
        ImageViewUnitFileNameEdit.Text := '';

        Editing := False;
      END;
    END; {WITH}
  EXCEPT
    ON E : Exception DO
      ShowMessage('ImageViewUnitFileNameNumbersEditKeyDown: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { ImageViewUnitFileNameNumbersEditKeyDown }

PROCEDURE FileNameNumbersEditKeyPress(VAR Key: Char);
{ Only permits numeric key presses in the lower edit box }
BEGIN
  CASE Key OF
    '0'..'9', Chr(vk_Back):
  ELSE
    Key := #0;
  END; {CASE}
END; { FileNameNumbersEditKeyPress }

PROCEDURE TImageViewUnitForm.ImageViewUnitFileNameNumbersEditKeyPress(Sender : TObject; VAR Key : Char);
{ Only permits numeric key presses in the lower edit box }
BEGIN
  FileNameNumbersEditKeyPress(Key);
END; { ImageViewUnitFileNameNumbersEditKeyPress }

FUNCTION SelectedFileRecRectangleVisibilityIsOn(FileName : String) : Boolean;
VAR
  TempRectangle : TShape;

BEGIN
  Result := False;

  TRY
    TempRectangle := FindSpecificRectangleAroundImageViewUnitForm(FileName);
    IF Assigned(TempRectangle) THEN
      IF TempRectangle.Visible = True THEN
        Result := True;
  EXCEPT
    ON E : Exception DO
      ShowMessage('SelectedFileRecRectangleVisibilityIsOn: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { SelectedFileRecRectangleVisibilityIsOn }

PROCEDURE TurnAllRectanglesVisibilityOff;
VAR
  I : Integer;

BEGIN
  TRY
    I := 0;
    WHILE I < ImageViewUnitForm.ControlCount DO BEGIN
      IF ImageViewUnitForm.Controls[I] IS TShape THEN
        TShape(ImageViewUnitForm.Controls[I]).Visible := False;
      Inc(I);
    END; {WHILE}
  EXCEPT
    ON E : Exception DO
      ShowMessage('TurnAllRectanglesVisibilityOff: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { TurnAllRectanglesVisibilityOff }

FUNCTION TurnSelectedFileRecRectangleVisibilityOn(FileName : String) : Boolean;
VAR
  TempRectangle : TShape;

BEGIN
  Result := False;
  TRY
    TurnAllRectanglesVisibilityOff;

    IF ImageViewUnitForm.ImageViewUnitEditPanel.Visible THEN
      ImageViewUnitForm.ImageViewUnitEditPanel.Hide;

    TempRectangle := FindSpecificRectangleAroundImageViewUnitForm(FileName);
    IF Assigned(TempRectangle) THEN BEGIN
      TempRectangle.Visible := True;
      Result := True;
    END;
  EXCEPT
    ON E : Exception DO
      ShowMessage('TurnSelectedFileRecRectangleVisibilityOn: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { TurnSelectedFileRecRectangleVisibilityOn }

PROCEDURE TImageViewUnitForm.ImageViewUnitFormClick(Sender : TObject);
{ We come here if we don't click on an image or a label - we then forget the chosen file }
BEGIN
  TRY
writetodebugfile('form click');
    TurnAllRectanglesVisibilityOff;
//    InitialiseSelectedFileVariables;
  EXCEPT
    ON E : Exception DO
      ShowMessage('ImageViewUnitFormClick: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { ImageViewUnitFormClick }

FUNCTION IsDirectory(Attr : Integer) : Boolean;
{ Return whether a given attribute indicates a directory }
TYPE
  TFileAttr = RECORD
    szAttrName : String;
    iAttr : Integer;
  END; {RECORD}

CONST
  AttrFileAttr: ARRAY[0..9] OF TFileAttr = (
      (szAttrName: 'r'; iAttr: FILE_ATTRIBUTE_READONLY),
      (szAttrName: 'h'; iAttr: FILE_ATTRIBUTE_HIDDEN),
      (szAttrName: 's'; iAttr: FILE_ATTRIBUTE_SYSTEM),
      (szAttrName: 'd'; iAttr: FILE_ATTRIBUTE_DIRECTORY),
      (szAttrName: 'a'; iAttr: FILE_ATTRIBUTE_ARCHIVE),
      (szAttrName: 't'; iAttr: FILE_ATTRIBUTE_TEMPORARY),
      (szAttrName: 'p'; iAttr: FILE_ATTRIBUTE_SPARSE_FILE),
      (szAttrName: 'l'; iAttr: FILE_ATTRIBUTE_REPARSE_POINT),
      (szAttrName: 'c'; iAttr: FILE_ATTRIBUTE_COMPRESSED),
      (szAttrName: 'e'; iAttr: FILE_ATTRIBUTE_ENCRYPTED)
      );
VAR
  I :Integer;

BEGIN
  { Set Result to an empty String }
  Result := False;

  TRY
    I := 3; { FILE_ATTRIBUTE_DIRECTORY }
    { Check Attribute of file in question by using 'and' bit operation with our file attribute structure }
    IF Attr AND AttrFileAttr[I].iAttr = AttrFileAttr[I].iAttr THEN
      Result := True;
  EXCEPT
    ON E : Exception DO
      ShowMessage('IsDirectory: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END; {TRY}
END; { IsDirectory }

PROCEDURE GetHHMMSS(TempFileName, NumberStr : String; OUT HHStr, MMStr, SSStr : String; OUT IsTextFile, IsImageFile, IsVideoFile : Boolean; OUT OK : Boolean);
VAR
  TypeOfFile : FileType;

BEGIN
  TRY
    WITH SelectedFileRec DO BEGIN
      HHStr := '00';
      MMStr := '00';
      SSStr := '00';
      IsImageFile := False;
      IsTextFile := False;
      IsVideoFile := False;

      IF NOT FileTypeSuffixFound(TempFileName, TypeOfFile) THEN
        OK := False
      ELSE
        IF TypeOfFile = Text_File THEN
          IsTextFile := True
        ELSE
          IF TypeOfFile = ImageFile THEN
            IsImageFile := True
          ELSE
            IF TypeOfFile = VideoFile THEN BEGIN
              IsVideoFile := True;

              IF Pos('vlc', LowerCase(TempFileName)) > 0 THEN BEGIN
                VLC := True;
                ZoomPlayer := False;
              END ELSE BEGIN
                ZoomPlayer := True;
                VLC := False;
              END;

              OK := True;

              IF Pos('.mp4', LowerCase(TempFileName)) <> 0 THEN
                NumberStr := ''
              ELSE BEGIN
                IF Length(NumberStr) = 6 THEN BEGIN
                  { must be HH MM SS }
                  HHStr := Copy(NumberStr, 1, 2);
                  MMStr := Copy(NumberStr, 3, 2);
                  SSStr := Copy(NumberStr, 5, 2);
                END ELSE
                  IF Length(NumberStr) = 5 THEN BEGIN
                    { must be H MM SS }
                    HHStr := '0' + Copy(NumberStr, 1, 1);
                    MMStr := Copy(NumberStr, 2, 2);
                    SSStr := Copy(NumberStr, 4, 2);
                  END ELSE
                    IF Length(NumberStr) = 4 THEN BEGIN
                      { must be MM SS }
                      HHStr := '00';
                      MMStr := Copy(NumberStr, 1, 2);
                      SSStr := Copy(NumberStr, 3, 2);
                    END ELSE
                      IF Length(NumberStr) = 3 THEN BEGIN
                        { could be MM SS but if it starts with a "1" it is more likely to be HH MM }
                        IF Copy(NumberStr, 1, 1) = '1' THEN BEGIN
                          HHStr := '0' + Copy(NumberStr, 1, 1);
                          MMStr := Copy(NumberStr, 2, 2);
                          SSStr := '00';
                        END ELSE BEGIN
                          HHStr := '00';
                          MMStr := '0' + Copy(NumberStr, 1, 1);
                          SSStr := Copy(NumberStr, 2, 2);
                        END;
                      END ELSE
                        IF Length(NumberStr) = 2 THEN BEGIN
                          { can only be MM }
                          HHStr := '00';
                          MMStr := NumberStr;
                          SSStr := '00';
                        END ELSE
                          IF Length(NumberStr) = 1 THEN BEGIN
                            { can only be M }
                            HHStr := '00';
                            MMStr := '0' + NumberStr;
                            SSStr := '00';
                          END;
            END;

            IF (HHStr > '12') OR (MMStr > '59') THEN BEGIN
              ShowMessage('Invalid time - ' + HHStr + ' :' + MMStr);
              HHStr := '00';
              MMStr := '00'
            END;
          END;

    END; {WITH}
  EXCEPT
    ON E : Exception DO
      ShowMessage('GetHHMMSS: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END; {TRY}
END; { GetHHMMSS }

PROCEDURE TImageViewUnitForm.MouseDownEvent(Sender : TObject; Button : TMouseButton; ShiftState : TShiftState; X, Y : Integer);

  FUNCTION GetFileNumberSuffixFromSnapFile(FileName : String; OUT NumberStr : String) : Boolean;
  { Return the suffix (if any) found in an associated snap file }
  VAR
    LastDotPos : Integer;
    SearchRec : TSearchRec;
    TempInt : Integer;

  BEGIN
    Result := False;

    IF FindFirst(PathName + 'Snaps\' + FileName + '*.*', FaAnyFile, SearchRec) = 0 THEN BEGIN
      { Find the last dot - if there are numbers after it, then we want to copy them }
      LastDotPos := LastDelimiter('.', SearchRec.Name);
      NumberStr := Copy(SearchRec.Name, LastDotPos + 1);
      IF NOT TryStrToInt(NumberStr, TempInt) THEN
        NumberStr := '';

      Result := True;
    END;
  END; { GetFileNumberSuffixFromSnapFile }

  PROCEDURE PrepareFiles(PathName, TempFileName : String);
  VAR
    HH : Word;
    Minutes : Word;
    MM : Word;
    MSS : Word;
    OK : Boolean;
    ShellStr : WideString;
    ShellStrPtr : PWideChar;
    SS : Word;
    StartTime : TDateTime;
    TempImage : TImage;

  BEGIN
    TRY
writetodebugfile('entering PrepareFiles');
      WITH SelectedFileRec DO BEGIN
        IF SelectedFile_IsTextFile THEN BEGIN
          IF NOT IsProgramRunning('epsilon') THEN
            ShellStr := '"' + PathName + TempFileName + '" '
          ELSE
            ShellStr := ' -add -rkill-current-buffer' + ' "' + PathName + TempFileName + '" ';

          ShellStrPtr := Addr(ShellStr[1]);

          ShellExecute(ImageViewUnitForm.Handle,
                       'open',
                       '"C :\Program Files (x86)\Eps13\bin\epsilon.exe"',
                       ShellStrPtr,
                       NIL,
                       SW_SHOWNORMAL);
        END ELSE
          IF SelectedFile_IsImageFile THEN BEGIN
            ShellStr := '"' + PathName + TempFileName + '" '
                        + ' /one /bf /resample';

            ShellStrPtr := Addr(ShellStr[1]);

            ShellExecute(ImageViewUnitForm.Handle,
                         'open',
                         '"C :\Program Files (x86)\IrfanView\i_view32.exe"',
                         ShellStrPtr,
                         NIL,
                         SW_SHOWNORMAL);
          END ELSE BEGIN
writetodebugfile('launching zoom player');
            StartTime := EncodeTime(StrToInt(SelectedFile_HHStr), StrToInt(SelectedFile_MMStr), StrToInt(SelectedFile_SSStr), 0);
            DecodeTime(StartTime, HH, MM, SS, MSS);
            IF ZoomPlayer THEN BEGIN
              ShellStr := '/seek:' + SelectedFile_HHStr + ':' + SelectedFile_MMStr + ':' + SelectedFile_SSStr + ' "' + PathName + TempFileName + '" '
                          + '/Max' + ' /MouseOff';

              ShellStrPtr := Addr(ShellStr[1]);
              WriteToDebugFile('executing Zoom Player command: ' + ShellStr);
              ShellExecute(ImageViewUnitForm.Handle,
                           'open',
                           '"C:\Program Files (x86)\Zoom Player\zplayer.exe"',
                           ShellStrPtr,
                           NIL,
                           SW_SHOWNORMAL);
              OK := True;

              REPEAT
                { This needs a timeout, as do the other ProcessMessages **** }
                Application.ProcessMessages;
              UNTIL IsProgramRunning('zplayer.exe');

              ZoomPlayerUnitForm.CreateZoomPlayerTCPClient(OK);

              IF OK AND HideImagesWhenMoviesPlayedToday THEN BEGIN
                TempImage := FindSpecificImageOnImageViewUnitForm(TempFileName);
                TempImage.Visible := False;
              END;
writetodebugfile('launched zoom player');
            END ELSE
              IF VLC THEN BEGIN
                Minutes := (HH * 60) + (MM * 60);
                ShellStr := '"' + PathName + TempFileName + '"'
                            + ' --start-time=' + IntToStr(Minutes)
                            + ' --no-video-title-show'
                            + ' -f -vvv';

                ShellStrPtr := Addr(ShellStr[1]);

                ShellExecute(ImageViewUnitForm.Handle,
                             'open',
                             '"C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"',
                             ShellStrPtr,
                             NIL,
                             SW_SHOWNORMAL);

                { Open the edit panel when VLC stops }
                REPEAT
                  Application.ProcessMessages;
                UNTIL IsProgramRunning('VLC') = False;
              END;
          END;
      END; {WITH}
writetodebugfile('exiting PrepareFiles');
    EXCEPT
      ON E : Exception DO
        ShowMessage('PrepareFiles: ' + E.ClassName +' error raised, with message: ' + E.Message);
    END; {TRY}
  END; { PrepareFiles }

  PROCEDURE TakeSnapWithVLC(PathName, FileName, StartTimeInSecondsStr, StopTimeInSecondsStr : String; OUT TimedOut : Boolean);
  { Press the camera shutter }
  VAR
    OutputFileName : String;
    ShellStr : WideString;
    ShellStrPtr : PWideChar;
    StartTimer : Cardinal;
    TickCount : Cardinal;

  BEGIN
    TRY
      StartTimer := GetTickCount();
      TimedOut := False;

      IF Assigned(ImageViewUnitForm) AND (ImageViewUnitForm.Visible) THEN
        { does this ever happen? **** }
        ImageViewUnitForm.Caption := 'Taking snap of "' + PathName + FileName + '" from ' + StartTimeInSecondsStr + ' to ' + StopTimeInSecondsStr + ' seconds';

      ShellStr := '"' + PathName + FileName + '"'
                  + ' --qt-start-minimized'
                  + ' --rate=1 --video-filter=scene'
                  + ' --vout=dummy'
                  + ' --aout=dummy'
                  + ' --start-time=' + StartTimeInSecondsStr
                  + ' --stop-time=' + StopTimeInSecondsStr
                  + ' --scene-format=jpg'
                  + ' --scene-ratio=25'
                  + ' --scene-prefix="' + FileName + '"'
                  + ' --scene-replace'
                  + ' --scene-path="' + PathName + 'Snaps" vlc://quit';
      ShellStrPtr := Addr(ShellStr[1]);

      REPEAT
        { This stops many multiple instances of vlc.exe running simultaneously }
        Application.ProcessMessages;
      UNTIL IsProgramRunning('VLC') = False;

      ShellExecute(Application.Handle,
                   'open',
                   '"C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"',
                   ShellStrPtr,
                   nil,
                   SW_SHOWNORMAL);

      REPEAT
        { This provides a time out }
        TickCount := (GetTickCount - StartTimer);
        IF TickCount > (60000) THEN
          TimedOut := True;
        Application.ProcessMessages;
      UNTIL (IsProgramRunning('VLC') = False) OR TimedOut;

      IF Assigned(ImageViewUnitForm) AND (ImageViewUnitForm.Visible) THEN
        ImageViewUnitForm.Caption := 'Snap taken of "' + PathName + FileName + '" saved as "' + OutputFileName + '"';
    EXCEPT
      ON E : Exception DO
        ShowMessage('TakeSnapWithVLC: ' + E.ClassName +' error raised, with message: ' + E.Message + ' for snap of "' + FileName + '"');
    END; {TRY}
  END; { TakeSnapWithVLC }

VAR
  NumberStr : String;
  OK : Boolean;
  SaveCursor : TCursor;
  TempImage : TImage;
  TimedOut : Boolean;

BEGIN
  TRY
    WITH SelectedFileRec DO BEGIN
      InitialiseSelectedFileVariables;

      IF Sender IS TImage THEN
        SelectedFile_Name := TImage(Sender).Hint
      ELSE
        IF Sender IS TShape THEN
          SelectedFile_Name := TShape(Sender).Hint
        ELSE
          IF Sender IS TLabel THEN
            SelectedFile_Name := TLabel(Sender).Hint;

      IF SelectedFile_Name = '' THEN
        ImageViewUnitForm.Caption := ''
      ELSE BEGIN
        GetFileNumberSuffixFromSnapFile(SelectedFile_Name, NumberStr);
        GetHHMMSS(SelectedFile_Name, NumberStr, SelectedFile_HHStr, SelectedFile_MMStr, SelectedFile_SSStr, SelectedFile_IsTextFile, SelectedFile_IsImageFile,
                  SelectedFile_IsVideoFile, OK);
        ImageViewUnitForm.Caption := SelectedFile_Name + '.' + NumberStr;

        CASE Button OF
          mbLeft :
            IF ssShift IN ShiftState THEN BEGIN
              { we need a replacement image - this takes some time so show the hourglass }
              SaveCursor := Screen.Cursor;
              Screen.Cursor := crHourGlass;
              TakeSnapWithVLC(PathName, SelectedFile_Name, '60', '65', TimedOut);
              REPEAT
                { This waits until VLC has stopped running, or else we load the old image }
                Application.ProcessMessages;
              UNTIL IsProgramRunning('VLC') = False;

              Screen.Cursor := SaveCursor;

              TempImage := FindSpecificImageOnImageViewUnitForm(SelectedFile_Name);
              LoadAndConvertImage(PathName + 'Snaps\' + SelectedFile_Name + '.jpg', TempImage); { +++ }
            END ELSE
              IF NOT (ssCtrl IN ShiftState) THEN BEGIN
                { the default }
                TurnSelectedFileRecRectangleVisibilityOn(SelectedFile_Name);
                PrepareFiles(PathName, SelectedFile_Name);
              END ELSE BEGIN
                { we need a replacement image - this takes some time so show the hourglass }
                SaveCursor := Screen.Cursor;
                Screen.Cursor := crHourGlass;
                TakeSnapWithVLC(PathName, SelectedFile_Name, '120', '125', TimedOut);
                REPEAT
                  { This waits until VLC has stopped running, or else we load the old image }
                  Application.ProcessMessages;
                UNTIL IsProgramRunning('VLC') = False;

                Screen.Cursor := SaveCursor;

                TempImage := FindSpecificImageOnImageViewUnitForm(SelectedFile_Name);
                LoadAndConvertImage(PathName + 'Snaps\' + SelectedFile_Name + '.jpg', TempImage); { +++ }
              END;

          mbRight :
            BEGIN
              IF NOT SelectedFileRecRectangleVisibilityIsOn(SelectedFile_Name) THEN
                TurnSelectedFileRecRectangleVisibilityOn(SelectedFile_Name)
              ELSE BEGIN
                TurnAllRectanglesVisibilityOff;

                ImageViewUnitForm.Caption := PathName + GetImageViewCaptionFileNumbers;
              END;
            END;
        END; {CASE}
      END;
    END; {WITH}
  EXCEPT
    ON E : Exception DO
      ShowMessage('MouseDownEvent: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { MouseDownEvent }

PROCEDURE TImageViewUnitForm.ImageViewUnitFindDialogFind(Sender : TObject);
VAR
  FoundFileName : String;
  I : Integer;

BEGIN
  FoundFileName := '';

  IF FindNextFlag THEN
    I := SaveFileFoundPosition + 1
  ELSE
    I := 0;
  FindNextFlag := False;

  WHILE (I < ImageViewUnitForm.ControlCount) AND (FoundFileName = '') DO BEGIN
    IF ImageViewUnitForm.Controls[I] IS TImage THEN BEGIN
      IF frWholeWord IN ImageViewUnitFindDialog.Options THEN BEGIN
        IF frMatchCase IN ImageViewUnitFindDialog.Options THEN BEGIN
          IF ImageViewUnitFindDialog.FindText = ImageViewUnitForm.Controls[I].Hint THEN
            { whole word and match case }
            FoundFileName := ImageViewUnitForm.Controls[I].Hint;
        END ELSE BEGIN
          IF UpperCase(ImageViewUnitFindDialog.FindText) = UpperCase(ImageViewUnitForm.Controls[I].Hint) THEN
            { whole word and not match case }
            FoundFileName := ImageViewUnitForm.Controls[I].Hint;
        END;
      END ELSE BEGIN
        IF frMatchCase IN ImageViewUnitFindDialog.Options THEN BEGIN
          IF Pos(ImageViewUnitFindDialog.FindText, ImageViewUnitForm.Controls[I].Hint) > 0 THEN
            { not whole word and match case }
            FoundFileName := ImageViewUnitForm.Controls[I].Hint;
        END ELSE BEGIN
          IF Pos(UpperCase(ImageViewUnitFindDialog.FindText), UpperCase(ImageViewUnitForm.Controls[I].Hint)) > 0 THEN
            { not whole word and not match case }
            FoundFileName := ImageViewUnitForm.Controls[I].Hint;
        END;
      END;
    END;

    Inc(I);
  END; {WHILE}

  TurnAllRectanglesVisibilityOff;
  IF FoundFileName = '' THEN BEGIN
    Beep;
    SaveFileFoundPosition := 0;
  END ELSE BEGIN
    SaveFileFoundPosition := I;

    { scroll it into view }
    VertScrollBar.Position := ImageViewUnitForm.Controls[I].Top;

    WITH SelectedFileRec DO BEGIN
      InitialiseSelectedFileVariables;
      SelectedFile_Name := FoundFileName;
      ImageViewUnitForm.Caption := SelectedFile_Name;
      IF NOT SelectedFileRecRectangleVisibilityIsOn(SelectedFile_Name) THEN
        TurnSelectedFileRecRectangleVisibilityOn(SelectedFile_Name);
    END; {WITH}
  END;

  ImageViewUnitFindDialog.CloseDialog;
END; { ImageViewUnitFindDialogFind }

FUNCTION SortFiles(List: TStringList; Index1, Index2: Integer): Integer;

  FUNCTION CompareNewAlphaNumericStr(S1, S2: String): Integer;
  VAR
    Part1, Part2: String;
    Pos1, Pos2: Integer;

  CONST
    Digits = ['0'..'9'];

    PROCEDURE FillPart(Source: String; VAR Pos: Integer; VAR Dest: String);
    VAR
      IsNum: Boolean;
      DP: Integer;

    BEGIN
      TRY
        IF Pos > Length(Source) THEN
          Dest := ''
        ELSE BEGIN
          IsNum := CharInSet(Source[Pos], Digits);
          DP := 0;
          WHILE (Pos+DP <= Length(Source)) AND (CharInSet(Source[Pos+DP], Digits) = IsNum) DO
            Inc(DP);
          Dest := Copy(Source, Pos, DP);
          Pos := Pos + DP;
        END;
      EXCEPT
        ON E : Exception DO
          ShowMessage('FillPart: ' + E.ClassName +' error raised, with message: ' + E.Message);
      END;
    END; { FillPart }

    FUNCTION NumComp(N1, N2: Int64): Integer;
    BEGIN
      TRY
        IF N1 < N2 THEN
          Result := -1
        ELSE
          IF N1 > N2 THEN
            Result := 1
          ELSE
            Result := 0;
      EXCEPT
        ON E : Exception DO BEGIN
          ShowMessage('NumComp: ' + E.ClassName +' error raised, with message: ' + E.Message);
          Result := 0;
        END;
      END;
    END; { NumComp }

  BEGIN
    TRY
      IF (S1 = '') OR (S2 = '') OR (CharInSet(S1[1], Digits) XOR (CharInSet(S2[1], Digits))) THEN
        Result := CompareText(S1, S2)
      ELSE BEGIN
        Pos1 := 1;
        Pos2 := 1;
        Result := 0;
        REPEAT
          FillPart(S1, Pos1, Part1);
          FillPart(S2, Pos2, Part2);
          IF Part1 = '' THEN BEGIN
            IF Part2 <> '' THEN
              Result := -1;
          END ELSE
            IF Part2 = '' THEN
              Result := 1
            ELSE
              IF CharInSet(Part1[1], Digits) AND (Length(Part1) < 20) AND (Length(Part2) < 20) THEN
                { the second and third tests are to avoid filenames consisting of more than twenty digits causing an Int64 exception }
                Result := NumComp(StrToInt64(Part1), StrToInt64(Part2))
              ELSE
                Result := CompareText(Part1, Part2);
        UNTIL (Result <> 0) OR ((Part1 = '') AND (Part2 = ''));
      END;
    EXCEPT
      ON E : Exception DO BEGIN
        ShowMessage('CompareNewAlphaNumericStr: ' + E.ClassName +' error raised, with message: ' + E.Message);
        Result := 0;
      END;
    END; {TRY}
  END; { CompareNewAlphaNumericStr }

  FUNCTION CompareDates(dt1, dt2: TDateTime): Integer;
  BEGIN
    IF (dt1 > dt2) THEN
      Result := 1
    ELSE
      IF (dt1 = dt2) THEN
        Result := 0
      ELSE
        Result := -1;
  END; { CompareDates }

  FUNCTION CompareNumeric(AInt1, AInt2: Integer): Integer;
  BEGIN
    IF AInt1 > AInt2 THEN
      Result := 1
    ELSE
      IF AInt1 = AInt2 THEN
        Result := 0
      ELSE
        Result := -1;
  END; { CompareNumeric }

VAR
  DateTime1, DateTime2 : TDateTime;
  FileName1, FileName2: String;
  FileType1, FileType2 : String;

BEGIN
  List.NameValueSeparator := '?';

  Result := CompareNewAlphaNumericStr(FileName1, FileName2);

  TRY
    FileName1 := List.Names[Index1];
    FileName2 := List.Names[Index2];

    CASE CustomSortType OF
      SortByFileName:
        Result := CompareNewAlphaNumericStr(FileName1, FileName2);
      SortByDate:
        BEGIN
          DateTime1 := StrToDateTime(List.Values[List.Names[Index1]]);
          DateTime2 := StrToDateTime(List.Values[List.Names[Index2]]);
          Result := -CompareDates(DateTime1, DateTime2);
        END;
      SortByLastAccess:
        BEGIN
          DateTime1 := StrToDateTime(List.Values[List.Names[Index1]]);
          DateTime2 := StrToDateTime(List.Values[List.Names[Index2]]);
          Result := -CompareDates(DateTime1, DateTime2);
        END;
      SortByNumericSuffix, SortByType:
        BEGIN
          FileType1 := List.Values[List.Names[Index1]];
          FileType2 := List.Values[List.Names[Index2]];
          Result := CompareNewAlphaNumericStr(FileType1, FileType2);
        END;
    END; {CASE}

    IF SortOrder = Descending THEN
      Result := -Result;
  EXCEPT
    ON E : Exception DO
      ShowMessage('SortFiles: ' + E.ClassName + ' error raised, with message: ' + E.Message);
  END; {TRY}
END; { SortFiles }

PROCEDURE AddEmptyImagesToImageView(AParent : TWinControl);
VAR
  Bitmap : TBitMap;
//  ElapsedTimeInSeconds : Integer;
//  HH : Integer;
  Image : TImage;
  ImageCount : Integer;
  ImageFocusRectangle : TShape;
  ImageLabel : TLabel;
//  MM : Integer;
  NumberStr : String;
//  Percentage : Integer;
//  PercentageStr : String;
  SearchRec : TSearchRec;
//  SS : Integer;
  TempFileName : String;
//  TotalTimeInSeconds : Integer;
  TypeOfFile : FileType;
//OleGraphic: TOleGraphic;
//fs: TFileStream;


BEGIN
  TRY
writetodebugfile('entering AddEmptyImagesToImageView');
    EligibleFiles := 0;

    IF PathName[Length(PathName)] <> '\' THEN
      PathName := PathName + '\';

    { First count how many potential images there are }
    TotalFileCount := 0;
    IF FindFirst(PathName + '*.*', FaAnyFile, SearchRec) = 0 THEN BEGIN
      REPEAT
        IF (SearchRec.Name =  '.') OR (SearchRec.Name =  '..') OR IsDirectory(SearchRec.Attr) THEN
          Continue
        ELSE BEGIN
          Inc(TotalFileCount);

          IF FileTypeSuffixFound(SearchRec.Name) THEN BEGIN
            IF FileTypeSuffixFound(SearchRec.Name, TypeOfFile)
            AND (TypeOfFile = VideoFile)
            AND GetFileNumberSuffixFromSnapFile(SearchRec.Name, NumberStr)
            AND (Pos('.lnk', SearchRec.Name) = 0)
            AND (Pos('.s', SearchRec.Name) = 0)
            AND (Pos('.d', SearchRec.Name) = 0)
            AND (Pos('.db', SearchRec.Name) = 0)
            THEN
              Inc(EligibleFiles);
          END;
        END;
      UNTIL FindNext(SearchRec) <> 0;
    END;

  WriteToDebugFile('-------------------------------------');

    ImageViewUnitForm.Width := Screen.WorkAreaWidth;

    ImageCount := 0;
    StopLoading := False;

    IF (FindFirst(PathName + '*.*', FaAnyFile, SearchRec) = 0) THEN BEGIN
      REPEAT
        IF (SearchRec.Name =  '.') OR (SearchRec.Name =  '..') OR IsDirectory(SearchRec.Attr) OR StopLoading THEN
          Continue
        ELSE BEGIN
          TempFileName := SearchRec.Name;

          { Get the duration from the snap file }
          IF GetFileNumberSuffixFromSnapFile(TempFileName, NumberStr) THEN BEGIN
            IF (Copy(TempFileName, Length(TempFileName) - 1) <> '.d')
            AND (Copy(TempFileName, Length(TempFileName) - 3) <> '.lnk')
            AND (Copy(TempFileName, Length(TempFileName) - 1) <> '.s')
            AND (Copy(TempFileName, Length(TempFileName) - 2) <> '.db')
            AND ((FileExists(PathName + 'snaps\' + TempFileName + '.jpg.' + NumberStr)) OR (FileExists(PathName + 'snaps\' + TempFileName + '.txt.' + NumberStr)))
            THEN BEGIN
              Application.ProcessMessages;

              Image := TImage.Create(NIL);

              Image.Parent := AParent;
              Image.Center := True;
              Image.Stretch := True;
              Image.Visible := False;
              Image.OnMouseDown := ImageViewUnitForm.MouseDownEvent;

              IF FileExists(PathName + 'snaps\' + TempFileName + '.jpg.' + NumberStr) THEN BEGIN
                LoadAndConvertImage(PathName + 'snaps\' + TempFileName + '.jpg.' + NumberStr, Image);
                Image.Visible := True;
              END ELSE BEGIN
                Bitmap := TBitmap.Create;
                Bitmap.Width:= 100;
                Bitmap.Height:= 100;
                Bitmap.Transparent:= True;
                Bitmap.TransparentColor:= clWhite;
                Bitmap.Canvas.Brush.Style:= bsSolid;
                Bitmap.Canvas.Brush.Color:= clSilver;
                Bitmap.Canvas.FillRect(Bitmap.Canvas.ClipRect);

                { Indicate that no image has been loaded }
                Image.Visible := False;

                Image.Picture.Bitmap := Bitmap;
              END;

              { we use Hint as images don't, surprisingly, have captions }
              Image.Hint := TempFileName;

              { Now add the label }
              ImageLabel := TLabel.Create(NIL);
              ImageLabel.Parent := AParent;
              ImageLabel.Visible := True;
              ImageLabel.Enabled := True;
              ImageLabel.Font.Color := clWindowText;
              ImageLabel.OnMouseDown := ImageViewUnitForm.MouseDownEvent;
              ImageLabel.Visible := False;

              { We have to store the file name in the Hint, as the caption may well have the elapsed time attached - which will cause problems if we click on it }
              ImageLabel.Hint := TempFileName;

              { The following three lines of code have to be in this exact order so that the word wrapping works properly, goodness knows why! }
              ImageLabel.WordWrap := True;
      //        IF NOT TestMode OR (Pos(':', TempNumbersStr) = 0) THEN
              IF NumberStr = '' THEN
                ImageLabel.Caption := TempFileName
              ELSE
                ImageLabel.Caption := TempFileName + '.' + NumberStr;
      //        ELSE BEGIN
      //          PercentageStr := ExplorerForm.ListView.Items[ImageCount].Caption;
      //          PercentageStr := TempFileName2;
      //
      //          TotalTimeFromTCPStr := Copy(TempNumbersStr, 6, 4);
      //          IF Length(TotalTimeFromTCPStr) = 6 THEN BEGIN
      //            HH := StrToInt(Copy(TotalTimeFromTCPStr, 1, 2));
      //            MM := StrToInt(Copy(TotalTimeFromTCPStr, 3, 2));
      //            SS := StrToInt(Copy(TotalTimeFromTCPStr, 5, 2));
      //            TotalTimeInSeconds := (HH * 360) * (MM * 60) + SS;
      //          END ELSE BEGIN
      //            MM := StrToInt(Copy(TotalTimeFromTCPStr, 1, 2));
      //            SS := StrToInt(Copy(TotalTimeFromTCPStr, 3, 2));
      //            TotalTimeInSeconds := (MM * 60) + SS;
      //          END;
      //
      //          ElapsedTimeFromTCPStr := Copy(TempNumbersStr, 1, 4);
      //          IF Length(ElapsedTimeFromTCPStr) = 6 THEN BEGIN
      //            HH := StrToInt(Copy(ElapsedTimeFromTCPStr, 1, 2));
      //            MM := StrToInt(Copy(ElapsedTimeFromTCPStr, 3, 2));
      //            SS := StrToInt(Copy(ElapsedTimeFromTCPStr, 5, 2));
      //            ElapsedTimeInSeconds := (HH * 360) * (MM * 60) + SS;
      //          END ELSE BEGIN
      //            MM := StrToInt(Copy(ElapsedTimeFromTCPStr, 1, 2));
      //            SS := StrToInt(Copy(ElapsedTimeFromTCPStr, 3, 2));
      //            ElapsedTimeInSeconds := (MM * 60) + SS;
      //          END;
      //
      //          { Convert the difference to a percentage }
      //          Percentage := 100 DIV (TotalTimeInSeconds DIV ElapsedTimeInSeconds);
      //          PercentageStr := IntToStr(Percentage) + '%';
      //
      //          ImageLabel.Caption := TempFileName2 + ' ' + PercentageStr;
      //        END;

              { And prepare a border around the image so we can see which one we've selected. We're using a TShape control rather than FrameRect as it's a control and is
                permanent.
              }
              ImageFocusRectangle := TShape.Create(NIL);
              WITH ImageFocusRectangle DO BEGIN
                Parent := AParent;
                Pen.Color := clAqua;
                Pen.Width := 5;
                Visible := False;
                Shape := stRectangle;
                Brush.Style := bsClear;
                OnMouseDown := ImageViewUnitForm.MouseDownEvent;
                Hint := TempFileName;
              END; {WITH}
            END;

            Inc(ImageCount);
            IF ImageCount = EligibleFiles THEN
              WriteSplashLoadingLabel(IntToStr(EligibleFiles) + ' Files Loaded')
            ELSE
              WriteSplashLoadingLabel(IntToStr(ImageCount) + ' / ' + IntToStr(EligibleFiles) + ' Loaded');
          END;
        END;

        Application.ProcessMessages;
      UNTIL (FindNext(SearchRec) <> 0) OR StopLoading;

      IF StopLoading THEN
        Application.Terminate;
    END;
writetodebugfile('exiting AddEmptyImagesToImageView');
  EXCEPT
    ON E : Exception DO
      ShowMessage('AddEmptyImagesToImageView: ' + E.ClassName + ' error raised, with message: ' + E.Message);
  END; {TRY}
END; { AddEmptyImagesToImageView }

PROCEDURE newAddEmptyImagesToImageView(AParent : TWinControl);
VAR
//  Bitmap : TBitMap;
//  ElapsedTimeInSeconds : Integer;
//  HH : Integer;
  Image : TImage;
  ImageCount : Integer;
  ImageFocusRectangle : TShape;
  ImageLabel : TLabel;
//  MM : Integer;
  NumberStr : String;
//  Percentage : Integer;
//  PercentageStr : String;
  SearchRec : TSearchRec;
//  SS : Integer;
  TempFileName : String;
//  TotalTimeInSeconds : Integer;
  TypeOfFile : FileType;
//OleGraphic: TOleGraphic;
//fs: TFileStream;

BEGIN
  TRY
    EligibleFiles := 0;

    IF PathName[Length(PathName)] <> '\' THEN
      PathName := PathName + '\';

    { First count how many potential images there are }
    TotalFileCount := 0;
    IF FindFirst(PathName + '*.*', FaAnyFile, SearchRec) = 0 THEN BEGIN
      REPEAT
        IF (SearchRec.Name =  '.') OR (SearchRec.Name =  '..') OR IsDirectory(SearchRec.Attr) THEN
          Continue
        ELSE BEGIN
          Inc(TotalFileCount);

          IF FileTypeSuffixFound(SearchRec.Name) THEN BEGIN
            IF FileTypeSuffixFound(SearchRec.Name, TypeOfFile)
            AND (TypeOfFile = VideoFile)
            AND GetFileNumberSuffixFromSnapFile(SearchRec.Name, NumberStr)
            AND (Pos('.lnk', SearchRec.Name) = 0)
            AND (Pos('.s', SearchRec.Name) = 0)
            AND (Pos('.d', SearchRec.Name) = 0)
            AND (Pos('.db', SearchRec.Name) = 0)
            THEN
              Inc(EligibleFiles);
          END;
        END;
      UNTIL FindNext(SearchRec) <> 0;
    END;

    ImageViewUnitForm.Width := Screen.WorkAreaWidth;

    ImageCount := 0;
    StopLoading := False;

    IF (FindFirst(PathName + '*.*', FaAnyFile, SearchRec) = 0) THEN BEGIN
      REPEAT
        IF (SearchRec.Name =  '.') OR (SearchRec.Name =  '..') OR IsDirectory(SearchRec.Attr) OR StopLoading THEN
          Continue
        ELSE BEGIN
          TempFileName := SearchRec.Name;

          { Get the duration from the snap file }
          IF GetFileNumberSuffixFromSnapFile(TempFileName, NumberStr) THEN BEGIN
            IF (Copy(TempFileName, Length(TempFileName) - 1) <> '.d')
            AND (Copy(TempFileName, Length(TempFileName) - 3) <> '.lnk')
            AND (Copy(TempFileName, Length(TempFileName) - 1) <> '.s')
            AND (Copy(TempFileName, Length(TempFileName) - 2) <> '.db')
            AND ((FileExists(PathName + 'snaps\' + TempFileName + '.jpg.' + NumberStr)) OR (FileExists(PathName + 'snaps\' + TempFileName + '.txt.' + NumberStr)))
            THEN BEGIN
              Application.ProcessMessages;

              Image := TImage.Create(NIL);

              Image.Parent := AParent;
//              Image.Center := True;
//              Image.Stretch := True;
//              Image.Visible := False;
//              Image.OnMouseDown := ImageViewUnitForm.MouseDownEvent;
//              { we use Hint as images don't, surprisingly, have captions }
//              Image.Hint := TempFileName;
//
//              IF FileExists(PathName + 'snaps\' + TempFileName + '.jpg.' + NumberStr) THEN BEGIN
//                LoadAndConvertImage(PathName + 'snaps\' + TempFileName + '.jpg.' + NumberStr, Image);
//                Image.Visible := True;
//              END ELSE BEGIN
//                Bitmap := TBitmap.Create;
//                Bitmap.Width:= 100;
//                Bitmap.Height:= 100;
//                Bitmap.Transparent:= True;
//                Bitmap.TransparentColor:= clWhite;
//                Bitmap.Canvas.Brush.Style:= bsSolid;
//                Bitmap.Canvas.Brush.Color:= clSilver;
//                Bitmap.Canvas.FillRect(Bitmap.Canvas.ClipRect);
//
//                { Indicate that no image has been loaded }
//                Image.Visible := False;
//
//                Image.Picture.Bitmap := Bitmap;
//              END;
//
//              { Now add the label }
              ImageLabel := TLabel.Create(NIL);
              ImageLabel.Parent := AParent;
//              ImageLabel.Visible := True;
//              ImageLabel.Enabled := True;
//              ImageLabel.Font.Color := clWindowText;
//              ImageLabel.OnMouseDown := ImageViewUnitForm.MouseDownEvent;
//              ImageLabel.Visible := False;
//
//              { The following three lines of code have to be in this exact order so that the word wrapping works properly, goodness knows why! }
//              ImageLabel.WordWrap := True;
//      //        IF NOT TestMode OR (Pos(':', TempNumbersStr) = 0) THEN
              IF NumberStr = '' THEN
                ImageLabel.Caption := TempFileName
              ELSE
                ImageLabel.Caption := TempFileName + '.' + NumberStr;
      //        ELSE BEGIN
      //          PercentageStr := ExplorerForm.ListView.Items[ImageCount].Caption;
      //          PercentageStr := TempFileName2;
      //
      //          TotalTimeFromTCPStr := Copy(TempNumbersStr, 6, 4);
      //          IF Length(TotalTimeFromTCPStr) = 6 THEN BEGIN
      //            HH := StrToInt(Copy(TotalTimeFromTCPStr, 1, 2));
      //            MM := StrToInt(Copy(TotalTimeFromTCPStr, 3, 2));
      //            SS := StrToInt(Copy(TotalTimeFromTCPStr, 5, 2));
      //            TotalTimeInSeconds := (HH * 360) * (MM * 60) + SS;
      //          END ELSE BEGIN
      //            MM := StrToInt(Copy(TotalTimeFromTCPStr, 1, 2));
      //            SS := StrToInt(Copy(TotalTimeFromTCPStr, 3, 2));
      //            TotalTimeInSeconds := (MM * 60) + SS;
      //          END;
      //
      //          ElapsedTimeFromTCPStr := Copy(TempNumbersStr, 1, 4);
      //          IF Length(ElapsedTimeFromTCPStr) = 6 THEN BEGIN
      //            HH := StrToInt(Copy(ElapsedTimeFromTCPStr, 1, 2));
      //            MM := StrToInt(Copy(ElapsedTimeFromTCPStr, 3, 2));
      //            SS := StrToInt(Copy(ElapsedTimeFromTCPStr, 5, 2));
      //            ElapsedTimeInSeconds := (HH * 360) * (MM * 60) + SS;
      //          END ELSE BEGIN
      //            MM := StrToInt(Copy(ElapsedTimeFromTCPStr, 1, 2));
      //            SS := StrToInt(Copy(ElapsedTimeFromTCPStr, 3, 2));
      //            ElapsedTimeInSeconds := (MM * 60) + SS;
      //          END;
      //
      //          { Convert the difference to a percentage }
      //          Percentage := 100 DIV (TotalTimeInSeconds DIV ElapsedTimeInSeconds);
      //          PercentageStr := IntToStr(Percentage) + '%';
      //
      //          ImageLabel.Caption := TempFileName2 + ' ' + PercentageStr;
      //        END;

              { And prepare a border around the image so we can see which one we've selected. We're using a TShape control rather than FrameRect as it's a control and is
                permanent.
              }
              ImageFocusRectangle := TShape.Create(NIL);
              WITH ImageFocusRectangle DO BEGIN
                Parent := AParent;
                Pen.Color := clAqua;
                Pen.Width := 5;
                Visible := False;
                Shape := stRectangle;
                Brush.Style := bsClear;
                OnMouseDown := ImageViewUnitForm.MouseDownEvent;
                Hint := TempFileName;
              END; {WITH}
            END;

            Inc(ImageCount);
            IF ImageCount = EligibleFiles THEN
              WriteSplashLoadingLabel(IntToStr(EligibleFiles) + ' Files Loaded')
            ELSE
              WriteSplashLoadingLabel(IntToStr(ImageCount) + ' / ' + IntToStr(EligibleFiles) + ' Loaded');
          END;
        END;

        Application.ProcessMessages;
      UNTIL (FindNext(SearchRec) <> 0) OR StopLoading;

      IF StopLoading THEN
        Application.Terminate;
    END;
  EXCEPT
    ON E : Exception DO
      ShowMessage('AddEmptyImagesToImageView: ' + E.ClassName + ' error raised, with message: ' + E.Message);
  END; {TRY}
END; { newAddEmptyImagesToImageView }

PROCEDURE newPositionImages(AParent : TWinControl; SortType : TypeOfSort; OUT CaptionStr : String; Redraw : Boolean);
{ Fill any gaps that arise, or use for sorting the images }

  {$H-}
  PROCEDURE KeepDateTimeToStr;
  { This is here to fool Delphi into not eliminating DateTimeToStr }
  VAR
    FunctionPtr : FUNCTION(CONST DateTime: TDateTime): String;

  BEGIN
    FunctionPtr := @DateTimeToStr;
  END; { KeepDateTimeToStr }
  {$H+}

  FUNCTION FileTimeToDateTime(FileTime: TFileTime) : TDateTime;
  VAR
    LocalFileTime: TFileTime;
    SystemTime: TSystemTime;

  BEGIN
    FileTimeToLocalFileTime(FileTime, LocalFileTime);
    FileTimeToSystemTime(LocalFileTime, SystemTime);
    Result := SystemTimeToDateTime(SystemTime);
  END; { FileTimeToDateTime }

CONST
  ImageHeight = 165;
  ImageWidth = 225;
  TopMargin = 10;

VAR
  Done : Boolean;
  FileList : TStringList;
  FileListCount : Integer;
//  FileTypeSuffix : String;
  ImageViewCount : Integer;
  ImageLeft : Integer;
  ImageTop : Integer;
//  LastDotPos : Integer;
  LeftMargin : Integer;
  NumberOfImagesPerRow : Integer;
  NumberStr : string;
//  SearchRec : TSearchRec;
//  TempFileName : String;
tempimage : Timage;

BEGIN
  TRY
    IF NOT Initialised THEN BEGIN
      AddEmptyImagesToImageView(AParent);
      Initialised := True;
    END;

    IF IsSplashFormVisible THEN BEGIN
      WriteSplashLoadingLabel('Sorting Files');
      Application.ProcessMessages;
    END;

    CheckImagesInView;

    IF (LastSort = SortType) AND (SortOrder = Ascending) AND NOT Redraw THEN
      SortOrder := Descending
    ELSE
      SortOrder := Ascending;

    LastSort := SortType;

    KeepDateTimeToStr;

    { ************** get sort stuff from old positionimages }
    filelist := nil;
    try

      CASE SortType OF
        SortByFileName:
          BEGIN
            CustomSortType := SortByFileName;
            IF SortOrder = Ascending THEN
              CaptionStr := 'Sorted by file name'
            ELSE
              CaptionStr := 'Reverse sorted by file name';
          END;
        SortByDate:
          BEGIN
            CustomSortType := SortByDate;
            IF SortOrder = Ascending THEN
              CaptionStr := 'Sorted by date'
            ELSE
              CaptionStr := 'Reverse sorted by date';
            END;
        SortByLastAccess:
          BEGIN
            CustomSortType := SortByLastAccess;
            IF SortOrder = Ascending THEN
              CaptionStr := 'Sorted by last access time'
            ELSE
              CaptionStr := 'Reverse sorted by last access time';
          END;
        SortByNumericSuffix:
          BEGIN
            CustomSortType := SortByNumericSuffix;
              IF SortOrder = Ascending THEN
                CaptionStr := 'Sorted by numeric suffix'
              ELSE
                CaptionStr := 'Reverse sorted by numeric suffix';
            END;
        SortByType:
          BEGIN
            CustomSortType := SortByType;
              IF SortOrder = Ascending THEN
                CaptionStr := 'Sorted by type'
              ELSE
                CaptionStr := 'Reverse sorted by type';
            END;
        END; {CASE}

      FileList.CustomSort(SortFiles);

      NumberOfImagesPerRow := ImageViewUnitForm.Width DIV (ImageWidth + 10);
      LeftMargin := (ImageViewUnitForm.Width - ((ImageWidth + 10) * NumberOfImagesPerRow)) DIV 2;
      ImageLeft := LeftMargin;
      ImageTop := TopMargin;

//  WITH ImageViewUnitForm DO BEGIN
//    I := 0;
//    WHILE (I < ImageViewUnitForm.ControlCount) DO BEGIN
//      IF Controls[I] IS TImage THEN BEGIN
//        WITH TImage(ImageViewUnitForm.Controls[I]) DO BEGIN
//          IF NOT Visible THEN BEGIN
//            IF PtInRect(Screen.WorkAreaRect, Point(Left, Top))
//            OR PtInRect(Screen.WorkAreaRect, Point(Left + Width, Top + Height))
//            THEN BEGIN
//              IF GetFileNumberSuffixFromSnapFile(Hint, IsJPEG, NumberStr) THEN BEGIN
//                IF IsJPEG THEN BEGIN
//                  IF NumberStr = '' THEN
//                    LoadAndConvertImage(PathName + 'Snaps\' + Hint + '.jpg', Image)
//                  ELSE;
//                    LoadAndConvertImage(PathName + 'Snaps\' + Hint + '.jpg.' + NumberStr, Image);
//                END;
//                Visible := True;
//              END;
//            END;
//          END;
//        END; {WITH}
//      END;
//      Inc(I);
//    END; {WHILE}
//  END; {WITH}


      FileListCount := 0;
      WHILE FileListCount < FileList.Count DO BEGIN
        Done := False;
        ImageViewCount := 0;
//        WHILE (ImageViewCount < ImageViewUnitForm.ControlCount) AND NOT Done DO BEGIN
//          IF ImageViewUnitForm.Controls[ImageViewCount] IS TImage THEN BEGIN
//            IF TImage(ImageViewUnitForm.Controls[ImageViewCount]).Hint = FileList.Names[FileListCount] THEN BEGIN
        WHILE (ImageViewCount <= ImageViewUnitForm.ControlCount - 3) AND NOT Done DO BEGIN
//if ImageViewCount = 30 then
//null;
//          IF ImageViewUnitForm.Controls[ImageViewCount] IS TImage THEN
//            null;
//          IF ImageViewUnitForm.Controls[ImageViewCount + 1] IS TLabel THEN
//            null;
//          IF ImageViewUnitForm.Controls[ImageViewCount + 2] IS Tshape THEN
//            null;
//
          IF ImageViewUnitForm.Controls[ImageViewCount + 2] IS TShape THEN BEGIN
            IF TShape(ImageViewUnitForm.Controls[ImageViewCount + 2]).Hint = FileList.Names[FileListCount] THEN BEGIN
  null;
//
              Done := True;

              TImage(ImageViewUnitForm.Controls[ImageViewCount]).Width := ImageWidth;
              TImage(ImageViewUnitForm.Controls[ImageViewCount]).Height := ImageHeight;
              TImage(ImageViewUnitForm.Controls[ImageViewCount]).Left := ImageLeft;
              TImage(ImageViewUnitForm.Controls[ImageViewCount]).Top := ImageTop;
              TImage(ImageViewUnitForm.Controls[ImageViewCount]).Visible := False;
//
              TLabel(ImageViewUnitForm.Controls[ImageViewCount + 1]).Width := ImageWidth;
              TLabel(ImageViewUnitForm.Controls[ImageViewCount + 1]).Left := ImageLeft;
              TLabel(ImageViewUnitForm.Controls[ImageViewCount + 1]).Top := ImageTop + ImageHeight;
              TLabel(ImageViewUnitForm.Controls[ImageViewCount + 1]).Visible := True;

              TShape(ImageViewUnitForm.Controls[ImageViewCount + 2]).Width := ImageWidth + 10;
              TShape(ImageViewUnitForm.Controls[ImageViewCount + 2]).Height := ImageHeight + 25;
              TShape(ImageViewUnitForm.Controls[ImageViewCount + 2]).Left := ImageLeft - 5;
              TShape(ImageViewUnitForm.Controls[ImageViewCount + 2]).Top := ImageTop - 5;
              TShape(ImageViewUnitForm.Controls[ImageViewCount + 2]).Visible := False;

  WITH TImage(ImageViewUnitForm.Controls[ImageViewCount]) DO BEGIN
    IF NOT Visible THEN BEGIN
      IF PtInRect(Screen.WorkAreaRect, Point(Left, Top))
      OR PtInRect(Screen.WorkAreaRect, Point(Left + Width, Top + Height))
      THEN BEGIN
        ImageViewUnitForm.Caption := TLabel(ImageViewUnitForm.Controls[ImageViewCount + 1]).Caption;
        TLabel(ImageViewUnitForm.Controls[ImageViewCount + 1]).Caption := TLabel(ImageViewUnitForm.Controls[ImageViewCount + 1]).Caption + ' VIS';
        IF GetFileNumberSuffixFromSnapFile(Hint, NumberStr) THEN BEGIN
          TempImage := TImage(ImageViewUnitForm.Controls[ImageViewCount]);
          LoadAndConvertImage(PathName + 'Snaps\' + FileList.Names[FileListCount] + '.jpg.' + NumberStr, tempimage);
          TempImage.Visible := True;
        END;
      END;
    END;
  END;

              Inc(ImageLeft, ImageWidth + 10);
              IF (ImageLeft + ImageWidth + 10) > ImageViewUnitForm.Width THEN BEGIN
                ImageLeft := LeftMargin;
                Inc(ImageTop, ImageHeight + 30);
              END;
            END;
          END;
          Inc(ImageViewCount, 3);
        END; {WHILE}

        Inc(FileListCount);
      END; {WHILE}

      IF IsSplashFormVisible THEN
        HideSplashForm;
    FINALLY
      FileList.Free;
    END;
  EXCEPT
    ON E : Exception DO
      ShowMessage('PositionImages: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { newPositionImages }

PROCEDURE PositionImages(AParent : TWinControl; SortType : TypeOfSort; OUT CaptionStr : String; Redraw : Boolean);
{ Fill any gaps that arise, or use for sorting the images }

  FUNCTION FileTimeToDateTime(FileTime: TFileTime) : TDateTime;
  VAR
    LocalFileTime: TFileTime;
    SystemTime: TSystemTime;

  BEGIN
    FileTimeToLocalFileTime(FileTime, LocalFileTime);
    FileTimeToSystemTime(LocalFileTime, SystemTime);
    Result := SystemTimeToDateTime(SystemTime);
  END; { FileTimeToDateTime }

CONST
  ImageHeight = 165;
  ImageWidth = 225;
  TopMargin = 10;

VAR
  Done : Boolean;
  FileList : TStringList;
  FileListCount : Integer;
  FilesSeenTodayCount : Integer;
  FilesSeenTodayList : TStringList;
  FileTypeSuffix : String;
  FunctionPtr : FUNCTION(CONST DateTime: TDateTime): String;
  FileToBeHiddenFound : Boolean;
  ImageViewCount : Integer;
  ImageLeft : Integer;
  ImageTop : Integer;
  LastDotPos : Integer;
  LeftMargin : Integer;
  NumberOfImagesPerRow : Integer;
  NumberStr : String;
  SearchRec : TSearchRec;

BEGIN
  TRY
writetodebugfile('entering PositionImages');
    IF NOT Initialised THEN BEGIN
      AddEmptyImagesToImageView(AParent);
      Initialised := True;
    END;

    IF IsSplashFormVisible THEN BEGIN
      WriteSplashLoadingLabel('Sorting Files');
      Application.ProcessMessages;
    END;

    CheckImagesInView;

    IF (LastSort = SortType) AND (SortOrder = Ascending) AND NOT Redraw THEN
      SortOrder := Descending
    ELSE
      SortOrder := Ascending;

    LastSort := SortType;

    { These are here to fool Delphi into not eliminating these functions, used for debugging }
    FunctionPtr := @DateTimeToStr;
    FunctionPtr := @DateToStr;

    FileList := TStringList.Create;

    { We need to substitute a character not allowable in a file name for the default equals sign, as a files may well have an equals sign in it }
    FileList.NameValueSeparator := '?';

    FilesSeenTodayList := TStringList.Create;

    TRY
      IF (FindFirst(PathName + '*.*', FaAnyFile, SearchRec) = 0) AND NOT StopLoading THEN BEGIN
        TRY
          REPEAT
            IF (SearchRec.Name =  '.') OR (SearchRec.Name =  '..') OR IsDirectory(SearchRec.Attr) THEN
              Continue
            ELSE BEGIN
              IF HideImagesWhenMoviesPlayedToday THEN
                IF DateToStr(Today) = DateToStr(FileTimeToDateTime(SearchRec.FindData.ftLastAccessTime)) THEN
                  FilesSeenTodayList.Add(SearchRec.Name);

              FormatSettings.ShortDateFormat := 'dd/mm/yyyy';
              FormatSettings.LongTimeFormat := 'hh:mm';
              CASE SortType OF
                SortByFileName:
                  FileList.Add(SearchRec.Name + FileList.NameValueSeparator);
                SortByDate:
                  FileList.Add(SearchRec.Name + FileList.NameValueSeparator + DateTimeToStr(SearchRec.TimeStamp));
                SortByLastAccess:
                  FileList.Add(SearchRec.Name + FileList.NameValueSeparator + DateTimeToStr(FileTimeToDateTime(SearchRec.FindData.ftLastAccessTime)));
                SortByNumericSuffix:
                  BEGIN
                    IF GetFileNumberSuffixFromSnapFile(SearchRec.Name, NumberStr) AND (NumberStr <> '') THEN
                      FileTypeSuffix := NumberStr
                    ELSE BEGIN
                      LastDotPos := LastDelimiter('.', SearchRec.Name);
                      FileTypeSuffix := Copy(SearchRec.Name, LastDotPos + 1);
                    END;
                    FileList.Add(SearchRec.Name + FileList.NameValueSeparator + FileTypeSuffix);
                  END;
                SortByType:
                  BEGIN
                    LastDotPos := LastDelimiter('.', SearchRec.Name);
                    FileTypeSuffix := Copy(SearchRec.Name, LastDotPos + 1);
                    FileList.Add(SearchRec.Name + FileList.NameValueSeparator + FileTypeSuffix);
                  END;
              END; {CASE}
            END;
          UNTIL FindNext(SearchRec) <> 0;
        FINALLY
          FindClose(SearchRec);
        END;
      END;

      CASE SortType OF
        SortByFileName:
          BEGIN
            CustomSortType := SortByFileName;
            IF SortOrder = Ascending THEN
              CaptionStr := 'Sorted by file name'
            ELSE
              CaptionStr := 'Reverse sorted by file name';
          END;
        SortByDate:
          BEGIN
            CustomSortType := SortByDate;
            IF SortOrder = Ascending THEN
              CaptionStr := 'Sorted by date'
            ELSE
              CaptionStr := 'Reverse sorted by date';
            END;
        SortByLastAccess:
          BEGIN
            CustomSortType := SortByLastAccess;
            IF SortOrder = Ascending THEN
              CaptionStr := 'Sorted by last access time'
            ELSE
              CaptionStr := 'Reverse sorted by last access time';
          END;
        SortByNumericSuffix:
          BEGIN
            CustomSortType := SortByNumericSuffix;
              IF SortOrder = Ascending THEN
                CaptionStr := 'Sorted by numeric suffix'
              ELSE
                CaptionStr := 'Reverse sorted by numeric suffix';
            END;
        SortByType:
          BEGIN
            CustomSortType := SortByType;
              IF SortOrder = Ascending THEN
                CaptionStr := 'Sorted by type'
              ELSE
                CaptionStr := 'Reverse sorted by type';
            END;
        END; {CASE}

      FileList.CustomSort(SortFiles);

      NumberOfImagesPerRow := ImageViewUnitForm.Width DIV (ImageWidth + 10);
      LeftMargin := (ImageViewUnitForm.Width - ((ImageWidth + 10) * NumberOfImagesPerRow)) DIV 2;
      ImageLeft := LeftMargin;
      ImageTop := TopMargin;

      FileListCount := 0;
      WHILE FileListCount < FileList.Count DO BEGIN
        Done := False;
        ImageViewCount := 0;
        WHILE (ImageViewCount < ImageViewUnitForm.ControlCount) AND NOT Done DO BEGIN
          IF ImageViewUnitForm.Controls[ImageViewCount] IS TImage THEN BEGIN
            IF TImage(ImageViewUnitForm.Controls[ImageViewCount]).Hint = FileList.Names[FileListCount] THEN BEGIN
              Done := True;
              FileToBeHiddenFound := False;

              { Are we hiding today's seen images? We've stored a list as the displaying code below doesn't have access to the last viewed date. }
              IF HideImagesWhenMoviesPlayedToday THEN BEGIN
                FilesSeenTodayCount := 0;
                WHILE (FilesSeenTodayCount < FilesSeenTodayList.Count) AND NOT FileToBeHiddenFound DO BEGIN
                  IF FilesSeenTodayList[FilesSeenTodayCount] = FileList.Names[FileListCount] THEN BEGIN
                    FileToBeHiddenFound := True;
                    TImage(ImageViewUnitForm.Controls[ImageViewCount]).Visible := False;
                  END;

                  Inc(FilesSeenTodayCount);
                END; {WHILE}
              END;

              { First the image }
              TImage(ImageViewUnitForm.Controls[ImageViewCount]).Width := ImageWidth;
              TImage(ImageViewUnitForm.Controls[ImageViewCount]).Height := ImageHeight;
              TImage(ImageViewUnitForm.Controls[ImageViewCount]).Left := ImageLeft;
              TImage(ImageViewUnitForm.Controls[ImageViewCount]).Top := ImageTop;
              IF NOT FileToBeHiddenFound THEN
                TImage(ImageViewUnitForm.Controls[ImageViewCount]).Visible := True
              ELSE
                TImage(ImageViewUnitForm.Controls[ImageViewCount]).Visible := False;

              { Then the caption }
              TLabel(ImageViewUnitForm.Controls[ImageViewCount + 1]).Width := ImageWidth;
              TLabel(ImageViewUnitForm.Controls[ImageViewCount + 1]).Left := ImageLeft;
              TLabel(ImageViewUnitForm.Controls[ImageViewCount + 1]).Top := ImageTop + ImageHeight;

              IF HideImagesWhenMoviesPlayedToday THEN
                TLabel(ImageViewUnitForm.Controls[ImageViewCount + 1]).Font.Color := clMaroon
              ELSE
                TLabel(ImageViewUnitForm.Controls[ImageViewCount + 1]).Font.Color := clBlack;

//              IF NOT FileToBeHiddenFound THEN
                TLabel(ImageViewUnitForm.Controls[ImageViewCount + 1]).Visible := True
;
//              ELSE
//                TLabel(ImageViewUnitForm.Controls[ImageViewCount + 1]).Visible := False;

              { And finally the box around the image and caption }
              TShape(ImageViewUnitForm.Controls[ImageViewCount + 2]).Width := ImageWidth + 10;
              TShape(ImageViewUnitForm.Controls[ImageViewCount + 2]).Height := ImageHeight + 25;
              TShape(ImageViewUnitForm.Controls[ImageViewCount + 2]).Left := ImageLeft - 5;
              TShape(ImageViewUnitForm.Controls[ImageViewCount + 2]).Top := ImageTop - 5;
              TShape(ImageViewUnitForm.Controls[ImageViewCount + 2]).Visible := False;

//              IF NOT FileToBeHiddenFound THEN BEGIN
                Inc(ImageLeft, ImageWidth + 10);
                IF (ImageLeft + ImageWidth + 10) > ImageViewUnitForm.Width THEN BEGIN
                  ImageLeft := LeftMargin;
                  Inc(ImageTop, ImageHeight + 30);
                END;
//              END;
            END;
          END;
          Inc(ImageViewCount, 3);
        END; {WHILE}

        Inc(FileListCount);
      END; {WHILE}

      IF IsSplashFormVisible THEN
        HideSplashForm;
    FINALLY
      FileList.Free;
    END;
writetodebugfile('exiting PositionImages');
  EXCEPT
    ON E : Exception DO
      ShowMessage('PositionImages: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END;
END; { PositionImages }

PROCEDURE TImageViewUnitForm.ImageViewUnitFormKeyDown(Sender : TObject; VAR Key : Word; ShiftState : TShiftState);
VAR
  CaptionStr : String;
  Done : Boolean;
  I : Integer;
  OK : Boolean;
  SaveCursor : TCursor;
  SaveFileName : String;
  TempImage : TImage;
  TempLabel : TLabel;
  TempRectangle : TShape;
  TempSelectedFileName : String;
  X, Y : Integer;

  FUNCTION DeleteFilePermanently(TempFileName : String) : Boolean;
  { Delete a file without sending it to the Recycle Bin }
  BEGIN
    Result := False;

    TRY
      IF NOT DeleteFile(TempFilename) THEN
        ShowMessage('Error ' + IntToStr(GetLastError) + ' in deleting file ''' + TempFileName + ''' - ' + SysErrorMessage(GetLastError))
      ELSE
        Result := True;
    EXCEPT
      ON E : Exception DO
        ShowMessage('DeleteFilePermanently: ' + E.ClassName +' error raised, with message: ' + E.Message);
    END; {TRY}
  END; { DeleteFilePermanently }

  PROCEDURE ClearImageData(TempFileName : String);
  { Clear all the data behind an image, and set PositionFlag to reposition all the images after the next loss of focus }
  BEGIN
    TurnAllRectanglesVisibilityOff;

    { Clear the label }
    TempLabel := FindSpecificLabelOnImageViewUnitForm(TempFileName);
    IF Assigned(TempLabel) THEN
      TempLabel.Free;

    { and the rectangle too }
    TempRectangle := FindSpecificRectangleAroundImageViewUnitForm(TempFileName);
    IF Assigned(TempRectangle) THEN
      TempRectangle.Free;

    { and finally the image }
    TempImage := FindSpecificImageOnImageViewUnitForm(TempFileName);
    IF Assigned(TempImage) THEN
      TempImage.Free;

    PositionImagesFlag := True;
  END; { ClearImageData }

  PROCEDURE ArchiveOrMoveMainProc(ArchiveOrMove : String; VAR TempDirectory : String; OUT OK : Boolean);
  { Archive or move a file to a given directory }

    FUNCTION GetDirectory(VAR TempDirectory : String) : Boolean;
    { Return whether a directory exists or if one's been created on the hoof }
    BEGIN
      Result := False;

      IF TempDirectory <> '' THEN BEGIN
        IF DirectoryExists(TempDirectory) THEN
          Result := True;
      END ELSE BEGIN
        IF InputQuery('Directory', 'Enter Directory Name', TempDirectory) THEN
          IF TempDirectory = '' THEN
            ShowMessage('No directory specified');
      END;

      IF Result = False THEN BEGIN
        IF DirectoryExists(TempDirectory) THEN
          Result := True
        ELSE BEGIN
          IF TempDirectory <> '' THEN BEGIN
            CASE MessageDlg('Directory "' + TempDirectory + '" does not exist: create it?', mtConfirmation, [mbYes, mbNo], 0, mbNo) OF
              mrYes:
                BEGIN
                  IF CreateDir(TempDirectory) THEN
                    Result := True
                  ELSE BEGIN
                    ShowMessage('Directory cannot be created');
                    TempDirectory := '';
                  END;
                END;
              mrNo:
                BEGIN
                  ShowMessage('Directory not created');
                  TempDirectory := '';
                END;
            END; {CASE}
          END;
        END;
      END;
    END; { GetDirectory }

  VAR
    CanArchive : Boolean;
    FileSize : Int64;
    FreeAvailable, TotalSpace : Int64;
    SearchRec : TSearchRec;

  BEGIN
    TRY
      OK := False;

      WITH SelectedFileRec DO BEGIN
        IF SelectedFile_Name ='' THEN
          ShowMessage('No file to ' + LowerCase(ArchiveOrMove))
        ELSE BEGIN
          IF GetDirectory(TempDirectory) THEN BEGIN
            { Is there room there? }
            CanArchive := True;
            IF FindFirst(PathName + SelectedFile_Name + '*.*', FaAnyFile, SearchRec) = 0 THEN BEGIN
              IF SysUtils.GetDiskFreeSpaceEx(PChar(ArchiveDirectory), FreeAvailable, TotalSpace, NIL) THEN BEGIN
                FileSize := Int64(SearchRec.FindData.nFileSizeHigh) SHL Int64(32) + Int64(SearchRec.FindData.nFileSizeLow);

                { Leave a margin, to stop the annoying "your disc is nearly full" system popups }
                IF FileSize + 100000 > FreeAvailable THEN BEGIN
                  { we can't save it there - best mark it as to-be-archived instead }
                  CanArchive := False;
                  FileRenameProc(PathName, SelectedFile_Name + '.s');
                END;
              END;
            END;

            IF CanArchive THEN BEGIN
              IF NOT FileRenameProc(TempDirectory + '\', SelectedFile_Name) THEN
                ShowMessage('Could not move "' + PathName + SelectedFile_Name + '"'
                            + ' to "' + TempDirectory + '\' + SelectedFile_Name + '" - ' + SysErrorMessage(GetLastError))
              ELSE BEGIN
                { and move the snap file, if any, too }
                IF FileExists(PathName + 'Snaps\' + SelectedFile_Name + '.jpg') THEN BEGIN
                  IF NOT DirectoryExists(TempDirectory + '\Snaps') THEN
                    CreateDir(TempDirectory + '\Snaps');
                  IF NOT RenameFile(PathName + 'Snaps\' + SelectedFile_Name + '.jpg', TempDirectory + '\Snaps\' + SelectedFile_Name + '.jpg') THEN
                    ShowMessage('Error ' + IntToStr(GetLastError) + ': could not rename snap file "' + PathName + 'Snaps\' + SelectedFile_Name + '.jpg"'
                                + '" - ' + SysErrorMessage(GetLastError));
                END;

                SelectedFile_Name := '';
                OK := True;
              END;
            END;
          END;
        END;
      END; {WITH}
    EXCEPT
      ON E : Exception DO
        ShowMessage('ArchiveOrMoveMainProc: ' + E.ClassName +' error raised, with message: ' + E.Message);
    END; {TRY}
  END; { ArchiveOrMoveMainProc }

  PROCEDURE ArchiveFile(OUT OK : Boolean);
  { Archive a file to a given directory }
  BEGIN
    ArchiveOrMoveMainProc('Archive', ArchiveDirectory, OK);
  END; { ArchiveFile }

  PROCEDURE MoveFile(DirectoryNum : Integer; OUT OK : Boolean);
  { Move a file to one of two directories }
  BEGIN
    IF DirectoryNum = 1 THEN
      ArchiveOrMoveMainProc('Move1', MoveDirectory1, OK)
    ELSE
      ArchiveOrMoveMainProc('Move2', MoveDirectory2, OK);
  END; { MoveFile }

BEGIN
  TRY
    IF NOT Editing THEN BEGIN
      WITH SelectedFileRec DO BEGIN
        CASE Key OF
          vk_Space:
            IF SelectedFile_Name = '' THEN
              Beep
            ELSE BEGIN
              { First find which rectangle is on, so we can position the edit panel for a potential file rename }
              X := 0;
              Y := 0;

              I := 0;
              Done := False;
              WHILE (I < ImageViewUnitForm.ControlCount) AND NOT Done DO BEGIN
                IF ImageViewUnitForm.Controls[I] IS TShape THEN BEGIN
                  IF TShape(ImageViewUnitForm.Controls[I]).Hint = SelectedFile_Name THEN BEGIN
                    X := TShape(ImageViewUnitForm.Controls[I]).Left;
                    Y := TShape(ImageViewUnitForm.Controls[I]).Top + TShape(ImageViewUnitForm.Controls[I]).Height;
                  END;
                END;
                Inc(I);
              END; {WHILE}

              IF (X > 0) AND (Y > 0) THEN
                OpenImageViewUnitEditPanel(X, Y);
            END;

          vk_Delete:
            IF SelectedFile_Name = '' THEN
              Beep
            ELSE BEGIN
              IF NOT (ssShift IN ShiftState) THEN BEGIN
                { Rename the files adding a "d" for future deletion by hand }
                TempSelectedFileName := SelectedFile_Name;
                FileRenameProc(PathName, SelectedFile_Name + '.d');
                ClearImageData(TempSelectedFileName + '.d');
//                PositionImages(TWinControl(Sender), LastSort, CaptionStr, NOT RedrawImages);
              END ELSE BEGIN
                SaveFileName := SelectedFile_Name;
                CASE MessageDlg('Permanently delete file "' + PathName + SaveFileName + '"?', mtConfirmation, [mbYes, mbNo], 0, mbNo) OF
                  mrYes :
                    IF DeleteFilePermanently(PathName + SaveFileName) THEN BEGIN
                      IF FileExists(PathName + 'Snaps\' + SaveFileName + '.jpg') THEN
                        IF NOT DeleteFilePermanently(PathName + 'Snaps\' + SaveFileName + '.jpg') THEN
                          ShowMessage('Error ' + IntToStr(GetLastError) + ' : could not delete snap file "' + PathName + 'Snaps\' + SaveFileName + '.jpg'
                                      + '" - ' + SysErrorMessage(GetLastError));
                      ClearImageData(SaveFileName);
                    END;
                  mrNo :
                    ;
                END; {CASE}
              END;
            END;

          vk_Escape:
            { close the image view }
            IF NOT ImageViewUnitEditPanel.Visible THEN BEGIN
              ImageViewUnitForm.Visible := False;
              ImageViewUnitForm.Close;
              Application.Terminate;
            END;

          Ord('A'):
            { archive a file }
            IF SelectedFile_Name = '' THEN
              Beep
            ELSE BEGIN
              TempSelectedFileName := SelectedFile_Name;
              ArchiveFile(OK);
              IF OK THEN
                ClearImageData(TempSelectedFileName);
            END;

          Ord('B'):
            begin
              { for debugging purposes }
              If IsProgramRunning('zplayer.exe') then begin
                ImageViewUnitForm.caption := 'running';
                CloseZoomPlayer;
              end else
                ImageViewUnitForm.caption := 'not running';
            end;

          Ord('C'):
            begin
              { for debugging purposes }
              CreateClient;
            end;

          Ord('D'):
            { reorder the images by date }
            BEGIN
              SaveCursor := Screen.Cursor;
              Screen.Cursor := crHourGlass;

              WITH VertScrollBar DO
                Position := 0;
              ImageViewUnitForm.Caption := PathName + ' ' + 'Sorting Images By Date - please wait';
              PositionImages(TWinControl(Sender), SortByDate, CaptionStr, NOT RedrawImages);
              ImageViewUnitForm.Caption := PathName + ' ' + CaptionStr + GetImageViewCaptionFileNumbers;

              Screen.Cursor := SaveCursor;
            END;

          Ord('F'):
            BEGIN
              SaveCursor := Screen.Cursor;
              Screen.Cursor := crHourGlass;

              IF (ssCtrl IN ShiftState) AND (Key = Ord('F')) THEN
                { do a file find }
                ImageViewUnitFindDialog.Execute
              ELSE BEGIN
                { reorder the listview by filename }
                WITH VertScrollBar DO
                  Position := 0;
                ImageViewUnitForm.Caption := PathName + ' ' + 'Sorting Images By File Name - please wait';
                PositionImages(TWinControl(Sender), SortByFileName, CaptionStr, NOT RedrawImages);
                ImageViewUnitForm.Caption := PathName + ' ' + CaptionStr + GetImageViewCaptionFileNumbers;
              END;

              Screen.Cursor := SaveCursor;
            END;

          Ord('G'):
            IF SelectedFile_Name <> '' THEN BEGIN
              IF Copy(SelectedFile_Name, 1, 3) = 'st-' THEN
                FileRenameProc(PathName, Copy(SelectedFile_Name, 4))
              ELSE
                FileRenameProc(PathName, 'st-' + SelectedFile_Name);
            END;

          Ord('H'):
            BEGIN
              IF NOT HideImagesWhenMoviesPlayedToday THEN BEGIN
                HideImagesWhenMoviesPlayedToday := True;
                ImageViewUnitForm.Caption := 'HideImagesWhenMoviesPlayedToday now ON';
              END ELSE BEGIN
                HideImagesWhenMoviesPlayedToday := False;
                ImageViewUnitForm.Caption := 'HideImagesWhenMoviesPlayedToday now OFF';
              END;
              PositionImages(TWinControl(Sender), LastSort, CaptionStr, RedrawImages);
            END;

          Ord('L'):
            { reorder the listview by last access time }
            BEGIN
              SaveCursor := Screen.Cursor;
              Screen.Cursor := crHourGlass;

              WITH VertScrollBar DO
                Position := 0;
              ImageViewUnitForm.Caption := PathName + ' ' + 'Sorting Images By Last Access Time Name - please wait';
              PositionImages(TWinControl(Sender), SortByLastAccess, CaptionStr, NOT RedrawImages);
              ImageViewUnitForm.Caption := PathName + ' ' + CaptionStr + GetImageViewCaptionFileNumbers;

              Screen.Cursor := SaveCursor;
            END;

          Ord('M') :
            { move a file }
            IF SelectedFile_Name = '' THEN
              Beep
            ELSE BEGIN
              TempSelectedFileName := SelectedFile_Name;
              IF ssShift IN ShiftState THEN
                MoveFile(2, OK)
              ELSE
                MoveFile(1, OK);
              IF OK THEN
                ClearImageData(TempSelectedFileName);
            END;

          Ord('O'):
            IF SelectedFile_Name <> '' THEN BEGIN
              IF Copy(SelectedFile_Name, 1, 3) = 'so-' THEN
                FileRenameProc(Pathname, Copy(SelectedFile_Name, 4))
              ELSE
                FileRenameProc(PathName, 'so-' + SelectedFile_Name);
            END;
          Ord('P'):
            IF SelectedFile_Name <> '' THEN BEGIN
              IF Copy(SelectedFile_Name, 1, 3) = 'sp-' THEN
                FileRenameProc(PathName, Copy(SelectedFile_Name, 4))
              ELSE
                FileRenameProc(PathName, 'sp-' + SelectedFile_Name);
            END;

          Ord('S'):
            IF SelectedFile_Name <> '' THEN BEGIN
              IF Copy(SelectedFile_Name, 1, 2) = 's-' THEN
                FileRenameProc(PathName, Copy(SelectedFile_Name, 3))
              ELSE
                FileRenameProc(PathName, 's-' + SelectedFile_Name);
            END;

          Ord('T'):
            { reorder the listview by file type }
            BEGIN
              WITH VertScrollBar DO
                Position := 0;

              ImageViewUnitForm.Caption := PathName + ' ' + 'Sorting Images By File Type - please wait';
              PositionImages(TWinControl(Sender), SortByType, CaptionStr, NOT RedrawImages);
              ImageViewUnitForm.Caption := PathName + ' ' + CaptionStr + GetImageViewCaptionFileNumbers;
            END;

          Ord('V'):
            IF SelectedFile_Name <> '' THEN BEGIN
              IF Copy(SelectedFile_Name, 1, 2) = 'v-' THEN
                FileRenameProc(PathName, Copy(SelectedFile_Name, 3))
              ELSE
                FileRenameProc(PathName, 'v-' + SelectedFile_Name);
            END;

          Ord('W'):
            { for debugging }
            BEGIN
              IF WritingToDebugFile THEN
                WritingToDebugFile := False
              ELSE
                WritingToDebugFile := True;
              ImageViewUnitForm.Caption := 'WritingToDebugFile=' + BoolToStr(WritingToDebugFile, True);
            END;

          Ord('X'):
            { reorder the listview by numeric file suffix }
            BEGIN
              WITH VertScrollBar DO
                Position := 0;

              ImageViewUnitForm.Caption := PathName + ' ' + 'Sorting Images By File Numeric Suffix - please wait';
              PositionImages(TWinControl(Sender), SortByNumericSuffix, CaptionStr, NOT RedrawImages);
              ImageViewUnitForm.Caption := PathName + ' ' + CaptionStr + GetImageViewCaptionFileNumbers;
            END;

          Ord('Z'):
            IF ZoomPlayerUnitForm.Visible THEN
              ZoomPlayerUnitForm.Visible := False
            ELSE
              ZoomPlayerUnitForm.Visible := True;

          vk_F3 :
            BEGIN
              FindNextFlag := True;
              ImageViewUnitFindDialogFind(Self);
            END;

          vk_Up:
            WITH VertScrollBar DO
              Position := Position - (Increment * 2);

          vk_Down:
            WITH VertScrollBar DO
              Position := Position + (Increment * 2);

          vk_Prior { PgUp } :
            WITH VertScrollBar DO
              Position := Position - (Increment * UserIncrement);

          vk_Next { PgDn } :
            WITH VertScrollBar DO
              Position := Position + (Increment * UserIncrement);

          vk_Home:
            VertScrollBar.Position := 0;

          vk_End:
            WITH VertScrollBar DO
              Position := Range;
        END; {CASE}
      END; {WITH}
    END;
  EXCEPT
    ON E : Exception DO
      ShowMessage('ImageViewUnitFormKeyDown: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END; {TRY}
END; { ImageViewUnitFormKeyDown }

PROCEDURE TImageViewUnitForm.ImageViewUnitFormShow(Sender : TObject);
VAR
  CaptionStr : String;

BEGIN
  TRY
    IF NOT Initialised THEN BEGIN
      IF (SortStr = 'FILENAMESORT') OR (SortStr = 'SIZESORT') THEN
        { size sort makes no sense for image view }
        PositionImages(Self, SortByFileName, CaptionStr, NOT RedrawImages)
      ELSE
        IF SortStr = 'DATESORT' THEN
          PositionImages(Self, SortByDate, CaptionStr, NOT RedrawImages)
        ELSE
          IF SortStr = 'LASTACCESSSORT' THEN
            PositionImages(Self, SortByLastAccess, CaptionStr, NOT RedrawImages)
          ELSE
            IF SortStr = 'NUMERICSUFFIXSORT' THEN
              PositionImages(Self, SortByNumericSuffix, CaptionStr, NOT RedrawImages)
            ELSE
              IF SortStr = 'TYPESORT' THEN
                PositionImages(Self, SortByType, CaptionStr, NOT RedrawImages);

//      IF IsSplashFormVisible THEN
//        HideSplashForm;
    END;
  EXCEPT
    ON E : Exception DO
      ShowMessage('ImageViewShow: ' + E.ClassName +' error raised, with message: ' + E.Message);
  END; {TRY}
END; { ImageViewShow }

PROCEDURE TImageViewUnitForm.ImageViewUnitStopButtonClick(Sender: TObject);
BEGIN
END; { ImageViewUnitStopButtonClick }

PROCEDURE TImageViewUnitForm.AppDeactivate(Sender : TObject);
{ This is called when the ImageViewUnitForm loses focus - i.e. is covered up by ZoomPlayer }
BEGIN
  IF ImageViewUnitForm.Visible THEN BEGIN
    IF PositionImagesFlag THEN BEGIN
      //RedrawImagesImages;
      PositionImagesFlag := False;
    END;
  END;
END; { AppDeactivate }

PROCEDURE StopFileLoading;
{ Allows the splash screen to interrupt the loading process }
BEGIN
  StopLoading := True;
END; { StopFileLoading }

PROCEDURE TImageViewUnitForm.WMVScroll(var Msg : TMessage);
BEGIN
  INHERITED;

  CheckImagesInView;
END; { WMVScroll }

END { ImageViewUnit }.
