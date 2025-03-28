import pandas as pd
import pdfplumber
import zipfile
import os
import re

def extract_table_from_pdf(pdf_path):
    """
    Extrai tabelas de todas as páginas do PDF.
    """
    all_data = []
    
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            # Extrai tabelas da página atual
            tables = page.extract_tables()
            
            for table in tables:
                # Adiciona os dados da tabela à lista geral
                all_data.extend(table)
    
    return all_data

def clean_and_process_data(data):
    """
    Processa os dados extraídos e retorna um DataFrame limpo.
    """
    # Assume que a primeira linha contém os cabeçalhos
    headers = [h.strip() if h else '' for h in data[0]]
    rows = data[1:]
    
    # Cria DataFrame
    df = pd.DataFrame(rows, columns=headers)
    
    # Remove linhas vazias ou inválidas
    df = df.dropna(how='all')
    
    # Limpa os dados em cada coluna
    for col in df.columns:
        df[col] = df[col].apply(lambda x: x.strip() if isinstance(x, str) else x)
    
    return df

def replace_abbreviations(df):
    """
    Substitui as abreviações conforme a legenda fornecida.
    """
    replacements = {
        'OD': 'Seg. Odontológica',
        'AMB': 'Seg. Ambulatorial',
        'HCO': 'Seg. Hospitalar Com Obstetrícia',
        'HSO': 'Seg. Hospitalar Sem Obstetrícia',
        'REF': 'Plano Referência'
    }
    
    # Substitui em todas as colunas
    for col in df.columns:
        if df[col].dtype == 'object':
            for abbrev, full in replacements.items():
                df[col] = df[col].str.replace(abbrev, full)
    
    return df

def save_to_zip(df, zip_filename, csv_filename='dados_extraidos.csv'):
    """
    Salva o DataFrame em CSV e compacta em um arquivo ZIP.
    """
    # Salva CSV temporário
    df.to_csv(csv_filename, index=False, encoding='utf-8-sig')
    
    # Cria arquivo ZIP
    with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
        zipf.write(csv_filename)
    
    # Remove CSV temporário
    os.remove(csv_filename)

def main(pdf_path, seu_nome):
    # Extrai dados do PDF
    raw_data = extract_table_from_pdf(pdf_path)
    
    # Processa os dados
    df = clean_and_process_data(raw_data)
    
    # Substitui abreviações
    df = replace_abbreviations(df)
    
    # Define nome do arquivo ZIP
    zip_filename = f"Teste_{seu_nome}.zip"
    
    # Salva em CSV e compacta
    save_to_zip(df, zip_filename)
    
    print(f"Processo concluído! Arquivo '{zip_filename}' criado com sucesso.")

if __name__ == "__main__":
    # Configurações - altere conforme necessário
    pdf_path = "Anexo_I.pdf"  # Substitua pelo caminho do seu PDF
    seu_nome = "Yuri_Fernandes"  # Substitua pelo seu nome
    
    main(pdf_path, seu_nome)