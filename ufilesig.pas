unit uFilesig;

{$mode objfpc}{$H+}

interface
uses
  Classes, SysUtils;

type
 tDelimiter = set of Char;
// TPicArray = array [0..829440] of Byte

 tSigs = record
   Offset : integer;
   Signature : TBytes;

 end;


 { TExtensionSigMime }

 TExtensionSigMime = class(TObject)
 public
   Name : string;
   Mime : string;
   Signatures : tstrings;
   Sigs : array of tSigs;
   procedure AssignSig(aList : tstrings);
   constructor Create(aName:string) ;
   destructor Destroy; override;
 end;

 { TExtensionsList }

 TExtensionsList = class(TObject)


 public
   fList : tstringlist;
   fAllsignatures : array of tSigs;
   constructor Create;
   destructor Destroy; override;
   procedure FreeList;
   procedure LoadFromJSON(aFilename :string);
   procedure SavetoFile(aFilename :string);
   procedure AddToAllsignatures(aSig : tSigs);
 end;

 function ExtraktExpresion(var Data: String; Delimiter : tDelimiter = [';'] ): string;
 function ExtraktString(var Data: String): string;
 function TestFile(aFilename :string) : string;
 function TestFileSigVsExtension(aFilename :string) : string;
 function TestFileSigOnly(aFilename:string):string;


 implementation
 var
    ExtensionsList  : TExtensionsList;


 { TExtensionSigMime }

  procedure TExtensionSigMime.AssignSig(aList: tstrings);
  var
   i, j : integer;
   vString : string;
   vSubstring : string;
  begin
    Signatures := aList;
    setlength(Sigs,aList.count);
    for i := 0 to aList.count - 1 do
    begin
      Sigs[i].Offset:= strtoint(copy(aList.strings[i],1,pos(',',aList.strings[i])-1));
      vString := copy(aList.strings[i],pos(',',aList.strings[i])+1,length(aList.strings[i]));
      setlength(Sigs[i].Signature,length(vString) div 2);
      j := 0;
      if pos(',',vString) = 0 then while vString <> '' do   // Fehlerhafter Eintrag bei Zip
      begin
        vSubstring := '0x'+ copy(vString,1,2);
        Sigs[i].Signature[j] := strtoint(vSubstring);
        delete(vString,1,2);
        inc(j);
      end;

      //Sigs.Signature := Strtoint;
    end;
  end;

  constructor TExtensionSigMime.Create(aName:string);
 begin
   inherited create;
   Name := aName;
   //Mime := aMime;
   //Signatures := aSignaturesList;
 end;

  destructor TExtensionSigMime.Destroy;
var
  i : integer;
begin
  for i := 0 to length(Sigs) - 1 do
  begin
     setlength(Sigs[i].Signature, 0);
  end;
  setlength(Sigs, 0);
  Signatures.free;
  inherited Destroy;
