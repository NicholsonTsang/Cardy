# 🔑 Client-Side vs Server-Side: The Key Difference Explained

## The Confusion

**Question**: "Payment functions are called by Edge Functions, so why are they client-side?"

**Answer**: It's not about WHERE they're called from, it's about **WHICH API KEY** the Edge Function uses!

---

## 🔍 The Key Difference

The distinction between client-side and server-side is determined by **which Supabase client the Edge Function creates**:

| Pattern | API Key Used | PostgreSQL Role | Can Use `auth.uid()`? |
|---------|-------------|-----------------|----------------------|
| **Client-Side** | `ANON_KEY` + User JWT | `authenticated` | ✅ Yes (returns user ID) |
| **Server-Side** | `SERVICE_ROLE_KEY` | `service_role` | ❌ No (returns NULL) |

---

## 📊 Visual Comparison

### Payment Functions (Client-Side Pattern)

**Edge Function: `create-checkout-session/index.ts`**

```typescript
// ⚠️ LOOK AT THIS LINE! Uses ANON_KEY, not SERVICE_ROLE_KEY!
const supabaseClient = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_ANON_KEY') ?? '',      // ← ANON KEY!
  {
    global: {
      headers: { Authorization: req.headers.get('Authorization')! },  // ← User JWT!
    },
  }
);

// This means:
// - Supabase client executes as 'authenticated' role
// - auth.uid() returns the user's ID (from JWT)
// - Functions need GRANT TO authenticated
```

**Stored Procedure: `create_batch_checkout_payment`**

```sql
CREATE OR REPLACE FUNCTION create_batch_checkout_payment(...)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- ✅ This works because Edge Function passes user JWT!
    IF v_batch_owner_id != auth.uid() THEN  -- auth.uid() returns user ID
        RAISE EXCEPTION 'Not authorized';
    END IF;
    -- ...
END;
$$;

-- ✅ Grant to authenticated (the role used by Edge Function)
GRANT EXECUTE ON FUNCTION create_batch_checkout_payment(...) TO authenticated;
```

**Why it's called "Client-Side"**:
- Even though called by Edge Function
- It uses **user credentials** (anon key + JWT)
- Executes as `authenticated` role
- `auth.uid()` works (returns user ID from JWT)
- Pattern is the same as if frontend called it directly

---

### Translation Function (Server-Side Pattern)

**Edge Function: `translate-card-content/index.ts`**

```typescript
// ⚠️ LOOK AT THIS LINE! Uses SERVICE_ROLE_KEY!
const supabaseAdmin = createClient(
  SUPABASE_URL, 
  SUPABASE_SERVICE_ROLE_KEY  // ← SERVICE ROLE KEY!
);

// Manually validate user from JWT
const token = req.headers.get('Authorization')?.replace('Bearer ', '');
const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);

// This means:
// - Supabase client executes as 'service_role'
// - auth.uid() returns NULL (no user context)
// - Must pass user.id explicitly to stored procedures
// - Functions need GRANT TO service_role
```

**Stored Procedure: `store_card_translations`**

```sql
CREATE OR REPLACE FUNCTION store_card_translations(
  p_user_id UUID,  -- ⚠️ Explicit parameter! Can't use auth.uid()
  p_card_id UUID,
  ...
)
RETURNS JSONB SECURITY DEFINER AS $$
BEGIN
  -- ✅ Validate against explicit parameter
  SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
  
  IF v_card_owner != p_user_id THEN  -- ⚠️ Use parameter, not auth.uid()!
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  -- ...
END;
$$;

-- ✅ Grant ONLY to service_role (Edge Function uses service_role)
GRANT EXECUTE ON FUNCTION store_card_translations(...) TO service_role;
```

**Why it's called "Server-Side"**:
- Called by Edge Function with **service role key**
- No user context in PostgreSQL (auth.uid() = NULL)
- Must pass user ID explicitly
- Only `service_role` can call it
- Frontend **cannot** call it directly

---

## 🎯 Side-by-Side Comparison

### Payment Functions (Client-Side)
```
┌─────────────┐      ANON_KEY + User JWT      ┌──────────────────┐
│   Frontend  │ ────────────────────────────> │  Edge Function   │
└─────────────┘                                │ (create-checkout)│
                                               └──────────────────┘
                                                        │
                                   Uses ANON_KEY + JWT  │
                                                        ▼
                                               ┌──────────────────┐
                                               │   Supabase DB    │
                                               │ (authenticated)  │
                                               └──────────────────┘
                                                        │
                         auth.uid() = user's ID ──────>│
                                                        ▼
                                          ┌──────────────────────────┐
                                          │ create_batch_checkout_   │
                                          │ payment() function       │
                                          │ GRANT TO authenticated   │
                                          └──────────────────────────┘
```

