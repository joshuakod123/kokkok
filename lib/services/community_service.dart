// lib/services/community_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_models.dart';

class CommunityService {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  final _supabase = Supabase.instance.client;

  // ===== 게시판 관리 =====

  Future<List<CommunityBoard>> getCertificationBoards(String certificationId) async {
    try {
      final response = await _supabase
          .from('community_boards')
          .select('*')
          .eq('certification_id', certificationId)
          .order('created_at');

      return response.map<CommunityBoard>((data) => CommunityBoard.fromJson(data)).toList();
    } catch (e) {
      throw Exception('게시판 조회 실패: $e');
    }
  }

  Future<CommunityBoard> createBoard({
    required String certificationId,
    required String name,
    required String description,
    required String category,
  }) async {
    try {
      final response = await _supabase
          .from('community_boards')
          .insert({
        'certification_id': certificationId,
        'name': name,
        'description': description,
        'category': category,
      })
          .select()
          .single();

      return CommunityBoard.fromJson(response);
    } catch (e) {
      throw Exception('게시판 생성 실패: $e');
    }
  }

  // ===== 게시글 관리 =====

  Future<List<CommunityPost>> getPosts({
    required String boardId,
    int page = 1,
    int limit = 20,
    String orderBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      final offset = (page - 1) * limit;

      final response = await _supabase
          .from('community_posts')
          .select('''
            *,
            profiles:author_id(id, username, user_id),
            certifications:certification_id(id, jm_nm)
          ''')
          .eq('board_id', boardId)
          .order(orderBy, ascending: ascending)
          .range(offset, offset + limit - 1);

      return response.map<CommunityPost>((data) => CommunityPost.fromJson(data)).toList();
    } catch (e) {
      throw Exception('게시글 조회 실패: $e');
    }
  }

  Future<CommunityPost> createPost({
    required String boardId,
    required String title,
    required String content,
    required String postType,
    String? certificationId,
    List<String>? tags,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('로그인이 필요합니다');

      final response = await _supabase
          .from('community_posts')
          .insert({
        'board_id': boardId,
        'author_id': userId,
        'title': title,
        'content': content,
        'post_type': postType,
        'certification_id': certificationId,
        'tags': tags,
      })
          .select('''
            *,
            profiles:author_id(id, username, user_id),
            certifications:certification_id(id, jm_nm)
          ''')
          .single();

      // 사용자 통계 업데이트
      await _updateUserStats(userId, 'post_created');

      return CommunityPost.fromJson(response);
    } catch (e) {
      throw Exception('게시글 작성 실패: $e');
    }
  }

  Future<CommunityPost> getPost(String postId) async {
    try {
      // 조회수 증가
      await _supabase.rpc('increment_view_count', params: {'post_id': postId});

      final response = await _supabase
          .from('community_posts')
          .select('''
            *,
            profiles:author_id(id, username, user_id),
            certifications:certification_id(id, jm_nm)
          ''')
          .eq('id', postId)
          .single();

      return CommunityPost.fromJson(response);
    } catch (e) {
      throw Exception('게시글 조회 실패: $e');
    }
  }

  // ===== 댓글 시스템 =====

  Future<List<CommunityComment>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('community_comments')
          .select('''
            *,
            profiles:author_id(id, username, user_id)
          ''')
          .eq('post_id', postId)
          .isFilter('parent_id', null) // null 값 필터링 수정
          .order('created_at');

      final comments = response.map<CommunityComment>((data) => CommunityComment.fromJson(data)).toList();

      // 각 댓글의 대댓글 조회
      for (final comment in comments) {
        comment.replies = await _getReplies(comment.id);
      }

