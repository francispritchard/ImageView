UNIT ZoomPlayerUnit;

INTERFACE

USES
  Windows, MESSAGEs, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, ExtCtrls, ComCtrls, {TNTDialogs,} Buttons, ScktComp, StrUtils;

CONST
  CommCode = WM_APP+444;         // The message number used to communicate with Zoom Player
  ZoomPlayerCode   = WM_APP+49;  // The message number used to tell Zoom Player our window name
  CRLF     = #13#10;

TYPE
  TZoomPlayerUnitForm = CLASS(TForm)
    BrowseButton : TButton;
    ClearButton : TButton;
    ConnectPanel : TPanel;
    IncomingGB : TGroupBox;
    LabelConnectTo : TLabel;
    LabelTextEntry : TLabel;
    MSGMemo : TMemo;
    PlayButton : TButton;
    PortEdit : TEdit;
    SendButton : TSpeedButton;
    TCPAddress : TEdit;
    TCPCommand : TMemo;
    TCPConnectButton : TButton;
    WinAPIConnectButton : TButton;
    TestButton : TButton;
    PROCEDURE BrowseButtonClick(Sender : TObject);
    PROCEDURE ClearButtonClick(Sender : TObject);
    PROCEDURE FormClose(Sender : TObject; VAR Action : TCloseAction);
    PROCEDURE FormShow(Sender : TObject);
    PROCEDURE PlayButtonClick(Sender : TObject);
    PROCEDURE SendButtonClick(Sender : TObject);
    PROCEDURE TCPConnectButtonClick(Sender : TObject);
    PROCEDURE WinAPIConnectButtonClick(Sender : TObject);
    procedure TestButtonClick(Sender : TObject);
  PRIVATE
    // Intercept Zoom Player MESSAGEs
    PROCEDURE ZoomPlayerEvent(VAR M : TMessage); MESSAGE CommCode;
  PUBLIC
    PROCEDURE CreateZoomPlayerTCPClient(OUT OK : Boolean);
    PROCEDURE DestroyZoomPlayerTCPClient;

    PROCEDURE ZoomPlayerTCPClientConnect(Sender : TObject; Socket : TCustomWinSocket);
    PROCEDURE ZoomPlayerTCPClientDisconnect(Sender : TObject; Socket : TCustomWinSocket);
    PROCEDURE ZoomPlayerTCPClientError(Sender : TObject; Socket : TCustomWinSocket; ErrorEvent : TErrorEvent; VAR ErrorCode : Integer);
    PROCEDURE ZoomPlayerTCPClientRead(Sender : TObject; Socket : TCustomWinSocket);
    PROCEDURE ZoomPlayerTCPSendText(S : String);
  END;


VAR
  ConnectTS : Int64;
  ElapsedTimeFromTCPStr : String;
  TCPBuf : String;
  PlaylistClearedAcknowledgmentReceived : Boolean = False;
  TotalTimeFromTCPStr : String;
  ZoomPlayerTCPClient : TClientSocket    = NIL;
  ZoomPlayerTCPSocket : TCustomWinSocket = NIL;
  ZoomPlayerUnitForm : TZoomPlayerUnitForm;

IMPLEMENTATION

{$R *.dfm}

USES ImageViewUnit;

VAR
  EndOfFile : Boolean = False;
  ZoomPlayerErrorFound : Boolean = False;

FUNCTION FillSpace(S : WideString; Len : Integer) : WideString;
BEGIN
  WHILE Length(S) < Len DO
    S := ' '+S;
  Result := S;
END; { FillSpace }

FUNCTION StringFromAtom(sATOM : ATOM) : String;
VAR
  I : Integer;
  S : String;

BEGIN
  I := 2048;
  SetLength(S, I); // Allocate memory for string
  I := GlobalGetAtomName(sATOM, @S[1], I); // Get string
  SetLength(S, I); // Set string to the current length
  GlobalDeleteAtom(sATOM); // Free memory used by Atom
  Result := S;
