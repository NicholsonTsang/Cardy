# 🎯 Hash Calculation: Trigger vs Stored Procedure

## The Question

> Why use a trigger for hash calculation? Why not just do it in the stored procedure?

**Great question!** This reveals an important design decision with trade-offs on both sides.

---

## 📊 Two Approaches

### Approach A: Trigger (Current Design)

```sql
-- Trigger automatically calculates hash
CREATE OR REPLACE FUNCTION update_card_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
    NEW.last_content_update := NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_card_content_hash
  BEFORE INSERT OR UPDATE ON cards
  FOR EACH ROW
  EXECUTE FUNCTION update_card_content_hash();

-- Stored procedure doesn't handle hash
CREATE OR REPLACE FUNCTION create_card(...)
RETURNS UUID AS $$
BEGIN
    INSERT INTO cards (name, description, ...)
    VALUES (p_name, p_description, ...)
    -- Trigger automatically sets content_hash
    RETURNING id INTO v_card_id;
    
    RETURN v_card_id;
END;
$$;
```

### Approach B: Stored Procedure (Alternative)

```sql
-- No trigger needed for hash calculation

-- Stored procedure calculates hash explicitly
CREATE OR REPLACE FUNCTION create_card(
    p_name TEXT,
    p_description TEXT,
    p_content_hash TEXT DEFAULT NULL,  -- ← Optional: for import
    ...
)
RETURNS UUID AS $$
DECLARE
    v_card_id UUID;
    v_hash TEXT;
BEGIN
    -- Calculate hash if not provided
    IF p_content_hash IS NULL THEN
        v_hash := md5(COALESCE(p_name, '') || '|' || COALESCE(p_description, ''));
    ELSE
        v_hash := p_content_hash;  -- ← Use provided hash (for import)
    END IF;
    
    INSERT INTO cards (
        name,
        description,
        content_hash,
        last_content_update,
        ...
    ) VALUES (
        p_name,
        p_description,
        v_hash,
        NOW(),
        ...
    )
    RETURNING id INTO v_card_id;
    
    RETURN v_card_id;
END;
$$ LANGUAGE plpgsql;
```

---

## ⚖️ Trade-Off Analysis

### ✅ Advantages of Trigger Approach (Current)

#### 1. **Guaranteed Consistency**
```sql
-- Hash is ALWAYS calculated, no matter how data is inserted
INSERT INTO cards (name, description, ...) VALUES (...);  -- ← Trigger runs
-- vs stored procedure
UPDATE cards SET name = 'New Name' WHERE id = ...;  -- ← Trigger runs
-- vs admin direct access
DELETE FROM cards WHERE ...;  -- ← Triggers work for all operations
```

**Benefit**: No way to forget or bypass hash calculation.

#### 2. **Centralized Logic**
```
One place to maintain hash algorithm:
  sql/triggers.sql → update_card_content_hash()

If we change hash algorithm (e.g., SHA256 instead of MD5):
  ✅ Trigger: Change one function
  ❌ Stored Proc: Update every function that creates/updates cards
```

#### 3. **Future-Proof**
```sql
-- If we add new stored procedures later...
CREATE OR REPLACE FUNCTION clone_card(...) RETURNS UUID AS $$
BEGIN
    INSERT INTO cards (name, description, ...)
    SELECT name, description, ... FROM cards WHERE id = p_source_id;
    -- ✅ Trigger automatically calculates hash
    -- ❌ Stored proc approach: Must remember to calculate hash!
END;
$$;
```

#### 4. **Direct SQL Access Protection**
```sql
-- Admin runs direct SQL
INSERT INTO cards (user_id, name, description) 
VALUES ('abc-123', 'Test Card', 'Test');

-- ✅ Trigger: Hash calculated automatically
-- ❌ Stored Proc: Hash would be NULL! 💥
```

#### 5. **UPDATE Operations**
```sql
-- User edits card name in UI
UPDATE cards 
SET name = 'Updated Name'
WHERE id = 'card-id';

-- ✅ Trigger: Detects change, recalculates hash automatically
-- ❌ Stored Proc: Need separate update_card_hash() function, must call it
```

---

### ✅ Advantages of Stored Procedure Approach (Your Suggestion)

#### 1. **Solves Import Problem Elegantly!** ⭐
```javascript
// Normal creation - calculate new hash
await supabase.rpc('create_card', {
  p_name: 'Card Name',
  p_description: 'Description',
  // p_content_hash not provided → Calculates new hash
})

// Import - preserve old hash
await supabase.rpc('create_card', {
  p_name: 'Card Name',
  p_description: 'Description',
  p_content_hash: 'OLD_HASH_789',  // ← From Excel, preserved!
  p_translations: translationsFromExcel  // ← Matches OLD_HASH_789
})
```

**No need for hash recalculation!** Import becomes 2 steps instead of 3! 🎉

#### 2. **Explicit and Predictable**
```javascript
// Developer knows exactly when hash is calculated
const hash = md5(name + description);  // ← Visible in code
await createCard({ name, description, hash });

// vs Trigger (magic!)
await createCard({ name, description });  // ← Where does hash come from? 🤷
```

#### 3. **Better for Testing**
```sql
-- Test with specific hash
SELECT create_card('Test', 'Desc', 'test-hash-123');

-- ✅ Stored Proc: Can control hash for deterministic tests
-- ❌ Trigger: Hash always calculated, harder to test
```

