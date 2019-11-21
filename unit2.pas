unit Unit2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ATBinHex;

type

  { TForm2 }

  TForm2 = class(TForm)
    ATBinHex1: TATBinHex;
    StatusBar: TStatusBar;
    procedure ATBinHex1ClickURL(ASender: TObject; const AString: AnsiString);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public
        fs: TFileStream;
        const filename: String = '';
  end;

var
  Form2: TForm2;


implementation

{$R *.lfm}

{ TForm2 }

procedure TForm2.FormCreate(Sender: TObject);
begin
     ATBinHex1.Align:= alClient;
     ATBinHex1.Font.Size:= 10;
     ATBinHex1.TextGutter:= true;
     ATBinHex1.TextGutterLinesStep:= 10;
     ATBinHex1.Mode:= vbmodeHex;
end;

procedure TForm2.FormActivate(Sender: TObject);
begin
  if FileExists(filename) then
  begin
    StatusBar.SimpleText:=filename;
    StatusBar.Hint:=filename;

    if Assigned(fs) then
    begin
      ATBinHex1.OpenStream(nil);
      FreeAndNil(fs);
    end;

    fs:= TFileStream.Create(filename, fmOpenRead or fmShareDenyNone);
    ATBinHex1.OpenStream(fs);
    ATBinHex1.Redraw;
  end else StatusBar.SimpleText:='Cant find file: '+filename;
end;

procedure TForm2.ATBinHex1ClickURL(ASender: TObject; const AString: AnsiString);
begin

end;

end.

