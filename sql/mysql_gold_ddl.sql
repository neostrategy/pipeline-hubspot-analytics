-- ---------------------------------------------------------------------------
-- Camada gold publicada no MySQL para consumo do BI.
--
-- Fonte da verdade: DuckLake (main_gold). Estas tabelas são uma CÓPIA,
-- recriada a cada execução do pipeline. Não escreva nelas manualmente —
-- qualquer alteração é sobrescrita no próximo run.
--
-- Convenções:
--   * Todos os timestamps estão em UTC. MySQL DATETIME não guarda fuso;
--     o BI precisa converter na leitura se quiser horário local.
--   * DATETIME(3) = milissegundos. O DuckDB guarda microssegundos; a
--     precisão extra é truncada de propósito (irrelevante para análise).
--   * Só as chaves são NOT NULL. Propriedades do HubSpot são nulas com
--     frequência e não devem quebrar a carga.
--   * utf8mb4 obrigatório: nomes e títulos têm acento e emoji.
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;

-- ===========================================================================
-- HUBS
-- ===========================================================================

CREATE TABLE IF NOT EXISTS analytics_contacts (
    contact_id            BIGINT        NOT NULL,
    email                 VARCHAR(320),                -- limite do RFC 5321
    first_name            VARCHAR(128),
    last_name             VARCHAR(128),
    phone                 VARCHAR(64),
    lifecycle_stage       VARCHAR(64),
    lead_status           VARCHAR(64),
    owner_id              BIGINT,
    original_source       VARCHAR(64),                 -- first-touch
    latest_source         VARCHAR(64),                 -- last-touch
    latest_source_at      DATETIME(3),
    origem_analytics      VARCHAR(64),
    origem_detalhe_1      VARCHAR(255),
    origem_detalhe_2      VARCHAR(255),
    primeira_url          VARCHAR(1024),
    ultima_url            VARCHAR(1024),
    criacao_origem_label  VARCHAR(128),
    criacao_detalhe_1     VARCHAR(255),
    criacao_detalhe_2     VARCHAR(255),
    criacao_detalhe_3     VARCHAR(255),
    clicou_linkedin_ad    VARCHAR(16),                 -- CONFERIR: bool ou texto?
    gclid                 VARCHAR(255),
    fbclid                VARCHAR(255),
    utm_source            VARCHAR(255),
    utm_medium            VARCHAR(255),
    utm_campaign          VARCHAR(255),
    utm_content           VARCHAR(255),
    utm_term              VARCHAR(255),
    campanha              VARCHAR(255),
    tipo_de_campanha      VARCHAR(255),
    created_at            DATETIME(3),
    updated_at            DATETIME(3),
    _loaded_at            DATETIME(3),
    PRIMARY KEY (contact_id),
    KEY ix_contacts_owner   (owner_id),
    KEY ix_contacts_created (created_at),
    KEY ix_contacts_email   (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS analytics_companies (
    company_id    BIGINT        NOT NULL,
    company_name  VARCHAR(255),
    domain        VARCHAR(255),
    owner_id      BIGINT,
    cnpj          VARCHAR(255),
    created_at    DATETIME(3),
    updated_at    DATETIME(3),
    _loaded_at    DATETIME(3),
    PRIMARY KEY (company_id),
    KEY ix_companies_owner  (owner_id),
    KEY ix_companies_domain (domain)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS analytics_deals (
    deal_id             BIGINT        NOT NULL,
    deal_name           VARCHAR(512),
    pipeline_id         VARCHAR(64),
    stage_id            VARCHAR(64),
    amount              DECIMAL(15,2),               -- igual ao staging
    owner_id            BIGINT,
    deal_type           VARCHAR(64),
    created_at          DATETIME(3),
    updated_at          DATETIME(3),
    close_date          DATETIME(3),
    primary_contact_id  BIGINT,
    company_id          BIGINT,
    is_won              TINYINT(1),                  -- 0/1
    is_closed           TINYINT(1),
    _loaded_at          DATETIME(3),
    PRIMARY KEY (deal_id),
    KEY ix_deals_owner    (owner_id),
    KEY ix_deals_stage    (stage_id),
    KEY ix_deals_created  (created_at),
    KEY ix_deals_close    (close_date),
    KEY ix_deals_contact  (primary_contact_id),
    KEY ix_deals_company  (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS analytics_calls (
    call_id      BIGINT        NOT NULL,
    owner_id     BIGINT,
    title        VARCHAR(512),
    direction    VARCHAR(32),
    disposition  VARCHAR(64),
    status       VARCHAR(32),
    duration_ms  BIGINT,                             -- ms; BIGINT por segurança
    occurred_at  DATETIME(3),
    created_at   DATETIME(3),
    updated_at   DATETIME(3),
    _loaded_at   DATETIME(3),
    PRIMARY KEY (call_id),
    KEY ix_calls_owner    (owner_id),
    KEY ix_calls_occurred (occurred_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS analytics_meetings (
    meeting_id   BIGINT        NOT NULL,
    owner_id     BIGINT,
    title        VARCHAR(512),
    outcome      VARCHAR(64),
    location     VARCHAR(512),
    starts_at    DATETIME(3),
    ends_at      DATETIME(3),
    occurred_at  DATETIME(3),
    created_at   DATETIME(3),
    updated_at   DATETIME(3),
    _loaded_at   DATETIME(3),
    PRIMARY KEY (meeting_id),
    KEY ix_meetings_owner    (owner_id),
    KEY ix_meetings_occurred (occurred_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ===========================================================================
-- HISTÓRICO (SCD2 materializado)
-- ===========================================================================

CREATE TABLE IF NOT EXISTS analytics_deal_stage_hist (
    deal_id         BIGINT        NOT NULL,
    pipeline_id     VARCHAR(64),
    stage_id        VARCHAR(64),
    valid_from      DATETIME(3)   NOT NULL,
    valid_to        DATETIME(3),                     -- NULL = versão vigente
    is_current      TINYINT(1),
    duration_hours  DECIMAL(12,2),
    PRIMARY KEY (deal_id, valid_from),
    KEY ix_hist_stage   (stage_id),
    KEY ix_hist_current (is_current)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ===========================================================================
-- ASSOCIAÇÕES (N:N)
-- ===========================================================================

CREATE TABLE IF NOT EXISTS assoc_deal_contact (
    deal_id     BIGINT      NOT NULL,
    contact_id  BIGINT      NOT NULL,
    assoc_type  VARCHAR(64),
    is_primary  TINYINT(1),
    _loaded_at  DATETIME(3),
    PRIMARY KEY (deal_id, contact_id),
    KEY ix_adc_contact (contact_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS assoc_deal_company (
    deal_id     BIGINT      NOT NULL,
    company_id  BIGINT      NOT NULL,
    assoc_type  VARCHAR(64),
    _loaded_at  DATETIME(3),
    PRIMARY KEY (deal_id, company_id),
    KEY ix_adco_company (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS assoc_activity_contact (
    engagement_type  VARCHAR(16) NOT NULL,           -- CALL | MEETING
    activity_id      BIGINT      NOT NULL,
    contact_id       BIGINT      NOT NULL,
    assoc_type       VARCHAR(64),
    _loaded_at       DATETIME(3),
    PRIMARY KEY (engagement_type, activity_id, contact_id),
    KEY ix_aac_contact (contact_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS assoc_activity_deal (
    engagement_type  VARCHAR(16) NOT NULL,
    activity_id      BIGINT      NOT NULL,
    deal_id          BIGINT      NOT NULL,
    assoc_type       VARCHAR(64),
    _loaded_at       DATETIME(3),
    PRIMARY KEY (engagement_type, activity_id, deal_id),
    KEY ix_aad_deal (deal_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS assoc_activity_company (
    engagement_type  VARCHAR(16) NOT NULL,
    activity_id      BIGINT      NOT NULL,
    company_id       BIGINT      NOT NULL,
    assoc_type       VARCHAR(64),
    _loaded_at       DATETIME(3),
    PRIMARY KEY (engagement_type, activity_id, company_id),
    KEY ix_aaco_company (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ===========================================================================
-- FATOS E MARTS
-- ===========================================================================

CREATE TABLE IF NOT EXISTS fct_activities (
    activity_id              BIGINT      NOT NULL,
    engagement_type          VARCHAR(16) NOT NULL,   -- CALL | MEETING
    contact_id               BIGINT,
    deal_id                  BIGINT,
    company_id               BIGINT,
    empresa_herdada_do_deal  TINYINT(1),
    owner_id                 BIGINT,
    title                    VARCHAR(512),
    occurred_at              DATETIME(3),
    occurred_data            DATE,                   -- pronta para coorte
    outcome                  VARCHAR(64),
    duration_ms              BIGINT,
    duracao_min              DECIMAL(10,2),
    starts_at                DATETIME(3),
    ends_at                  DATETIME(3),
    sem_negocio              TINYINT(1),
    _loaded_at               DATETIME(3),
    PRIMARY KEY (activity_id, engagement_type),
    KEY ix_fa_owner    (owner_id),
    KEY ix_fa_data     (occurred_data),
    KEY ix_fa_deal     (deal_id),
    KEY ix_fa_contact  (contact_id),
    KEY ix_fa_company  (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS mart_entradas (
    contact_id         BIGINT        NOT NULL,
    email              VARCHAR(320),
    nome               VARCHAR(257),                 -- first + ' ' + last
    owner_id           BIGINT,
    lifecycle_stage    VARCHAR(64),

    entrada_em         DATETIME(3),
    entrada_data       DATE,
    mes_entrada        CHAR(7),                      -- YYYY-MM
    semana_entrada     CHAR(8),                      -- YYYY-Www

    origem             VARCHAR(64),
    origem_detalhe     VARCHAR(255),
    origem_detalhe_2   VARCHAR(255),
    primeira_url       VARCHAR(1024),

    origem_recente     VARCHAR(64),
    origem_recente_em  DATETIME(3),

    utm_source         VARCHAR(255),
    utm_medium         VARCHAR(255),
    utm_campaign       VARCHAR(255),
    utm_content        VARCHAR(255),
    utm_term           VARCHAR(255),
    campanha           VARCHAR(255),

    veio_google_ads    TINYINT(1),
    veio_meta_ads      TINYINT(1),
    criacao_origem     VARCHAR(128),
    is_importacao      TINYINT(1),                   -- ruído de coorte

    _loaded_at         DATETIME(3),
    PRIMARY KEY (contact_id),
    KEY ix_me_data     (entrada_data),
    KEY ix_me_mes      (mes_entrada),
    KEY ix_me_origem   (origem),
    KEY ix_me_campanha (campanha),
    KEY ix_me_owner    (owner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
