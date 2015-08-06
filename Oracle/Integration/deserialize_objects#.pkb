create or replace
PACKAGE BODY     deserialize_objects#
AS

  subtype t_serialized_record IS deserialize_object%rowtype;
  type t_serialized_table is table of t_serialized_record;

  type t_gltypes is table of GL.GLTYPE%type index by PLS_INTEGER;

  type t_key_gl_array_tuple is record
  (
   key_id PLS_INTEGER,
   gl_array T_gl_ARRAY
  );

  TYPE t_key_gl_array_tuples IS REF CURSOR;

  type t_key_t_value_tuple is record
  (
   key_id PLS_INTEGER,
   gl_id  PLS_INTEGER,
   val  T_VALUE
  );

  TYPE t_key_t_value_tuples IS REF CURSOR;

  type t_deserialized is record
  (
   key_id PLS_INTEGER,
   gl_array T_gl_ARRAY,
   val      T_VALUE
  );

  type t_deserialized_table IS TABLE OF t_deserialized;
  
  g_deserial_cache t_deserialized_table := t_deserialized_table();

  g_number_cached PLS_INTEGER := 0;
  g_gltypes t_gltypes;

  c_max_cache constant integer := 300;
  g_tablename varchar2(30);  
  
   
  g_cfr_cache  t_serialized_table := t_serialized_table();
  
  procedure serialize_gl_arrays(i_tablename VARCHAR2, i_fieldname in  VARCHAR2, i_fieldtype in VARCHAR2);
  procedure serialize_t_values(i_tablename VARCHAR2, i_fieldname in  VARCHAR2, i_fieldtype in VARCHAR2, i_gl_fieldname in VARCHAR2);

procedure init_gl_types
is
begin
   for l_rec in (select key_id, UPPER(gl_objectTYPE) gl_objectTYPE from cf)
   loop
      g_gltypes(l_rec.key_id) := l_rec.gl_objectTYPE;
   end loop;
end;

procedure add_single_value(i_tablename in varchar2,
                      i_fieldname in varchar2,
                      i_fieldtype  in varchar2,
                      i_key_id in pls_integer,
                      i_collection_position in pls_integer,
                      i_gl pls_integer,
                      i_value T_VALUE,
                      i_dest_tab IN OUT NOCOPY t_serialized_table)
is
  l_pos pls_integer;
begin
   if g_number_cached = i_dest_tab.COUNT then
         i_dest_tab.EXTEND;
   end if;
   g_number_cached := g_number_cached + 1;

   l_pos := g_number_cached;
   i_dest_tab(l_pos).TABLE_NAME := i_tablename;
   i_dest_tab(l_pos).FIELD_NAME := i_fieldname;
   i_dest_tab(l_pos).FIELD_TYPE := i_fieldtype;
   i_dest_tab(l_pos).KEY_ID := i_key_id;
   i_dest_tab(l_pos).COLLECTION_POSITION := i_collection_position;
   i_dest_tab(l_pos).gl_ID := i_gl;

   CASE g_gltypes(i_gl)
      when gl_object#.c_glvaluetype_date then  i_dest_tab(l_pos).VALUE_DATE := i_value.valueasdate;
      when gl_object#.c_glvaluetype_number then i_dest_tab(l_pos).VALUE_NUMBER := i_value.valueasnumber;
      when gl_object#.c_glvaluetype_string then  i_dest_tab(l_pos).VALUE_STRING := i_value.valueasvarchar2;
   else
      errpkg#.raise_check_failed('invalid case, gl ' || i_gl || ' ' || g_gltypes(i_gl));
   end case;
end;

procedure serialize_gl_array(i_tablename in varchar2, i_fieldname in varchar2, i_fieldtype in VARCHAR2,
                             i_key_id in pls_integer, i_gl_array IN OUT NOCOPY t_gl_array,
                             i_dest_tab IN OUT NOCOPY t_serialized_table)
is
begin
   for i in reverse 1..i_gl_array.COUNT
   loop
      add_single_value(i_tablename, i_fieldname, i_fieldtype, i_key_id, i, i_gl_array(i).gl_id, i_gl_array(i).value, i_dest_tab);
   end loop;
end;

procedure write_cache(i_cache  IN OUT NOCOPY t_serialized_table)
is
begin
   forall l_idx IN 1 .. g_number_cached
      INSERT INTO deserialize_object
       values  i_cache(l_idx);
   g_number_cached := 0;
   commit;
end;

