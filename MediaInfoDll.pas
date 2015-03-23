//Two versions :
//MediaInfo_* : Unicode
//MediaInfoA_* : Ansi

unit MediaInfoDll;

interface
uses
{$IFDEF WIN32}
  Windows;
{$ELSE}
  Wintypes, WinProcs;
{$ENDIF}

function MediaInfo_New(): Cardinal cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

procedure MediaInfo_Delete(Handle: Cardinal) cdecl  {$IFDEF WIN32} stdcall {$ENDIF}; 

function MediaInfo_Open(Handle: Cardinal;
                        File__: PWideChar): Cardinal cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

procedure MediaInfo_Close(Handle: Cardinal) cdecl  {$IFDEF WIN32} stdcall {$ENDIF}; 

function MediaInfo_Inform(Handle: Cardinal;
                        Reserved: Integer): PWideChar cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

function MediaInfo_GetI(Handle: Cardinal; 
                        StreamKind: Integer; 
                        StreamNumber: Integer; 
                        Parameter: Integer;
                        KindOfInfo: Integer): PWideChar cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

function MediaInfo_Get(Handle: Cardinal;
                       StreamKind: Integer;
                       StreamNumber: Integer;
                       Parameter: PWideChar;
                       KindOfInfo: Integer;
                       KindOfSearch: Integer): PWideChar cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

function MediaInfo_Option(Handle: Cardinal;
                       Option: PWideChar;
                       Value: PWideChar): PWideChar cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

function MediaInfo_State_Get(Handle: Cardinal): Integer cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

function MediaInfo_Count_Get(Handle: Cardinal;
                             StreamKind: Integer;
                             StreamNumber: Integer): Integer cdecl  {$IFDEF WIN32} stdcall {$ENDIF};


function MediaInfoA_New(): Cardinal cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

procedure MediaInfoA_Delete(Handle: Cardinal) cdecl  {$IFDEF WIN32} stdcall {$ENDIF}; 

function MediaInfoA_Open(Handle: Cardinal;
                        File__: PChar): Cardinal cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

procedure MediaInfoA_Close(Handle: Cardinal) cdecl  {$IFDEF WIN32} stdcall {$ENDIF}; 

function MediaInfoA_Inform(Handle: Cardinal;
                        Reserved: Integer): PChar cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

function MediaInfoA_GetI(Handle: Cardinal; 
                        StreamKind: Integer; 
                        StreamNumber: Integer; 
                        Parameter: Integer; 
                        KindOfInfo: Integer): PChar cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

function MediaInfoA_Get(Handle: Cardinal;
                       StreamKind: Integer;
                       StreamNumber: Integer;
                       Parameter: PChar;
                       KindOfInfo: Integer;
                       KindOfSearch: Integer): PChar cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

function MediaInfoA_Option(Handle: Cardinal;
                       Option: PChar;
                       Value: PChar): PChar cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

function MediaInfoA_State_Get(Handle: Cardinal): Integer cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

function MediaInfoA_Count_Get(Handle: Cardinal;
                             StreamKind: Integer;
                             StreamNumber: Integer): Integer cdecl  {$IFDEF WIN32} stdcall {$ENDIF};


implementation

function MediaInfo_New; external 'MediaInfo.Dll';
procedure MediaInfo_Delete; external 'MediaInfo.Dll';
function MediaInfo_Open; external 'MediaInfo.Dll';
procedure MediaInfo_Close; external 'MediaInfo.Dll';
function MediaInfo_Inform; external 'MediaInfo.Dll';
function MediaInfo_GetI; external 'MediaInfo.Dll';
function MediaInfo_Get; external 'MediaInfo.Dll';
function MediaInfo_Option; external 'MediaInfo.Dll';
function MediaInfo_State_Get; external 'MediaInfo.Dll';
function MediaInfo_Count_Get; external 'MediaInfo.Dll';

function MediaInfoA_New; external 'MediaInfo.Dll';
procedure MediaInfoA_Delete; external 'MediaInfo.Dll';
function MediaInfoA_Open; external 'MediaInfo.Dll';
procedure MediaInfoA_Close; external 'MediaInfo.Dll';
function MediaInfoA_Inform; external 'MediaInfo.Dll';
function MediaInfoA_GetI; external 'MediaInfo.Dll';
function MediaInfoA_Get; external 'MediaInfo.Dll';
function MediaInfoA_Option; external 'MediaInfo.Dll';
function MediaInfoA_State_Get; external 'MediaInfo.Dll';
function MediaInfoA_Count_Get; external 'MediaInfo.Dll';

end.
