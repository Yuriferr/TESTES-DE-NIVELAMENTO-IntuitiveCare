-- =============================================
-- CONFIGURAÇÕES INICIAIS
-- =============================================

-- Habilita importação de arquivos locais (necessário para LOAD DATA)
SET GLOBAL local_infile = 1;

-- Verifica se a opção está ativada
SHOW GLOBAL VARIABLES LIKE 'local_infile';

-- =============================================
-- CRIAÇÃO DO BANCO DE DADOS E TABELAS
-- =============================================

-- Remove o banco se já existir e cria novo
DROP DATABASE IF EXISTS ans_analysis;
CREATE DATABASE ans_analysis CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE ans_analysis;

-- Tabela de operadoras (dados cadastrais)
CREATE TABLE operadoras (
    registro_ans VARCHAR(20) PRIMARY KEY,  -- Código único da operadora
    cnpj VARCHAR(20),                     -- CNPJ da operadora
    razao_social VARCHAR(255),            -- Nome legal da empresa
    nome_fantasia VARCHAR(255),           -- Nome comercial
    modalidade VARCHAR(100),              -- Tipo de operadora
    logradouro VARCHAR(255),              -- Endereço
    numero VARCHAR(20),                   -- Número do endereço
    complemento VARCHAR(100),             -- Complemento
    bairro VARCHAR(100),                  -- Bairro
    cidade VARCHAR(100),                  -- Cidade
    uf VARCHAR(2),                       -- Estado (sigla)
    cep VARCHAR(10),                     -- CEP
    ddd VARCHAR(5),                      -- DDD
    telefone VARCHAR(20),                -- Telefone
    fax VARCHAR(20),                     -- Fax
    endereco_eletronico VARCHAR(100),    -- Email
    representante VARCHAR(100),          -- Nome do responsável
    cargo_representante VARCHAR(100),    -- Cargo do responsável
    regiao_de_comercializacao VARCHAR(10), -- Região de atuação
    data_registro_ans DATE               -- Data de registro na ANS
);

-- Tabela de demonstrações contábeis
CREATE TABLE demonstracoes_contabeis (
    id INT AUTO_INCREMENT PRIMARY KEY,    -- ID automático
    data DATE,                           -- Data do registro
    registro_ans VARCHAR(20),            -- Código da operadora
    conta_contabil VARCHAR(20),          -- Código da conta contábil
    descricao VARCHAR(255),              -- Descrição da conta
    valor_saldo_inicial DECIMAL(15,2),   -- Saldo inicial
    valor_saldo_final DECIMAL(15,2),     -- Saldo final
    FOREIGN KEY (registro_ans) REFERENCES operadoras(registro_ans)
) ENGINE=InnoDB;

-- =============================================
-- IMPORTAÇÃO DOS DADOS
-- =============================================

-- Importa dados cadastrais (ajuste o caminho do arquivo)
LOAD DATA LOCAL INFILE 'C:/Projetos/TESTES-DE-NIVELAMENTO-IntuitiveCare/TesteBancoDeDados/Dados/Relatorio_cadop.csv'
INTO TABLE operadoras
CHARACTER SET latin1                     -- Define codificação de caracteres
FIELDS TERMINATED BY ';'                -- Campos separados por ;
ENCLOSED BY '"'                         -- Texto entre aspas
LINES TERMINATED BY '\r\n'              -- Linhas terminam com \r\n
IGNORE 1 ROWS                           -- Ignora cabeçalho
(registro_ans, cnpj, razao_social, nome_fantasia, modalidade, logradouro, 
 numero, complemento, bairro, cidade, uf, cep, ddd, telefone, fax, 
 endereco_eletronico, representante, cargo_representante, 
 regiao_de_comercializacao, @data_registro_ans)
SET data_registro_ans = STR_TO_DATE(@data_registro_ans, '%Y-%m-%d');  -- Converte data

-- Importa dados contábeis (ajuste o caminho do arquivo)
LOAD DATA LOCAL INFILE 'C:/Projetos/TESTES-DE-NIVELAMENTO-IntuitiveCare/TesteBancoDeDados/Dados/1T2023.csv'
INTO TABLE demonstracoes_contabeis
CHARACTER SET latin1
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@data, registro_ans, conta_contabil, descricao, valor_saldo_inicial, valor_saldo_final)
SET data = STR_TO_DATE(@data, '%Y-%m-%d');  -- Converte data