procedure serialize(i_tablename VARCHAR2, i_fieldname in  VARCHAR2, i_fieldtype in VARCHAR2, i_gl_fieldname in VARCHAR2 default null)
is 
begin   
   g_tablename := i_tablename;
   g_number_cached := 0;
   init_gl_types;
   g_cfr_cache .extend(c_max_cache);
      CASE
      WHEN i_fieldtype = 'T_gl_ARRAY' THEN
         serialize_gl_arrays(i_tablename, i_fieldname, i_fieldtype);
      WHEN i_fieldtype = 'T_VALUE' THEN
         serialize_t_values(i_tablename, i_fieldname, i_fieldtype, i_gl_fieldname);
      ELSE
        errpkg#.raise_check_failed('can not process field type ' || i_fieldtype);         
      END CASE ;
      
      write_cache(g_cfr_cache );
end;

procedure check_cache
is
begin
   if g_number_cached >= c_max_cache then
      write_cache(g_cfr_cache );
   end if;
end;

procedure serialize_gl_arrays(i_tablename VARCHAR2, i_fieldname in  VARCHAR2, i_fieldtype in VARCHAR2)
as
   l_rec t_key_gl_array_tuple;
   l_tuples t_key_gl_array_tuples;
begin
    open l_tuples for 'select key_id, ' || i_fieldname || ' val ' ||
                      ' from ' || i_tablename ||
                      ' where ' || i_fieldname || ' is not null';   
   loop
      fetch l_tuples into l_rec;
      exit when l_tuples%notfound;

      serialize_gl_array(g_tablename, i_fieldname, i_fieldtype, l_rec.key_id, l_rec.gl_array, g_cfr_cache);
      check_cache;
   end loop;  
end;

procedure serialize_t_values(i_tablename VARCHAR2, i_fieldname in  VARCHAR2, i_fieldtype in VARCHAR2, i_gl_fieldname in VARCHAR2)
as
   l_rec t_key_t_value_tuple;
   l_tuples t_key_t_value_tuples;
begin
    usr_checks#.check_not_null(i_gl_fieldname, 'i_gl_fieldname is null');
    
    open l_tuples for 'select key_id, ' || i_gl_fieldname || ', ' || i_fieldname ||
                      ' from ' || i_tablename ||
                      ' where ' || i_fieldname || ' is not null and rownum < 10';
   loop
      fetch l_tuples into l_rec;
      exit when l_tuples%notfound;

      add_single_value(i_tablename, i_fieldname, i_fieldtype, l_rec.key_id, 1, l_rec.gl_id, l_rec.val, g_cfr_cache);
      check_cache;
   end loop;  
end;

procedure write_deserial_cache(i_tablename in VARCHAR2,  i_fieldname in VARCHAR2, i_fieldtype varchar2, 
                               i_deserial_cache IN OUT NOCOPY t_deserialized_table)
is
begin
   CASE
      WHEN i_fieldtype = 'T_gl_ARRAY' THEN
          forall i in 1..g_number_cached
            EXECUTE IMMEDIATE
            'UPDATE ' || i_tablename || ' SET ' || i_fieldname || '=:1 WHERE KEY_ID=:2' using i_deserial_cache(i).gl_array, i_deserial_cache(i).key_id;
      WHEN i_fieldtype = 'T_VALUE' THEN
         forall i in 1..g_number_cached
            EXECUTE IMMEDIATE
            'UPDATE ' || i_tablename || ' SET ' || i_fieldname || '=:1 WHERE KEY_ID=:2' using i_deserial_cache(i).val, i_deserial_cache(i).key_id;      
   END CASE ;
  
   commit;
   g_number_cached := 0;
end;

procedure add_deserial_cache(i_tablename in VARCHAR2, i_fieldname in VARCHAR2, i_fieldtype varchar2, 
                             i_key_id IN pls_integer, i_gl_array IN OUT NOCOPY T_gl_ARRAY, i_value IN OUT NOCOPY T_VALUE)
is
begin
   g_number_cached := g_number_cached + 1;
   g_deserial_cache(g_number_cached).key_id := i_key_id;
   g_deserial_cache(g_number_cached).gl_array := i_gl_array;
   g_deserial_cache(g_number_cached).val := i_value;

   if g_number_cached = c_max_cache then
      write_deserial_cache(i_tablename, i_fieldname, i_fieldtype, g_deserial_cache);
   end if;
end;

function deserialize_t_value( io_gl_ID IN OUT NOCOPY PLS_INTEGER,
                              io_VALUE_NUMBER IN OUT NOCOPY NUMBER,
                              io_VALUE_DATE date,
                              io_VALUE_STRING  IN OUT NOCOPY VARCHAR2)
return t_value                          
is   
   l_val T_VALUE;
begin
   CASE g_gltypes(io_gl_ID)
      when gl_object#.c_glvaluetype_date then l_val := T_VALUE_DATE(io_VALUE_DATE);
      when gl_object#.c_glvaluetype_number then l_val := T_VALUE_NUMBER(io_VALUE_NUMBER);
      when gl_object#.c_glvaluetype_string then l_val := T_VALUE_STRING(io_VALUE_STRING);
   else
      errpkg#.raise_check_failed('invalid case, gl ' || io_gl_ID || ' ' || g_gltypes(io_gl_ID));
   end case;
   return l_val;
