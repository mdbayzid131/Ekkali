/// An absent or unrecognised status must never reactivate an account.
class AccountStatus {
  static bool? restrictionFrom(Map<dynamic, dynamic> payload) {
    bool? flag(dynamic value) {
      if (value == true || value == 'true') return true;
      if (value == false || value == 'false') return false;
      return null;
    }

    final restricted = flag(payload['isRestricted']);
    final suspended = flag(payload['isSuspended']);
    final states = [
      payload['status'],
      payload['accountState'],
    ].map((value) => value?.toString().trim().toUpperCase());
    if (restricted == true ||
        suspended == true ||
        states.contains('SUSPENDED')) {
      return true;
    }
    if (restricted == false ||
        suspended == false ||
        states.any(
          (state) => const ['VERIFIED', 'ACTIVE', 'APPROVED'].contains(state),
        )) {
      return false;
    }
    return null;
  }

  static bool isSuspensionError(dynamic data) {
    if (data is! Map) return false;
    if (restrictionFrom(data) == true) return true;
    final message = data['message']?.toString().toLowerCase() ?? '';
    return message.contains('account') &&
        (message.contains('suspend') || message.contains('restrict'));
  }
}
