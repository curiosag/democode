CREATE TYPE T_RAW_PRICE AS OBJECT
(       
    LINE_NUMBER             NUMBER(10),    
    RECORD_TYPE             VARCHAR2(5),
    R_SECURITIES_CODE       VARCHAR2(12),
    R_ISIN                  VARCHAR2(24),
    R_STOCK_EXCHANGE        VARCHAR2(6),
    R_MIC                   VARCHAR2(8),
    R_DATE_CONSECUTIVELY    VARCHAR2(16),
    R_FIXING_DATE           VARCHAR2(16),
    R_PRICE_CURRENCY        VARCHAR2(6),
    R_LISTING_TYPE          VARCHAR2(2),
    R_MARKET                VARCHAR2(4),
    R_CLOSING_PRICE         VARCHAR2(32)
);

