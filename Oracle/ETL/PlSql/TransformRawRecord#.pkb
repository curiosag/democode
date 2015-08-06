CREATE OR REPLACE PACKAGE BODY TransformRawRecord#
AS
UTIL
  TYPE T_KEYLIST IS TABLE OF VARCHAR(4); 
  TYPE T_VAL_LEN IS TABLE OF PLS_INTEGER;

  g_price T_RAW_PRICE := NULL;
  g_result_extract BOOLEAN := FALSE;   
  g_idxBegin PLS_INTEGER;
  g_idxEnd PLS_INTEGER;
  g_idx PLS_INTEGER;
  g_currval VARCHAR(32);
  g_num_values PLS_INTEGER;  
  g_keys T_KEYLIST := T_KEYLIST(':01E',':02A',':03A',':04F',':05F',':06F',':07A',':10A',':13F',':21F',':29F');
  g_vlen T_VAL_LEN := T_VAL_LEN(5, 12, 24, 6, 8, 16, 16, 6, 2, 4, 32);
  
  cFieldDelim VARCHAR(1) := ':'; 
    
  cRECORD_TYPE          PLS_INTEGER := 1;
  cR_SECURITIES_CODE    PLS_INTEGER := 2;
  cR_ISIN               PLS_INTEGER := 3;  
  ...
  cR_CLOSING_PRICE      PLS_INTEGER := 11;
  
  e_problem EXCEPTION;
  
  FUNCTION PICK(i_key_Idx IN PLS_INTEGER, i_source IN OUT NOCOPY VARCHAR, i_price IN OUT NOCOPY T__RAW_PRICE) RETURN PLS_INTEGER
  IS
  BEGIN    
    g_idx := INSTR(i_source, g_keys(i_key_Idx), g_idxBegin, 1);
    IF g_idx <= 0 THEN
      g_currval := '';           
    ELSE
      g_idxBegin := g_idx + LENGTH(g_keys(i_key_Idx));
      g_idx := INSTR(i_source, cFieldDelim, g_idxBegin, 1);
      
      IF g_idx > 0 THEN
        g_idxEnd := g_idx - 1;   
      ELSE
        g_idxEnd := LENGTH(i_source);       
      END IF;
      
      g_currval := SUBSTR(i_source, g_idxBegin, g_idxEnd - (g_idxBegin - 1));
	  g_idxBegin := g_IdxEnd;      
    END IF;  
  
    IF LENGTH(g_currval) > 0
    THEN
        CASE i_key_Idx       
           WHEN cRECORD_TYPE          THEN i_price.RECORD_TYPE          := SUBSTR(g_currval, 1, g_vlen(i_key_Idx));
           WHEN cR_SECURITIES_CODE    THEN i_price.R_SECURITIES_CODE    := SUBSTR(g_currval, 1, g_vlen(i_key_Idx));          
     ...
           WHEN cR_CLOSING_PRICE      THEN i_price.R_CLOSING_PRICE      := SUBSTR(g_currval, 1, g_vlen(i_key_Idx));                 
           ELSE RAISE e_problem;      
        END CASE;
        RETURN LENGTH(g_currval);
    ELSE
        RETURN 0;            
    END IF;            
  END;
  
  FUNCTION EXTRACT(i_source IN OUT NOCOPY VARCHAR, o_price OUT T__RAW_PRICE) RETURN BOOLEAN
  IS   
  BEGIN
    g_idxBegin := 1;       
    g_num_values := 0;
    
    IF g_price IS NULL THEN
      g_price := T__RAW_PRICE (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    END IF;
    
    FOR l_key_idx IN 1 .. g_keys.COUNT LOOP
      g_num_values := g_num_values + PICK(l_key_idx, i_source, g_price);
    END LOOP;
    
    IF g_num_values > 0 THEN
      g_result_extract := true;
      o_price := g_price;
      g_price := NULL;
    ELSE
      g_result_extract := false;
      o_price := NULL;
    END IF;
    
    RETURN g_result_extract;
  END;


END TransformRawRecord#;
/
