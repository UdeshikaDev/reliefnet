/// The four roles in ReliefNet.
///
/// - [public]    No account. Can view the map and find donation centers.
/// - [victim]    Registered with phone OTP + NIC. Can submit one active request,
///               track delivery, and confirm receipt via QR.
/// - [volunteer] Registered with phone OTP + admin approval. Can register centers,
///               log stock, accept delivery tasks, and scan handover QR codes.
/// - [admin]     Pre-provisioned. Can approve volunteers, edit the parcel blueprint,
///               review flagged photos, and send broadcast notifications.
enum UserRole { public, victim, volunteer, admin }