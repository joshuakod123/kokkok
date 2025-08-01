// lib/models/community_models.dart
import 'package:flutter/material.dart';

class CommunityBoard {
  final String id;
  final String? certificationId;
  final String name;
  final String description;
  final String category;
  final int memberCount;
  final int postCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunityBoard({
    required this.id,
    this.certificationId,
    required this.name,
    required this.description,
    required this.category,
    required this.memberCount,
    required this.postCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityBoard.fromJson(Map<String, dynamic> json) {
    return CommunityBoard(
      id: json['id'],
      certificationId: json['certification_id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      memberCount: json['member_count'] ?? 0,
      postCount: json['post_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  IconData get categoryIcon {
    switch (category) {
      case 'discussion':
        return Icons.forum;
      case 'tips':
        return Icons.lightbulb;
      case 'success_stories':
        return Icons.celebration;
      case 'questions':
        return Icons.help;
      default:
        return Icons.chat;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'discussion':
        return Colors.blue;
      case 'tips':
        return Colors.orange;
      case 'success_stories':
        return Colors.green;
      case 'questions':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class CommunityPost {
  final String id;
  final String boardId;
  final String authorId;
  final String title;
  final String content;
  final String postType;
  final String? certificationId;
  final List<String> tags;
  final int upvotes;
  final int downvotes;
  final int viewCount;
  final int commentCount;
  final bool isPinned;
  final bool isSolved;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 관계 데이터
  final UserProfile? author;
  final String? certificationName;
  final List<CommunityComment> comments;

  const CommunityPost({
    required this.id,
    required this.boardId,
    required this.authorId,
    required this.title,
    required this.content,
    required this.postType,
    this.certificationId,
    required this.tags,
    required this.upvotes,
    required this.downvotes,
    required this.viewCount,
    required this.commentCount,
    required this.isPinned,
    required this.isSolved,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.certificationName,
    this.comments = const [],
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'],
      boardId: json['board_id'],
      authorId: json['author_id'],
      title: json['title'],
      content: json['content'],
      postType: json['post_type'],
      certificationId: json['certification_id'],
      tags: List<String>.from(json['tags'] ?? []),
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      isPinned: json['is_pinned'] ?? false,
      isSolved: json['is_solved'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      author: json['profiles'] != null ? UserProfile.fromJson(json['profiles']) : null,
      certificationName: json['certifications']?['jm_nm'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_id': boardId,
      'author_id': authorId,
      'title': title,
      'content': content,
      'post_type': postType,
      'certification_id': certificationId,
      'tags': tags,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'view_count': viewCount,
      'comment_count': commentCount,
      'is_pinned': isPinned,
      'is_solved': isSolved,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  IconData get postTypeIcon {
    switch (postType) {
      case 'discussion':
        return Icons.chat_bubble_outline;
      case 'tip':
        return Icons.lightbulb_outline;
      case 'success_story':
        return Icons.celebration_outlined;
      case 'question':
        return Icons.help_outline;
      case 'study_recruit':
        return Icons.group_add;
      default:
        return Icons.article_outlined;
    }
  }

  Color get postTypeColor {
    switch (postType) {
      case 'discussion':
        return Colors.blue;
      case 'tip':
        return Colors.orange;
      case 'success_story':
        return Colors.green;
      case 'question':
        return Colors.purple;
      case 'study_recruit':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String get postTypeLabel {
    switch (postType) {
      case 'discussion':
        return '자유토론';
      case 'tip':
        return '꿀팁';
      case 'success_story':
        return '합격후기';
      case 'question':
        return '질문';
      case 'study_recruit':
        return '스터디모집';
      default:
        return '게시글';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.month}/${createdAt.day}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  int get totalVotes => upvotes - downvotes;
}

class CommunityComment {
  final String id;
  final String postId;
  final String? parentId;
  final String authorId;
  final String content;
  final int upvotes;
  final bool isAuthorReply;
  final bool isBestAnswer;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 관계 데이터
  final UserProfile? author;
  List<CommunityComment> replies;

  CommunityComment({
    required this.id,
    required this.postId,
    this.parentId,
    required this.authorId,
    required this.content,
    required this.upvotes,
    required this.isAuthorReply,
    required this.isBestAnswer,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.replies = const [],
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'],
      postId: json['post_id'],
      parentId: json['parent_id'],
      authorId: json['author_id'],
      content: json['content'],
      upvotes: json['upvotes'] ?? 0,
      isAuthorReply: json['is_author_reply'] ?? false,
      isBestAnswer: json['is_best_answer'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      author: json['profiles'] != null ? UserProfile.fromJson(json['profiles']) : null,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.month}/${createdAt.day}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  bool get isReply => parentId != null;
}

class StudyGroup {
  final String id;
  final String certificationId;
  final String leaderId;
  final String name;
  final String description;
  final int maxMembers;
  final int currentMembers;
  final DateTime? targetDate;
  final String studyMethod;
  final String? location;
  final String status;
  final List<String> tags;
  final String? meetingSchedule;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 관계 데이터
  final UserProfile? leader;
  final String? certificationName;
  final List<StudyGroupMember> members;

  const StudyGroup({
    required this.id,
    required this.certificationId,
    required this.leaderId,
    required this.name,
    required this.description,
    required this.maxMembers,
    required this.currentMembers,
    this.targetDate,
    required this.studyMethod,
    this.location,
    required this.status,
    required this.tags,
    this.meetingSchedule,
    required this.createdAt,
    required this.updatedAt,
    this.leader,
    this.certificationName,
    this.members = const [],
  });

  factory StudyGroup.fromJson(Map<String, dynamic> json) {
    return StudyGroup(
      id: json['id'],
      certificationId: json['certification_id'],
      leaderId: json['leader_id'],
      name: json['name'],
      description: json['description'],
      maxMembers: json['max_members'],
      currentMembers: json['current_members'],
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date']) : null,
      studyMethod: json['study_method'],
      location: json['location'],
      status: json['status'],
      tags: List<String>.from(json['tags'] ?? []),
      meetingSchedule: json['meeting_schedule'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      leader: json['profiles'] != null ? UserProfile.fromJson(json['profiles']) : null,
      certificationName: json['certifications']?['jm_nm'],
    );
  }

  IconData get studyMethodIcon {
    switch (studyMethod) {
      case 'online':
        return Icons.computer;
      case 'offline':
        return Icons.location_on;
      case 'hybrid':
        return Icons.sync_alt;
      default:
        return Icons.group;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'recruiting':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'recruiting':
        return '모집중';
      case 'active':
        return '진행중';
      case 'completed':
        return '완료';
      default:
        return '대기중';
    }
  }

  bool get isRecruiting => status == 'recruiting' && currentMembers < maxMembers;

  int? get daysUntilTarget {
    if (targetDate == null) return null;
    final now = DateTime.now();
    final target = DateTime(targetDate!.year, targetDate!.month, targetDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    return target.difference(today).inDays;
  }
}

class StudyGroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final double progressRate;
  final DateTime lastActivity;

  // 관계 데이터
  final UserProfile? user;

  const StudyGroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.progressRate,
    required this.lastActivity,
    this.user,
  });

  factory StudyGroupMember.fromJson(Map<String, dynamic> json) {
    return StudyGroupMember(
      id: json['id'],
      groupId: json['group_id'],
      userId: json['user_id'],
      role: json['role'],
      joinedAt: DateTime.parse(json['joined_at']),
      progressRate: (json['progress_rate'] ?? 0.0).toDouble(),
      lastActivity: DateTime.parse(json['last_activity']),
      user: json['profiles'] != null ? UserProfile.fromJson(json['profiles']) : null,
    );
  }

  bool get isLeader => role == 'leader';
  bool get isActive => DateTime.now().difference(lastActivity).inDays <= 3;
}

class UserProfile {
  final String id;
  final String username;
  final String userId;

  const UserProfile({
    required this.id,
    required this.username,
    required this.userId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'] ?? '익명',
      userId: json['user_id'] ?? '',
    );
  }
}

class UserCommunityStats {
  final String userId;
  final int totalPosts;
  final int totalComments;
  final int totalUpvotesReceived;
  final int totalBestAnswers;
  final int communityLevel;
  final int communityPoints;
  final List<String> badges;

  const UserCommunityStats({
    required this.userId,
    required this.totalPosts,
    required this.totalComments,
    required this.totalUpvotesReceived,
    required this.totalBestAnswers,
    required this.communityLevel,
    required this.communityPoints,
    required this.badges,
  });

  factory UserCommunityStats.fromJson(Map<String, dynamic> json) {
    return UserCommunityStats(
      userId: json['user_id'],
      totalPosts: json['total_posts'] ?? 0,
      totalComments: json['total_comments'] ?? 0,
      totalUpvotesReceived: json['total_upvotes_received'] ?? 0,
      totalBestAnswers: json['total_best_answers'] ?? 0,
      communityLevel: json['community_level'] ?? 1,
      communityPoints: json['community_points'] ?? 0,
      badges: List<String>.from(json['badges'] ?? []),
    );
  }

  String get levelTitle {
    if (communityLevel >= 10) return '마스터';
    if (communityLevel >= 7) return '전문가';
    if (communityLevel >= 5) return '숙련자';
    if (communityLevel >= 3) return '활발한 멤버';
    return '새싹';
  }

  Color get levelColor {
    if (communityLevel >= 10) return Colors.purple;
    if (communityLevel >= 7) return Colors.orange;
    if (communityLevel >= 5) return Colors.blue;
    if (communityLevel >= 3) return Colors.green;
    return Colors.grey;
  }
}