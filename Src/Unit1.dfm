object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #8220#33821#33673#8221#39764#20861#20105#38712'3'#22320#22270#33050#26412#30149#27602#25195#25551#24037#20855' -by Yoie'
  ClientHeight = 340
  ClientWidth = 540
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object g1: TGauge
    Left = 26
    Top = 49
    Width = 487
    Height = 24
    Progress = 0
  end
  object btn1: TButton
    Left = 440
    Top = 16
    Width = 75
    Height = 25
    Caption = #25195#25551
    TabOrder = 0
    OnClick = btn1Click
  end
  object lbledt1: TLabeledEdit
    Left = 80
    Top = 18
    Width = 337
    Height = 21
    EditLabel.Width = 52
    EditLabel.Height = 13
    EditLabel.Caption = #25195#25551#30446#24405':'
    LabelPosition = lpLeft
    TabOrder = 1
  end
  object grp1: TGroupBox
    Left = 24
    Top = 79
    Width = 491
    Height = 250
    Caption = #25195#25551#26085#24535
    TabOrder = 2
    object mmo1: TMemo
      Left = 2
      Top = 15
      Width = 487
      Height = 233
      Align = alClient
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
end
