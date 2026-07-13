import 'package:flutter/material.dart';
import 'package:billingapp/mainscreen/repositories/lock_repository.dart';
import 'package:billingapp/mainscreen/services/lock_service.dart';
import 'package:billingapp/mainscreen/screens/app_lock_screen.dart';

class SecurityManager extends ChangeNotifier {
  final LockRepository _repository;
  final LockService _lockService;

  // Internal locks to prevent concurrent prompts or validation loops
  bool _isLockScreenShowing = false;
  bool _isSyncing = false;
  static bool _isInitialized = false;
  static int? _initializedUserId;

  bool get isLockScreenShowing => _isLockScreenShowing;
  bool get isSyncing => _isSyncing;

  SecurityManager({
    required LockRepository repository,
    required LockService lockService,
  })  : _repository = repository,
        _lockService = lockService;

  static void resetInitialization() {
    _isInitialized = false;
    _initializedUserId = null;
  }

  /// Retrieves setting status from secure local cache
  bool isLockEnabled(String key) {
    return _repository.getLocalEnabled(key);
  }

  bool isLockConfigured(String key) {
    return _repository.isLockConfigured(key);
  }

  /// Checks if any critical lock is active in secure storage
  bool isAnyLockEnabled() {
    final bool isAppLockEnabled = isLockEnabled('is_app_lock_enabled');
    final bool isBiometricOpenEnabled = isLockEnabled('ask_biometrics_on_open');

    if (!isAppLockEnabled && !isBiometricOpenEnabled) {
      return false;
    }

    final List<String> primaryLockKeys = [
      'pincode',
      'pattern_lock',
      'fingerprint',
      'face_lock'
    ];

    for (final key in primaryLockKeys) {
      if (isLockEnabled(key)) {
        return true;
      }
    }
    return false;
  }

  /// Startup initialization: Fetches settings from API, syncs state, and secures environment
  Future<void> initializeSecurity(int userId) async {
    if (_isInitialized && _initializedUserId == userId) {
      debugPrint("SecurityManager: Already initialized for user $userId. Skipping background sync.");
      return;
    }
    _isInitialized = true;
    _initializedUserId = userId;
    _isSyncing = true;
    notifyListeners();

    try {
      final remoteSettings = await _repository.fetchLockSettings(userId);
      debugPrint("SecurityManager: Successfully synced security profile. Active status: $remoteSettings");
    } catch (e) {
      debugPrint("SecurityManager: API sync failed during initialization, relying on secure storage: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Strict gated enable flow:
  /// 1. Run lock configuration wizard
  /// 2. If successful, push enablement payload to backend API
  /// 3. Save state locally to secure storage
  /// 4. Synchronize UI
  /// Unified gated lock configuration flow:
  /// 1. Run lock configuration wizard
  /// 2. If successful, save configured state but KEEP lock disabled by default
  /// 3. Synchronize UI
  Future<bool> configureLock(BuildContext context, String key) async {
    final handler = _lockService.getHandler(key);
    
    // Run the handler's configure method (which saves configured state to secure storage)
    final bool configured = await handler.configure(context, _repository);
    if (!configured) {
      debugPrint("SecurityManager: Configuration request for $key cancelled or aborted by user.");
      return false;
    }

    debugPrint("SecurityManager: Successfully configured lock: $key.");
    notifyListeners();
    return true;
  }

  /// Enables a lock that is already configured without re-triggering the configuration flow
  Future<bool> enableLockState(BuildContext context, int userId, String key) async {
    _isSyncing = true;
    notifyListeners();

    final Map<String, bool> updatedSettings = {key: true};
    final bool success = await _repository.syncLockSettings(userId, updatedSettings);

    if (success) {
      await _repository.saveLocalConfig(key, true);
      debugPrint("SecurityManager: Successfully enabled pre-configured lock $key.");
    } else {
      debugPrint("SecurityManager: Sync failed to enable lock $key.");
    }

    _isSyncing = false;
    notifyListeners();
    return success;
  }

  /// Strict gated disable flow:
  /// 1. Request authentication verification BEFORE disabling
  /// 2. If authenticated, update backend API
  /// 3. Clear local secure cache
  /// 4. Synchronize UI
  Future<bool> disableLock(BuildContext context, int userId, String key) async {
    _isSyncing = true;
    notifyListeners();

    final Map<String, bool> updatedSettings = {key: false};
    final bool success = await _repository.syncLockSettings(userId, updatedSettings);

    if (success) {
      await _repository.deleteLocalConfig(key);
      debugPrint("SecurityManager: Successfully synchronized disable state for $key on backend.");
    } else {
      debugPrint("SecurityManager: Sync failed for disable request, reverting.");
    }

    _isSyncing = false;
    notifyListeners();
    return success;
  }

  /// General authentication gate: Runs challenge for the most secure active lock
  Future<bool> authenticateUser(BuildContext context, {String reason = 'Authenticate to proceed'}) async {
    // Priority order: Biometrics -> PIN -> Pattern -> Grid Card -> Security Tab
    final List<String> priorityKeys = [
      'fingerprint',
      'face_lock',
      'pincode',
      'pattern_lock',
      'grid_card',
      'security_tab'
    ];

    for (final key in priorityKeys) {
      if (isLockEnabled(key)) {
        final handler = _lockService.getHandler(key);
        debugPrint("SecurityManager: Triggering active security challenge for ${handler.name}");
        final bool result = await handler.authenticate(context, _repository, reason: reason);
        if (result) return true;
      }
    }

    // Fallback: If any other dynamic lock is enabled
    for (final handler in _lockService.registeredHandlers) {
      if (isLockEnabled(handler.key) && !priorityKeys.contains(handler.key)) {
        final bool result = await handler.authenticate(context, _repository, reason: reason);
        if (result) return true;
      }
    }

    return false;
  }

  /// App Resume lifecycle listener: Triggers active lock blocker screen to prevent background bypass
  Future<void> handleAppResume(BuildContext context, int userId) async {
    if (_isLockScreenShowing) return;

    // Check if any lock requires active authentication
    if (isAnyLockEnabled()) {
      _isLockScreenShowing = true;
      notifyListeners();

      debugPrint("SecurityManager: App resumed from background. Mounting lock blocker screen.");

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AppLockScreen(isStartupBlocker: true),
        ),
      );

      _isLockScreenShowing = false;
      notifyListeners();
    }
  }
}
