# Batch Minimum Configuration - Flow Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Environment Configuration                     │
├─────────────────────────────────────────────────────────────────┤
│  .env.local (Development)                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ VITE_BATCH_MIN_QUANTITY=100                               │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Production Environment (Vercel/Netlify/etc)                   │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ VITE_BATCH_MIN_QUANTITY=100                               │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Build Time (Vite)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Frontend Component                            │
│                 CardIssuanceCheckout.vue                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  const minBatchQuantity =                                       │
│    Number(import.meta.env.VITE_BATCH_MIN_QUANTITY) || 100      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ InputNumber                                             │   │
│  │ ┌─────────────────────────────────────────────────────┐ │   │
│  │ │ v-model="newBatch.cardCount"                        │ │   │
│  │ │ :min="minBatchQuantity"  ← Dynamic from env         │ │   │
│  │ │ :max="1000"                                         │ │   │
│  │ └─────────────────────────────────────────────────────┘ │   │
│  │                                                         │   │
│  │ Helper Text:                                            │   │
│  │ "Minimum batch size: {minBatchQuantity} cards"         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Default Value: cardCount = minBatchQuantity                   │
│  Reset Value: cardCount = minBatchQuantity                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ User Input
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Validation Layer                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Frontend Validation (PrimeVue InputNumber)                     │
│  ┌───────────────────────────────────────────────────┐         │
│  │  if (input < minBatchQuantity) {                  │         │
│  │    // Auto-adjust to minimum                      │         │
│  │    cardCount = minBatchQuantity                   │         │
│  │  }                                                 │         │
│  │                                                    │         │
│  │  // Decrement button disabled at minimum          │         │
│  │  decrementDisabled = (value === minBatchQuantity) │         │
│  └───────────────────────────────────────────────────┘         │
│                                                                 │
│  Backend Validation (None for minimum)                         │
│  ┌───────────────────────────────────────────────────┐         │
│  │  // Only validates maximum and positive            │         │
│  │  if (p_quantity <= 0 OR p_quantity > 1000)        │         │
│  │    RAISE EXCEPTION                                 │         │
│  │  // No minimum validation                          │         │
│  └───────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

## User Interaction Flow

```
User Opens Batch Dialog
         │
         ▼
┌────────────────────────┐
│ Dialog Loads           │
│ - Default: 100 cards   │ ← minBatchQuantity from env
│ - Min: 100             │
│ - Max: 1000            │
└────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────────┐
│                    User Actions                            │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Action 1: Decrease Button                                │
│  ┌──────────────────────────────────────────┐             │
│  │ Try: 100 → 99                            │             │
│  │ Result: Blocked (button disabled)        │             │
│  └──────────────────────────────────────────┘             │
│                                                            │
│  Action 2: Manual Input (type "50")                       │
│  ┌──────────────────────────────────────────┐             │
│  │ Try: Type "50"                           │             │
│  │ Result: Auto-adjusts to 100              │             │
│  └──────────────────────────────────────────┘             │
│                                                            │
│  Action 3: Increase Button                                │
│  ┌──────────────────────────────────────────┐             │
│  │ Try: 100 → 101                           │             │
│  │ Result: Success ✓                        │             │
│  └──────────────────────────────────────────┘             │
│                                                            │
│  Action 4: Submit with 100                                │
│  ┌──────────────────────────────────────────┐             │
│  │ Backend: Accepts (no min validation)     │             │
│  │ Result: Batch created ✓                  │             │
│  └──────────────────────────────────────────┘             │
└────────────────────────────────────────────────────────────┘
```

## Configuration Scenarios

```
Scenario 1: Default (No env var set)
┌─────────────────────────────────────────┐
│ Environment: (not set)                  │
│ Code: || 100  ← Fallback               │
│ Result: minBatchQuantity = 100          │
│ UI: [Input: 100] Min: 100              │
└─────────────────────────────────────────┘

Scenario 2: Custom Minimum (Testing)
┌─────────────────────────────────────────┐
│ Environment: VITE_BATCH_MIN_QUANTITY=10 │
│ Code: Number("10")                      │
│ Result: minBatchQuantity = 10           │
│ UI: [Input: 10] Min: 10                │
└─────────────────────────────────────────┘

Scenario 3: Production Standard
┌─────────────────────────────────────────┐
│ Environment: VITE_BATCH_MIN_QUANTITY=100│
│ Code: Number("100")                     │
│ Result: minBatchQuantity = 100          │
│ UI: [Input: 100] Min: 100              │
└─────────────────────────────────────────┘

Scenario 4: High Volume Client
┌─────────────────────────────────────────┐
│ Environment: VITE_BATCH_MIN_QUANTITY=200│
│ Code: Number("200")                     │
│ Result: minBatchQuantity = 200          │
│ UI: [Input: 200] Min: 200              │
└─────────────────────────────────────────┘

Scenario 5: Invalid Value
┌─────────────────────────────────────────┐
│ Environment: VITE_BATCH_MIN_QUANTITY=abc│
│ Code: Number("abc") → NaN              │
│ Fallback: || 100                        │
│ Result: minBatchQuantity = 100          │
└─────────────────────────────────────────┘
```

