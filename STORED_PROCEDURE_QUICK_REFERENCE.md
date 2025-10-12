# 📋 Stored Procedure Quick Reference Card

**Print or bookmark this for quick reference when writing stored procedures!**

---

## 🔵 CLIENT-SIDE or 🔴 SERVER-SIDE?

### Decision Tree

```
WHO calls this function?
├─ Frontend JavaScript ────────────────► 🔵 CLIENT-SIDE
├─ Edge Function with user JWT ────────► 🔵 CLIENT-SIDE  
└─ Edge Function with SERVICE_ROLE_KEY ► 🔴 SERVER-SIDE
    └─ Webhook (no user JWT) ──────────► 🔴 SERVER-SIDE
```

---

## 🔵 CLIENT-SIDE Pattern

### Quick Facts
- 📁 **Folder**: `sql/storeproc/client-side/`
- 🔑 **Auth**: `auth.uid()` from JWT
- 👤 **Role**: `authenticated`
- ✅ **GRANT**: `TO authenticated`

### Template
```sql
CREATE OR REPLACE FUNCTION my_function(p_param UUID)
RETURNS JSONB SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();  -- ✅ From JWT
BEGIN
    -- 1. Check auth
    IF v_user_id IS NULL THEN 
        RAISE EXCEPTION 'Not authenticated'; 
    END IF;
    
    -- 2. Verify ownership
    IF NOT EXISTS (
        SELECT 1 FROM table 
        WHERE id = p_param AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;
    
    -- 3. Your logic...
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION my_function(UUID) TO authenticated;
```

### ✅ DO
- ✅ Use `auth.uid()`
- ✅ GRANT TO authenticated
- ✅ Verify ownership
- ✅ Check user is not NULL

### ❌ DON'T
- ❌ Accept `p_user_id` parameter
- ❌ GRANT TO service_role
- ❌ Skip ownership checks
- ❌ Trust any input

---

## 🔴 SERVER-SIDE Pattern

### Quick Facts
- 📁 **Folder**: `sql/storeproc/server-side/`
- 🔑 **Auth**: `p_user_id UUID` parameter
- 👤 **Role**: `service_role`
- ✅ **GRANT**: `TO service_role` ONLY

### Template
```sql
CREATE OR REPLACE FUNCTION my_function(
    p_user_id UUID,  -- ✅ REQUIRED first param
    p_param UUID
)
RETURNS JSONB SECURITY DEFINER AS $$
DECLARE
    v_owner UUID;
BEGIN
    -- 1. Validate user ID
    IF p_user_id IS NULL THEN 
        RAISE EXCEPTION 'User ID required'; 
    END IF;
    
    -- 2. Verify user exists
    IF NOT EXISTS (
        SELECT 1 FROM auth.users WHERE id = p_user_id
    ) THEN
        RAISE EXCEPTION 'Invalid user ID';
    END IF;
    
    -- 3. Verify ownership
    SELECT user_id INTO v_owner 
    FROM table WHERE id = p_param
    FOR UPDATE;  -- Lock if needed
    
    IF v_owner != p_user_id THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;
    
    -- 4. Your privileged logic...
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION my_function(UUID, UUID) TO service_role;
REVOKE ALL ON FUNCTION my_function(UUID, UUID) FROM PUBLIC, authenticated;
```

### ✅ DO
- ✅ Accept `p_user_id` first
- ✅ Validate user exists
- ✅ GRANT TO service_role
- ✅ Use FOR UPDATE for locks
- ✅ Verify against p_user_id

### ❌ DON'T
- ❌ Use `auth.uid()` (returns NULL)
- ❌ GRANT TO authenticated
- ❌ Skip user validation
- ❌ Trust p_user_id without checks

---

## 🔧 Edge Function Patterns

### 🔵 Client-Side Edge Function
```typescript
// Uses ANON_KEY + User JWT
const supabaseClient = createClient(
  SUPABASE_URL,
  SUPABASE_ANON_KEY,
  {
    global: {
      headers: { 
        Authorization: req.headers.get('Authorization')! 
      }
    }
  }
);

// auth.uid() available in stored procedure
await supabaseClient.rpc('my_function', {
  p_param: value
});
```

### 🔴 Server-Side Edge Function
```typescript
// Uses SERVICE_ROLE_KEY
const supabaseAdmin = createClient(
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY
);

// Validate JWT manually
const token = req.headers.get('Authorization')
  ?.replace('Bearer ', '');
const { data: { user } } = await supabaseAdmin.auth.getUser(token);

// Pass explicit user ID
await supabaseAdmin.rpc('my_function', {
  p_user_id: user.id,  // ← Explicit
  p_param: value
});
```

---

## 🔒 Security Checklist

### Client-Side ✅
- [ ] Uses `auth.uid()`
- [ ] Checks user is not NULL
- [ ] Verifies ownership
- [ ] GRANT TO authenticated
- [ ] Uses SECURITY DEFINER
- [ ] NO p_user_id parameter

### Server-Side ✅
- [ ] Accepts `p_user_id` parameter
- [ ] Validates user exists
- [ ] Verifies ownership vs p_user_id
- [ ] GRANT TO service_role ONLY
- [ ] Uses SECURITY DEFINER
- [ ] Uses FOR UPDATE for locks
- [ ] Validates amounts (payments)
- [ ] Checks status (prevent duplicates)

---

## 🚨 Common Mistakes

| ❌ Wrong | ✅ Right | Pattern |
|---------|---------|---------|
| `p_user_id UUID` | `auth.uid()` | 🔵 Client |
| `auth.uid()` | `p_user_id UUID` | 🔴 Server |
| `GRANT TO service_role` | `GRANT TO authenticated` | 🔵 Client |
| `GRANT TO authenticated` | `GRANT TO service_role` | 🔴 Server |
| No ownership check | Verify ownership | Both |
| Trust input | Validate all inputs | Both |

---

## 📊 Quick Comparison

| Aspect | 🔵 Client-Side | 🔴 Server-Side |
|--------|---------------|----------------|
| **Folder** | `client-side/` | `server-side/` |
| **Called By** | Frontend / Edge with JWT | Edge with SERVICE_ROLE |
| **User Auth** | `auth.uid()` | `p_user_id UUID` |
| **PG Role** | `authenticated` | `service_role` |
| **GRANT** | `TO authenticated` | `TO service_role` |
| **RLS** | Applies | Can bypass |
| **Use Case** | CRUD, user ops | Credits, payments, webhooks |

---

## 🎯 When to Use Which?

### Use 🔵 CLIENT-SIDE for:
- ✅ Card CRUD operations
- ✅ Content management
- ✅ User profile updates
- ✅ Batch issuance (credit-based)
- ✅ Standard user operations
- ✅ Translation status queries

### Use 🔴 SERVER-SIDE for:
- ✅ Credit completion (webhooks)
- ✅ Translation storage (AI)
- ✅ Payment processing
- ✅ Refund handling
- ✅ Privileged admin ops
- ✅ Cross-user operations

---

## 📚 Full Documentation

- `sql/storeproc/client-side/README.md` - Complete client-side guide
- `sql/storeproc/server-side/README.md` - Complete server-side guide
- `CLIENT_VS_SERVER_SIDE_EXPLAINED.md` - Detailed comparison
- `SERVER_SIDE_SECURITY_GUIDE.md` - Security deep dive
- `CLAUDE.md` - Project documentation

---

## 💡 Remember

1. **Folder location = Security pattern**
2. **Client uses auth.uid(), Server uses p_user_id**
3. **Always validate, always verify**
4. **When in doubt, check the README**

---

*Keep this handy when writing stored procedures!* 📌

