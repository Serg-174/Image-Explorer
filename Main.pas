unit Main;

interface

uses
  ShellApi, Winapi.Windows, Winapi.Messages, System.SysUtils,
  System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  System.ImageList, GDIPAPI, GDIPOBJ, Vcl.ImgList, Vcl.Grids, Vcl.ExtCtrls;

type
  TfmMain = class(TForm)
    tvFolders: TTreeView;
    ilExplorer: TImageList;
    Splitter1: TSplitter;
    ilThumbs: TImageList;
    StatusBar1: TStatusBar;
    lvThumbs: TListView;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tvFoldersExpanding(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
    procedure tvFoldersGetImageIndex(Sender: TObject; Node: TTreeNode);
    procedure tvFoldersChange(Sender: TObject; Node: TTreeNode);
    procedure tvFoldersChanging(Sender: TObject; Node: TTreeNode; var AllowChange: Boolean);
    procedure lvThumbsGetImageIndex(Sender: TObject; Item: TListItem);
  private
    procedure PopulateDriveList;
    procedure ScanNextLevel(AParentNode: TTreeNode);
    procedure StartImgFinder(ACurDir: string);
  public
  end;

type
  TImgFinder = class(TThread)
  private
    FImgFiles: TStringList;
    FCurDir: string;
  protected
    procedure Execute; override;
    procedure CleanAll;
    function IsGoodFormat(AFileName: string): Boolean;
    procedure MakeThumb(var ABmp: TBitmap; AFileName: string);
  public
    constructor Create(ADir: string);
    destructor Destroy; override;
  end;

var
  fmMain: TfmMain;
  Images: TStringList;
  ImgFinder: TImgFinder;

implementation

{$R *.dfm}

uses Common;

procedure TfmMain.ScanNextLevel(AParentNode: TTreeNode);
var
  SRec, SRecChild: TSearchRec;
  Node: TTreeNode;
  Path: string;
begin
  Node := AParentNode;
  Path := IncludeTrailingPathDelimiter(GetNodePath(Node));
  try
    if FindFirst(Path + '*.*', faDirectory, SRec) = 0 then
    begin
      repeat
        if (SRec.Name <> '.') and (SRec.Name <> '..') then
          if (SRec.Attr and faDirectory) = faDirectory then
          begin
            Node := tvFolders.Items.AddChild(AParentNode, SRec.Name);
            Node.HasChildren := False;
            try
              if FindFirst(Path + SRec.Name + '\*.*', faDirectory, SRecChild) = 0 then
              // Чтоб рисовать стрелочку (плюсик) или не рисовать
              begin
                repeat
                  if (SRecChild.Name <> '.') and (SRecChild.Name <> '..') then
                    if (SRecChild.Attr and faDirectory) = faDirectory then
                    begin
                      Node.HasChildren := True;
                      Break;
                    end;
                until (FindNext(SRecChild) <> 0) or Node.HasChildren;
              end;
            finally
              FindClose(SRecChild);
            end;
          end;
      until FindNext(SRec) <> 0;
    end
    else
      AParentNode.HasChildren := False;
  finally
    FindClose(SRec);
  end;

end;

procedure TfmMain.PopulateDriveList;
var
  LDLength, I: Integer;
  LDStr, LDSub: string;
  RootNode, Node: TTreeNode;
  LDName, FSName: array [0 .. MAX_PATH - 1] of Char;
  LDSerial, MaxLength, FSFlags: LongWord;
  LDrive: PLDriveRec;
  Cur: TCursor;
const
  RootNodeText = 'My Computer';
begin
  Cur := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  tvFolders.Items.BeginUpdate;
  try
    LDLength := GetLogicalDriveStrings(0, nil);
    SetLength(LDStr, LDLength);
    GetLogicalDriveStrings(LDLength, @LDStr[1]);
    I := 1;
    RootNode := tvFolders.Items.Add(nil, RootNodeText);
    while I < LDLength do
    begin
      LDSub := Copy(LDStr, I, 3);
      Inc(I, Length(LDSub) + 1);
      New(LDrive);
      LDrive^.DisplayName := ExcludeTrailingPathDelimiter(LDSub);
      LDrive^.Name := LDSub;
      LDName := '';
      GetVolumeInformation(PChar(LDSub), LDName, MAX_PATH, @LDSerial, MaxLength, FSFlags, FSName, MAX_PATH);
      // Нужна только метка тома
      if LDName <> '' then
        LDrive.DisplayName := format('%s (%s)', [LDName, LDrive.DisplayName]);
      Node := tvFolders.Items.AddChildObject(RootNode, LDrive^.DisplayName, LDrive);
      Node.HasChildren := True;
    end;
    RootNode.Expanded := True;
  finally
    tvFolders.Items.EndUpdate;
    Screen.Cursor := Cur;
  end;
end;

procedure TfmMain.StartImgFinder(ACurDir: string);
begin
  ImgFinder := TImgFinder.Create(ACurDir);
end;

procedure TfmMain.tvFoldersChange(Sender: TObject; Node: TTreeNode);
var
  Path: string;
begin
  if Node.Parent = nil then
    Exit;

  Path := IncludeTrailingPathDelimiter(GetNodePath(Node));
  StartImgFinder(Path);
  StatusBar1.Panels[0].Text := Path;
end;

procedure TfmMain.tvFoldersChanging(Sender: TObject; Node: TTreeNode; var AllowChange: Boolean);
begin
  FreeAndNil(ImgFinder);
end;

procedure TfmMain.tvFoldersExpanding(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
var
  Cur: TCursor;
begin
  if Node.Parent = nil then
    Exit;
  Cur := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  tvFolders.Items.BeginUpdate;

  try
    Node.DeleteChildren;
    ScanNextLevel(Node);

  finally
    tvFolders.Items.EndUpdate;
    Screen.Cursor := Cur;
  end;
end;

procedure TfmMain.tvFoldersGetImageIndex(Sender: TObject; Node: TTreeNode);
begin
  if Node.Parent = nil then
  begin
    Node.ImageIndex := GetMyComputerIconIndex;
    Node.SelectedIndex := Node.ImageIndex;
    Exit;
  end;

  Node.ImageIndex := GetShellIconIndex(GetNodePath(Node), Node.Expanded);
  Node.SelectedIndex := Node.ImageIndex;
end;

procedure TfmMain.FormCreate(Sender: TObject);
var
  FImageListHandle: Cardinal;
  AInfo: TSHFileInfo;
begin
  Images := TStringList.Create;
  FImageListHandle := SHGetFileInfo('C:\', 0, AInfo, SizeOf(AInfo), SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
  ilExplorer.Handle := FImageListHandle;
  tvFolders.Images := ilExplorer;
  PopulateDriveList;
  ilThumbs.Height := ThumbHeight + ThumbBottomHeigh;
  ilThumbs.Width := ThumbWidth;
  fmMain.lvThumbs.DoubleBuffered := True;
end;

procedure TfmMain.FormDestroy(Sender: TObject);
var
  I: Integer;
  Node: TTreeNode;
begin
  Node := tvFolders.Items[0];
  for I := 0 to Node.Count - 1 do
    Dispose(PLDriveRec(Node.Item[I].Data));
  Images.Free;

  FreeAndNil(ImgFinder);
end;

procedure TfmMain.lvThumbsGetImageIndex(Sender: TObject; Item: TListItem);
begin
  Item.ImageIndex := Item.Index;
end;

{ TImgFinder }

constructor TImgFinder.Create(ADir: string);
begin
  inherited Create;
  FCurDir := ADir;
  FImgFiles := TStringList.Create;
end;

destructor TImgFinder.Destroy;
begin
  FImgFiles.Free;
  inherited Destroy;
end;

procedure TImgFinder.Execute;
var
  SRec: TSearchRec;
  FindPic: Integer;
  Item: TListItem;
  Bmp: TBitmap;
  TC: Cardinal;
const
  UpdateStatusCount = 10;
begin
  TC := GetTickCount;
  Synchronize(
    procedure
    begin
      fmMain.StatusBar1.Panels[1].Text := '';
    end);
  Synchronize(CleanAll);
  try
    FindPic := FindFirst(FCurDir + '*.*', faAnyFile, SRec);
    while (FindPic = 0) and (not Terminated) do
    begin
      if ((SRec.Attr and faDirectory) = faDirectory) and ((SRec.Name = '.') or (SRec.Name = '..')) then
      begin
        FindPic := FindNext(SRec);
        Continue;
      end;
      if IsGoodFormat(SRec.Name) then
      begin
        FImgFiles.Add(FCurDir + SRec.Name);
        Bmp := TBitmap.Create;
        try
          Bmp.Canvas.Lock;
          try
            MakeThumb(Bmp, FCurDir + SRec.Name);
          finally
            Bmp.Canvas.Unlock;
          end;
          Synchronize(
            procedure
            begin
              with fmMain do
              begin
                lvThumbs.Items.BeginUpdate;
                ilThumbs.BeginUpdate;
                try
                  Item := fmMain.lvThumbs.Items.Add;
                  Item.Caption := ''; // SRec.Name;
                  ilThumbs.Add(Bmp, nil);
                finally
                  ilThumbs.EndUpdate;
                  lvThumbs.Items.EndUpdate;
                end;
              end;
            end);
        finally
          Bmp.Free;
        end;
      end;
      FindPic := FindNext(SRec);
    end;
  finally
    FindClose(SRec);
  end;

  Synchronize(
    procedure
    begin
      fmMain.StatusBar1.Panels[1].Text := format('Файлов: %d (%d ms)', [fmMain.lvThumbs.Items.Count, GetTickCount - TC]);
    end);
end;

procedure TImgFinder.CleanAll;
begin
  FImgFiles.Clear;
  fmMain.ilThumbs.Clear;
  fmMain.lvThumbs.Items.Clear;
end;

function TImgFinder.IsGoodFormat(AFileName: string): Boolean;
const
  Pics = ImgFormats;
begin
  Result := False;
  if Pos(UpperCase(ExtractFileExt(AFileName)), Pics) > 0 then
    Result := True;
end;

procedure TImgFinder.MakeThumb(var ABmp: TBitmap; AFileName: string);
var
  FN: string;
  Graphics: TGPGraphics;
  Image, Thumbnail: TGPImage;
  X, Y, W: Integer;
  ThumbSize: TPoint;
begin
  FN := ExtractFileName(AFileName);
  ABmp.Width := ThumbWidth;
  ABmp.Height := ThumbHeight + ThumbBottomHeigh;
  Graphics := TGPGraphics.Create(ABmp.Canvas.Handle);
  Image := TGPImage.Create(AFileName);
  Thumbnail := nil;
  try
    ThumbSize.X := Image.GetWidth;
    ThumbSize.Y := Image.GetHeight;
    ThumbSize := CalcThumbSize(ThumbSize);
    Thumbnail := Image.GetThumbnailImage(ThumbSize.X, ThumbSize.Y, nil, nil);
    X := Trunc((ThumbWidth - ThumbSize.X) / 2);
    Y := Trunc((ThumbHeight - ThumbSize.Y) / 2);
    Graphics.SetSmoothingMode(SmoothingModeHighSpeed);

    with ABmp.Canvas do
    begin
      Brush.Color := clBtnFace;
      Pen.Color := clBtnShadow;
      FillRect(Rect(0, 0, ThumbWidth, ThumbHeight + ThumbBottomHeigh));
      LineTo(0, ThumbHeight);
      LineTo(ThumbWidth - 1, ThumbHeight);
      LineTo(ThumbWidth - 1, 0);
      MoveTo(0, 0);
      LineTo(ThumbWidth, 0);

      W := TextWidth(FN) div 2;
      TextOut((ThumbWidth div 2) - W, ThumbHeight + 2, FN);
    end;

    Graphics.DrawImage(Thumbnail, X, Y, ThumbSize.X, ThumbSize.Y);
    {
      try
      if (not FileExists('E:\!\2\' + ChangeFileExt(FN, '.bmp'))) then
      ABmp.SaveToFile('E:\!\2\' + ChangeFileExt(FN, '.bmp'));
      except
      end;
    }
  finally
    Image.Free;
    Thumbnail.Free;
    Graphics.Free;
  end;

end;



initialization

ReportMemoryLeaksOnShutdown := True;

end.
