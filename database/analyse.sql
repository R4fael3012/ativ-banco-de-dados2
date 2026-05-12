ANALYZE;

DROP INDEX IF EXISTS idx_agendamento_status_data;
DROP INDEX IF EXISTS idx_pagamento_agendamento;
DROP INDEX IF EXISTS idx_item_servico_tipo_servico;
DROP INDEX IF EXISTS idx_item_servico_funcionario_agendamento;
DROP INDEX IF EXISTS idx_veiculo_cliente;
DROP INDEX IF EXISTS idx_agendamento_veiculo;
DROP INDEX IF EXISTS idx_peca_estoque;
DROP INDEX IF EXISTS idx_avaliacao_agendamento;
DROP INDEX IF EXISTS idx_item_servico_agendamento;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
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

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
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

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    ts.descricao,
    COUNT(its.id_item_servico) AS quantidade_execucoes,
    SUM(its.total_item) AS faturamento_total
FROM tipo_servico ts
JOIN item_servico its ON ts.id_tipo_servico = its.id_tipo_servico
GROUP BY ts.id_tipo_servico, ts.descricao
ORDER BY quantidade_execucoes DESC, faturamento_total DESC
LIMIT 10;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
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

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
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

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    forma_pagamento,
    COUNT(*) AS qtd_transacoes,
    SUM(valor_pago) AS valor_total,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()), 2) AS percentual_quantidade
FROM pagamento
GROUP BY forma_pagamento
ORDER BY valor_total DESC;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    nome,
    fornecedor,
    quantidade_minima,
    quantidade_atual,
    (quantidade_minima - quantidade_atual) AS deficit
FROM peca
WHERE quantidade_atual < quantidade_minima
ORDER BY deficit DESC;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
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

CREATE INDEX idx_agendamento_status_data ON agendamento(status, data_conclusao);
CREATE INDEX idx_pagamento_agendamento ON pagamento(id_agendamento);
CREATE INDEX idx_item_servico_tipo_servico ON item_servico(id_tipo_servico);
CREATE INDEX idx_item_servico_funcionario_agendamento ON item_servico(id_funcionario, id_agendamento);
CREATE INDEX idx_veiculo_cliente ON veiculo(id_cliente);
CREATE INDEX idx_agendamento_veiculo ON agendamento(id_veiculo);
CREATE INDEX idx_peca_estoque ON peca(quantidade_atual, quantidade_minima);
CREATE INDEX idx_avaliacao_agendamento ON avaliacao(id_agendamento);
CREATE INDEX idx_item_servico_agendamento ON item_servico(id_agendamento);

ANALYZE;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
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

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
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

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    ts.descricao,
    COUNT(its.id_item_servico) AS quantidade_execucoes,
    SUM(its.total_item) AS faturamento_total
FROM tipo_servico ts
JOIN item_servico its ON ts.id_tipo_servico = its.id_tipo_servico
GROUP BY ts.id_tipo_servico, ts.descricao
ORDER BY quantidade_execucoes DESC, faturamento_total DESC
LIMIT 10;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
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

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
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

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    forma_pagamento,
    COUNT(*) AS qtd_transacoes,
    SUM(valor_pago) AS valor_total,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()), 2) AS percentual_quantidade
FROM pagamento
GROUP BY forma_pagamento
ORDER BY valor_total DESC;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    nome,
    fornecedor,
    quantidade_minima,
    quantidade_atual,
    (quantidade_minima - quantidade_atual) AS deficit
FROM peca
WHERE quantidade_atual < quantidade_minima
ORDER BY deficit DESC;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
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
