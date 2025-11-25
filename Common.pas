unit Common;

interface

uses ShellApi, ShlObj, Winapi.Windows, Vcl.ComCtrls, Vcl.Forms;

type
  PLDriveRec = ^TLDriveRec;

  TLDriveRec = record
    DisplayName: string;
    Name: string;
  end;

const
  ThumbWidth = 120;
  ThumbHeight = 90;
  ThumbBottomHeigh = 20;
  ThumbSep = 4;
  ThumbRatio = ThumbWidth / ThumbHeight;
  ImgFormats = '.JPG.PNG.BMP.GIF.ICO.WMF.JPEG.TIF.TIFF';

function CalcThumbSize(APicSize: TPoint): TPoint;
function GetMyComputerIconIndex: Integer;
function GetShellIconIndex(const AName: string; AExpanded: Boolean = False): Integer;
function GetNodePath(ANode: TTreeNode): string;

implementation

function GetNodePath(ANode: TTreeNode): string;
var
  Path: string;
  Node: TTreeNode;
begin
  Result := '';
  Node := ANode;
  if Node.Data <> nil then
    Path := PLDriveRec(ANode.Data)^.Name
  else
    Path := ANode.Text;
  while Node.Parent.Parent <> nil do
  begin
    Node := Node.Parent;
    if Node.Data <> nil then
      Path := PLDriveRec(Node.Data)^.Name + Path
    else
      Path := Node.Text + '\' + Path;
  end;
  Result := Path;
end;

function CalcThumbSize(APicSize: TPoint): TPoint;
var
  ImgRatio: Double;
begin
  if APicSize.Y = 0 then
    Exit;

  ImgRatio := APicSize.X / APicSize.Y;

  Result.X := ThumbWidth;
  Result.Y := ThumbHeight;

  if (ThumbWidth > APicSize.X) and (ThumbHeight > APicSize.Y) then
  begin
    Result.X := APicSize.X;
    Result.Y := APicSize.Y;
    Exit;
  end;

  if ThumbRatio < ImgRatio then
  begin
    Result.Y := Round(ThumbWidth / ImgRatio);
    Exit;
  end;

  if ThumbRatio > ImgRatio then
  begin
    Result.X := Round(ThumbHeight * ImgRatio);
    Exit;
  end;

end;

function GetMyComputerIconIndex: Integer;
var
  PIDL: PItemIDList;
  AInfo: TSHFileInfo;
begin
  SHGetSpecialFolderLocation(Application.Handle, CSIDL_DRIVES, PIDL);
  FillChar(AInfo, SizeOf(AInfo), 0);
  SHGetFileInfo(PChar(PIDL), 0, AInfo, SizeOf(TSHFileInfo), SHGFI_PIDL or SHGFI_SYSICONINDEX);
  Result := AInfo.iIcon;
  DestroyIcon(AInfo.hIcon);
end;

function GetShellIconIndex(const AName: string; AExpanded: Boolean = False): Integer;
var
  Flags: Integer;
  AInfo: TSHFileInfo;
begin
  FillChar(AInfo, SizeOf(AInfo), 0);
  Flags := SHGFI_SYSICONINDEX;
  if AExpanded then
    Flags := Flags or SHGFI_OPENICON;
  SHGetFileInfo(PChar(AName), 0, AInfo, SizeOf(AInfo), Flags);
  Result := AInfo.iIcon;
  DestroyIcon(AInfo.hIcon);
end;

end.
