unit uDB2Writer;

interface

type
  TDFDB2Writer = class(TSqlDbWriter_c)
  private
    FDB2Database: TDb2Database;
    FWriteLock: TDb2Database;
    FOptions: TReducedDfOptions;

    FSQLFormat: TSQLFormat_DB2;

    FTableSpaceName: string;
    FLobTableSpaceName: string;
    FIndexTableSpaceName: string;
    FPrefetchRows: integer;
    FIndexMinPctUsed: integer;
    FIndexPctFree: integer;
    FTablePctFree: integer;

    procedure OwnStandardTAParams(out AParams: TTaConstructorParameters_db2;
      const ATableName: string;
      const AAccessMode: TTAAccessMode;
      const AOpenExclusively: boolean;
      const AIsProviderTableLoad: boolean);
    procedure OwnTaForLoad(const ATableName: string;
      const AIsRoot: boolean; out ATAccess: TabstractTableAccess);
    procedure OwnTaForTableLikeUsage(const ATableName: string;
      const AOpenExclusively: boolean;
      out ATAccess: TAbstractTableAccess);
    procedure CorrectFieldDefs(ATableAccess: TAbstractTableAccess;
      AFieldInfo: PTDFFieldInfo);
    procedure LockTable(ADataBase: TSDDatabase; const ATable: string);
    procedure ConnectToDatabase(ADatabase: TSDDatabase; AOptions: IDfOptions);
  protected
    procedure OpenDatabase(AOptions: IDfOptions); override;
    procedure FreeDatabase; override;
    procedure GetDbTableNames(ATableNames: TStringList); override;
    function GetDatabaseType: TDatabaseType; override;
    function GetSQLFormat: TSQLFormat_a; override;
    class function GetElemPropRange(
      AElementType: TDRElementType): TDRElementPropertyRange; override;
    function GetSupportsReading: boolean; override;
    function GetForeignKeyParent: boolean; override;
    function InternalOwnTableAccess(const ATableName: string;
      var ATableAccess: TAbstractTableAccess;
      AOpenExclusively: boolean;
      ARetrieveIndexes: boolean;
      AAddToRepository: boolean;
      AWriteOnly: Boolean;
      const AFilter: string;
      ARetrieveAutoIncInfo: boolean): boolean; override;
    procedure InternalOwnDbDDataSet(ATableName: string;
      ANode: PMdNode; AOpenMode: TDFOpenModes; out AFields: TDbDFSetDataFields); override;
  public
    function GetInTransaction: boolean; override;
    procedure doStartTransaction; override;
    procedure doRollback; override;
    procedure SetOptions(AOptions: IDFOptions); override;
    function GetDbTableName(AName: string): string; override;

    function GetTableExists(const ATableName: string): boolean; override;

  end;

implementation


