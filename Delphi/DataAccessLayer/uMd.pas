unit uMd;

interface

type
  TDataType = (dtInteger, dtInt64, dtDouble, dtString, dtChar,
    dtBoolean, dtDate, dtTime, dtDateTime);

  PMdField = ^TMdField;
  TMdField = packed record
    Identifier: PChar;
    DataType: TDataType;
    IsKeyField: boolean;
    next: PMdField; 
  end;

  PMdNode = ^TMdNode;
  TMdNode = packed record
    Identifier: PChar;
    next, lower: PMdNode;
    Field: PMdField;
  end;

end.

