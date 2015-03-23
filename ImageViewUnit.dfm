object ImageViewUnitForm: TImageViewUnitForm
  Left = 0
  Top = 120
  Width = 762
  Height = 724
  VertScrollBar.Tracking = True
  AutoScroll = True
  Caption = 'ImageViewUnitForm'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poDesigned
  Scaled = False
  SnapBuffer = 0
  WindowState = wsMaximized
  OnClick = ImageViewUnitFormClick
  OnClose = ImageViewFormClose
  OnCreate = ImageViewUnitFormCreate
  OnKeyDown = ImageViewUnitFormKeyDown
  OnMouseWheel = ImageViewUnitFormMouseWheel
  OnShow = ImageViewUnitFormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ImageViewUnitEditPanel: TPanel
    Left = 272
    Top = 129
    Width = 169
    Height = 65
    BevelOuter = bvNone
    Color = clWindow
    ParentBackground = False
    TabOrder = 0
    Visible = False
    object ImageViewUnitFileNameEdit: TEdit
      Left = 8
      Top = 8
      Width = 1000
      Height = 21
      ReadOnly = True
      TabOrder = 0
      Visible = False
      OnEnter = ImageViewUnitFileNameEditEnter
      OnExit = ImageViewUnitFileNameEditExit
      OnKeyDown = ImageViewUnitFileNameEditKeyDown
    end
    object ImageViewUnitFileNameNumbersEdit: TEdit
      Left = 8
      Top = 35
      Width = 153
      Height = 21
      ReadOnly = True
      TabOrder = 1
      Text = 'New number here'
      Visible = False
      OnEnter = ImageViewUnitFileNameNumbersEditEnter
      OnExit = ImageViewUnitFileNameNumbersEditExit
      OnKeyDown = ImageViewUnitFileNameNumbersEditKeyDown
      OnKeyPress = ImageViewUnitFileNameNumbersEditKeyPress
    end
  end
  object ImageViewUnitStopButton: TButton
    Left = 296
    Top = 328
    Width = 177
    Height = 73
    Caption = 'Stop'
    TabOrder = 1
    OnClick = ImageViewUnitStopButtonClick
  end
  object ImageViewUnitFindDialog: TFindDialog
    Options = [frDown, frHideUpDown]
    OnFind = ImageViewUnitFindDialogFind
    Left = 544
    Top = 168
  end
end
