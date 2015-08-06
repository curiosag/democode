CREATE OR REPLACE function convert_raw (i_raw_prices IN WSS_UTIL#.tc_raw_records)
return T_WSS_PRICES 

PIPELINED 
PARALLEL_ENABLE (PARTITION i_raw_prices BY HASH (LINE_NUMBER)) 

AS
l_row et_raw_price%ROWTYPE;
l_curr T_RAW_PRICE;
PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
    LOOP
        FETCH i_raw_prices INTO l_row;
        EXIT WHEN i_raw_prices%NOTFOUND;
         
        IF TransformRawRecord#.EXTRACT(l_row.RAW_RECORD, l_curr) THEN       
          l_curr.LINE_NUMBER := l_row.LINE_NUMBER;        
          PIPE ROW (l_curr);
        END IF;
    END LOOP;
    
    EXCEPTION
        WHEN OTHERS THEN
            LOAD_UTILS#.add_convert_exception_msg(
                'unexpected exception running convert_raw', 
                LOAD_UTILS#.C_ADD_EXCEPTION_STACK);
            RAISE;    
RETURN;

END;

