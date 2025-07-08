# Stored Procedures - Modular Organization

This directory contains the stored procedures for the Cardy CMS system, organized into logical modules and separated by deployment location for better maintainability and development workflow.

## Overview

The monolithic `schemaStoreProc.sql` file has been broken down into 11 focused modules, each handling specific functionality. All functions use `CREATE OR REPLACE FUNCTION` syntax, so they can be safely re-executed without conflicts.

## File Structure

### Core Files
- `execute_all.sql` - Master execution file that runs client-side modules in correct order
- `README.md` - This documentation file
- `server-side/` - Directory containing server-side stored procedures

### Deployment Separation
- **Client-Side Procedures** (main folder): Called by Vue.js frontend application
- **Server-Side Procedures** (`server-side/` folder): Called by Edge Functions and server operations

### Client-Side Modules (in execution order)
1. `01_auth_functions.sql` - Authentication and role management
2. `02_card_management.sql` - Card CRUD operations  
3. `03_content_management.sql` - Content item management
4. `04_batch_management.sql` - Card batch operations
5. `06_print_requests.sql` - Physical card printing requests
6. `07_public_access.sql` - Public card access and mobile QR scanning
7. `08_user_profiles.sql` - User profile and verification management
8. `09_user_analytics.sql` - User-level analytics and reporting
9. `10_shipping_addresses.sql` - Shipping address management
10. `11_admin_functions.sql` - Admin-only operations and system management

### Server-Side Modules (in server-side/ folder)
- `05_payment_management.sql` - Stripe payment processing (Edge Functions)

## Usage

### Execute Client-Side Modules
```sql
\i sql/storeproc/execute_all.sql
```

### Execute Server-Side Modules
```sql
\i sql/storeproc/server-side/execute_server_side.sql
```

### Execute Individual Modules
```sql
-- Example: Update only card management functions
\i sql/storeproc/02_card_management.sql

-- Example: Update only payment functions (server-side)
\i sql/storeproc/server-side/05_payment_management.sql
```

## Key Features

### Security & Authentication
- All functions use `SECURITY DEFINER` with proper authentication checks
- Row-level security enforcement and user ownership validation
- Admin role verification where required
- Audit logging for administrative actions

### Business Logic
- Two-step payment verification workflow (create intent → confirm payment)
- Comprehensive batch management with payment tracking
- Print request lifecycle management
- User verification system with admin review process

### Error Handling
- Comprehensive validation and error messages
- Proper exception handling with descriptive messages
- Transaction safety and data integrity checks

## Function Categories

### Card Management (02_card_management.sql)
- `get_user_cards()` - List user's cards
- `create_card()` - Create new card design
- `get_card_by_id()` - Get specific card details
- `update_card()` - Update card properties
- `delete_card()` - Remove card design

### Content Management (03_content_management.sql)
- `get_card_content_items()` - Get hierarchical content structure
- `create_content_item()` - Add new content item
- `update_content_item()` - Modify content item
- `update_content_item_order()` - Reorder content items
- `delete_content_item()` - Remove content item

### Batch Management (04_batch_management.sql)
- `issue_card_batch()` - Create new card batch
- `get_card_batches()` - List batches for a card
- `toggle_card_batch_disabled_status()` - Enable/disable batches
- `get_card_issuance_stats()` - Batch statistics
- `generate_batch_cards()` - Create issued cards after payment

### Payment Processing (05_payment_management.sql)
- `create_batch_payment_intent()` - Initialize Stripe payment
- `confirm_batch_payment()` - Complete payment and generate cards
- `handle_failed_batch_payment()` - Handle payment failures
- `get_batch_payment_info()` - Payment status and details

### Print Requests (06_print_requests.sql)
- `request_card_printing()` - Submit print request
- `request_card_printing_with_address()` - Print with saved address
- `get_print_requests_for_batch()` - List print requests
- `withdraw_print_request()` - Cancel print request

### Public Access (07_public_access.sql)
- `get_public_card_content()` - Public card viewing and activation
- `get_sample_issued_card_for_preview()` - Preview functionality
- `get_card_preview_access()` - Owner preview access

### User Profiles (08_user_profiles.sql)
- `get_user_profile()` - Get user profile information
- `create_or_update_basic_profile()` - Basic profile management
- `submit_verification()` - Submit verification documents
- `review_verification()` - Admin verification review
- `withdraw_verification()` - Cancel verification submission

### User Analytics (09_user_analytics.sql)
- `get_user_all_issued_cards()` - All issued cards across designs
- `get_user_issuance_stats()` - Aggregated user statistics
- `get_user_all_card_batches()` - All batches across designs
- `get_user_recent_activity()` - Recent activity feed

### Shipping Addresses (10_shipping_addresses.sql)
- `get_user_shipping_addresses()` - List saved addresses
- `create_shipping_address()` - Add new address
- `update_shipping_address()` - Modify address
- `delete_shipping_address()` - Remove address
- `set_default_shipping_address()` - Set default address
- `format_shipping_address()` - Format for display/printing

### Admin Functions (11_admin_functions.sql)
- `admin_waive_batch_payment()` - Waive payment and generate cards
- `admin_get_all_print_requests()` - Manage print requests
- `admin_update_print_request_status()` - Update print status
- `admin_get_system_stats()` - System-wide statistics
- `admin_get_pending_verifications()` - Verification queue management

## Benefits of Modular Structure

1. **Better Organization** - Related functions grouped together
2. **Easier Maintenance** - Update specific functionality without affecting others
3. **Faster Development** - Work on individual modules independently
4. **Selective Deployment** - Deploy only changed modules
5. **Improved Testing** - Test individual modules in isolation
6. **Clear Dependencies** - Numbered files indicate execution order
7. **Better Documentation** - Each module is self-contained and documented

## Development Workflow

1. **Make Changes** - Edit individual module files as needed
2. **Test Module** - Execute individual module file for testing
3. **Full Deployment** - Run `execute_all.sql` for complete update
4. **Verify Functions** - Test functionality after deployment

## Dependencies and Execution Order

The numbered prefixes ensure proper execution order:
1. Auth functions (foundation)
2. Core card/content management
3. Batch and payment processing
4. Print and public access
5. User profiles and analytics
6. Shipping and admin functions

Each module can be safely re-executed using `CREATE OR REPLACE FUNCTION` without conflicts. 