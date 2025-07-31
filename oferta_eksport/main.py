from datetime import datetime
from classes.oracle import PolaczenieOracle
from utils.formatowanie_personal import write_formatted_df_to_excel
import pandas as pd
import os
import yaml
from monitor import nadzorowana_funkcja

def generuj_raport():
    # os.environ["NLS_LANG"] = "GERMAN_GERMANY.AL32UTF8"
    # Wczytaj konfigurację z YAML
    with open('config/report_config.yaml', 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)

    dzisiaj_str = datetime.now().strftime("%d%m%Y")
    
    oracle = PolaczenieOracle()
    try:
        oracle.otworz_polaczenie()
        
        for lang, lang_config in config['wersje_jezykowe'].items():
            # Wczytanie zapytania SQL
            with open(lang_config['sql_file'], 'r', encoding="utf-8-sig") as f:
                query = f.read()
            # print(repr(query))
            # Wykonanie zapytania
            oracle.wywolaj_query(query)
            
            # Generowanie ścieżki
            sciezka_wyjsciowa = os.path.join(
                config['base_dir'],
                config['output_filename_template']
                    .replace('{sufix}', lang_config['sufix'])
                    .replace('{date}', dzisiaj_str)
            )
            
            # Zapis do Excel
            with pd.ExcelWriter(sciezka_wyjsciowa, engine='xlsxwriter') as writer:
                write_formatted_df_to_excel(oracle.df, writer, lang_config['arkusz'])
    finally:
        oracle.zamknij_polaczenie()

if __name__ == "__main__":
    wlasciciel = "patryk.gajda@marcopol.pl"
    skrypt_sciezka = os.path.abspath(__file__)
    nadzorowana_funkcja(generuj_raport, wlasciciel, skrypt_sciezka)