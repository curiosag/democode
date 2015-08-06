unit uActionFactory_b;

interface

uses
  uQueryServer_a, uQueryCommon_a;

type

  TActionFactory_b = class(TActionFactory_a)
  private
    FCurrRequestPart: string;
  public
    property CurrRequestPart: string read FCurrRequestPart;
    procedure AddRequestActions(AActions: TFiFoActionQueue_a); override;
  end;

implementation

uses
  uStubManager_a, uConst_h, uTestActions, uDbActions,
  uTriggerAction, uCommonActions,
  Variants;

//----------------------------------------------------------------------------
// N,PS:

procedure TActionFactory_b.AddRequestActions(AActions: TFiFoActionQueue_a);

  function nGetPartToProcess(...): string;
  var lRequest: TMessage_a;
  begin
    lRequest := StubManager.GetServerStub.GetRequestReference(...);
   
 if lRequest.GetParamValue(CRequests) = Unassigned then
      raise EIntern.fire(self, 'Invalid reaquest: CRequests not defined');

    if not lRequest.ParamById[CRequests].DeQValElem(Result) then
      raise EIntern.Fire(Self, 'Request empty');
  end;

begin
  // no inherited (abstract);
  if AActions = nil then
    raise EIntern.fire(self, 'Param = nil');

  FCurrRequestPart := nGetPartToProcess(...);
  if CurrRequestPart = CTest then
    AActions.EnQueue(TTestAction)
  else if CurrRequestPart = CDatabaseLoad then
    AActions.EnQueue(TDbLoadAction)
...
  else if CurrRequestPart = CFinishFetchExternalData then
    AActions.EnQueue(TFinishExternalDataFetchAction);
end;


end.

