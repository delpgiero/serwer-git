from classes.oracle import PolaczenieOracle
from func.mail import WyslijMaila



with open('sql/baza.sql') as f:
    sql = f.read()
oracle = PolaczenieOracle()
oracle.otworz_polaczenie()
oracle.wywolaj_query(sql)


if len(oracle.df) > 0:
    # print(oracle.df['EMAIL'].unique())
    for ph in oracle.df['EMAIL'].unique():
        wynik = None
        df = oracle.df[oracle.df['EMAIL'] == ph].copy()
        df = df.drop(columns=['EMAIL', 'ZAMOWIENIE_TAB', 'NOWA_DATA_REALIZACJI_PODMIANA'])
        df_string = df[['ODBIORCA', 'NR_ZAPYTANIA_FLOW', 'O_ILE_DNI_ZMIENIONO']].drop_duplicates()
        lista_df = df_string.values.tolist()
        wynik = "<br><br>".join(
        [f"Zamowienie dla {i[0]} o sygnaturze {i[1]} zmieniono o {i[2]} dni" for i in lista_df]
    )

        WyslijMaila(df, email = ph, info = wynik)
oracle.callproc(procedure_name='ZAMOWIENIA_TERMINY_REALIZACJI_P')
oracle.zamknij_polaczenie()