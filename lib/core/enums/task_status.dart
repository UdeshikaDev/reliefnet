/// Lifecycle of a volunteer's delivery task.
///
/// - [reserved]              Task created. Parcels reserved via Firestore Transaction.
/// - [coordinatorConfirmed]  Main Coordinator confirmed collection at the center.
/// - [inTransit]             Volunteer collected parcels and is delivering.
/// - [delivered]             Victim QR scanned. Task closed. Receipt immutable.
/// - [cancelled]             Task cancelled (parcels automatically returned to available).
enum TaskStatus {
  reserved,
  coordinatorConfirmed,
  inTransit,
  delivered,
  cancelled,
}