// lib/customer/payment_screen.dart
//
// "Pay deposit" screen shown after tapping Book Now.
//
// Payments go through Stripe Checkout (Stripe's own secure, hosted page):
//  1. The app asks the `createCheckoutSession` Cloud Function for a payment page.
//     The function sets the amount (£10) on the server, so it can't be changed.
//  2. The customer pays on Stripe's page — card, Apple Pay or Google Pay.
//     Card details never touch this app.
//  3. Stripe tells the `stripeWebhook` Cloud Function, which creates the
//     booking in Firestore (`bookings/{ref}`) and marks `payments/{id}` as
//     "paid" with its `bookingRef`. This screen listens to that payment doc
//     and shows the booking as soon as it appears — but the booking exists
//     either way, even if the customer closed the app mid-payment.
//
// The money goes into the salon's own Stripe account, which pays out to the
// business bank account automatically. See functions/index.js.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'salon_messages.dart' show MessageBadge;
import '../theme/app_colors.dart';
import 'customer_nav.dart';
import 'profile/profile_ui.dart' show openProfile;
import 'activity_screen.dart';
import 'booking_store.dart';
import 'profile/profile_store.dart';
import '../theme/app_text.dart';

/// Must match the region in functions/index.js.
const String _functionsRegion = 'europe-west2';

class PaymentScreen extends StatefulWidget {
  final String serviceName;
  final int? servicePrice; // null = POA
  final DateTime date;
  final String time;
  final double deposit;

