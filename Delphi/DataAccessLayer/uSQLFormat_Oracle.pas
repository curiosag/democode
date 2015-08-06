unit uSQLFormat_Oracle;

interface
{$I iGlobalConfig.pas}
uses
  uSQLFormat_a, uSQLFormat_c, uAbstractProcessor, uDFDCl, Db;

type
  TSQLFormat_Oracle = class(TSQLFormat_c)
  public
    function getVal(AField: TAbstractDataRow; AIdx: integer): string; override;
    function getEqOp(AMetaField: TMetaField): string; override;
    function getDDLFieldIdent(AField: PMetaField): string; override;
    function getDMLFieldIdent(AField: PMetaField): string; override;
    function getDataTypeString(AType: TFieldType; ASize: integer): string; override;
    function getSymCommentBegin: string; override;
    function getSymCommentEnd: string; override;
    function get1LineComment: string; override;
  end;

implementation

uses
  uWriterConst_h, uDFOracleWriterConst_h, uWriterTypes_h,
  uOracleTableAccess, uCustomTableAccess, uWriterUtils, uKrnl_r,
  Ora,
  uSQLFormatUtil, SysUtils;

//----------------------------------------------------------------------------

function TSQLFormat_Oracle.getDataTypeString(AType: TFieldType; ASize: integer): string;
begin
  // no inherited (abstract)
  if AType = TFieldType(ftXML) then
    Result := 'XMLTYPE'
  else
    case AType of
      ftString: Result := 'VARCHAR2(' + IntToStr(ASize) + ')';
      ftInteger, ftSmallInt, ftAutoInc,
        ftBoolean: Result := 'NUMBER(' + intToStr(CPrecisionInteger) + ', 0)';
...
      ftTimeStamp: Result := 'TIMESTAMP';
    else
      raise EWriterIntern.Fire(self, 'Type not supported');
    end;
end;

//----------------------------------------------------------------------------

function TSQLFormat_Oracle.getSymCommentBegin: string;
begin
  // no inherited (abstract)
  Result := '/*'; //begin of  sql comment line
end;

//----------------------------------------------------------------------------

function TSQLFormat_Oracle.getSymCommentEnd: string;
begin
  // no inherited (abstract)
  Result := '*/'; //end of sql comment line
end;

//----------------------------------------------------------------------------

function TSQLFormat_Oracle.getEqOp(AMetaField: TMetaField): string;
begin
  if (AMetaField.DataType = dtString) and
    GetStringIsLobField(AMetaField.MaxLength, CMaxLenOraVarchar2) then
    Result := ' LIKE '
  else
    Result := inherited getEqOp(AMetaField);
end;


end.

