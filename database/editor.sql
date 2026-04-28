--database: ./db.sqlite

-- Requisitos Funcionais
-- Regras de Negócio
-- Requisitos Não Funcionais

DROP SCHEMA IF EXISTS oficina CASCADE;
CREATE SCHEMA oficina;
SET search_path TO oficina, public;


CREATE DOMAIN dm_cpf AS VARCHAR(11) 
    CHECK (VALUE ~ '^\d{11}$');

CREATE DOMAIN dm_cnpj AS VARCHAR(14) 
    CHECK (VALUE ~ '^\d{14}$');

CREATE DOMAIN dm_placa AS VARCHAR(7) 
    CHECK (VALUE ~ '^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$'); 

CREATE DOMAIN dm_email AS VARCHAR(255) 
    CHECK (VALUE ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$');

CREATE DOMAIN dm_telefone AS VARCHAR(15);


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
    salario NUMERIC(12,2) NOT NULL CHECK (salario > 0) -- Salário maior que zero [cite: 36, 41]
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
    -- Regra de Negócio: Estoque não pode ser negativo [cite: 30]
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