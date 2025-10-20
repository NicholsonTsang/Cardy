# Deployment Documentation Guide

## Which Document Should I Use?

This directory contains **4 deployment documents**. Here's when to use each one:

---

### 📋 [`DEPLOYMENT_CHECKLIST.md`](DEPLOYMENT_CHECKLIST.md)
**Use this for**: Quick reference during deployment

**Best for**:
- ✅ First-time deployment (print and check off items)
- ✅ Quick verification you haven't missed anything
- ✅ Handing off to someone else to deploy
- ✅ Monthly deployment review

**Features**:
- Compact checkbox format
- All critical steps in order
- No explanations (just actions)
- Can be printed on 8-10 pages
- Includes verification points

**Start here if**: You want a simple "do this, then this" list

---

### 📖 [`DEPLOYMENT_COMPLETE_GUIDE.md`](DEPLOYMENT_COMPLETE_GUIDE.md)
**Use this for**: Detailed step-by-step instructions

**Best for**:
- ✅ First deployment ever
- ✅ Learning how everything works
- ✅ When something goes wrong
- ✅ Reference documentation

**Features**:
- Complete explanations for each step
- Copy-paste commands
- Verification steps with SQL queries
- Troubleshooting section
- Time estimates
- Multiple options for each step

**Start here if**: You're deploying for the first time or need detailed help

---

### 🗺️ [`DEPLOYMENT_FLOW_DIAGRAM.md`](DEPLOYMENT_FLOW_DIAGRAM.md)
**Use this for**: Understanding the deployment process

**Best for**:
- ✅ Visual learners
- ✅ Understanding dependencies
- ✅ Planning deployment timeline
- ✅ Team training

**Features**:
- ASCII flowcharts
- Dependency diagrams
- Common pitfalls highlighted
- Time estimates
- Quick reference commands

**Start here if**: You want to understand the big picture before deploying

---

### 📝 [`DEPLOYMENT_GUIDE_SUMMARY.md`](DEPLOYMENT_GUIDE_SUMMARY.md)
**Use this for**: Overview of what's covered

**Best for**:
- ✅ Executives/stakeholders
- ✅ Quick overview
- ✅ Understanding what deployment involves

**Features**:
- High-level summary
- What's covered in each part
- Integration with existing docs
- Benefits explanation

**Start here if**: You just want to know what's involved without details

---

## Recommended Workflow

### For First-Time Deployment:

```
Step 1: Read DEPLOYMENT_GUIDE_SUMMARY.md
        ↓ (understand what's involved)
        
Step 2: Review DEPLOYMENT_FLOW_DIAGRAM.md
        ↓ (understand the process)
        
Step 3: Print DEPLOYMENT_CHECKLIST.md
        ↓ (your working checklist)
        
Step 4: Follow DEPLOYMENT_COMPLETE_GUIDE.md
        ↓ (detailed instructions)
        
Step 5: Check off DEPLOYMENT_CHECKLIST.md
        ↓ (track progress)
        
Done! 🎉
```

### For Subsequent Deployments:

```
Step 1: Use DEPLOYMENT_CHECKLIST.md
        ↓ (familiar with process)
        
Step 2: Reference DEPLOYMENT_COMPLETE_GUIDE.md as needed
        ↓ (if you forget a step)
        
Done! 🎉
```

### When Troubleshooting:

```
Step 1: Check DEPLOYMENT_COMPLETE_GUIDE.md > Troubleshooting
        ↓ (common issues and solutions)
        
Step 2: Review DEPLOYMENT_FLOW_DIAGRAM.md
        ↓ (verify you followed correct order)
        
Step 3: Re-run verification steps from DEPLOYMENT_CHECKLIST.md
        ↓ (ensure everything is correct)
        
Fixed! ✅
```

---

## Quick Start Commands

### First Time Setup:
```bash
# 1. Environment
cp .env.example .env
# Edit .env with your values

# 2. Database
./scripts/combine-storeproc.sh
# Then execute SQL files in Supabase Dashboard

# 3. Edge Functions
./scripts/setup-production-secrets.sh
./scripts/deploy-edge-functions.sh

# 4. Frontend
npm run build:production
# Deploy to hosting provider
```

### Update Existing Deployment:

**Database Update**:
```bash
# Edit files in sql/storeproc/
./scripts/combine-storeproc.sh
# Execute sql/all_stored_procedures.sql in Supabase
```

**Edge Function Update**:
```bash
npx supabase functions deploy <function-name>
```

**Frontend Update**:
```bash
npm run build:production
# Deploy to hosting provider
```

---

## Document Sizes

| Document | Pages (approx) | Reading Time |
|----------|----------------|--------------|
| DEPLOYMENT_CHECKLIST.md | 8-10 pages | 5 min (scanning) |
| DEPLOYMENT_COMPLETE_GUIDE.md | 25-30 pages | 30 min (reading) |
| DEPLOYMENT_FLOW_DIAGRAM.md | 10-12 pages | 15 min (reading) |
| DEPLOYMENT_GUIDE_SUMMARY.md | 5-6 pages | 10 min (reading) |

---

## File Structure

```
/
├── DEPLOYMENT_README.md              ← You are here
├── DEPLOYMENT_CHECKLIST.md           ← Printable checklist
├── DEPLOYMENT_COMPLETE_GUIDE.md      ← Detailed guide
├── DEPLOYMENT_FLOW_DIAGRAM.md        ← Visual flowcharts
└── DEPLOYMENT_GUIDE_SUMMARY.md       ← Overview summary
```

