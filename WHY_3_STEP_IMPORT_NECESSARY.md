# ❓ Why Can't We Just Pass Translations to create_card()?

## 🤔 Your Question

> Why not make `translations` nullable in `create_card()`, pass translations from Excel directly, and do it all in one step?

**Great question!** It seems like this should work, but there's a **critical database trigger timing issue**.

---

## 🔍 The Database Trigger

Here's the actual trigger from `sql/triggers.sql`:

```sql
CREATE OR REPLACE FUNCTION update_card_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  -- On INSERT: Always calculate hash
  IF TG_OP = 'INSERT' THEN
    NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
    NEW.last_content_update := NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_card_content_hash
  BEFORE INSERT OR UPDATE ON cards  -- ← BEFORE trigger!
  FOR EACH ROW
  EXECUTE FUNCTION update_card_content_hash();
```

**Key point**: This is a **BEFORE INSERT** trigger that **modifies the NEW row**.

---

## ❌ What Would Happen with One-Step Approach

Let's trace through what happens if we pass translations directly:

### Approach A: Pass Translations to create_card()

```sql
CREATE OR REPLACE FUNCTION create_card(
    p_name TEXT,
    p_description TEXT,
    p_translations JSONB DEFAULT NULL,  -- ← NEW: Accept translations
    ...
) RETURNS UUID AS $$
BEGIN
    INSERT INTO cards (
        user_id,
        name,
        description,
        translations,  -- ← Pass translations from Excel
        ...
    ) VALUES (
        auth.uid(),
        p_name,
        p_description,
        p_translations,  -- ← Contains OLD hashes from export
        ...
    )
    RETURNING id INTO v_card_id;
    
    RETURN v_card_id;
END;
$$;
```

### What Happens in Database (Step by Step):

```
┌──────────────────────────────────────────────────────────────┐
│ Step 1: INSERT Statement Starts                              │
├──────────────────────────────────────────────────────────────┤
│ INSERT INTO cards (name, description, translations, ...)     │
│ VALUES (                                                     │
│   'Card Name',                                               │
│   'Description',                                             │
│   '{"zh-Hant": {"content_hash": "OLD_HASH_789"}}', ← FROM EXCEL│
│   ...                                                        │
│ )                                                            │
│                                                              │
│ PostgreSQL prepares NEW row:                                 │
│   NEW.name = 'Card Name'                                     │
│   NEW.description = 'Description'                            │
│   NEW.translations = '{"zh-Hant": {"content_hash": "OLD_HASH_789"}}'│
│   NEW.content_hash = NULL (not set yet)                      │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│ Step 2: BEFORE INSERT Trigger Fires                          │
├──────────────────────────────────────────────────────────────┤
│ update_card_content_hash() function runs:                    │
│                                                              │
│ NEW.content_hash := md5(NEW.name || NEW.description);       │
│                                                              │
│ Calculates: md5('Card Name|Description')                     │
│           = "NEW_HASH_123" ← DIFFERENT from OLD_HASH_789!    │
│                                                              │
│ NEW.last_content_update := NOW();                            │
│                                                              │
│ Modified NEW row:                                            │
│   NEW.name = 'Card Name'                                     │
│   NEW.description = 'Description'                            │
│   NEW.translations = '{"zh-Hant": {"content_hash": "OLD_HASH_789"}}'│
│   NEW.content_hash = "NEW_HASH_123" ← TRIGGER SET THIS       │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│ Step 3: Row Inserted Into Database                           │
├──────────────────────────────────────────────────────────────┤
│ Final row in cards table:                                    │
│                                                              │
│ {                                                            │
│   name: 'Card Name',                                         │
│   description: 'Description',                                │
│   content_hash: 'NEW_HASH_123',  ← From trigger              │
│   translations: {                                            │
│     'zh-Hant': {                                             │
│       'name': '翻譯名稱',                                    │
│       'description': '翻譯描述',                             │
│       'content_hash': 'OLD_HASH_789'  ← From Excel! ❌       │
│     }                                                        │
│   }                                                          │
│ }                                                            │
│                                                              │
│ ⚠️  HASH MISMATCH:                                           │
│ card.content_hash = 'NEW_HASH_123'                           │
│ translation.content_hash = 'OLD_HASH_789'                    │
│                                                              │
│ NEW_HASH_123 ≠ OLD_HASH_789 → Translation shows "Outdated"!  │
└──────────────────────────────────────────────────────────────┘
```

**Result**: ❌ Same problem! The trigger **always** calculates a new hash, but the translations JSONB still contains the old hash from the export.

---

## 🤷 Why Can't We Modify the Trigger?

### Option 1: Make Trigger Update Translation Hashes

```sql
CREATE OR REPLACE FUNCTION update_card_content_hash()
RETURNS TRIGGER AS $$
DECLARE
    v_new_hash TEXT;
    v_lang_code TEXT;
    v_updated_translations JSONB := '{}'::JSONB;
BEGIN
    -- Calculate new hash
    v_new_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
    NEW.content_hash := v_new_hash;
    
    -- Update all translation hashes?
    IF NEW.translations IS NOT NULL THEN
        FOR v_lang_code IN SELECT jsonb_object_keys(NEW.translations)
        LOOP
            v_updated_translations := v_updated_translations || 
                jsonb_build_object(
                    v_lang_code,
                    (NEW.translations->v_lang_code) || 
                    jsonb_build_object('content_hash', v_new_hash)
                );
        END LOOP;
        NEW.translations := v_updated_translations;
    END IF;
    
    RETURN NEW;
END;
$$;
```