end;


 { TExtensionsList }

 constructor TExtensionsList.Create;
 var
   i,j : integer;
   vExtensionSigMime : TExtensionSigMime;
 begin
   inherited create;
   fList := tstringlist.create;
   LoadFromJSON('extensions.json');
   for i := 0 to fList.count-1  do
   begin
     vExtensionSigMime  :=  fList.Objects[i] as TExtensionSigMime;
     for j := 0 to length(vExtensionSigMime.Sigs) - 1 do
       AddToAllsignatures(vExtensionSigMime.Sigs[j]);
   end;

   SavetoFile('debug.txt');
 end;

 destructor TExtensionsList.Destroy;
 begin
   FreeList;
   fList.free;
   inherited Destroy;
 end;

 procedure TExtensionsList.FreeList;
 var
    i : integer;
  begin
    for i := 0 to fList.count-1  do
    begin
      (fList.Objects[i] as TExtensionSigMime).Free;
    end;
  end;

 procedure TExtensionsList.LoadFromJSON(aFilename: string);
   var
     JSONText : tstringlist;
     i : integer;
     vline : string;
     vExpresion : string;
     vName : string;
     vEbene  : integer;
     vObjekt : TExtensionSigMime;
     vEntityName : string;
     vStrings : tstringlist;
     vStartedList : boolean;
 begin

   JSONText := tstringlist.create;
   JSONText.LoadFromFile(aFilename);

   vline := '';
   i := 0;
   vEbene := 0;
   vEntityName := '';
   vStartedList := false;
   while i < JSONText.count do
   begin
     if vline = '' then
     begin
       vline := JSONText.Strings[i];
       inc(i);
     end;

     vExpresion := ExtraktExpresion(vline,[' ']) ;

     if vExpresion = '{' then
       inc(vEbene);

     if vExpresion = '[' then
     begin
       vStartedList := true;
       vStrings := tstringlist.create;
       vStrings.Clear;
     end;

     if pos(']',vExpresion) = 1 then
     begin
       delete(vExpresion,1,1);
       if  vEntityName = 'signs' then
       vObjekt.AssignSig(vStrings);
       vEntityName := '';
       vStartedList := false;
     end;

     if pos('}',vExpresion) = 1 then
     begin
       delete(vExpresion,1,1);
       dec(vEbene);
       if  vEbene = 1 then
         fList.AddObject(vObjekt.Name,vObjekt);
     end;


     if  vEbene = 1 then
     begin
       if Pos('"',vExpresion) > 0 then
       begin
         vName := ExtraktString(vExpresion);
         if (vExpresion = ':') or (ExtraktExpresion(vline,[' ']) = ':') then
           vObjekt := TExtensionSigMime.Create(vName);
       end;
     end;

     if  (vEbene = 2) and (vEntityName = '') then
     begin
       if Pos('"',vExpresion) > 0 then
       begin
         vName := ExtraktString(vExpresion);
         if (vExpresion = ':') or (ExtraktExpresion(vline,[' ']) = ':') then
           vEntityName := vName;
       end;
     end;

     if  vEntityName = 'signs' then
     begin
       if vStartedList then
       begin
         if Pos('"',vExpresion) > 0 then
         begin
           vName := ExtraktString(vExpresion);
           vStrings.Add(vName);

         end;
       end;
     end;

     if  vEntityName = 'mime' then
     begin
       if Pos('"',vExpresion) > 0 then
       begin
         vName := ExtraktString(vExpresion);
         vObjekt.Mime := vName;
         vEntityName := '';
       end;

     end;



   end;
   JSONText.Free;



 end;

 procedure TExtensionsList.SavetoFile(aFilename: string);
 var
   i,j : integer;
   output : tstringlist;
   sigstr : string;
 begin
   output := tstringlist.create;
   for i := 0 to fList.count-1  do
   begin
     output.Add((fList.Objects[i] as TExtensionSigMime).Name);
     output.Add((fList.Objects[i] as TExtensionSigMime).Mime);
     output.AddStrings((fList.Objects[i] as TExtensionSigMime).Signatures);



   end;

   for i := 0 to length(fAllsignatures)-1  do
   begin
     sigstr := '';
     for j:=0 to length(fAllsignatures[i].Signature)-1 do begin
       sigstr := sigstr +  inttohex(fAllsignatures[i].Signature[j],2);
     end;
     output.Add(inttostr(fAllsignatures[i].Offset) + ',' + sigstr);
   end;


  output.SaveToFile(aFilename);
  output.free;
 end;

function ExtraktString(var Data: String) : string;
begin
  if Pos('"',Data) = 1 then
  begin
    Delete(Data,1,1);
    result := copy(Data,1,Pos('"',Data)-1);
    Data := copy(Data,Pos('"',Data)+1,length(Data));
  end;
end;

function TestFile(aFilename: string):string;
var
  r : string[20];
begin
  r := TestFileSigVsExtension(aFilename);
  case r of
       'ext-not-in-list': begin
          result := r;
       end;

       'ext-not-match-sig': begin
          result := r;
       end;

       'ext-match-sig': begin
          result := r;
       end;
  end;

