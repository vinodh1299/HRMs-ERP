-- Asian Christian Academy of India - Postgres 16 + pgvector Schema Blueprint
-- Run this SQL on Postgres 16 database server to create vector search & ERP tables

-- 1. Enable pgvector extension for AI embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Knowledge Chunks Table for RAG Document Search
CREATE TABLE IF NOT EXISTS knowledge_chunks (
    id VARCHAR(64) PRIMARY KEY,
    category VARCHAR(64) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    embedding vector(1536), -- 1536-dimensional vector embedding
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Index for Fast Vector Cosine Similarity Search
CREATE INDEX IF NOT EXISTS knowledge_chunks_embedding_idx 
ON knowledge_chunks 
USING hnsw (embedding vector_cosine_ops);

-- 4. Staged Human-In-The-Loop Actions Table
CREATE TABLE IF NOT EXISTS agent_pending_actions (
    action_id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    action_type VARCHAR(64) NOT NULL,
    risk_level VARCHAR(16) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(32) DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. AI Chat Audit & Event Log Table
CREATE TABLE IF NOT EXISTS ai_audit_log (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    prompt TEXT NOT NULL,
    response_type VARCHAR(64) NOT NULL,
    response_text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
