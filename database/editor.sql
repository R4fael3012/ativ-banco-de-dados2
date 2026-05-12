--database: ./db.sqlite

CREATE TABLE cliente (
    id_cliente SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email dm_email UNIQUE NOT NULL, 
    telefone dm_telefone,
    cpf dm_cpf UNIQUE,
    cnpj dm_cnpj UNIQUE,
    tipo_pessoa CHAR(2) NOT NULL CHECK (tipo_pessoa IN ('PF', 'PJ')),
    
    CONSTRAINT ck_documento_valido CHECK (
        (tipo_pessoa = 'PF' AND cpf IS NOT NULL AND cnpj IS NULL) OR
        (tipo_pessoa = 'PJ' AND cnpj IS NOT NULL AND cpf IS NULL)
    )
);


CREATE TABLE veiculo (
    id_veiculo SERIAL PRIMARY KEY,
    id_cliente INTEGER NOT NULL REFERENCES cliente(id_cliente),
    placa dm_placa UNIQUE NOT NULL,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    ano_fabricacao INTEGER NOT NULL,
    cor VARCHAR(30)
);


CREATE TABLE funcionario (
    id_funcionario SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    especialidade VARCHAR(50),
    salario NUMERIC(12,2) NOT NULL CHECK (salario > 0) 
);


CREATE TABLE tipo_servico (
    id_tipo_servico SERIAL PRIMARY KEY,
    descricao VARCHAR(100) NOT NULL,
    preco_base NUMERIC(12,2) NOT NULL CHECK (preco_base >= 0),
    tempo_estimado_minutos INTEGER NOT NULL
);


CREATE TABLE peca (
    id_peca SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    fornecedor VARCHAR(100),
    quantidade_atual INTEGER NOT NULL DEFAULT 0,
    quantidade_minima INTEGER NOT NULL DEFAULT 0,
    preco_unitario NUMERIC(12,2) NOT NULL CHECK (preco_unitario >= 0),
    
    CONSTRAINT ck_estoque_positivo CHECK (quantidade_atual >= 0)
);


CREATE TABLE agendamento (
    id_agendamento SERIAL PRIMARY KEY,
    id_veiculo INTEGER NOT NULL REFERENCES veiculo(id_veiculo),
    data_abertura TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_conclusao TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'Agendado' 
        CHECK (status IN ('Agendado', 'Em andamento', 'Concluído', 'Cancelado', 'No-show')),
    km_entrada INTEGER NOT NULL CHECK (km_entrada >= 0),
    km_saida INTEGER,
    total_mao_de_obra NUMERIC(12,2) DEFAULT 0,
    total_pecas NUMERIC(12,2) DEFAULT 0,
    
    CONSTRAINT ck_datas_coerentes CHECK (data_conclusao IS NULL OR data_conclusao >= data_abertura),
    CONSTRAINT ck_km_coerente CHECK (km_saida IS NULL OR km_saida >= km_entrada)
);


CREATE TABLE item_servico (
    id_item_servico SERIAL PRIMARY KEY,
    id_agendamento INTEGER NOT NULL REFERENCES agendamento(id_agendamento),
    id_tipo_servico INTEGER NOT NULL REFERENCES tipo_servico(id_tipo_servico),
    id_funcionario INTEGER NOT NULL REFERENCES funcionario(id_funcionario),
    quantidade INTEGER NOT NULL DEFAULT 1 CHECK (quantidade > 0),
    preco_unitario NUMERIC(12,2) NOT NULL,
    desconto_percentual NUMERIC(5,2) DEFAULT 0 CHECK (desconto_percentual BETWEEN 0 AND 100),
    
    total_item NUMERIC(12,2) GENERATED ALWAYS AS (
        (quantidade * preco_unitario) * (1 - desconto_percentual / 100)
    ) STORED
);


