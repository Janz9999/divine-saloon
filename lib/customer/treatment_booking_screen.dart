// lib/customer/treatment_booking_screen.dart

import 'package:flutter/material.dart';

import 'salon_messages.dart' show MessageBadge;
import '../theme/app_colors.dart';
import 'customer_nav.dart';
import 'profile/profile_ui.dart' show openProfile;
import 'activity_screen.dart';

import 'payment_screen.dart';
import 'service_image.dart';

/// Details, price list and date/time booking for one service card
/// (opened from [CategoryDetailScreen] or straight from the home screen).
class TreatmentBookingScreen extends StatefulWidget {
  /// One card map from lib/customer/catalog/ (title, image, tagline,
  /// description, highlights, note, services).
  final Map<String, dynamic> card;

  /// Shown if the card's own photo is missing (the category banner).
  final String? fallbackImage;

  const TreatmentBookingScreen({
    super.key,
    required this.card,
    this.fallbackImage,
  });

  @override
  State<TreatmentBookingScreen> createState() => _TreatmentBookingScreenState();
}

class _TreatmentBookingScreenState extends State<TreatmentBookingScreen> {
  // Colours from the design
  static const Color _pink = AppColors.surface;
  static const Color _pinkBorder = AppColors.border;
  static const Color _chipGrey = AppColors.surface;
  static const Color _chipBorder = AppColors.border;
  static const Color _accent = AppColors.accent;

  static const double _depositAmount = 10;

  Map<String, dynamic> get _card => widget.card;
  List<Map<String, dynamic>> get _services =>
      List<Map<String, dynamic>>.from(_card['services'] as List? ?? const []);

  String _priceLabel(Object? price) => price == null ? 'POA' : '£$price';

  final List<String> _times = const [
    '9:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
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

  int? _selectedService;
  late DateTime _startDate;
  late DateTime _selectedDate;
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _selectedDate = _startDate;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _startDate = picked; // show the picked date first in the strip
      });
    }
  }

  void _bookNow() {
    if (_selectedService == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a treatment and a time')),
      );
      return;
    }
    final service = _services[_selectedService!];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          serviceName: service['name'] as String,
          servicePrice: service['price'] as int?,
          date: _selectedDate,
          time: _selectedTime!,
          deposit: _depositAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(),
              const SizedBox(height: 20),
              _buildDetails(),
              const SizedBox(height: 22),

              // Price list
              const Text(
                'Treatments & Prices',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a treatment to select it',
                style: TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              if (_services.isEmpty)
                Text(
                  'Prices coming soon',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              for (int i = 0; i < _services.length; i++) _buildServiceTile(i),
              if (_services.any((s) => s['price'] == null))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'POA = price on application, confirmed at your consultation.',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),

              const SizedBox(height: 30),
              _buildDateSection(),
              const SizedBox(height: 20),
              _buildTimeSection(),
              const SizedBox(height: 40),

              // Book button
              Center(
                child: SizedBox(
                  width: 210,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _bookNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pink,
                      foregroundColor: AppColors.text,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: _pinkBorder),
                      ),
                    ),
                    child: Text(
                      'Book Now £${_depositAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Banner photo with back button
  Widget _buildBanner() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ServiceImage(
            _card['image'] as String,
            fallbackPath: widget.fallbackImage,
            height: 200,
            width: double.infinity,
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Title, tagline, description, highlights and note
  Widget _buildDetails() {
    const bodyStyle = TextStyle(
      fontSize: 13.5,
      color: AppColors.text,
      height: 1.35,
    );
    final tagline = _card['tagline'] as String?;
    final description = _card['description'] as String?;
    final note = _card['note'] as String?;
    final highlights =
        (_card['highlights'] as List?)?.cast<String>() ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (_card['title'] as String).toUpperCase(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        if (tagline != null) ...[
          const SizedBox(height: 6),
          Text(
            tagline,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _pinkBorder,
            ),
          ),
        ],
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(description, style: bodyStyle),
        ],
        if (highlights.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final h in highlights)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Text('•  $h', style: bodyStyle),
            ),
        ],
        if (note != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _pink),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: _pinkBorder),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note,
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 3. Pink pill price row
  Widget _buildServiceTile(int index) {
    final service = _services[index];
    final selected = _selectedService == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedService = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 9),
        height: 31,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : _pink,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : _pinkBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                service['name'],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: AppColors.text),
              ),
            ),
            Text(
              _priceLabel(service['price']),
              style: const TextStyle(fontSize: 12, color: AppColors.text),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Choose Date strip
  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Choose Date', style: TextStyle(fontSize: 13)),
            ),
            GestureDetector(
              onTap: _pickDate,
              child: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(6, (i) {
            final date = _startDate.add(Duration(days: i));
            final selected = _sameDay(date, _selectedDate);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  margin: EdgeInsets.only(right: i == 5 ? 0 : 6),
                  height: 50,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accentSoft : _chipGrey,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? _accent : _chipBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${date.day}', style: const TextStyle(fontSize: 20)),
                      Text(
                        _weekdays[date.weekday - 1],
                        style: TextStyle(fontSize: 9, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 5. Choose Time chips (horizontal scroll)
  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Time', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        SizedBox(
          height: 22,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _times.length,
            separatorBuilder: (_, _) => const SizedBox(width: 4),
            itemBuilder: (context, i) {
              final time = _times[i];
              final selected = _selectedTime == time;
              return GestureDetector(
                onTap: () => setState(() => _selectedTime = time),
                child: Container(
                  width: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accentSoft : _chipGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? _accent : _chipBorder),
                  ),
                  child: Text(time, style: const TextStyle(fontSize: 11)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 6. Bottom navigation (search / home / saved / profile)
  Widget _buildBottomNav() {
    return SafeArea(
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
              icon: const Icon(Icons.home_outlined, color: Colors.black),
              onPressed: () => goCustomerHome(context),
            ),
            IconButton(
              icon: MessageBadge(
                child: Icon(Icons.bookmark_border, color: AppColors.muted),
              ),
              onPressed: () => openActivity(context),
            ),
            IconButton(
              icon: Icon(Icons.account_circle_outlined, color: AppColors.muted),
              onPressed: () => openProfile(context),
            ),
          ],
        ),
      ),
    );
  }
}
