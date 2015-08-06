CREATE OR REPLACE VIEW v_cp_rating_eval AS
SELECT /*+ PARALLEL */ SRCID, CP_ID, rtg_scheme_id, RTG_VAL, sym.key_id RTG_CLS_ID, RTG_DT, PRIORITY,
       MAX(RTG_DT) OVER (PARTITION BY CP_ID, rtg_scheme_id, PRIORITY) MAX_RTG_DT,
       MIN(PRIORITY) OVER (PARTITION BY CP_ID, rtg_scheme_id) HIGHEST_PRIORITY,
       COUNT(DISTINCT RTG_VAL) OVER (PARTITION BY CP_ID, rtg_scheme_id, PRIORITY, RTG_DT) NUM_DIST_SYMS,    
       ROW_NUMBER() OVER (PARTITION BY CP_ID, rtg_scheme_id, PRIORITY, RTG_DT ORDER BY CP_ID) GRP_SEQ_ID 
FROM rating_cp_norm norm
LEFT OUTER JOIN rating_cp_symbol sym
ON norm.RTG_VAL=sym.symbol;