object fmMain: TfmMain
  Left = 0
  Top = 0
  Caption = 'Image Explorer'
  ClientHeight = 561
  ClientWidth = 784
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 281
    Top = 0
    Height = 542
    ExplicitLeft = 352
    ExplicitTop = 112
    ExplicitHeight = 100
  end
  object tvFolders: TTreeView
    Left = 0
    Top = 0
    Width = 281
    Height = 542
    Align = alLeft
    Images = ilExplorer
    Indent = 19
    StateImages = ilExplorer
    TabOrder = 0
    OnChange = tvFoldersChange
    OnChanging = tvFoldersChanging
    OnExpanding = tvFoldersExpanding
    OnGetImageIndex = tvFoldersGetImageIndex
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 542
    Width = 784
    Height = 19
    Panels = <
      item
        Width = 400
      end
      item
        Width = 50
      end>
  end
  object lvThumbs: TListView
    Left = 284
    Top = 0
    Width = 500
    Height = 542
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alClient
    Columns = <>
    ColumnClick = False
    GridLines = True
    IconOptions.Arrangement = iaLeft
    IconOptions.AutoArrange = True
    IconOptions.WrapText = False
    LargeImages = ilThumbs
    MultiSelect = True
    StyleElements = []
    ShowColumnHeaders = False
    TabOrder = 2
    OnGetImageIndex = lvThumbsGetImageIndex
  end
  object ilExplorer: TImageList
    Left = 100
    Top = 60
  end
  object ilThumbs: TImageList
    AllocBy = 1
    Left = 428
    Top = 40
  end
end
