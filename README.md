# TESTES-DE-NIVELAMENTO-IntuitiveCare
Este repositório contém vários projetos relacionados a testes de API, banco de dados e transformação de dados. Abaixo estão as instruções para executar cada um deles.

## Pré-requisitos
- Python 3.x
- Node.js (para a parte web)
- pip (gerenciador de pacotes Python)
- npm (gerenciador de pacotes Node.js)

## Instalação e Execução

### 1. TesteApi (Backend)
```bash
cd TesteApi
python -m venv venv
source venv/bin/activate  # No Windows: venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

### 2. TesteApi (Frontend)
```bash
cd TesteApi/web
npm install
npm run dev
```

### 3. TesteBancoDeDados
```bash
cd TesteBancoDeDados
# Execute o arquivo dados.sql em seu SGBD (MySQL, PostgreSQL, etc.)
# Ou use o main.py se houver scripts Python para o banco de dados
```

### 4. TesteTransformaçãoDados
```bash
cd TesteTransformaçãoDados
python -m venv venv
source venv/bin/activate  # No Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

## Arquivos Importantes
- `Postaman.txt`: Contém informações sobre as requisições da API
- `Relatorio_cadop.csv`: Arquivo de dados para os testes
- `Anexo_Lpdf` e `Anexos.zip`: Documentação adicional