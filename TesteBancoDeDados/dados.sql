-- =============================================
-- CONFIGURAÇÕES INICIAIS
-- =============================================
SET GLOBAL local_infile = 1;

-- =============================================
-- CRIAÇÃO DO BANCO DE DADOS E TABELAS (Tarefa 3.3)
-- =============================================
DROP DATABASE IF EXISTS ans_analysis;
CREATE DATABASE ans_analysis CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE ans_analysis;

-- Tabela de operadoras (dados cadastrais)
CREATE TABLE operadoras (
    registro_ans VARCHAR(20) PRIMARY KEY,
    cnpj VARCHAR(20),
    razao_social VARCHAR(255),
    nome_fantasia VARCHAR(255),
    modalidade VARCHAR(100),
    uf VARCHAR(2)  -- Mantido apenas campos relevantes para as análises
);

-- Tabela de demonstrações contábeis
CREATE TABLE demonstracoes_contabeis (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data DATE,
    registro_ans VARCHAR(20),
    conta_contabil VARCHAR(20),
    descricao VARCHAR(255),
    valor_saldo_inicial DECIMAL(15,2),
    valor_saldo_final DECIMAL(15,2),
    FOREIGN KEY (registro_ans) REFERENCES operadoras(registro_ans)
) ENGINE=InnoDB;

-- =============================================
-- IMPORTAÇÃO DOS DADOS (Tarefa 3.4)
-- =============================================

-- Importa dados cadastrais (ajuste o caminho do arquivo)
LOAD DATA LOCAL INFILE 'C:/Projetos/TESTES-DE-NIVELAMENTO-IntuitiveCare/TesteBancoDeDados/Dados/Relatorio_cadop.csv'
INTO TABLE operadoras
CHARACTER SET latin1
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(registro_ans, cnpj, razao_social, nome_fantasia, modalidade, @ignored1, @ignored2, @ignored3, @ignored4, @ignored5, uf, @ignored6, @ignored7, @ignored8, @ignored9, @ignored10, @ignored11, @ignored12, @ignored13, @ignored14);

-- Importa dados contábeis (ajuste o caminho do arquivo)
LOAD DATA LOCAL INFILE 'C:/Projetos/TESTES-DE-NIVELAMENTO-IntuitiveCare/TesteBancoDeDados/Dados/1T2023.csv'
INTO TABLE demonstracoes_contabeis
CHARACTER SET latin1
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@data, registro_ans, conta_contabil, descricao, valor_saldo_inicial, valor_saldo_final)
SET data = STR_TO_DATE(@data, '%Y-%m-%d');

-- =============================================
-- ÍNDICES PARA MELHOR PERFORMANCE
-- =============================================
CREATE INDEX idx_descricao_sinistros ON demonstracoes_contabeis(descricao(100));
CREATE INDEX idx_data ON demonstracoes_contabeis(data);
CREATE INDEX idx_registro_ans ON demonstracoes_contabeis(registro_ans);

-- =============================================
-- CONSULTAS ANALÍTICAS (Tarefa 3.5)
-- =============================================

-- 1. Top 10 operadoras com maiores despesas em sinistros médicos no último trimestre
SELECT 
    o.razao_social AS 'Razão Social',
    o.nome_fantasia AS 'Nome Fantasia',
    o.uf AS 'UF',
    FORMAT(SUM(d.valor_saldo_final - d.valor_saldo_inicial), 2) AS 'Total Despesas (R$)',
    COUNT(*) AS 'Qtd. Registros'
FROM 
    demonstracoes_contabeis d
JOIN 
    operadoras o ON d.registro_ans = o.registro_ans
WHERE 
    d.descricao LIKE '%EVENTOS/ SINISTROS CONHECIDOS OU AVISADOS DE ASSISTÊNCIA A SAÚDE MEDICO HOSPITALAR%'
    AND d.data >= DATE_SUB((SELECT MAX(data) FROM demonstracoes_contabeis), INTERVAL 3 MONTH)
GROUP BY 
    o.registro_ans, o.razao_social, o.nome_fantasia, o.uf
ORDER BY 
    SUM(d.valor_saldo_final - d.valor_saldo_inicial) DESC
LIMIT 10;

-- 2. Top 10 operadoras com maiores despesas em sinistros médicos no último ano
SELECT 
    o.razao_social AS 'Razão Social',
    o.nome_fantasia AS 'Nome Fantasia',
    o.uf AS 'UF',
    FORMAT(SUM(d.valor_saldo_final - d.valor_saldo_inicial), 2) AS 'Total Despesas (R$)',
    COUNT(*) AS 'Qtd. Registros'
FROM 
    demonstracoes_contabeis d
JOIN 
    operadoras o ON d.registro_ans = o.registro_ans
WHERE 
    d.descricao LIKE '%EVENTOS/ SINISTROS CONHECIDOS OU AVISADOS DE ASSISTÊNCIA A SAÚDE MEDICO HOSPITALAR%'
    AND d.data >= DATE_SUB((SELECT MAX(data) FROM demonstracoes_contabeis), INTERVAL 1 YEAR)
GROUP BY 
    o.registro_ans, o.razao_social, o.nome_fantasia, o.uf
ORDER BY 
    SUM(d.valor_saldo_final - d.valor_saldo_inicial) DESC
LIMIT 10;
