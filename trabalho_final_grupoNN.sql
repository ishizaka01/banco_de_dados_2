-- ============================================================================
-- TRABALHO FINAL - BANCO DE DADOS II
-- INTEGRANTES: Luccas Rafael (e grupo)
-- DOMÍNIO: EventHub (Plataforma de Gestão de Eventos e Ingressos)
-- ============================================================================

-- Configuração inicial do ambiente para garantir reprodutibilidade integral
DROP SCHEMA IF EXISTS grupo_eventhub CASCADE;
CREATE SCHEMA grupo_eventhub;
SET search_path TO grupo_eventhub;

-- ----------------------------------------------------------------------------
-- 1. MODELAGEM FÍSICA (DDL)
-- ----------------------------------------------------------------------------

-- Tabela: LOCAL
CREATE TABLE local (
    id_local SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    rua VARCHAR(150) NOT NULL,
    numero VARCHAR(20) NOT NULL,
    bairro VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    cep CHAR(8) NOT NULL
);

-- Tabela: CATEGORIA
CREATE TABLE categoria (
    id_categoria SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT
);

-- Tabela: USUARIO
CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    email VARCHAR(150) NOT NULL UNIQUE,
    data_nascimento DATE NOT NULL,
    CONSTRAINT chk_idade CHECK (data_nascimento <= CURRENT_DATE - INTERVAL '12 years') -- Validação plausível de idade mínima
);

-- Tabela: USUARIO_TELEFONE (Resolução do atributo multivalorado para 1FN)
CREATE TABLE usuario_telefone (
    id_usuario INT REFERENCES usuario(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
    telefone VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_usuario, telefone)
);