CREATE TABLE item_peca (
    id_item_peca SERIAL PRIMARY KEY,
    id_agendamento INTEGER NOT NULL REFERENCES agendamento(id_agendamento),
    id_peca INTEGER NOT NULL REFERENCES peca(id_peca),
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(12,2) NOT NULL,
    desconto_percentual NUMERIC(5,2) DEFAULT 0 CHECK (desconto_percentual BETWEEN 0 AND 100),
    
    total_item NUMERIC(12,2) GENERATED ALWAYS AS (
        (quantidade * preco_unitario) * (1 - desconto_percentual / 100)
    ) STORED
);


CREATE TABLE pagamento (
    id_pagamento SERIAL PRIMARY KEY,
    id_agendamento INTEGER NOT NULL REFERENCES agendamento(id_agendamento),
    forma_pagamento VARCHAR(50) NOT NULL,
    valor_pago NUMERIC(12,2) NOT NULL CHECK (valor_pago > 0),
    data_pagamento TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    parcelas INTEGER DEFAULT 1 CHECK (parcelas >= 1)
);


CREATE TABLE avaliacao (
    id_avaliacao SERIAL PRIMARY KEY,
    id_agendamento INTEGER UNIQUE NOT NULL REFERENCES agendamento(id_agendamento),
    nota INTEGER NOT NULL CHECK (nota BETWEEN 1 AND 5), 
    comentario TEXT,
    data_avaliacao DATE DEFAULT CURRENT_DATE
);

WITH RECURSIVE s(i) AS (SELECT 1 UNION ALL SELECT i+1 FROM s WHERE i < 55)
INSERT INTO funcionario (nome, cargo, especialidade, salario)
SELECT 
    'Funcionario ' || i,
    CASE 
        WHEN i % 4 = 0 THEN 'Mecânico Senior'
        WHEN i % 4 = 1 THEN 'Mecânico Junior'
        WHEN i % 4 = 2 THEN 'Eletricista'
        ELSE 'Consultor Técnico'
    END,
    CASE WHEN i % 2 = 0 THEN 'Motores' ELSE 'Suspensão' END,
    round(2500 + (random() * 5000),2)
FROM s;

WITH RECURSIVE s(i) AS (SELECT 1 UNION ALL SELECT i+1 FROM s WHERE i < 25)
INSERT INTO tipo_servico (descricao, preco_base, tempo_estimado_minutos)
SELECT 
    'Serviço Catalogo ' || i,
    round(100 + (random() * 900),2),
    30 + (i * 10)
FROM s;

WITH RECURSIVE s(i) AS (SELECT 1 UNION ALL SELECT i+1 FROM s WHERE i < 45)
INSERT INTO peca (nome, fornecedor, quantidade_atual, quantidade_minima, preco_unitario)
SELECT 
    'Peça ' || i,
    'Fornecedor ' || (i % 5 + 1),
    CAST((random() * 100) AS INTEGER),
    15,
    round(50 + (random() * 450),2)
FROM s;

WITH RECURSIVE s(i) AS (SELECT 1 UNION ALL SELECT i+1 FROM s WHERE i < 210)
INSERT INTO cliente (nome, email, telefone, tipo_pessoa, cpf, cnpj)
SELECT 
    'Cliente ' || i,
    'cliente' || i || '@provedor.com',
    '849' || printf('%08d', i),
    CASE WHEN i % 2 = 0 THEN 'PF' ELSE 'PJ' END,
    CASE WHEN i % 2 = 0 THEN printf('%011d', i) ELSE NULL END,
    CASE WHEN i % 2 <> 0 THEN printf('%014d', i) ELSE NULL END
FROM s;

WITH RECURSIVE s(i) AS (SELECT 1 UNION ALL SELECT i+1 FROM s WHERE i < 520)
INSERT INTO veiculo (id_cliente, placa, marca, modelo, ano_fabricacao, cor)
SELECT 
    CAST((random() * 209 + 1) AS INTEGER),
    'ABC' || printf('%04d', i) || 'A' || (i % 9),
    'Marca ' || (i % 10),
    'Modelo ' || (i % 20),
    2010 + (i % 15),
    'Cor ' || (i % 5)
