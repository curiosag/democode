unit uAction_b;

interface

uses
  uQueryServer_a, uQueryCommon_a, uConst_h,
  Classes, SyncObjs;

type

  TAction_b = class(TAction_a)
  private
	...  
  protected
    property Request: TMessage_a read FRequest write setRequest;
    property Status: integer read FStatus write FStatus;
    property AbortAction: boolean read FAbortAction write SetAbortAction;
  public
    function RemoveAfterExecute: Boolean; override;
    function HasFatalError(var AStatusCode: Integer): Boolean; override;
    procedure Abort; override;
    function IsAborted: Boolean; override;
    property ProviderID: Integer read FProviderID;
    function EnterLock(ALockList: TActionLockList_a): Boolean; override;
    procedure LeaveLock(ALockList: TActionLockList_a); override;
    function GetRequestValue(AParam: string): Variant;
    procedure Log(const AMsg: string; const ALogKey: Integer = CltLog;
      const ASendToClient: Boolean = True; const AStatusCode: Integer = CAH_OK); overload;
    procedure OnRequestDeleted; override;
  end;

implementation

uses
  uStubManager_a, uQueryServer,
  uFileUtil, Variants;

//----------------------------------------------------------------------------
// N,PS:

function TAction_b.HasFatalError(var AStatusCode: Integer): Boolean;
begin
  // no inherited (abstract)
  Result := false;
  AStatusCode := COK;
end;

//----------------------------------------------------------------------------
// N,PS:

function TAction_b.GetRequestValue(AParam: string): variant;
begin
  // no inherited (private)
  Result := Request.GetParamValue(AParam);
  if Result = unassigned then
  begin
    Log(SErrorWhileGettingRequestValue);
    AbortAction := True;
    raise EUsrInfo.fireFmt(Self, SAutoRSMandatoryRequestParamNotSet,
      [AParam]);
  end;
end;

//----------------------------------------------------------------------------
// N,PS T475:

procedure TAction_b.Log(const AMsg, ANonTranslatedMsg: string; Args: array of const;
  const ALogKey: Integer = CltLog; const ASendToClient: Boolean = True;
  const AStatusCode: Integer = CAH_OK);
var
  lTranslated, lNonTranslated: string;
begin
  lTranslated := Fmt(AMsg, Args);
  lNonTranslated := Fmt(ANonTranslatedMsg, Args);

  LogToLog(lNonTranslated, ALogKey);
  if ASendToClient then
    LogToClient(lTranslated, AStatusCode);
end;


//----------------------------------------------------------------------------
// N,PS T475: split from log

procedure TAction_b.LogToClient(const AMsg: string; const AStatusCode: Integer = COK);
var
  lServerStub_a: TServerStub_a;
  lEvent: TNotifyEvent;
  lResult: Boolean;
begin
  lServerStub_a := StubManager.GetServerStub;
  
  if lServerStub_a is TServer then
  begin
    lEvent := TServer(lServerStub_a).GetNotifyEvent(...);
    if Assigned(lEvent) then
    begin
      lEvent(ntRequestMessage, AStatusCode, AMsg, lResult);
        // Nothing to do with lResult since this is just a logmessage.
    end;
  end
  else
    raise EIntern.Fire(Self, 'Implementation of TServerStub_a is not a TServer');
end;


//----------------------------------------------------------------------------
// N,PS:

function TAction_b.RemoveAfterExecute: Boolean;
begin
  // no inherited (abstract)
  Result := true;
end;

end.

