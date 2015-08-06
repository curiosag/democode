CREATE OR REPLACE PACKAGE BODY load_instruments#
AS
   g_count_loaded                         PLS_INTEGER                    := 0;
   c_max_count_cache_reinit      CONSTANT PLS_INTEGER                := 10000;

   g_common_price_properties              t_common_price_properties;
   g_issuer_price_properties              t_issuer_price_properties;

   max_common_cd                 CONSTANT NUMBER                          := 9;
   max_isin_cd                   CONSTANT NUMBER                         := 12;

...

   max_issue_prc_date            CONSTANT NUMBER                         := 40;
   max_settl_curry_iso           CONSTANT NUMBER                          := 3;
   max_init_amnt                 CONSTANT NUMBER                          := 0;
   max_outs_amnt                 CONSTANT NUMBER                          := 0;

   c_assetgrp_insert_type_cd     CONSTANT mdm_asset_grp.ins_type_code%TYPE
                                                                        := 'A';
   c_non_existing                CONSTANT PLS_INTEGER                    := -1;
   c_len_common_cd               CONSTANT NUMBER                          := 9;

...

   c_num_bool_false              CONSTANT NUMBER                          := 0;
   c_prsgroup_importratings      CONSTANT VARCHAR2 (100)
                                                := 'ProcessInstrument_Ratings';
   g_key_id_testasset                     NUMBER                       := NULL;

   /*  caching */
   
   g_market_price_class_id                object#.t_id = ...;

   g_tech_mkt_id                          types#.t_id = ...;
