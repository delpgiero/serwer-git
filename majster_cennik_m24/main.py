from oracle import PolaczenieOracle
from datetime import datetime
from mail import WyslijMaila
import os
import pandas as pd


def pobierz_df(sql_code):
    oracle = PolaczenieOracle()
    oracle.otworz_polaczenie()
    oracle.wywolaj_query(sql_code)
    df = oracle.df
    oracle.zamknij_polaczenie()
    return df

def format_as_table(worksheet, df, table_name):
    # Określenie zakresu danych dla tabeli
    (max_row, max_col) = df.shape
    column_settings = [{'header': col} for col in df.columns]

    # Dodanie tabeli do worksheet'a
    worksheet.add_table(0, 0, max_row, max_col - 1,
                        {'columns': column_settings,
                            'name': table_name,
                            'style': 'Table Style Medium 9',  # Możesz zmienić styl tabeli
                            'autofilter': True})
    
today = datetime.today()
TODAY = today.strftime("%Y%m%d")    
# kwartal = "1 kwartal 2025"
path = f"MAJSTER_CENNIK_{TODAY}.xlsx"


with open("kod_baza.sql", "r") as file:
    sql_code1 = file.read()   
    

df_baza = pobierz_df(sql_code1)


writer = pd.ExcelWriter(path, engine="xlsxwriter")
df_baza.to_excel(writer, sheet_name="BAZA", index=False)

workbook = writer.book
worksheet_baza = writer.sheets["BAZA"]

percent_format = workbook.add_format({'num_format': '0.00%'})
thousands_decimal_format = workbook.add_format({'num_format': '#,##0.00'})

for i, col in enumerate(df_baza.columns):
    # Oblicz maksymalną długość wartości w kolumnie, uwzględniając nagłówek
    max_length = max(df_baza[col].astype(str).map(len).max(), len(col)) + 2  # +2 dla marginesu
    worksheet_baza.set_column(i, i, max_length)

# worksheet_baza.set_column('N:P', None, percent_format)
# worksheet_baza.set_column('J:M', None, thousands_decimal_format)


format_as_table(worksheet_baza, df_baza, "BAZA")

worksheet_baza.autofit()
writer.close()



WyslijMaila(today, path, df_baza, TODAY)
os.remove(path)  # Usuwa plik XLSX po wysłaniu maila
