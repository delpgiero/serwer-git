SELECT 
    b.podgrupa_asortymentowa grupa_towarowa,
    b.nazwa_podgrupy_asortymentowej nazwa_grupy,
    A.MATERIAL,
    B.INDEKS_HURT indeks,
    b.nazwa_materialu nazwa_towaru,
    A.ILE_ZBIOR WIELKOSC_OPAKOWANIA,
    A.JM,
    A.CENA cena_opakowanie_pln,
    b.ean11 EAN
FROM 
    dane_sklep_slp_m24 a
    LEFT JOIN OLAP_DANE.MV_SAP_MARA B ON A.MATERIAL=B.MATERIAL AND A.PARTIA = B.PARTIA
WHERE 
    B.MAABC IN ('A','B','C','D','N')
ORDER BY 
    1,3