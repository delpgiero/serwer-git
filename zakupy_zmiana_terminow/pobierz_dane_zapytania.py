import pyodbc
import pandas as pd
from classes.oracle import PolaczenieOracle

# warnings.simplefilter(action='ignore', category=FutureWarning)


def flow():
    def DaneMSSQL(sql_query):
        server = "mssql1"
        database = ""
        username = "DWS"
        password = "az2qe3M9SR"
        driver = "{ODBC Driver 17 for SQL Server}"  # zrob odbc

        conn_str = f"DRIVER={driver};SERVER={server};DATABASE={database};UID={username};PWD={password}"

        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        cursor.execute(sql_query)

        rows = cursor.fetchall()
        data = []
        for row in rows:
            data.append(list(row))

        col_names = []
        for i in range(0, len(cursor.description)):
            col_names.append(cursor.description[i][0])

        cursor.close()
        conn.close()
        df = pd.DataFrame(data, columns=col_names)
        return df

    sql_query = """SELECT  distinct WFH_Signature sygnatura,
SUBSTRING(WFH_AttChoose6, CHARINDEX('#', WFH_AttChoose6) + 1, LEN(WFH_AttChoose6)) as odbiorca
  FROM [WEBCON-PRD-DB].[BPS_Content].[dbo].[WFHistoryElements]
WHERE 
        WFH_DTYPEID = '36'
		AND WFH_TSInsert >= DATEADD(DAY, -900, GETDATE())
		and SUBSTRING(SUBSTRING(WFH_AttChoose6, CHARINDEX('#', WFH_AttChoose6) + 1, LEN(WFH_AttChoose6)),4,1) IN ('1','2')"""

    
    df = DaneMSSQL(sql_query)
    # df = df.assign(NR_ZAMOW=df["NR_ZAMOW"].str.split(",")).explode("NR_ZAMOW")
    # df["NR_ZAMOW"] = df["NR_ZAMOW"].str.replace(r".*?#", "", regex=True)
    # df["NR_ZAMOW"] = df["NR_ZAMOW"].str.strip()
    # df["PRZYPISANE"] = " "
    df = df.drop_duplicates()
    df.columns = [col.upper() for col in df.columns]
    print(df)

    oracle = PolaczenieOracle(tabela="ZAPYTANIE_TOWAR_PRZYPISANIE")
    oracle.otworz_polaczenie()
    oracle.usun_dane_tabela()
    oracle.wgraj_do_bazy(df)
    oracle.zamknij_polaczenie()
flow()