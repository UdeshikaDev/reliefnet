/// Lifecycle of a single packed parcel inside a donation center.
///
/// - [available]   Packed and ready to be reserved for a request.
/// - [reserved]    Atomically reserved for a specific victim request via
///                 a Firestore Transaction. Cannot be taken by another volunteer.
/// - [inTransit]   Collected by the volunteer and currently en route to victim.
/// - [distributed] Handover confirmed. QR code was scanned. Receipt is immutable.
enum ParcelStatus { available, reserved, inTransit, distributed }