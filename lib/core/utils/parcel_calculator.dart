/// Returns the number of packed parcels a victim family is entitled to.
///
/// Formula: `ceil(familySize / 3)`
///
/// | Family Size | Parcels |
/// |---|---|
/// | 1 | 1 |
/// | 2 | 1 |
/// | 3 | 1 |
/// | 4 | 2 |
/// | 6 | 2 |
/// | 7 | 3 |
/// | 9 | 3 |
/// | 10 | 4 |
int calculateParcels(int familySize) {
  assert(familySize >= 1, 'familySize must be at least 1');
  return (familySize / 3).ceil();
}