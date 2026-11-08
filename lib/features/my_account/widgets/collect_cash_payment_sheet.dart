import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/my_account/domain/models/collect_cash_payment.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';

typedef CashPaymentContentBuilder =
    Widget Function(
      BuildContext context,
      Future<void> Function(Uri) onMainFrameNavigation,
    );

/// Lives in the payment-method modal itself: no browser window, payment route,
/// success route, or global navigator operations are involved.
class CollectCashPaymentSheet extends StatefulWidget {
  final CollectCashPayment payment;
  final Future<CollectCashPaymentStatus> Function(CollectCashPayment) verify;
  final Future<void> Function() refreshAccount;
  final CashPaymentContentBuilder? contentBuilder;
  final Duration pollDelay;
  final bool statusOnly;
  final void Function(CollectCashPayment, CollectCashPaymentState)? onTerminal;

  const CollectCashPaymentSheet({
    super.key,
    required this.payment,
    required this.verify,
    required this.refreshAccount,
    this.contentBuilder,
    this.pollDelay = const Duration(seconds: 1),
    this.statusOnly = false,
    this.onTerminal,
  });

  @override
  State<CollectCashPaymentSheet> createState() =>
      _CollectCashPaymentSheetState();
}

class _CollectCashPaymentSheetState extends State<CollectCashPaymentSheet>
    with WidgetsBindingObserver {
  final _policy = CollectCashNavigationPolicy(Uri.parse(AppConstants.baseUrl));
  InAppWebViewController? _webView;
  bool _verifying = false;
  bool _closed = false;
  bool _showPending = false;
  bool _loadError = false;
  int _progress = 0;
  CollectCashPaymentState? _terminal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.statusOnly) {
      _showPending = true;
      _progress = 100;
    }
  }

  @override
  void dispose() {
    _closed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_closed && _terminal == null) {
      unawaited(_verify());
    }
  }

  Future<void> _navigation(Uri uri) async {
    if (_closed || _terminal != null || _policy.callback(uri) == null) return;
    await _verify(attempts: 4);
  }

  Future<void> _verify({int attempts = 1}) async {
    // onLoadStart/onLoadStop/override/popup callbacks can race. A single
    // verification owns settlement handling and account refresh.
    if (!mounted || _closed || _verifying || _terminal != null) return;
    setState(() {
      _verifying = true;
      _showPending = false;
    });
    var status = CollectCashPaymentState.pending;
    try {
      for (var attempt = 0; attempt < attempts; attempt++) {
        final result = await widget.verify(widget.payment);
        if (!mounted || _closed) return;
        if (result.paymentId == widget.payment.paymentId) status = result.state;
        if (status != CollectCashPaymentState.pending) break;
        if (attempt + 1 < attempts) {
          await Future<void>.delayed(widget.pollDelay);
        }
        if (!mounted || _closed) return;
      }
      if (status != CollectCashPaymentState.pending) {
        widget.onTerminal?.call(widget.payment, status);
      }
      if (status == CollectCashPaymentState.success) {
        // Refresh errors must not turn a confirmed transfer into a retry of
        // the payment creation call. It remains paid; refresh can retry later.
        try {
          await widget.refreshAccount();
        } catch (_) {
          /* read-only retry later */
        }
        if (!mounted || _closed) return;
      }
    } catch (_) {
      status = CollectCashPaymentState.pending;
    } finally {
      if (mounted && !_closed) {
        setState(() {
          _verifying = false;
          _showPending = status == CollectCashPaymentState.pending;
          if (status != CollectCashPaymentState.pending) _terminal = status;
        });
      }
    }
  }

  void _close() {
    if (_closed || !mounted) return;
    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) return;
    _closed = true;
    Navigator.of(context).pop(_terminal ?? CollectCashPaymentState.pending);
  }

  @override
  Widget build(BuildContext context) {
    final bool success = _terminal == CollectCashPaymentState.success;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'payment'.tr,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  key: const Key('cash-payment-close'),
                  tooltip: 'cancel_payment'.tr,
                  onPressed: _close,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (_verifying ||
                (_progress < 100 && _terminal == null && !_loadError))
              const LinearProgressIndicator(),
            if (_verifying) Text('cash_payment_verifying'.tr),
            if (_terminal != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error_outline,
                          size: 64,
                          color: success ? Colors.green : Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          (success
                                  ? 'your_payment_is_successfully_completed'
                                  : 'your_payment_is_not_done')
                              .tr,
                          key: const Key('cash-payment-result'),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(onPressed: _close, child: Text('okay'.tr)),
                      ],
                    ),
                  ),
                ),
              ),
            if (_terminal == null) ...[
              if (_showPending || _loadError)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'cash_payment_status_pending'.tr,
                    key: const Key('cash-payment-pending'),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_showPending || _loadError)
                TextButton(
                  key: const Key('cash-payment-verify'),
                  onPressed: _verifying ? null : () => _verify(attempts: 4),
                  child: Text('try_again'.tr),
                ),
              if (!widget.statusOnly)
                Expanded(
                  child:
                      widget.contentBuilder?.call(context, _navigation) ??
                      InAppWebView(
                        initialUrlRequest: URLRequest(
                          url: WebUri(widget.payment.redirectUri.toString()),
                        ),
                        initialSettings: InAppWebViewSettings(
                          useShouldOverrideUrlLoading: true,
                          javaScriptEnabled: true,
                          supportMultipleWindows: true,
                          javaScriptCanOpenWindowsAutomatically: false,
                          mixedContentMode:
                              MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
                          allowFileAccess: false,
                          allowContentAccess: false,
                        ),
                        onWebViewCreated: (controller) => _webView = controller,
                        shouldOverrideUrlLoading: (controller, action) async {
                          final uri = action.request.url;
                          if (uri == null || !_policy.allowsInline(uri)) {
                            return NavigationActionPolicy.CANCEL;
                          }
                          if (action.isForMainFrame != false &&
                              _policy.callback(uri) != null) {
                            unawaited(_navigation(uri));
                            return NavigationActionPolicy.CANCEL;
                          }
                          return NavigationActionPolicy.ALLOW;
                        },
                        onLoadStart: (controller, uri) {
                          if (uri != null) unawaited(_navigation(uri));
                        },
                        onLoadStop: (controller, uri) {
                          if (uri != null) unawaited(_navigation(uri));
                        },
                        onProgressChanged: (controller, progress) {
                          if (mounted && !_closed) {
                            setState(() => _progress = progress);
                          }
                        },
                        onReceivedError: (controller, request, error) {
                          if (request.isForMainFrame == true &&
                              mounted &&
                              !_closed) {
                            setState(() => _loadError = true);
                          }
                        },
                        onCreateWindow: (controller, action) async {
                          // Keep HTTPS 3DS/ACS popups in our owned WebView, not an
                          // unmanaged browser. Reject unknown/custom intent schemes.
                          final uri = action.request.url;
                          if (uri != null && _policy.allowsInline(uri)) {
                            if (_policy.callback(uri) != null) {
                              unawaited(_navigation(uri));
                            } else {
                              await _webView?.loadUrl(
                                urlRequest: URLRequest(url: uri),
                              );
                            }
                          }
                          return false;
                        },
                      ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
