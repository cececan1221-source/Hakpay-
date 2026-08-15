/// Bildirim soyutlaması.
/// FCM eklendiğinde UI'ya dokunulmadan bu katman değişir.
abstract class NotificationService {
  Future<void> initialize();
  Future<String?> getToken();
  Future<void> subscribeTopic(String topic);
  Stream<Map<String, dynamic>> get onMessage;
}

class DemoNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> subscribeTopic(String topic) async {}

  @override
  Stream<Map<String, dynamic>> get onMessage => const Stream.empty();
}

/// FCM bağlandığında bu sınıf implement edilir.
/// Örnek iskelet — firebase_messaging eklendiğinde doldurulur.
class FcmNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {
    // TODO: Firebase.initializeApp + messaging.requestPermission
  }

  @override
  Future<String?> getToken() async {
    // TODO: return await FirebaseMessaging.instance.getToken();
    return null;
  }

  @override
  Future<void> subscribeTopic(String topic) async {
    // TODO: await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  @override
  Stream<Map<String, dynamic>> get onMessage {
    // TODO: FirebaseMessaging.onMessage.map(...)
    return const Stream.empty();
  }
}

NotificationService createNotificationService() {
  // FCM bağımlılığı yoksa demo
  return DemoNotificationService();
}
