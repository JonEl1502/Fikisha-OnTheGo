/// A person on the platform. One account acts as sender or traveler at any
/// time — there is no separate registration per role (PRD §2).
class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    required this.ratingsCount,
    this.verified = false,
    this.deliveredCount = 0,
    this.sentCount = 0,
    this.kesEarned = 0,
    this.joined = 'Mar 2026',
    this.photoUrl,
  });

  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  double rating;
  int ratingsCount;
  final bool verified;
  int deliveredCount;
  int sentCount;
  int kesEarned;
  final String joined;

  String get initial => name.isEmpty ? '?' : name[0];
}
