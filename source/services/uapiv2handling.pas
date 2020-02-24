unit uapiv2handling;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, HTTPDefs, websession,iniwebsession, fpHTTP, fpWeb, fpjson,
  ubasedbclasses, uPrometORM,fpjsonrtti, memds, uData, perp2, db;

type
  TAPIV2Session = class(TIniWebSession)
  public
    User : TUser;
  end;

  TDatasetToJSONOption = (djoSetNull, djoCurrentRecord, djoPreserveCase);
  TDatasetToJSONOptions = set of TDatasetToJSONOption;

  { TAPIV2SessionFactory }

  TAPIV2SessionFactory = class(TIniSessionFactory)
  protected
    constructor Create(AOwner: TComponent); override;
    Function DoCreateSession(ARequest : TRequest) : TCustomSession; override;
  end;

  { TAPIV2Module }

  TAPIV2Module = class(TFPWebModule)
    constructor CreateNew(AOwner: TComponent; CreateMode: Integer); override;
  private
    procedure DoHandleRequest(Sender: TObject; ARequest: TRequest;
      AResponse: TResponse; var Handled: Boolean);
    procedure NewSession(Sender: TObject);
  end;

implementation

uses base64;

{ TAPIV2SessionFactory }

constructor TAPIV2SessionFactory.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Cached:=True;
  CheckSessionDir;
  writeln(SessionDir);
end;

function TAPIV2SessionFactory.DoCreateSession(ARequest: TRequest
  ): TCustomSession;
begin
  Result := TAPIV2Session.Create(nil);
end;

{ TAPIV2Module }

constructor TAPIV2Module.CreateNew(AOwner: TComponent; CreateMode: Integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  OnNewSession:=@NewSession;
  OnRequest:=@DoHandleRequest;
  CreateSession := True;
end;

procedure TAPIV2Module.DoHandleRequest(Sender: TObject; ARequest: TRequest;
  AResponse: TResponse; var Handled: Boolean);
var
  aUser: TUser;
  aStreamer, Streamer: TJSONStreamer;
  aOpt: TOption;
  aUsers, aDS: TMemDataset;
  tmp: String;
  aData : TBaseDBDataset;
  i: Integer;
  arr: TJSONArray;

  procedure DatasetToJSON(Dataset: TDataset; JSONArray: TJSONArray; Options: TDatasetToJSONOptions);
  var
    OldRecNo: Integer;
    RecordData: TJSONArray;
  begin
    if Dataset.IsEmpty then
      Exit;
    if djoCurrentRecord in Options then
    begin
      RecordData := TJSONArray.Create;
      DatasetToJSON(Dataset, RecordData, Options);
      JSONArray.Add(RecordData);
    end
    else
    begin
      Dataset.DisableControls;
      OldRecNo := Dataset.RecNo;
      try
        Dataset.First;
        while not Dataset.EOF do
        begin
          RecordData := TJSONArray.Create;
          DatasetToJSON(Dataset, RecordData, Options);
          JSONArray.Add(RecordData);
          Dataset.Next;
        end;
      finally
        Dataset.RecNo := OldRecNo;
        Dataset.EnableControls;
      end;
    end;
  end;
begin
  Handled := False;
  if (not Assigned(TAPIV2Session(Session).User)) and (not Assigned(GlobalUser)) then
    begin
      if lowercase(copy(ARequest.Authorization,0,6))='basic ' then
        begin
          aUser := TUser.Create;
          try
            with aUser do
              begin
                tmp := DecodeStringBase64(copy(ARequest.Authorization,7,length(ARequest.Authorization)));
                if (not Data.Load(aUser,'NAME='+copy(tmp,0,pos(':',tmp)-1)+' OR LOGINNAME='+copy(tmp,0,pos(':',tmp)-1)+' OR EMAIL='+copy(tmp,0,pos(':',tmp)-1)))
                or (not CheckUserPasswort(copy(tmp,pos(':',tmp)+1,length(tmp))))
                then
                  begin
                    FreeAndNil(TAPIV2Session(Session).User);
                    Handled:=True;
                    Response.Code:=403;
                    Response.CodeText:='Access denied';
                    Response.SendContent;
                    exit;
                  end
                else TAPIV2Session(Session).User := aUser;
              end;
          finally
            if TAPIV2Session(Session).User <> aUser then
              FreeAndNil(aUser);
          end;
        end
      else
        begin
          Handled:=True;
          Response.Code:=401;
          Response.CodeText:='You must login first';
          Response.WWWAuthenticate:='Basic realm="Login first"';
          Response.SendContent;
          exit;
        end;
    end;
  Response.Code:=404;
  Response.CodeText:='Not found';
  Handled:=True;
  if ARequest.GetNextPathInfo = 'v2' then
    begin  //api/v2
      tmp := ARequest.GetNextPathInfo;
      for i := 0 to length(DatasetClasses)-1 do
        if DatasetClasses[i].aClass.InheritsFrom(TBaseDBDataset)
        and (lowercase(tmp) = lowercase(DatasetClasses[i].aClass.GetRealTableName))
        then
          begin
            Streamer := TJSONStreamer.Create(Self);
            Streamer.Options:=[jsoDateTimeAsString,jsoLowerPropertyNames,jsoSetAsString,jsoCheckEmptyDateTime];
            tmp := ARequest.GetNextPathInfo;
            case tmp of
            'by-id':
              begin
                aData := DatasetClasses[i].aClass.CreateEx(Self,Data);
                case aRequest.Method of
                'GET':
                  begin
                    if Data.Load(aData,ARequest.GetNextPathInfo) then
                      begin
                        Response.Code:=200;
                        Response.CodeText:='OK';
                        Response.Content:=Streamer.ObjectToJSON(aData).FormatJSON;
                        Response.ContentType:='text/json';
                        exit;
                      end;
                  end;
                end;
              end;
            'index.json':
              begin
                aDS := Data.Select(DatasetClasses[i].aClass,'','SQL_ID');
                if Assigned(aDS) then
                  begin
                    Response.Code:=200;
                    Response.CodeText:='OK';
                    Response.ContentType:='text/json';
                    arr := TJSONArray.Create;
                    DatasetToJSON(aDS,arr,[]);
                    Response.Content:=Streamer.ObjectToJSON(arr).FormatJSON;
                  end;
              end;
            end;
          end;
    end;
end;

procedure TAPIV2Module.NewSession(Sender: TObject);
begin
end;

initialization
  RegisterHTTPModule('api/v2', TAPIV2Module, True);
  SessionFactoryClass:=TAPIV2SessionFactory;
end.

