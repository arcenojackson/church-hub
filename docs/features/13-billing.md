# Feature: Billing & Subscription Tiers

## Overview
Commercial SaaS billing system that manages church subscriptions and feature access.
**New Implementation — no current code**

### Tier Definitions

| Tier | Name | Max Members | Ads | Societies | Calendar Art | Evaluations | Holyrics |
|---|---|---|---|---|---|---|---|
| `free` | Free | 30 | ✅ | ❌ | ❌ | ❌ | ❌ |
| `basic` | Basic | 100 | ❌ | ❌ | ❌ | ❌ | ❌ |
| `pro` | Pro | 300 | ❌ | ✅ | ✅ | ❌ | ❌ |
| `max` | Max | Unlimited | ❌ | ✅ | ✅ | ✅ | ✅ |

### Add-on User Packages
- **Basic**: +50 users ($X/mo), +200 users ($Y/mo)
- **Pro**: +200 users ($X/mo), +500 users ($Y/mo)
- **Free**: No add-ons available
- **Max**: No add-ons needed (unlimited)

### Subscription Model (`ChurchSubscriptionModel`)
```json
{
  "tier": "basic",
  "userLimit": 150,
  "addons": [
    { "type": "extra_50_users", "quantity": 1, "price": 9.90 }
  ],
  "billingStatus": "active",
  "billingCycle": "monthly",
  "stripeCustomerId": "cus_XXX",
  "trialEndsAt": null,
  "nextBillingDate": "2026-05-05"
}
```

### Stripe Integration
- Use Stripe via Firebase Functions webhooks
- Customer creation on church signup
- Subscription lifecycle: create, update, cancel, pause
- Webhooks for payment success/failure, subscription changes
- Hosted checkout (Stripe Checkout) for payment collection

### Billing Cloud Functions

| Function | Trigger | Purpose |
|---|---|---|
| `onSubscriptionChanged` | onUpdate `churches/{churchId}/subscription` | Apply tier changes, enable/disable features |
| `subscriptionChecker` | Scheduled (daily) | Check expired/trial-ending, apply limits |
| `stripeWebhookHandler` | HTTP | Handle Stripe events (payment success, failure, cancellation) |

### Feature Enforcement at Backend
- When a church's tier changes, Cloud Functions update feature flags
- Security Rules enforce tier at the database level
- Example: if Pro→Basic, `societies` collection becomes read-only, `evaluations` becomes inaccessible

### Super Admin Dashboard
- View all churches with their tiers and billing status
- Manually change a church's tier (override)
- Revenue metrics

### Multi-tenant Changes Needed
- `churches/{churchId}/subscription` — per-church subscription tracking
- Platform-level billing admin for super admin
- Stripe Integration: one Stripe account with multiple customers (one per church)
