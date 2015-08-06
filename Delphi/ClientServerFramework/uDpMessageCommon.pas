unit uDpMessageCommon;

interface

uses
  uDpQueryCommon_a, uDpConst_h,
  Classes, SyncObjs, Variants;

type
  // ***************************************************************************
  TDpParam = class(TDpParam_a)
  private
    FKey: string;
    FValue: Variant;
  protected
    function getKey: string; override;
    procedure setKey(const AKey: string); override;
    function getValue: variant; override;
    procedure setValue(const AValue: variant); override;
  public
    procedure EnQValElem(AElem: string); override;
    function DeQValElem(out AElem: string): boolean; override;
    function ValElemInQ(AElem: string): boolean; override;
  end;

  // ***************************************************************************
  TDpMessage = class(TDpMessage_a)
  private
    FParams: TStringList;
    FLock: TCriticalSection;
  protected
    function IndexOfParam(const AKey: string): integer;
    function GetParam(AIndex: Integer): TDpParam_a; override;
    function GetParamById(const AId: string): TDpParam_a; override;
    function GetParamCount: Integer; override;
    function GetContent: string;
    procedure SetContent(const AValue: string);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Clear; override;
    function Clone: TDpMessage_a; override;
    function IsEqual(AReferenceMessage: TDpMessage_a): Boolean; override;
    function GetParamValue(AKey: string): Variant; override;
    procedure SetParamValue(AKey: string; AValue: Variant); override;
    function Find(const AKey: string): boolean; override;
  published
    property MsgContent: string read GetContent write SetContent;
  end;

implementation

//----------------------------------------------------------------------------
// N,PS:

function TDpMessage.getParamById(const AId: string): TDpParam_a;
var lIdx: integer;
begin
  // no inherited: abstract.
  if AId = '' then
    raise EIntern.fire(self, 'Param = ""');

  Result := nil;
  FLock.Enter;
  try
    lIdx := FParams.IndexOf(AId);
    if lIdx >= 0 then
      Result := TDpParam(FParams.Objects[lIdx]);
  finally
    FLock.Leave;
  end;
end;

//----------------------------------------------------------------------------
// N,PS:

function TDpMessage.IndexOfParam(const AKey: string): integer;
begin
  // no inherited: abstract.
  if AKey = '' then
    raise EIntern.Fire(Self, 'AKey not specified in TDpMessage.SetParamValue()');

  Result := FParams.IndexOf(AKey);
end;
...

//----------------------------------------------------------------------------
// N,PS:

procedure TDpMessage.Clear;
var i: integer;
begin
  // no inherited: static
  for i := 0 to FParams.Count - 1 do
    FParams.Objects[i].Free;
  FParams.Clear;
end;

{ TDpParam }


//----------------------------------------------------------------------------
// 16:58 N,PS:

procedure TDpParam.EnQValElem(AElem: string);
begin
  // no inherited: abstract.
  if not ((TVarData(Value).VType = varString) or
    (TVarData(Value).VType = varEmpty) or
    (TVarData(Value).VType = varNull)) then
    raise EIntern.fire(self, 'can queue value elements only to params of type string, null or emtpy');

  if AElem = '' then
    raise EIntern.fire(self, 'can not queue empty elements');

  Value := SeqStr(Value, CTermSymRequests, AElem);
end;

//----------------------------------------------------------------------------
// N,PS:

function TDpMessage.find(const AKey: string): boolean;
var lIdx: integer;
begin
  // no inherited: abstract.
  FLock.Enter;
  try
    lIdx := FParams.IndexOf(AKey);
    Result := lIdx >= 0;
  finally
    FLock.Leave;
  end;
end;

//----------------------------------------------------------------------------
// N,PS:

function TDpMessage.GetContent: string;
var i: integer;
  lStream: TStringStream;
  lWriter: TWriter;
begin
  // no inherited (abstract)
  lStream := TStringStream.Create('');
  try
    lWriter := TWriter.Create(lStream, 4096);
    try
      lWriter.WriteString(IntToStr(ParamCount));
      for i := 0 to ParamCount - 1 do
        lWriter.WriteString(
          getIdentVarValuePairAsStringEncode(Param[i].Key, Param[i].Value));
    finally
      FreeAndNil(lWriter);
    end;
    Result := lStream.DataString; // data not available before writer is destroyed
  finally
    FreeAndNil(lStream);
  end;
end;


end.

