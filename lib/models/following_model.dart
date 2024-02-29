class FollowingModel {
  final String id;
  final String username;
  final String fullname;
  final String? profileImageUrl;

  FollowingModel({
    required this.id,
    required this.username,
    required this.fullname,
    this.profileImageUrl,
  });

  factory FollowingModel.fromJson(Map<String, dynamic> json) {
    return FollowingModel(
      id: json['id'],
      username: json['username'],
      fullname: json['fullname'],
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