end;

function TestFileSigVsExtension(aFilename: string): string;
var
  vExtension : string;
  vIndex : integer;
  fs : TFilestream;
  i,j : integer;
  vExtensionSigMime : TExtensionSigMime;
  vReadbuffer : array [0..255] of byte;
  vBytesCount : integer;
  vBytesRead : integer;
  vComparedBytes : integer;
begin
  vExtension := ExtractFileExt(aFilename);
  delete(vExtension,1,1);
  vIndex :=  ExtensionsList.fList.IndexOf(vExtension);
  if vIndex >= 0 then
  begin
    vExtensionSigMime  :=  ExtensionsList.fList.Objects[vIndex] as TExtensionSigMime;

    try
      fs := TFileStream.Create(aFilename, fmOpenRead or fmShareDenyWrite);                // open file for read
    except
      On E : Exception do
      begin
        result := 'open-failed';
        exit;
      end;
    end;

    for i := 0 to length(vExtensionSigMime.Sigs) - 1 do
    begin
      fs.Position := vExtensionSigMime.Sigs[i].Offset;
      vBytesCount := length(vExtensionSigMime.Sigs[i].Signature);
      if vBytesCount > 255 then
        vBytesCount := 255;
      vBytesRead := fs.Read(vReadbuffer,vBytesCount);
      {
      vComparedBytes := 0;
      for j := 0 to vBytesRead - 1 do
      begin
        if vReadbuffer[j] <> vExtensionSigMime.Sigs[i].Signature[j] then
          break;
        vComparedBytes := j+1;
      end;
      if vComparedBytes = vBytesCount then
      }

      if (vBytesCount = vBytesRead) and CompareMem(@vReadbuffer[0],@vExtensionSigMime.Sigs[i].Signature[0],vBytesRead) then
      begin
        result := 'ext-match-sig';
        fs.free;
        exit;
      end else result := 'ext-not-match-sig';
    end;
    fs.free;
  end else result:='ext-not-in-list';

end;

function TestFileSigOnly(aFilename:string):string;

begin

end;

procedure TExtensionsList.AddToAllsignatures(aSig: tSigs);
var
  i : integer;
begin
  for i := 0 to length(fAllsignatures) - 1 do begin
    if (fAllsignatures[i].Offset = aSig.Offset) and (fAllsignatures[i].Signature = aSig.Signature) then
      Exit;
  end;
  setlength(fAllsignatures,length(fAllsignatures)+1);
  fAllsignatures[length(fAllsignatures)-1].Offset := aSig.Offset;
  setlength(fAllsignatures[length(fAllsignatures)-1].Signature,length(aSig.Signature));
  Move(aSig.Signature[0],fAllsignatures[length(fAllsignatures)-1].Signature[0],length(aSig.Signature));

end;

function ExtraktExpresion(var Data: String; Delimiter : tDelimiter = [';'] ): string;
const
  Zeichen : array [1..16] of Char = (' ',#9,',',';',':','=','(',')','[',']','/','{','}','-','+','"');
var
  Zeichenkette  : string;
  Trennposition : integer;
  Position      : Integer;
  n             : Integer;
begin
  Zeichenkette  := Trim(Data);
  Trennposition := Length(Zeichenkette) + 1;
  if SizeOf(Zeichen) > 0 then
  begin
    for n := 1 to SizeOf(Zeichen) do if Zeichen[n] in Delimiter then
    begin
      Position := Pos(Zeichen[n],Zeichenkette);
      if (Position > 0) and (Position < Trennposition) then Trennposition := Position;
    end;
  end;
  Result        := copy(Zeichenkette, 1, Trennposition - 1);
  Zeichenkette  := copy(Zeichenkette, Trennposition + 1, 1 + Length(Zeichenkette) - Trennposition);
  Data          := Trim(Zeichenkette);
end;


initialization
begin
   ExtensionsList  := TExtensionsList.Create;
end;

finalization
begin
  ExtensionsList.Free;
end;
end.

