SELECT DISTINCT
    a.material,
    a.grupa_asortymentowa KATALOGGRUPPE,
    a.podgrupa_asortymentowa KATALOGUNTERGRUPPE,
    a.nazwa_materialu marcopol_name,
    etykieta_de LINK_ZUM_PRODUKT,
    b.norma norm,
    b.krozmiar ABMESSUNG,
    k.de made_of_material,
    b.klasa KLASSE_DER_MECHANISCHEN_EIGENSCHAFTEN  ,
    j.de BESCHICHTUNG,
    l.de Antrieb,
    e.iloscoj VERPACKUNGSMENGE_STÜCK_ODER_KG,
        CASE WHEN A.JM = 'TYS' THEN 'TSD'
              WHEN A.JM = 'SZT' THEN 'STK'
              WHEN A.JM = 'KPL' THEN 'SATZ'
              WHEN A.JM = 'OPK' THEN 'BOX'
              ELSE A.JM END EINHEIT,
    waga_1000_sztuk CA_GEWICHT_VON_1000_STÜCK,
    CASE WHEN SUBSTR(a.material,-1,1) != 'K' THEN CEIL(1 /(waga_1000_sztuk / 1000))
              WHEN SUBSTR(a.material,-1,1) = 'K' THEN ilosc_w_kg END CA_MENGE_STÜCK_PRO_KG,
    CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END TOWAR_WYPRODUKOWANY_MARCOPOL,
    SUM(CASE WHEN F.LGORT = '0' THEN QTY ELSE 0 END) LAGERMENGE_0,
    SUM(CASE WHEN F.LGORT = '10' THEN QTY ELSE 0 END) LAGERMENGE_10,
    SUM(CASE WHEN F.LGORT = '99' THEN QTY ELSE 0 END) LAGERMENGE_99,
    SUM(CASE WHEN F.LGORT = '6' THEN QTY ELSE 0 END) LAGERMENGE_6,
    SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END) LAGERMENGE_ALLE,
    ROUND(DECODE(SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN),0,G.CENA_BAZOWA,
    SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END) * G.CENA_BAZOWA) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN) /
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN)),2) C_B_PLN,
    ROUND((ROUND(DECODE(SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN),0,G.CENA_BAZOWA,
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END) * G.CENA_BAZOWA) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN) /
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN)),2)) /
        (SELECT UKURS * 0.98 KURS FROM olap_dane.KURSY_WALUT A WHERE FCURR = 'EUR' ORDER BY DATA DESC FETCH FIRST 1 ROWS ONLY),2) C_B_EUR,
    ROUND(CASE WHEN A.JM = 'TYS' THEN ROUND(DECODE(SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN),0,G.CENA_BAZOWA,
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END) * G.CENA_BAZOWA) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN) /
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN)),2)
        WHEN A.JM = 'KG' THEN  (1000 / CASE WHEN SUBSTR(a.material,-1,1) != 'K' THEN CEIL(1 /(waga_1000_sztuk / 1000))
        WHEN SUBSTR(a.material,-1,1) = 'K' THEN ilosc_w_kg END) * ROUND(DECODE(SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN),0,G.CENA_BAZOWA,
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END) * G.CENA_BAZOWA) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN) /
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN)),2) 
        ELSE ROUND(DECODE(SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN),0,G.CENA_BAZOWA,
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END) * G.CENA_BAZOWA) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN) /
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN)),2) * 1000 END,2) PRZELICZENIE_C_B_ZA_1000SZT_PLN,
    ROUND(ROUND(CASE WHEN A.JM = 'TYS' THEN ROUND(DECODE(SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN),0,G.CENA_BAZOWA,
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END) * G.CENA_BAZOWA) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN) /
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN)),2)
        WHEN A.JM = 'KG' THEN  (1000 / CASE WHEN SUBSTR(a.material,-1,1) != 'K' THEN CEIL(1 /(waga_1000_sztuk / 1000))
        WHEN SUBSTR(a.material,-1,1) = 'K' THEN ilosc_w_kg END) * ROUND(DECODE(SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN),0,G.CENA_BAZOWA,
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END) * G.CENA_BAZOWA) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN) /
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN)),2) 
        ELSE ROUND(DECODE(SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN),0,G.CENA_BAZOWA,
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END) * G.CENA_BAZOWA) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN) /
        SUM(SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END)) OVER (PARTITION BY a.material, e.iloscoj, CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, h.C_MIN)),2) * 1000 END,2) /  (SELECT UKURS * 0.98 KURS FROM olap_dane.KURSY_WALUT A WHERE FCURR = 'EUR' ORDER BY DATA DESC FETCH FIRST 1 ROWS ONLY),2) PRZELICZENIE_C_B_ZA_1000SZT_EUR,
    NULL MARZA,
    ROUND((SELECT UKURS * 0.98 KURS FROM olap_dane.KURSY_WALUT A WHERE FCURR = 'EUR' ORDER BY DATA DESC FETCH FIRST 1 ROWS ONLY),4) KURS,
    H.C_MIN CENA_MINIMALNA,
    ROUND(H.C_MIN /  (SELECT UKURS * 0.98 KURS FROM olap_dane.KURSY_WALUT A WHERE FCURR = 'EUR' ORDER BY DATA DESC FETCH FIRST 1 ROWS ONLY),2) CENA_MINIMALNA_EUR,
    srednia_cena SREDNIA_CENA_180_D2_PLN,
    ROUND(srednia_cena /  (SELECT UKURS * 0.98 KURS FROM olap_dane.KURSY_WALUT A WHERE FCURR = 'EUR' ORDER BY DATA DESC FETCH FIRST 1 ROWS ONLY),2) SREDNIA_CENA_180_D2_EUR,
    NULL EINHEITSPREIS,
    'EUR' Währung,
    de_url 
    
