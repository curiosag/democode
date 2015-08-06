create or replace
PACKAGE BODY RTG_UTIL# AS

   c_tag_RATING_AGENCY_ID constant varchar2(30) := '<RATING_AGENCY_ID>';
   c_tag_ENTITY_ID constant varchar2(30) := '<ENTITY_ID>';
   c_tag_PREFIX_AGNCY constant varchar2(30) := '<PREFIX_AGNCY>';   
   c_tag_NAME_ERROR_INFO constant VARCHAR2(30) := '<NAME_ERROR_INFO>';
   c_tag_EXPRESSION_ERROR_INFO constant varchar2(30) := '<EXPRESSION_ERROR_INFO>';

   c_errcs_blank_rtg mdm_of.id%TYPE;
   
   TYPE t_errname IS TABLE OF mdm_of.NAME%TYPE INDEX BY PLS_INTEGER;
   g_mdm_ofnames t_errname;    
      
   type t_rtg_error_recs_internal is ref cursor;
   
   FUNCTION exists_ID(i_of_id IN VARCHAR2) RETURN boolean;

   PROCEDURE list_of(i_of_id IN VARCHAR2, i_ofid IN VARCHAR2)
   IS
      l_of_id mdm_of.id%TYPE;
      l_ofname mdm_of.NAME%TYPE;
   BEGIN     
      l_of_id := ...;         
      g_mdm_ofes(i_ofid) := l_of_id;
      SELECT NAME
      INTO l_ofname
      FROM mdm_of
      WHERE id = l_of_id;
      g_mdm_ofnames(l_of_id) := l_ofname;
   END;


   FUNCTION get_of_name(i_of_id in mdm_of.id%TYPE)
      RETURN mdm_of.NAME%TYPE
   IS   
   BEGIN
      RETURN g_mdm_ofnames(i_of_id);
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN NULL;     
      WHEN OTHERS THEN
         RAISE;
   END;

------------------------------------------------------------------------------
-- N,PS T23195:

  PROCEDURE collect_symbols(i_agency_id IN mdm_of.id%type, i_targettable_name IN VARCHAR2) 
  AS  
  BEGIN   
    EXECUTE IMMEDIATE 
    'INSERT /*+ APPEND NOLOGGING */ INTO '|| i_targettable_name ||
    q'{ SELECT id, substr(NAME, instr(NAME, '_') + 1) symbol
      FROM mdm_of
      WHERE of_id = 'cp_rating_sym'
      and  substr(NAME, 1, instr(NAME, '_') - 1) = :1}' using get_of_name(i_agency_id);      
  END;

  
------------------------------------------------------------------------------
-- N,PS T23195:

  FUNCTION set_query_tagvalues(i_query IN VARCHAR2, 
                               i_agncy_id mdm_of.id%TYPE,
                               i_entity_id PLS_INTEGER)
  RETURN VARCHAR2                               
  IS      
      l_query varchar2(10000);
  BEGIN       
       l_query := REPLACE(i_query, c_tag_RATING_AGENCY_ID, i_agncy_id);
       l_query := REPLACE(l_query, c_tag_PREFIX_AGNCY, get_of_name(i_agncy_id));
       RETURN REPLACE(l_query, c_tag_ENTITY_ID, i_entity_id);       
  END;

------------------------------------------------------------------------------
-- N,PS T23195:
-- C,PS B24429:

   PROCEDURE SYNC_mdm(i_agncy_id mdm_of.id%TYPE)
   IS
      c_query_ins VARCHAR2(1000) := 
           'INSERT INTO mdm_RATING R    
            (RATING_AGENCY_ID, OBJ_ID, RATING_SYMBOL_ID, RATING_SCHEME_ID, RATING_DATE_FROM)
            SELECT <RATING_AGENCY_ID> RATING_AGENCY_ID, cpk.id OBJ_ID, 
                   rtg_of_id RATING_SYMBOL_ID, rtg_scheme_id RATING_SCHEME_ID, rtg_dt RATING_DATE_FROM
              FROM <PREFIX_AGNCY>_rating_cp_eval rcp
              JOIN <PREFIX_AGNCY>_cp_key cpk 
                ON cpk.key_val=rcp.cp_id  
            WHERE NOT EXISTS
            (
               SELECT 1
               FROM <PREFIX_AGNCY>_mdm_RATING_CP RC
               WHERE RC.obj_id = cpk.id                              
               AND   RC.RATING_SCHEME_ID = rcp.rtg_scheme_id
            )';
      -- MERGE instead of UPDATE for technical reasons related to the implementation of UPDATE
        'MERGE INTO mdm_RATING RTG_CURR
         USING (select cpk.id OBJ_ID, rtg_of_id RATING_SYMBOL_ID, 
                       rtg_scheme_id RATING_SCHEME_ID, rtg_dt RATING_DATE_FROM
                  FROM <PREFIX_AGNCY>_rating_cp_eval rcp
                  JOIN <PREFIX_AGNCY>_cp_key cpk 
                    ON cpk.key_val=rcp.cp_id
                  WHERE R.RATING_DATE_FROM < rcp.rtg_dt
                     OR (R.RATING_DATE_FROM = rcp.rtg_dt) RTG_IN
            ON (RTG_CURR.obj_id = RTG_IN.obj_id 
            AND RTG_CURR.ENTITY_ID = <ENTITY_ID>)
          WHEN MATCHED THEN
            UPDATE SET RTG_CURR.RATING_SYMBOL_ID = RTG_IN.RATING_SYMBOL_ID,
                       RTG_CURR.RATING_DATE_FROM = RTG_IN.RATING_DATE_FROM';
   BEGIN
      EXECUTE IMMEDIATE set_query_tagvalues(c_query_ins, i_agncy_id, cbl_h#.c_entity_id);
      EXECUTE IMMEDIATE 
         set_query_tagvalues(c_query_upd, i_agncy_id, cbl_h#.c_entity_id) using i_agncy_id;
   END;

------------------------------------------------------------------------------
-- N,PS T23195:

   PROCEDURE gather_table_stats(i_agency_id IN mdm_of.id%type, i_table_name IN VARCHAR2)
   IS
   BEGIN
      DBMS_STATS.gather_table_stats (ownname => g_agncy_dbusers(i_agency_id), tabname => i_table_name, degree => 1); 
   END;

BEGIN
   Init;  
END RTG_UTIL#;
