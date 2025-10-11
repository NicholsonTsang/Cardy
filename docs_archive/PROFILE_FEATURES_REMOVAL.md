# Profile Features Removal - Complete Documentation

## Summary
This document details the complete removal of all profile-related features, verification system, and associated code from the CardStudio platform as per user request dated October 2, 2025.

## Removed Components

### 1. Frontend Components
#### Deleted Files:
- `src/components/Profile/ProfileDisplay.vue` - Main profile display component
- `src/components/Profile/WelcomeSection.vue` - Welcome section for new profiles
- `src/components/Profile/BasicProfileForm.vue` - Basic profile creation/editing form
- `src/components/Profile/VerificationForm.vue` - Verification submission form
- `src/components/Profile/VerificationBadge.vue` - Verification status badge component
- `src/views/Dashboard/CardIssuer/Profile.vue` - Card issuer profile page
- `src/views/Dashboard/Admin/VerificationManagement.vue` - Admin verification management page

### 2. State Management (Pinia Stores)
#### Deleted Files:
- `src/stores/profile.ts` - Profile state management store
- `src/stores/admin/verifications.ts` - Admin verifications store
- `src/stores/admin/feedback.ts` - Verification feedback store

#### Updated Files:
- `src/stores/admin.ts` - Removed all verification and feedback imports, exports, and methods
- `src/stores/admin/dashboard.ts` - Removed verification-related stats and computed properties
- `src/components/Layout/AppHeader.vue` - Removed verification menu item and profile settings link
- `src/views/Dashboard/Admin/UserManagement.vue` - Completely rewritten to remove verification features, kept only basic user listing and role management

### 3. Backend (Database)
#### Deleted Files:
- `sql/storeproc/client-side/08_user_profiles.sql` - All user profile stored procedures

#### Tables to be Dropped (requires manual DB update):
- `user_profiles` - Main profiles table
- `verification_feedbacks` - Verification feedback messages
- Related triggers and indexes

#### Stored Procedures to be Dropped (requires manual DB update):
- `create_or_update_profile()`
- `get_user_profile()`
- `submit_verification()`
- `review_verification()`
- `withdraw_verification()`
- `reset_user_verification()`
- `manual_verification()`
- `get_pending_verifications()`
- `get_all_verifications()`
- `get_verification_by_id()`
- `get_verification_feedbacks()`
- `create_or_update_verification_feedback()`

### 4. Router Configuration
#### Updated Files:
- `src/router/index.ts` - Removed profile and verification routes:
  - Removed `/cms/profile` route (Card Issuer profile page)
  - Removed `/cms/verifications` route (Admin verification management page)

### 5. Admin Dashboard Updates
#### Updated Interface in `src/stores/admin/dashboard.ts`:
**Removed Fields:**
- `total_verified_users`
- `pending_verifications`
- `recent_feedback_count`
- `total_feedback_count`

**Removed Computed Properties:**
- `pendingVerificationCount`

**Removed Store Methods:**
- All verification-related methods from `useAdminStore`
- All feedback-related methods from `useAdminStore`

## Database Schema Changes Required

### Schema Changes Applied:

✅ **Removed from `schema.sql`:**
- `ProfileStatus` ENUM type definition
- `user_profiles` table definition
- `verification_feedbacks` table definition
- `update_user_profiles_updated_at` trigger
- All related indexes for verification feedbacks

✅ **Updated in `all_stored_procedures.sql`:**
- Removed all user profile stored procedures (from `08_user_profiles.sql`)

### Manual Database Deployment Required:

```bash
# Deploy the updated schema and stored procedures
cd /Users/nicholsontsang/coding/Cardy

# Deploy updated schema (will drop old tables)
psql "$DATABASE_URL" -f sql/schema.sql

# Deploy updated stored procedures (without profile functions)
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

**Alternative using Supabase CLI:**
```bash
# If using Supabase locally
supabase db reset

