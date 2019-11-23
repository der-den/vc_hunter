unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, CheckBoxThemed, RTTICtrls, Forms, Controls,
  Graphics, LCLIntf, Dialogs, StdCtrls, ComCtrls, Menus, ExtCtrls, Spin,
  Clipbrd, md5, Unit2;

type

  TRes = Record
    byte_difference    : Integer;
    shannon_entropy   : double;
    headerString : string;
  end;


  { TForm1 }

  TForm1 = class(TForm)
    Button_scanDirectory: TButton;
    Button_cancelSearch: TButton;
    CheckBox_onSignatureList: TCheckBoxThemed;
    CheckBox_skipMod512odd: TCheckBox;
    FloatSpinEdit_se_limit: TFloatSpinEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    ListBox: TListBox;
    ListView: TListView;
    MenuItem_ShowInHexViewer: TMenuItem;
    MenuItem_SaveListToTSV: TMenuItem;
    MenuItem_OpenPath: TMenuItem;
    MenuItem_CopyHeader: TMenuItem;
    MenuItem_separator1: TMenuItem;
    MenuItem_CopyFilename: TMenuItem;
    MenuItem_CopyPathAndFilename: TMenuItem;
    MenuItem_CopyPath: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem_CalcMD5selected: TMenuItem;
    MenuItem_CalcMD5AllFiles: TMenuItem;
    MenuItem_cpToclipboard: TMenuItem;
    MenuItem_clearList: TMenuItem;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    PopupMenu_ListView: TPopupMenu;
    SaveDialog: TSaveDialog;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    SpinEdit1: TSpinEdit;
    StatusBar: TStatusBar;
    procedure Button_cancelSearchClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ListViewColumnClick(Sender: TObject; Column: TListColumn);
    procedure MenuItem_CalcMD5AllFilesClick(Sender: TObject);
    procedure MenuItem_CalcMD5selectedClick(Sender: TObject);
    procedure MenuItem_clearListClick(Sender: TObject);
    procedure MenuItem_CopyFilenameClick(Sender: TObject);
    procedure MenuItem_CopyHeaderClick(Sender: TObject);
    procedure MenuItem_CopyPathAndFilenameClick(Sender: TObject);
    procedure MenuItem_CopyPathClick(Sender: TObject);
    procedure MenuItem_OpenPathClick(Sender: TObject);
    procedure MenuItem_SaveListToTSVClick(Sender: TObject);
    procedure MenuItem_ShowInHexViewerClick(Sender: TObject);
    procedure scanDirectory(Sender: TObject);
    procedure SortListView(Lv:TListView; Index:integer);
    function calcByteDivAndShannonEntropyFromFile(f:string):TRes;
  private

  public

  end;

var
  Form1: TForm1;
  cancelSearch : Boolean;
  searchRunning : Boolean;
  showDebug  : Boolean;
  starttimer : Int64;
  ScanTime : Int64;

implementation

