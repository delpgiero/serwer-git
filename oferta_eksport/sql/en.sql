SELECT DISTINCT
    a.material,
    a.grupa_asortymentowa catalogue_group,
    a.podgrupa_asortymentowa catalogue_subgroup,
    a.nazwa_materialu marcopol_name,
    ETYKIETA_EN link_to_product,
    b.norma norm,
    b.krozmiar dimention,
    b.made_of_material_en made_of_material,
    b.klasa class_of_mechanical_properties,
    b.coating_en coating,
    J.ENG recess,
    e.iloscoj quantity_in_packing_pcs_or_kg,
    CASE WHEN A.JM = 'TYS' THEN 'THS'
              WHEN A.JM = 'SZT' THEN 'PCS'
              WHEN A.JM = 'KPL' THEN 'CPL'
              WHEN A.JM = 'OPK' THEN 'BOX'
              ELSE A.JM END UNIT,
    waga_1000_sztuk approx_weight_of_1000pcs,
    CASE WHEN SUBSTR(a.material,-1,1) != 'K' THEN NULL
              WHEN SUBSTR(a.material,-1,1) = 'K' THEN ilosc_w_kg END approx_qty_pcs_in_kg,
    CASE WHEN K.MATERIAL IS NOT NULL THEN 'X' END TOWAR_WYPRODUKOWANY_MARCOPOL,
    SUM(CASE WHEN F.LGORT = '0' THEN QTY ELSE 0 END) STOCK_0,
    SUM(CASE WHEN F.LGORT = '10' THEN QTY ELSE 0 END) STOCK_10,
    SUM(CASE WHEN F.LGORT = '99' THEN QTY ELSE 0 END) STOCK_99,
    SUM(CASE WHEN F.LGORT = '6' THEN QTY ELSE 0 END) STOCK_6,
    SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END) STOCK_ALL,
    NVL(g.cena_bazowa,0) C_B_PLN,
    NVL(ROUND(NVL(g.cena_bazowa,0) / (SELECT UKURS * 0.98 KURS FROM olap_dane.KURSY_WALUT A WHERE FCURR = 'EUR' ORDER BY DATA DESC FETCH FIRST 1 ROWS ONLY),2),0) C_B_EUR,
    ROUND(CASE WHEN A.JM = 'TYS' THEN NVL(g.cena_bazowa,0)
        WHEN A.JM = 'KG' THEN  (1000 / CASE WHEN SUBSTR(a.material,-1,1) != 'K' THEN CEIL(1 /(waga_1000_sztuk / 1000))
        WHEN SUBSTR(a.material,-1,1) = 'K' THEN ilosc_w_kg END) * NVL(g.cena_bazowa,0)
        ELSE NVL(g.cena_bazowa,0) * 1000 END,2) PRZELICZENIE_C_B_ZA_1000SZT_PLN,                    
    ROUND(CASE WHEN A.JM = 'TYS' THEN NVL(g.cena_bazowa,0)
        WHEN A.JM = 'KG' THEN  (1000 / CASE WHEN SUBSTR(a.material,-1,1) != 'K' THEN CEIL(1 /(waga_1000_sztuk / 1000))
        WHEN SUBSTR(a.material,-1,1) = 'K' THEN ilosc_w_kg END) * NVL(g.cena_bazowa,0)
        ELSE NVL(g.cena_bazowa,0) * 1000 END /  (SELECT UKURS * 0.98 KURS FROM olap_dane.KURSY_WALUT A WHERE FCURR = 'EUR' ORDER BY DATA DESC FETCH FIRST 1 ROWS ONLY),2) PRZELICZENIE_C_B_ZA_1000SZT_EUR,                
    NULL MARZA,
    ROUND((SELECT UKURS * 0.98 KURS FROM olap_dane.KURSY_WALUT A WHERE FCURR = 'EUR' ORDER BY DATA DESC FETCH FIRST 1 ROWS ONLY),4) KURS,
    h.C_MIN CENA_MINIMALNA,
    ROUND(h.C_MIN /  (SELECT UKURS * 0.98 KURS FROM olap_dane.KURSY_WALUT A WHERE FCURR = 'EUR' ORDER BY DATA DESC FETCH FIRST 1 ROWS ONLY),2) CENA_MINIMALNA_EUR,
    srednia_cena SREDNIA_CENA_180_D2_PLN,
    ROUND(srednia_cena /  (SELECT UKURS * 0.98 KURS FROM olap_dane.KURSY_WALUT A WHERE FCURR = 'EUR' ORDER BY DATA DESC FETCH FIRST 1 ROWS ONLY),2) SREDNIA_CENA_180_D2_EUR,
    NULL PRICE_EUR_UNIT,
    'EUR' CURRENCY,
    en_URL

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
                            ILOSCOJ,
                            CASE 
                                WHEN SUM(ILOSC) = 0 OR SUM(ILOSC) IS NULL THEN 0
                                ELSE ROUND(SUM(CENA * ILOSC) / SUM(ILOSC), 2)
                            END AS CENA_BAZOWA
                                               FROM 
                                                    promocja_ceny a
                                                    LEFT JOIN OLAP_DANE.ZKATALOG2 C ON A.MATERIAL = C.MATNR AND A.PARTIA = C.CHARG
                                                    LEFT JOIN (SELECT 
                                                                            A.MATNR, A.CHARG, SUM(QTY) ILOSC 
                                                                        FROM OLAP_DANE.STAN_ZATP0 A
                                                                            LEFT JOIN OLAP_DANE.ZKATALOG2 B ON A.BISMT = b.indeks
                                                                        WHERE 
                                                                            LGORT IN ('0', '10', '99', '6')
                                                                        GROUP BY A.MATNR, A.CHARG) B ON A.MATERIAL = B.MATNR AND A.PARTIA = B.CHARG
                        
                        WHERE 
                            TO_CHAR(sysdate,'yyyymmdd') between data_od and data_do
                        having CASE 
                                WHEN SUM(ILOSC) = 0 OR SUM(ILOSC) IS NULL THEN 0
                                ELSE ROUND(SUM(CENA * ILOSC) / SUM(ILOSC), 2)
                            END > 0
                        GROUP BY 
                            MATERIAL, ILOSCOJ
                        ) G ON A.MATERIAL = G.MATERIAL AND g.iloscoj = e.iloscoj
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
    LEFT JOIN dane_pim_zkatalog_slownik_wglebienie J ON b.rodzaj_wglebienia = J.PL
    LEFT JOIN MATERIALY_PROD_WNWIT K ON A.MATERIAL = K.MATERIAL AND A.PARTIA = K.PARTIA
    LEFT JOIN (SELECT 
                            A.MATNR, 
                            ILOSCOJ, 
                            LGORT, 
                            QTY, 
                            CASE WHEN D.MATERIAL IS NOT NULL THEN 'X' END PRODUKCJA, 
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
                            LEFT JOIN MATERIALY_PROD_WNWIT D ON A.MATNR = D.MATERIAL AND A.CHARG = D.PARTIA
                        WHERE 
                            LGORT IN ('0', '10', '99', '6')
                            AND qty > 0
                    ) F ON A.MATERIAL = F.MATNR AND E.ILOSCOJ = F.ILOSCOJ AND NVL(F.PRODUKCJA,'NIE') = NVL(CASE WHEN K.MATERIAL IS NOT NULL THEN 'X' END, 'NIE') AND h.c_min = f.c_min

