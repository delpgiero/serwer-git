import pandas as pd

def write_formatted_df_to_excel(df, writer, sheet_name):
    workbook  = writer.book

    # === Definicja stylu dla hiperłącza ===
    format_hyperlink = workbook.add_format({
        'font_color': 'blue',
        'underline': 1
    })

    # === Dodawanie hiperłączy: tekst z kolumny E, URL z kolumny AG ===
    try:
        col_text_idx = 4   # kolumna E
        col_url_idx  = 33  # kolumna AG

        col_text = df.columns[col_text_idx]
        col_url  = df.columns[col_url_idx]
    except IndexError:
        print("Nie znaleziono kolumny E lub AG – upewnij się, że DataFrame ma co najmniej 33 kolumny.")
        return

    # Zapis arkusza bez hiperłączy (hiperlinki zostaną dodane ręcznie poniżej)
    df_out = df.drop(columns=[col_url])  # usuwamy URL z df do eksportu
    df_out.to_excel(writer, sheet_name=sheet_name, index=False, startrow=0)

    worksheet = writer.sheets[sheet_name]

    # Format nagłówków
    header_format = workbook.add_format({
        'bold': True,
        'text_wrap': True,
        'valign': 'vcenter',
        'align': 'center',
        'border': 1
    })

    # Ogólny formaty
    format_number = workbook.add_format({'num_format': '#,##0.00', 'align': 'right'})
    format_text = workbook.add_format({})
    format_number_orange = workbook.add_format({'num_format': '#,##0.00', 'align': 'right', 'bg_color': '#FFE5B4'})
    format_text_orange = workbook.add_format({'bg_color': '#FFE5B4'})

    numeric_cols = df.select_dtypes(include='number').columns

    # Dopasowanie szerokości kolumn i zapis nagłówków
    for col_idx, col in enumerate(df_out.columns):
        max_len = max(df_out[col].astype(str).map(len).max(), len(str(col)))
        col_width = max_len + 2
        worksheet.set_column(col_idx, col_idx, col_width)
        worksheet.write(0, col_idx, col, header_format)

    # Wpisanie danych (z hyperlinkiem w kolumnie E)
    for row_idx, row in df.iterrows():
        for col_idx, col in enumerate(df_out.columns):
            val = row[col]

            # Jeśli wartość to NaN, zostawiamy pustą komórkę
            if pd.isna(val):
                val = ''

            is_orange_col = 15 <= col_idx <= 30
            is_numeric = col in numeric_cols

            if is_orange_col:
                fmt = format_number_orange if is_numeric else format_text_orange
            else:
                fmt = format_number if is_numeric else format_text

            # Jeśli to kolumna z hiperlinkiem (E / index 4), użyj write_formula
            if col_idx == col_text_idx:
                url = row[col_url]
                display_text = row[col_text]
                if pd.notna(url) and pd.notna(display_text):
                    formula = f'=HYPERLINK("{url}", "{display_text}")'
                    worksheet.write_formula(row_idx + 1, col_idx, formula, format_hyperlink)
                else:
                    worksheet.write(row_idx + 1, col_idx, '', format_text)
            else:
                worksheet.write(row_idx + 1, col_idx, val, fmt)

    worksheet.set_row(0, 30)
    worksheet.freeze_panes(1, 0)
