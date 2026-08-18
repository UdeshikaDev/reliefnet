/// Lifecycle of a victim's relief request (10-step flow).
///
/// - [pending]    Submitted. Awaiting volunteer acceptance.
/// - [accepted]   Volunteer has accepted the task and reserved parcels.
/// - [collecting] Volunteer is at the center collecting the parcels.
/// - [delivering] Volunteer is on the way to the victim's location.
/// - [completed]  QR code scanned. Handover receipt finalized. Immutable.
/// - [expired]    72 hours passed without a volunteer accepting. Auto-expired
///                by the `requestExpiry` Cloud Function.
/// - [cancelled]  Victim cancelled the request (only allowed while [pending]).
enum RequestStatus {
  pending,
  accepted,
  collecting,
  delivering,
  completed,
  expired,
  cancelled,
}