#### 4. **Performance Control**
```sql
-- Bulk import: Calculate hash once outside loop
v_hash := md5(p_name || p_description);

FOR i IN 1..1000 LOOP
    INSERT INTO cards (..., content_hash) VALUES (..., v_hash);
    -- ✅ Stored Proc: Hash calculated once
    -- ❌ Trigger: Hash calculated 1000 times
END LOOP;
```

#### 5. **Conditional Hash Logic**
```sql
-- Different hash algorithms based on context
IF p_secure_mode THEN
    v_hash := sha256(p_name || p_description || p_salt);
ELSE
    v_hash := md5(p_name || p_description);
END IF;

-- ✅ Stored Proc: Easy to add conditional logic
-- ❌ Trigger: Complex logic in trigger is bad practice
```

---

## 🎯 Why Current Design Uses Triggers

### Historical Context

The translation system was **added later** to an existing codebase. At that time:

1. **Multiple entry points** existed:
   - `create_card()` stored procedure
   - Admin SQL console access
   - Future features (clone, duplicate, etc.)

2. **Safety first**: Ensuring hash is ALWAYS calculated was critical

3. **Standard pattern**: Using triggers for auto-calculated fields is a common database pattern
   - `updated_at` timestamps → trigger
   - `created_at` timestamps → default
   - `content_hash` → trigger (similar to timestamp)

### Why It Persists

```sql
-- Cards table
CREATE TRIGGER trigger_update_card_content_hash ...

-- Content Items table  
CREATE TRIGGER trigger_update_content_item_content_hash ...

-- Issued Cards table
CREATE TRIGGER update_issue_cards_updated_at ...

-- Print Requests table
CREATE TRIGGER update_print_requests_updated_at ...
```

**Pattern**: The codebase uses triggers for **automatic field maintenance** consistently.

---

## 🤔 Should We Switch to Stored Procedure Approach?

### If Starting Fresh Today

**I would probably use the stored procedure approach** for hash calculation because:

1. ✅ Solves import problem elegantly (no recalculation needed)
2. ✅ More explicit and easier to understand
3. ✅ Better control for special cases
4. ✅ Easier debugging

### Why Not to Switch Now

1. **Breaking Change**:
   ```sql
   -- Would need to update:
   - create_card()
   - update_card()
   - create_content_item()
   - update_content_item()
   - All import/export logic
   - All admin functions
   ```

2. **Works Well Enough**:
   - Import recalculation is fast (~1ms per item)
   - Only happens during import (rare operation)
   - No performance impact on normal usage

3. **Risk vs Reward**:
   - Risk: Breaking existing functionality
   - Reward: Slightly cleaner import code
   - **Not worth it for production system**

---

## 💡 The Best of Both Worlds?

### Hybrid Approach (If We Were to Refactor)

```sql
-- Keep trigger for safety, but allow override
CREATE OR REPLACE FUNCTION update_card_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Only calculate if not already set
    IF NEW.content_hash IS NULL THEN
      NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
      NEW.last_content_update := NOW();
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Only recalculate if content changed AND hash not manually set
    IF (NEW.name IS DISTINCT FROM OLD.name OR NEW.description IS DISTINCT FROM OLD.description)
       AND NEW.content_hash = OLD.content_hash THEN
      NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
      NEW.last_content_update := NOW();
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Stored procedure can now provide hash
CREATE OR REPLACE FUNCTION create_card(
    ...,
    p_content_hash TEXT DEFAULT NULL,  -- ← Optional
    p_translations JSONB DEFAULT NULL   -- ← Optional
)
RETURNS UUID AS $$
BEGIN
    INSERT INTO cards (..., content_hash, translations)
    VALUES (..., p_content_hash, p_translations);
    -- If p_content_hash is NULL, trigger calculates it
    -- If provided, trigger keeps it!
END;
$$;
```

**Benefits**:
- ✅ Normal creation: Trigger calculates (safety net)
- ✅ Import: Provide hash explicitly (no recalculation)
- ✅ Direct SQL: Trigger calculates (protection)
- ✅ Backward compatible

**Import becomes 1 step**:
```javascript
await supabase.rpc('create_card', {
  p_name: 'Card Name',
  p_description: 'Description',
  p_content_hash: exportedCard.content_hash,  // ← Preserve original
  p_translations: exportedCard.translations   // ← Matches hash!
})
// Done! No recalculation needed!
```

---

## 📋 Conclusion

### Your Question is Valid!

**Yes, hash calculation COULD be done in stored procedures instead of triggers.**

### Current Design (Trigger):
- ✅ Guaranteed consistency
- ✅ Centralized logic
- ✅ Standard pattern
- ❌ Less flexible
- ❌ Requires import recalculation

### Alternative (Stored Procedure):
- ✅ More flexible
- ✅ Explicit control
- ✅ Easier import
- ❌ Risk of forgetting
- ❌ Multiple places to maintain

### Best Answer:

**For a NEW project**: Use stored procedure approach with optional hash parameter

**For THIS project**: Keep triggers (they work, widely used pattern, not worth refactoring risk)

**If we refactor later**: Use hybrid approach (trigger as safety net, allow override)

---

## 🎓 Database Design Lesson

> There are often **multiple valid approaches** to solving the same problem.
> 
> The "best" approach depends on:
> - Project maturity (new vs established)
> - Team preferences (explicit vs automatic)
> - Risk tolerance (safety vs flexibility)
> - Performance requirements
> 
> **Both approaches are defensible!**

The trigger approach prioritizes **safety and consistency**.  
The stored procedure approach prioritizes **flexibility and explicitness**.

In this case, we have triggers because it was a safe default choice when the system was built. Your suggestion is equally valid and would work well if implemented from the start! 👍