WHERE
    MAABC IN ('A', 'B', 'C', 'D', 'N')
    AND e.iloscoj IS NOT NULL
    AND h.C_MIN IS NOT NULL
HAVING
    CASE WHEN SUM(CASE WHEN F.LGORT IN ('0', '10', '99', '6') THEN QTY ELSE 0 END) = 0 AND e.aktywny != 'X' THEN 1 ELSE 0 END = 0

GROUP BY
    a.material,
    a.grupa_asortymentowa,
    a.podgrupa_asortymentowa,
    a.nazwa_materialu,
    b.norma,
    b.krozmiar,
    b.made_of_material_en,
    b.klasa,
    b.coating_en,
    A.JM,
    e.iloscoj,
    waga_1000_sztuk,
    ilosc_w_kg,
    CASE WHEN SUBSTR(a.material,-1,1) != 'K' THEN NULL
              WHEN SUBSTR(a.material,-1,1) = 'K' THEN ilosc_w_kg END,
    CASE WHEN A.JM = 'TYS' THEN 'THS'
              WHEN A.JM = 'SZT' THEN 'PCS'
              WHEN A.JM = 'KPL' THEN 'CPL'
              WHEN A.JM = 'OPK' THEN 'BOX'
              ELSE A.JM END,
    G.CENA_BAZOWA,
    h.C_MIN,
    srednia_cena,
    en_url,
   j.eng,
   ETYKIETA_EN,
   e.aktywny,
   a.partia,
   K.MATERIAL
ORDER BY
    MATERIAL, E.ILOSCOJ