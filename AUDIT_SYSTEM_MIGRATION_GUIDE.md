# Audit System Migration Guide

## Overview

This document provides a comprehensive guide for migrating from the old audit logging and admin feedback system to the new optimized architecture. The migration addresses critical performance, consistency, and cost optimization issues.

## Key Improvements

### 1. Schema Optimization
- **Separated Concerns**: Audit logs (immutable compliance) vs Admin feedback (user communication)
- **Performance Indexes**: Composite indexes for common query patterns
- **Size Constraints**: JSONB fields limited to 32KB to prevent excessive storage costs
- **Enum Validation**: Standardized action types with database-level constraints
- **Partitioning Ready**: Architecture supports future table partitioning by date

### 2. Audit Log Enhancements
- **Action Severity Levels**: LOW, MEDIUM, HIGH, CRITICAL for priority filtering
- **Standardized Format**: Consistent action_summary for display, detailed metadata for analysis
- **Enhanced Filtering**: Search by text, multiple action types, severity levels
- **Retention Policy**: 7-year compliance retention with automated archival
- **Performance**: Denormalized user emails, optimized indexes

### 3. Admin Feedback System
- **Conversation Threading**: Linked messages for better communication flow
- **Status Tracking**: DRAFT → SENT → READ → RESOLVED workflow
- **Priority Levels**: low, normal, high, urgent for triage
- **Context Linking**: Ties feedback to specific entities (verification, print requests)
- **Internal Notes**: Separate admin-only notes from user-facing feedback

### 4. Cost Optimization
- **Archive Strategy**: Automatic movement of old records to archive tables
- **Size Limits**: Prevents unlimited JSONB growth
- **Efficient Queries**: Partial indexes for recent data, composite indexes for common patterns
- **Data Lifecycle**: Clear retention and cleanup policies

## Migration Steps

### Step 1: Database Schema Migration

1. **Backup Current Data** (CRITICAL - DO NOT SKIP)
   ```sql
   -- Run these backup commands first
   CREATE TABLE admin_audit_log_backup AS SELECT * FROM admin_audit_log;
   CREATE TABLE admin_feedback_history_backup AS SELECT * FROM admin_feedback_history;
   ```

2. **Run Schema Migration**
   ```bash
   # Execute in order:
   psql -f sql/migrations/audit_system_revamp.sql
   psql -f sql/migrations/audit_system_stored_procedures.sql
   psql -f sql/migrations/update_existing_procedures.sql
   ```

3. **Verify Migration**
   ```sql
   -- Check data migration was successful
   SELECT migrate_audit_data();
   
   -- Verify new table structures
   \d admin_audit_log
   \d admin_feedback
   
   -- Check indexes are created
   \di admin_audit_log
   ```

### Step 2: Frontend Code Updates

1. **Update Store Imports**
   ```typescript
   // Replace old imports
   import { useAdminFeedbackStore } from '@/stores/admin/feedback'
   
   // With new imports
   import { useAuditLogStore } from '@/stores/admin/auditLog'
   import { useAdminFeedbackStore } from '@/stores/admin/adminFeedback'
   ```

2. **Update Component References**
   ```typescript
   // Old action type handling
   action_type: 'VERIFICATION_UPDATE'
   
   // New action type handling
   action_type: AdminActionType.VERIFICATION_REVIEW
   action_severity: ActionSeverity.MEDIUM
   ```

3. **Update Dashboard Statistics**
   ```typescript
   // New audit metrics available
   dashboardStats.total_audit_entries
   dashboardStats.critical_actions_today
   dashboardStats.high_severity_actions_week
   dashboardStats.unique_admin_users_month
   ```

### Step 3: Function Call Updates

1. **Replace Old RPC Calls**
   ```typescript
   // Old calls
   supabase.rpc('get_admin_audit_logs', {...})
   supabase.rpc('admin_get_system_stats', {...})
   
   // New calls
   supabase.rpc('get_admin_audit_logs_enhanced', {...})
   supabase.rpc('admin_get_system_stats_enhanced', {...})
   ```

2. **Update Feedback Calls**
   ```typescript
   // Old feedback creation
   supabase.rpc('create_or_update_admin_feedback', {...})
   
   // New feedback creation
   supabase.rpc('create_admin_feedback', {...})
   ```

### Step 4: Testing Checklist

#### Database Tests
- [ ] All enum types created successfully
- [ ] Audit log table created with proper constraints
- [ ] Admin feedback table created with threading support
- [ ] All indexes created and functional
- [ ] Triggers working (auto-populate emails, thread setup)
- [ ] Data migration completed without data loss
- [ ] Old data backed up and accessible