FROM s;

WITH RECURSIVE s(i) AS (SELECT 1 UNION ALL SELECT i+1 FROM s WHERE i < 3600)
INSERT INTO agendamento (id_veiculo, data_abertura, data_conclusao, status, km_entrada, km_saida)
SELECT 
    CAST((random() * 519 + 1) AS INTEGER),
    datetime('now', '-' || i || ' minutes'),
    CASE 
        WHEN i <= 3200 THEN datetime('now', '-' || i || ' minutes', '+2 hours')
        ELSE NULL
    END,
    CASE 
        WHEN i <= 3200 THEN 'Concluído'
        WHEN i <= 3300 THEN 'Em andamento'
        WHEN i <= 3400 THEN 'Cancelado'
        WHEN i <= 3500 THEN 'No-show'
        ELSE 'Agendado'
    END,
    CAST((random() * 50000) AS INTEGER),
    CASE WHEN i <= 3200 THEN CAST((random() * 50000 + 100) AS INTEGER) ELSE NULL END
FROM s;

WITH RECURSIVE s(i) AS (SELECT 1 UNION ALL SELECT i+1 FROM s WHERE i < 7200)
INSERT INTO item_servico (id_agendamento, id_tipo_servico, id_funcionario, quantidade, preco_unitario)
SELECT 
    CAST((random() * 3599 + 1) AS INTEGER),
    CAST((random() * 24 + 1) AS INTEGER),
    CAST((random() * 54 + 1) AS INTEGER),
    1 + CAST((random()*2) AS INTEGER),
    round(50 + (random()*100),2)
FROM s;

WITH RECURSIVE s(i) AS (SELECT 1 UNION ALL SELECT i+1 FROM s WHERE i < 5100)
INSERT INTO item_peca (id_agendamento, id_peca, quantidade, preco_unitario)
SELECT 
    CAST((random() * 3599 + 1) AS INTEGER),
    CAST((random() * 44 + 1) AS INTEGER),
    CAST((random() * 3 + 1) AS INTEGER),
    round(10 + (random()*50),2)
FROM s;

WITH RECURSIVE s2(i) AS (SELECT 1 UNION ALL SELECT i+1 FROM s2 WHERE i < 5100)
INSERT INTO item_peca (id_agendamento, id_peca, quantidade, preco_unitario)
SELECT 
    CAST((random() * 3599 + 1) AS INTEGER),
    CAST((random() * 44 + 1) AS INTEGER),
    CAST((random() * 3 + 1) AS INTEGER),
    round(10 + (random()*50),2)
FROM s2;

INSERT INTO pagamento (id_agendamento, forma_pagamento, valor_pago, parcelas)
SELECT
    id_agendamento,
    CASE 
        WHEN id_agendamento % 3 = 0 THEN 'Cartão'
        WHEN id_agendamento % 3 = 1 THEN 'PIX'
        ELSE 'Dinheiro'
    END,
    round(100 + (random()*500),2),
    1 + CAST((random()*3) AS INTEGER)
FROM agendamento
WHERE status = 'Concluído'
LIMIT 3000;

INSERT INTO avaliacao (id_agendamento, nota, comentario)
SELECT 
    id_agendamento,
    CAST((abs(random()) % 5) + 1 AS INTEGER),
    'Avaliacao automática'
FROM agendamento 
WHERE status = 'Concluído'
LIMIT 2200;

ANALYZE;

-- SET search_path TO oficina, public; -- commented out: SQLite does not support SET search_path (PostgreSQL-specific)

