/// Gender options collected at victim registration.
///
/// Modeled as an enum rather than a free-text field, consistent with how
/// [UserRole] and other fixed-choice fields are represented elsewhere in
/// this codebase.
enum Gender { male, female, other }
