# Operations Logging - Quick Reference

## Add Logging to Any Function

### Pattern
```sql
-- At the end of your write operation, before RETURN:
PERFORM log_operation('<Action> <resource>: <name> (ID: <id>)');
```

### Copy-Paste Templates

#### CREATE Operations
```sql
PERFORM log_operation('Created card: ' || p_name || ' (ID: ' || v_card_id || ')');
PERFORM log_operation('Created content item: ' || p_name || ' (ID: ' || v_item_id || ')');
PERFORM log_operation('Created batch: ' || p_batch_name || ' (ID: ' || v_batch_id || ')');
PERFORM log_operation('Issued batch: ' || p_cards_count || ' cards for card ' || p_card_id);
```

#### UPDATE Operations
```sql
PERFORM log_operation('Updated card: ' || p_name || ' (ID: ' || p_card_id || ')');
PERFORM log_operation('Updated content item: ' || p_name || ' (ID: ' || p_item_id || ')');
PERFORM log_operation('Updated batch: ' || p_batch_name || ' (ID: ' || p_batch_id || ')');
PERFORM log_operation('Updated print request status to ' || p_status || ' (ID: ' || p_request_id || ')');
```

#### DELETE Operations
```sql
PERFORM log_operation('Deleted card: ' || v_card_name || ' (ID: ' || p_card_id || ')');
PERFORM log_operation('Deleted content item: ' || v_item_name || ' (ID: ' || p_item_id || ')');
PERFORM log_operation('Deleted batch: ' || v_batch_name || ' (ID: ' || p_batch_id || ')');
```

#### Custom Actions
```sql
PERFORM log_operation('Activated issued card: ' || p_card_id);
PERFORM log_operation('Waived payment for batch: ' || p_batch_id);
PERFORM log_operation('Reordered content items for card: ' || p_card_id);
PERFORM log_operation('Withdrew print request for batch: ' || p_batch_id);
PERFORM log_operation('Changed user role to ' || p_new_role || ' for user ' || p_user_id);
```

## View Logs (Admin Only)

### Recent Operations
```sql
SELECT * FROM get_operations_log(50, 0);
```

### Filter by User
```sql
SELECT * FROM get_operations_log(100, 0, '<user-uuid>', NULL);
```

### Filter by Role
```sql
SELECT * FROM get_operations_log(100, 0, NULL, 'admin'::"UserRole");
SELECT * FROM get_operations_log(100, 0, NULL, 'cardIssuer'::"UserRole");
SELECT * FROM get_operations_log(100, 0, NULL, 'user'::"UserRole");
```

### Get Statistics
```sql
SELECT * FROM get_operations_log_stats();
```

## Deploy Commands

```bash
# 1. Regenerate combined SQL
cd /Users/nicholsontsang/coding/Cardy
bash scripts/combine-storeproc.sh

# 2. Deploy to database
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql

# Or use Supabase Dashboard SQL Editor
```

## Full Example Function

```sql
CREATE OR REPLACE FUNCTION create_something(
    p_name TEXT,
    p_description TEXT
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_id UUID;
BEGIN
    -- Your business logic
    INSERT INTO sometable (
        user_id,
        name,
        description
    ) VALUES (
        auth.uid(),
        p_name,
        p_description
    ) RETURNING id INTO v_id;
    
    -- Log the operation (always at the end, before RETURN)
    PERFORM log_operation('Created something: ' || p_name || ' (ID: ' || v_id || ')');
    
    RETURN v_id;
END;
$$;
```

## Important Notes

- ✅ Use `PERFORM` not `SELECT` (it's a VOID function)
- ✅ Always add logging BEFORE the final RETURN
- ✅ Include the resource name and ID in the message
- ✅ Keep messages simple and consistent
- ✅ Logging failures won't break your operation (fails silently with warning)
- ✅ User ID and role are captured automatically

