-- Updated schema.sql with new audit system
-- This replaces the existing audit_log and feedback_history sections

-- Replace the existing enum types and tables with these updated versions:

-- 1. Enhanced enum types for audit system
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

-- 2. Updated admin_audit_log table (replace existing)
DROP TABLE IF EXISTS admin_audit_log CASCADE;

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

-- 3. New admin_feedback table (replaces admin_feedback_history)
DROP TABLE IF EXISTS admin_feedback_history CASCADE;

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

-- 4. Performance-optimized indexes
-- Audit Log Indexes
CREATE INDEX IF NOT EXISTS idx_audit_admin_user ON admin_audit_log(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_target_user ON admin_audit_log(target_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_action_type ON admin_audit_log(action_type);
CREATE INDEX IF NOT EXISTS idx_audit_severity ON admin_audit_log(action_severity);
CREATE INDEX IF NOT EXISTS idx_audit_created_at ON admin_audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_retention ON admin_audit_log(retention_date);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_audit_action_date ON admin_audit_log(action_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_target_action ON admin_audit_log(target_user_id, action_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_admin_date ON admin_audit_log(admin_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON admin_audit_log(target_entity_type, target_entity_id);

-- Recent activity partial index (last 30 days for dashboard)
CREATE INDEX IF NOT EXISTS idx_audit_recent ON admin_audit_log(created_at DESC, action_type)
    WHERE created_at > NOW() - INTERVAL '30 days';

-- Admin Feedback Indexes  
CREATE INDEX IF NOT EXISTS idx_feedback_admin_user ON admin_feedback(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_target_user ON admin_feedback(target_user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_context ON admin_feedback(context_type, context_entity_id);
CREATE INDEX IF NOT EXISTS idx_feedback_thread ON admin_feedback(thread_id, created_at);
CREATE INDEX IF NOT EXISTS idx_feedback_status ON admin_feedback(status);
CREATE INDEX IF NOT EXISTS idx_feedback_created_at ON admin_feedback(created_at DESC);

-- Composite indexes for conversations
CREATE INDEX IF NOT EXISTS idx_feedback_user_context ON admin_feedback(target_user_id, context_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_unread ON admin_feedback(target_user_id, status) 
    WHERE status IN ('SENT');

-- 5. JSONB indexes for metadata queries
CREATE INDEX IF NOT EXISTS idx_audit_metadata_gin ON admin_audit_log USING gin(metadata);
CREATE INDEX IF NOT EXISTS idx_audit_old_values_gin ON admin_audit_log USING gin(old_values);
CREATE INDEX IF NOT EXISTS idx_audit_new_values_gin ON admin_audit_log USING gin(new_values);

-- 6. Triggers for automated maintenance

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

-- 7. Views for common queries
CREATE OR REPLACE VIEW recent_admin_activity AS
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

CREATE OR REPLACE VIEW user_feedback_summary AS
SELECT 
    af.target_user_id,
    af.context_type,
    COUNT(*) as feedback_count,
    COUNT(*) FILTER (WHERE status = 'SENT') as unread_count,
    MAX(af.created_at) as last_feedback_date
FROM admin_feedback af
GROUP BY af.target_user_id, af.context_type;

-- 8. Comments for documentation
COMMENT ON TABLE admin_audit_log IS 'Immutable audit trail for administrative actions with compliance retention';
COMMENT ON TABLE admin_feedback IS 'Admin-user communication system with conversation threading';
COMMENT ON COLUMN admin_audit_log.retention_date IS 'Date when record can be archived for compliance';
COMMENT ON COLUMN admin_feedback.thread_id IS 'Groups related feedback messages in conversation';
COMMENT ON COLUMN admin_audit_log.action_severity IS 'Impact level: LOW=routine, MEDIUM=important, HIGH=critical, CRITICAL=security-sensitive';
COMMENT ON COLUMN admin_audit_log.metadata IS 'Structured context data (max 32KB): IP addresses, request IDs, business metrics';

-- Instructions for migration:
-- 1. Run the audit system migration first: sql/migrations/audit_system_revamp.sql
-- 2. Update all stored procedures: sql/migrations/audit_system_stored_procedures.sql  
-- 3. Update existing procedures: sql/migrations/update_existing_procedures.sql
-- 4. Replace the audit_log and feedback_history sections in schema.sql with this content
-- 5. Update frontend to use new stores: src/stores/admin/auditLog.ts and src/stores/admin/adminFeedback.ts