import cx_Oracle
import pandas as pd
from dotenv import load_dotenv
import os


class PolaczenieOracle:
    def __init__(self, tabela=None) -> None:
        env_path = r".env"
        load_dotenv(dotenv_path=env_path)
        self.IP = os.getenv("ORACLE_IP")
        self.PORT = os.getenv("ORACLE_PORT")
        self.SERVICE_NAME = os.getenv("ORACLE_SERVICE_NAME")
        self.USERNAME = os.getenv("ORACLE_USERNAME")
        self.PASSWORD = os.getenv("ORACLE_PASSWORD")
        self.tabela = tabela

    def otworz_polaczenie(self):
        self.dsn_tns = cx_Oracle.makedsn(
            self.IP, self.PORT, service_name=self.SERVICE_NAME
        )
        self.connection = cx_Oracle.connect(
            user=self.USERNAME, password=self.USERNAME, dsn=self.dsn_tns
        )
        self.cursor = self.connection.cursor()

    def zamknij_polaczenie(self):
        self.cursor.close()
        self.connection.close()

    def wywolaj_query(self, sql_query):
        self.cursor.execute("ALTER SESSION SET NLS_TERRITORY = 'POLAND'")

        self.cursor.execute(sql_query)
        data = self.cursor.fetchall()
        col_names = [
            self.cursor.description[i][0] for i in range(len(self.cursor.description))
        ]
        self.df = pd.DataFrame(data, columns=col_names)

    def wgraj_do_bazy(self, df):
        self.res = []
        data = [tuple(x) for x in df.values]
        # Tworzenie placeholderów do zapytania SQL
        placeholders = ", ".join([":" + str(i + 1) for i in range(len(df.columns))])
        batch_size = 10000
        # Iteracja przez dane w partiach
        for i in range(0, len(data), batch_size):
            batch = data[i : i + batch_size]
            for row in batch:
                try:
                    # Próba wstawienia pojedynczego wiersza
                    self.cursor.execute(
                        f"INSERT INTO {self.tabela} ({', '.join(df.columns)}) VALUES ({placeholders})",
                        row,
                    )
                    self.res.append(1)
                except Exception as e:
                    self.res.append(0)
                    # Ignorowanie błędu unikalności
                    if "unique constraint" in str(e).lower():

                        continue
                    else:
                        # Przerzucenie innych błędów
                        raise e
            self.connection.commit()

    def usun_dane_tabela(self):
        sql_query = f"DELETE FROM {self.tabela}"
        self.cursor.execute(sql_query)
        self.connection.commit()

    def callproc(self, procedure_name, parameters=None):
        """
        Wywołuje procedurę składowaną w Oracle.
        
        Args:
            procedure_name (str): Nazwa procedury do wywołania
            parameters (list, optional): Lista parametrów do przekazania do procedury
            
        Returns:
            list: Lista wyników zwróconych przez procedurę (jeśli są parametry OUT)
            
        Example:
            # Procedura bez parametrów
            oracle.callproc('ZAMOWIENIA_TERMINY_REALIZACJI_P')
            
            # Procedura z parametrami IN
            oracle.callproc('MOJA_PROCEDURA', ['param1', 'param2'])
            
            # Procedura z parametrami IN i OUT
            out_param = oracle.cursor.var(cx_Oracle.STRING)
            oracle.callproc('PROCEDURA_Z_OUT', ['input_param', out_param])
            result = out_param.getvalue()
        """
        try:
            if parameters is None:
                # Procedura bez parametrów
                result = self.cursor.callproc(procedure_name)
            else:
                # Procedura z parametrami
                result = self.cursor.callproc(procedure_name, parameters)
            
            self.connection.commit()
            return result
            
        except Exception as e:
            self.connection.rollback()
            raise Exception(f"Błąd podczas wywoływania procedury {procedure_name}: {str(e)}")