-- Tabela: ORGANIZADOR (Especialização de USUARIO)
CREATE TABLE organizador (
    id_organizador SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL UNIQUE REFERENCES usuario(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Tabela: EVENTO
CREATE TABLE evento (
    id_evento SERIAL PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    descricao TEXT,
    data DATE NOT NULL,
    horario TIME NOT NULL,
    capacidade_maxima INT NOT NULL CHECK (capacidade_maxima > 0),
    id_local INT NOT NULL REFERENCES local(id_local) ON DELETE RESTRICT ON UPDATE CASCADE,
    id_organizador INT NOT NULL REFERENCES organizador(id_organizador) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_data_futura CHECK (data >= '2026-01-01') -- Contexto do ano corrente do trabalho
);

-- Tabela Associativa: EVENTO_CATEGORIA (Relacionamento N:M)
CREATE TABLE evento_categoria (
    id_evento INT REFERENCES evento(id_evento) ON DELETE CASCADE ON UPDATE CASCADE,
    id_categoria INT REFERENCES categoria(id_categoria) ON DELETE RESTRICT ON UPDATE CASCADE,
    PRIMARY KEY (id_evento, id_categoria)
);

-- Tabela: INGRESSO
CREATE TABLE ingresso (
    id_ingresso SERIAL PRIMARY KEY,
    tipo VARCHAR(50) NOT NULL, -- Ex: 'Pista', 'Camarote', 'VIP'
    preco NUMERIC(10,2) NOT NULL CHECK (preco >= 0.00),
    quantidade_disponivel INT NOT NULL CHECK (quantidade_disponivel >= 0),
    id_evento INT NOT NULL REFERENCES evento(id_evento) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Tabela: COMPRA
CREATE TABLE compra (
    id_compra SERIAL PRIMARY KEY,
    data_compra TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor_total NUMERIC(10,2) NOT NULL DEFAULT 0.00 CHECK (valor_total >= 0.00),
    id_usuario INT NOT NULL REFERENCES usuario(id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Tabela Associativa: COMPRA_INGRESSO
CREATE TABLE compra_ingresso (
    id_compra INT REFERENCES compra(id_compra) ON DELETE CASCADE ON UPDATE CASCADE,
    id_ingresso INT REFERENCES ingresso(id_ingresso) ON DELETE RESTRICT ON UPDATE CASCADE,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    PRIMARY KEY (id_compra, id_ingresso)
);

-- Tabela: PAGAMENTO
CREATE TABLE pagamento (
    id_pagamento SERIAL PRIMARY KEY,
    tipo_pagamento VARCHAR(50) NOT NULL, -- Ex: 'Cartão', 'Pix', 'Boleto'
    status VARCHAR(20) NOT NULL CHECK (status IN ('pendente', 'pago', 'cancelado')),
    data_pagamento TIMESTAMP,
    id_compra INT NOT NULL UNIQUE REFERENCES compra(id_compra) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Tabela: AVALIACAO
CREATE TABLE avaliacao (
    id_avaliacao SERIAL PRIMARY KEY,
    nota INT NOT NULL CHECK (nota BETWEEN 1 AND 5),
    comentario TEXT,
    data_avaliacao DATE NOT NULL DEFAULT CURRENT_DATE,
    id_usuario INT NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
    id_evento INT NOT NULL REFERENCES evento(id_evento) ON DELETE CASCADE ON UPDATE CASCADE
);
-- ----------------------------------------------------------------------------
-- 2. CARGA DE DADOS (DML)
-- ----------------------------------------------------------------------------

-- Inserindo Locais (Mínimo 5)
INSERT INTO local (nome, rua, numero, bairro, cidade, cep) VALUES
('Expominas BH', 'Avenida Amazonas', '5855', 'Gameleira', 'Belo Horizonte', '30510000'),
('Teatro Municipal de Lavras', 'Rua Santana', '112', 'Centro', 'Lavras', '37200000'),
('Arena Hall', 'Avenida Nossa Senhora do Carmo', '230', 'Savassi', 'Belo Horizonte', '30330000'),
('Centro de Eventos Unilavras', 'Rua Padre Paulino', '50', 'Centenário', 'Lavras', '37200123'),
('Parque de Exposições de Lavras', 'Avenida do Contorno', 'S/N', 'Zona Industrial', 'Lavras', '37200500');

-- Inserindo Categorias (Mínimo 5)
INSERT INTO categoria (nome, descricao) VALUES
('Show', 'Apresentações musicais ao vivo, concertos e festivais.'),
('Palestra', 'Eventos corporativos, acadêmicos, seminários e workshops.'),
('Teatro', 'Peças teatrais, comédias stand-up e expressões artísticas.'),
('Esporte', 'Campeonatos, corridas e atividades físicas integrativas.'),
('Gastronomia', 'Festivais de food truck, feiras de vinho e experiências culinárias.');

-- Inserindo Usuários (Mínimo 5)
INSERT INTO usuario (nome, cpf, email, data_nascimento) VALUES
('Carlos Henrique Silva', '11122233344', 'carlos.silva@email.com', '1990-05-15'),
('Mariana Costa Oliveira', '55566677788', 'mariana.costa@email.com', '1995-09-22'),
('Rodrigo Souza Santos', '99988877766', 'rodrigo.santos@email.com', '1988-02-10'),
('Ana Beatriz Pereira', '44433322211', 'ana.pereira@email.com', '2001-11-30'),
('Juliana Martins Rocha', '22244466688', 'juliana.rocha@email.com', '1993-07-04');

-- Inserindo Telefones dos Usuários (Tratamento multivalorado)
INSERT INTO usuario_telefone (id_usuario, telefone) VALUES
(1, '31988887777'),
(1, '3133334444'),
(2, '35999998888'),
(3, '31977776666'),
(4, '35988881111'),
(5, '35991112222');

-- Inserindo Organizadores (Vinculados a Usuários existentes)
INSERT INTO organizador (id_usuario) VALUES
(1), -- Carlos Henrique
(3); -- Rodrigo Souza

-- Inserindo Eventos (Mínimo 5)
-- Nota: data >= '2026-01-01' conforme a restrição CHECK imposta
INSERT INTO evento (titulo, descricao, data, horario, capacidade_maxima, id_local, id_organizador) VALUES
('Festival de Inverno de Lavras', 'O maior festival de música regional do sul de Minas.', '2026-07-15', '19:00:00', 5000, 5, 1),
('Stand-up Comedy de Quinta', 'Uma noite inteira de risadas com humoristas locais.', '2026-08-20', '20:30:00', 300, 2, 2),
('Congresso de Tecnologia e Inovação', 'Palestras focadas em IA, Banco de Dados e Web3.', '2026-09-10', '08:00:00', 1000, 4, 1),
('Circuito de Corrida de Rua EventHub', 'Corrida de 5km e 10km pelas ruas históricas.', '2026-10-04', '07:00:00', 800, 1, 2),
('Feira Gastronômica Mineira', 'O melhor do queijo, café e cachaça da nossa região.', '2026-11-12', '12:00:00', 1500, 5, 1);

-- Inserindo Associações de Evento e Categoria
INSERT INTO evento_categoria (id_evento, id_categoria) VALUES
(1, 1), -- Festival -> Show
(2, 3), -- Stand-up -> Teatro
(3, 2), -- Congresso -> Palestra
(4, 4), -- Corrida -> Esporte
(5, 5); -- Feira -> Gastronomia

-- Inserindo Ingressos (Mínimo 5)
INSERT INTO ingresso (tipo, preco, quantidade_disponivel, id_evento) VALUES
('Pista Comum', 40.00, 4000, 1),
('Camarote VIP', 120.00, 1000, 1),
('Entrada Geral Teatro', 25.00, 300, 2),
('Passaporte Estudante', 50.00, 400, 3),
('Passaporte Profissional', 100.00, 600, 3),
('Inscrição Corrida', 60.00, 800, 4),
('Entrada Franca Sabores', 0.00, 1500, 5);

-- Inserindo Compras (Mínimo 5)
INSERT INTO compra (data_compra, valor_total, id_usuario) VALUES
('2026-06-20 14:30:00', 160.00, 2), -- Mariana comprou
('2026-06-21 10:15:00', 25.00, 4),  -- Ana comprou
('2026-06-22 18:45:00', 120.00, 5), -- Juliana comprou
('2026-06-23 09:00:00', 60.00, 2),  -- Mariana comprou novamente
('2026-06-24 16:20:00', 200.00, 4); -- Ana comprou novamente

-- Inserindo Relações de Compra e Ingresso
INSERT INTO compra_ingresso (id_compra, id_ingresso, quantidade) VALUES
(1, 1, 4), -- 4 Pistas Comuns (4 * 40 = 160)
(2, 3, 1), -- 1 Entrada Geral (1 * 25 = 25)
(3, 2, 1), -- 1 Camarote VIP (1 * 120 = 120)
(4, 6, 1), -- 1 Inscrição Corrida (1 * 60 = 60)
(5, 5, 2); -- 2 Passaportes Profissionais (2 * 100 = 200)

-- Inserindo Pagamentos (Mínimo 5, linkados 1:1 com as compras)
INSERT INTO pagamento (tipo_pagamento, status, data_pagamento, id_compra) VALUES
('Pix', 'pago', '2026-06-20 14:31:00', 1),
('Cartão', 'pago', '2026-06-21 10:17:00', 2),
('Boleto', 'pendente', NULL, 3),
('Pix', 'pago', '2026-06-23 09:01:00', 4),
('Cartão', 'cancelado', NULL, 5);

-- Inserindo Avaliações (Mínimo 5, simulando eventos passados/concluídos por usuários)
INSERT INTO avaliacao (nota, comentario, data_avaliacao, id_usuario, id_evento) VALUES
(5, 'O festival foi incrível, organização perfeita!', '2026-07-16', 2, 1),
(4, 'Muito engraçado, mas o local estava um pouco quente.', '2026-08-21', 4, 2),
(5, 'Conteúdo das palestras de altíssimo nível.', '2026-09-12', 5, 3),
(3, 'Faltou ponto de hidratação na metade da corrida.', '2026-10-05', 2, 4),
(4, 'Comida maravilhosa, os preços estavam um pouco salgados.', '2026-11-13', 4, 5);
-- ----------------------------------------------------------------------------
-- 3. MANIPULAÇÃO DE SCHEMA E DADOS (1,0 pt)
-- ----------------------------------------------------------------------------

-- Alteração 1: ADD COLUMN
-- Justificativa: Adicionando a coluna "link_transmissao" na tabela evento para suportar eventos híbridos ou online.
ALTER TABLE evento 
ADD COLUMN link_transmissao VARCHAR(255);

-- Alteração 2: RENAME COLUMN
-- Justificativa: Corrigindo o nome da coluna "bome" que foi mapeada erroneamente no diagrama original para "nome".
ALTER TABLE local 
RENAME COLUMN nome TO nome_local;

-- Alteração 3: ADD CONSTRAINT
-- Justificativa: Adicionando uma nova restrição CHECK para garantir que o tipo de ingresso só possa ser um dos padrões do sistema.
ALTER TABLE ingresso 
ADD CONSTRAINT chk_tipo_ingresso 
CHECK (tipo IN ('Pista Comum', 'Camarote VIP', 'Entrada Geral Teatro', 'Passaporte Estudante', 'Passaporte Profissional', 'Inscrição Corrida', 'Entrada Franca Sabores', 'Meia Entrada'));

-- Alteração 4: DROP COLUMN
-- Justificativa: Removendo a coluna "link_transmissao" recém-criada, pois a regra de negócio mudou e o foco do sistema será estritamente em eventos presenciais.
ALTER TABLE evento 
DROP COLUMN link_transmissao;

-- Update em Massa 1
-- Justificativa: Conceder um desconto de 10% no preço de todos os ingressos de eventos agendados para o segundo semestre de 2026 (a partir de julho), impulsionando as vendas.
UPDATE ingresso
SET preco = preco * 0.90
WHERE id_evento IN (
    SELECT id_evento 
    FROM evento 
    WHERE data >= '2026-07-01'
);

-- Update em Massa 2
-- Justificativa: Atualizar o status de todos os pagamentos em "Boleto" que foram gerados há mais de 3 dias e continuavam pendentes para "cancelado" (regra de expiração).
UPDATE pagamento
SET status = 'cancelado'
WHERE status = 'pendente' 
  AND tipo_pagamento = 'Boleto'
  AND id_compra IN (
      SELECT id_compra 
      FROM compra 
      WHERE data_compra < CURRENT_TIMESTAMP - INTERVAL '3 days'
  );
  -- ----------------------------------------------------------------------------
-- 4. CONSULTAS COM PROPÓSITO (3,5 pts)
-- ----------------------------------------------------------------------------

-- ============================================================================
-- 4.1. CONSULTAS SIMPLES
-- ============================================================================

-- Q4.1.1: Quais eventos estão cadastrados na plataforma e qual a sua capacidade máxima?
SELECT titulo, capacidade_maxima 
FROM evento;

-- Q4.1.2: Quais são as categorias disponíveis para classificação dos eventos?
SELECT nome, descricao 
FROM categoria;

-- Q4.1.3: Quais usuários cadastrados nasceram antes do ano 2000?
SELECT nome, email, data_nascimento 
FROM usuario 
WHERE data_nascimento < '2000-01-01';

-- Q4.1.4: Quais ingressos cadastrados possuem preço superior a R$ 50,00?
SELECT tipo, preco, id_evento 
FROM ingresso 
WHERE preco > 50.00;

-- Q4.1.5: Quais pagamentos foram realizados utilizando o método 'Pix'?
SELECT id_pagamento, status, data_pagamento 
FROM pagamento 
WHERE tipo_pagamento = 'Pix';


-- ============================================================================
-- 4.2. CONSULTAS COMPLEXAS
-- ============================================================================

-- Q4.2.1 (Técnica: JOIN envolvendo 3 ou mais tabelas)
-- Pergunta: Quais são os nomes dos clientes, os títulos dos eventos e os tipos de ingressos comprados por eles?
SELECT u.nome AS cliente, e.titulo AS evento, i.tipo AS tipo_ingresso, ci.quantidade
FROM usuario u
JOIN compra c ON u.id_usuario = c.id_usuario
JOIN compra_ingresso ci ON c.id_compra = ci.id_compra
JOIN ingresso i ON ci.id_ingresso = i.id_ingresso
JOIN evento e ON i.id_evento = e.id_evento;

-- Q4.2.2 (Técnica: Subconsulta Correlacionada)
-- Pergunta: Quais ingressos possuem um preço acima da média de preço de todos os ingressos do seu próprio evento?
SELECT i1.tipo, i1.preco, i1.id_evento
FROM ingresso i1
WHERE i1.preco > (
    SELECT AVG(i2.preco)
    FROM ingresso i2
    WHERE i2.id_evento = i1.id_evento
);

-- Q4.2.3 (Técnica: GROUP BY com HAVING)
-- Pergunta: Quais eventos possuem uma média de nota de avaliação superior a 3.5?
SELECT e.titulo, ROUND(AVG(a.nota), 2) AS media_notas
FROM evento e
JOIN avaliacao a ON e.id_evento = a.id_evento
GROUP BY e.id_evento, e.titulo
HAVING AVG(a.nota) > 3.5;

-- Q4.2.4 (Técnica: Função de Janela - ROW_NUMBER)
-- Pergunta: Qual a classificação (ranking) dos ingressos mais caros para cada evento?
SELECT 
    e.titulo AS evento,
    i.tipo AS tipo_ingresso,
    i.preco,
    ROW_NUMBER() OVER(PARTITION BY i.id_evento ORDER BY i.preco DESC) AS ranking_preco
FROM ingresso i
JOIN evento e ON i.id_evento = e.id_evento;

-- Q4.2.5 (Técnica: Operação de Conjunto - EXCEPT)
-- Pergunta: Quais usuários do sistema estão cadastrados, mas nunca realizaram nenhuma compra de ingresso?
SELECT id_usuario, nome, email
FROM usuario
EXCEPT
SELECT u.id_usuario, u.nome, u.email
FROM usuario u
JOIN compra c ON u.id_usuario = c.id_usuario;
-- ----------------------------------------------------------------------------
-- 5. VIEWS (2,0 pts)
-- ----------------------------------------------------------------------------

-- ============================================================================
-- VIEW 1: MATERIALIZED VIEW - Ocupação e Receita dos Eventos
-- Caso de uso: Utilizada pela diretoria financeira para acompanhar as receitas 
-- e ingressos vendidos de forma consolidada, sem onerar o banco com cálculos pesados.
-- ============================================================================
CREATE MATERIALIZED VIEW mv_resumo_financeiro_evento AS
SELECT 
    e.id_evento,
    e.titulo AS evento,
    e.data AS data_evento,
    COALESCE(SUM(ci.quantidade), 0) AS total_ingressos_vendidos,
    ROUND(COALESCE(SUM(ci.quantidade * i.preco), 0), 2) AS receita_total_estimada
FROM evento e
LEFT JOIN ingresso i ON e.id_evento = i.id_evento
LEFT JOIN compra_ingresso ci ON i.id_ingresso = ci.id_ingresso
GROUP BY e.id_evento, e.titulo, e.data;

-- ----------------------------------------------------------------------------
-- DEMONSTRAÇÃO DO CICLO COMPLETO DA VIEW MATERIALIZADA
-- ----------------------------------------------------------------------------

-- Passo 1: Selecionar dados atuais da View Materializada
SELECT * FROM mv_resumo_financeiro_evento WHERE id_evento = 1;

-- Passo 2: Inserir uma nova compra na tabela base que altera os valores do evento 1
INSERT INTO compra (data_compra, valor_total, id_usuario) 
VALUES (CURRENT_TIMESTAMP, 80.00, 3);

INSERT INTO compra_ingresso (id_compra, id_ingresso, quantidade) 
VALUES (6, 1, 2); -- Adicionando mais 2 ingressos do tipo Pista Comum (Evento 1)

-- Passo 3: Consultar a View novamente (Ainda NÃO deve refletir a mudança)
SELECT * FROM mv_resumo_financeiro_evento WHERE id_evento = 1;

-- Passo 4: Executar a atualização da View Materializada
REFRESH MATERIALIZED VIEW mv_resumo_financeiro_evento;

-- Passo 5: Consultar novamente (Agora DEVE refletir a mudança perfeitamente)
SELECT * FROM mv_resumo_financeiro_evento WHERE id_evento = 1;


-- ============================================================================
-- VIEW 2: VIEW NORMAL - Próximos Eventos e Detalhes de Localização
-- Caso de uso: Utilizada pela equipe de marketing e front-end para exibir a 
-- agenda completa de eventos no site principal.
-- ============================================================================
CREATE OR REPLACE VIEW v_agenda_proximos_eventos AS
SELECT 
    e.id_evento,
    e.titulo AS evento,
    e.data,
    e.horario,
    l.nome_local AS local,
    l.cidade,
    l.bairro
FROM evento e
JOIN local l ON e.id_local = l.id_local
WHERE e.data >= CURRENT_DATE
ORDER BY e.data ASC;

-- Teste da View 2
SELECT * FROM v_agenda_proximos_eventos;


-- ============================================================================
-- VIEW 3: VIEW NORMAL - Ranking de Avaliações por Evento
-- Caso de uso: Utilizada pelo time de suporte e qualidade para monitorar quais 
-- eventos estão agradando o público e quais precisam de melhorias.
-- ============================================================================
CREATE OR REPLACE VIEW v_feedback_eventos AS
SELECT 
    e.id_evento,
    e.titulo AS evento,
    COUNT(a.id_avaliacao) AS total_avaliacoes,
    ROUND(AVG(a.nota), 1) AS nota_media,
    STRING_AGG(a.comentario, ' | ') AS comentarios_consolidados
FROM evento e
LEFT JOIN avaliacao a ON e.id_evento = a.id_evento
GROUP BY e.id_evento, e.titulo;

-- Teste da View 3
SELECT * FROM v_feedback_eventos;
-- ----------------------------------------------------------------------------
-- 6. PROGRAMAÇÃO NO SGBD (3,5 pts)
-- ----------------------------------------------------------------------------

-- ============================================================================
-- 6.1. TRIGGERS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TRIGGER 1 (BEFORE): Validação de Estoque de Ingressos
-- Regra: Impede a venda se a quantidade solicitada for maior que o estoque.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_valida_estoque_ingresso()
RETURNS TRIGGER AS $$
DECLARE
    v_estoque INT;
BEGIN
    -- Recupera a quantidade disponível atual do ingresso solicitado
    SELECT quantidade_disponivel INTO v_estoque
    FROM ingresso
    WHERE id_ingresso = NEW.id_ingresso;

    -- Se não houver quantidade suficiente, barra a operação
    IF v_estoque < NEW.quantidade THEN
        RAISE EXCEPTION 'Venda cancelada: Estoque insuficiente para o ingresso ID %. Disponível: %', 
            NEW.id_ingresso, v_estoque;
    END IF;

    -- Se houver estoque, deduz a quantidade comprada do estoque do ingresso
    UPDATE ingresso
    SET quantidade_disponivel = quantidade_disponivel - NEW.quantidade
    WHERE id_ingresso = NEW.id_ingresso;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_valida_estoque_ingresso
BEFORE INSERT ON compra_ingresso
FOR EACH ROW
EXECUTE FUNCTION fn_valida_estoque_ingresso();


-- ----------------------------------------------------------------------------
-- TRIGGER 2 (AFTER): Atualização Automática do Valor Total da Compra
-- Regra: Calcula o subtotal (quantidade * preço) e soma ao valor_total da compra.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_atualiza_valor_total_compra()
RETURNS TRIGGER AS $$
DECLARE
    v_preco_unitario NUMERIC(10,2);
    v_subtotal NUMERIC(10,2);
BEGIN
    -- Busca o preço do ingresso vendido
    SELECT preco INTO v_preco_unitario
    FROM ingresso
    WHERE id_ingresso = NEW.id_ingresso;

    -- Calcula o valor total do item inserido
    v_subtotal := v_preco_unitario * NEW.quantidade;

    -- Atualiza o valor somando-o à tabela compra
    UPDATE compra
    SET valor_total = valor_total + v_subtotal
    WHERE id_compra = NEW.id_compra;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_atualiza_valor_total_compra
AFTER INSERT ON compra_ingresso
FOR EACH ROW
EXECUTE FUNCTION fn_atualiza_valor_total_compra();


-- ----------------------------------------------------------------------------
-- DEMONSTRAÇÃO DO FUNCIONAMENTO DAS TRIGGERS (Antes / Depois)
-- ----------------------------------------------------------------------------

-- Visualizando estado inicial do estoque do ingresso ID 3 e da compra ID 2
SELECT id_ingresso, quantidade_disponivel FROM ingresso WHERE id_ingresso = 3;
SELECT id_compra, valor_total FROM compra WHERE id_compra = 2;

-- Teste 1: Inserindo uma compra válida (Dispara trg_valida_estoque e trg_atualiza_valor_total)
INSERT INTO compra_ingresso (id_compra, id_ingresso, quantidade) VALUES (2, 3, 5);

-- Verificando efeito da inserção bem-sucedida (Estoque diminuiu e valor_total subiu)
SELECT id_ingresso, quantidade_disponivel FROM ingresso WHERE id_ingresso = 3;
SELECT id_compra, valor_total FROM compra WHERE id_compra = 2;

-- Teste 2: Forçando estouro de estoque (Deve disparar o RAISE EXCEPTION da Trigger BEFORE)
-- O ingresso ID 3 agora tem 295 unidades disponíveis. Vamos tentar comprar 400.
-- O bloco abaixo vai gerar um erro esperado de validação do sistema.
DO $$
BEGIN
    BEGIN
        INSERT INTO compra_ingresso (id_compra, id_ingresso, quantidade) VALUES (2, 3, 400);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Capturado erro esperado de validação: %', SQLERRM;
    END;
END $$;
-- ============================================================================
-- 6.2. PROCEDURE OU FUNCTION (COM ESTRUTURA DE CONTROLE)
-- Regra: Uma rotina procedural que recebe parâmetros, possui condicionais (IF)
-- e um laço de repetição (FOR) para atualizar em lote registros específicos.
-- Caso de uso: Permitir que organizadores alterem os preços dos ingressos de um
-- evento específico aplicando um fator de reajuste (ex: virada de lote).
-- ============================================================================
CREATE OR REPLACE PROCEDURE pr_reajustar_precos_evento(
    p_id_evento INT,
    p_percentual_reajuste NUMERIC
) AS $$
DECLARE
    v_registro RECORD;
    v_novo_preco NUMERIC(10,2);
BEGIN
    -- Verifica se o evento existe antes de processar
    IF NOT EXISTS (SELECT 1 FROM evento WHERE id_evento = p_id_evento) THEN
        RAISE EXCEPTION 'Erro na Procedure: Evento com ID % não foi encontrado.', p_id_evento;
    END IF;

    -- Laço de repetição (FOR) para percorrer todos os ingressos daquele evento
    FOR v_registro IN 
        SELECT id_ingresso, tipo, preco 
        FROM ingresso 
        WHERE id_evento = p_id_evento
    LOOP
        -- Estrutura Condicional (IF): Se for ingresso do tipo 'VIP', o reajuste ganha +5% de taxa extra
        IF v_registro.tipo LIKE '%VIP%' THEN
            v_novo_preco := v_registro.preco * (1 + (p_percentual_reajuste / 100) + 0.05);
        ELSE
            v_novo_preco := v_registro.preco * (1 + (p_percentual_reajuste / 100));
        END IF;

        -- Atualiza o preço do ingresso correspondente no loop
        UPDATE ingresso
        SET preco = ROUND(v_novo_preco, 2)
        WHERE id_ingresso = v_registro.id_ingresso;

        RAISE NOTICE 'Ingresso ID % (%): Preço antigo: R$ % | Novo preço: R$ %', 
            v_registro.id_ingresso, v_registro.tipo, v_registro.preco, ROUND(v_novo_preco, 2);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- DEMONSTRAÇÃO DO FUNCIONAMENTO DA PROCEDURE
-- ----------------------------------------------------------------------------
-- Consultando os preços antes do reajuste para o Evento 1
SELECT id_ingresso, tipo, preco FROM ingresso WHERE id_evento = 1;

-- Executa a Procedure aplicando 10% de aumento nos ingressos do Evento 1
CALL pr_reajustar_precos_evento(1, 10.00);

-- Consultando os preços depois do reajuste (Camarote VIP ganha +5% adicionais por regra)
SELECT id_ingresso, tipo, preco FROM ingresso WHERE id_evento = 1;


-- ============================================================================
-- 6.3. TRANSAÇÃO COM ROLLBACK (ATOMICIDADE E CONCORRÊNCIA)
-- Regra: Demonstrar o controle transacional explícito. O script deve abrir uma
-- transação, realizar comandos DML e forçar um ROLLBACK simulando um erro/desistência.
-- ============================================================================

-- Passo 1: Verificar o estado atual de um usuário e suas compras antes do bloco
SELECT id_compra, valor_total FROM compra WHERE id_usuario = 5;

-- Passo 2: Início do bloco transacional explícito
BEGIN;

    -- Insere uma nova intenção de compra
    INSERT INTO compra (id_compra, data_compra, valor_total, id_usuario)
    VALUES (99, CURRENT_TIMESTAMP, 0.00, 5);

    -- Insere itens nessa compra (o que aciona os gatilhos e muda o estoque e valor_total)
    INSERT INTO compra_ingresso (id_compra, id_ingresso, quantidade)
    VALUES (99, 4, 3); -- Compra 3 Passaportes Estudante

    -- Exibe os dados de dentro da transação para provar que as alterações ocorreram temporariamente
    SELECT 'DENTRO DA TRANSAÇÃO' AS status_momento, id_compra, valor_total FROM compra WHERE id_compra = 99;

-- Passo 3: Forçar a desistência/erro cancelando todas as operações do bloco de forma atômica
ROLLBACK;

-- Passo 4: Verificar se a transação realmente não deixou rastros ou sujeiras no banco (Deve retornar vazio)
SELECT 'FORA DA TRANSAÇÃO (PÓS-ROLLBACK)' AS status_momento, id_compra, valor_total 
FROM compra 
WHERE id_compra = 99;