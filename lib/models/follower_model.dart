class FollowerModel {
  final String id;
  final String username;
  final String fullname;
  final String? profileImageUrl;

  FollowerModel({
    required this.id,
    required this.username,
    required this.fullname,
    this.profileImageUrl,
  });

  factory FollowerModel.fromJson(Map<String, dynamic> json) {
    return FollowerModel(
      id: json['id'],
      username: json['username'],
      fullname: json['fullname'],
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
