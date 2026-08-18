/// Named route path constants.
/// Never write raw path strings in widgets — always use these constants.
class RouteNames {
  RouteNames._();

  // ── Core ──────────────────────────────────────────────────
  static const String splash     = '/splash';      // same as Module 0
  static const String onboarding = '/onboarding';  // same as Module 0

  // ── Auth (Module 2) ───────────────────────────────────────
  static const String phoneEntry          = '/auth/phone';
  static const String otpVerify           = '/auth/otp';
  static const String roleSelect          = '/auth/role';    // same path as Module 0
  static const String pendingVerification = '/auth/pending'; // same path as Module 0

  // ── Public (Module 3) ─────────────────────────────────────
  static const String publicMap    = '/public/map';
  static const String centerDetail = '/public/center/:centerId';

  // ── Victim (Module 4) ─────────────────────────────────────
  static const String victimHome    = '/victim/home';
  static const String submitRequest = '/victim/request/submit';
  static const String myRequests    = '/victim/requests';
  static const String requestDetail = '/victim/request/:requestId';
  static const String trackDelivery = '/victim/track/:taskId';
  static const String victimQr      = '/victim/qr/:requestId';

  // ── Volunteer (Module 5) ──────────────────────────────────
  static const String volunteerHome    = '/volunteer/home';
  static const String requestMap       = '/volunteer/map';
  static const String requestList      = '/volunteer/requests';
  static const String requestDetailVol = '/volunteer/request/:requestId';
  static const String acceptTask       = '/volunteer/task/accept/:requestId';
  static const String registerCenter   = '/volunteer/center/register';
  static const String myCenters        = '/volunteer/centers';
  static const String centerInventory  = '/volunteer/center/:centerId/inventory';
  static const String addStock         = '/volunteer/center/:centerId/stock/add';
  static const String taskHistory      = '/volunteer/tasks/history';
  static const String taskDetail       = '/volunteer/tasks/detail';

  // ── Coordinator (Module 6 & 7) ────────────────────────────
  static const String coordinatorDashboard  = '/coordinator/home';
  static const String manageSubCoordinators = '/coordinator/sub-coordinators';
  static const String parcelManager         = '/coordinator/parcels';
  static const String dispatch              = '/coordinator/dispatch';
  static const String stockLog              = '/coordinator/stock-log';
  static const String confirmCollection     = '/coordinator/confirm/:taskId';

  // ── Delivery (Module 7) ───────────────────────────────────
static const String activeTask        = '/delivery/task/:taskId';     // ← already there
static const String collectionConfirm = '/delivery/collect/:taskId';  // ← already there
static const String deliveryConfirm   = '/delivery/confirm/:taskId';  // ← already there
static const String qrScanner         = '/delivery/qr/:taskId';       // ← ADD THIS

  // ── Admin (Module 8) ──────────────────────────────────────
  static const String adminHome        = '/admin/home';
  static const String volunteerQueue   = '/admin/volunteers';
  static const String volunteerDetail  = '/admin/volunteer/:uid';
  static const String blueprintEditor  = '/admin/blueprint';
  static const String globalInventory  = '/admin/inventory';
  static const String flaggedRequests  = '/admin/flagged';
  static const String broadcast        = '/admin/broadcast';
  static const String adminMetrics     = '/admin/metrics';

  // ── Shared (All logged-in roles) ──────────────────────────
  static const String notifications = '/notifications';
  static const String profile       = '/profile';
  static const String receiptDetail = '/receipt/:receiptId';
  static const String error         = '/error';

  // ── Path builders (concrete paths with params) ────────────
  static String centerDetailPath(String centerId)    => '/public/center/$centerId';
  static String requestDetailPath(String requestId)  => '/victim/request/$requestId';
  static String trackDeliveryPath(String taskId)     => '/victim/track/$taskId';
  static String victimQrPath(String requestId)       => '/victim/qr/$requestId';
  static String requestDetailVolPath(String id)      => '/volunteer/request/$id';
  static String acceptTaskPath(String requestId)     => '/volunteer/task/accept/$requestId';
  static String centerInventoryPath(String centerId) => '/volunteer/center/$centerId/inventory';
  static String addStockPath(String centerId)        => '/volunteer/center/$centerId/stock/add';
  static String confirmCollectionPath(String taskId) => '/coordinator/confirm/$taskId';
  static String activeTaskPath(String taskId)        => '/delivery/task/$taskId';
  static String collectionConfirmPath(String taskId) => '/delivery/collect/$taskId';
  static String deliveryConfirmPath(String taskId)   => '/delivery/confirm/$taskId';
  static String volunteerDetailPath(String uid)      => '/admin/volunteer/$uid';
  static String receiptDetailPath(String receiptId)  => '/receipt/$receiptId';
  static String qrScannerPath(String taskId)    => '/delivery/qr/$taskId'; // ← ADD THIS
}