END; { StringFromAtom }

PROCEDURE TZoomPlayerUnitForm.ZoomPlayerEvent(VAR M : TMessage);
VAR
  S, S1 : String;

BEGIN
  CASE M.WParam OF
    1000 : { Play State Changed }
           BEGIN
             S := '* Play state changed : ';
             Case M.LParam of
               0 : S1 := 'Closed';   // Also DVD Stop
               1 : S1 := 'Stopped';  // Media only
               2 : S1 := 'Paused';
               3 : S1 := 'Playing';
             END;
             MSGMemo.Lines.Add(S+S1);
           END;
    1100 : { TimeLine update (once per second) }
           MSGMemo.Lines.Add('* Timeline : '+ StringFromAtom(M.LParam));

    1200 : { On Screen Display Messages }
           MSGMemo.Lines.Add('* OSD : '+ StringFromAtom(M.LParam));
    1201 : { On Screen Display MESSAGE has been removed }
           MSGMemo.Lines.Add('* OSD Removed');

    1300 : { DVD & Media Mode changes }
           BEGIN
             S := '* Mode change : Entering ';
             Case M.LParam of
               0 : S1 := 'DVD';
               1 : S1 := 'Media';
             END;
             MSGMemo.Lines.Add(S+S1+' mode');
           END;

    1400 : { DVD Title Change }
           MSGMemo.Lines.Add('* DVD Title : ' + IntToStr(M.LParam));

    1450 : { Current Unique string identifying the DVD disc }
           MSGMemo.Lines.Add('* DVD Unique String : ' + IntToStr(M.LParam));

    1500 : { DVD Chapter Change }
           MSGMemo.Lines.Add('* DVD Chapter : ' + IntToStr(M.LParam));

    1600 : { DVD Audio Change }
           MSGMemo.Lines.Add('* DVD Audio : ' + StringFromAtom(M.LParam));

    1700 : { DVD Subtitle Change }
           MSGMemo.Lines.Add('* DVD Subtitle : ' + StringFromAtom(M.LParam));

    1800 : { Media File Name }
           MSGMemo.Lines.Add('* New Media File : ' + StringFromAtom(M.LParam));

    1855 : { end of file - FWP }
           MSGMemo.Lines.Add('* End of file : ' + StringFromAtom(M.LParam));

    1900 : { Position of Media file in play list }
           MSGMemo.Lines.Add('* Media File play list track number : ' + StringFromAtom(M.LParam));

    2000 : { Video Resolution }
           MSGMemo.Lines.Add('* Video Resolution : ' + StringFromAtom(M.LParam));

    2100 : { Video Frame Rate }
           MSGMemo.Lines.Add('* Video FPS : ' + StringFromAtom(M.LParam));

    2200 : { AR Changed }
           MSGMemo.Lines.Add('* AR Changed to : ' + StringFromAtom(M.LParam));
  END;
END; { ZoomPlayerEvent }

PROCEDURE TZoomPlayerUnitForm.WinAPIConnectButtonClick(Sender : TObject);
VAR
  I : Integer;

BEGIN
  I := FindWindow(NIL, 'Zoom Player');
  IF I > 0 THEN
    SendMessage(I, ZoomPlayerCode, GlobalAddAtom(PChar(ZoomPlayerUnitForm.Caption)), 200);
END; { WinAPIConnectButtonClick }

PROCEDURE CloseProgram(ProgramName : PWideChar);
VAR
  MyHandle: THandle;

BEGIN
  MyHandle:=FindWindow(NIL, ProgramName);
  SendMessage(MyHandle, WM_CLOSE, 0, 0);
END; { CloseProgram }

PROCEDURE TZoomPlayerUnitForm.FormClose(Sender : TObject; VAR Action : TCloseAction);
BEGIN
  IF ZoomPlayerTCPClient <> NIL THEN
    DestroyZoomPlayerTCPClient;
END; { FormClose }

