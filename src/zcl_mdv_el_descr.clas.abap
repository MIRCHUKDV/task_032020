class ZCL_MDV_EL_DESCR definition
  public
  final
  create public .

public section.

  class-methods GET_VAL_DESCR
    importing
      !IV_VAR type ANY
      !IV_TEXT_FNAME type STRING optional
    returning
      value(RV_RES) type STRING .
protected section.
private section.

  types:
    "таблица "значение-текстовое описание"
    begin of ty_data,
      value type string,
      text  type string,
    end of ty_data .
  types:
    tty_data type sorted table of ty_data with non-unique key value . "не уникальность оставим на случай пересечений разных источников
  types:
    "таблица буфера
    begin of ty_buffer,
      name    type string, "имя типа данных (ЭД)
      t_data  type tty_data,
      t_fixed type ddfixvalues,
    end of ty_buffer .
  types:
    tty_buffer type hashed table of ty_buffer with unique key name .

  class-data GT_BUFFER type TTY_BUFFER .

  class-methods _GET_TEXT_FROM_FIXED
    importing
      !IT_FIXED type TY_BUFFER-T_FIXED
      !IV_VAR type ANY
    returning
      value(RV_RES) type STRING .
  class-methods _GET_TEXT_FIELD
    importing
      !IV_TABNAME type TABNAME16
    returning
      value(RV_FNAME) type NAME_FELD .
  class-methods _GET_FIELD_BY_DOMEN
    importing
      !IV_TABNAME type TABNAME16
      !IV_DOMNAME type DOMNAME
    returning
      value(RV_FNAME) type NAME_FELD .
  class-methods _GET_LANG_FIELD
    importing
      !IV_TABNAME type TABNAME16
    returning
      value(RV_FNAME) type NAME_FELD .
ENDCLASS.



CLASS ZCL_MDV_EL_DESCR IMPLEMENTATION.


  method get_val_descr.
    types:
*      "тип диапазона, в который можно поместить любые значения (пока без динамики)
*      tr_string type range of string,
      "Тип для динамических выборок по рассматриваемым таблицам (таблице значений, текстовой таблице)
      begin of ty_source,
        tabname     type tabname16, "имя таблицы
        value_fname type fieldname, "имя ключевого поля, содержащего значения
        text_fname  type fieldname, "имя текстового поля, содержащего описание к значению
        lang_fname  type fieldname, "имя языкового поля
      end of ty_source.

    data:
      lt_source type table of ty_source,
      ls_buffer like line of gt_buffer.


*   Получаем описание ЭД по входному параметру
    data(lo_elem) = cast cl_abap_elemdescr( cl_abap_typedescr=>describe_by_data( iv_var ) ).
    check lo_elem->is_ddic_type( ) eq abap_true.


*   Проверяем содержимое буфера
    read table gt_buffer assigning field-symbol(<ls_buffer>) with table key name = lo_elem->get_relative_name( ).
    if sy-subrc is initial.
      try.
          "ищем запись среди табличных значений
          rv_res = <ls_buffer>-t_data[ value = iv_var ]-text.
        catch cx_root.
          "запись с таким значением не найдена: ищем ее среди постоянных значений.
          rv_res = _get_text_from_fixed( it_fixed = <ls_buffer>-t_fixed iv_var = iv_var ).
      endtry.
      "если ничего не нашли - в буфере есть информация про текущий тип, но текущее значение переменной не найдено.
      "выходим в любом случае
      return.
    endif.


*    Данных в буфере нет - начинаем анализ
    ls_buffer-name = lo_elem->get_relative_name( ).
    " Получем перечень фиксированных значений из домена, если таковые имеются
    ls_buffer-t_fixed = lo_elem->get_ddic_fixed_values( ).
    "Получаем структуру с описанием ЭД
    data(ls_ddic_field) = lo_elem->get_ddic_field( ).
    "ищем значение переменной в перечне фиксированных значений домена (отдельные значения и диапазоны)
    rv_res = _get_text_from_fixed( it_fixed = ls_buffer-t_fixed iv_var = iv_var ).


*   Продолжаем анализ - смотрим на возможные проверочные таблицы со значениями (проверочная таблица и текстовая к ней)
    select single d1~entitytab, d8~tabname as texttab
      from dd01l as d1
      left join dd08l as d8 on d8~checktable = d1~entitytab and
                               d8~frkart = 'TEXT' and
                               d8~as4local = 'A' "todo: find const
      into @data(ls_res)
      where d1~domname = @ls_ddic_field-domname and
            d1~as4local = 'A' and
            d1~entitytab is not null.

    "теперь у нас есть в ls_res имена одной или двух таблиц, где могут лежать текстовые. Нам надо проанализировать каждую таблицу и найти в каждой:
    " 1) поле такого же типа, как и входное IV_VAR - в нем лежат значения;
    " 2) поле с описанием - либо взять его из входного параметра IV_TEXT_FNAME, либо постараться определить самостоятельно
    " 3) поля с языком, так как тексты зависят от языка.
    "Итог анализа положим в локальную таблицу lt_source - потом с ее помощью будем делать селект. Порядок записей важен, чем первее запись - тем выше приоритет todo prior

    "если определена текстовая таблица - заносим ее данные в lt_source
    if ls_res-texttab is not initial.
      lt_source = value #( let lv_tabname = conv tabname16( ls_res-texttab ) in
                           base lt_source (
                                            "заполняем имя таблицы - текстовая таблица
                                            tabname = ls_res-texttab
                                            "определяем ключевое поле таблицы, имеющее такой же домен
                                            value_fname = _get_field_by_domen( iv_tabname = lv_tabname iv_domname = ls_ddic_field-domname )
                                            "определяем текстовое поле в таблице. Либо переданное на вход метода как параметр IV_TEXT_FNAME, либо динамически
                                            text_fname = cond #( when iv_text_fname is not initial then iv_text_fname
                                                                 else _get_text_field( lv_tabname )
                                                                )
                                            lang_fname = _get_lang_field( lv_tabname )
                                           )
                          ).
    endif.
    "если определена таблица со значениями - заносим ее данные в lt_source
    if ls_res-entitytab is not initial.
      lt_source = value #( let lv_tabname = conv tabname16( ls_res-entitytab ) in
                           base lt_source (
                                            "заполняем имя таблицы - таблица со значениями
                                            tabname = ls_res-entitytab
                                            "определяем ключевое поле таблицы, имеющее такой же домен
                                            value_fname = _get_field_by_domen( iv_tabname = lv_tabname iv_domname = ls_ddic_field-domname )
                                            "определяем текстовое поле в таблице. Либо переданное на вход метода как параметр IV_TEXT_FNAME, либо динамически
                                            text_fname = cond #( when iv_text_fname is not initial then iv_text_fname
                                                                 else _get_text_field( lv_tabname )
                                                                )
                                            lang_fname = _get_lang_field( lv_tabname )
                                           )
                          ).
    endif.


