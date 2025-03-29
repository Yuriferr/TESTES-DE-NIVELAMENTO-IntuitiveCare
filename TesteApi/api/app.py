from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import re
from unidecode import unidecode

app = Flask(__name__)
CORS(app)

def normalize_text(text):
    """Remove acentos e converte para minúsculas"""
    if pd.isna(text):
        return ""
    return unidecode(str(text)).lower()

def load_and_clean_data():
    try:
        # Carrega o CSV com tratamento especial
        df = pd.read_csv(
            'Relatorio_cadop.csv',
            sep=';',
            encoding='latin1',
            dtype=str,
            on_bad_lines='skip'
        )
        
        # Normaliza todas as colunas de texto
        text_cols = df.select_dtypes(include=['object']).columns
        for col in text_cols:
            df[col] = df[col].apply(normalize_text)
        
        print("✅ Dados carregados. Colunas disponíveis:", list(df.columns))
        return df
    except Exception as e:
        print("❌ Erro crítico ao carregar dados:", str(e))
        return pd.DataFrame()

df = load_and_clean_data()

@app.route('/buscar', methods=['GET'])
def buscar():
    if df.empty:
        return jsonify({"erro": "Dados não disponíveis"}), 500
    
    termo = normalize_text(request.args.get('termo', ''))
    
    if len(termo) < 2:
        return jsonify({"erro": "Termo deve ter pelo menos 2 caracteres"}), 400
    
    try:
        # Busca flexível em todas as colunas de texto
        mask = df.apply(lambda row: any(
            termo in str(cell) 
            for cell in row 
        ), axis=1)
        
        resultados = df[mask]
        
        return jsonify({
            "termo": termo,
            "total": len(resultados),
            "resultados": resultados.head(50).to_dict('records')
        })
    except Exception as e:
        return jsonify({"erro": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)