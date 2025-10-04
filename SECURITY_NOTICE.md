# 🔒 Security Notice - API Keys in config.toml

## ⚠️ **CRITICAL SECURITY ISSUE DETECTED**

Your `supabase/config.toml` file currently contains a **real OpenAI API key** and is **tracked by Git**. This is a security risk!

---

## 🚨 **Immediate Actions Required**

### **Step 1: Remove config.toml from Git Tracking**

The file has been added to `.gitignore`, but it's already tracked by Git. You need to remove it:

```bash
# Remove from Git tracking but keep the local file
git rm --cached supabase/config.toml

# Verify it's removed from staging
git status

# Commit the removal
git commit -m "chore: Remove config.toml from version control for security"
```

### **Step 2: Use the Template Instead**

A new **`supabase/config.toml.example`** file has been created:
- ✅ Contains placeholder values (`sk_test_YOUR_KEY_HERE`)
- ✅ Safe to commit to Git
- ✅ Includes documentation

**For team members:**
```bash
# Copy the example and add your own keys
cp supabase/config.toml.example supabase/config.toml

# Edit with your actual keys
# This file is now gitignored and won't be committed
```

### **Step 3: Check Git History**

If you've already pushed commits with your API key, you need to:

```bash
# Check if config.toml with secrets was pushed
git log --all --full-history -- supabase/config.toml

# If you find commits with secrets, you MUST:
# 1. Rotate your OpenAI API key immediately
# 2. Consider using git-filter-repo to remove sensitive data
# 3. Force push the cleaned history (if you're the only developer)
```

### **Step 4: Rotate Your API Key** (If Already Pushed)

If your OpenAI API key was already committed and pushed:

1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. **Revoke** the exposed key: `sk-d6xbooVgVWS0uIv3Cf6090465bE24c979bF5Dd596f7c7a04`
3. Generate a new API key
4. Update it in:
   - Your local `config.toml` (for local dev)
   - Supabase Cloud secrets (for production)

```bash
# Update Supabase Cloud secret
supabase secrets set OPENAI_API_KEY=sk-NEW_KEY_HERE
```

---

## 📋 **What Changed**

### **1. `.gitignore` Updated**

Added:
```gitignore
# Supabase local configuration (contains secrets)
supabase/config.toml
supabase/.branches/
supabase/.temp/
```

### **2. New Template File Created**

`supabase/config.toml.example` - Safe template with placeholders

### **3. Current config.toml Status**

- ❌ Currently tracked by Git
- ❌ Contains real API key
- ✅ Will be ignored after `git rm --cached`

---

## 🔐 **Best Practices Going Forward**

### **1. Never Commit Secrets**

❌ **BAD:**
```toml
OPENAI_API_KEY = "sk-d6xbooVgVWS0uIv3Cf6090465bE24c979bF5Dd596f7c7a04"
```

✅ **GOOD:**
```toml
OPENAI_API_KEY = "sk-proj-YOUR_KEY_HERE"  # Placeholder
# Or use environment variables:
OPENAI_API_KEY = "env(OPENAI_API_KEY)"
```

### **2. Use Environment Variables**

Instead of hardcoding in `config.toml`:
```bash
# In your shell profile (.bashrc, .zshrc, etc.)
export OPENAI_API_KEY="sk-..."
export STRIPE_SECRET_KEY="sk_test_..."
```

Then in `config.toml`:
```toml
OPENAI_API_KEY = "env(OPENAI_API_KEY)"
STRIPE_SECRET_KEY = "env(STRIPE_SECRET_KEY)"
```

### **3. Separate Dev and Prod Keys**

- **Development:** Use test keys (sk_test_...)
- **Production:** Use live keys (sk_live_...) stored in Supabase Dashboard

### **4. Regular Key Rotation**

Rotate API keys periodically:
- OpenAI: Every 3-6 months
- Stripe: As per security policy
- After any security incident

---

## 🎯 **For Supabase Cloud Users**

Since you're using Supabase Cloud, you **DON'T NEED** `config.toml` for production!

### **What You Should Use:**

**For Production (Supabase Cloud):**
```bash
# Configure secrets via CLI
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set STRIPE_SECRET_KEY=sk_live_...

# Or via Supabase Dashboard:
# Edge Functions → Secrets → Add Secret
```

**For Local Development (Optional):**
```toml
# config.toml (gitignored)
[edge_runtime.secrets]
OPENAI_API_KEY = "sk-..."  # Test key
STRIPE_SECRET_KEY = "sk_test_..."  # Test key
```

---

## 📊 **Verification Checklist**

After completing the steps above:

- [ ] Ran `git rm --cached supabase/config.toml`
- [ ] Committed the removal
- [ ] Verified `.gitignore` includes `supabase/config.toml`
- [ ] Created `config.toml` from `config.toml.example`
- [ ] Updated Supabase Cloud secrets via CLI/Dashboard
- [ ] (If pushed) Rotated OpenAI API key
- [ ] Verified `git status` doesn't show `config.toml`
- [ ] Tested Edge Functions still work

---

## 🔍 **How to Check If You're Safe**

### **Check if config.toml is still tracked:**
```bash
git ls-files supabase/config.toml
# If this returns nothing, you're safe!
# If it returns the file path, run: git rm --cached supabase/config.toml
```

### **Check if config.toml is gitignored:**
```bash
git check-ignore supabase/config.toml
# Should return: supabase/config.toml
# If not, add it to .gitignore
```

### **Check recent commits:**
```bash
git log --oneline -10 -- supabase/config.toml
# Review if any commits contain your actual API key
```

---

## 📚 **Related Documentation**

- `SUPABASE_CLOUD_VS_LOCAL_CONFIG.md` - Cloud vs local configuration
- `EDGE_FUNCTIONS_CONFIG.md` - Complete Edge Functions setup
- `CONFIGURATION_CENTRALIZATION.md` - Configuration overview

---

## 🆘 **Need Help?**

If you've already pushed secrets to Git:

1. **Rotate keys immediately** (OpenAI, Stripe)
2. **Use git-filter-repo** to remove sensitive history:
   ```bash
   pip install git-filter-repo
   git filter-repo --path supabase/config.toml --invert-paths
   git push --force --all
   ```
3. **Notify team members** to re-clone the repository

---

## ✅ **Summary**

**Current Situation:**
- ⚠️ `config.toml` contains real API key
- ⚠️ File is tracked by Git
- ✅ `.gitignore` has been updated
- ✅ Template file created

**What You Need to Do:**
1. Run `git rm --cached supabase/config.toml`
2. Commit the change
3. (If pushed) Rotate your OpenAI API key
4. Use Supabase Cloud secrets for production

**Going Forward:**
- ✅ Use `config.toml.example` as reference
- ✅ Keep actual `config.toml` gitignored
- ✅ Use Supabase Dashboard/CLI for production secrets
- ✅ Never commit real API keys