uses uFilesig;
{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin

  showDebug := false;

  if ( showDebug = false ) then begin
     ListBox.Enabled := false;
     ListBox.Visible := false;
     ListView.Align  := AlClient;
  end;

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin

end;


procedure TForm1.scanDirectory(Sender: TObject);
var
  AllFiles   : TStringList;
  i, skipped,
  inList     : Integer;
  r          : TRes;
  newItem    : TListItem;

begin
  if SelectDirectoryDialog1.Execute then
  begin
      starttimer := gettickcount;
      Button_cancelSearch.Visible:=true;
      Button_scanDirectory.Visible:=false;
      cancelSearch:=false;
      searchRunning:=true;
      skipped := 0;
      inList  := 0;

      AllFiles := TStringList.Create;
      try
        StatusBar.SimpleText:=' Calculating files ..';
        Application.ProcessMessages;

        FindAllFiles(AllFiles,SelectDirectoryDialog1.FileName,'*.*',true);

        for i:=0 to AllFiles.Count-1 do
        begin

           if cancelSearch then
           begin
               break;                                                           // cancel clicked
           end;

           if FileSize(AllFiles[i]) > 4095 then                                 // skip all files under 4K
           begin
              if ( i mod 10 = 0 ) then begin

               StatusBar.SimpleText:=' Total: '+IntToStr(AllFiles.Count)+', Processed: '+IntToStr(i+1)+', Skipped: '+IntToStr(skipped) + ', Listed: '+IntToStr(inList)+', Time: ' +Inttostr(gettickcount - starttimer) + ' ms';
               Application.ProcessMessages;
              end;


              if CheckBox_skipMod512odd.Checked AND ((FileSize(AllFiles[i]) mod 512) <> 0) then         // skip mod512 <> 0
              begin
                 inc(skipped);
                 Continue;
              end;


              r := calcByteDivAndShannonEntropyFromFile(AllFiles[i]);                                   // shannon of first 4k

              if r.shannon_entropy < FloatSpinEdit_se_limit.Value then
              begin
                 inc(skipped);
                 Continue;
              end;

              if r.byte_difference > SpinEdit1.Value then
              begin
                 inc(skipped);
                 Continue;
              end;

              if CheckBox_onSignatureList.Checked and (TestFile(AllFiles[i]) = 'ext-match-sig' )then
              begin
                inc(skipped);
                Continue;
              end;

              // okay, no more skipping features, add to list:

              inc(inList);
              newItem := ListView.Items.Add;
              newItem.Caption := ExtractFileDir(AllFiles[i]);                   // 1 - filename
              newItem.SubItems.Add(ExtractFileName(AllFiles[i]));               // 2 (sub 0) - Path
              newItem.SubItems.Add(IntToStr(Filesize(AllFiles[i])));            // 3 (sub 1) - Filesize
              newItem.SubItems.Add(IntToStr(r.byte_difference));                // 4 (sub 2) - Byte Div
              newItem.SubItems.Add(FloatToStr(r.shannon_entropy));              // 5 (sub 3) - Entropy
              newItem.SubItems.Add(r.headerString);                             // 6 (sub 4) - Header String
                                                                                // 7 (sub 5) - Hash
           end else inc(skipped);

        end;
//        StatusBar.SimpleText:='';
      finally
      end;
      StatusBar.SimpleText:=' Total: '+IntToStr(AllFiles.Count)+', Processed: '+IntToStr(i+1)+', Skipped: '+IntToStr(skipped) + ', Listed: '+IntToStr(inList) + ', Time: ' +Inttostr(gettickcount - starttimer) + ' ms';
      Application.ProcessMessages;
      Button_cancelSearch.Visible:=false;
      Button_scanDirectory.Visible:=true;
      searchRunning:=false;
      AllFiles.free;
      ScanTime := gettickcount - starttimer;
  end;
end;




procedure TForm1.MenuItem_clearListClick(Sender: TObject);
begin
  ListView.Clear;
  StatusBar.SimpleText:='';
end;

procedure TForm1.MenuItem_CopyFilenameClick(Sender: TObject);
var
  Item: TListItem;
begin
  if( ListView.Selected <> nil ) then
  begin
    Item := ListView.Selected;
    Clipboard.AsText := Item.SubItems[0];
  end;
end;

procedure TForm1.MenuItem_CopyHeaderClick(Sender: TObject);
var
  Item: TListItem;
begin
  if( ListView.Selected <> nil ) then
  begin
    Item := ListView.Selected;
    Clipboard.AsText := Item.SubItems[4];
  end;
end;

procedure TForm1.MenuItem_CopyPathAndFilenameClick(Sender: TObject);
var
  Item: TListItem;
begin
  if( ListView.Selected <> nil ) then
  begin
    Item := ListView.Selected;
    Clipboard.AsText := Item.Caption+'\'+Item.SubItems[0];
  end;
end;

procedure TForm1.MenuItem_CopyPathClick(Sender: TObject);
var
  Item: TListItem;
begin
  if( ListView.Selected <> nil ) then
  begin
    Item := ListView.Selected;
    Clipboard.AsText := Item.Caption;
  end;
end;

procedure TForm1.MenuItem_OpenPathClick(Sender: TObject);
var
  Item: TListItem;
begin
  if( ListView.Selected <> nil ) then
  begin
     Item := ListView.Selected;
     OpenDocument(Item.Caption);
  end;
end;

procedure TForm1.MenuItem_SaveListToTSVClick(Sender: TObject);
var
  Item: TListItem;
  TSVlist : TStringList;
  i : integer;

begin
  if( ListView.Items.Count > -1 ) then
  begin
     TSVlist := TStringlist.Create;

       for i:=0 to ListView.Items.Count-1 do
       begin
         Item := ListView.Items[i];
         TSVList.Add(Item.Caption+#09+Item.SubItems[0]+#09+Item.SubItems[1]+#09+Item.SubItems[2]+#09+Item.SubItems[3]+#09+Item.SubItems[4]+#09+Item.SubItems[5]);
       end;
     if SaveDialog.Execute then
     begin
        TSVList.SaveToFile(SaveDialog.FileName);
     end;
     TSVlist.free;
  end;



end;

procedure TForm1.MenuItem_ShowInHexViewerClick(Sender: TObject);
var
  Item: TListItem;
begin
  if( ListView.Selected <> nil ) then
  begin
    Item := ListView.Selected;
    Form2.filename:=Item.Caption+'\'+Item.SubItems[0];
    Form2.Show;
  end;
end;

procedure TForm1.Button_cancelSearchClick(Sender: TObject);
begin
  cancelSearch := true;
end;


procedure TForm1.ListViewColumnClick(Sender: TObject; Column: TListColumn);
begin
  if searchRunning then exit;
  SortListView(ListView,Column.Index);
end;


procedure TForm1.MenuItem_CalcMD5AllFilesClick(Sender: TObject);
var
  Item: TListItem;
  i : integer;
begin
  for i:=0 to ListView.Items.Count-1 do
  begin
    Item := ListView.Items[i];
    Item.SubItems.Add(MD5Print(Md5File(Item.Caption+'\'+Item.SubItems[0])));
  end;

end;

procedure TForm1.MenuItem_CalcMD5selectedClick(Sender: TObject);
var
  Item: TListItem;
begin
  if( ListView.Selected <> nil ) then
  begin
    Item := ListView.Selected;
    Item.SubItems.Add(MD5Print(Md5File(Item.Caption+'\'+Item.SubItems[0])));
  end;
end;


procedure TForm1.SortListView(Lv:TListView; Index:integer);
var
    sl: TStringList;
    i : Integer;
begin
  sl := TStringList.Create;
  if Index = 0 then
     for i := 0 to Lv.Items.Count-1 do sl.AddObject(Lv.Items[i].Caption, Lv.Items[i]) else
     for i := 0 to Lv.Items.Count-1 do sl.AddObject(Lv.Items[i].SubItems[Index-1], Lv.Items[i]);
  sl.Sort;
  for i := 0 to sl.count-1 do Lv.Items[i] := TListItem(sl.Objects[i]);
  sl.free;
end;


function TForm1.calcByteDivAndShannonEntropyFromFile(f:string):TRes;
const
    DbLog: Double = 1.4426950408889634073599246810023;
var
    BytesRead : Int64;
    Buffer4K : array [0..4095] of byte;

    fs : TFilestream;
    i, min, max, minmaxtemp : Integer;
    byte_array : array[0..255] of QWord;

    se, se_temp : double;
    res         : TRes;

    header :  array[0..15] of byte;
    headerString : string;

begin

                                                                                // init variables
  for i:=0 to 255 do byte_array[i] := 0;
  min := 100;
  max := 100;
  minmaxtemp  :=0;
  se          := 0.0;
  headerString := '';

  // DEBUG: ListBox.Items.Add(f);

  try
    fs := TFileStream.Create(f, fmOpenRead or fmShareDenyWrite);                // open file for read
  except
    On E : Exception do
    begin
       // ShowMessage(e.Message);
       Result.shannon_entropy := 0.0;
       Result.byte_difference  := 0;
       exit;
    end;

  end;

  if fs.size < 4096 then
  begin
      fs.free;
      Result.shannon_entropy := 0.0;
      Result.byte_difference  := 0;
      exit;
  end;

  fs.Position := 0;
  BytesRead := fs.Read(Buffer4K,sizeof(Buffer4K));

  for i:=0 to 15 do begin                                                       // Copy header section
        header[i] := Buffer4K[i];
        if ( (Buffer4K[i] > 32) AND (Buffer4K[i] < 127)  ) then begin           // Copy ascii header
           headerString := headerString + Chr(Buffer4K[i]);
        end;
  end;


  res.headerString := headerString;


  for i:=0 to BytesRead-1 do inc(byte_array[Buffer4K[i]]);                      // counting every byte

  for i:=0 to 255 do begin
     minmaxtemp := round(byte_array[i] * 100 / 16);                             // calc min & max, 16 = 4K Buffer
     if minmaxtemp > max then max := minmaxtemp;
     if minmaxtemp < min then min := minmaxtemp;

     se_temp := byte_array[i] / 4095;                                            // calc shannon,
     if (se_temp > 0) then se := se + se_temp * (Ln(se_temp) * DbLog);           // calc shannon
  end;

  se := round(se*100)/100;                                                        // shannon, round to .00
  se := -se;                                                                      // shannon, neg to pos

  res.byte_difference  := max-min;                                                // byte diverence  (experimentel)
  res.shannon_entropy := se;                                                      // shannon entropy

  fs.Free;
  Result := res;

end;



end.