---

## Integration with CLAUDE.md

The main `CLAUDE.md` file has a **Deployment** section that references these documents:

- Links to `DEPLOYMENT_COMPLETE_GUIDE.md` for full instructions
- Contains quick reference for common tasks
- Shows deployment order

**When to update**: If you change the deployment process, update both:
1. The relevant deployment document(s)
2. The Deployment section in `CLAUDE.md`

---

## Maintenance

### When Deployment Process Changes:

1. **Update the main guide**: `DEPLOYMENT_COMPLETE_GUIDE.md`
2. **Update the checklist**: `DEPLOYMENT_CHECKLIST.md`
3. **Update the flow diagram**: `DEPLOYMENT_FLOW_DIAGRAM.md` (if order changes)
4. **Update the summary**: `DEPLOYMENT_GUIDE_SUMMARY.md` (if major changes)
5. **Update CLAUDE.md**: Deployment section (if order/process changes)

### Version Control:
- All deployment docs are version controlled in Git
- Major changes should be documented in commit messages
- Consider tagging releases with deployment guide versions

---

## Support & Troubleshooting

### If Deployment Fails:

1. **Check the Troubleshooting section** in `DEPLOYMENT_COMPLETE_GUIDE.md`
2. **Verify you followed the correct order** using `DEPLOYMENT_FLOW_DIAGRAM.md`
3. **Run verification steps** from `DEPLOYMENT_CHECKLIST.md`
4. **Check logs**:
   - Supabase Dashboard > Database > Logs
   - Supabase Dashboard > Edge Functions > Logs
   - Browser console (for frontend issues)
   - Stripe Dashboard > Webhooks > Logs

### Common Issues:

| Issue | Fix Location |
|-------|-------------|
| "Permission denied for function" | `DEPLOYMENT_COMPLETE_GUIDE.md` > Troubleshooting |
| Password reset not working | `DEPLOYMENT_COMPLETE_GUIDE.md` > Part 2C |
| Edge Function 401 error | `DEPLOYMENT_COMPLETE_GUIDE.md` > Troubleshooting |
| Stripe webhook failing | `DEPLOYMENT_COMPLETE_GUIDE.md` > Part 3C |
| Build errors | Check `package.json` and run `npm run type-check` |

---

## Deployment Phases

### Phase 1: Preparation (15 minutes)
- Read documentation
- Gather credentials
- Set up accounts
- **Document**: `DEPLOYMENT_GUIDE_SUMMARY.md`

### Phase 2: Backend Setup (45 minutes)
- Database deployment
- Storage configuration
- Auth configuration
- **Document**: `DEPLOYMENT_COMPLETE_GUIDE.md` Part 2

### Phase 3: Edge Functions (35 minutes)
- Secrets configuration
- Function deployment
- Webhook setup
- **Document**: `DEPLOYMENT_COMPLETE_GUIDE.md` Part 3

### Phase 4: Frontend (45 minutes)
- Build process
- Deployment
- Domain configuration
- **Document**: `DEPLOYMENT_COMPLETE_GUIDE.md` Part 4

### Phase 5: Verification (45 minutes)
- Run all tests
- Verify functionality
- Check monitoring
- **Document**: `DEPLOYMENT_COMPLETE_GUIDE.md` Part 5

### Phase 6: Launch (30 minutes)
- Final checks
- Go live
- Monitor initial usage
- **Document**: `DEPLOYMENT_CHECKLIST.md` Final section

**Total Time**: ~3-4 hours for first deployment

---

## Team Roles

### Who Should Read What:

**DevOps/Backend Developer**:
- Primary: `DEPLOYMENT_COMPLETE_GUIDE.md`
- Reference: `DEPLOYMENT_CHECKLIST.md`

**Frontend Developer**:
- Primary: `DEPLOYMENT_COMPLETE_GUIDE.md` Part 4
- Reference: `DEPLOYMENT_CHECKLIST.md` Part 4

**Project Manager**:
- Primary: `DEPLOYMENT_GUIDE_SUMMARY.md`
- Reference: `DEPLOYMENT_FLOW_DIAGRAM.md`

**QA/Tester**:
- Primary: `DEPLOYMENT_COMPLETE_GUIDE.md` Part 5
- Reference: `DEPLOYMENT_CHECKLIST.md` Part 5

**Stakeholder/Executive**:
- Primary: `DEPLOYMENT_GUIDE_SUMMARY.md`

---

## Feedback & Improvements

### How to Improve These Docs:

1. Deploy following the guides
2. Note any confusing sections
3. Document any issues you encountered
4. Update the relevant document(s)
5. Commit changes with descriptive message

### What to Document:

- Missing steps
- Confusing explanations
- New troubleshooting scenarios
- Time estimate inaccuracies
- Better ways to do things

---

## Quick Links

- **Full Guide**: [DEPLOYMENT_COMPLETE_GUIDE.md](DEPLOYMENT_COMPLETE_GUIDE.md)
- **Checklist**: [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
- **Flow Diagram**: [DEPLOYMENT_FLOW_DIAGRAM.md](DEPLOYMENT_FLOW_DIAGRAM.md)
- **Summary**: [DEPLOYMENT_GUIDE_SUMMARY.md](DEPLOYMENT_GUIDE_SUMMARY.md)
- **Main Docs**: [CLAUDE.md](CLAUDE.md)

---

**Last Updated**: 2025-10-15  
**Version**: 1.0.0  
**Maintained By**: Development Team

