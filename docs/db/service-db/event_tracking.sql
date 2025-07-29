<!-- Event Tracking Service SQL -->
<xaiFile name="event_tracking.sql" contentType="text/sql">
-- event_tracking.sql: Schema for Event Tracking Service
-- Table: queue_tasks
-- Indexes for task processing

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table: queue_tasks
CREATE TABLE IF NOT EXISTS queue_tasks (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    status VARCHAR(20) CHECK (status IN ('pending', 'completed', 'failed')),
    payload JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_queue_tasks_merchant_id ON queue_tasks (merchant_id);
CREATE INDEX IF NOT EXISTS idx_queue_tasks_event_type ON queue_tasks (event_type);
CREATE INDEX IF NOT EXISTS idx_queue_tasks_created_at ON queue_tasks (created_at);

-- Function: Process task
CREATE OR REPLACE FUNCTION process_task(
    p_task_id UUID,
    p_status VARCHAR
) RETURNS VOID AS $$
BEGIN
    UPDATE queue_tasks
    SET status = p_status,
        payload = jsonb_set(payload, '{processed_at}', to_jsonb(CURRENT_TIMESTAMP))
    WHERE task_id = p_task_id;
END;
$$ LANGUAGE plpgsql;
</xaiFile>