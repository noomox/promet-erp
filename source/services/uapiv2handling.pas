unit uapiv2handling;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, HTTPDefs, websession, fpHTTP, fpWeb, fpjson,
  ubasedbclasses, uPrometORM;

type

  { TAPIV2Module }

  TAPIV2Module = class(TFPWebModule)
    constructor CreateNew(AOwner: TComponent; CreateMode: Integer); override;
  private
    procedure DoHandleRequest(Sender: TObject; ARequest: TRequest;
      AResponse: TResponse; var Handled: Boolean);
    procedure NewSession(Sender: TObject);
  end;

implementation

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
  User: TUser;
begin
  Handled := False;
  if Session.Variables['auth'] <> 'true' then
    begin
      Handled:=True;
      Response.Code:=401;
      Response.CodeText:='You must login first';
      User := TUser.Create(TSQLStreamer.Create(ThreadID));
      User.Streamer.Select(User,'NAME=Jemand');
    end;
end;

procedure TAPIV2Module.NewSession(Sender: TObject);
begin
end;

initialization
  RegisterHTTPModule('api/v2', TAPIV2Module, True)
end.

