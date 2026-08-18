// lib/core/enums/broadcast_target.dart

/// Target audience for an admin emergency broadcast notification.
enum BroadcastTarget {
  /// All registered users (victims + volunteers).
  allUsers,

  /// Victims only.
  victimsOnly,

  /// Approved volunteers only.
  volunteersOnly,
}

/// Returns the human-readable label for each broadcast target.
extension BroadcastTargetExt on BroadcastTarget {
  String get label => switch (this) {
        BroadcastTarget.allUsers      => 'All Users',
        BroadcastTarget.victimsOnly   => 'Victims Only',
        BroadcastTarget.volunteersOnly => 'Volunteers Only',
      };
}