  const PaymentScreen({
    super.key,
    required this.serviceName,
    required this.servicePrice,
    required this.date,
    required this.time,
    required this.deposit,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

enum _Stage { ready, opening, waiting, finishing }

class _PaymentScreenState extends State<PaymentScreen> {
  // Colours from the design
  static const Color _bg = AppColors.bg;
  static const Color _blue = AppColors.accent;
  static const Color _text = AppColors.text;
  static const Color _muted = AppColors.muted;
  static const Color _border = AppColors.border;
  static const Color _infoBg = AppColors.accentSoft;

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final _phoneCtrl = TextEditingController(
    text: CustomerProfile.instance.phone,
  );
  final _phoneKey = GlobalKey<FormFieldState<String>>();

  final _functions = FirebaseFunctions.instanceFor(region: _functionsRegion);

  _Stage _stage = _Stage.ready;
  String? _paymentId;
  Uri? _checkoutUrl;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _paymentSub;

  @override
  void dispose() {
    // Left the screen mid-payment (e.g. bottom nav): close the Stripe page so it
    // can't be paid without a booking. If it was already paid, Stripe still has it.
    if (_stage == _Stage.waiting && _paymentId != null) {
      unawaited(
        _functions
            .httpsCallable('cancelCheckoutSession')
            .call({'paymentId': _paymentId})
            .then((_) {}, onError: (_) {}),
      );
    }
    _paymentSub?.cancel();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String get _depositLabel => '£${widget.deposit.toStringAsFixed(0)}';

  String _two(int n) => n.toString().padLeft(2, '0');
  String get _isoDate =>
      '${widget.date.year}-${_two(widget.date.month)}-${_two(widget.date.day)}';

  void _showMessage(String text, {Color color = AppColors.danger}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  // ───────────────────────── Payment ─────────────────────────

  /// Step 1: create the Stripe Checkout page on the server and open it.
  Future<void> _startPayment() async {
    if (!_phoneKey.currentState!.validate()) return;
    final phone = _phoneCtrl.text.trim();
    if (phone != CustomerProfile.instance.phone) {
      CustomerProfile.instance.update(
        () => CustomerProfile.instance.phone = phone,
      );
    }

    setState(() => _stage = _Stage.opening);
    try {
      final result = await _functions
          .httpsCallable('createCheckoutSession')
          .call<Map<String, dynamic>>({
            'serviceName': widget.serviceName,
            'servicePrice': widget.servicePrice,
            'date': _isoDate,
            'time': widget.time,
            'phone': phone,
            'customerName': CustomerProfile.instance.fullName,
          });
      final paymentId = result.data['paymentId'] as String;
      final url = Uri.parse(result.data['url'] as String);

      _paymentId = paymentId;
      _checkoutUrl = url;
      _listenForResult(paymentId);
      if (!mounted) return;
      setState(() => _stage = _Stage.waiting);
      await _openCheckout();
    } on FirebaseFunctionsException catch (e) {
      setState(() => _stage = _Stage.ready);
      _showMessage(
        e.message ?? 'Could not start the payment. Please try again.',
      );
    } catch (_) {
      setState(() => _stage = _Stage.ready);
      _showMessage(
        'Could not start the payment. Check your connection and try again.',
      );
    }
  }

  Future<void> _openCheckout() async {
    final url = _checkoutUrl;
    if (url == null) return;
    final opened = await launchUrl(
      url,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.inAppBrowserView,
      webOnlyWindowName: '_blank',
    );
    if (!opened) _showMessage('Could not open the payment page.');
  }

  /// Step 2: wait for Stripe's webhook to mark payments/{id} as paid.
  void _listenForResult(String paymentId) {
    _paymentSub?.cancel();
    _paymentSub = FirebaseFirestore.instance
        .collection('payments')
        .doc(paymentId)
        .snapshots()
        .listen(
          (snap) {
            final data = snap.data();
            if (data == null) return;
            switch (data['status']) {
              case 'paid':
                final ref = data['bookingRef'] as String?;
                if (ref != null) _onPaid(ref);
              case 'expired':
                _resetAfterFailure(
                  'The payment page expired. No money was taken — please try again.',
                );
            }
          },
          onError: (_) =>
              _showMessage('Lost connection while waiting for the payment.'),
        );
  }

  /// Customer tapped "Cancel": close the Stripe page on the server so it
  /// can't be paid later without a booking.
  Future<void> _cancelPayment() async {
    final paymentId = _paymentId;
    if (paymentId == null) return;
    try {
      final result = await _functions
          .httpsCallable('cancelCheckoutSession')
          .call<Map<String, dynamic>>({'paymentId': paymentId});
      if (result.data['status'] == 'paid') {
        // Already paid — the listener will confirm the booking any moment.
        _showMessage(
          'Your payment already went through — confirming your booking…',
          color: _blue,
        );
        return;
      }
      _resetAfterFailure(
        'Payment cancelled. No money was taken.',
        color: AppColors.muted,
      );
    } catch (_) {
      _showMessage(
        'Could not cancel right now. If you didn\'t pay, the page expires in 30 minutes.',
      );
    }
  }

  void _resetAfterFailure(String message, {Color color = AppColors.danger}) {
    _paymentSub?.cancel();
    _paymentSub = null;
    _paymentId = null;
    _checkoutUrl = null;
    if (!mounted) return;
    setState(() => _stage = _Stage.ready);
    _showMessage(message, color: color);
  }

  /// Step 3: the server created the booking → show it.
  Future<void> _onPaid(String bookingRef) async {
    if (_stage == _Stage.finishing || !mounted) return;
    await _paymentSub?.cancel();
    _paymentSub = null;
    setState(() => _stage = _Stage.finishing);

    if (!kIsWeb) {
      closeInAppWebView().catchError((_) {});
    }

    Booking? booking = BookingStore.instance.find(bookingRef);
    for (var attempt = 0; booking == null && attempt < 3; attempt++) {
      try {
        booking = await BookingStore.instance.fetch(bookingRef);
      } catch (_) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    if (!mounted) return;

    if (booking == null) {
      // Paid, but couldn't load it right now — it's safe in Firestore.
      _showMessage(
        'Payment received! Your booking $bookingRef will appear in My bookings shortly.',
        color: _blue,
      );
      Navigator.popUntil(context, isCustomerRoot);
      return;
    }

    // Show "Booking confirmed" (back arrow goes to My bookings, not the payment form).
    final confirmed = booking;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BookingDetailScreen(booking: confirmed, justBooked: true),
      ),
      isCustomerRoot,
    );
  }

  String _formatDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final busy = _stage != _Stage.ready;
    return PopScope(
      canPop: !busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _stage == _Stage.waiting) _cancelPayment();
      },
      child: Scaffold(
        backgroundColor: _bg,
        bottomNavigationBar: _buildBottomNav(),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _buildTopBar(),
              const SizedBox(height: 18),
              const Text(
                'Pay your deposit',
                style: TextStyle(
                  fontFamily: AppFonts.heading,
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: _text,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pay your deposit to confirm your booking.',
                style: TextStyle(fontSize: 14, color: _muted),
              ),
              const SizedBox(height: 18),
              _buildSummary(),
              const SizedBox(height: 22),
              _buildContact(),
              const SizedBox(height: 22),
              _buildHowYouPay(),
              const SizedBox(height: 22),
              if (_stage == _Stage.waiting || _stage == _Stage.finishing)
                _buildWaitingPanel()
              else
                _buildPayButton(),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Only the $_depositLabel deposit is charged today.',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.maybePop(context),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.arrow_back, color: _text, size: 22),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Payment',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _text,
          ),
        ),
      ],
    );
  }