#### Stored Procedure Tests
- [ ] `log_admin_action()` creates proper audit entries
- [ ] `create_admin_feedback()` creates threaded conversations
- [ ] `get_admin_audit_logs_enhanced()` returns filtered results
- [ ] `admin_get_system_stats_enhanced()` includes new metrics
- [ ] All existing procedures updated to use new audit system
- [ ] Role-based security still enforced

#### Frontend Tests
- [ ] Admin dashboard loads without errors
- [ ] Recent Activity section displays properly
- [ ] Audit log filtering works with new action types
- [ ] Severity filtering displays correct results
- [ ] New statistics cards show audit metrics
- [ ] Action type labels display correctly
- [ ] Color coding works for severity levels
- [ ] Search functionality works across action summaries

#### Performance Tests
- [ ] Dashboard loads within 2 seconds
- [ ] Audit log queries complete within 1 second
- [ ] Large dataset filtering (>1000 records) performs well
- [ ] Memory usage remains stable with large result sets
- [ ] Index usage verified in query plans

#### Integration Tests
- [ ] Card creation logs audit entry
- [ ] User verification logs appropriate severity
- [ ] Payment waiver logs critical severity
- [ ] Role changes log high severity
- [ ] Feedback creation triggers audit log
- [ ] Thread conversations work properly
- [ ] Feedback status updates correctly

## Rollback Plan

If issues arise during migration:

### 1. Database Rollback
```sql
-- Restore original tables if needed
DROP TABLE IF EXISTS admin_audit_log CASCADE;
DROP TABLE IF EXISTS admin_feedback CASCADE;

-- Restore from backup
CREATE TABLE admin_audit_log AS SELECT * FROM admin_audit_log_backup;
CREATE TABLE admin_feedback_history AS SELECT * FROM admin_feedback_history_backup;

-- Restore old indexes and triggers
-- (Run original schema.sql sections)
```

### 2. Frontend Rollback
```bash
# Revert to old store files
git checkout HEAD~1 -- src/stores/admin/feedback.ts
git checkout HEAD~1 -- src/views/Dashboard/Admin/AdminDashboard.vue
```

### 3. Stored Procedure Rollback
```sql
-- Restore old stored procedures
-- (Run previous versions of stored procedure files)
```

## Post-Migration Maintenance

### 1. Monitor Performance
```sql
-- Check query performance
EXPLAIN ANALYZE SELECT * FROM admin_audit_log 
WHERE action_type = 'CARD_CREATION' AND created_at > NOW() - INTERVAL '7 days';

-- Monitor table sizes
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE tablename LIKE 'admin_%';
```

### 2. Set Up Automated Archival
```sql
-- Schedule monthly archival (example using pg_cron)
SELECT cron.schedule('archive-audit-logs', '0 0 1 * *', 'SELECT archive_old_audit_logs(24);');
```

### 3. Monitor Audit Metrics
- Track critical actions daily
- Review high-severity action trends weekly
- Monitor admin user activity monthly
- Verify retention compliance quarterly

## Troubleshooting

### Common Issues

1. **Migration Fails on Enum Creation**
   ```sql
   -- Drop existing enum if it exists
   DROP TYPE IF EXISTS "AdminActionType" CASCADE;
   -- Then re-run migration
   ```

2. **Index Creation Timeouts**
   ```sql
   -- Create indexes one by one with CONCURRENTLY
   CREATE INDEX CONCURRENTLY idx_audit_action_date ON admin_audit_log(action_type, created_at DESC);
   ```

3. **Frontend Type Errors**
   ```typescript
   // Ensure enum imports are correct
   import { AdminActionType, ActionSeverity } from '@/stores/admin/auditLog'
   ```

4. **Performance Issues**
   ```sql
   -- Analyze table statistics
   ANALYZE admin_audit_log;
   ANALYZE admin_feedback;
   
   -- Check index usage
   SELECT schemaname, tablename, indexname, idx_tup_read, idx_tup_fetch
   FROM pg_stat_user_indexes WHERE schemaname = 'public';
   ```

## Success Criteria

The migration is considered successful when:

1. **All tests pass** without errors
2. **Dashboard loads** within performance targets
3. **No data loss** during migration
4. **New features work** (severity filtering, enhanced search)
5. **Audit logging** captures all administrative actions
6. **Feedback system** supports threaded conversations
7. **Storage costs** are optimized with size constraints
8. **Performance** meets or exceeds previous system

## Support

If you encounter issues during migration:

1. Check this guide's troubleshooting section
2. Verify all steps completed in order
3. Review database logs for specific error messages
4. Test individual components in isolation
5. Use rollback plan if critical issues arise

Remember: **Always backup before migration** and test in a staging environment first.