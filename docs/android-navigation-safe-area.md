# Android bottom system navigation audit

The Android Navigator is now wrapped in a bottom-only SafeArea in lib/app.dart. This covers named pages, dialogs, and modal sheets. Existing SafeAreas consume the adjusted MediaQuery padding and do not add the system inset twice. iOS and web retain their existing layout.

Confirmed by regression tests: Private Booking Save Direct Booking remains above a 48px system navigation inset; 0px and 24px insets; existing page SafeAreas; modal sheets; keyboard resizing; iOS unchanged.

## Screen-level candidates found by source audit

These files contain a Scaffold and no local SafeArea. This is a potential exposure list, not a claim that every screen was independently reproduced on a phone. Tab screens may already inherit protection from BottomNabbarView. The shared navigator fix protects standalone routes as well.

- lib/modules/auth/vehicle/views/vehicle_Information_view.dart
- lib/modules/auth/vehicle/views/vehicle_details_view.dart
- lib/modules/auth/authentication/views/success_reset_password_view.dart
- lib/modules/auth/authentication/views/change_password_view.dart
- lib/modules/auth/authentication/views/signin_view.dart
- lib/modules/auth/vehicle/views/add_new_vehicle_view.dart
- lib/modules/auth/authentication/views/account_succes_view.dart
- lib/modules/auth/authentication/views/auth_selection_view.dart
- lib/modules/auth/authentication/views/personal_document_view.dart
- lib/modules/auth/authentication/views/personal_document_detail_view.dart
- lib/modules/auth/authentication/views/documents_upload_view.dart
- lib/modules/auth/authentication/views/all_vehicle_view.dart
- lib/modules/auth/profile/views/settings_view.dart
- lib/modules/auth/authentication/views/create_account_view.dart
- lib/modules/deals/views/deals_view.dart
- lib/modules/auth/splash/views/splash_view.dart
- lib/modules/preferred_drivers/views/preferred_driver_profile_view.dart
- lib/modules/preferred_drivers/views/preferred_drivers_view.dart
- lib/modules/request_under_review/views/request_under_review_view.dart
- lib/modules/market_place/views/market_place_view.dart
- lib/modules/rides/views/rides_view.dart
- lib/modules/market_place/views/market_place_detail_view.dart
- lib/modules/notifications/views/notifications_view.dart
- lib/modules/invoice/views/saved_clients_view.dart
- lib/modules/invoice/views/invoice_settings_view.dart
- lib/modules/invoice/views/invoice_profile_settings_view.dart
- lib/modules/ratings_feedback/views/ratings_feedback_view.dart
- lib/modules/my_schedule/views/widgets/add_schedule_job_sheet.dart
- lib/modules/invoice/views/invoice_preview_view.dart
- lib/modules/jobs_offers/views/Job_offer_view.dart
- lib/modules/invoice/views/invoice_history_view.dart
- lib/modules/my_schedule/views/schedule_job_detail_view.dart
- lib/modules/invoice/views/invoice_detail_view.dart
- lib/modules/my_schedule/views/my_schedule_view.dart
- lib/modules/invoice/views/create_invoice_view.dart
- lib/modules/my_items/views/my_Items_view.dart
- lib/modules/expense/views/expense_detail_sheet.dart

## Device verification

Physical Android device verification is still needed for three-button navigation and gesture navigation, including keyboard open/closed and the Add/Edit Private Booking, vehicle forms, documents, invoices, and modal sheets.
