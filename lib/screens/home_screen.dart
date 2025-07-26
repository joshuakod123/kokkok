import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = "사용자";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // 먼저 메타데이터에서 username 확인
        String? name = user.userMetadata?['username'];

        // 메타데이터에 없으면 profiles 테이블에서 가져오기
        if (name == null || name.isEmpty) {
          final profileData = await supabase
              .from('profiles')
              .select('username')
              .eq('id', user.id)
              .maybeSingle();

          if (profileData != null) {
            name = profileData['username'];
          }
        }

        if (name != null && name.isNotEmpty) {
          setState(() {
            username = name!;
          });
        }
      }
    } catch (error) {
      debugPrint('Error loading user info: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('콕콕', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 환영 메시지 (실제 사용자 이름 사용)
              Text(
                '$username님,\n오늘은 어떤 성장을 꿈꾸시나요?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // 2. 나의 다음 목표 (D-Day)
              _buildSectionTitle(context, '나의 다음 목표'),
              _buildDdayCard(context, '정보처리기사 필기', 28),
              const SizedBox(height: 24),

              // 3. 콕콕! 맞춤 추천
              _buildSectionTitle(context, '콕콕! 맞춤 추천'),
              _buildRecommendationCard(context, '경영학과 전공자를 위한 추천', '사회조사분석사 2급'),
              const SizedBox(height: 24),

              // 4. 커뮤니티 인기글
              _buildSectionTitle(context, '커뮤니티 인기글 🔥'),
              _buildHotTopicCard(context, '정보처리기사 2주 합격 후기', 'by 합격요정'),
            ],
          ),
        ),
      ),
    );
  }

  // 섹션 제목을 만드는 위젯
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  // D-Day 카드 위젯
  Widget _buildDdayCard(BuildContext context, String title, int dDay) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text('D-$dDay', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor)),
          ],
        ),
      ),
    );
  }

  // 추천 카드 위젯
  Widget _buildRecommendationCard(BuildContext context, String reason, String certName) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(reason, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        subtitle: Text(certName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }

  // 인기글 카드 위젯
  Widget _buildHotTopicCard(BuildContext context, String title, String author) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(title),
        subtitle: Text(author, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}