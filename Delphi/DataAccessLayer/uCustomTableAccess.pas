unit uCustomTableAccess;

interface

type
  TCustomTableAccess = class(TAbstractTableAccess)
  private
    FWriter: TCustomWriter;
    FOnBufferFlushNeeded: TBufferFlushNeededEvent;

    procedure SetAnyData(AIdx: integer; aType: TDataType; aPointer: Pointer; NativeFormat: boolean = true);

    class procedure OwnFieldInfo(AFieldDef: TFieldDef; out AFieldInfo: TFieldInfo);
    function GetAssignedTable: TDataSet;
    function GetWriter: TCustomWriter;

  protected
    property Writer: TCustomWriter read getWriter;
    function GetTableName: string; override;
    procedure SetTableName(const ATableName: string); override;

    function GetRecordCount: integer; override;
    function GetTable: TDataSet; override;
    function GetFieldAt(AIdx: integer): TField; override;
    function GetFieldDefAt(AIdx: integer): TFieldDef; override;
    procedure SetBuffered(AValue: boolean); override;
    procedure SetOnBufferFlushNeeded(const AValue: TBufferFlushNeededEvent); override;
    procedure hdlOnBufferFlushNeeded; override;

    function GetIntValue(AIdx: integer): integer; override;

    function GetDateTimeValue(AIdx: integer): TDateTime; override;
    function GetValue(AIdx: integer): Variant; override;
...
    function GetCachedUpdates: boolean; override;
    function GetUpdatesPending: boolean; override;
    procedure SetCachedUpdates(const AValue: boolean); override;

    function GetDatabaseType: TDatabaseType; override;

  public
    function GetFieldDefs: TFieldDefs; override;
    function GetIsEmpty: boolean; override;
    function GetFields: TFields; override;
    function FieldByName(const FieldName: string): TField; override;
    function GetFieldIndex(const AFieldName: string): integer; override;
    procedure Append; override;
    procedure Cancel; override;
    procedure Close; override;
    function Locate(ADbKeyFields: TAbstractDataRow): boolean; override;
    procedure SetFilter(ADbKeyFields: TAbstractDataRow); override;

    class function GetDataType(AFieldType: TFieldType; DbSize: integer; var MaxLength: integer): TDataType; override;

    procedure SetIntValue(AIdx: integer; AValue: integer); override;
...   
    procedure ClearField(AIdx: integer); override;

    function GetIsNull(AIdx: integer): boolean; override;
    function GetKeyValue(AIdx: integer): TKeyVal; override;

    // data caching: usually not supported
    function GetCanCacheUpdates: boolean; override;
    function CommitUpdates(out AErrorMsg: string): boolean; override;
    procedure CancelUpdates; override;

    property DatabaseType: TDatabaseType read GetDatabaseType;
  end;

const
  // number of reserved words per database type	
  // 110 for oracle
  // 306 for db2
  // 13 postgresql (that are not in ansi-iso-reserved)
  // 140 ansi-iso 92 sql
  // 118 interbase (that are not in ansi-iso-reserved)
  // 204 sybase
  // 186 sql server
  // 194 sql server future
  // 235 odbc
  CGeneralDBReservedWords: array[0..1086] of string = (
    'FIELD', 
    'IDENTIFIER',
    'ABORT ANALYZE', // postgresql reserved words
    'BINARY',
    'CLUSTER CONSTRAINT COPY',
    'DO',
    
    ....
    
    'WHERE',
    'WHILE',
    'WITH',
    'WLM',
    'WRITE',
    'YEAR',
    'YEARS'
    );

implementation

var
  FReservedWords: TStringList;


//----------------------------------------------------------------------------
//N,PS:

procedure TCustomTableAccess.setAnyData(AIdx: integer; aType: TDataType; aPointer: Pointer; NativeFormat: boolean = true);
begin
  checkFieldIndex(AIdx);
  checkAssigned(getTable);
  getAssignedTable.Fields[AIdx].SetData(aPointer, NativeFormat);
end;

//----------------------------------------------------------------------------
// N,PS:

constructor TCustomTableAccess.Create(AOwnedRootTA: TSpecificTableAccess_a;
  AWriter: TCustomWriter;
  ADatabase: TComponent; const ATableName: string; ABlockReadSize: integer;
  AOpenExclusively: boolean; ATableDestroy: boolean);
begin
  inherited Create;

  checkAssigned(AWriter);
  checkAssigned(AOwnedRootTA);

  FWriter := AWriter;
  FRootTA := AOwnedRootTA;
end;

//----------------------------------------------------------------------------
// N,PS:

class function TCustomTableAccess.GetDataType(AFieldType: TFieldType; DbSize: integer; var MaxLength: integer): TDataType;
begin
  MaxLength := DbSize;
  case AFieldType of
    ftMemo, ftWideString, ftString, ftOraClob:
      begin
        Result := dtString;
        if DbSize = 0 then
          MaxLength := MaxInt;
      end;
    ftSmallInt, ftInteger: Result := dtInteger;
    ftFloat, ftCurrency: Result := dtDouble;
    ftDate: Result := dtDate;
    ftBoolean: Result := dtBoolean;
    ftTime: Result := dtTime;
    ftDateTime: Result := dtDateTime;
  else
    Result := dtUnknown;
  end;
end;

//----------------------------------------------------------------------------
// N,PS:

function TCustomTableAccess.getMaxFieldLength(AProposal: integer; AType: TFieldType): integer;
begin // no inherited (abstract)
  if (AType = ftString) or (AType = ftBytes) then
    Result := AProposal
  else
    Result := 0;
end;

//----------------------------------------------------------------------------
// N,PS:

