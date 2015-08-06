create or replace
PACKAGE BODY load_company_xml#
AS
      c_date_fmt                 constant VARCHAR2(20) := 'YYYY-MM-DD HH24:MI';
      c_xp_envelope              constant VARCHAR2(20) := '/pub:PublEnvlp';
      c_xp_inst_action           constant VARCHAR2(250) := c_xp_envelope || '/base:Inst/base:Key/base:ActTyp/text()';
      c_xp_inst_oid              constant VARCHAR2(250) := c_xp_envelope || '/base:Inst/base:Key/base:TechKey/base:InstOId/text()';   
      c_xp_inst_short_name       constant VARCHAR2(250) := c_xp_envelope || '/base:Inst/base:InstShtNmBlk/base:InstShtNm/text()';

 ...	

      c_role_cd_issuer            constant VARCHAR(6) := 'ISSUER';      
      c_xp_issuer_rl_end_date     constant VARCHAR2(250) := c_xp_envelope || '/base:Inst/base:InstRoleStrc.List/base:InstRoleStrc[base:InstRoleBlk/base:InstRole/base:InstRoleTypShtCd/text()="' || c_role_cd_issuer || '"]/base:EndDtBlk/base:EndDt/text()';      
   
      c_xp_nmmap_base            constant VARCHAR2(250) := c_xp_envelope || '/base:Inst/base:InstNmMap.List/base:InstNmMap';      
    
...

      c_xp_nmmap_Issuer_Name     constant VARCHAR2(250) := '/base:InstNmMap/base:LocNmBlk/base:LocNm/text()';
      c_required constant boolean := TRUE;
      
      subtype t_change_code IS VARCHAR2(10);
      type t_actions IS TABLE OF h#.t_change_indicator INDEX BY t_change_code;
      
      g_actions t_actions;

      procedure init_actions
      is 
      BEGIN         
         g_actions('SELECT') := h#.c_ind_no_change;
         g_actions('INSERT') := h#.c_ind_no_change;
         g_actions('UPDATE') := h#.c_ind_no_change;
         g_actions('DELETE') := h#.c_ind_delete; 
      end;

------------------------------------------------------------------------------
-- N,PS T23195:

      FUNCTION get_action(
            i_act IN t_change_code)
         RETURN h#.t_change_indicator
      IS
      BEGIN
         IF i_act IS NULL THEN
            RETURN h#.c_ind_no_change;
         ELSE
            RETURN g_actions(i_act) ;
         END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN h#.c_ind_no_change;
      WHEN OTHERS THEN
         raise;
      END;

------------------------------------------------------------------------------
-- N,PS T23195:

      PROCEDURE get_links (io_xml IN out nocopy XMLTYPE,
                           i_institution_short_cd in varchar2,
                           io_lnk_data IN out nocopy  load_company#.t_company_issuer_link_raw, 
                           io_lnk_change IN out nocopy  load_company#.t_company_issuer_link_change)
      IS            
         l_prov_sht_cd VARCHAR2(250);
         l_Issuer_Id   VARCHAR2(250);
         l_Issuer_Name VARCHAR2(250);
         l_action      h#.t_change_indicator;
      BEGIN      
          io_lnk_data.institution_short_cd := i_institution_short_cd;         
          FOR l_rec IN (SELECT x.COLUMN_VALUE x
                        FROM TABLE(XMLSEQUENCE(EXTRACT(io_xml, c_xp_nmmap_base, c_xmlns))) x)
          LOOP
            l_prov_sht_cd := xml_util#.get_string(l_rec.x, c_xp_nmmap_prov_sht_cd, NULL, c_required, c_xmlns);
            l_Issuer_Id := xml_util#.get_string(l_rec.x, c_xp_nmmap_issuer_id, NULL, c_required, c_xmlns);
            l_Issuer_Name := xml_util#.get_string(l_rec.x, c_xp_nmmap_Issuer_Name, NULL, NOT c_required, c_xmlns);
            l_action :=  get_action(xml_util#.get_string(l_rec.x, c_xp_nmmap_action, NULL, NOT c_required, c_xmlns));
            CASE
            WHEN l_prov_sht_cd = load_company#.c_shtcd_moody THEN
               io_lnk_data.Moody_Issuer_Id  := l_Issuer_Id;    
               io_lnk_data.Moody_Issuer_Name  := l_Issuer_Name; 
               io_lnk_change.moody_issuer_id := l_action;
               io_lnk_change.moody_issuer_name := l_action;
            WHEN l_prov_sht_cd = load_company#.c_shtcd_fitch THEN   
               io_lnk_data.fitch_issuer_id  := l_Issuer_Id;
               io_lnk_data.fitch_Issuer_Name  := l_Issuer_Name;  
               io_lnk_change.fitch_issuer_id := l_action;
               io_lnk_change.fitch_issuer_name := l_action;
            WHEN l_prov_sht_cd = load_company#.c_shtcd_sandp THEN   
               io_lnk_data.Sandp_Issuer_Id   := l_Issuer_Id;   
               io_lnk_data.Sandp_Issuer_Name  := l_Issuer_Name;
               io_lnk_change.sandp_issuer_id  := l_action;
               io_lnk_change.sandp_issuer_name  := l_action;
            ELSE
               load_common#.add_convert_exception_msg('invalid provider received. issuer:'|| io_lnk_data.institution_short_cd ||' provider:' || l_prov_sht_cd);
            END CASE ;
          END LOOP;
      END;

------------------------------------------------------------------------------
-- N,PS T23195:

      PROCEDURE get_cp (io_xml IN out nocopy XMLTYPE,
                        io_cp_data IN out nocopy  load_company#.t_company_raw, 
                        io_cp_change IN out nocopy  load_company#.t_company_change)
      IS            
      BEGIN      
          io_cp_data.omi_cp_id               := xml_util#.get_string(io_xml, c_xp_inst_oid, null, c_required, c_xmlns);
          io_cp_data.institution_short_cd    := xml_util#.get_string(io_xml, c_xp_inst_short_cd, null, c_required, c_xmlns);
  
...

          io_cp_data.End_Date                := xml_util#.get_date(io_xml, c_xp_inst_end_date, NULL, NOT c_required, c_xmlns, c_date_fmt);
          io_cp_data.role_End_Date           := xml_util#.get_date(io_xml, c_xp_issuer_rl_end_date, NULL, NOT c_required, c_xmlns, c_date_fmt);            
          io_cp_change.institution_short_cd  := get_action(xml_util#.get_string(io_xml, c_xp_inst_action, NULL, not c_required, c_xmlns));          
      END;

------------------------------------------------------------------------------
-- N,PS T23195:

      PROCEDURE get_raw (io_xml IN out nocopy XMLTYPE,
                      io_cp_data IN out nocopy  load_company#.t_company_raw, 
                      io_cp_change IN out nocopy  load_company#.t_company_change,
                      io_lnk_data IN out nocopy  load_company#.t_company_issuer_link_raw, 
                      io_lnk_change IN out nocopy  load_company#.t_company_issuer_link_change)
      IS                       
      BEGIN      
         IF io_xml IS NULL THEN
            errpkg#.raise_check_failed('io_xml is null');
         END IF;
         
         get_cp(io_xml, io_cp_data, io_cp_change);         
         get_links(io_xml, io_cp_data.institution_short_cd, io_lnk_data, io_lnk_change);         
      END;
BEGIN
   init_actions;
END;
