# 📁 Stored Procedures Folder Structure Decision

## The Question

**Should client-side and server-side stored procedures be in:**
- **A) Separate folders** (`client-side/` and `server-side/`)
- **B) A single folder** with naming conventions

---

## ✅ Decision: Keep Separate Folders

**Recommendation**: **KEEP** the current separate folder structure.

---

## 🎯 Reasoning

### Arguments FOR Separate Folders ✅

1. **Immediate Visual Clarity**
   - File location instantly tells you the security model
   - No need to open files to understand authentication pattern
   - Easier code navigation

2. **Security Benefits**
   - Clear separation prevents accidental misuse
   - Harder to accidentally use wrong pattern
   - Easier security audits (can review entire folder)
   - GRANT statements clearly separated

3. **Code Review Efficiency**
   - Reviewers immediately know which pattern to expect
   - Server-side functions get extra scrutiny
   - Can focus security review on `server-side/` folder

4. **Different Requirements**
   - **Client-side**: Use `auth.uid()`, GRANT TO authenticated, called by frontend
   - **Server-side**: Accept `p_user_id`, GRANT TO service_role, called by Edge Functions
   - These are fundamentally different patterns

5. **Maintenance**
   - Clear ownership boundaries
   - Easy to identify which Edge Functions need which procedures
   - Deployment script already combines them

6. **Documentation**
   - Each folder can have its own README
   - Clear examples for each pattern
   - Reduces confusion for new developers

### Arguments AGAINST Separate Folders ❌

1. **Folder Complexity** - Minor, only 2 folders
2. **"All in One Place"** - Combine script handles this
3. **More Navigation** - IDE search works fine

---

## 📊 Comparison

| Aspect | Separate Folders | Single Folder |
|--------|-----------------|---------------|
| **Security Clarity** | ✅ Excellent | ⚠️ Requires naming conventions |
| **Code Review** | ✅ Easy | ⚠️ Need to check each file |
| **Pattern Enforcement** | ✅ Physical separation | ⚠️ Convention-based |
| **Navigation** | ✅ Clear categories | ⚠️ Need to scan file names |
| **Deployment** | ✅ Same (combine script) | ✅ Same |
| **Maintenance** | ✅ Clear boundaries | ⚠️ Mental overhead |

---

## 🏗️ Current Structure (Recommended)

```
sql/storeproc/
├── client-side/           # Called by frontend via supabase.rpc()
│   ├── README.md          # Client-side pattern guide
│   ├── 01_auth_functions.sql
│   ├── 02_card_management.sql
│   ├── 03_content_management.sql
│   ├── 04_batch_management.sql
│   ├── credit_management.sql
│   └── 12_translation_management.sql
│
└── server-side/           # Called by Edge Functions with service_role
    ├── README.md          # Server-side pattern guide
    ├── credit_purchase_completion.sql
    └── translation_management.sql
```

---

## 🔐 Security Pattern Enforcement

### Client-Side Pattern (`client-side/` folder)
```sql
CREATE OR REPLACE FUNCTION my_client_function(
    p_card_id UUID,
    ...
)
RETURNS JSONB
SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();  -- ✅ Uses auth.uid()
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Verify ownership
    IF NOT EXISTS (
        SELECT 1 FROM cards 
        WHERE id = p_card_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;
    
    -- Business logic...
END;
$$ LANGUAGE plpgsql;

-- ✅ Grant to authenticated users
GRANT EXECUTE ON FUNCTION my_client_function(...) TO authenticated;
```

### Server-Side Pattern (`server-side/` folder)
```sql
CREATE OR REPLACE FUNCTION my_server_function(
    p_user_id UUID,  -- ✅ Explicit parameter
    p_card_id UUID,
    ...
)
RETURNS JSONB
SECURITY DEFINER AS $$
DECLARE
    v_card_owner UUID;
BEGIN
    -- ✅ Validate user exists
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'Invalid user ID';
    END IF;
    
    -- ✅ Verify ownership against parameter
    SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
    IF v_card_owner != p_user_id THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;
    
    -- Business logic...
END;
$$ LANGUAGE plpgsql;

-- ✅ Grant ONLY to service_role
GRANT EXECUTE ON FUNCTION my_server_function(...) TO service_role;
```

---

## 📋 Folder Guidelines

### When to Put in `client-side/`

✅ **Use client-side when:**
- Called directly from Vue.js frontend
- Edge Function uses ANON_KEY + User JWT
- Function uses `auth.uid()` for user context
- Needs `GRANT TO authenticated`
- RLS policies apply

**Examples**: Card CRUD, Content management, User profiles

### When to Put in `server-side/`

✅ **Use server-side when:**
- Called from Edge Function with SERVICE_ROLE_KEY
- Webhook-triggered operations
- Privileged operations (credit consumption, payments)
- Function accepts `p_user_id` parameter
- Needs `GRANT TO service_role`
- Bypasses RLS

**Examples**: Credit completion, Translation storage, Payment webhooks

---

## 🔍 Quick Reference

### Is This Client-Side or Server-Side?

**Ask these questions:**

1. **Who calls it?**
   - Frontend with user JWT → Client-side
   - Edge Function with service_role → Server-side
   - Webhook → Server-side

2. **How is user identified?**
   - Uses `auth.uid()` → Client-side
   - Accepts `p_user_id` parameter → Server-side

3. **What API key?**
   - ANON_KEY → Client-side
   - SERVICE_ROLE_KEY → Server-side

4. **Grant to whom?**
   - `authenticated` → Client-side
   - `service_role` → Server-side

---

## ✅ Summary

**Decision**: **KEEP separate folders** (`client-side/` and `server-side/`)

**Benefits**:
- ✅ Immediate security clarity
- ✅ Enforces pattern separation
- ✅ Easier code reviews
- ✅ Better documentation
- ✅ Reduced confusion

**Implementation**:
- ✅ Update README files in each folder
- ✅ Add security notes to CLAUDE.md
- ✅ Create pattern templates
- ✅ Document decision

**Rationale**: The physical separation provides immediate visual feedback about security patterns and prevents accidental misuse. The minor navigation overhead is vastly outweighed by the security and clarity benefits.

---

**Approved**: ✅ Keep separate folder structure  
**Next Steps**: Update READMEs and CLAUDE.md with security notes

