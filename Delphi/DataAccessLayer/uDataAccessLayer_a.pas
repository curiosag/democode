unit uDataAccessLayer_a;

interface

type

  TAbstractDataRow = class
  protected
    function GetMetaField(AIdx: integer): TMdField; virtual; abstract;
    function GetIntValue(AIdx: integer): integer; virtual; abstract;
...
    function GetDateTimeValue(AIdx: integer): TDateTime; virtual; abstract;
    function GetIsNull(AIdx: integer): boolean; virtual; abstract;
  public
    procedure SetIntValue(AIdx: integer; AValue: integer); virtual; abstract;
...
    procedure SetDateTimeValue(AIdx: integer; AValue: TDateTime); virtual; abstract;
    procedure ClearField(AIdx: integer); virtual; abstract;

    property MetaField[AIdx: integer]: TMdField read getMetaField;
    property IntValue[AIdx: integer]: integer read getIntValue;
...
    property DateTimeValue[AIdx: integer]: TDateTime read getDateTimeValue;
    property IsNull[AIdx: integer]: boolean read getIsNull;
  end;
 
  TAbstractDataSet = class(TAbstractDataRow)
  public
    procedure Append; virtual; abstract;
    function GetKeyValue: TKeyVal; virtual; abstract;
    procedure SetRelation(AValue: TKeyVal); virtual; abstract;
  end;

  TAbstractWriter = class
  public
    function GetDataSet(ANode: PMdNode; var ADataSet: TAbstractDataSet): boolean; virtual; abstract;
    // alters data store structures according to metadata
    procedure updateDataStructure(ANewMetaDataRoot: PMdNode; AVerbosely: boolean); virtual; abstract;
    function GetHasData(ANode: PMdNode): boolean; virtual; abstract;
  end;

implementation

end.

