# Release checklist

## Kodda tamamlanan
- [x] HakPay branding/logo
- [x] Demo/remote service locator
- [x] Wallet/auth/withdrawal/ad service boundaries
- [x] Catalog repository boundary
- [x] AdMob adapter
- [x] Play Billing adapter
- [x] Streak/referral/VIP/subscription/early-access service boundaries
- [x] CI analyze/test/APK/AAB workflow
- [x] No secret keys embedded

## Yayın öncesi dışarıdan tamamlanacak
- [ ] Backend URL + production DB
- [ ] AdMob production IDs
- [ ] Survey/offerwall provider + postback secrets on backend
- [ ] Play Console VIP/subscription product IDs
- [ ] Google Play signing setup
- [ ] Privacy Policy / Terms / account deletion and required store disclosures
- [ ] Real withdrawal provider
- [ ] Production security/rate limits/fraud controls

The source package cannot honestly be called a fully live earning/withdrawal system until these external services exist.