# Or push specific migration
supabase db push
```

### Admin Functions to Update:
The following admin functions will need to be reviewed and updated as they may have dependencies on `user_profiles`:
- `admin_get_system_stats_enhanced()` - Remove verification-related stats
- `get_recent_admin_activity()` - May reference user profile changes
- Any audit logging functions that track profile/verification changes

## Affected Business Workflows

### Removed Workflows:
1. **User Verification & Compliance Flow** - Complete removal
   - Registration/profile creation
   - Document submission
   - Admin review and approval
   - Account verification status tracking
   - Ongoing monitoring

2. **Profile Management** - Complete removal
   - Profile creation and editing
   - Company information management
   - Bio/description fields
   - Public display name management

### Remaining Workflows (Unaffected):
- Card creation and design
- Content management
- Batch issuance and payment
- Print request management
- Analytics and reporting
- Admin user management (basic auth only)

## Admin Dashboard Impact

### Removed Metrics:
- Total verified users count
- Pending verifications count
- Recent feedback count
- Total feedback count

### Removed Admin Features:
- Verification queue management
- Document review
- Approval/rejection workflow
- Verification feedback system
- User verification status updates
- Manual verification capability

## Navigation Changes

### Card Issuer Dashboard:
- **Removed:** Profile Settings menu item (`/cms/profile`)
- **Removed:** Account Settings section from navigation menu
- **Remaining:** My Cards, Issued Cards, Sign Out

### Admin Dashboard:
- **Removed:** Verifications menu item and page (`/cms/verifications`)
- **Remaining:** Dashboard (`/cms/admin`), Users, Batches, Print Requests, History Logs, Sign Out

## Migration Checklist

### Frontend (Completed):
- [x] Deleted all profile-related components (7 files)
- [x] Deleted profile and verification stores (3 files)
- [x] Updated admin store to remove verification references
- [x] Updated admin dashboard store interface
- [x] Removed profile and verification routes from router
- [x] Updated admin dashboard view to remove verification UI
- [x] Updated AppHeader navigation to remove profile settings and verifications menu

### Backend (Completed):
- [x] Deleted `08_user_profiles.sql` stored procedures file
- [x] Removed `ProfileStatus` enum from `schema.sql`
- [x] Removed `user_profiles` table from `schema.sql`
- [x] Removed `verification_feedbacks` table from `schema.sql`
- [x] Removed `update_user_profiles_updated_at` trigger from `schema.sql`
- [x] Removed verification feedback indexes from `schema.sql`
- [x] Added new user management functions to `11_admin_functions.sql`:
  - `admin_get_all_users()` - Get all users with basic info and stats
  - `admin_update_user_role()` - Update user role with audit logging
- [x] Regenerated `all_stored_procedures.sql` with new user management functions

### Database Deployment (Requires Manual Action):
- [ ] Deploy updated `schema.sql` to database
- [ ] Deploy updated `all_stored_procedures.sql` to database
- [ ] Verify `admin_get_system_stats_enhanced()` function works without profile tables
- [ ] Verify no foreign key dependencies remain
- [ ] Test application after deployment

### Testing Required:
- [ ] Test Card Issuer dashboard loads without profile
- [ ] Test Admin dashboard loads without verification stats
- [ ] Test card creation flow (ensure no profile dependencies)
- [ ] Test batch issuance flow
- [ ] Test print request workflow
- [ ] Test admin user management
- [ ] Verify no console errors related to missing stores
- [ ] Verify no broken navigation links

## Breaking Changes

### For Existing Users:
- **Profile data will be permanently deleted** when database changes are applied
- Users will no longer have verification status
- Card creation will not require profile setup
- No public display names (may need alternative for card attribution)

### For Admin Users:
- Cannot review or manage user verifications
- No verification-based access control
- Cannot track verification history
- No verification feedback system

## Alternative Approaches (Not Implemented)

If verification/compliance is needed in the future, consider:
1. External KYC/KYB service integration (Stripe Identity, Onfido, etc.)
2. Simplified verification flag in `auth.users` metadata
3. Separate verification microservice
4. Third-party identity verification API

## Rollback Plan

If profile features need to be restored:
1. Restore deleted component files from git history
2. Restore deleted store files from git history
3. Restore `08_user_profiles.sql` from git history
4. Restore router configuration
5. Re-run database migrations
6. Restore `user_profiles` and `verification_feedbacks` tables
7. Regenerate `all_stored_procedures.sql`

## Notes

- This is a **destructive change** - profile data cannot be recovered after database changes
- Ensure all stakeholders are aware of removed features
- Consider backup of `user_profiles` table data before dropping
- Update user documentation to reflect removed features
- Update API documentation if applicable
- Review and update CLAUDE.md project documentation

## References

- Original request: "Delete all the profile related code, file and features of the schema, storeproc and frontend"
- Date: October 2, 2025
- Ticket: N/A
- Review: Required before database deployment

---

**⚠️ WARNING:** Do not apply database changes to production without:
1. Full backup
2. Stakeholder approval
3. User communication
4. Verified frontend deployment
5. Rollback plan confirmation