end;

procedure deserialize_cf(io_curr_array IN OUT NOCOPY T_gl_ARRAY,
                          i_curr_item_pos  IN OUT NOCOPY PLS_INTEGER,
                          io_gl_ID IN OUT NOCOPY PLS_INTEGER,
                          io_VALUE_NUMBER IN OUT NOCOPY NUMBER,
                          io_VALUE_DATE date,
                          io_VALUE_STRING  IN OUT NOCOPY VARCHAR2)
is
begin
   io_curr_array(i_curr_item_pos) := T_CF(io_gl_ID, deserialize_t_value(io_gl_ID, io_VALUE_NUMBER, io_VALUE_DATE, io_VALUE_STRING));
end;

procedure deserialize_gl_arrays(i_tablename VARCHAR2, i_fieldname in  VARCHAR2, i_fieldtype in VARCHAR2)
as  
   l_curr_item_pos integer := 0;
   l_curr_array T_gl_ARRAY;
   c_null_value t_value := null;  
begin
      for l_rec in (SELECT oe.KEY_ID, oeg.ITEM_COUNT, oe.gl_ID, oe.VALUE_NUMBER, oe.VALUE_DATE, oe.VALUE_STRING
                    FROM deserialize_object oe join
                    (
                      SELECT KEY_ID, COUNT(KEY_ID) ITEM_COUNT
                      FROM deserialize_object
                      where TABLE_NAME =i_tablename
                      and FIELD_NAME =i_fieldname
                      and FIELD_TYPE = i_fieldtype
                      group by KEY_ID
                    ) oeg on oe.key_id = oeg.key_id
                    where TABLE_NAME =i_tablename
                    and FIELD_NAME =i_fieldname
                    and FIELD_TYPE = i_fieldtype                    
                    group by oe.KEY_ID, oe.COLLECTION_POSITION, oe.gl_ID, oe.VALUE_NUMBER, oe.VALUE_DATE, oe.VALUE_STRING, oeg.ITEM_COUNT
                    order by oe.KEY_ID, oe.COLLECTION_POSITION)
   loop
      if l_curr_item_pos = 0 then
         l_curr_array := T_gl_ARRAY();
         l_curr_array.extend(l_rec.ITEM_COUNT);
      end if;
      l_curr_item_pos := l_curr_item_pos + 1;
      deserialize_cf(l_curr_array, l_curr_item_pos, l_rec.gl_ID, l_rec.VALUE_NUMBER, l_rec.VALUE_DATE, l_rec.VALUE_STRING);
      if l_curr_item_pos = l_rec.ITEM_COUNT then
          add_deserial_cache(i_tablename, i_fieldname, i_fieldtype, l_rec.key_id, l_curr_array, c_null_value);
          l_curr_item_pos := 0;
      end if;      
   end loop;   
end;

procedure deserialize_t_values(i_tablename VARCHAR2, i_fieldname in  VARCHAR2, i_fieldtype in VARCHAR2)
is
  c_null_value t_gl_array := null;
  l_val t_value;
begin
   for l_rec in (SELECT oe.KEY_ID, oe.gl_ID, oe.VALUE_NUMBER, oe.VALUE_DATE, oe.VALUE_STRING
                 FROM deserialize_object oe
                 where TABLE_NAME =i_tablename
                 and FIELD_NAME =i_fieldname
                 and FIELD_TYPE = i_fieldtype)
   loop    
       l_val := deserialize_t_value(l_rec.gl_ID, l_rec.VALUE_NUMBER, l_rec.VALUE_DATE, l_rec.VALUE_STRING);
       add_deserial_cache(i_tablename, i_fieldname, i_fieldtype, l_rec.key_id, c_null_value, l_val);      
   end loop;   
end;

procedure deserialize(i_tablename VARCHAR2, i_fieldname in  VARCHAR2, i_fieldtype in VARCHAR2)
as   
begin   
   init_gl_types;  
   g_number_cached := 0;
   g_deserial_cache.extend(c_max_cache);      
   
      CASE
      WHEN i_fieldtype = 'T_GL_ARRAY' THEN
          deserialize_gl_arrays(i_tablename, i_fieldname, i_fieldtype);
      WHEN i_fieldtype = 'T_VALUE' THEN
          deserialize_t_values(i_tablename, i_fieldname, i_fieldtype);
      ELSE
        errpkg#.raise_check_failed('can not process field type ' || i_fieldtype);         
   END CASE ;
   
   write_deserial_cache(i_tablename, i_fieldname, i_fieldtype, g_deserial_cache);
   commit;
end;


END deserialize_objects#;
