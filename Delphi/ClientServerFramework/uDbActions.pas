unit uDbActions;

interface

uses
  uQueryServer_a, uQueryCommon_a, uAction_b, ...;

type

  TDbAction = class(TAction_b)
  protected
    function getEnvironment: TActionEnvironmentDb;
    procedure CheckFirstLockTry;
    property Options: TOptions read FOptions;
    property DbAccessId: string read FDbAccessId;
    property Done: boolean read FDone write FDone;
    property FatalError: boolean read FFatalError write FFatalError;
  public
    property Environment: TActionEnvironmentDb read getEnvironment write FEnvironment;
    function HasFatalError(var AStatusCode: Integer): Boolean; override;
  end;

  TDbLoadAction = class(TDbAction)
  private
	...  
    procedure ExecuteProcessor(out AExceptLogMsgProviderId, AExceptLogMsgCommand: string);
  public
    procedure Execute; override;
    function Valid: Boolean; override;
    function RemoveAfterExecute: Boolean; override;
    function CanEnterLock(ALockList: TActionLockList_a): Boolean; override;
    function EnterLock(ALockList: TActionLockList_a): Boolean; override;
    procedure LeaveLock(ALockList: TActionLockList_a); override;
  end;

implementation

uses ...;

//----------------------------------------------------------------------------
// N,PS:

procedure TDbLoadAction.Execute;
var
  lExceptLogMsgProviderId: string;
  lExceptLogMsgCommand: string;
begin
  // no inherited (replaces)
  if Request.GetParamValue(CIsSimple) = True then
    LockSimpleSection(..., sasImportAndAfterScripts);
  Log(LangHdl.Translate(SWritingIntoDatabaseStarted));
  try
    try
    ExecuteProcessor(lExceptLogMsgProviderId, lExceptLogMsgCommand);
    finally
      FinishDataDir;
    end;
  except
    on E: Exception do
    begin
      FatalError := True;
      Status := ...
      raise;
    end;
  end;
  Log(LangHdl.Translate(SWritingIntoDatabaseFinished));
  Done := True;
end;

//----------------------------------------------------------------------------
// N,PS:

function TDbLoadAction.RemoveAfterExecute: Boolean;
begin
  // no inherited: abstract.
  Result := Done; //only true when loaded
end;

//----------------------------------------------------------------------------
// N,PS:

function TDbLoadAction.Valid: Boolean;
begin
  // no inherited: abstract.
  Result := (not FatalError) and
    Environment.getCanGoNow(ProviderId,
    GetRequestValue(CTargetOptions));

  if Result then
    Result := not IsSimpleSectionLocked(sasImportAndAfterScripts);
end;

//----------------------------------------------------------------------------
// N,PS:

function TActionEnvironmentDb.getCanGoNow(AProviderId: integer; ADbOptions: string): boolean;
begin
  // no inherited (defined here)
  Result := true;
end;

//----------------------------------------------------------------------------
// N,PS:

function TActionEnvironmentDb.getProviders: TProviderList;
begin
  // no inherited: static.
  if not Assigned(FProviders) then
    raise EIntern.Fire(self, 'Providerlist not assigned');

  Result := FProviders;
end;

//----------------------------------------------------------------------------
// N,PS:

procedure TDbAction.InternalAbortAction(const AErrorMsg: string; AUsrInfo: boolean = false);
begin
  // no inherited: static.
  FatalError := true;
  Done := true;
  Log(AErrorMsg);
  if AUsrInfo then
    raise EUsrInfo.fire(self, AErrorMsg)
  else
    raise EIntern.fire(self, AErrorMsg);
end;

//----------------------------------------------------------------------------
// N,PS:

function TDbAction.HasFatalError(var AStatusCode: Integer): Boolean;
begin
  AStatusCode := COK;
  // no inherited (replaces)
  Result := FatalError;
  if Result then
    AStatusCode := CERROR;
end;

//----------------------------------------------------------------------------
// N,PS:

function TDbLoadAction.EnterLock(ALockList: TActionLockList_a): Boolean;
begin
  // no inherited (replaces)
  Result := False;
  if CanEnterLock(ALockList) then
  begin
    ALockList.AddLock(..., ProviderId, CDatabaseLockKey, DbAccessId);
    Result := True;
  end;
end;

//----------------------------------------------------------------------------
// N,PS:

procedure TDbLoadAction.LeaveLock(ALockList: TActionLockList_a);
begin
  // no inherited (misfit)
  ALockList.DelLock(ProviderId, CDatabaseLockKey, DbAccessId);
end;

//----------------------------------------------------------------------------

procedure TDbLoadAction.ExecuteProcessor(out AExceptLogMsgProviderId, AExceptLogMsgCommand: string);
var
  lProcessor: TAbstractProcessor;
  lOptions: TOptions;
  lProcessorCmdIdx: integer;
  lCommand: TAbstractDFCommand;
begin
  lOptions := TOptions.Create;
  try
    lOptions.SetAsString(GetRequestValue(COptions));
    CoInitialize(nil);
    try
      with Environment.Providers.Get(ProviderId) do
      begin
        lProcessor := ProcessorClass.Create(True);
        try
            lProcessor.SetOptions(lOptions);
    
            lCommand := lProcessor.Commands..
            
            RegisterMessageCallback(OnAppMessage);
            try
              lCommand.Execute;
            finally
              UnRegisterMessageCallback(OnAppMessage);
            end;
          finally
            FreeAndNil(lProcessor);
          end;
      end;
    finally
      CoUninitialize;
    end;
  finally
    FreeAndNil(lOptions);
  end;
end;


end.

