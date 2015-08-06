CREATE OR REPLACE VIEW V_TRANSFORMED_PRICE AS
SELECT      
    LINE_NUMBER,    
    RECORD_TYPE,
    R_SECURITIES_CODE,
    R_ISIN,
    R_CLOSING_PRICE,
     
    (CASE WHEN LENGTH(R_SECURITIES_CODE) = 6 THEN 
        R_SECURITIES_CODE
       ELSE NULL        
     END
    ) AS SECURITIES_CODE,    
    
    (CASE WHEN LENGTH(R_ISIN) = 12 THEN 
        R_ISIN
       ELSE NULL        
     END
    ) AS ISIN,
           
    (CASE WHEN R_STOCK_EXCHANGE IN ('EDS', 'EDF') THEN 
        R_STOCK_EXCHANGE
       ELSE NULL        
     END
    ) AS STOCK_EXCHANGE,
    
...    
    
    
    (CASE WHEN REGEXP_LIKE(R_CLOSING_PRICE, '^(([0-9]{0,8},{0,1}[0-9]{0,7}))$') THEN 
        TO_NUMBER(R_CLOSING_PRICE, '99999999D9999999', 'NLS_NUMERIC_CHARACTERS = '',.''')
       ELSE NULL        
     END
    ) AS CLOSING_PRICE    
    
    
    
FROM table (convert_raw(CURSOR(select * from ET_RAW_PRICE))) RP; 

  