*   Выбираем либо текстовую таблицу к проверочной (если она есть), либо саму проверочную таблицу.
*   На текущий момент есть три возможных варианта:
*   1. Проверочная таблица с текстовой (например, Код налога. Таблицы T007A + T007S)
*   2. Проверочная таблица с текстовой, несодержащей записи (например, Мандант. Таблицы T000 + AD00PMCLT)
*   3. Проверочная таблица без текстовой (например, Балансовая единица. Таблица T001)
    loop at lt_source assigning field-symbol(<ls_source>).
      "заполняем список выбираемых полей (поле со значением и поле с описанием)
      data(lv_field_list) = conv string( |{ <ls_source>-value_fname } as value, { <ls_source>-text_fname } as text| ).
      "при необходимости ставим языковое ограничение
      data(lv_where) = cond string( when <ls_source>-lang_fname is not initial then |{ <ls_source>-lang_fname } = @sy-langu| ).
      "Делаем динамическую выборку и помещаем результат в буфер
      try.
          select (lv_field_list)
            from (<ls_source>-tabname)
            into corresponding fields of table @ls_buffer-t_data
            where (lv_where).
        catch cx_root.
      endtry.

      "Если никаких данных нет (это вариант №2) - переходим к следующей таблице
      check sy-subrc is initial.

      "теперь ищем текстовое описание к нашему входному значению IV_VAR
      try.
          rv_res = ls_buffer-t_data[ value = iv_var ]-text.
          "значение найдено - значит текущая таблица содержит актуальные данные. Заказнчиваем обработку в цикле
          exit.
        catch cx_root.
          "запись не найдена - такое бывает. Не расстраиваемся и переходим к следующей таблице
          continue.
      endtry.
    endloop.


    "заносим накопленные данные в буфер
    insert ls_buffer into table gt_buffer.

  endmethod.


  method _get_field_by_domen.
*   Метод определяет в таблице первое ключевое поле с типом входящего домена.

    loop at cast cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( iv_tabname ) )->get_ddic_field_list( ) "получаем описание и перечень полей таблицы по входящему имени таблицы
            assigning field-symbol(<ls>)
            where domname = iv_domname and keyflag eq abap_true.  "и находим первое подходящее ключевое поле
      rv_fname = <ls>-fieldname.
      return.
    endloop.

  endmethod.


  method _get_lang_field.
*   Метод определяет ключевое поле языка в таблице.

    loop at cast cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( iv_tabname ) )->get_ddic_field_list( ) "получаем описание и перечень полей таблицы по входящему имени
            assigning field-symbol(<ls>)
            where datatype = 'LANG' and keyflag eq abap_true.
      "берем первую подходящую запись
      rv_fname = <ls>-fieldname.
      return.
    endloop.

  endmethod.


  method _get_text_field.
*   Метод определяет первое подходящее текстовое поле в таблице. Поле должно быть неключевым, символьным и иметь длину хотя бы 10 символов.
*   todo: проверить, как будет работать с типом string (однако в стандарте подобных полей в текстовых таблицах не видел).

    loop at cast cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( iv_tabname ) )->get_ddic_field_list( ) "получаем описание и перечень полей таблицы по входящему имени
            assigning field-symbol(<ls>)
            where leng >= 10 and inttype = 'C' and keyflag is initial.  "и находим первое немаленькое неключевое символьное поле
      "берем первую подходящую запись
      rv_fname = <ls>-fieldname.
      return.
    endloop.

  endmethod.


  method _get_text_from_fixed.
*   Метод возвращает текстовое описание из фиксированных значений (отдельные значения и диапазоны) 
    types:
      "тип диапазона, в который можно поместить любые значения (пока без динамики)
      tr_string type range of string.

    loop at it_fixed assigning field-symbol(<ls_fixed>).
      if iv_var in value tr_string( ( sign = 'I' option = <ls_fixed>-option low = <ls_fixed>-low high = <ls_fixed>-high ) ).
        "Значение найдено - берем текстовое описание и выходим
        rv_res = <ls_fixed>-ddtext.
        return.
      endif.
    endloop.

  endmethod.
  
ENDCLASS.
