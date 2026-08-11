class ApiConstants {
  // Base URL
  // static const String baseUrl = 'https://nayem5001.binarybards.online/api/v1';
  static const String baseUrl = 'https://api.ekkali.app/api/v1';
  // static const String baseUrl = 'http://10.10.7.47:5003/api/v1';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';

  // Registration & Verification
  static const String signup = '/user';
  static const String resendVerifyEmail = '/auth/resend-verify-email';
  static const String verifyEmail = '/auth/verify-email';

  // Password Management
  static const String forgotPassword = '/auth/forget-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // User Endpoints
  static const String profile = '/user/profile';
  static const String userProfile = '/user/profile';
  // Marketplace Endpoints
  static const String items = '/items';

  // Create JobEndpoint
  static const String createJob = '/jobs';
  static const String myJobs = '/jobs/my-jobs';

  static const String getAllJobOffers = '/jobs';
  static const String applytoJob = '/jobs/{jobId}/apply';
  static const String myRides = '/jobs/my-rides';
  static const String rejectApplicant = '/jobs/{jobId}/reject-applicant';
  static const String approveApplicant = '/jobs/{jobId}/approve-applicant';
  static const String cancelJobOffer = '/jobs/{jobId}/cancel';
  static const String updateJob = '/jobs/{jobId}';
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
  //Service Areas
  static const String serviceAreas = '/service-areas';

  // Legal Endpoints
  static const String legals = '/legals';
  static const String legalsBySlug = '/legals/{{slug}}';

  //Support Endpoints
  static const String myTickets = '/supports/my-tickets';
  static const String createSupport = '/supports';

  // Community Chat Endpoints
  static const String communityRoom = '/community-chats/room';
  static const String communityMessages = '/community-chats/messages';

  // Driver Endpoints
  static const String deleteVehicle = '/user/vehicles/{{vehicleId}}';
  static const String deleteAccount = '/user/delete-account';

  // Expense Endpoints
  static const String expenses = '/expenses';
  static const String expensesTotal = '/expenses/total';

  // Invoice Endpoints
  static const String invoices = '/invoices';
  static const String invoiceProfile = '/invoices/profile';
  static const String invoiceClient = '/invoices/client';
}