const
  CInvalidTableName = '''%s'' is not a valid tablename';

const
  CMaxTypeMappings = 8;

  CDb2DbDfTypeMapping: array[0..CMaxTypeMappings] of TDbDfTypeMapping = (
    (Db: 'integer'; Df: dtInteger),
    (Db: 'decimal'; Df: dtInt64),
    (Db: 'double'; Df: dtDouble),
    (Db: 'date'; Df: dtDate),
    (Db: 'time'; Df: dtTime),
    (Db: 'timestamp'; Df: dtDateTime),
    (Db: 'varchar'; Df: dtString),
    (Db: 'clob'; Df: dtString),
    (Db: 'blob'; Df: dtBlob));

//----------------------------------------------------------------------------

procedure TDFDB2Writer.InternalDoCommit;
begin
  // no inherited; (abstract)
  try
    FDB2Database.Commit;
  except
    on E: EDB2Error do
      raise EWriterUsrInfo.Fire(Self, E.Message);
  end;
end;

//----------------------------------------------------------------------------

procedure TDFDB2Writer.doRollback;
begin
  // no inherited; (abstract)
  try
    FDB2Database.Rollback;
  except
    on E: EDB2Error do
      raise EWriterUsrInfo.Fire(Self, E.Message);
  end;
end;

//----------------------------------------------------------------------------

procedure TDFDB2Writer.doStartTransaction;
begin
  // no inherited; (abstract)
  try
    FDB2Database.StartTransaction;
  except
    on E: EDB2Error do
      raise EWriterUsrInfo.Fire(Self, E.Message);
  end;
end;


//----------------------------------------------------------------------------

function TDFDB2Writer.getDatabaseType: TDatabaseType;
begin
  //no inherited (abstract)
  Result := tdbtDB2;
end;

//----------------------------------------------------------------------------
// T42:

function TDFDB2Writer.getDataSetCount: integer;
begin
  // no inherited (abstract)
  Result := FDB2Database.DataSetCount;
end;

//----------------------------------------------------------------------------
// N,PS T42:

function TDFDB2Writer.getDbAttribStr(AAttrib: string): string;
begin
  //no inherited (abstract)
  Result := TDB2TableAccess.getDbAttribStr(AAttrib);
end;

//----------------------------------------------------------------------------
// N,PS T42:

function TDFDB2Writer.getDbTableName(AName: string): string;
begin
  //no inherited (abstract)
  Result := TDB2TableAccess.getQryAttribStr(AName);
end;


//----------------------------------------------------------------------------

class function TDFDB2Writer.getElemPropRange(
  AElementType: TDRElementType): TDRElementPropertyRange;
begin
  // no inherited (abstract)
  Result := TDB2TableAccess.getElemPropRange(AElementType);
end;


//----------------------------------------------------------------------------
// N,PS T42:

function TDFDB2Writer.getQryAttribStr(AAttrib: string): string;
begin
  // no inherited (abstract)
  Result := TDB2TableAccess.getQryAttribStr(AAttrib);
end;

//----------------------------------------------------------------------------
// N,PS T42:

function TDFDB2Writer.getSQLFormat: TSQLFormat_a;
begin
  // no inherited (abstract)
  Result := FSqlFormat;
end;

//----------------------------------------------------------------------------
// N,PS T42:

procedure TDFDB2Writer.OwnStandardTAParams(
  out AParams: TTaConstructorParameters_db2;
  const ATableName: string;
  const AAccessMode: TTAAccessMode;
  const AOpenExclusively: boolean;
  const AIsProviderTableLoad: boolean);
begin
  AParams := TTaConstructorParameters_db2.Create(
    ATableName,
    FDB2Database,
    AAccessMode,
    FIndexMinPctUsed,
    FIndexPctFree,
    FTablePctFree,
    FIndexTableSpaceName,
    FLobTableSpaceName,
    FTableSpaceName,
    CFreeTableOnDestroy,
    AOpenExclusively,
    AIsProviderTableLoad
    );
end;

//----------------------------------------------------------------------------
// N,PS T42:

procedure TDFDB2Writer.OwnClone(out AClone: TAbstractWriter);
begin
  //no inherited (abstract)
  if OpenExclusively then
    raise EWriterIntern.Fire(self,
      'Can not clone if opended exclusively');

  AClone := TDFDB2Writer.Create;
  AClone.SetOptions(Self.GetOptions);
end;

//----------------------------------------------------------------------------
// N,PS T42:

function TDFDB2Writer.getSupportsReading: boolean;
begin
  // no inherited (abstract)
  Result := true;
end;

//----------------------------------------------------------------------------
//2004-01-04 18:39 N,PS T42:

procedure TDFDB2Writer.DetermineDataType(const AFieldInfoQuery: TDataSet;
  out ADataType: TDataType; out ALength: integer;
  out AFieldName: string);
var
  lDbTypeString: string;
  i: integer;
begin
  // no inherited (abstract)
  checkAssigned(AFieldInfoQuery);
  checkEquals(AFieldInfoQuery.Fields.count, 3, 'invalid query result received for determining field information');
  checkEquals(AFieldInfoQuery.bof, false, 'bof reached in query result for determining field information');

  AFieldName := AFieldInfoQuery.Fields[0].AsString;
  ALength := AFieldInfoQuery.Fields[2].AsInteger;
  lDbTypeString := AnsiLowerCase(AFieldInfoQuery.Fields[1].AsString);

  ADataType := dtUnknown;
  for i := 0 to CMaxTypeMappings do
    with CDb2DbDfTypeMapping[i] do
      if lDbTypeString = Db then
      begin
        ADataType := Df;
        break;
      end;

  if ADataType = dtUnknown then
    raise EWriterUsrInfo.FireFmt(
      Self, LangHdl.Translate(STdftUnknown), [AFieldName, lDbTypeString]);

  if ADataType in [dtInteger, dtInt64, dtDate, dtTime, dtDateTime, dtDouble] then
    ALength := 0;
end;

//----------------------------------------------------------------------------
// N,PS T42:

function TDFDB2Writer.getFieldInfoQuery(const ATableName: string): string;
begin
  // no inherited (abstract)
  Result := 'SELECT COLNAME , TYPENAME , LENGTH ' +
    'FROM SYSCAT.COLUMNS ' +
    'WHERE TABNAME = ''%s'' ' +
    'ORDER BY COLNO ASC';
  Result := Format(Result, [ATableName])
end;

//----------------------------------------------------------------------------
// N,PS T42:

function TDFDB2Writer.CreateTableAccessForDataStructureCheck(AFieldInfo: PTDFFieldInfo): TAbstractTableAccess;
var
  lNode: PMdNode;
begin
  checkAssigned(AFieldInfo);

  lNode := CreateMetaNodesForDataStructureCheck(AFieldInfo);
  Result := TDb2CheckDataStructureTableAccess.Create(self, lNode); //owns lnode
end;

//----------------------------------------------------------------------------
// N,PS T42:

procedure TDFDB2Writer.TransferFieldProperties(ASource, ADest: TDataSet);
var
  i: integer;
  lSrcName, lDestName: string;
begin
  checkAssigned(ASource);
  checkAssigned(ADest);
  checkEquals(ASource.FieldDefs.Count, ADest.FieldDefs.Count, 'number of FieldDefs different');
  ADest.FieldDefs.BeginUpdate;
  try
    for i := 0 to ASource.FieldDefs.Count - 1 do
    begin
      lSrcName := ASource.FieldDefs[i].Name;
      lDestName := ADest.FieldDefs[i].Name;
      checkEquals(lSrcName, lDestName,
        Fmt('Field names differ on position %d (%s <> %s)', [i, lSrcName, lDestName]));

      ADest.FieldDefs[i].DataType := ASource.FieldDefs[i].DataType;
      ADest.FieldDefs[i].Size := ASource.FieldDefs[i].Size;
    end;
  finally
    ADest.FieldDefs.EndUpdate;
  end;
end;

//----------------------------------------------------------------------------
// N,PS T42:

function TDFDB2Writer.getConstraintsQuery(const ATableName: string): string;
begin
  // no inherited (abstract)
  Result := uDfDb2WriterUtil.getConstraintsQuery(tctForeignKey, ATableName);
end;

//----------------------------------------------------------------------------
// N,PS T42:

procedure TDFDB2Writer.OwnTaForTableLikeUsage(const ATableName: string;
  const AOpenExclusively: boolean;
  out ATAccess: TAbstractTableAccess);
var
  lInitParams: TTaConstructorParameters_db2;
begin
  OwnStandardTAParams(lInitParams, ATableName, tamReadWrite, AOpenExclusively, not CIsProviderTableLoad);
  try
    ATAccess := TDB2TableAccess.Create(Self, lInitParams);
  finally
    FreeAndNil(lInitParams);
  end;
end;

//----------------------------------------------------------------------------
// N,PS:

function TDFDB2Writer.GetLockQuery(const ATableName: string): string;
begin
  Result := 'LOCK TABLE ' + ATableName + ' IN EXCLUSIVE MODE';
end;


end.

