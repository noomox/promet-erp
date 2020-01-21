unit ubasestreamer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TypInfo, Contnrs, RttiUtils;

type
  TStreamingTyp = (stSelect,stRead,stWrite);

  { TBaseStreamer }

  TBaseStreamer = class(TComponent)
  protected
  public
    procedure StreamObject(aObject : TObject;Action : TStreamingTyp);virtual;
    procedure StreamClassProperty(Const AObject: TObject); virtual;
    procedure StreamCollection(Const ACollection: TCollection;Action : TStreamingTyp); virtual;abstract;
    procedure StreamObjectList(AnObjectList: TObjectList;Action : TStreamingTyp); virtual;
    procedure StreamTStringsArray(Const AStrings: TStrings;Action : TStreamingTyp); virtual;abstract;
    procedure StreamTStringsObject(Const AStrings: TStrings;Action : TStreamingTyp); virtual;abstract;
    procedure StreamTStrings(Const AStrings: TStrings;Action : TStreamingTyp); virtual;abstract;
    procedure StreamVariant(const Data: Variant;Action : TStreamingTyp); virtual;abstract;

    procedure StreamProperty(Const AObject : TObject; Const PropertyName : String;Action : TStreamingTyp); virtual;
    procedure StreamProperty(Const AObject : TObject; PropertyInfo : PPropInfo;Action : TStreamingTyp); virtual;abstract;

    procedure Load(Obj : TPersistent;Cascatic : Boolean = True);virtual;
    procedure Save(Obj : TPersistent;Cascatic : Boolean = True);virtual;
    function Select(Obj : TPersistent;aFilter : string;aFields : string = '*') : Integer;overload;virtual;
    function Select(Obj : TPersistent;aId : Int64;aFields : string = '*') : Boolean;overload;virtual;
  end;

implementation

{ TBaseStreamer }

procedure TBaseStreamer.StreamObject(aObject: TObject; Action: TStreamingTyp);
var
  PIL: TPropInfoList;
  I: Integer;
  aPI: PPropInfo;
begin
  If AObject is TStrings then
    StreamTStrings(Tstrings(AObject),Action)
  else If AObject is TCollection then
    StreamCollection(TCollection(AObject),Action)
  else If (AObject is TObjectList) then
    StreamObjectList(TObjectList(AObject),Action)
  else
    begin
      PIL:=TPropInfoList.Create(AObject,tkProperties);
      try
        For I:=0 to PIL.Count-1 do
          begin
            if PIL.Items[i]^.PropType^.Kind<>tkClass then
              StreamProperty(AObject,PIL.Items[i],Action);
          end;
        For I:=0 to PIL.Count-1 do
          begin
            if PIL.Items[i]^.PropType^.Kind=tkClass then
              begin
                aPI := PIL.Items[i];
                StreamObject(GetObjectProp(AObject,aPI),Action)
              end
          end;
      finally
        FReeAndNil(Pil);
      end;
    end;
end;

procedure TBaseStreamer.StreamClassProperty(const AObject: TObject);
begin

end;

procedure TBaseStreamer.StreamObjectList(AnObjectList: TObjectList;
  Action: TStreamingTyp);
var
  i: Integer;
begin
  i := 0;
  while i < AnObjectList.Count-1 do
    begin
      StreamObject(TObject(AnObjectList[i]),Action);
      inc(i);
    end;
end;

procedure TBaseStreamer.StreamProperty(const AObject: TObject;
  const PropertyName: String; Action: TStreamingTyp);
begin
  StreamProperty(AObject,GetPropInfo(AObject,PropertyName),Action);
end;

procedure TBaseStreamer.Load(Obj: TPersistent; Cascatic: Boolean);
begin
  StreamObject(Obj,stRead);
end;

procedure TBaseStreamer.Save(Obj: TPersistent; Cascatic: Boolean);
begin
  StreamObject(Obj,stWrite);
end;

function TBaseStreamer.Select(Obj: TPersistent; aFilter: string; aFields: string
  ): Integer;
begin
  StreamObject(Obj,stSelect);
end;

function TBaseStreamer.Select(Obj: TPersistent; aId: Int64; aFields: string
  ): Boolean;
begin
  Result := Select(Obj,'SQL_ID='+IntToStr(aId),aFields) = 1;
end;

end.

