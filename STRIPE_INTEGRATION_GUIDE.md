# Stripe Payment Integration for Cardy CMS

## Overview
This guide covers the complete Stripe payment integration for the Cardy platform, replacing the previous dummy implementation with real payment processing for card batch issuance.

## 🎯 **Integration Architecture**

### **Frontend (Vue.js)**
- **Stripe Elements**: Real card input with validation
- **Payment Flow**: Integrated into CardIssurance component
- **Environment Variables**: Configurable pricing and currency

### **Backend (Supabase Edge Functions)**
- **Payment Intent Creation**: `create-payment-intent` Edge Function
- **Payment Confirmation**: `confirm-payment` Edge Function
- **Database Integration**: Automatic batch updates and card generation

### **Security**
- **Publishable Key**: Frontend environment variable (safe for client-side)
- **Secret Key**: Server-side only via Supabase Edge Function secrets
- **Payment Intents**: Secure server-side payment processing

## 🔧 **Setup Instructions**

### **1. Environment Variables**

Add to your `.env` file:
```bash
# Frontend (client-safe)
VITE_STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here

# Backend (server-only)
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here

# Business Configuration
VITE_CARD_PRICE_CENTS=200
VITE_DEFAULT_CURRENCY=USD
```

### **2. Supabase Configuration**

The Stripe secret key is automatically configured in `supabase/config.toml`:
```toml
stripe_secret_key = "env(STRIPE_SECRET_KEY)"
```

### **3. Edge Functions**

Two Edge Functions are created for secure payment processing:

#### **`create-payment-intent`**
- Creates Stripe payment intents
- Validates user authentication
- Stores payment records in database
- Returns client secret for frontend

#### **`confirm-payment`**
- Verifies payment success with Stripe
- Updates batch payment status
- Triggers card generation
- Handles error scenarios

## 💳 **Payment Flow**

### **1. Batch Creation**
```javascript
// User creates batch via CardIssurance component
handleIssueBatch() -> Creates batch in database (without cards)
```

### **2. Payment Intent Creation**
```javascript
// Frontend calls Supabase Edge Function
createBatchPaymentIntent(cardCount, batchId, metadata)
// Edge Function calls Stripe API
// Returns client_secret for frontend
```

### **3. Payment Processing**
```javascript
// Frontend collects payment details via Stripe Elements
// Confirms payment with Stripe
confirmBatchPayment(clientSecret, elements, billingDetails)
```

### **4. Payment Confirmation**
```javascript
// Frontend calls confirm-payment Edge Function
// Verifies payment status with Stripe
// Updates database and generates cards
```

## 📊 **Key Features**

### **Real-time Payment Processing**
- ✅ Secure card input with Stripe Elements
- ✅ Real-time validation and error handling
- ✅ Custom styling matching Cardy theme

### **Configurable Pricing**
- ✅ Environment-based card pricing (`VITE_CARD_PRICE_CENTS`)
- ✅ Multi-currency support (`VITE_DEFAULT_CURRENCY`)
- ✅ Dynamic cost calculation

### **Database Integration**
- ✅ Payment records in `batch_payments` table
- ✅ Automatic batch status updates
- ✅ Card generation after successful payment

### **Error Handling**
- ✅ Payment failures gracefully handled
- ✅ User-friendly error messages
- ✅ Retry mechanisms for incomplete payments

## 🔄 **Updated Components**

### **CardIssurance.vue**
- ✅ Real Stripe Elements integration
- ✅ Payment dialog with card input
- ✅ Payment status tracking
- ✅ Resume payment functionality

### **stripe.js Utility**
- ✅ Complete rewrite using `@stripe/stripe-js`
- ✅ Stripe Elements creation and management
- ✅ Payment intent handling
- ✅ Error handling and validation

## 🚀 **Testing**

### **Test Mode**
- Use Stripe test keys for development
- Test card numbers available in Stripe documentation
- All payments are simulated (no real charges)

### **Common Test Cards**
```
Visa: 4242 4242 4242 4242
Visa (debit): 4000 0566 5566 5556
Mastercard: 5555 5555 5555 4444
American Express: 3782 8224 6310 005
```

### **Test Scenarios**
- ✅ Successful payments
- ✅ Declined cards
- ✅ Invalid card details
- ✅ Network failures
- ✅ Payment resumption

## 📋 **Deployment Checklist**

### **Development Environment**
- [ ] Test Stripe keys configured
- [ ] Edge Functions deployed locally
- [ ] Database schema up to date
- [ ] Payment flow tested end-to-end

### **Production Environment**
- [ ] Live Stripe keys configured
- [ ] Environment variables set in hosting platform
- [ ] Edge Function secrets configured in Supabase
- [ ] Payment webhooks configured (if needed)
- [ ] SSL certificates valid
- [ ] Error monitoring enabled

## 🛡️ **Security Best Practices**

### **✅ Implemented**
- Stripe secret key never exposed to frontend
- Payment intents created server-side only
- User authentication verified for all payments
- Input validation on all payment parameters
- Secure database updates after payment confirmation

### **🔒 Additional Recommendations**
- Enable Stripe webhooks for production
- Implement payment reconciliation
- Add fraud detection rules in Stripe Dashboard
- Monitor unusual payment patterns
- Regular security audits

## 🚨 **Common Issues & Solutions**

### **1. Payment Intent Creation Fails**
```
Error: "Failed to create payment intent"
Solution: Check STRIPE_SECRET_KEY in Edge Function environment
```

### **2. Stripe Elements Not Loading**
```
Error: "Failed to load Stripe"
Solution: Verify VITE_STRIPE_PUBLISHABLE_KEY is correct
```

### **3. Payment Confirmation Fails**
```
Error: "Payment not properly initialized"
Solution: Ensure Stripe Elements are mounted before payment
```

### **4. Cards Not Generated After Payment**
```
Error: Card generation fails silently
Solution: Check generate_batch_cards stored procedure
```

## 📞 **Support**

### **Stripe Documentation**
- [Stripe.js Reference](https://stripe.com/docs/js)
- [Payment Intents API](https://stripe.com/docs/api/payment_intents)
- [Elements Styling](https://stripe.com/docs/elements/appearance-api)

### **Supabase Documentation**
- [Edge Functions](https://supabase.com/docs/guides/functions)
- [Environment Variables](https://supabase.com/docs/guides/functions/environment-variables)

## 🎉 **Migration Complete**

The Cardy CMS now has a fully functional Stripe payment integration:

- ✅ **Real payment processing** instead of dummy implementation
- ✅ **Secure server-side** payment handling via Edge Functions
- ✅ **Professional UI** with Stripe Elements
- ✅ **Environment-based configuration** for easy deployment
- ✅ **Comprehensive error handling** for production reliability
- ✅ **Database integration** for seamless card generation

The payment system is now production-ready and can process real payments for card batch issuance!