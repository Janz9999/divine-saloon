// lib/customer/customer_nav.dart
//
// Bottom-bar navigation for the customer area.
// The customer area starts at SalonDetailScreen (pushed after login with the
// name [customerRootRoute]). Tabs replace everything above that screen, so
// "Home", "Activity" and "Profile" never fall back to the Welcome screen.

import 'package:flutter/material.dart';

import 'customer_home_screen.dart';

const String customerRootRoute = 'customer-root';

/// True for the first customer screen (or the app's first route as a fallback).
bool isCustomerRoot(Route<dynamic> r) =>
    r.settings.name == customerRootRoute || r.isFirst;

/// Opens a tab screen on top of the customer root, clearing anything between.
void openCustomerTab(BuildContext context, Widget screen) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => screen),
    isCustomerRoot,
  );
}

/// Home tab: the treatments home screen.
void goCustomerHome(BuildContext context) =>
    openCustomerTab(context, const CustomerHomeScreen());

/// Search tab: back to the salon screen (the customer root).
void goCustomerExplore(BuildContext context) =>
    Navigator.popUntil(context, isCustomerRoot);
