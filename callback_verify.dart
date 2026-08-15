/// Anket / offerwall postback doğrulama iskeleti.
/// Gerçek doğrulama SUNUCUDA yapılır. Bu dosya istemci tarafı
/// referans ve dokümantasyon içindir.
///
/// Backend örneği (sunucu):
/// POST /v1/callbacks/offerwall
/// Headers: X-Provider-Signature: ...
/// Body: { user_id, transaction_id, amount, currency, ... }
///
/// Kurallar:
/// 1. Secret APK'da olmaz — sadece sunucu ortam değişkeni
/// 2. transaction_id / reference_id tek kullanımlık
/// 3. Puan yazmadan önce imza + tutar + kullanıcı doğrulanır
/// 4. İstemci asla "puan ver" demez

class CallbackVerifyHints {
  static const offerwallPath = '/v1/callbacks/offerwall';
  static const surveyPath = '/v1/callbacks/survey';

  /// Sunucu tarafında kontrol edilmesi gerekenler (kontrol listesi)
  static const serverChecklist = [
    'Provider secret sadece sunucu env\'de',
    'HMAC / signature doğrulama',
    'transaction_id tekillik (DB unique)',
    'user_id eşleşmesi',
    'Tutar sunucu tarafında hesaplanır veya whitelist',
    'Idempotent credit (aynı ref ikinci kez puan yazmaz)',
    'Rate limit + IP / fraud kontrolü',
  ];
}