-- =============================================
-- ÍNDICES PARA MELHOR PERFORMANCE
-- =============================================

CREATE INDEX idx_conta_contabil ON demonstracoes_contabeis(conta_contabil);
CREATE INDEX idx_descricao ON demonstracoes_contabeis(descricao);
CREATE INDEX idx_data ON demonstracoes_contabeis(data);
CREATE INDEX idx_registro_ans ON demonstracoes_contabeis(registro_ans);

-- =============================================
-- CONSULTAS ANALÍTICAS
-- =============================================

-- 1. Top 10 operadoras com maiores despesas em sinistros médicos
SELECT 
    o.razao_social AS 'Razão Social',
    o.nome_fantasia AS 'Nome Fantasia',
    o.registro_ans AS 'Registro ANS',
    CONCAT('R$ ', FORMAT(SUM(d.valor_saldo_final - d.valor_saldo_inicial), 2)) AS 'Total Despesas',
    COUNT(*) AS 'Qtd. Registros'
FROM 
    demonstracoes_contabeis d
JOIN 
    operadoras o ON d.registro_ans = o.registro_ans
WHERE 
    (d.descricao LIKE '%EVENTOS/ SINISTROS CONHECIDOS OU AVISADOS DE ASSISTÊNCIA A SAÚDE MEDICO HOSPITALAR%'
    OR d.descricao LIKE '%EVENTOS\\ SINISTROS CONHECIDOS OU AVISADOS DE ASSISTÊNCIA A SAÚDE MEDICO HOSPITALAR%')
GROUP BY 
    o.razao_social, o.nome_fantasia, o.registro_ans
ORDER BY 
    SUM(d.valor_saldo_final - d.valor_saldo_inicial) DESC
LIMIT 10;

-- 2. Estatísticas gerais do banco de dados
SELECT 
    COUNT(DISTINCT registro_ans) AS 'Total Operadoras',
    MIN(data) AS 'Data Mais Antiga',
    MAX(data) AS 'Data Mais Recente',
    COUNT(*) AS 'Total Registros Contábeis'
FROM 
    demonstracoes_contabeis;

-- 3. Contagem de operadoras por estado (UF)
SELECT 
    uf AS 'Estado',
    COUNT(*) AS 'Quantidade de Operadoras'
FROM 
    operadoras
GROUP BY 
    uf
ORDER BY 
    COUNT(*) DESC;

-- =============================================
-- PROCEDURE PARA RELATÓRIO COMPLETO
-- =============================================

DELIMITER //
CREATE PROCEDURE gerar_relatorio_completo()
BEGIN
    -- Cabeçalho
    SELECT '=== TOP 10 OPERADORAS COM MAIORES DESPESAS EM SINISTROS ===' AS relatorio;
    
    -- Top 10
    SELECT 
        razao_social AS 'Razão Social',
        nome_fantasia AS 'Nome Fantasia',
        registro_ans AS 'Registro ANS',
        CONCAT('R$ ', FORMAT(SUM(valor_saldo_final - valor_saldo_inicial), 2)) AS 'Total Despesas'
    FROM 
        demonstracoes_contabeis d
    JOIN 
        operadoras o ON d.registro_ans = o.registro_ans
    WHERE 
        descricao LIKE '%SINISTROS%ASSISTÊNCIA%SAÚDE%'
    GROUP BY 
        registro_ans, razao_social, nome_fantasia
    ORDER BY 
        SUM(valor_saldo_final - valor_saldo_inicial) DESC
    LIMIT 10;
    
    -- Estatísticas
    SELECT '=== ESTATÍSTICAS GERAIS ===' AS relatorio;
    SELECT 
        COUNT(DISTINCT o.registro_ans) AS 'Total Operadoras',
        MIN(d.data) AS 'Data Mais Antiga',
        MAX(d.data) AS 'Data Mais Recente',
        CONCAT('R$ ', FORMAT(SUM(d.valor_saldo_final - d.valor_saldo_inicial), 2)) AS 'Volume Financeiro Total'
    FROM 
        demonstracoes_contabeis d
    JOIN 
        operadoras o ON d.registro_ans = o.registro_ans;
END //
DELIMITER ;

-- =============================================
-- COMO USAR:
-- 1. Execute todo este script no MySQL
-- 2. Para gerar relatório: CALL gerar_relatorio_completo();
-- 3. Verifique os caminhos dos arquivos CSV
-- =============================================