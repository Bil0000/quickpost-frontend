class Post {
  final String? id;
  final String userId;
  final String caption;
  final String? imageUrl;
  final String username;
  final String profileImageUrl;
  final DateTime createdAt;
  int likeCount;
  int views;
  final int commentCount;
  bool isLikedByCurrentUser;

  Post({
    this.id,
    required this.userId,
    required this.caption,
    required this.imageUrl,
    required this.username,
    required this.profileImageUrl,
    required this.createdAt,
    required this.likeCount,
    required this.views,
    required this.commentCount,
    required this.isLikedByCurrentUser,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String?,
      userId: json['userId'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      username: json['username'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      createdAt: json['createdat'] != null
          ? DateTime.parse(json['createdat'] as String)
          : DateTime.now(),
      likeCount: json['likeCount'] as int? ?? 0,
      views: json['views'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] == true,
    );
  }
}
