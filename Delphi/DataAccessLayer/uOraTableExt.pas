unit uOraTableExt;

interface
uses
  uAbstractTableAccess, uSqlFormat_Oracle,  DB, DbTables, Classes, SysUtils;

type
  TOraTableExt = class(TOracleTable)
  private
    function getPhysAttrClauseString(AInit, ANext, APctIncrease, APctFree, APctUsed: integer): string;
    function GetExists: Boolean;
    procedure SetIndexDefs(Value: TIndexDefs);
    procedure GetIndexOptionsFromConstraints;
    procedure AddIndexOption(const AIndexName: string;
      AOption: TIndexOption);
  public
    property TableId: integer read FTableId write FTableId;
    property StorageInit: integer read FStorageInit write FStorageInit;
    property StorageNext: integer read FStorageNext write FStorageNext;
    property StoragePctIncrease: integer read FStoragePctIncrease write FStoragePctIncrease;
    property StoragePctIndex: integer read FStoragePctIndex write FStoragePctIndex;
    property StoragePctFree: integer read FStoragePctFree write FStoragePctFree;
    property StoragePctUsed: integer read FStoragePctUsed write FStoragePctUsed;
    property IndexTableSpace: string read FIndexTableSpace write FIndexTableSpace;
    property DDLChange: boolean read FDDLChange write FDDLChange;
    procedure CreateIndex(AName: string; const AFields: string;
      AOptions: TIndexOptions; AStorageClause: string = '');
    procedure CreateTable;
    procedure DeleteTable;
    procedure RenameTable(const ANewTableName: string);
    procedure EmptyTable;
    procedure AddIndex(const AName, AFields: string;
      AOptions: TIndexOptions;
      const ADescFields: string = '');
    procedure DeleteIndex(const AName: string);
    property IndexDefs: TIndexDefs read FIndexDefs write SetIndexDefs;
    property IndexName: string read GetIndexName write SetIndexName;

  end;

implementation

const
  CInvalidSynonymSource = 'Invalid synonym source view ''%s''';

const
  CSelectEditable = 'SELECT DT.ROWID, DT.* FROM %s DT';
  CSelectReadOnly = 'SELECT DT.* FROM %s DT';

  CBaseSelect = 'SELECT %sDT.* FROM %s DT ';


//----------------------------------------------------------------------------

procedure TOraTableExt.CreateTable;

  function nExistsUniqueConstraint(const AFieldName: string): boolean;
  var
    j: integer;
  begin
    Result := false;
    for j := 0 to IndexDefs.Count - 1 do
      with IndexDefs[j] do
        if (Fields = AFieldName) and ((Options * [ixUnique, ixPrimary]) <> []) then
        begin
          Result := true;
          break;
        end;
  end;
var
  lS: string;
  i, lNumAutoinc: integer;
  lMInitial, lMNext: integer;
  lIdxStorage: string;
begin
  ToUpperCase(FieldDefs);
  ToUpperCase(IndexDefs);

  // no inherited (defined here)
  lNumAutoInc := 0;
  for i := 0 to FieldDefs.Count - 1 do
    if FieldDefs[i].DataType = ftAutoInc then
    begin
      inc(lNumAutoInc);
      if lNumAutoInc > 1 then
        raise EIntern.fire(self, 'only 1 AutoInc-field allowed');
    end;

  lS := 'CREATE TABLE ' + TableName + ' (';
  for i := 0 to FieldDefs.Count - 1 do
  begin
    with FieldDefs[i] do
    begin
      lS := ls + getQuotedName(Name) + ' ' + FSqlFormat.getDataTypeString(DataType, Size);
      if Required or (DataType = ftAutoInc) then
        lS := ls + ' NOT NULL ';
      if (DataType = ftAutoInc) and (not nExistsUniqueConstraint(Name)) then
        lS := ls + ' UNIQUE ';
    end;
    if i < FieldDefs.Count - 1 then
      lS := ls + ', ';
  end;

  lS := lS + ') ' + getPhysAttrClauseString(lMInitial, lMNext, StoragePctIncrease, StoragePctFree, StoragePctUsed);