....

   
   TYPE t_dep_cd_ids IS TABLE OF v_il_depository_country.key_id%TYPE
      INDEX BY VARCHAR2 (30000);

   g_dep_cd_ids                           t_dep_cd_ids;

   TYPE t_curry_ids IS TABLE OF mdm_curry.key_id%TYPE
      INDEX BY VARCHAR2 (30000);

   g_curry_ids                            t_curry_ids;
   g_depository_types                     load_common#.t_class_dataset;
   g_asset_stati                          load_common#.t_class_dataset;
   g_asset_categories                     load_common#.t_class_dataset;

   
   FUNCTION get_dep_cd_id (i_dep_cd IN v_il_depository_country.dep_cd%TYPE)
      RETURN v_il_depository_country.key_id%TYPE
   IS
      l_result   v_il_depository_country.key_id%TYPE   := NULL;
   BEGIN
      IF g_dep_cd_ids.EXISTS (UPPER (i_dep_cd))
      THEN
         l_result := g_dep_cd_ids (UPPER (i_dep_cd));
      END IF;

      RETURN l_result;
   END;

   PROCEDURE init_dep_cd_cache
   IS
   BEGIN
      g_dep_cd_ids.DELETE;

      FOR l_rec IN (SELECT key_id, dep_cd
                      FROM v_il_depository_country)
      LOOP
         IF g_dep_cd_ids.EXISTS (l_rec.dep_cd)
         THEN
            load_common#.cache_init_error ('dep_cd', l_rec.dep_cd);
         END IF;

         g_dep_cd_ids (UPPER (l_rec.dep_cd)) := l_rec.key_id;
      END LOOP;
   END;


   PROCEDURE init_caches
   IS
   BEGIN
      init_dep_cd_cache;
      init_class_depository_types;
      init_class_asset_stati;
      init_class_asset_categories;
   END;


   FUNCTION get_check_holding_value (
      i_raw         IN              VARCHAR2,
      i_asset       IN OUT NOCOPY   t_asset,
      i_errorinfo   IN OUT NOCOPY   VARCHAR2
   )
      RETURN BOOLEAN
   IS
      l_result   BOOLEAN     := FALSE;
      l_raw      VARCHAR (1) := SUBSTR (i_raw, 1, 1);
   BEGIN
      l_result := l_raw IN ('Y', 'N', 'P');

      IF l_result
      THEN
         CASE TRUE
            WHEN l_raw = 'Y'
            THEN
               i_asset.rdf_holding_flg := c_num_bool_true;
            WHEN l_raw IN ('N', 'P')
            THEN
               i_asset.rdf_holding_flg := c_num_bool_false;
            ELSE
               NULL;
         END CASE;
      ELSE
         add_line (i_errorinfo,
                   'Invalid value for RDF_HOLDING_FLG flag received: '
                   || i_raw
                  );
      END IF;

      RETURN l_result;
   END;

   PROCEDURE upd_asset_ref_holdg_flag (
      i_asset_id           IN   PLS_INTEGER,
      i_ref_holding_flag   IN   NUMBER,
      io_change            IN   h#.t_change_indicator,
      i_logid              IN   log#.t_log_pkg
   )
   IS
   BEGIN
      load_common#.upd_cf_val_number (c_iid_holdingid,
                                          i_asset_id,
                                          i_ref_holding_flag,
                                          io_change,
                                          i_logid
                                         );
   EXCEPTION
      WHEN OTHERS
      THEN
         log#.err (i_logid,
                      'Unexpected Error while updating asset cf_val to: '
                   || i_ref_holding_flag
                  );
         RAISE;
   END;

   PROCEDURE upd_asset_status (
      i_asset_id   IN              PLS_INTEGER,
      i_status     IN              VARCHAR,
      io_changes   IN OUT NOCOPY   t_change
   )
   IS
      l_stat_data   load_common#.t_class_data;
      l_dummy       h#.t_change_indicator;
   BEGIN
      usr_checks#.check_not_null (i_asset_id, 'i_asset_id is null');
      usr_checks#.check_not_null (i_status, 'i_status is null');
      l_stat_data :=
         load_common#.get_class_data (g_asset_stati,
                                          i_status,
                                          'asset_status'
                                         );
      io_changes.fin_sec_status :=
         load_common#.upd_obj_class (i_asset_id,
                                         i_status,
                                         'instr_state',
                                         l_stat_data.class_id,
                                         l_stat_data.classif_id,
                                         c_logid
                                        );
   END;


   FUNCTION get_risk_domi_id (i_dep_cd IN VARCHAR)
      RETURN PLS_INTEGER
   IS
      l_result   PLS_INTEGER;
   BEGIN
      RETURN get_dep_cd_id (i_dep_cd);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
      WHEN OTHERS
      THEN
         log#.err
               (c_logid,
                   'Unexpected Error while retrieving country id for DEP_CD '
                || i_dep_cd
               );
         RAISE;
   END;

   PROCEDURE util_check_val_asset (i_asset_id types#.t_id, i_ref IN t_asset)
   IS
      l_denom_curry_id   PLS_INTEGER;
      l_issue_curry_id   PLS_INTEGER;
      l_curr             mdm_asset%ROWTYPE;
   BEGIN
      l_denom_curry_id := get_curry_id (i_ref.settl_curry_iso);
      l_issue_curry_id := get_curry_id (i_ref.init_amnt_curr);

      SELECT *
        INTO l_curr
        FROM mdm_asset
       WHERE key_id = i_asset_id;

      util_check_eq ('SETTL_CURRY_ISO',
                     l_curr.denom_curry_id,
                     l_denom_curry_id,
                     i_ref.settl_curry_iso
                    );
      util_check_eq ('INIT_AMNT_CURR',
                     l_curr.issue_curry_id,
                     l_issue_curry_id,
                     i_ref.init_amnt_curr
                    );
      util_check_eq ('INIT_AMNT', l_curr.issued_amount, i_ref.init_amnt, '');
      util_check_eq ('ISSUE_PRC_VAL',
                     l_curr.par_value,
                     i_ref.issue_prc_val,
                     ''
                    );
      util_check_eq ('OUTS_AMNT', l_curr.outsta_piece, i_ref.outs_amnt, '');
   END;

   PROCEDURE util_check_val_key (
      l_asset_id         types#.t_id,
      iid_keytype        VARCHAR,
      i_refval      IN   VARCHAR
   )
   IS
      l_keyval   VARCHAR (200);
   BEGIN
      l_keyval := mdm_key#.get_obj_key_val (l_asset_id);
      usr_checks#.check_equals (l_keyval,
                                i_refval,
                                   iid_keytype
                                || ' key values differ. expected:'
                                || i_refval
                                || ' actual:'
                                || l_keyval
                               );
   END;

   PROCEDURE test_fail_num_key
   IS
      l_asset     t_asset;
      l_key_id    PLS_INTEGER;
      l_parts     t_test_num_part;
      l_changes   t_change;
   BEGIN
      test_prepare;
      l_asset := get_init_testasset;
      util_test_set_full_asset (l_asset, l_parts);
      l_key_id := create_testasset (l_asset, l_changes);
      l_parts.num_isin_cd := 0;
      util_check_asset (l_asset, l_parts);
      util_del_testasset (g_key_id_testasset);
      RAISE errpkg#.e_check_failed;
   EXCEPTION
      WHEN errpkg#.e_check_failed
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         util_del_testasset (g_key_id_testasset);
   END;

   PROCEDURE test_fail_num_cf
   IS
      l_asset     t_asset;
      l_key_id    PLS_INTEGER;
      l_parts     t_test_num_part;
      l_changes   t_change;
   BEGIN
      test_prepare;
      l_asset := get_init_testasset;
      util_test_set_full_asset (l_asset, l_parts);
      l_key_id := create_testasset (l_asset, l_changes);
      l_parts.num_cfval := 0;
      util_check_asset (l_asset, l_parts);
      util_del_testasset (g_key_id_testasset);
      RAISE errpkg#.e_check_failed;
   EXCEPTION
      WHEN errpkg#.e_check_failed
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         util_del_testasset (g_key_id_testasset);
   END;

BEGIN
   init_common_price_properties;
   init_issuer_price_properties;
   init_caches;
END load_instruments#;
