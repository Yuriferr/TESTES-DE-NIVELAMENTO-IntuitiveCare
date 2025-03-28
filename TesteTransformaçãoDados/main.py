import pandas as pd
import tabula
import os
import warnings

# Configuração para suprimir avisos
warnings.filterwarnings("ignore")

def extrair_dados_pdf(pdf_path):
    """Extrai tabelas do PDF com tratamento robusto"""
    print("Extraindo tabelas do PDF...")
    try:
        # Configurações otimizadas para extração
        dfs = tabula.read_pdf(
            pdf_path,
            pages='all',
            multiple_tables=True,
            lattice=True,
            stream=True,
            guess=False,
            pandas_options={'header': None},
            silent=True
        )
        
        if not dfs:
            print("Nenhuma tabela encontrada no PDF.")
            return None
            
        # Combinar todas as tabelas encontradas (caso estejam divididas por páginas)
        df = pd.concat(dfs, ignore_index=True)
        return df
        
    except Exception as e:
        print(f"Erro na extração: {str(e)}")
        return None

def processar_tabela(df):
    """Processa a tabela conforme requisitos específicos"""
    if df is None:
        return None

    print("Processando tabela...")
    
    # Verificar se temos dados suficientes
    if len(df) < 2:
        print("Tabela com poucos dados - possível erro na extração")
        return None
    
    # Definir cabeçalhos corretos (assumindo que a primeira linha contém os cabeçalhos)
    df.columns = df.iloc[0].astype(str).str.strip()
    df = df[1:].reset_index(drop=True)
    
    # Substituir apenas as colunas especificadas
    df = df.rename(columns={
        'OD': 'Seg. Odontológica',
        'AMB': 'Seg. Ambulatorial'
    })
    
    # Limpeza básica dos dados
    df = df.apply(lambda x: x.str.strip() if x.dtype == 'object' else x)
    
    return df

def salvar_csv(df, nome_arquivo="Rol_Procedimentos.csv"):
    """Salva o DataFrame em CSV com substituição do arquivo existente"""
    if df is None or df.empty:
        print("Nenhum dado válido para salvar!")
        return False

    try:
        # Configurações para CSV bem formatado
        df.to_csv(
            nome_arquivo,
            index=False,
            header=True,
            encoding='utf-8-sig',
            sep=',',
            quotechar='"',
            quoting=1
        )
        
        print(f"Arquivo CSV sobrescrito com sucesso: {nome_arquivo}")
        print(f"Local: {os.path.abspath(nome_arquivo)}")
        return True
        
    except Exception as e:
        print(f"Erro ao salvar CSV: {str(e)}")
        return False

def main():
    pdf_local = "Anexo_I.pdf"  # Nome do seu arquivo PDF
    
    if not os.path.exists(pdf_local):
        print(f"Erro: Arquivo {pdf_local} não encontrado na pasta atual!")
        print("Certifique-se de que:")
        print(f"1. O arquivo PDF está na mesma pasta do script")
        print(f"2. O nome do arquivo é exatamente '{pdf_local}'")
        return

    # Extrair e processar dados
    tabela = extrair_dados_pdf(pdf_local)
    tabela_processada = processar_tabela(tabela)
    
    # Salvar CSV (substituindo se existir)
    salvar_csv(tabela_processada)

if __name__ == "__main__":
    main()