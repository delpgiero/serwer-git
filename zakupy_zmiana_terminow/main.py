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
        df = oracle.df[oracle.df['EMAIL'] == ph].copy()
        df = df.drop(columns=['EMAIL', 'ZAMOWIENIE_TAB', 'NOWA_DATA_REALIZACJI_PODMIANA'])
        WyslijMaila(df, email = ph)
oracle.callproc(procedure_name='ZAMOWIENIA_TERMINY_REALIZACJI_P')
oracle.zamknij_polaczenie()