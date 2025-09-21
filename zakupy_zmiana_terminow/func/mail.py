from datetime import date
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
import pandas as pd
import time

def build_table(df, theme, title):
    """Tworzy responsywną tabelę HTML - oryginalny wygląd na PC, responsive na mobile"""
    
    # Style CSS z media queries dla responsywności
    responsive_styles = """
    <style>
        /* Style podstawowe - zachowujemy oryginalny wygląd */
        .table-title {
            font-size: 18px;
            font-weight: bold;
            margin: 20px 0 10px 0;
        }
        
        .responsive-table {
            border-collapse: collapse;
            width: 100%;
            font-size: 14px;
        }
        
        .responsive-table th {
            background-color: #f7931e;
            color: white;
            text-align: left;
            padding: 8px;
            white-space: nowrap;
            border: 1px solid #ddd;
        }
        
        .responsive-table td {
            padding: 8px;
            border: 1px solid #ddd;
            text-align: left;
            white-space: nowrap;
        }
        
        /* Layout kartowy - domyślnie ukryty */
        .mobile-card-layout {
            display: none;
        }
        
        /* Style dla urządzeń mobilnych */
        @media only screen and (max-width: 600px) {
            .table-title {
                font-size: 16px;
                text-align: center;
                margin: 15px 0 8px 0;
            }
            
            .responsive-table {
                font-size: 12px;
                display: block;
                overflow-x: auto;
                white-space: nowrap;
                -webkit-overflow-scrolling: touch;
            }
            
            .responsive-table th,
            .responsive-table td {
                padding: 6px 4px;
                min-width: 80px;
            }
        }
        
        /* Layout kartowy tylko dla bardzo małych ekranów */
        @media only screen and (max-width: 480px) {
            .responsive-table {
                display: none !important;
            }
            
            .mobile-card-layout {
                display: block !important;
            }
            
            .card {
                background: white;
                margin: 10px 0;
                padding: 15px;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                border-left: 4px solid #f7931e;
            }
            
            .card-row {
                margin: 8px 0;
                padding: 4px 0;
                border-bottom: 1px solid #eee;
            }
            
            .card-row:last-child {
                border-bottom: none;
            }
            
            .card-label {
                font-weight: bold;
                color: #f7931e;
                font-size: 12px;
                text-transform: uppercase;
                margin-bottom: 2px;
            }
            
            .card-value {
                font-size: 14px;
                color: #333;
            }
        }
    </style>
    """
    
    def format_value(val, col_index):
        """Formatuje wartość - bez separatorów tysięcy"""
        return str(val) if val is not None else ""
    
    # HTML z responsywnymi stylami
    html = responsive_styles
    html += f'<p class="table-title">{title}</p>'
    
    # Tabela standardowa (widoczna na większych ekranach)
    html += f'<table class="responsive-table">'
    
    # Nagłówki
    html += '<tr>'
    for col in df.columns:
        html += f'<th>{col}</th>'
    html += '</tr>'
    
    # Wiersze danych
    for _, row in df.iterrows():
        html += '<tr>'
        for i, val in enumerate(row):
            formatted_val = format_value(val, i)
            html += f'<td>{formatted_val}</td>'
        html += '</tr>'
    
    html += '</table>'
    
    # Layout kartowy dla bardzo małych ekranów (< 480px)
    html += '<div class="mobile-card-layout">'
    for idx, row in df.iterrows():
        html += '<div class="card">'
        for col_name, val in row.items():
            formatted_val = format_value(val, 0)
            html += f'<div class="card-row">'
            html += f'<div class="card-label">{col_name}:</div>'
            html += f'<div class="card-value">{formatted_val}</div>'
            html += '</div>'
        html += '</div>'
    html += '</div>'
    
    return html


def WyslijMaila(df_1, email, info):
    today = date.today()
    sender_email = 'analizy_@marcopol.pl'
    sender_password = 'analizy1'
    receiver_email = f"{email}"
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
        <strong>{info}</strong>
        
        {build_table(df_1, 'orange_dark', 'Szczegóły opóźnionych zamówień')}
        
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
    msg['To'] = email
    msg['Subject'] = subject
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
            print('Wystapil blad podczas wysylania: ', e)
            time.sleep(5)

