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
  object IncomingGB: TGroupBox
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
    object MSGMemo: TMemo
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
    object ClearButton: TButton
      Left = 634
      Top = 333
      Width = 95
      Height = 25
      Caption = 'Clear'
      TabOrder = 1
      OnClick = ClearButtonClick
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
    object LabelConnectTo: TLabel
      Left = 522
      Top = 13
      Width = 55
      Height = 13
      Anchors = [akTop, akRight]
      Caption = 'Connect to:'
      ExplicitLeft = 300
    end
    object LabelTextEntry: TLabel
      Left = 8
      Top = 43
      Width = 75
      Height = 13
      Caption = 'TCP Text Entry:'
    end
    object SendButton: TSpeedButton
      Left = 659
      Top = 123
      Width = 100
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Send Text'
      OnClick = SendButtonClick
      ExplicitLeft = 437
    end
    object WinAPIConnectButton: TButton
      Left = 109
      Top = 7
      Width = 172
      Height = 25
      Caption = 'SendMessage (WinAPI) Connect'
      TabOrder = 0
      OnClick = WinAPIConnectButtonClick
    end
    object TCPConnectButton: TButton
      Left = 8
      Top = 7
      Width = 95
      Height = 25
      Caption = 'TCP Connect'
      TabOrder = 1
      OnClick = TCPConnectButtonClick
    end
    object BrowseButton: TButton
      Left = 8
      Top = 123
      Width = 100
      Height = 25
      Caption = 'Browse for File'
      TabOrder = 2
      OnClick = BrowseButtonClick
    end
    object TCPAddress: TEdit
      Left = 584
      Top = 9
      Width = 117
      Height = 21
      Anchors = [akTop, akRight]
      TabOrder = 4
      Text = '127.0.0.1'
    end
    object PortEdit: TEdit
      Left = 705
      Top = 9
      Width = 55
      Height = 21
      Anchors = [akTop, akRight]
      TabOrder = 5
      Text = '4769'
    end
    object TCPCommand: TMemo
      Left = 8
      Top = 59
      Width = 751
      Height = 60
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 6
    end
    object PlayButton: TButton
      Left = 114
      Top = 123
      Width = 100
      Height = 25
      Caption = 'Play/Pause'
      TabOrder = 3
      OnClick = PlayButtonClick
    end
    object TestButton: TButton
      Left = 220
      Top = 123
      Width = 100
      Height = 25
      BiDiMode = bdLeftToRight
      Caption = 'Test'
      ParentBiDiMode = False
      TabOrder = 7
      OnClick = TestButtonClick
    end
  end
end