### Translation Functions (Server-Side)
```
┌─────────────┐         User JWT              ┌──────────────────┐
│   Frontend  │ ────────────────────────────> │  Edge Function   │
└─────────────┘                                │ (translate)      │
                                               └──────────────────┘
                                                        │
                              Uses SERVICE_ROLE_KEY    │
                              + validates JWT manually │
                                                        ▼
                                               ┌──────────────────┐
                                               │   Supabase DB    │
                                               │ (service_role)   │
                                               └──────────────────┘
                                                        │
                         auth.uid() = NULL ────────────│
                         Must pass user.id explicitly  │
                                                        ▼
                                          ┌──────────────────────────┐
                                          │ store_card_translations()│
                                          │ function                 │
                                          │ GRANT TO service_role    │
                                          └──────────────────────────┘
```

---

## 🤔 Why Does This Matter?

### Security Implications

**Client-Side Pattern**:
- ✅ Frontend **CAN** call functions directly
- ✅ `auth.uid()` works (user from JWT)
- ⚠️ Must validate ownership in function
- ⚠️ Can't bypass RLS without SECURITY DEFINER

**Server-Side Pattern**:
- ❌ Frontend **CANNOT** call functions directly
- ❌ `auth.uid()` returns NULL
- ✅ More secure isolation
- ✅ Can bypass RLS for privileged operations

---

## 📋 Decision Tree

```
Is your Edge Function using:

┌─ ANON_KEY + User JWT?
│  └─> YES ─> Functions are CLIENT-SIDE
│              - Keep in client-side/ folder
│              - Use auth.uid() in functions
│              - GRANT TO authenticated
│              - Frontend CAN call directly
│
└─ SERVICE_ROLE_KEY?
   └─> YES ─> Functions are SERVER-SIDE
               - Keep in server-side/ folder
               - Accept p_user_id parameter
               - DON'T use auth.uid()
               - GRANT TO service_role
               - Frontend CANNOT call directly
```

---

## 🔍 How to Check Your Code

### Step 1: Look at Edge Function

```typescript
// Find this line in your Edge Function:
const client = createClient(
  url,
  KEY_HERE,  // ← What key is used?
  ...
);
```

**If `KEY_HERE` is**:
- `SUPABASE_ANON_KEY` → Client-side pattern
- `SUPABASE_SERVICE_ROLE_KEY` → Server-side pattern

### Step 2: Look at Stored Procedure

```sql
-- Does function use auth.uid()?
IF v_something != auth.uid() THEN  -- ← Using auth.uid()?
```

**If uses `auth.uid()`**: Client-side pattern  
**If accepts `p_user_id` parameter**: Server-side pattern

---

## ✅ Your Specific Case: Payment Functions

### What You Have

**Edge Function (`create-checkout-session/index.ts`)**:
```typescript
const supabaseClient = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_ANON_KEY') ?? '',  // ← ANON KEY!
  { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
);
```

**Stored Procedure**:
```sql
IF v_batch_owner_id != auth.uid() THEN  -- ← Uses auth.uid()!
    RAISE EXCEPTION 'Not authorized';
END IF;
```

**Conclusion**: CLIENT-SIDE pattern!

### Why It Works

1. Edge Function uses **ANON_KEY + User JWT**
2. PostgreSQL sees this as `authenticated` role
3. `auth.uid()` extracts user ID from JWT → Returns user's actual ID
4. Function checks: "Does this batch belong to this user?"
5. Works perfectly! ✅

### Why We Moved It

**Before (Wrong)**:
- File location: `server-side/` folder
- But pattern: Client-side (uses auth.uid())
- Missing: GRANT statements
- Result: Confusing and insecure

**After (Correct)**:
- File location: `client-side/` folder
- Pattern matches: Uses auth.uid() + GRANT to authenticated
- Clear: Everyone understands it's client-side pattern
- Secure: Proper GRANT statements

---

## 💡 Key Takeaway

**"Client-Side" vs "Server-Side" is NOT about WHERE the function is called from.**

**It's about WHICH API KEY the caller uses:**

| If Using | Then It's | PostgreSQL Role | Use auth.uid()? | GRANT TO |
|----------|-----------|----------------|-----------------|----------|
| ANON_KEY + User JWT | **Client-Side** | `authenticated` | ✅ Yes | `authenticated` |
| SERVICE_ROLE_KEY | **Server-Side** | `service_role` | ❌ No | `service_role` |

---

## 🎓 Examples in Your Codebase

### Client-Side Functions
- ✅ Payment management (uses ANON_KEY)
- ✅ Card CRUD operations (uses auth.uid())
- ✅ Content management (uses auth.uid())
- ✅ Most authenticated user operations

### Server-Side Functions
- ✅ Translation storage (uses SERVICE_ROLE_KEY)
- ✅ Credit purchase completion (uses SERVICE_ROLE_KEY)
- ✅ Credit refunds (uses SERVICE_ROLE_KEY)
- ✅ Privileged operations called by webhooks

---

## 📚 Summary

**Payment functions are "client-side" because:**

1. ✅ Edge Function uses **ANON_KEY** (not SERVICE_ROLE_KEY)
2. ✅ Functions use **auth.uid()** (works with user JWT)
3. ✅ Execute as **authenticated** role (not service_role)
4. ✅ Pattern is same as frontend calling directly
5. ✅ Security maintained by ownership checks

**Even though they're called by Edge Functions**, they follow the **client-side authentication pattern**!

---

Does this make sense now? The folder name isn't about "who calls it", it's about "which authentication pattern it uses"! 🎯

