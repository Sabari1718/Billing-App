class ApiConfig {
  // Centralized Base URLs
  static const String validationBaseUrl = "https://mobilevalidation.srivagroups.in/api";
  static const String adminBaseUrl = "https://mobileadmin.srivagroups.in/api";
  static const String billingBaseUrl = "https://billing.srivagroups.in/api";

  // Production Endpoints
  static const String userAppData = "$validationBaseUrl/UserAppData";
  static const String deviceStore = "$validationBaseUrl/device/store";
  static const String variants = "$adminBaseUrl/variants";
  static const String login = "$billingBaseUrl/auth/login";
}
