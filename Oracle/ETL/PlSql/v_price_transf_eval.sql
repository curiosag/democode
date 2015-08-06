CREATE OR REPLACE VIEW v_transformed_price
AS
   SELECT line_number, common_code, isin, 
          (CASE
              WHEN price_type_marker = '1' THEN '3'
              WHEN price_type_marker IN('3', '4', '9', 'R', '0', '2', 'I', 'D', 'M', 'C') THEN price_type_marker
              ELSE NULL
           END) AS price_a_type,
          price_a_amount AS r_price_a,
          (CASE
              WHEN(cua.fmtp IS NULL)
               OR(NOT REGEXP_LIKE(price_a_amount, '\d{8}'))
               OR((cua.fmtp = 'F') AND(SUBSTR(price_a_amount, 7, 2) = '00')) THEN NULL
              WHEN cua.fmtp = 'F' THEN TO_NUMBER(SUBSTR(price_a_amount, 1, 4))
                                       + TO_NUMBER(SUBSTR(price_a_amount, 5, 2))
                                         / TO_NUMBER(SUBSTR(price_a_amount, 7, 2))
              ELSE TO_NUMBER(SUBSTR(price_a_amount, 1, cua.fmts) || '.' || SUBSTR(price_a_amount, cua.fmts + 1),
                             '99999999.99999999',
                             'NLS_NUMERIC_CHARACTERS = ''.,''')
           END) AS price_a,
  ...         
           
          amend_date AS r_price_value_date,
          (CASE
              WHEN NOT REGEXP_LIKE(amend_date, '\d{3}')
               OR TO_NUMBER(amend_date) < 1
               OR TO_NUMBER(amend_date) > refd.max_refday THEN NULL
              WHEN TO_NUMBER(amend_date, '999') <= refd.curr THEN refd.base_dt_curr +(TO_NUMBER(amend_date, '999') - 1)
              ELSE refd.base_dt_prev +(TO_NUMBER(amend_date, '999') - 1)
           END) AS price_value_date,
          quot_basis_marker, qb.multiplier AS quot_basis_multiplier,
    
    ...
    
     FROM et_raw_price rp CROSS JOIN v_fcrefday refd
          LEFT OUTER JOIN v_valid_country_exch ce
          ON rp.country_code = ce.country_code AND rp.exch_letter = ce.exch_letter
          LEFT OUTER JOIN v_quot_base qb ON rp.quot_basis_marker = qb.key_code
          LEFT OUTER JOIN v_currency cua ON rp.price_a_currency_code = cua.num_code
          LEFT OUTER JOIN v_currency cub ON rp.price_b_currency_code = cub.num_code
          LEFT OUTER JOIN v_currency cud ON rp.denomination_currency = cud.num_code
          ;