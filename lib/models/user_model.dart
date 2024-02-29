class UserModel {
  final String id;
  final String fullname;
  final String bio;
  final String email;
  final String username;
  final String profileImageUrl;
  final String bannerImageUrl;
  int followerCount;
  final int followingCount;

  UserModel({
    required this.id,
    required this.fullname,
    required this.bio,
    required this.email,
    required this.username,
    required this.profileImageUrl,
    required this.bannerImageUrl,
    required this.followerCount,
    required this.followingCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullname: json['fullname'],
      bio: json['bio'],
      email: json['email'],
      username: json['username'],
      profileImageUrl: json['profileImageUrl'],
      bannerImageUrl: json['bannerImageUrl'],
      followerCount: json['followerCount'],
      followingCount: json['followingCount'],
    );
  }
}
