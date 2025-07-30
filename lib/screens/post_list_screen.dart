import 'package:flutter/material.dart';
import '../models/certification.dart';
// ... (향후 추가될 Post 모델 및 API 서비스 import)

class PostListScreen extends StatefulWidget {
  final Certification certification;
  const PostListScreen({super.key, required this.certification});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  // TODO: Supabase에서 게시글 목록을 불러오는 로직 구현 필요
  // final _posts = await supabase.from('community_posts').select()...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.certification.jmNm} 커뮤니티'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('게시글 목록이 여기에 표시됩니다.'),
            Text('(현재 개발 중...)', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: 게시글 작성 화면으로 이동하는 로직 구현
        },
        label: const Text('글쓰기'),
        icon: const Icon(Icons.edit),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
