// lib/screens/create_post_screen.dart
import 'package:flutter/material.dart';
import '../services/community_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String? initialPostType;

  const CreatePostScreen({super.key, this.initialPostType});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _communityService = CommunityService();

  String _selectedPostType = 'discussion';
  final List<String> _tags = [];
  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _postTypes = {
    'discussion': {
      'label': '자유토론',
      'icon': Icons.chat_bubble_outline,
      'color': Colors.blue,
    },
    'question': {
      'label': '질문',
      'icon': Icons.help_outline,
      'color': Colors.purple,
    },
    'tip': {
      'label': '꿀팁',
      'icon': Icons.lightbulb_outline,
      'color': Colors.orange,
    },
    'success_story': {
      'label': '합격후기',
      'icon': Icons.celebration,
      'color': Colors.green,
    },
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialPostType != null) {
      _selectedPostType = widget.initialPostType!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 기본 게시판 ID 사용 (실제로는 동적으로 선택)
      const boardId = '550e8400-e29b-41d4-a716-446655440000';

      await _communityService.createPost(
        boardId: boardId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        postType: _selectedPostType,
        tags: _tags,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 작성되었습니다!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 작성 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('게시글 작성'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitPost,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('완료'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 게시글 유형 선택
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '게시글 유형',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _postTypes.entries.map((entry) {
                      final isSelected = _selectedPostType == entry.key;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedPostType = entry.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? entry.value['color'].withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? entry.value['color']
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                entry.value['icon'],
                                size: 16,
                                color: isSelected
                                    ? entry.value['color']
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.value['label'],
                                style: TextStyle(
                                  color: isSelected
                                      ? entry.value['color']
                                      : Colors.grey[600],
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 제목 입력
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  hintText: '제목을 입력하세요',
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '제목을 입력해주세요';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 16),

            // 내용 입력
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '내용',
                  hintText: '내용을 입력하세요',
                  border: InputBorder.none,
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '내용을 입력해주세요';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}