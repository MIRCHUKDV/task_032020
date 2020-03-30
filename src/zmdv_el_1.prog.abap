*&---------------------------------------------------------------------*
*& Report ZMDV_EL_1
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
report zmdv_el_1.

*data iv_tabname type string value 'T007S'.
*
*data(lo_descr) = cast cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( iv_tabname ) ).
*data(lt_comp) = lo_descr->get_components( ).
*data(lt_comp2) = lo_descr->components.
*data(lt_fl) = lo_descr->get_ddic_field_list( ).
*loop at lo_descr->get_ddic_field_list( ) assigning field-symbol(<ls>) where leng >= 10 and inttype = 'C' and keyflag is initial. "= abap_true.
*  "берем первую подходящую запись
*  "<ls>-fieldname.
*  exit.
*endloop.
*
*exit.

data:
  lv_fixed  type zemdv_el_fixed,
  lv_ranged type zemdv_el_ranged,
  lv_tabled type zemdv_el_table.

lv_tabled = lv_ranged = lv_fixed = 'A'.
lv_ranged = 'BB'.

write: / |Fixed: { zcl_mdv_el_descr=>get_val_descr( lv_fixed ) }|.
write: / |Ranged: { zcl_mdv_el_descr=>get_val_descr( lv_ranged ) }|.
write: / |Tabled: { zcl_mdv_el_descr=>get_val_descr( lv_tabled ) }|. "проверить MWSKZ + T007A + T007S
lv_tabled = 'ZZZ'. "don't exists value
write: / |Tabled: { zcl_mdv_el_descr=>get_val_descr( lv_tabled ) }|. "проверить MWSKZ + T007A + T007S

*   1. Проверочная таблица с текстовой (например, Код налога. Таблицы T007A + T007S)
data lv_mwskz type mwskz value 'C0'.
write: / |MWSKZ: { zcl_mdv_el_descr=>get_val_descr( lv_mwskz ) }|.
write: / |MWSKZ: { zcl_mdv_el_descr=>get_val_descr( lv_mwskz ) }|.

*   2. Проверочная таблица с текстовой, несодержащей записи (например, Мандант. Таблицы T000 + AD00PMCLT)
write: / |MANDT: { zcl_mdv_el_descr=>get_val_descr( sy-mandt ) }|.
*write: / |MANDT: { zcl_mdv_el_descr=>get_val_descr(  ) }|.
*   3. Проверочная таблица без текстовой (например, Балансовая единица. Таблица T001)
data lv_bukrs type bukrs value '1000'.
write: / |BUKRS: { zcl_mdv_el_descr=>get_val_descr( lv_bukrs ) }|.
