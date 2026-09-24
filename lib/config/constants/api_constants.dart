class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://nayem5001.binarybards.online/api/v1';
  // static const String baseUrl = 'https://api.ekkali.app/api/v1';
  // static const String baseUrl = 'http://10.10.7.47:5003/api/v1';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';

  // Registration & Verification
  static const String signup = '/auth/register';
  static const String resendOtp = '/auth/resend-otp';
  static const String resendVerifyEmail = '/auth/resend-otp';
  static const String verifyEmail = '/auth/verify-otp';
  static const String vehicles = '/vehicles';
  static const String vehicleConfigOptions = '/vehicle-configs/options';
  static const String documents = '/documents';

  // Password Management
  static const String forgotPassword = '/auth/forget-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // User Endpoints
  static const String profile = '/user/profile';
  static const String userProfile = '/user/profile';
  // Marketplace Endpoints
  static const String items = '/items';
  static const String feedItems = '/items/feed';

  // Create JobEndpoint
  static const String createJob = '/jobs';
  static const String myJobs = '/jobs/my-jobs';
  static const String calendarJobs = '/jobs/calendar';

  static const String getAllJobOffers = '/jobs/feed';
  static const String applytoJob = '/jobs/{jobId}/apply';
  static const String myRides = '/jobs/my-rides';
  static const String rejectApplicant = '/jobs/{jobId}/reject-applicant';
  static const String approveApplicant = '/jobs/{jobId}/approve-applicant';
  static const String cancelJobOffer = '/jobs/{jobId}/cancel';
  static const String updateJob = '/jobs/{jobId}';
  static const String getJobDetails = '/jobs/{jobId}';
  static const String updateRideStatus = '/jobs/{jobId}/ride-status';
  //Deals Endpoints
  static const String dealsItems = '/deals';
  static const String ratingsFeedback = '/user/my-reviews';
  //My Items
  static const String myItems = '/items/my-items';
  static const String myItemsUpdate = '/items/{{itemId}}';

  //socket_io endpoints
  static const String chats = '/chats';
  static const String chatsId = '/chats/{{chatId}}';
  static const String messages = '/messages/{{chatId}}';
  static const String jobReview = '/jobs/{jobId}/review';
  //Notifications
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String deviceToken = '/notifications/device-token';
  //Service Areas
  static const String serviceAreas = '/service-areas/options';

  // Legal Endpoints
  static const String legals = '/legals';
  static const String legalsBySlug = '/legals/{{slug}}';

  //Support Endpoints
  static const String myTickets = '/supports/my-tickets';
  static const String createSupport = '/supports';
  static const String supports = '/supports';

  // Community Chat Endpoints
  static const String communityRoom = '/community-chats/room';
  static const String communityMessages = '/community-chats/messages';

  // Driver & Vehicle Endpoints
  static const String deleteVehicle = '/vehicles/{{vehicleId}}';
  static const String deleteAccount = '/user/delete-account';

  // Expense Endpoints
  static const String expenses = '/expenses';
  static const String expensesTotal = '/expenses/total';

  // Invoice Endpoints
  static const String invoices = '/invoices';
  static const String invoiceProfile = '/invoices/profile';
  static const String invoiceClient = '/invoices/client';

  // Favorites & Chauffeurs Endpoints
  static const String favorites = '/users/favorites';
  static const String chauffeurs = '/users/chauffeurs';
  static const String users = '/users';

  // Subscription Endpoints
  static const String subscriptionVerifyApple = '/subscriptions/verify-apple';
  static const String subscriptionVerifyGoogle = '/subscriptions/verify-google';
  static const String subscriptionRestore = '/subscriptions/restore';
  static const String subscriptionStatus = '/subscriptions/status';
}
