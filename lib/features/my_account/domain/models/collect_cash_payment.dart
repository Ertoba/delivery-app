/// A transfer is successful only after the authenticated backend confirms the
/// payment AND its cash-accounting receipt. Browser redirects are merely hints.
enum CollectCashPaymentState { pending, success, failed }

class CollectCashPaymentStatus {
  final String paymentId;
  final CollectCashPaymentState state;

  const CollectCashPaymentStatus(this.paymentId, this.state);

  factory CollectCashPaymentStatus.fromJson(
    Map<dynamic, dynamic> json,
    String expectedPaymentId,
  ) {
    if (json['payment_id'] != expectedPaymentId) {
      throw const FormatException('Payment identity mismatch');
    }
    final bool confirmed =
        json['status'] == 'success' &&
        json['is_paid'] == true &&
        json['is_settled'] == true;
    return CollectCashPaymentStatus(
      expectedPaymentId,
      confirmed
          ? CollectCashPaymentState.success
          : json['status'] == 'failed' && json['is_paid'] != true
          ? CollectCashPaymentState.failed
          : CollectCashPaymentState.pending,
    );
  }
}

class CollectCashPayment {
  static const statusPath =
      '/api/v1/delivery-man/collected-cash-payment-status';
  final Uri redirectUri;
  final String paymentId;
  final Uri statusUri;

  const CollectCashPayment({
    required this.redirectUri,
    required this.paymentId,
    required this.statusUri,
  });

  factory CollectCashPayment.fromJson(Map<dynamic, dynamic> json, Uri baseUri) {
    final String id = json['payment_id']?.toString() ?? '';
    final Uri? redirect = Uri.tryParse(json['redirect_link']?.toString() ?? '');
    final Uri? status = Uri.tryParse(json['status_url']?.toString() ?? '');
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(id) ||
        redirect == null ||
        !_sameSecureOrigin(redirect, baseUri) ||
        status == null ||
        !_sameSecureOrigin(status, baseUri) ||
        status.path != statusPath ||
        status.queryParametersAll['payment_id']?.length != 1 ||
        status.queryParameters['payment_id'] != id ||
        status.queryParameters.containsKey('token')) {
      throw const FormatException('Invalid cash payment session');
    }
    final redirectId = redirect.queryParameters['payment_id'];
    if (redirectId != null && redirectId != id) {
      throw const FormatException('Payment identity mismatch');
    }
    return CollectCashPayment(
      redirectUri: redirect,
      paymentId: id,
      statusUri: status,
    );
  }
}

class CollectCashPaymentResult {
  final CollectCashPayment? payment;
  final String message;
  bool get isSuccess => payment != null;

  const CollectCashPaymentResult.success(CollectCashPayment session)
    : payment = session,
      message = '';
  const CollectCashPaymentResult.failure(this.message) : payment = null;
}

enum CollectCashCallback { success, failed, cancelled }

class CollectCashNavigationPolicy {
  final Uri baseUri;
  const CollectCashNavigationPolicy(this.baseUri);

  CollectCashCallback? callback(Uri uri) {
    if (!_sameSecureOrigin(uri, baseUri) ||
        uri.path != '/success' ||
        uri.queryParametersAll['flag']?.length != 1 ||
        uri.hasFragment) {
      return null;
    }
    return switch (uri.queryParameters['flag']) {
      'success' => CollectCashCallback.success,
      'fail' => CollectCashCallback.failed,
      'cancel' => CollectCashCallback.cancelled,
      _ => null,
    };
  }

  // HTTPS bank/ACS challenges stay in the sheet. Do not launch arbitrary
  // intent://, custom schemes, javascript:, file:, or a separate browser.
  bool allowsInline(Uri uri) {
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.port != 443) {
      return false;
    }
    // Bank HTTPS challenges may use different origins, but an off-origin
    // imitation of our result URL is never an app payment callback.
    if (uri.path == '/success' && uri.queryParameters.containsKey('flag')) {
      return callback(uri) != null;
    }
    return true;
  }
}

bool _sameSecureOrigin(Uri uri, Uri base) =>
    uri.scheme == 'https' &&
    uri.host == base.host &&
    uri.port == base.port &&
    uri.userInfo.isEmpty;
