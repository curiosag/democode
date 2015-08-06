unit uActionFactoryFetchExternalData;

interface

uses
  uQueryCommon_a, uActionFactory_b, uQueryServer_a;

type

  TActionFactoryFetchExternalData = class(TActionFactory_b)
  public
    procedure AddRequestActions(...; AActions: TFiFoActionQueue_a); override;
  end;

implementation

uses uConst_h, uCommonActions;

//----------------------------------------------------------------------------
// N,PS:

procedure TActionFactoryFetchExternalData.addRequestActions(...;
  AActions: TFiFoActionQueue_a);
begin
  if AActions = nil then
    raise EIntern.fire(self, 'AActions not assigned');

  inherited;
  if CurrRequestPart = CFetchExternalData then
  begin
    AActions.enQueue(TUploadAction);
...
    AActions.enQueue(TDownloadAction);
  end;
end;

end.