      return comments;
    } catch (e) {
      throw Exception('댓글 조회 실패: $e');
    }
  }

  Future<List<CommunityComment>> _getReplies(String parentId) async {
    try {
      final response = await _supabase
          .from('community_comments')
          .select('''
            *,
            profiles:author_id(id, username, user_id)
          ''')
          .eq('parent_id', parentId)
          .order('created_at');

      return response.map<CommunityComment>((data) => CommunityComment.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<CommunityComment> createComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('로그인이 필요합니다');

      final response = await _supabase
          .from('community_comments')
          .insert({
        'post_id': postId,
        'parent_id': parentId,
        'author_id': userId,
        'content': content,
      })
          .select('''
            *,
            profiles:author_id(id, username, user_id)
          ''')
          .single();

      // 댓글 수 업데이트
      await _supabase.rpc('increment_comment_count', params: {'post_id': postId});

      // 사용자 통계 업데이트
      await _updateUserStats(userId, 'comment_created');

      return CommunityComment.fromJson(response);
    } catch (e) {
      throw Exception('댓글 작성 실패: $e');
    }
  }

  // ===== 스터디 그룹 =====

  Future<List<StudyGroup>> getStudyGroups({
    String? certificationId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final offset = (page - 1) * limit;
      var query = _supabase
          .from('study_groups')
          .select('''
            *,
            profiles:leader_id(id, username, user_id),
            certifications:certification_id(id, jm_nm),
            study_group_members(count)
          ''');

      if (certificationId != null) {
        query = query.eq('certification_id', certificationId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<StudyGroup>((data) => StudyGroup.fromJson(data)).toList();
    } catch (e) {
      throw Exception('스터디 그룹 조회 실패: $e');
    }
  }

  Future<StudyGroup> createStudyGroup({
    required String certificationId,
    required String name,
    required String description,
    required int maxMembers,
    required DateTime targetDate,
    required String studyMethod,
    String? location,
    List<String>? tags,
    String? meetingSchedule,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('로그인이 필요합니다');

      final response = await _supabase
          .from('study_groups')
          .insert({
        'certification_id': certificationId,
        'leader_id': userId,
        'name': name,
        'description': description,
        'max_members': maxMembers,
        'target_date': targetDate.toIso8601String().split('T')[0],
        'study_method': studyMethod,
        'location': location,
        'tags': tags,
        'meeting_schedule': meetingSchedule,
      })
          .select('''
            *,
            profiles:leader_id(id, username, user_id),
            certifications:certification_id(id, jm_nm)
          ''')
          .single();

      // 그룹장을 멤버로 추가
      await _supabase.from('study_group_members').insert({
        'group_id': response['id'],
        'user_id': userId,
        'role': 'leader',
      });

      return StudyGroup.fromJson(response);
    } catch (e) {
      throw Exception('스터디 그룹 생성 실패: $e');
    }
  }

  Future<bool> joinStudyGroup(String groupId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('로그인이 필요합니다');

      // 이미 참여했는지 확인
      final existing = await _supabase
          .from('study_group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('이미 참여한 스터디 그룹입니다');
      }

      // 그룹 정보 조회 (정원 확인)
      final group = await _supabase
          .from('study_groups')
          .select('max_members, current_members')
          .eq('id', groupId)
          .single();

      if (group['current_members'] >= group['max_members']) {
        throw Exception('스터디 그룹이 가득 찼습니다');
      }

      // 멤버 추가
      await _supabase.from('study_group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
      });

      // 현재 멤버 수 업데이트
      await _supabase.rpc('increment_group_members', params: {'group_id': groupId});

      // 활동 로그 추가
      await _supabase.from('study_activities').insert({
        'group_id': groupId,
        'user_id': userId,
        'activity_type': 'join',
        'content': '스터디 그룹에 참여했습니다',
        'points': 10,
      });

      return true;
    } catch (e) {
      throw Exception('스터디 그룹 참여 실패: $e');
    }
  }

  // ===== 투표 시스템 =====

  Future<bool> votePost(String postId, String voteType) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('로그인이 필요합니다');

      // 기존 투표 확인
      final existingVote = await _supabase
          .from('community_votes')
          .select('vote_type')
          .eq('user_id', userId)
          .eq('target_type', 'post')
          .eq('target_id', postId)
          .maybeSingle();

      if (existingVote != null) {
        if (existingVote['vote_type'] == voteType) {
          // 같은 투표면 취소
          await _supabase
              .from('community_votes')
              .delete()
              .eq('user_id', userId)
              .eq('target_type', 'post')
              .eq('target_id', postId);

          await _supabase.rpc('decrement_vote_count', params: {
            'post_id': postId,
            'vote_type': voteType,
          });
        } else {
          // 다른 투표면 변경
          await _supabase
              .from('community_votes')
              .update({'vote_type': voteType})
              .eq('user_id', userId)
              .eq('target_type', 'post')
              .eq('target_id', postId);

          await _supabase.rpc('change_vote_count', params: {
            'post_id': postId,
            'old_vote': existingVote['vote_type'],
            'new_vote': voteType,
          });
        }
      } else {
        // 새 투표
        await _supabase.from('community_votes').insert({
          'user_id': userId,
          'target_type': 'post',
          'target_id': postId,
          'vote_type': voteType,
        });

        await _supabase.rpc('increment_vote_count', params: {
          'post_id': postId,
          'vote_type': voteType,
        });
      }

      return true;
    } catch (e) {
      throw Exception('투표 실패: $e');
    }
  }

  // ===== 검색 기능 =====

  Future<List<CommunityPost>> searchPosts({
    required String query,
    String? certificationId,
    String? postType,
    List<String>? tags,
  }) async {
    try {
      var supabaseQuery = _supabase
          .from('community_posts')
          .select('''
            *,
            profiles:author_id(id, username, user_id),
            certifications:certification_id(id, jm_nm)
          ''');

      // 제목과 내용에서 검색
      supabaseQuery = supabaseQuery.or('title.ilike.%$query%,content.ilike.%$query%');

      if (certificationId != null) {
        supabaseQuery = supabaseQuery.eq('certification_id', certificationId);
      }

      if (postType != null) {
        supabaseQuery = supabaseQuery.eq('post_type', postType);
      }

      if (tags != null && tags.isNotEmpty) {
        supabaseQuery = supabaseQuery.overlaps('tags', tags);
      }

      final response = await supabaseQuery
          .order('created_at', ascending: false)
          .limit(50);

      return response.map<CommunityPost>((data) => CommunityPost.fromJson(data)).toList();
    } catch (e) {
      throw Exception('검색 실패: $e');
    }
  }

  // ===== 사용자 통계 업데이트 =====

  Future<void> _updateUserStats(String userId, String action) async {
    try {
      await _supabase.rpc('update_user_community_stats', params: {
        'user_id': userId,
        'action': action,
      });
    } catch (e) {
      // 통계 업데이트 실패는 조용히 처리
    }
  }

  // ===== 트렌딩 및 인기 콘텐츠 =====

  Future<List<CommunityPost>> getTrendingPosts({
    int days = 7,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase.rpc('get_trending_posts', params: {
        'days_back': days,
        'result_limit': limit,
      });

      return response.map<CommunityPost>((data) => CommunityPost.fromJson(data)).toList();
    } catch (e) {
      throw Exception('트렌딩 게시글 조회 실패: $e');
    }
  }

  Future<List<CommunityPost>> getSuccessStories({
    String? certificationId,
    int limit = 20,
  }) async {
    try {
      var query = _supabase
          .from('community_posts')
          .select('''
            *,
            profiles:author_id(id, username, user_id),
            certifications:certification_id(id, jm_nm)
          ''')
          .eq('post_type', 'success_story');

      if (certificationId != null) {
        query = query.eq('certification_id', certificationId);
      }

      final response = await query
          .order('upvotes', ascending: false)
          .limit(limit);

      return response.map<CommunityPost>((data) => CommunityPost.fromJson(data)).toList();
    } catch (e) {
      throw Exception('합격 후기 조회 실패: $e');
    }
  }
}