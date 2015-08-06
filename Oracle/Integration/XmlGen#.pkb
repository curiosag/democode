CREATE OR REPLACE PACKAGE BODY x_interface#
AS

   g_xid_asset  xy.key_id%TYPE;
   g_xid_company xy.key_id%type;
   
    PROCEDURE Init
   IS
   BEGIN
      g_xid_asset := ...
      g_xid_company :=  ...
   END;

   PROCEDURE send_message(i_xml IN XMLTYPE, i_asset_id IN object#.t_id, i_serv_nm IN VARCHAR2, i_msg_type IN VARCHAR2)
   IS
      c_header_template   VARCHAR(32767)
         := '<HEADER>
                      <SERV_NM>%s</SERV_NM>
                      <MSG_ORIG>PLING</MSG_ORIG>
                      <REQ_PRIO>%d</REQ_PRIO>
                      <OID>%s</OID>
                      <MSG_TYPE>%s</MSG_TYPE>
                      <COMMON_CD>%s</COMMON_CD>
                      <ISIN_CD>%s</ISIN_CD>
                      <VERS_TMSTMP>%s</VERS_TMSTMP>
                 </HEADER>';
      l_header            VARCHAR2(32767);
   BEGIN
      l_header    :=
         UTL_LMS.format_message(c_header_template,
                                i_serv_nm,
                                100,
                                key#.get_single_key_val(i_asset_id, 'id'),
                                i_msg_type,
                                key#.get_single_key_val(i_asset_id, 'common_code'),
                                key#.get_single_key_val(i_asset_id, 'asset_isin'),
                                xml_util#.tochar(SYSDATE));
      workload_util#.add_msg_outputqueue(t_msg(NULL,
                                                    msg#.c_msgtype_custom,
                                                    'PLING',
                                                    NULL,
                                                    '',
                                                    XMLTYPE(l_header),
                                                    i_xml,
                                                    LOCALTIMESTAMP));
   END;

------------------------------------------------------------------------------
-- N,PS T13580: factorized

   FUNCTION price_gen_update_xml(i_msg t_msg)
      RETURN VARCHAR2
   IS
      l_xml                VARCHAR2(32767) := NULL;
      l_asset_id           object#.t_id;
 ...
      l_quality_class_id   object#.t_id;
      l_unit_class_id      object#.t_id;

      PROCEDURE n_add(io_xml IN OUT NOCOPY VARCHAR2, i_elem IN VARCHAR2, i_value IN DATE)
      IS
      BEGIN
         io_xml    := io_xml || xml_util#.get_tag(i_elem, xml_util#.tochar(i_value));
      END;

      PROCEDURE n_add(io_xml IN OUT NOCOPY VARCHAR2, i_elem IN VARCHAR2, i_value IN NUMBER)
      IS
      BEGIN
         io_xml    :=
            io_xml
            || xml_util#.get_tag(i_elem,
                                 TO_CHAR(ROUND(i_value, 11),
                                         'FM999999999999990.09999999999',
                                         'NLS_NUMERIC_CHARACTERS = ''.,'''));
      END;

      PROCEDURE n_add(io_xml IN OUT NOCOPY VARCHAR2, i_elem IN VARCHAR2, i_value IN VARCHAR2)
      IS
      BEGIN
         io_xml    := io_xml || xml_util#.get_tag(i_elem, i_value);
      END;

      PROCEDURE n_add(io_xml IN OUT NOCOPY VARCHAR2, i_elem IN VARCHAR2, i_open IN BOOLEAN)
      IS
      BEGIN
         IF i_open THEN
            io_xml    := io_xml || xml_util#.get_tag_opn(i_elem);
         ELSE
            io_xml    := io_xml || xml_util#.get_tag_cls(i_elem);
         END IF;
      END;

      FUNCTION n_get_market(i_mkt_id IN object#.t_id)
         RETURN VARCHAR2
      AS
         l_res   mkt#.t_name;
      BEGIN
         l_res    := mkt#.get_mkt_name(i_mkt_id);

         IF l_res IS NOT NULL THEN
            RETURN l_res;
         ELSE
            RETURN 'Market name empty';
         END IF;
      END;
   BEGIN
      l_asset_id            := msg_util#.get_notvalue_asnumber(i_msg, 'ASSET_ID');
      l_curry_id            := msg_util#.get_notvalue_asnumber(i_msg, 'PRICE_CURRY_ID');
  
 ...
  
      l_unit_class_id       := msg_util#.get_notvalue_asnumber(i_msg, 'QUOT_VAL_UNIT_CLASS_ID');

         l_xml    := xml_util#.get_tag_opn('MrktPrc');
         n_add(l_xml, 'KeyVal', TRUE);
         n_add(l_xml, 'Oid', key#.get_single_key_val(l_asset_id, 'id'));
         n_add(l_xml, 'KeyVal', FALSE);
         n_add(l_xml, 'MrktPrcVal', msg_util#.get_notvalue_asnumber(i_msg, 'QUOT_VAL'));
 
... 
 
         n_add(l_xml, 'MrktPrcProvidString', price_map_providid(l_provid_id));
         n_add(l_xml, 'VersTmstmp', xml_util#.tochar(i_msg.msg_timestamp));
         n_add(l_xml, 'MrktPrc', FALSE);
  
      RETURN l_xml;
   END;

   PROCEDURE price_process_msg(i_msg IN t_msg)
   IS
      l_xml   VARCHAR2(32767);
   BEGIN
      l_xml    := price_gen_update_xml(i_msg);

      IF l_xml IS NOT NULL THEN
         l_xml    := '<?xml version="1.0" encoding="' || xml_util#.get_encoding || '"?>' || l_xml;
         send_message(XMLTYPE(l_xml),
                      msg_util#.get_notvalue_asnumber(i_msg, 'Q_ID'),
                      'PRC_FEED',
                      'MRKT_PRC_CPY');
      END IF;
   END;

   
   PROCEDURE cprtg_send_message_direct(
      i_xml          IN   VARCHAR2,
      i_keyid        IN   cp.key_id%type,
      i_serv_nm      IN   VARCHAR2,
      i_msg_type     IN   VARCHAR2,
      i_queue_name   IN   VARCHAR2)
   IS
      message_payload      SYS.aq$_jms_bytes_message;
      message_properties   DBMS_AQ.message_properties_t;
      enqueue_options      DBMS_AQ.enqueue_options_t;
      message_id           RAW(16);
   BEGIN
      message_payload := get_msg_payload(i_xml, i_serv_nm, i_msg_type);
      message_payload.set_string_property('I_NSE_CD', key#.get_single_key_val(i_keyid, x_load_company#.c_i_short_cd));
      ...
      
      DBMS_AQ.enqueue(queue_name              => i_queue_name,                                  
                      message_properties      => message_properties,
                      enqueue_options         => enqueue_options,
                      payload                 => message_payload,
                      msgid                   => message_id);
   END;
     
BEGIN
   Init;
END;
/