...

  for i := 0 to IndexDefs.Count - 1 do
    with IndexDefs[i] do
      CreateIndex(Name, Fields, Options, lIdxStorage);

...

end;


//----------------------------------------------------------------------------

procedure TOraTableExt.AddIndex(const AName, AFields: string;
  AOptions: TIndexOptions; const ADescFields: string);
begin
  // no inherited (defined here)
  CreateIndex(AName, AFields, AOptions,
    getPhysAttrClauseString(CStorageInit, CStorageNext, CStoragePctIncrease, StoragePctFree, CNoStoragePctUsed)); 
  with IndexDefs.AddIndexDef do
  begin
    Name := AName;
    Fields := AFields;
    Options := AOptions;
    DescFields := ADescFields;
  end;
end;

//----------------------------------------------------------------------------
// C,PS: truncate table used

procedure TOraTableExt.EmptyTable;
begin
  // no inherited (defined here)
  GetExecutedQuery('TRUNCATE TABLE ' + TableName);
  Refresh;
end;

//----------------------------------------------------------------------------
// N,PS:

procedure TOraTableExt.RetrieveIndexInformation;

  function nGetIndexQuery: string;
  begin
    Result :=
      'SELECT ' +
      'UI.INDEX_NAME, ' +
      'UI.UNIQUENESS, ' +
      'UC.COLUMN_NAME, ' +
      'UC.DESCEND ' +
      'FROM ' + FNameIndexes + ' UI, ' + FNameInd_Columns + ' UC ' +
      'WHERE UI.TABLE_NAME = ''' + TableName + ''' AND ' +
      'UI.INDEX_NAME = UC.INDEX_NAME';
  end;

var
  lQIndices: TDataSet;
  lIndex: TIndexDef;
  lIndexNames: TStringList;
  lIndexName, lFieldName: string;
  lIndexOptions: TIndexOptions;

begin
  IndexDefs.Clear; //B5432

  lQIndices := GetExecutedQuery(nGetIndexQuery);
  lIndexNames := TStringList.Create;
  try
    with lQIndices do
    begin
      first;
      while not eof do
      begin
        lIndexName := Fields[CIdx_INDEX_NAME].AsString;
        lFieldName := Fields[CIdx_COLUMN_NAME].AsString;
        if not lIndexNames.IndexOf(lIndexName) >= 0 then
        begin
          lIndexOptions := [];
          if Fields[CIdx_UNIQUENESS].AsString = 'UNIQUE' then
            lIndexOptions := [ixUnique];
          lIndexNames.Add(lIndexName);
          IndexDefs.Add(lIndexName, lFieldName, lIndexOptions);
        end
        else
        begin
          lIndex := IndexDefs.Find(lIndexName);
          lIndex.Fields := lIndex.Fields + ';' + lFieldName;
        end;
        next;
      end;
    end;
  finally
    FreeAndNil(lIndexNames);
  end;
  GetIndexOptionsFromConstraints;
end;

//----------------------------------------------------------------------------
// N,PS:

procedure TOraTableExt.AddIndexOption(const AIndexName: string; AOption: TIndexOption);
var
  lDef: TIndexDef;
begin
  lDef := IndexDefs.Find(AIndexName);
  checkAssigned(lDef, 'No indexDefs found for ' + AIndexName);

  lDef.Options := lDef.Options + [AOption];
end;

//----------------------------------------------------------------------------
// N,PS:

procedure TOraTableExt.GetIndexOptionsFromConstraints;
const
  CConstraintPrimary = 'P';
  CConstraintUnique = 'U';
  CIdxIndexName = 0;
  CIdxConstraintType = 1;
var
  lQConstraints: TDataSet;
begin
  lQConstraints := GetExecutedQuery(
    'SELECT ' +
    'INDEX_NAME, CONSTRAINT_TYPE ' +
    'FROM ' + FNameConstraints + ' WHERE ' +
    'TABLE_NAME = ''' + TableName + '''' +
    ' AND INDEX_NAME IS NOT NULL '
    );
  with lQConstraints do
  begin
    first;
    while not eof do
    begin
      if Fields[CIdxConstraintType].AsString = CConstraintPrimary then
        AddIndexOption(Fields[CIdxIndexName].AsString, ixPrimary)
      else
        if Fields[CIdxConstraintType].AsString = CConstraintUnique then
          AddIndexOption(Fields[CIdxIndexName].AsString, ixUnique);
      next;
    end;
  end;
end;

//----------------------------------------------------------------------------
// N,PS:

procedure TOraTableExt.AddIndexOption(const AIndexName: string; AOption: TIndexOption);
var
  lDef: TIndexDef;
begin
  lDef := IndexDefs.Find(AIndexName);
  checkAssigned(lDef, 'No indexDefs found for ' + AIndexName);

  lDef.Options := lDef.Options + [AOption];
end;

//----------------------------------------------------------------------------
// N,PS:

procedure TOraTableExt.CreateIndex(AName: string; const AFields: string;
  AOptions: TIndexOptions; AStorageClause: string = '');
var
  lQuery, lCstIndex: string;
begin
  // no inherited (defined here)
  if IndexTableSpace <> '' then
    AStorageClause := 'TABLESPACE ' + IndexTableSpace + ' ' + AStorageClause;

  lCstIndex :=
    ' USING INDEX (CREATE UNIQUE INDEX ' + AName + ' ON ' + TableName + //B2548
    ' (' + IdxFields2Sql(AFields) + ') ' + AStorageClause + ' )';

  if (ixPrimary in AOptions) then
  begin
    if AName = '' then
      AName := CProviderTableIndexPfx + intToStr(TableId) + 'PRIMARY';
    lQuery := 'ALTER TABLE ' + TableName + ' ADD CONSTRAINT ' + AName +
      ' PRIMARY KEY ' + '(' + IdxFields2Sql(AFields) + ') ' + lCstIndex
  end
  else 
...

  end;
  GetExecutedQuery(lQuery);
end;

//----------------------------------------------------------------------------
// N,PS:

function TOraTableExt.IdxFields2Sql(const AFields: string): string;
var
  i: integer;
begin
  // no inherited (defined here)
  with TStringList.Create do
  try
    Delimiter := CIndexFieldsDelimiter;
    DelimitedText := AFields;
    Result := '';
    for i := 0 to Count - 1 do
      Result := SeqStr(Result, COraQueryFieldsDelimiter, getQuotedName(Strings[i]));
  finally
    Free;
  end;
end;

//----------------------------------------------------------------------------
// N,PS:

function TOraTableExt.getPhysAttrClauseString(AInit, ANext, APctIncrease, APctFree, APctUsed: integer): string;
begin
  // no inherited (defined here)
  Result := '';
  if (APctFree <> CStoragePctFree) then
    Result := Result + ' PCTFREE ' + IntToStr(APctFree);
  if (APctUsed <> CNoStoragePctUsed) and (APctUsed <> CStoragePctUsed) then // ps changed B1408
    Result := Result + ' PCTUSED ' + IntToStr(APctUsed);

	...
end;

//----------------------------------------------------------------------------
// N,PS:

function TOraTableExt.getAutoIncTriggerName(ATableId: integer): string;
begin
  // no inherited (private)
  Result := CPfx_Triggers_AutoincFields + intToStr(ATableId);
end;

//----------------------------------------------------------------------------
// N,PS:

procedure TOraTableExt.CreateAutoIncTrigger(const ATriggerName, ATableName,
  ASequenceName, AFieldName: string);
begin
  // no inherited (private)
  GetExecutedQuery(
    'CREATE OR REPLACE TRIGGER ' + ATriggerName + ' BEFORE INSERT ON ' + ATableName + ' ' +
    'FOR EACH ROW ' +
    'BEGIN ' +
    '  SELECT ' + ASequenceName + '.NEXTVAL INTO :NEW.' + AFieldName + ' FROM DUAL; ' +
    'END;'
    );
end;



end.

