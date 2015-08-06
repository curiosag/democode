CREATE OR REPLACE PACKAGE BODY pro#
AS

------------------------------------------------------------------------------
--2009-05-14 08:57 N,PS T13097: 
   
   PROCEDURE load_data
   IS
   BEGIN
      EXECUTE IMMEDIATE 'INSERT /*+ APPEND NOLOGGING PARALLEL */
        INTO PRO_IMPORT_PRICE
                       (PRO_PRICE_ID,
                        LINE_NUMBER,
                        IMPORT_TIMESTAMP, 
                        DATA_SOURCETYPE, 
                        
                        COMMON_CODE, 
                        ISIN, 
                   ...     
                        PRICE_A_CURRENCY_CODE, 
                        PRICE_A_CURRENCY_ISO,
                        PRICE_A,       
                   ...  
                        PRICE_B_CURRENCY_CODE, 
                   ...
                        DENOMINATION
                        )
        SELECT SQ_PRO_PRICE.NEXTVAL AS PRO_PRICE_ID,
               LINE_NUMBER,
               :gIMPORT_TIMESTAMP1, 
               :gData_sourcetype,
                
               COMMON_CODE, 
               ISIN,
              
            ...  
              
               DENOMINATION
               
        FROM V_PRO_TRANSFORMED_PRICE      
        LOG ERRORS INTO PRO_IMPORT_PRICE_ERRORS(TO_CHAR(:gIMPORT_TIMESTAMP2, ''YYYYMMDD HH24MISS''))
        REJECT LIMIT UNLIMITED'
                  USING IN gimport_timestamp, IN gdata_sourcetype, IN gimport_timestamp;
   END;

   PROCEDURE check_amenddt(i_amnddt_code IN VARCHAR, i_refday IN DATE, i_amnd_dt_expected IN DATE)
   IS
      l_result   DATE;
   BEGIN
      DELETE FROM PRO_fcrefday;
      set_fcrefday(i_refday);
      COMMIT;

      SELECT (CASE
                 WHEN NOT REGEXP_LIKE(i_amnddt_code, '\d{3}')
                  OR TO_NUMBER(i_amnddt_code) < 1
                  OR TO_NUMBER(i_amnddt_code) > refd.max_refday THEN NULL
                 WHEN TO_NUMBER(i_amnddt_code, '999') <= refd.curr THEN refd.base_dt_curr
                                                                        +(TO_NUMBER(i_amnddt_code, '999') - 1)
                 ELSE refd.base_dt_prev +(TO_NUMBER(i_amnddt_code, '999') - 1)
              END) AS price_value_date
        INTO l_result
        FROM v_fcrefday refd;

      IF i_amnd_dt_expected IS NULL THEN
         gain_app.usr_checks#.check_true(l_result IS NULL, 'check_amenddt failed. expected: null received: ');
      ELSE
         gain_app.usr_checks#.check_equals(TO_CHAR(i_amnd_dt_expected, 'dd.mm.yy'), TO_CHAR(l_result, 'dd.mm.yy'),         
                                           'check_amenddt failed. expected: '
                                           || TO_CHAR(i_amnd_dt_expected, 'dd.mm.yy')
                                           ||  ' received: '
                                           || TO_CHAR(l_result, 'dd.mm.yy'));
      END IF;
   END;
   
   ------------------------------------------------------------------------------
   -- N,PS T13097: 
   
   /* year  days/  days/    cycleid       
            year   cycle
            
     1998    365               
     1999    365    730      C0  
      
     2000    366            
     2001    365    731      C1
      
     2002    365
     2003    365    730      C2  
      
     2004    366
     2005    365    731      C3  
            
     
     Expected decoded date values depending on reference date and amnd date code
     
                   \        amd date code value
   refday per cycle \ 
   & encoded refday  \     1     |    2     |    729   |    730   |   731
   --------------------------------------------------------------------------
     1:                            
     C1:01.01.00 (1)  | 01.01.00 | 02.01.98 | 30.12.99 | 31.12.99 | invalid	
     C2:01.01.02 (1)  | 01.01.02 | 02.01.00 | 29.12.01 | 30.12.01 | 31.12.01
                                               
     2:                                        
     C1:02.01.00 (2)  | 01.01.00 | 02.01.00 | 30.12.99 | 31.12.99 | invalid
     C2:02.01.02 (2)  | 01.01.02 | 02.01.02 | 29.12.01 | 30.12.01 | 31.12.01
                                              
     max-1                                     
     C1:30.12.01 (730)| 01.01.00 | 02.01.00 | 29.12.01 | 30.12.01 | invalid
     C2:30.12.03 (729)| 01.01.02 | 02.01.02 | 30.12.03 | 30.12.01 | 31.12.01
											  
     max:                                      
     C1:31.12.01 (731)| 01.01.00 | 02.01.00 | 29.12.01 | 30.12.01 | 31.12.01
     C2:31.12.03 (730)| 01.01.02 | 02.01.02 | 30.12.03 | 31.12.03 | 31.12.01
                                  
   */   
   
   PROCEDURE test_amend_date
   IS
      c_fmt CONSTANT VARCHAR(8) := 'dd.mm.yy'; 
   BEGIN
      check_amenddt('00x', to_date('01.01.00', c_fmt), null);
      check_amenddt('-1', to_date('01.01.00', c_fmt), null);
      check_amenddt('01', to_date('01.01.00', c_fmt), null);
      check_amenddt('000', to_date('01.01.00', c_fmt), null);
      check_amenddt('732', to_date('01.01.00', c_fmt), null);

      -- 1 / C1
      check_amenddt('001', to_date('01.01.00', c_fmt), to_date('01.01.00', c_fmt));
      check_amenddt('002', to_date('01.01.00', c_fmt), to_date('02.01.98', c_fmt));      
      check_amenddt('729', to_date('01.01.00', c_fmt), to_date('30.12.99', c_fmt));
      check_amenddt('730', to_date('01.01.00', c_fmt), to_date('31.12.99', c_fmt));
      check_amenddt('731', to_date('01.01.00', c_fmt), null);
      -- 1 / C2
      check_amenddt('001', to_date('01.01.02', c_fmt), to_date('01.01.02', c_fmt));
      check_amenddt('002', to_date('01.01.02', c_fmt), to_date('02.01.00', c_fmt));      
      check_amenddt('729', to_date('01.01.02', c_fmt), to_date('29.12.01', c_fmt));
      check_amenddt('730', to_date('01.01.02', c_fmt), to_date('30.12.01', c_fmt));
      check_amenddt('731', to_date('01.01.02', c_fmt), to_date('31.12.01', c_fmt));
      -- 2 / C1      
      check_amenddt('001', to_date('02.01.00', c_fmt), to_date('01.01.00', c_fmt));
      check_amenddt('002', to_date('02.01.00', c_fmt), to_date('02.01.00', c_fmt));      
      check_amenddt('729', to_date('02.01.00', c_fmt), to_date('30.12.99', c_fmt));
      check_amenddt('730', to_date('02.01.00', c_fmt), to_date('31.12.99', c_fmt));
      check_amenddt('731', to_date('02.01.00', c_fmt), null);
      -- 2 / C2      
      check_amenddt('001', to_date('02.01.02', c_fmt), to_date('01.01.02', c_fmt));
      check_amenddt('002', to_date('02.01.02', c_fmt), to_date('02.01.02', c_fmt));      
      check_amenddt('729', to_date('02.01.02', c_fmt), to_date('29.12.01', c_fmt));
      check_amenddt('730', to_date('02.01.02', c_fmt), to_date('30.12.01', c_fmt));
      check_amenddt('731', to_date('02.01.02', c_fmt), to_date('31.12.01', c_fmt));
      -- max-1 / C1  
      check_amenddt('001', to_date('30.12.01', c_fmt), to_date('01.01.00', c_fmt));
      check_amenddt('002', to_date('30.12.01', c_fmt), to_date('02.01.00', c_fmt));      
      check_amenddt('729', to_date('30.12.01', c_fmt), to_date('29.12.01', c_fmt));
      check_amenddt('730', to_date('30.12.01', c_fmt), to_date('30.12.01', c_fmt));
      check_amenddt('731', to_date('30.12.01', c_fmt), null);
     	  -- max-1 / C2  
      check_amenddt('001', to_date('30.12.03', c_fmt), to_date('01.01.02', c_fmt));
      check_amenddt('002', to_date('30.12.03', c_fmt), to_date('02.01.02', c_fmt));      
      check_amenddt('729', to_date('30.12.03', c_fmt), to_date('30.12.03', c_fmt));
      check_amenddt('730', to_date('30.12.03', c_fmt), to_date('30.12.01', c_fmt));
      check_amenddt('731', to_date('30.12.03', c_fmt), to_date('31.12.01', c_fmt));
      -- max / C1    
      check_amenddt('001', to_date('31.12.01', c_fmt), to_date('01.01.00', c_fmt));
      check_amenddt('002', to_date('31.12.01', c_fmt), to_date('02.01.00', c_fmt));      
      check_amenddt('729', to_date('31.12.01', c_fmt), to_date('29.12.01', c_fmt));
      check_amenddt('730', to_date('31.12.01', c_fmt), to_date('30.12.01', c_fmt));
	   check_amenddt('731', to_date('31.12.01', c_fmt), to_date('31.12.01', c_fmt));
      -- max / C2    
      check_amenddt('001', to_date('31.12.03', c_fmt), to_date('01.01.02', c_fmt));
      check_amenddt('002', to_date('31.12.03', c_fmt), to_date('02.01.02', c_fmt));      
      check_amenddt('729', to_date('31.12.03', c_fmt), to_date('30.12.03', c_fmt));
      check_amenddt('730', to_date('31.12.03', c_fmt), to_date('31.12.03', c_fmt));   
      check_amenddt('731', to_date('31.12.03', c_fmt), to_date('31.12.01', c_fmt));  
   END;
   
END idc#;
/