FROM
    olap_dane.mv_sap_mara a
    LEFT JOIN dane_pim_zkatalog b ON a.material = b.matnr
    LEFT JOIN (SELECT DISTINCT 
                            b.material,
                            CASE WHEN SUBSTR(TO_CHAR(MIN(ilosc_tys_w_kg_dla_kg)),1,1) = ',' THEN MIN(ilosc_tys_w_kg_dla_kg) * 1000 ELSE MIN(ilosc_tys_w_kg_dla_kg) END ilosc_w_kg
                       FROM 
                             crm_produkcja.klancrm_app_indeksy_info_dod a
                             LEFT JOIN olap_dane.mv_sap_mara b ON a.indeks = b.indeks_hurt
                       WHERE 
                             ilosc_tys_w_kg_dla_kg <> 0
                             AND ilosc_tys_w_kg_dla_kg <> 1
                        GROUP BY 
                              b.material
                    ) C ON a.material = c.material
    LEFT JOIN (SELECT DISTINCT
                                b.material,
                                CASE WHEN SUBSTR(b.material,-1,1) = 'K' THEN waga_tys
                                          WHEN SUBSTR(b.material,-1,1) = 'S' THEN c.waga * 1000
                                          WHEN SUBSTR(b.material,-1,1) = 'O' THEN c.waga * 1000
                                           WHEN SUBSTR(b.material,-1,1) = 'M' THEN c.waga * 1000
                                           WHEN SUBSTR(b.material,-1,1) = 'P' THEN c.waga * 1000
                                            ELSE c.waga END waga_1000_sztuk
                            FROM 
                                crm_produkcja.klancrm_app_indeksy_info_dod a
                                LEFT JOIN olap_dane.mv_sap_mara b ON a.indeks = b.indeks_hurt
                                LEFT JOIN wagi_normatywne c ON b.material = c.material
                            WHERE
                                  CASE WHEN SUBSTR(b.material,-1,1) = 'K' THEN waga_tys ELSE c.waga END IS NOT NULL
                                           AND CASE WHEN ( SUBSTR(b.material,-1,1) = 'K'
                                           AND waga_tys = 1 ) THEN 1 ELSE 0 END <> 1
                    ) D ON a.material = d.material
    LEFT JOIN OLAP_DANE.ZKATALOG2 E ON A.MATERIAL = E.MATNR AND A.PARTIA = E.CHARG
    LEFT JOIN (SELECT 
                            MATERIAL, 
                            PARTIA, 
                            CENA CENA_BAZOWA 
                       FROM 
                            promocja_ceny
                    WHERE 
                            TO_CHAR(sysdate,'yyyymmdd') between data_od and data_do
                        ) G ON A.MATERIAL = G.MATERIAL AND A.PARTIA = G.PARTIA
    LEFT JOIN (SELECT 
                            matnr material, 
                            charg partia, 
                            c_min
                        FROM 
                            Olap_dane.sap_ceny_minimalne_historia
                        WHERE 
                            TO_DATE(SYSDATE) BETWEEN TO_DATE(data_od,'yyyymmdd') AND TO_DATE(data_do,'yyyymmdd')
                        ) H ON A.MATERIAL = H.MATERIAL AND A.PARTIA = H.PARTIA
    LEFT JOIN (SELECT 
                            A.MATERIAL, 
                            C.ILOSCOJ,                           
                            ROUND(AVG(NETTO/ILOSC),2) SREDNIA_CENA 
                        FROM 
                            olap_dane.mv_sap_copa A
                            LEFT JOIN OLAP_DANE.MV_SAP_MARA B ON A.MATERIAL = B.MATERIAL AND A.PARTIA = B.PARTIA
                            LEFT JOIN OLAP_DANE.ZKATALOG2 C ON A.MATERIAL = C.MATNR AND A.PARTIA = C.CHARG
                        WHERE 
                            "data utworzenia faktury" >= sysdate - 180
                            AND "dzial sprzedazy" LIKE '2%'
                            AND ILOSC > 0
                            AND MAABC IN ('A', 'B', 'C', 'D', 'N')
                        GROUP BY 
                            A.MATERIAL,
                            C.ILOSCOJ
                        ) I ON a.material = i.material AND E.ILOSCOJ = I.ILOSCOJ
    LEFT JOIN dane_pim_zkatalog_slownik_pokrycie J ON B.COATING_PL = J.PL
    LEFT JOIN dane_pim_zkatalog_slownik_material K ON b.made_of_material_pl = k.PL
    LEFT JOIN dane_pim_zkatalog_slownik_wglebienie L ON b.rodzaj_wglebienia = l.PL
    
        LEFT JOIN (SELECT 
                                A.MATNR, 
                                ILOSCOJ, 
                                LGORT, 
                                QTY, 
                                CASE WHEN A.CHARG LIKE '%PR' THEN 'X' END PRODUKCJA, 
                                c_min
                            FROM 
                                OLAP_DANE.STAN_ZATP0 a
                                LEFT JOIN OLAP_DANE.ZKATALOG2 B ON A.MATNR = B.MATNR AND A.CHARG = B.CHARG
                                LEFT JOIN (SELECT 
                                                        matnr material, 
                                                        charg partia, 
                                                        c_min
                                                    FROM 
                                                        Olap_dane.sap_ceny_minimalne_historia
                                                    WHERE 
                                                        TO_DATE(SYSDATE) BETWEEN TO_DATE(data_od,'yyyymmdd') AND TO_DATE(data_do,'yyyymmdd')
                                                ) c on a.matnr = c.material and a.charg = c.partia
                            WHERE 
                                LGORT IN ('0', '10', '99', '6')
                                AND qty > 0
                        ) F ON A.MATERIAL = F.MATNR AND E.ILOSCOJ = F.ILOSCOJ AND NVL(F.PRODUKCJA,'NIE') = NVL(CASE WHEN A.PARTIA LIKE '%PR' THEN 'X' END, 'NIE') AND h.c_min = f.c_min
    
    