PROCEDURE TZoomPlayerUnitForm.TCPConnectButtonClick(Sender : TObject);
VAR
  OK : Boolean;

BEGIN
  IF ZoomPlayerTCPSocket = NIL THEN
    CreateZoomPlayerTCPClient(OK)
  ELSE
    DestroyZoomPlayerTCPClient;
END; { TCPConnectButtonClick }

PROCEDURE TZoomPlayerUnitForm.PlayButtonClick(Sender : TObject);
BEGIN
  IF ZoomPlayerTCPClient <> NIL THEN
    ZoomPlayerTCPSendText('5100 fnPlay');
END; { PlayButtonClick }

PROCEDURE TZoomPlayerUnitForm.TestButtonClick(Sender : TObject);
BEGIN
  IF ZoomPlayerTCPClient <> NIL THEN
    ZoomPlayerTCPSendText('1110');
END; { TestButtonClick }

PROCEDURE TZoomPlayerUnitForm.BrowseButtonClick(Sender : TObject);
//VAR
//  Browser : TTNTOpenDialog;
BEGIN
//  IF ZoomPlayerTCPClient <> NIL THEN BEGIN
//    Browser := TTNTOpenDialog.Create(MainForm);
//    IF Browser.Execute = True THEN BEGIN
//      ZoomPlayerTCPSendText('1850 '+UTF8Encode(Browser.FileName));
//    END;
//    Browser.Free;
//  END;
END; { BrowseButtonClick }

PROCEDURE TZoomPlayerUnitForm.FormShow(Sender : TObject);
BEGIN
//  ZoomPlayerForm.SetBounds((ZoomPlayerForm.Monitor.Left+ZoomPlayerForm.Monitor.Width)-ZoomPlayerForm.Width,
//                     ZoomPlayerForm.Monitor.Top,
//                     ZoomPlayerForm.Width,ZoomPlayerForm.Height);
END; { FormShow }

PROCEDURE TZoomPlayerUnitForm.SendButtonClick(Sender : TObject);
VAR
  I : Integer;
  S : WideString;

BEGIN
  IF ZoomPlayerTCPClient <> NIL THEN BEGIN
    IF TCPCommand.Lines.Count = 0 THEN
      Exit;

    IF TCPCommand.Lines.Count > 1 THEN BEGIN
      S := '';
      FOR I := 0 TO TCPCommand.Lines.Count-1 DO
        S := S + '"' + TCPCommand.Lines[I] + '" ';
    END ELSE
      S := TCPCommand.Lines[0];

    MSGMemo.Text := MSGMemo.Text + 'OUT ' + FillSpace(IntToStr(GetTickCount - ConnectTS), 8) + 'ms : ' + S + CRLF;
    ZoomPlayerTCPSendText(TCPCommand.Text);
    TCPCommand.Clear;
  END;
END; { SendButtonClick }

PROCEDURE TZoomPlayerUnitForm.CreateZoomPlayerTCPClient(OUT OK : Boolean);
VAR
  I : Integer;

BEGIN
  OK := True;

  IF ZoomPlayerTCPClient = NIL THEN BEGIN
    ZoomPlayerTCPClient := TClientSocket.Create(ZoomPlayerUnitForm);
    ZoomPlayerTCPClient.ClientType := ctNonBlocking;
    ZoomPlayerTCPClient.OnConnect := ZoomPlayerTCPClientConnect;
    ZoomPlayerTCPClient.OnDisconnect := ZoomPlayerTCPClientDisconnect;
    ZoomPlayerTCPClient.OnRead := ZoomPlayerTCPClientRead;
    ZoomPlayerTCPClient.OnError := ZoomPlayerTCPClientError;
  END;

  ZoomPlayerTCPClient.Port := 4769; // StrToInt(PortEdit.Text);
  ZoomPlayerTCPClient.Address := '127.0.0.1'; // TCPAddress.Text;

  TRY
    ZoomPlayerTCPClient.Active := True;
      REPEAT
        Application.ProcessMessages;
      UNTIL ZoomPlayerTCPSocket = NIL;

      I := 0;
      WHILE (ZoomPlayerTCPSocket = NIL) AND (I < 100) DO BEGIN
        Application.ProcessMessages;
        IF ZoomPlayerTCPSocket = NIL THEN
          Sleep(1000); { increased from 100 31/12/12 }
        Inc(I);
      END;
  EXCEPT
    FreeAndNIL(ZoomPlayerTCPClient);
    MSGMemo.Lines.Add('*** Unable to Connect');
    OK := False;
  END;