  // Booking summary card
  Widget _buildSummary() {
    final price = widget.servicePrice;
    return _whiteBox(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.serviceName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDate(widget.date)} · ${widget.time}',
                      style: const TextStyle(fontSize: 12.5, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: _border),
          _summaryRow('Treatment price', price == null ? 'POA' : '£$price'),
          const SizedBox(height: 6),
          _summaryRow('Deposit due now', _depositLabel, bold: true),
          if (price != null && price > widget.deposit) ...[
            const SizedBox(height: 6),
            _summaryRow(
              'Remaining balance',
              '£${(price - widget.deposit).toStringAsFixed(0)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: 13.5,
      color: bold ? _text : _muted,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }

  // Phone number
  Widget _buildContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your phone number',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _text,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: _phoneKey,
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
          ],
          validator: (v) =>
              (v ?? '').replaceAll(RegExp(r'[^0-9]'), '').length < 10
              ? 'Enter a valid phone number'
              : null,
          style: const TextStyle(fontSize: 15, color: _text),
          decoration: _inputDecoration(hint: '07123 456789'),
        ),
        const SizedBox(height: 6),
        const Text(
          'The salon uses this to contact you about your booking.',
          style: TextStyle(fontSize: 12, color: _muted),
        ),
      ],
    );
  }

  // Accepted methods + security note
  Widget _buildHowYouPay() {
    Widget chip(IconData icon, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _text),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12.5, color: _text)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How you\'ll pay',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _text,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip(Icons.credit_card, 'Debit / credit card'),
            chip(Icons.apple, 'Apple Pay'),
            chip(Icons.account_balance_wallet_outlined, 'Google Pay'),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _infoBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, color: _blue, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secure payment by Stripe',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _text,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'You\'ll enter your details on Stripe\'s secure page. '
                      'The salon never sees or stores your card number.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    final opening = _stage == _Stage.opening;
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: opening ? null : _startPayment,
        style: FilledButton.styleFrom(
          backgroundColor: _blue,
          disabledBackgroundColor: _blue.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: opening
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Pay $_depositLabel deposit',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Shown while the customer is on Stripe's page
  Widget _buildWaitingPanel() {
    final finishing = _stage == _Stage.finishing;
    return _whiteBox(
      borderColor: _blue,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: _blue),
          ),
          const SizedBox(height: 12),
          Text(
            finishing
                ? 'Payment received — confirming your booking…'
                : 'Waiting for your payment…',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _text,
            ),
          ),
          if (!finishing) ...[
            const SizedBox(height: 4),
            const Text(
              'Finish paying on the Stripe page. This screen updates by itself once it\'s done.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: _muted, height: 1.35),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelPayment,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _text,
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _openCheckout,
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Reopen page'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────── Small helpers ─────────────────────────

  InputDecoration _inputDecoration({String? hint, Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.muted),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      suffixIcon: suffix,
      enabledBorder: border(_border),
      focusedBorder: border(_blue, 1.5),
      errorBorder: border(AppColors.danger.withValues(alpha: 0.6)),
      focusedErrorBorder: border(AppColors.danger, 1.5),
    );
  }

  Widget _whiteBox({
    required Widget child,
    EdgeInsets? padding,
    Color borderColor = _border,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.search, color: AppColors.muted),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.home_outlined, color: AppColors.muted),
                onPressed: () => goCustomerHome(context),
              ),
              IconButton(
                icon: MessageBadge(
                  child: Icon(Icons.bookmark_border, color: AppColors.muted),
                ),
                onPressed: () => openActivity(context),
              ),
              IconButton(
                icon: const Icon(
                  Icons.account_circle_outlined,
                  color: Colors.black,
                ),
                onPressed: () => openProfile(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
