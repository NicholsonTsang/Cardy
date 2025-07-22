-- =================================================================
-- AUDIT SYSTEM REVAMP - SCHEMA MIGRATION
-- Comprehensive redesign of audit logging and admin feedback system
-- =================================================================

-- 1. Create standardized action type enum
DO $$ BEGIN
    CREATE TYPE "AdminActionType" AS ENUM (
        -- User Management Actions
        'USER_REGISTRATION',
        'ROLE_CHANGE', 
        'VERIFICATION_REVIEW',
        'VERIFICATION_RESET',
        'MANUAL_VERIFICATION',
        
        -- Card Management Actions  
        'CARD_CREATION',
        'CARD_UPDATE',
        'CARD_DELETION',
        
        -- Batch Management Actions
        'BATCH_CREATION',
        'BATCH_STATUS_CHANGE', 
        'CARD_GENERATION',
        
        -- Payment Management Actions
        'PAYMENT_WAIVER',
        'PAYMENT_CREATION',
        'PAYMENT_CONFIRMATION',
        'PAYMENT_REFUND',
        
        -- Print Request Actions
        'PRINT_REQUEST_STATUS_UPDATE',
        'PRINT_REQUEST_WITHDRAWAL',
        
        -- System Actions
        'SYSTEM_CONFIGURATION',
        'BULK_OPERATION'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Create action severity enum for prioritization
DO $$ BEGIN
    CREATE TYPE "ActionSeverity" AS ENUM (
        'LOW',      -- Regular operations (card creation, updates)
        'MEDIUM',   -- Important operations (verification changes, payments)
        'HIGH',     -- Critical operations (role changes, system config)
        'CRITICAL'  -- Security-sensitive operations (admin promotion, bulk operations)
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. Create feedback status enum
DO $$ BEGIN
    CREATE TYPE "FeedbackStatus" AS ENUM (
        'DRAFT',     -- Admin is composing feedback
        'SENT',      -- Feedback sent to user
        'READ',      -- User has viewed feedback
        'RESOLVED'   -- Issue addressed
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 4. Backup existing data before migration
CREATE TABLE IF NOT EXISTS admin_audit_log_backup AS 
    SELECT * FROM admin_audit_log;

CREATE TABLE IF NOT EXISTS admin_feedback_history_backup AS 
    SELECT * FROM admin_feedback_history;

-- 5. Drop existing tables and recreate with optimized structure
DROP TABLE IF EXISTS admin_feedback_history CASCADE;
DROP TABLE IF EXISTS admin_audit_log CASCADE;

-- 6. Create optimized audit log table
CREATE TABLE admin_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Actor Information (WHO)
    admin_user_id UUID NOT NULL, -- REFERENCES auth.users(id)
    admin_email VARCHAR(255) NOT NULL, -- Denormalized for performance
    
    -- Target Information (WHAT/WHO affected)
    target_user_id UUID, -- REFERENCES auth.users(id) - nullable for system actions
    target_user_email VARCHAR(255), -- Denormalized for performance
    target_entity_type VARCHAR(50), -- 'card', 'batch', 'print_request', 'user_profile', etc.
    target_entity_id UUID, -- ID of the affected entity
    
    -- Action Information (WHAT happened)
    action_type "AdminActionType" NOT NULL,
    action_severity "ActionSeverity" NOT NULL DEFAULT 'MEDIUM',
    action_summary VARCHAR(500) NOT NULL, -- Concise description for display
    
    -- Change Tracking (BEFORE/AFTER)
    old_values JSONB, -- Previous state (size-limited)
    new_values JSONB, -- New state (size-limited)
    
    -- Context & Metadata
    reason TEXT, -- Business justification (max 1000 chars)
    metadata JSONB DEFAULT '{}', -- Structured metadata (request_id, ip_address, etc.)
    
    -- Performance & Archival
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    retention_date TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 years'), -- Compliance retention
    
    -- Constraints
    CONSTRAINT chk_reason_length CHECK (length(reason) <= 1000),
    CONSTRAINT chk_action_summary_length CHECK (length(action_summary) <= 500),
    CONSTRAINT chk_old_values_size CHECK (pg_column_size(old_values) <= 32768), -- 32KB limit
    CONSTRAINT chk_new_values_size CHECK (pg_column_size(new_values) <= 32768)  -- 32KB limit
);

-- 7. Create admin feedback system (separate from audit logs)
CREATE TABLE admin_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Communication Parties
    admin_user_id UUID NOT NULL, -- REFERENCES auth.users(id) - who sent feedback
    admin_name VARCHAR(255) NOT NULL, -- Denormalized admin name
    target_user_id UUID NOT NULL, -- REFERENCES auth.users(id) - who receives feedback
    
    -- Feedback Context
    context_type VARCHAR(50) NOT NULL, -- 'verification', 'print_request', 'general', etc.
    context_entity_id UUID, -- Related entity ID
    subject VARCHAR(200) NOT NULL, -- Feedback subject/title
    
    -- Feedback Content
    content TEXT NOT NULL,
    status "FeedbackStatus" DEFAULT 'DRAFT',
    
    -- Threading (for conversation chains)
    thread_id UUID, -- Groups related feedback exchanges
    reply_to_id UUID REFERENCES admin_feedback(id), -- Links to previous message
    
    -- Metadata
    is_internal BOOLEAN DEFAULT FALSE, -- Internal admin notes vs user-facing
    priority VARCHAR(20) DEFAULT 'normal', -- 'low', 'normal', 'high', 'urgent'
    tags TEXT[], -- Categorization tags
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE, -- When sent to user
    read_at TIMESTAMP WITH TIME ZONE, -- When user read it
    
    -- Constraints
    CONSTRAINT chk_subject_length CHECK (length(subject) <= 200),
    CONSTRAINT chk_content_length CHECK (length(content) <= 5000), -- Reasonable limit
    CONSTRAINT chk_valid_priority CHECK (priority IN ('low', 'normal', 'high', 'urgent'))
);

-- 8. Create performance-optimized indexes
-- Audit Log Indexes
CREATE INDEX idx_audit_admin_user ON admin_audit_log(admin_user_id);
CREATE INDEX idx_audit_target_user ON admin_audit_log(target_user_id);
CREATE INDEX idx_audit_action_type ON admin_audit_log(action_type);
CREATE INDEX idx_audit_severity ON admin_audit_log(action_severity);
CREATE INDEX idx_audit_created_at ON admin_audit_log(created_at DESC);
CREATE INDEX idx_audit_retention ON admin_audit_log(retention_date);

-- Composite indexes for common queries
CREATE INDEX idx_audit_action_date ON admin_audit_log(action_type, created_at DESC);
CREATE INDEX idx_audit_target_action ON admin_audit_log(target_user_id, action_type, created_at DESC);
CREATE INDEX idx_audit_admin_date ON admin_audit_log(admin_user_id, created_at DESC);
CREATE INDEX idx_audit_entity ON admin_audit_log(target_entity_type, target_entity_id);

-- Recent activity partial index (last 30 days for dashboard)
CREATE INDEX idx_audit_recent ON admin_audit_log(created_at DESC, action_type)
    WHERE created_at > NOW() - INTERVAL '30 days';

-- Admin Feedback Indexes  
CREATE INDEX idx_feedback_admin_user ON admin_feedback(admin_user_id);
CREATE INDEX idx_feedback_target_user ON admin_feedback(target_user_id);
CREATE INDEX idx_feedback_context ON admin_feedback(context_type, context_entity_id);
CREATE INDEX idx_feedback_thread ON admin_feedback(thread_id, created_at);
CREATE INDEX idx_feedback_status ON admin_feedback(status);
CREATE INDEX idx_feedback_created_at ON admin_feedback(created_at DESC);

-- Composite indexes for conversations
CREATE INDEX idx_feedback_user_context ON admin_feedback(target_user_id, context_type, created_at DESC);
CREATE INDEX idx_feedback_unread ON admin_feedback(target_user_id, status) 
    WHERE status IN ('SENT');

-- 9. Create JSONB indexes for metadata queries
CREATE INDEX idx_audit_metadata_gin ON admin_audit_log USING gin(metadata);
CREATE INDEX idx_audit_old_values_gin ON admin_audit_log USING gin(old_values);
CREATE INDEX idx_audit_new_values_gin ON admin_audit_log USING gin(new_values);

-- 10. Create table partitioning for audit logs (by month)
-- This will improve performance for large datasets
-- Note: This requires PostgreSQL 10+

-- Create partitioned table structure
CREATE TABLE admin_audit_log_partitioned (
    LIKE admin_audit_log INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- Create initial partitions for current and next 12 months
DO $$ 
DECLARE
    start_date DATE;
    end_date DATE;
    partition_name TEXT;
    counter INTEGER := 0;
BEGIN
    -- Start from beginning of current month
    start_date := date_trunc('month', CURRENT_DATE);
    
    WHILE counter < 12 LOOP
        end_date := start_date + INTERVAL '1 month';
        partition_name := 'admin_audit_log_' || to_char(start_date, 'YYYY_MM');
        
        EXECUTE format('CREATE TABLE %I PARTITION OF admin_audit_log_partitioned 
                       FOR VALUES FROM (%L) TO (%L)', 
                       partition_name, start_date, end_date);
        
        start_date := end_date;
        counter := counter + 1;
    END LOOP;
END $$;

-- 11. Create triggers for automated maintenance

-- Trigger to auto-populate admin email
CREATE OR REPLACE FUNCTION populate_admin_email()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.admin_email IS NULL THEN
        SELECT email INTO NEW.admin_email 
        FROM auth.users 
        WHERE id = NEW.admin_user_id;
    END IF;
    
    IF NEW.target_user_email IS NULL AND NEW.target_user_id IS NOT NULL THEN
        SELECT email INTO NEW.target_user_email
        FROM auth.users 
        WHERE id = NEW.target_user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_populate_admin_email
    BEFORE INSERT ON admin_audit_log
    FOR EACH ROW EXECUTE FUNCTION populate_admin_email();

-- Trigger for admin feedback threading
CREATE OR REPLACE FUNCTION setup_feedback_thread()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-generate thread_id if not provided
    IF NEW.thread_id IS NULL THEN
        NEW.thread_id := gen_random_uuid();
    END IF;
    
    -- Set updated_at
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_setup_feedback_thread
    BEFORE INSERT OR UPDATE ON admin_feedback
    FOR EACH ROW EXECUTE FUNCTION setup_feedback_thread();

-- 12. Create helper functions for data migration
CREATE OR REPLACE FUNCTION migrate_audit_data()
RETURNS INTEGER AS $$
DECLARE
    migrated_count INTEGER := 0;
    rec RECORD;
    mapped_action_type "AdminActionType";
    action_severity "ActionSeverity";
BEGIN
    FOR rec IN SELECT * FROM admin_audit_log_backup LOOP
        -- Map old action types to new enum values
        CASE rec.action_type
            WHEN 'USER_REGISTRATION' THEN 
                mapped_action_type := 'USER_REGISTRATION';
                action_severity := 'LOW';
            WHEN 'ROLE_CHANGE' THEN 
                mapped_action_type := 'ROLE_CHANGE';
                action_severity := 'HIGH';
            WHEN 'VERIFICATION_REVIEW' THEN 
                mapped_action_type := 'VERIFICATION_REVIEW';
                action_severity := 'MEDIUM';
            WHEN 'CARD_CREATION' THEN 
                mapped_action_type := 'CARD_CREATION';
                action_severity := 'LOW';
            WHEN 'CARD_UPDATE' THEN 
                mapped_action_type := 'CARD_UPDATE';
                action_severity := 'LOW';
            WHEN 'CARD_DELETION' THEN 
                mapped_action_type := 'CARD_DELETION';
                action_severity := 'MEDIUM';
            WHEN 'PAYMENT_WAIVER' THEN 
                mapped_action_type := 'PAYMENT_WAIVER';
                action_severity := 'HIGH';
            WHEN 'PRINT_REQUEST_STATUS_UPDATE' THEN 
                mapped_action_type := 'PRINT_REQUEST_STATUS_UPDATE';
                action_severity := 'LOW';
            ELSE 
                -- Skip unknown action types or map to system configuration
                CONTINUE;
        END CASE;
        
        -- Insert into new table structure
        INSERT INTO admin_audit_log (
            id,
            admin_user_id,
            target_user_id,
            action_type,
            action_severity,
            action_summary,
            old_values,
            new_values,
            reason,
            metadata,
            created_at
        ) VALUES (
            rec.id,
            rec.admin_user_id,
            rec.target_user_id,
            mapped_action_type,
            action_severity,
            COALESCE(rec.reason, 'Migrated audit entry'),
            rec.old_values,
            rec.new_values,
            rec.reason,
            COALESCE(rec.action_details, '{}'),
            rec.created_at
        );
        
        migrated_count := migrated_count + 1;
    END LOOP;
    
    RETURN migrated_count;
END;
$$ LANGUAGE plpgsql;

-- 13. Create archive management functions
CREATE OR REPLACE FUNCTION archive_old_audit_logs(months_to_keep INTEGER DEFAULT 24)
RETURNS INTEGER AS $$
DECLARE
    archived_count INTEGER;
    cutoff_date TIMESTAMP WITH TIME ZONE;
BEGIN
    cutoff_date := NOW() - INTERVAL '1 month' * months_to_keep;
    
    -- Move old records to archive table
    CREATE TABLE IF NOT EXISTS admin_audit_log_archive (
        LIKE admin_audit_log INCLUDING ALL
    );
    
    WITH moved_rows AS (
        DELETE FROM admin_audit_log 
        WHERE created_at < cutoff_date
        RETURNING *
    )
    INSERT INTO admin_audit_log_archive 
    SELECT * FROM moved_rows;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

-- 14. Create views for common queries
CREATE VIEW recent_admin_activity AS
SELECT 
    aal.id,
    aal.admin_email,
    aal.target_user_email,
    aal.action_type,
    aal.action_severity,
    aal.action_summary,
    aal.created_at,
    aal.reason
FROM admin_audit_log aal
WHERE aal.created_at > NOW() - INTERVAL '30 days'
ORDER BY aal.created_at DESC;

CREATE VIEW user_feedback_summary AS
SELECT 
    af.target_user_id,
    af.context_type,
    COUNT(*) as feedback_count,
    COUNT(*) FILTER (WHERE status = 'SENT') as unread_count,
    MAX(af.created_at) as last_feedback_date
FROM admin_feedback af
GROUP BY af.target_user_id, af.context_type;

-- 15. Grant appropriate permissions
-- Note: Adjust these based on your RLS policies
GRANT SELECT, INSERT ON admin_audit_log TO authenticated;
GRANT SELECT, INSERT, UPDATE ON admin_feedback TO authenticated;
GRANT USAGE ON SEQUENCE admin_audit_log_id_seq TO authenticated;
GRANT USAGE ON SEQUENCE admin_feedback_id_seq TO authenticated;

-- 16. Performance monitoring queries (for testing)
-- These can be used to verify the migration was successful

-- Query to check data distribution
CREATE VIEW audit_log_statistics AS
SELECT 
    action_type,
    action_severity,
    COUNT(*) as count,
    MIN(created_at) as earliest,
    MAX(created_at) as latest,
    AVG(pg_column_size(old_values)) as avg_old_values_size,
    AVG(pg_column_size(new_values)) as avg_new_values_size
FROM admin_audit_log 
GROUP BY action_type, action_severity
ORDER BY count DESC;

COMMENT ON TABLE admin_audit_log IS 'Immutable audit trail for administrative actions with compliance retention';
COMMENT ON TABLE admin_feedback IS 'Admin-user communication system with conversation threading';
COMMENT ON COLUMN admin_audit_log.retention_date IS 'Date when record can be archived for compliance';
COMMENT ON COLUMN admin_feedback.thread_id IS 'Groups related feedback messages in conversation';