function TCustomTableAccess.getFieldTypeEq(AMetaField: PMetaField; AField: TFieldDef; ATableName: string): boolean;
begin
  // no inherited (abstract)
  checkAssigned(AMetaField);

  Result := AField.DataType = GetFieldType(AMetaField^.DataType, AMetaField^.MaxLength);
end;

//----------------------------------------------------------------------------
// N,PS:

function TCustomTableAccess.getDfTypeEq(AType,
  ANotherType: TDataType): boolean;
const
  CEqualIntTypes = [dtInteger, dtAutoInc];
begin
  // no inherited (abstract)
  Result := (AType = ANotherType) or
    ((AType in CEqualIntTypes) and (ANotherType in CEqualIntTypes));
end;


//----------------------------------------------------------------------------
// N,PS:

procedure TCustomTableAccess.SetIntValue(AIdx: integer; AValue: integer);
begin
  setAnyData(AIdx, dtInteger, @AValue);
end;

//----------------------------------------------------------------------------
// N,PS:

procedure TCustomTableAccess.SetInt64Value(AIdx: integer; AValue: Int64);
begin
  setAnyData(AIdx, dtInt64, @AValue);
end;



//----------------------------------------------------------------------------
// N,PS T3:

function TCustomTableAccess.getIsNull(AIdx: integer): boolean;
begin
  // no inherited(abstract)
  checkFieldIndex(AIdx);
  Result := getAssignedTable.Fields[AIdx].IsNull;
end;


//----------------------------------------------------------------------------
// N,PS:

function TCustomTableAccess.getDataSetState: TDataSetState;
begin
  Result := getAssignedTable.State;
end;

//----------------------------------------------------------------------------
// N,PS:

procedure TCustomTableAccess.Append;
begin
  // no inherited (abstract)
  getAssignedTable.Append;
end;

//----------------------------------------------------------------------------
// N,PS:

procedure TCustomTableAccess.Cancel;
begin
  // no inherited (abstract)
  getAssignedTable.Cancel;
end;


//----------------------------------------------------------------------------
// N,PS:

procedure TCustomTableAccess.CleanBuffers;
begin
  // no inherited (abstract)
  // empty implementation here
end;

//----------------------------------------------------------------------------
// N,PS:

function TCustomTableAccess.getFiltered: boolean;
begin
  // no inherited(abstract);
  Result := getAssignedTable.Filtered;
end;


//----------------------------------------------------------------------------
//2003-08-26 09:18 N,PS:
//2004-10-22 09:32 C,PS T50: getAssnignedTable used
//2004-11-18 12:08 R,CT T50:

procedure TCustomTableAccess.setFilterText(AValue: string);
begin
  // no inherited(abstract);
  getAssignedTable.Filter := AValue;
end;

//----------------------------------------------------------------------------
// N,PS:

function TCustomTableAccess.Locate(ADbKeyFields: TAbstractDataRow): boolean;
var
  i: integer;
  lFields: string;
  lVals: array of variant;
begin
  // no inherited(abstract);
  if IsEmpty then
    Result := false
  else
  begin
    setLength(lVals, ADbKeyFields.Count);
    for i := 0 to ADbKeyFields.Count - 1 do
    begin
      lFields := SeqStr(lFields, ';', ADbKeyFields.MetaField[i].Identifier);
      case ADbKeyFields.MetaField[i].DataType of
          // case-order by estimated probability of occurance in data
        dtString: lVals[i] := ADbKeyFields.StringValue[i];
        dtInteger: lVals[i] := ADbKeyFields.IntValue[i];
...
        dtDateTime: lVals[i] := ADbKeyFields.DateTimeValue[i];
        dtInt64: lVals[i] := ADbKeyFields.Int64Value[i];
      else
        raise EIntern.Fire(nil, 'Invalid type');
      end;
    end;
    Result := getAssignedTable.Locate(lFields, lVals, []);
  end;
end;

//----------------------------------------------------------------------------
// N,PS:

function TCustomTableAccess.getFieldAt(AIdx: integer): TField;
begin
  // no inherited(abstract);
  Result := getAssignedTable.Fields[AIdx];
end;


//----------------------------------------------------------------------------
// N,PS:

procedure TCustomTableAccess.flushBuffers;
begin
  // no inherited(abstract);
  // nothing to do here
end;

//----------------------------------------------------------------------------
// N,PS:

procedure TCustomTableAccess.setBuffered(AValue: boolean);
begin
  // no inherited(abstract);
  // nothing to do here
end;

//----------------------------------------------------------------------------
// T42:

procedure TCustomTableAccess.hdlOnBufferFlushNeeded;
begin
  // no inherited; (abstract)
  if not Assigned(FOnBufferFlushNeeded) then
    raise EIntern.Fire(Self, 'Mandatory event OnBufferFlushNeeded not set');

  FOnBufferFlushNeeded;
end;

//----------------------------------------------------------------------------
// N,PS T42:

procedure TCustomTableAccess.setOnBufferFlushNeeded(
  const AValue: TBufferFlushNeededEvent);
begin
  // no inherited; (abstract)
  FOnBufferFlushNeeded := AValue;
end;


//----------------------------------------------------------------------------
// N,PS T42:

constructor TCustomTableAccess.Create;
begin
  raise EMethodNotSupported.Fire(Self, 'Invalid constructor used');
end;

initialization
  FReservedWords := TStringList.Create;
  FReservedWords.sorted := true;
  FReservedWords.Duplicates := dupIgnore;
  AddStringArrayToStringList(FReservedWords, CGeneralDBReservedWords);
  AddStringArrayToStringList(FReservedWords, COracleReservedWords);
  AddStringArrayToStringList(FReservedWords, CDB2ReservedWords);

finalization
  FReservedWords.free;

end.