SELECT 'cliente' AS tabela, COUNT(*) AS total FROM cliente
UNION ALL SELECT 'veiculo', COUNT(*) FROM veiculo
UNION ALL SELECT 'funcionario', COUNT(*) FROM funcionario
UNION ALL SELECT 'tipo_servico', COUNT(*) FROM tipo_servico
UNION ALL SELECT 'peca', COUNT(*) FROM peca
UNION ALL SELECT 'agendamento', COUNT(*) FROM agendamento
UNION ALL SELECT 'item_servico', COUNT(*) FROM item_servico
UNION ALL SELECT 'item_peca', COUNT(*) FROM item_peca
UNION ALL SELECT 'pagamento', COUNT(*) FROM pagamento
UNION ALL SELECT 'avaliacao', COUNT(*) FROM avaliacao;

SELECT 
    strftime('%Y-%m', a.data_conclusao) AS mes,
    SUM(p.valor_pago) AS receita_total,
    ROUND(AVG(p.valor_pago), 2) AS ticket_medio
FROM agendamento a
JOIN pagamento p ON a.id_agendamento = p.id_agendamento
WHERE a.status = 'Concluído' 
  AND a.data_conclusao >= date('now','-12 months')
GROUP BY strftime('%Y-%m', a.data_conclusao)
ORDER BY mes DESC;

SELECT 
    ts.descricao,
    COUNT(its.id_item_servico) AS quantidade_execucoes,
    SUM(its.total_item) AS faturamento_total
FROM tipo_servico ts
JOIN item_servico its ON ts.id_tipo_servico = its.id_tipo_servico
GROUP BY ts.id_tipo_servico, ts.descricao
ORDER BY quantidade_execucoes DESC, faturamento_total DESC
LIMIT 10;

SELECT 
    f.nome,
    COUNT(DISTINCT its.id_agendamento) AS os_atendidas,
    SUM(its.total_item) AS faturamento_gerado
FROM funcionario f
JOIN item_servico its ON f.id_funcionario = its.id_funcionario
JOIN agendamento a ON its.id_agendamento = a.id_agendamento
WHERE a.status = 'Concluído'
GROUP BY f.id_funcionario, f.nome
ORDER BY faturamento_gerado DESC;

SELECT 
    c.nome,
    c.tipo_pessoa,
    SUM(p.valor_pago) AS gasto_total
FROM cliente c
JOIN veiculo v ON c.id_cliente = v.id_cliente
JOIN agendamento a ON v.id_veiculo = a.id_veiculo
JOIN pagamento p ON a.id_agendamento = p.id_agendamento
GROUP BY c.id_cliente, c.nome, c.tipo_pessoa
ORDER BY gasto_total DESC
LIMIT 20;

SELECT 
    forma_pagamento,
    COUNT(*) AS qtd_transacoes,
    SUM(valor_pago) AS valor_total,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()), 2) AS percentual_quantidade
FROM pagamento
GROUP BY forma_pagamento
ORDER BY valor_total DESC;

SELECT 
    nome,
    fornecedor,
    quantidade_minima,
    quantidade_atual,
    (quantidade_minima - quantidade_atual) AS deficit
FROM peca
WHERE quantidade_atual < quantidade_minima
ORDER BY deficit DESC;

SELECT 
    f.nome,
    ROUND(AVG(av.nota), 2) AS nota_media,
    COUNT(av.id_avaliacao) AS total_avaliacoes
FROM funcionario f
JOIN item_servico its ON f.id_funcionario = its.id_funcionario
JOIN agendamento a ON its.id_agendamento = a.id_agendamento
JOIN avaliacao av ON a.id_agendamento = av.id_agendamento
GROUP BY f.id_funcionario, f.nome
HAVING COUNT(av.id_avaliacao) >= 5
ORDER BY nota_media DESC;

SELECT 
    forma_pagamento,
    COUNT(*) AS qtd_transacoes,
    SUM(valor_pago) AS valor_total,
    ROUND((SUM(valor_pago) * 100.0 / SUM(SUM(valor_pago)) OVER()), 2) AS percentual_valor
FROM pagamento
GROUP BY forma_pagamento
ORDER BY valor_total DESC;