## Data Flow

```
┌──────────────────┐
│ Environment Var  │
│ at Build Time    │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────┐
│ Embedded in JavaScript Bundle            │
│ import.meta.env.VITE_BATCH_MIN_QUANTITY  │
└────────┬─────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────┐
│ Component Reactive Variable              │
│ const minBatchQuantity = 100             │
└────────┬─────────────────────────────────┘
         │
         ├─────────────────────────────┐
         │                             │
         ▼                             ▼
┌──────────────────┐         ┌──────────────────┐
│ InputNumber      │         │ Helper Text      │
│ :min="100"       │         │ "Min: 100 cards" │
└──────────────────┘         └──────────────────┘
         │                             │
         ▼                             ▼
┌──────────────────────────────────────────┐
│ User sees:                               │
│ ┌────────────────────────────────────┐   │
│ │ Cards: [100 ▼]                     │   │
│ │ Minimum batch size: 100 cards      │   │
│ │ Credits Required: 200 credits      │   │
│ └────────────────────────────────────┘   │
└──────────────────────────────────────────┘
```

## i18n Translation Flow

```
┌─────────────────────────────────────────────────────────┐
│                   Translation Files                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  en.json:                                               │
│  "minimum_batch_size": "Minimum batch size: {count}    │
│                         cards"                          │
│                                                         │
│  zh-Hant.json:                                          │
│  "minimum_batch_size": "最低批次數量：{count} 張卡片"      │
│                                                         │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              Vue i18n Interpolation                     │
│  {{ $t('batches.minimum_batch_size',                   │
│        { count: minBatchQuantity }) }}                  │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  Rendered Output                        │
├─────────────────────────────────────────────────────────┤
│  English:  "Minimum batch size: 100 cards"              │
│  Chinese:  "最低批次數量：100 張卡片"                      │
└─────────────────────────────────────────────────────────┘
```

## Deployment Flow

```
┌──────────────────┐
│ Local Dev        │
│ .env.local       │
│ MIN=50 (testing) │
└────────┬─────────┘
         │
         ▼
┌──────────────────────┐
│ Build Development    │
│ npm run dev:local    │
│ → Embedded: MIN=50   │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ Test Locally         │
│ Minimum shows as 50  │
└──────────────────────┘

┌──────────────────┐
│ Production       │
│ Hosting Env Vars │
│ MIN=100          │
└────────┬─────────┘
         │
         ▼
┌──────────────────────┐
│ Build Production     │
│ npm run build        │
│ → Embedded: MIN=100  │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ Deploy to Hosting    │
│ Vercel/Netlify/etc   │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ Users See            │
│ Minimum shows as 100 │
└──────────────────────┘
```

## Error Handling Flow

```
Input Value Decision Tree:

User Input: _____
       │
       ▼
  Is numeric?
   │      │
  Yes     No
   │      │
   │      └─→ [Treat as 0] ─→ Adjust to MIN
   │
   ▼
 < MIN?
   │      │
  Yes     No
   │      │
   │      └─→ Is > MAX?
   │              │      │
   │             Yes     No
   │              │      │
   │              │      └─→ [Accept Value]
   │              │
   └─→ [Adjust  ←┘
        to MIN]
```

## Legend

```
┌──────────────┐
│ Box Types    │
├──────────────┤
│ │ Config     │
│ └ Frontend   │
│ ≈ Backend    │
│ ○ User       │
└──────────────┘

Arrow Types:
→  Data flow
▼  Process flow
├─ Branch/Split
```

## Notes

1. **Environment Variable**: Read at build time, embedded in bundle
2. **Fallback**: Always defaults to 100 if not set or invalid
3. **Frontend Guard**: Prevents invalid input via UI constraints
4. **Backend Agnostic**: Server doesn't validate minimum (intentional)
5. **i18n Ready**: Supports parameterized translations
6. **No Database**: Entirely configuration-driven

