# 🚀 Translation Feature Deployment Instructions

## ✅ What Was Fixed

You encountered this error:
```
Translation error: Error: Failed to store translations: column "metadata" of relation "credit_consumptions" does not exist
```

**Root causes**:
1. ❌ `consume_credits()` was trying to INSERT into non-existent `metadata` column
2. ❌ `store_card_translations()` was in wrong folder (client-side instead of server-side)

**Solutions**:
1. ✅ Fixed `consume_credits()` - removed metadata from INSERT statement
2. ✅ Moved `store_card_translations()` to `server-side/` with proper permissions
3. ✅ Added `GRANT EXECUTE TO service_role` for Edge Function access

---

## 📋 Deployment Steps

### Step 1: Deploy Database Changes

Open [Supabase SQL Editor](https://supabase.com/dashboard/project/mzgusshseqxrdrkvamrg/sql) and run **`DEPLOY_TRANSLATION_FIX.sql`**:

```bash
# Option A: Copy/paste the entire file content into SQL Editor
cat DEPLOY_TRANSLATION_FIX.sql
# Then paste and execute in Supabase Dashboard

# Option B: Use the pre-generated all_stored_procedures.sql
# (Already regenerated with all fixes)
```

The deployment script will:
- ✅ Update `consume_credits()` function (remove metadata column)
- ✅ Create server-side `store_card_translations()` function
- ✅ Grant permissions to service_role

### Step 2: Verify Deployment

Run this test query in SQL Editor:
```sql
-- Check if store_card_translations exists with correct signature
SELECT proname, pronargs, proargtypes 
FROM pg_proc 
WHERE proname = 'store_card_translations';

-- Should return 1 row with 6 arguments
```

### Step 3: Test Translation Feature

1. Open your CardStudio dashboard: `http://localhost:5173/cms/mycards`
2. Select any card
3. Go to **General** tab
4. Scroll to **Multi-Language Support** section
5. Click **Manage Translations** button
6. Select a language (e.g., "繁體中文 (Traditional Chinese)")
7. Verify credits are calculated correctly
8. Click **Start Translation**
9. ✅ Translation should complete successfully!

---

## 🏗️ Architecture Changes

### Before (Broken)
```
Frontend → Edge Function → Client-Side Stored Procedure → ❌ Error
                            (uses auth.uid(), which is NULL)
```

### After (Fixed)
```
Frontend → Edge Function → Server-Side Stored Procedure → ✅ Success
                            (uses explicit p_user_id parameter)
```

### File Structure
```
sql/storeproc/
├── client-side/                    # Called by frontend via supabase.rpc()
│   ├── credit_management.sql       # ✅ Fixed consume_credits()
│   └── 12_translation_management.sql  # Removed duplicate
│
└── server-side/                    # Called by Edge Functions
    ├── translation_management.sql  # ✅ NEW - store_card_translations()
    ├── credit_purchase_completion.sql
    └── 05_payment_management.sql
```

---

## 📚 Key Differences: Client-Side vs Server-Side

| Aspect | Client-Side | Server-Side |
|--------|------------|-------------|
| **Called by** | Frontend JS | Edge Functions (Deno) |
| **Auth** | `auth.uid()` from JWT | Explicit `p_user_id` param |
| **Permissions** | Public/authenticated | `GRANT TO service_role` |
| **Security** | RLS policies | `SECURITY DEFINER` + validation |
| **Examples** | `get_card_translation_status` | `store_card_translations` |

### Client-Side Example
```sql
CREATE OR REPLACE FUNCTION get_card_translation_status(p_card_id UUID)
RETURNS JSONB SECURITY DEFINER AS $$
DECLARE
  v_user_id UUID := auth.uid(); -- From JWT token
BEGIN
  -- RLS policies handle authorization
END;
$$ LANGUAGE plpgsql;
```

### Server-Side Example
```sql
CREATE OR REPLACE FUNCTION store_card_translations(
  p_user_id UUID,  -- ← Explicit parameter
  p_card_id UUID,
  ...
) RETURNS JSONB SECURITY DEFINER AS $$
BEGIN
  -- Manual authorization check
  SELECT user_id INTO v_owner FROM cards WHERE id = p_card_id;
  IF v_owner != p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  ...
END;
$$ LANGUAGE plpgsql;

-- ← Permission grant required
GRANT EXECUTE ON FUNCTION store_card_translations(...) TO service_role;
```

---

## 🔍 Troubleshooting

### If translation still fails:

1. **Check Edge Function logs**:
   ```bash
   npx supabase functions logs translate-card-content
   ```

2. **Verify function exists**:
   ```sql
   SELECT routine_name, routine_type 
   FROM information_schema.routines 
   WHERE routine_name = 'store_card_translations';
   ```

3. **Check permissions**:
   ```sql
   SELECT grantee, privilege_type 
   FROM information_schema.routine_privileges 
   WHERE routine_name = 'store_card_translations';
   ```

4. **Test manually**:
   ```sql
   SELECT store_card_translations(
     'your-user-id'::UUID,
     'your-card-id'::UUID,
     ARRAY['zh-Hans'],
     '{}'::JSONB,
     '{}'::JSONB,
     1.00
   );
   ```

---

## 📝 Files Modified

### Database
- ✅ `sql/storeproc/client-side/credit_management.sql`
- ✅ `sql/storeproc/server-side/translation_management.sql` (NEW)
- ✅ `sql/storeproc/client-side/12_translation_management.sql`
- ✅ `sql/all_stored_procedures.sql` (regenerated)

### Documentation
- ✅ `CLAUDE.md` (added client/server-side guidance)
- ✅ `DEPLOY_TRANSLATION_FIX.sql` (deployment script)
- ✅ `TRANSLATION_SERVER_SIDE_FIX.md` (detailed explanation)
- ✅ `DEPLOY_INSTRUCTIONS.md` (this file)

### Edge Function
- ✅ `supabase/functions/translate-card-content/index.ts` (already correct)

---

## ✅ Checklist

- [x] Fixed `consume_credits()` function
- [x] Created server-side `store_card_translations()`
- [x] Regenerated `all_stored_procedures.sql`
- [x] Updated documentation
- [x] Created deployment scripts
- [ ] **Deploy `DEPLOY_TRANSLATION_FIX.sql`** ← **YOU ARE HERE**
- [ ] Test translation feature
- [ ] Verify credits are consumed correctly

---

## 🎯 Success Criteria

After deployment, you should be able to:
1. ✅ Open card General tab
2. ✅ See Multi-Language Support section
3. ✅ Click "Manage Translations"
4. ✅ Select languages
5. ✅ See correct credit calculation
6. ✅ Click "Start Translation"
7. ✅ See progress bar
8. ✅ Translation completes successfully
9. ✅ Credits are consumed
10. ✅ Translations appear in language selector

---

## 🆘 Need Help?

Check these files for details:
- **`DEPLOY_TRANSLATION_FIX.sql`** - SQL to run
- **`TRANSLATION_SERVER_SIDE_FIX.md`** - Technical details
- **`CLAUDE.md`** - Architecture overview
- **Edge Function logs** - `npx supabase functions logs translate-card-content`

**Common Issues**:
- If "function does not exist" → Redeploy SQL
- If "insufficient credits" → Check user_credits table
- If "unauthorized" → Check card ownership
- If timeout → Check OpenAI API key

