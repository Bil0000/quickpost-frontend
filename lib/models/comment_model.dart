class Comment {
  final String? id;
  final String postId;
  final String userId;
  String text;
  final String? commentImageUrl;
  final String? parentCommentId;
  final bool isReply;
  final DateTime createdAt;
  final List<Comment> replies;

  Comment({
    this.id,
    required this.postId,
    required this.userId,
    required this.text,
    required this.commentImageUrl,
    required this.parentCommentId,
    required this.isReply,
    required this.replies,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String?,
      postId: json['postId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      commentImageUrl: json['commentImageUrl'] as String?,
      parentCommentId: json['parentCommentId'] as String?,
      isReply: json['isReply'] as bool,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map((replyJson) => Comment.fromJson(replyJson))
          .toList(), // Parse nested replies
    );
  }
}
