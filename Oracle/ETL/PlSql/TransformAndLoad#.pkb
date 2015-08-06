CREATE OR REPLACE PACKAGE BODY TL#
AS
  
  PROCEDURE IMPORT_DATA(i_import_timestamp TIMESTAMP)
  AS
  BEGIN
    EXECUTE IMMEDIATE
      'INSERT /*+ APPEND NOLOGGING PARALLEL */
      INTO IMPORT_PRICE
      (
        PRICE_ID,                 
        LINE_NUMBER,             
        IMPORT_TIMESTAMP,       
        RECORD_TYPE,            
        R_SECURITIES_CODE,      
        R_ISIN,                 
       ...
        CLOSING_PRICE
        
      )  
    SELECT SQ_IMPORT_PRICE.NEXTVAL,     
        LINE_NUMBER,
        :IMPORT_TIMESTAMP1, 
        RECORD_TYPE,
        R_SECURITIES_CODE,
        R_ISIN,
      ...
        CLOSING_PRICE
           
    FROM V_TRANSFORMED_PRICE
    LOG ERRORS INTO IMPORT_PRICE_ERRORS(TO_CHAR(:IMPORT_TIMESTAMP2, ''YYYYMMDD HH24MISS''))
    REJECT LIMIT UNLIMITED'
    USING IN i_import_timestamp, IN i_import_timestamp;

  END;
  
  PROCEDURE LOAD(i_loadtimestamp VARCHAR)
  AS
  BEGIN        
    IMPORT_DATA (TO_DATE(i_loadtimestamp, 'YYYYMMDD_HH24MISS'));
    COMMIT;
                                                             
  END;
  
  PROCEDURE CHECK_LOAD(o_num_errloglines OUT PLS_INTEGER)
  AS
  BEGIN
    SELECT COUNT(*) 
    INTO o_num_errloglines
    FROM IMPORT_PRICE_ERRORS;
  END;

END;