**Problems with this approach**:

❌ **Performance**: Trigger runs on EVERY INSERT/UPDATE, even when no translations exist  
❌ **Complexity**: Trigger becomes very complex and harder to debug  
❌ **Overhead**: JSONB manipulation in triggers is expensive  
❌ **Maintenance**: Mixing hash calculation with translation management  
❌ **Special Cases**: What if user manually edits translations? Trigger would overwrite  
❌ **Testing**: Harder to test trigger behavior  

### Option 2: Use AFTER Trigger

```sql
CREATE TRIGGER trigger_update_card_content_hash
  AFTER INSERT OR UPDATE ON cards  -- ← AFTER instead of BEFORE
  ...
```

**Problem**: AFTER triggers **cannot modify the row** that was just inserted. They can only perform side effects (like inserting into other tables). The row is already committed.

---

## ✅ Why 3-Step Approach is Better

### Current Design:

```javascript
// Step 1: Create card WITHOUT translations
const cardId = await supabase.rpc('create_card', {
  p_name, p_description, ...
  // No translations parameter
})
// Trigger calculates NEW hash

// Step 2: Restore translations (contains OLD hashes)
await supabase.rpc('update_card_translations_bulk', {
  p_card_id: cardId,
  p_translations: translationsFromExcel
})

// Step 3: Fix the hash mismatch
await supabase.rpc('recalculate_card_translation_hashes', {
  p_card_id: cardId
})
```

### Advantages:

✅ **Separation of Concerns**:
   - Trigger: Calculate hash (simple, focused)
   - Bulk update: Restore data (import-specific)
   - Recalculate: Fix hashes (import-specific)

✅ **Performance**:
   - Trigger stays lightweight (runs on EVERY card operation)
   - Hash recalculation only runs when needed (import)

✅ **Maintainability**:
   - Each function has single responsibility
   - Easy to debug and test separately
   - Clear code flow

✅ **Flexibility**:
   - Normal card creation: No overhead, trigger just calculates hash
   - Import: Explicit steps, clear what's happening
   - Future changes: Easy to modify without affecting triggers

✅ **Error Handling**:
   - Can handle errors at each step
   - Partial success possible (e.g., card created but translation restore fails)
   - Better logging and debugging

✅ **Explicit Intent**:
   - Code clearly shows: "This is an import, we need special handling"
   - Not hidden in trigger logic

---

## 🎯 Could We Do 2 Steps Instead of 3?

### Attempt: Combine Steps 2 & 3

```sql
CREATE OR REPLACE FUNCTION restore_card_translations_with_hash_fix(
    p_card_id UUID,
    p_translations JSONB
) RETURNS VOID AS $$
DECLARE
    v_current_hash TEXT;
    v_updated_translations JSONB;
BEGIN
    -- Get current hash
    SELECT content_hash INTO v_current_hash FROM cards WHERE id = p_card_id;
    
    -- Update all translation hashes
    v_updated_translations := update_translation_hashes(p_translations, v_current_hash);
    
    -- Update card
    UPDATE cards 
    SET translations = v_updated_translations
    WHERE id = p_card_id;
END;
$$;
```

**This would work!** But:

❌ Less modular (combining two different operations)  
❌ Harder to reuse (what if we want to recalculate hashes separately?)  
❌ Less clear intent  

The 3-step approach is more **UNIX philosophy**: Each function does one thing well.

---

## 📊 Normal Card Creation vs Import

### Normal Card Creation (UI):

```
User fills form
     ↓
create_card(name, description, ...) ← No translations
     ↓
Trigger calculates hash
     ↓
Card created ✅
content_hash: "ABC123"
translations: {} (empty)
```

**No issues!** Translations are added later via translation UI, and the translation Edge Function handles hash properly.

### Import Card (Excel):

```
User uploads Excel
     ↓
Parse data (includes translations with OLD hashes)
     ↓
create_card(name, description, ...) ← No translations yet
     ↓
Trigger calculates NEW hash
     ↓
update_card_translations_bulk(translations) ← Has OLD hashes
     ↓
⚠️  Hash mismatch!
     ↓
recalculate_card_translation_hashes() ← Fix!
     ↓
Card imported ✅
content_hash: "NEW_HASH"
translations: {"zh-Hant": {"content_hash": "NEW_HASH"}}
```

---

## 💡 Final Answer

**Q**: Why not pass translations directly to `create_card()`?

**A**: Because the **BEFORE INSERT trigger** calculates a new hash based on the new card's content, which will **always be different** from the hash stored in the exported translations. The trigger has no way to know:
- Whether this is a normal creation (no translations)
- Whether this is an import (translations need hash update)
- What the "correct" behavior should be for translations

The 3-step approach:
1. Keeps triggers simple and fast
2. Makes import logic explicit and clear
3. Allows better error handling
4. Follows separation of concerns
5. **Only adds overhead during import, not normal operations**

---

## 🎓 Database Design Principle

> **Triggers should be simple, fast, and predictable.**
> 
> Complex logic that only applies to specific scenarios (like import) should be in stored procedures, not triggers.

The 3-step approach follows this principle perfectly!

