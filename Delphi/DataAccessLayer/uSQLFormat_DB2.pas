unit uSqlFormat_DB2;

interface
uses
  uSQLFormat_a, uSQLFormat_c, uAbstractProcessor, uMd, Db;

type
  TSQLFormat_DB2 = class(TSQLFormat_c)
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
  uWriterConst_h, uDFDB2WriterConst_h, uWriterTypes_h,
  uWriterUtils, uDB2TableAccess,
  uCustomTableAccess,
  uSQLFormatUtil, uKrnl_r, SysUtils;

//----------------------------------------------------------------------------

function TSQLFormat_DB2.getVal(AField: TAbstractDataRow; AIdx: integer): string;
var
  lChr: char;
  lFormats: TFormatSettings;
begin
  // no inherited (abstract)
  CheckFieldsAccess(AField, AIdx);

  case AField.MetaField[AIdx].DataType of
    dtString: Result := AnsiQuotedStr(AField.StringValue[AIdx], CHyphen);
    dtInteger: Result := IntToStr(AField.IntValue[AIdx]);
    dtDouble: //B2923
      begin
        lFormats.DecimalSeparator := CDecimalSeparator_dot;
        Result := FloatToStr(AField.FloatValue[AIdx], lFormats);
      end;
    dtChar:
      begin
        lChr := AField.CharValue[AIdx];
        if lChr = #0 then
          Result := AnsiQuotedStr('', CHyphen)
        else
          Result := AnsiQuotedStr(lChr, CHyphen);
      end;
    dtBoolean:
      if AField.BoolValue[AIdx] then
        Result := IntToStr(CTrue_DbIntMapping)
      else
        Result := IntToStr(CFalse_DbIntMapping);
    dtDate: Result := Format('DATE(%s)',
        [AnsiQuotedStr(getAnsiDateStr(AField.DateValue[AIdx]), CHyphen)]);
    dtTime: Result := Format('TIME(%s)', //B2923
        [AnsiQuotedStr(FormatDateTime(CDb2TimeFormatString, AField.TimeValue[AIdx]), CHyphen)]);
    dtDateTime: Result := Format('TIMESTAMP(%s)', //B2923
        [AnsiQuotedStr(FormatDateTime(CDb2TimeStampFormatString, AField.DateTimeValue[AIdx]), CHyphen)]);
    dtInt64: Result := IntToStr(AField.Int64Value[AIdx]);
  else
    raise EWriterIntern.Fire(self, 'Type not supported');
  end;
end;

//----------------------------------------------------------------------------

function TSQLFormat_DB2.getDDLFieldIdent(AField: PMetaField): string;
begin
  // no inherited (abstract)
  checkAssigned(AField);
  Result := TDB2TableAccess.getDbAttribStr(AField^.Identifier);
end;

//----------------------------------------------------------------------------

function TSQLFormat_DB2.getDMLFieldIdent(AField: PMetaField): string;
begin
  // no inherited (abstract)
  checkAssigned(AField);
  Result := AField^.Identifier;
end;

//----------------------------------------------------------------------------

function TSQLFormat_DB2.getDataTypeString(AType: TFieldType; ASize: integer): string;
begin
  // no inherited (abstract)
  case AType of
    ftSmallInt: Result := 'SMALLINT';
    ftInteger: Result := 'INTEGER';
    ftWord: Result := 'INTEGER'; 
    ftLargeInt: Result := 'DEC(19,0)'; 
    ftBoolean: Result := 'SMALLINT';
    ftAutoInc: Result := 'INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY'; // no CYCLE attribute here, would violate identity (2005-01-01)
...
    ftDate: Result := 'DATE';
    ftTime: Result := 'TIME';
    ftDateTime, ftTimeStamp: Result := 'TIMESTAMP';
    ftBlob: Result := 'BLOB'; //the length/size doesn't need to be specified
...
  else
    raise EWriterIntern.Fire(self, 'Type not supported: ' + Format('%d', [Integer(AType)]));
  end;
end;

function TSQLFormat_DB2.getSymCommentBegin: string;
begin
  // no inherited (abstract)
  Result := '/*'; //begin of SQL comment
end;

//----------------------------------------------------------------------------

function TSQLFormat_DB2.getSymCommentEnd: string;
begin
  // no inherited (abstract)
  Result := '*/'; //end of SQL comment
end;

//----------------------------------------------------------------------------
//2004-09-06 12:54 N,MN:

function TSQLFormat_DB2.getEqOp(AMetaField: TMetaField): string;
begin
  if (AMetaField.DataType = dtString) and
    GetStringIsLobField(AMetaField.MaxLength, CDb2MaxLenDbString) then
    Result := ' LIKE '
  else
    Result := inherited getEqOp(AMetaField);
end;

//----------------------------------------------------------------------------

function TSQLFormat_DB2.get1LineComment: string;
begin
  Result := '--';
end;

end.