WHERE
    MAABC IN ('A', 'B', 'C', 'D', 'N')
    AND e.iloscoj IS NOT NULL
    AND H.C_MIN IS NOT NULL
HAVING
    CASE WHEN SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END) = 0 AND e.aktywny != 'X' THEN 1 ELSE 0 END = 0
GROUP BY
    a.material,
    a.grupa_asortymentowa,
    a.podgrupa_asortymentowa,
    a.nazwa_materialu,
    b.norma,
    b.krozmiar,
    k.de,
    b.klasa,
    J.DE,
    A.JM,
    e.iloscoj,
    waga_1000_sztuk,
ilosc_w_kg,
    CASE WHEN SUBSTR(a.material,-1,1) != 'K' THEN NULL
              WHEN SUBSTR(a.material,-1,1) = 'K' THEN ilosc_w_kg END,
    CASE WHEN A.JM = 'TYS' THEN 'TSD'
              WHEN A.JM = 'SZT' THEN 'STK'
              WHEN A.JM = 'KPL' THEN 'SATZ'
              WHEN A.JM = 'OPK' THEN 'BOX'
              ELSE A.JM END,
    G.CENA_BAZOWA,
    H.C_MIN,
    srednia_cena,
    de_url,
    l.de,
    etykieta_de,
    E.AKTYWNY,
    A.PARTIA
ORDER BY
    MATERIAL, E.ILOSCOJ