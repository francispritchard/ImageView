object ZoomPlayerUnitForm: TZoomPlayerUnitForm
  Left = 0
  Top = 228
  Caption = 'Zoom Player Communication & Control Sample Application v3.2'
  ClientHeight = 549
  ClientWidth = 787
  Color = clBtnFace
  Constraints.MinHeight = 300
  Constraints.MinWidth = 300
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  OnShow = FormShow
  DesignSize = (
    787
    549)
  PixelsPerInch = 96
  TextHeight = 13
  object ZoomPlayerUnitIncomingGroupBox: TGroupBox
    Left = 6
    Top = 168
    Width = 768
    Height = 366
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = ' Traffic log : '
    TabOrder = 0
    DesignSize = (
      768
      366)
    object ZoomPlayerUnitMsgMemo: TMemo
      Left = 8
      Top = 20
      Width = 751
      Height = 307
      Anchors = [akLeft, akTop, akRight, akBottom]
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object ZoomPlayerUnitClearButton: TButton
      Left = 634
      Top = 333
      Width = 95
      Height = 25
      Caption = 'Clear'
      TabOrder = 1
      OnClick = ZoomPlayerUnitClearButtonClick
    end
  end
  object ConnectPanel: TPanel
    Left = 8
    Top = 5
    Width = 768
    Height = 157
    Anchors = [akLeft, akTop, akRight]
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 1
    DesignSize = (
      768
      157)
    object ZoomPlayerUnitLabelConnectTo: TLabel
      Left = 522
      Top = 13
      Width = 55
      Height = 13
      Anchors = [akTop, akRight]
      Caption = 'Connect to:'
      ExplicitLeft = 300
    end
    object ZoomPlayerUnitLabelTextEntry: TLabel
      Left = 8
      Top = 43
      Width = 75
      Height = 13
      Caption = 'TCP Text Entry:'
    end
    object SendButton: TSpeedButton
      Left = 659
      Top = 125
      Width = 100
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Send Text'
      OnClick = ZoomPlayerUnitSendButtonClick
    end
    object ZoomPlayerUnitWinAPIConnectButton: TButton
      Left = 109
      Top = 7
      Width = 172
      Height = 25
      Caption = 'SendMessage (WinAPI) Connect'
      TabOrder = 0
      OnClick = ZoomPlayerUnitWinAPIConnectButtonClick
    end
    object ZoomPlayerUnitTCPConnectButton: TButton
      Left = 8
      Top = 12
      Width = 95
      Height = 25
      Caption = 'TCP Connect'
      TabOrder = 1
      OnClick = ZoomPlayerUnitTCPConnectButtonClick
    end
    object ZoomPlayerUnitBrowseButton: TButton
      Left = 8
      Top = 125
      Width = 100
      Height = 25
      Caption = 'Browse for File'
      TabOrder = 2
      OnClick = ZoomPlayerUnitBrowseButtonClick
    end
    object ZoomPlayerUnitTCPAddress: TEdit
      Left = 583
      Top = 9
      Width = 117
      Height = 21
      Anchors = [akTop, akRight]
      TabOrder = 4
      Text = '127.0.0.1'
    end
    object ZoomPlayerUnitPortEdit: TEdit
      Left = 706
      Top = 9
      Width = 55
      Height = 21
      Anchors = [akTop, akRight]
      TabOrder = 5
      Text = '4769'
    end
    object ZoomPlayerUnitTCPCommand: TMemo
      Left = 8
      Top = 59
      Width = 751
      Height = 60
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 6
    end
    object ZoomPlayerUnitPlayButton: TButton
      Left = 114
      Top = 123
      Width = 100
      Height = 25
      Caption = 'Play/Pause'
      TabOrder = 3
      OnClick = ZoomPlayerUnitPlayButtonClick
    end
    object ZoomPlayerUnitTestButton: TButton
      Left = 220
      Top = 125
      Width = 100
      Height = 25
      BiDiMode = bdLeftToRight
      Caption = 'Test'
      ParentBiDiMode = False
      TabOrder = 7
      OnClick = ZoomPlayerUnitTestButtonClick
    end
  end
  object ZoomPlayerUnitTimer: TTimer
    OnTimer = ZoomPlayerUnitTimerTick
    Left = 496
    Top = 125
  end
end
