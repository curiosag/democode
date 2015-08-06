CREATE OR REPLACE PACKAGE BODY load_instruments_xml#
AS    
   
------------------------------------------------------------------------------
--N,PS T13152: 
   
   FUNCTION msg_extract_asset_2(i_xmldata IN OUT NOCOPY XMLTYPE) RETURN T_asset_CUST_KEYS_raw   
   IS
     -- there is a 4K limit for the XQuery expression in 10g (also in 10.0.4, as opposed
     -- to some posts in the web) so the query had to be split
     l_result T_asset_CUST_KEYS_raw;          
   BEGIN
    for l_data in (
        select KEY, VAL                     
        from XMLTABLE(xmlnamespaces(DEFAULT 'publication.schema.omi'),
                         'declare namespace base="base.schema.omi";  
                                  
                          for $i in /PublEnvlp/base:/base:Ref.List/base:Ref
                          return                      
                          <REC>                      
                            <KEY>                                                                            
                               {$i/base:RefTyp/base:RefTyp/base:RefTypShtCd/text()}                
                            </KEY>
                                
                            <VAL>                                                
                                {$i/base:RefVal/base:RefVal/text()}
                            </VAL>  
                                                        
                          </REC>'
                                                 
                         PASSING i_xmldata
                         COLUMNS KEY               VARCHAR(20)  PATH '/REC/KEY',
                                 VAL               VARCHAR(10)  PATH '/REC/VAL') XMLRESULT)
    LOOP
        CASE TRUE            
            WHEN UPPER(l_data.KEY) = 'CUSIP' THEN
                l_result.CUSIP_CD := l_data.VAL;
                
            WHEN UPPER(l_data.KEY) = 'WKN' THEN
                l_result.WKN_CD := l_data.VAL;
                
            WHEN UPPER(l_data.KEY) = 'NL' THEN
                l_result.NL_CD := l_data.VAL;
                
            WHEN UPPER(l_data.KEY) = 'CH' THEN
                l_result.CH_CD := l_data.VAL;
                
            WHEN UPPER(l_data.KEY) = 'DOM' THEN                
                l_result.DOM_CD := l_data.VAL;
            ELSE
                NULL;                        
        END CASE;
    END LOOP;                                     
    
      RETURN l_result;                                                    
   END;

------------------------------------------------------------------------------
-- N,PS T13152: 
   
   FUNCTION msg_extract_asset_1(i_xmldata IN OUT NOCOPY XMLTYPE) RETURN T_asset_raw
   IS
     l_result T_asset_raw;     
   BEGIN
    select OID,  
           ISIN_CD,            
           NULL AS CUSIP_CD,
           NULL AS WKN_CD,
           NULL AS NL_CD,
           NULL AS CH_CD,
           NULL AS DOM_CD,
           LONG_NM,
           ISSUE_PRC_VAL,  
           ...  
    into l_result
    from XMLTABLE(xmlnamespaces(DEFAULT 'publication.schema.omi'), 
                     'declare namespace core="base.schema.omi";  
                      let $Base     := /PublEnvlp/base:
                      let $Denom    := $Base/base:Denom.List/base:Denom/base:Key/base:FuncKey/base:Nom/text()                                                                  
                      return
                      <REC>    
                        <Oid>     {$Base/base:Key/base:TechKey/base:OId/text()}                                     </Oid>                    
                        <Isin>          {$Base/base:IsinCd/base:IsinCd/text()}                                               </Isin>
                        <LongName>   {$Base/base:Detl/base:LongNm/base:LongNm/text()}                         </LongName>
                        <PrcVal>        {$Base/base:ClsgInfo/base:IssPrcVal/base:IssPrcVal/text()}         </PrcVal>
            ...
                      </REC>'                    
                     PASSING i_xmldata
                     COLUMNS OID        VARCHAR2(4000)  PATH '/REC/Oid',
                             ISIN_CD            VARCHAR2(4000)  PATH '/REC/Isin',                             
                             LONG_NM    VARCHAR2(4000)  PATH '/REC/LongName',
                             ISSUE_PRC_VAL      VARCHAR2(4000)  PATH '/REC/PrcVal',
            ...                               
               ) XMLRESULT;
      RETURN l_result;                                     
   END;
*/  


END;
/
