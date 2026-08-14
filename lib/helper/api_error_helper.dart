import 'package:get/get.dart';

class ApiErrorHelper {
  static String _localized({
    required String en,
    required String ka,
    required String ru,
    required String es,
    required String ar,
    required String bn,
  }) {
    switch ((Get.locale?.languageCode ?? 'en').toLowerCase()) {
      case 'ka':
        return ka;
      case 'ru':
        return ru;
      case 'es':
        return es;
      case 'ar':
        return ar;
      case 'bn':
        return bn;
      default:
        return en;
    }
  }

  static String get networkErrorMessage => _localized(
        en: 'Unable to connect to the server. Check your internet connection.',
        ka: 'სერვერთან დაკავშირება ვერ მოხერხდა. შეამოწმეთ ინტერნეტი.',
        ru: 'Не удалось подключиться к серверу. Проверьте интернет-соединение.',
        es: 'No se pudo conectar con el servidor. Comprueba tu conexión a Internet.',
        ar: 'تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.',
        bn: 'সার্ভারের সাথে সংযোগ করা যায়নি। আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।',
      );

  static String get requestFailedMessage => _localized(
        en: 'The request could not be completed. Please try again.',
        ka: 'მოთხოვნა ვერ შესრულდა. გთხოვთ, სცადოთ ხელახლა.',
        ru: 'Не удалось выполнить запрос. Пожалуйста, попробуйте снова.',
        es: 'No se pudo completar la solicitud. Inténtalo de nuevo.',
        ar: 'تعذر إكمال الطلب. يرجى المحاولة مرة أخرى.',
        bn: 'অনুরোধটি সম্পন্ন করা যায়নি। আবার চেষ্টা করুন।',
      );

  static String get credentialErrorMessage => _localized(
        en: 'The phone number or password is incorrect.',
        ka: 'ტელეფონის ნომერი ან პაროლი არასწორია.',
        ru: 'Неверный номер телефона или пароль.',
        es: 'El número de teléfono o la contraseña son incorrectos.',
        ar: 'رقم الهاتف أو كلمة المرور غير صحيحة.',
        bn: 'ফোন নম্বর বা পাসওয়ার্ড সঠিক নয়।',
      );

  static String userMessage(String? rawMessage, {int? statusCode}) {
    if (statusCode == 0 || statusCode == 1) {
      return networkErrorMessage;
    }

    final String message = (rawMessage ?? '').trim();
    if (message.isEmpty) {
      return requestFailedMessage;
    }

    final String normalized = message.toLowerCase();

    const List<String> credentialMarkers = <String>[
      'credential do not match',
      'credentials do not match',
      'incorrect credential',
      'incorrect credentials',
      'invalid credential',
      'invalid credentials',
      'phone or password is incorrect',
      'wrong password',
    ];

    if (statusCode == 401 && credentialMarkers.any(normalized.contains)) {
      return credentialErrorMessage;
    }

    const List<String> networkMarkers = <String>[
      'connection to api server failed',
      'handshakeexception',
      'certificate_verify_failed',
      'certificate verify failed',
      'bad certificate',
      'socketexception',
      'clientexception',
      'dioexception',
      'failed host lookup',
      'connection refused',
      'connection reset',
      'network is unreachable',
      'network request failed',
      'xmlhttprequest error',
      'connection closed before full header was received',
      'timed out',
      'timeout',
      'ssl error',
      'tls error',
      'errno =',
    ];

    if (networkMarkers.any(normalized.contains)) {
      return networkErrorMessage;
    }

    if (statusCode != null && statusCode >= 500) {
      return requestFailedMessage;
    }

    const List<String> technicalMarkers = <String>[
      'stack trace',
      'traceback',
      'httpclient',
      'formatexception',
      'typeerror',
      'nosuchmethoderror',
      'unhandled exception',
    ];

    if (technicalMarkers.any(normalized.contains)) {
      return requestFailedMessage;
    }

    // Preserve useful backend validation/account-state messages (normally 4xx).
    return message;
  }
}
