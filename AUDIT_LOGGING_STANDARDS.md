# Audit Logging Standards & Action Details

## Overview
This document defines the standardized patterns for audit logging across all stored procedures in the CardStudio platform.

## Standard Action Details Structure

All `action_details` JSONB fields should follow these patterns for consistency:

### Core Fields (Required)
```json
{
  "action": "specific_action_name",  // e.g., "verification_approved", "payment_confirmed"
  "entity_type": "entity_name",      // e.g., "batch", "user", "verification"
  "entity_id": "uuid"                // Primary entity being acted upon
}
```

### Common Optional Fields
```json
{
  "is_admin_action": true|false,     // Whether admin performed this action
  "security_impact": "high|medium|low", // Security significance
  "automated": true|false,           // Whether action was automated
  "target_email": "user@example.com", // Target user's email for context
  "reason_category": "category"      // Categorized reason for action
}
```

## Action Type Standards

### 1. VERIFICATION_REVIEW
**Usage**: User verification approval/rejection
```json
{
  "action": "verification_approved|verification_rejected|verification_reviewed",
  "review_type": "APPROVED|REJECTED",
  "has_feedback": true|false,
  "target_email": "user@example.com"
}
```

### 2. PAYMENT_CONFIRMATION
**Usage**: Payment processing completion
```json
{
  "action": "payment_confirmed",
  "payment_method": "stripe|manual|waived",
  "stripe_checkout_session_id": "session_id",
  "batch_id": "uuid",
  "amount_cents": 200,
  "currency": "usd",
  "cards_count": 50,
  "automated_card_generation": true
}
```

### 3. PAYMENT_CREATION
**Usage**: Payment session initialization
```json
{
  "action": "payment_session_created",
  "stripe_checkout_session_id": "session_id",
  "stripe_payment_intent_id": "intent_id",
  "batch_id": "uuid",
  "amount_cents": 200,
  "currency": "usd",
  "metadata": {}
}
```

### 4. CARD_GENERATION
**Usage**: Card generation after payment or waiver
```json
{
  "action": "cards_generated",
  "batch_id": "uuid",
  "card_id": "uuid",
  "cards_count": 50,
  "is_admin_action": true|false,
  "payment_method": "waived|stripe|unknown",
  "batch_name": "Batch Name"
}
```

### 5. ROLE_CHANGE
**Usage**: User role modifications by admin
```json
{
  "action": "role_changed",
  "from_role": "card_issuer",
  "to_role": "admin",
  "target_email": "user@example.com",
  "is_promotion": true|false,
  "is_demotion": true|false,
  "security_impact": "high|medium|low"
}
```

### 6. PAYMENT_WAIVER
**Usage**: Admin waiving payment for batch
```json
{
  "action": "payment_waived",
  "batch_id": "uuid",
  "cards_count": 50,
  "waiver_reason": "promotional",
  "automated_card_generation": true
}
```

### 7. PRINT_REQUEST_STATUS_UPDATE
**Usage**: Print request status changes by admin
```json
{
  "action": "print_status_updated",
  "request_id": "uuid",
  "batch_id": "uuid",
  "card_name": "Card Name",
  "batch_name": "Batch Name",
  "from_status": "SUBMITTED",
  "to_status": "PROCESSING"
}
```

### 8. PRINT_REQUEST_WITHDRAWAL
**Usage**: User withdrawing print request
```json
{
  "action": "print_request_withdrawn",
  "request_id": "uuid",
  "batch_id": "uuid",
  "card_name": "Card Name",
  "batch_name": "Batch Name",
  "self_withdrawal": true|false
}
```

### 9. BATCH_STATUS_CHANGE
**Usage**: Batch enable/disable operations
```json
{
  "action": "batch_disabled|batch_enabled",
  "batch_id": "uuid",
  "card_id": "uuid",
  "batch_name": "Batch Name",
  "is_admin_action": true|false,
  "status_change": "enabled_to_disabled|disabled_to_enabled"
}
```

## Security Guidelines

### High Impact Actions
Actions that require special attention in audit logs:
- Role changes (promotion/demotion)
- Payment waivers
- Admin-initiated card generation
- Verification status changes

### Required Context
For high-impact actions, always include:
- Target user email
- Security impact level
- Whether action was admin-initiated
- Detailed reason in the `reason` field

### Sensitive Data Handling
- Never log full payment details or PII beyond email
- Use IDs and references instead of full objects
- Include enough context for audit trail without exposing sensitive data

## Implementation Checklist

### For Each Audit Log Entry
- [ ] Action type is from approved list
- [ ] Action details follow standard structure
- [ ] Security impact is assessed and logged
- [ ] Target user is properly identified
- [ ] Old/new values capture state changes accurately
- [ ] Reason is descriptive and actionable

### Code Review Standards
- [ ] All admin functions include audit logging
- [ ] Critical user actions are logged
- [ ] Action details are consistent with standards
- [ ] No sensitive data in logs
- [ ] Proper error handling around audit logging

## Migration Notes

When adding audit logging to existing functions:
1. Identify the action type and impact level
2. Follow the appropriate action_details pattern
3. Include admin detection logic where applicable
4. Test with both admin and regular user contexts
5. Update documentation and type definitions