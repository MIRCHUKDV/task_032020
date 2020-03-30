*&---------------------------------------------------------------------*
*& Report ZMDV_EL_1
*&---------------------------------------------------------------------*
*&  Пример использования класса zcl_mdv_el_descr - возвращающего текстовые описания для значений.
*&---------------------------------------------------------------------*
report zmdv_el_1.


**********************************************************************
* Проверка ЭД с фиксированными значениями
data lv_fixed  type xfeld.
lv_fixed = abap_true.
write: / |Fixed. Existing value = { lv_fixed }. Text = { zcl_mdv_el_descr=>get_val_descr( lv_fixed ) }|.
lv_fixed = '2'.
write: / |Fixed. Non-existing value = { lv_fixed }. Text = { zcl_mdv_el_descr=>get_val_descr( lv_fixed ) }|.


**********************************************************************
* Проверка ЭД с диапазоном значений
data lv_ranged type zemdv_el_ranged.
lv_ranged = 'BB'.
write: / |Ranged: { zcl_mdv_el_descr=>get_val_descr( lv_ranged ) }|.


**********************************************************************
* Проверка ЭД с табличными значениями. 3 варианта
* 1. Проверочная таблица с текстовой (например, Код налога. Таблицы T007A + T007S)
data lv_mwskz type mwskz.
lv_mwskz = 'C0'.
write: / |MWSKZ. Existing value = { lv_mwskz }. Text = { zcl_mdv_el_descr=>get_val_descr( lv_mwskz ) }|.
lv_mwskz = '__'.
write: / |MWSKZ. Non-existing value = { lv_mwskz }. Text = { zcl_mdv_el_descr=>get_val_descr( lv_mwskz ) }|.

* 2. Проверочная таблица с текстовой, несодержащей записи (например, Мандант. Таблицы T000 + AD00PMCLT)
write: / |MANDT. Existing value = { sy-mandt }. Text = { zcl_mdv_el_descr=>get_val_descr( sy-mandt ) }|.

* 3. Проверочная таблица без текстовой (например, Балансовая единица. Таблица T001)
data lv_bukrs type bukrs.
lv_bukrs = '2000'.
write: / |BUKRS. Existing value = { lv_bukrs }. Text = { zcl_mdv_el_descr=>get_val_descr( lv_bukrs ) }|.
lv_bukrs = '2__2'.
write: / |BUKRS. Non-existing value = { lv_bukrs }. Text = { zcl_mdv_el_descr=>get_val_descr( lv_bukrs ) }|.
