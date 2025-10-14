from datetime import date
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
import pandas as pd

# from pretty_html_table import build_table

def build_table(df, theme, title):
    # Style
    table_style = 'border-collapse: collapse; width: 100%; font-size: 14px;'
    th_style = 'background-color: #f7931e; color: white; text-align: left; padding: 8px; white-space: nowrap; border: 1px solid #ddd;'
    td_style = 'padding: 8px; border: 1px solid #ddd; text-align: left; white-space: nowrap;'
    title_style = 'font-size: 18px; font-weight: bold; margin: 20px 0 10px 0;'

    def format_number(val, col_index):
        """Formatuje wartość liczbową z separatorem tysięcy dla kolumn od 2"""
        if col_index == 0:  # Pierwsza kolumna bez formatowania
            return val
        
        # Sprawdź czy to liczba
        if isinstance(val, (int, float)) and not pd.isna(val):
            # Dla liczb całkowitych
            if isinstance(val, int) or val.is_integer():
                return f"{int(val):,}".replace(',', ' ')
            else:
                # Dla liczb z częścią dziesiętną - zachowaj oryginalną precyzję
                return f"{val:,}".replace(',', ' ')
        elif isinstance(val, str) and val.replace('.', '').replace('-', '').isdigit():
            try:
                num = float(val)
                if num.is_integer():
                    return f"{int(num):,}".replace(',', ' ')
                else:
                    return f"{num:,}".replace(',', ' ')
            except:
                return val
        else:
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
            formatted_val = format_number(val, i)
            html += f'<td style="{td_style}">{formatted_val}</td>'
        html += '</tr>'

    html += '</table>'
    return html



def WyslijMaila(today, path, df_1, kwartal):
    today = date.today()
    sender_email = 'analizy_@marcopol.pl'
    sender_password = 'analizy1'
    receiver_email = ['wtorek.m@marcopol.pl', 'blonski.k@marcopol.pl']
    # receiver_email = ['patryk.gajda@marcopol.pl']
    subject = f'Dane Majster cennik M24 Marcopol: {today}'
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
    
    <p>W załączniku znajdują się materiały i ich ceny z platformy Marcopol24.</p>
    
    <br><br>
    
    <br>
   
    <hr>
    
    <p style="font-size: 12px;">
        
        Pozdrawiamy, Dział Analiz i Polityki Cenowej
    </p>

</body>
</html>
"""

    with open(path, 'rb') as f:
        attachment = f.read()
    msg = MIMEMultipart()
    msg['From'] = sender_email
    msg['To'] = ', '.join(receiver_email)
    msg['Subject'] = subject
    msg.attach(MIMEText(message, 'html'))
    part = MIMEBase('application', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    part.set_payload(attachment)
    encoders.encode_base64(part)
    filename = f"MAJSTER_CENNIK_{kwartal}.xlsx"
    part.add_header('Content-Disposition', f'attachment; filename="{filename}"; name="{filename}"')
    part.add_header('Content-Type', f'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet; name="{filename}"')

    msg.attach(part)

    try:
        server = smtplib.SMTP('smtp.office365.com', 587)
        server.ehlo()
        server.starttls()
        server.login(sender_email, sender_password)
        text = msg.as_string()
        server.sendmail(sender_email, receiver_email, text)
        server.quit()
        print('Mail zostal wyslany')
    except Exception as e:
        # pass
        print('Wystapil blad podczas wysylania: ', e)