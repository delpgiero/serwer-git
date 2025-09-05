from datetime import date
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
import pandas as pd
import time

# from pretty_html_table import build_table

def build_table(df, theme, title):
    # Style
    table_style = 'border-collapse: collapse; width: 100%; font-size: 14px;'
    th_style = 'background-color: #f7931e; color: white; text-align: left; padding: 8px; white-space: nowrap; border: 1px solid #ddd;'
    td_style = 'padding: 8px; border: 1px solid #ddd; text-align: left; white-space: nowrap;'
    title_style = 'font-size: 18px; font-weight: bold; margin: 20px 0 10px 0;'

    def format_value(val, col_index):
        """Formatuje wartość - bez separatorów tysięcy"""
        return val

    # HTML składanie
    html = f'<p style="{title_style}">{title}</p>'
    html += f'<table style="{table_style}">'

    # Nagłówki
    html += '<tr>'
    for col in df.columns:
        html += f'<th style="{th_style}">{col}</th>'
    html += '</tr>'

    # Wiersze danych
    for _, row in df.iterrows():
        html += '<tr>'
        for i, val in enumerate(row):
            formatted_val = format_value(val, i)
            html += f'<td style="{td_style}">{formatted_val}</td>'
        html += '</tr>'

    html += '</table>'
    return html



def WyslijMaila(df_1, email):
    today = date.today()
    sender_email = 'analizy_@marcopol.pl'
    sender_password = 'analizy1'
    receiver_email = f"[{email}]"
    # receiver_email = ['patryk.gajda@marcopol.pl']
    subject = f'Zmiana terminu realizacji zamówienia w dniu: {today}'
    message = f"""
    <!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Raport</title>
</head>
<body style="font-family: Arial, sans-serif; margin: 20px;">
    <p>Witam,</p>
    
    <p>W tabeli poniżej znajdują się dane dotyczące zmian terminów zamówień zakupowych. Dane z dnia: {today}.</p>
    
    
    
    <br><br>
    
    <br>
    {build_table(df_1, 'orange_dark', 'Szczegółowe dane opóźnionych zamówień')}
    <hr>
    
    <p style="font-size: 12px;">
        W razie pytań dotyczących opóźnień, bardzo proszę o kontakt z pracownikiem zakupów wymienionym w tabeli.<br>
        Pozdrawiamy, Dział Analiz i Polityki Cenowej
    </p>

</body>
</html>
"""

    msg = MIMEMultipart()
    msg['From'] = sender_email
    msg['To'] = ', '.join(receiver_email)
    msg['Subject'] = subject
    msg['Bcc'] = 'patryk.gajda@marcopol.pl'
    msg.attach(MIMEText(message, 'html'))
    wyslano = False
    while not wyslano:
        try:
            server = smtplib.SMTP('smtp.office365.com', 587)
            server.ehlo()
            server.starttls()
            server.login(sender_email, sender_password)
            text = msg.as_string()
            server.sendmail(sender_email, receiver_email, text)
            server.quit()
            print('Mail zostal wyslany')
            wyslano = True
        except Exception as e:
            # pass
            print('Wystapil blad podczas wysylania: ', e)
            time.sleep(5)