END; { CreateZoomPlayerTCPClient }

PROCEDURE TZoomPlayerUnitForm.DestroyZoomPlayerTCPClient;
BEGIN
  IF ZoomPlayerTCPClient <> NIL THEN BEGIN
    IF ZoomPlayerTCPSocket <> NIL THEN BEGIN
      ZoomPlayerTCPSocket.Close;
      ZoomPlayerTCPSocket := NIL;
    END;
    ZoomPlayerTCPClient.Active := False;
    FreeAndNIL(ZoomPlayerTCPClient);
  END;
END; { DestroyZoomPlayerTCPClient }

PROCEDURE TZoomPlayerUnitForm.ZoomPlayerTCPClientConnect(Sender : TObject; Socket : TCustomWinSocket);
BEGIN
  ConnectTS := GetTickCount;
  ZoomPlayerTCPSocket := Socket;
  MSGMemo.Lines.Add('*** Connected');
  TCPConnectButton.Enabled := True;
  TCPConnectButton.Caption := 'TCP Disconnect';
END; { ZoomPlayerTCPClientConnect }

PROCEDURE TZoomPlayerUnitForm.ZoomPlayerTCPClientDisconnect(Sender : TObject; Socket : TCustomWinSocket);
VAR
  I : Integer;

  FUNCTION SetFileLastAccessTime(TempFileName : String; NewDateTime : TDateTime) : Boolean;
  VAR
    FileHandle : Integer;
    FileTime : TFileTime;
    LastFileTime : TFileTime;
    LastSystemTime : TSystemTime;

  BEGIN
    Result := False;
    TRY
      FileHandle := 0;
      TRY
        DecodeDate(NewDateTime, LastSystemTime.wYear, LastSystemTime.wMonth, LastSystemTime.wDay);
        DecodeTime(NewDateTime, LastSystemTime.wHour, LastSystemTime.wMinute, LastSystemTime.wSecond, LastSystemTime.wMilliSeconds);

        IF SystemTimeToFileTime(LastSystemTime, LastFileTime) THEN BEGIN
          IF LocalFileTimeToFileTime(LastFileTime, FileTime) THEN BEGIN
            FileHandle := FileOpen(TempFileName, fmOpenReadWrite OR fmShareExclusive);
            IF FileHandle = -1 THEN
              ShowMessage('Error in setting last access time for file ' + TempFileName + ' : ' + SysErrorMessage(GetLastError))
            ELSE
              { SetFileTime's parameters are CreationTime, LastAccessTime, LastWriteTime }
              IF SetFileTime(FileHandle, NIL, @FileTime, NIL) THEN
                Result := True;
          END;
        END;
      FINALLY
        FileClose(FileHandle);
      END; {TRY}
    EXCEPT
      ON E : Exception DO
        ShowMessage('SetFileLastAccessTime :' + E.ClassName +' error raised, with message : ' + E.Message);
    END; {TRY}
  END; { SetFileLastAccessTime }

BEGIN
  TRY
    WITH SelectedFileRec DO BEGIN
      IF ZoomPlayerTCPClient <> NIL THEN BEGIN

        MSGMemo.Lines.Add('*** Disconnected' + CRLF);
        TCPConnectButton.Enabled := True;
        TCPConnectButton.Caption := 'TCP Connect';
        ZoomPlayerTCPSocket := NIL;

        { FWP additions }
        IF ZoomPlayerErrorFound THEN
          { do nothing to the filename }
          ZoomPlayerErrorFound := False
        ELSE BEGIN
          IF EndOfFile THEN BEGIN
            ElapsedTimeFromTCPStr := '';
            TotalTimeFromTCPStr := '';
            EndOfFile := False;
          END;

          IF TryStrToInt(ElapsedTimeFromTCPStr, I) THEN BEGIN
            { do not record times less than 5 seconds }
            IF I < 5 THEN
              SnapsFileNumberRename(SelectedFile_Name, '')
            ELSE
              SnapsFileNumberRename(SelectedFile_Name, ElapsedTimeFromTCPStr);

            { Update the last access time, as Zoom Player doesn't seem to do it }
            SetFileLastAccessTime(PathName + SelectedFile_Name, Now);
          END;
        END;
        ElapsedTimeFromTCPStr := '';
        TotalTimeFromTCPStr := '';
      END;
    END; {WITH}
  EXCEPT
    ON E : Exception DO
      ShowMessage('ZoomPlayerTCPClientDisconnect : ' + E.ClassName +' error raised, with message : ' + E.Message);
  END; {TRY}
END; { ZoomPlayerTCPClientDisconnect }

PROCEDURE TZoomPlayerUnitForm.ZoomPlayerTCPClientRead(Sender : TObject; Socket : TCustomWinSocket);
VAR
  I : Integer;
  LParamNum : Integer;
  LParamStr : String;
  ObliquePos : Integer;
  S : String;
  TempTimeStr : String;
  WParamNum : Integer;
  WParamStr : String;

BEGIN
  LParamStr := '';

  IF Socket.Connected = True THEN BEGIN
    S := String(Socket.ReceiveText);
    TCPBuf := TCPBuf + S;

    WHILE Pos(CRLF, TCPBuf) > 0 DO BEGIN
      I := Pos(CRLF, TCPBuf);
      S := Copy(TCPBuf, 1, I - 1);

      IF NOT TryStrToInt(Copy(S, 1, 4), LParamNum) THEN
        Exit;

      IF NOT TryStrToInt(Copy(S, 6, 2), WParamNum) THEN
        WParamNum := 0;

      LParamStr := '';
      CASE LParamNum Of
        0000 :
          LParamStr := 'Application Name';
        0001 :
          LParamStr := 'Application Version';
        0100 :
          LParamStr := 'Ping';
        1000 :
          BEGIN
            LParamStr := 'State Change';
            CASE WParamNum OF
              0 :
                WParamStr := 'Closed';
              1 :
                WParamStr := 'Stopped [not DVD]';
              2 :
                WParamStr := 'Paused';
              3 :
                WParamStr := 'Playing';
            END; {CASE}
          END;
        1010 :
          BEGIN
            LParamStr := 'Current Fullscreen State';
            CASE WParamNum OF
              0 :
                WParamStr := 'Windowed';
              1 :
                WParamStr := 'Fullscreen';
            END; {CASE}
          END;
        1020 :
          BEGIN
            LParamStr := 'Current FastForward State';
            CASE WParamNum OF
              0 :
                WParamStr := 'Disabled';
              1 :
                WParamStr := 'Enabled';
            END; {CASE}
          END;
        1021 :
          BEGIN
            LParamStr := 'Current Rewind State';
            CASE WParamNum OF
              0 :
                WParamStr := 'Disabled';
              1 :
                WParamStr := 'Enabled';
            END; {CASE}
          END;
        1090 :
          LParamStr := 'Timeline Text';
        1100 :
          BEGIN
            { decode the elapsed time }
            LParamStr := 'Position Update';

            S := Copy(S, 6);

            ObliquePos := Pos('/', S);

            TempTimeStr := Copy(S, 1, ObliquePos - 2);
            IF Length(TempTimeStr) = 7 THEN
              TempTimeStr := '0' + TempTimeStr;

            { remove the colons }
            ElapsedTimeFromTCPStr := ReplaceStr(TempTimeStr, ':', '');

            TempTimeStr := Copy(S, ObliquePos + 2);
            S := Copy(S, ObliquePos + 2);

            IF Length(S) = 7 THEN
              TempTimeStr := '0' + S;

            TotalTimeFromTCPStr := ReplaceStr(TempTimeStr, ':', '');
          END;
        1110 :
          LParamStr := 'Current Duration';
        1120 :
          LParamStr := 'Current Position';
        1130 :
          LParamStr := 'Current Frame Rate (realtime)';
        1140 :
          LParamStr := 'Estimated Frame Rate';
        1200 :
          LParamStr := 'OSD Message';
        1201 :
          LParamStr := 'OSD Message Off';
        1300 :
          BEGIN
            LParamStr := 'Current Play Mode';
            CASE WParamNum OF
              0 :
                WParamStr := 'DVD Mode';
              1 :
                WParamStr := 'Media Mode';
              2 :
                WParamStr := 'Audio Mode';
            END; {CASE}
          END;
        1310 :
          LParamStr := 'TV/PC Mode';
        1400 :
          LParamStr := 'DVD Title Change';
        1401 :
          LParamStr := 'DVD Title Count';
        1410 :
          LParamStr := 'DVD Domain Change';
        1420 :
          LParamStr := 'DVD Menu Mode';
        1450 :
          LParamStr := 'DVD Unique String';
        1500 :
          LParamStr := 'DVD Chapter Change';
        1501 :
          LParamStr := 'DVD Chapter Count';
        1600 :
          LParamStr := 'DVD/Media Active Audio Track';
        1601 :
          LParamStr := 'DVD/Media Audio Track Count';
        1602 :
          LParamStr := 'DVD Audio Name';
        1700 :
          LParamStr := 'DVD/Media Active Sub';
        1701 :
          LParamStr := 'DVD/Media Sub Count';
        1702 :
          LParamStr := 'DVD Sub Name';
        1704 :
          BEGIN
            LParamStr := 'DVD Sub Disabled';
            CASE WParamNum OF
              0 :
                WParamStr := 'Sub Visible';
              1 :
                WParamStr := 'Sub Hidden';
            END; {CASE}
          END;
        1750 :
          LParamStr := 'DVD Angle Change';
        1751 :
          LParamStr := 'DVD Angle Count';
        1800 :
          LParamStr := 'Currently Loaded File';
        1810 :
          LParamStr := 'Current Playlist...';
        1811 :
          LParamStr := 'Playlist Change : Number of New Items';
        1855 :
          BEGIN
            LParamStr := 'End of File';
            EndOfFile := True;
          END;
        1900 :
          LParamStr := 'File PlayList Pos';
        1920 :
          BEGIN
            LParamStr := 'Playlist Cleared Acknowledgment';
            PlaylistClearedAcknowledgmentReceived := True;
          END;
        1950 :
          LParamStr := 'A Play List file was removed';
        2000 :
          LParamStr := 'Video Resolution';
        2100 :
          LParamStr := 'Video Frame Rate';
        2200 :
          LParamStr := 'AR Change';
        2210 :
          BEGIN
            LParamStr := 'DVD AR Mode Change';
            CASE WParamNum OF
              0 :
                WParamStr := 'Unknown';
              1 :
                WParamStr := 'Full-Frame';
              2 :
                WParamStr := 'Letterbox';
              3 :
                WParamStr := 'Anamorphic';
            END; {CASE}
          END;
        2300 :
          LParamStr := 'Current Audio Volume';
        2400 :
          LParamStr := 'Media Content Tags';
        2500 :
          LParamStr := 'A CD/DVD Was Inserted';
        2611 :
          LParamStr := 'Video Display Area X-Ofs';
        2621 :
          LParamStr := 'Video Display Area Y-Ofs';
        2631 :
          LParamStr := 'Video Display Area Width';
        2641 :
          LParamStr := 'Video Display Area Height';
        2700 :
          LParamStr := 'Play Rate Changed';
        2710 :
          BEGIN
            LParamStr := 'Random Play State';
            CASE WParamNum OF
              0 :
                WParamStr := 'Disabled';
              1 :
                WParamStr := 'Enabled';
            END; {CASE}
          END;
        3000 :
          BEGIN
            LParamStr := 'ZP Error Message';
            ZoomPlayerErrorFound := True;
          END;
        3100 :
          LParamStr := 'Nav Dialog Opened';
        3110 :
          LParamStr := 'Nav Dialog Closed';
        3200 :
          LParamStr := 'Screen Saver Mode';
        4000 :
          LParamStr := 'Virtual Keyboard Input Result';
        5100 :
          LParamStr := 'ZP Function Called';
        5110 :
          LParamStr := 'ZP ExFunction Called';
        5120 :
          LParamStr := 'ZP ScanCode Called';
        6000 :
          LParamStr := 'Shared Items List';
        6010 :
          LParamStr := 'Add Shared files ack.';
        9000 :
          LParamStr := 'Flash Mouse Click';
      END; {CASE}

      Delete(TCPBuf, 1, I + 1);
      MSGMemo.Lines.Add('IN  '
                        + FillSpace(IntToStr(GetTickCount - ConnectTS), 8) + 'ms :'
                        + ' '
                        + Copy(S, 1, 4)
                        + ' '
                        + LParamStr + IfThen(WParamStr <> '', ' : ' + WParamStr, ' ' + Copy(S, 6)));

// This commented out as program never reaches "If stopped" and the forms remain hidden for ever!
//        IF Started THEN BEGIN
//          IF ImageViewForm <> NIL THEN
//            ImageViewForm.Hide;
//        END;
//
//        IF Stopped THEN BEGIN
//          IF ImageViewForm <> NIL THEN
//            ImageViewForm.Show;
//          ExplorerForm.Show;
//        END;

      // Trigger event on stop example :
      {IF S = '1000 0' THEN BEGIN
        TCPCommand.Text := '5100 fnMediaNav';
        Application.ProcessMessages;
        SendButton.Click;
      END;}
    END;
  END;
END; { ZoomPlayerTCPClientRead }

PROCEDURE TZoomPlayerUnitForm.ZoomPlayerTCPClientError(Sender : TObject; Socket : TCustomWinSocket; ErrorEvent : TErrorEvent; VAR ErrorCode : Integer);
BEGIN
  IF ErrorCode = 10061 THEN BEGIN
    Beep;
    MSGMemo.Lines.Add('*** Error #10061 - Unable to Connect');
    ShowMessage('Unable to Connect to ZoomPlayer');
//    IF TestMode THEN { +++ }
      CloseProgram('Zoom Player');
//    ZoomPlayerUnitForm.Visible := True;
    ErrorCode := 0;
  END;

  IF ErrorCode = 10053 THEN BEGIN
    MSGMemo.Lines.Add('*** Error #10053 - Server has disconnected/shutdown');
//    ShowMessage('Server has disconnected/shutdown');
//    ZoomPlayerUnitForm.Visible := True;
//    MakeSound;
    ZoomPlayerUnitForm.TCPConnectButtonClick(Sender);
    ErrorCode := 0;
  END;
END; { ZoomPlayerTCPClientError }

PROCEDURE TZoomPlayerUnitForm.ZoomPlayerTCPSendText(S : String);
BEGIN
  IF ZoomPlayerTCPSocket <> NIL THEN
    ZoomPlayerTCPSocket.SendText(AnsiString(S + CRLF));
END; { ZoomPlayerTCPSendText }

PROCEDURE TZoomPlayerUnitForm.ClearButtonClick(Sender : TObject);
BEGIN
  MSGMemo.Clear;
END; { ClearButtonClick }

END { ZoomPlayerUnit}.
