SELECT distinct
    CASE WHEN LENGTH(E.ODBIORCA) > 5 THEN '['||''||e.odbiorca||']  '||f.nazwa1||' '||F.NAZWA2 ELSE 'BRAK DANYCH O KLIENCIE' END ODBIORCA,
    a.NRZAP nr_zapytania_flow,
    b.indeks_hurt,
    a.partia,
    b.nazwa_materialu,
    TO_CHAR(d.data_realizacji, 'DD Month YYYY', 'NLS_DATE_LANGUAGE = POLISH') pierwotna_data_realizacji,
    TO_CHAR(a.DATA_REALIZACJI, 'DD Month YYYY', 'NLS_DATE_LANGUAGE = POLISH') nowa_data_realizacji,
    a.DATA_REALIZACJI - d.data_realizacji o_ile_dni_zmieniono,
    c.email,
    d.nr_zamow zamowienie_tab,
    a.DATA_REALIZACJI nowa_data_realizacji_podmiana
    
FROM 
    olap_dane.mv_sap_zamow A
    left join olap_dane.mv_sap_mara B on a.material = b.material and a.partia = b.partia
    left join olap_dane.mv_sap_ph C on SUBSTR(ZLECAJACY, -4) = substr(c.pernr,5,4)
    left join zamowienia_terminy_realizacji D on a.nr_zamow = d.nr_zamow and a.material = d.material and a.lp_zamow = d.lp_zamow
    left join ZAPYTANIE_TOWAR_PRZYPISANIE e on a.nrzap = e.sygnatura
    left join olap_dane.mv_sap_odbiorcy f on e.odbiorca = f.kod_odbiorcy
WHERE 
    a.ZAMOWIENIE_ZREALIZOWANE != 'X'
    AND ZLECAJACY != ' '
    AND a.DATA_UTWORZENIA >= SYSDATE - 1000
    AND LENGTH(ZLECAJACY) <= 8
    AND SUBSTR(A.NRZAP,1,1) = 'Z'
   AND a.DATA_REALIZACJI - d.data_realizacji > 3
ORDER BY 
    2,1
