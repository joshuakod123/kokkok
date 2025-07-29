import 'package:flutter/material.dart';
import '../models/certification.dart';
import '../services/certification_api_service.dart';
import '../widgets/certification_list_tile.dart';
import 'certification_detail_screen.dart';

class CertificationBrowseScreen extends StatefulWidget {
  const CertificationBrowseScreen({super.key});

  @override
  State<CertificationBrowseScreen> createState() => _CertificationBrowseScreenState();
}

class _CertificationBrowseScreenState extends State<CertificationBrowseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _apiService = CertificationApiService();

  List<Certification> _allCertifications = [];
  List<Certification> _filteredCertifications = [];
  List<Certification> _searchResults = [];
  String _selectedCategory = '전체';
  bool _isLoading = true;
  bool _isSearching = false;

  // 카테고리 목록
  final List<Map<String, dynamic>> _categories = [
    {'name': '전체', 'icon': Icons.all_inclusive, 'color': Colors.grey},
    {'name': 'IT', 'icon': Icons.computer, 'color': Colors.blue},
    {'name': '공학', 'icon': Icons.engineering, 'color': Colors.orange},
    {'name': '경영', 'icon': Icons.business, 'color': Colors.green},
    {'name': '어학', 'icon': Icons.language, 'color': Colors.purple},
    {'name': '금융', 'icon': Icons.account_balance, 'color': Colors.teal},
    {'name': '건설', 'icon': Icons.construction, 'color': Colors.brown},
    {'name': '서비스', 'icon': Icons.room_service, 'color': Colors.pink},
  ];

  // 정렬 옵션
  String _sortBy = '이름순';
  final List<String> _sortOptions = ['이름순', '인기순', '합격률순', '최신순'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCertifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCertifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _allCertifications = await _apiService.getCertifications(numOfRows: 1000);
      _filterCertifications();
    } catch (e) {
      debugPrint('자격증 로드 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCertifications() {
    List<Certification> filtered = List.from(_allCertifications);

    // 카테고리 필터링
    if (_selectedCategory != '전체') {
      filtered = filtered.where((cert) =>
      cert.category?.toLowerCase() == _selectedCategory.toLowerCase() ||
          cert.seriesNm.contains(_selectedCategory)
      ).toList();
    }

    // 정렬
    switch (_sortBy) {
      case '이름순':
        filtered.sort((a, b) => a.jmNm.compareTo(b.jmNm));
        break;
      case '인기순':
        filtered.sort((a, b) => (b.applicants ?? 0).compareTo(a.applicants ?? 0));
        break;
      case '합격률순':
        filtered.sort((a, b) => (b.passingRate ?? 0).compareTo(a.passingRate ?? 0));
        break;
      case '최신순':
        filtered.sort((a, b) => b.implYy.compareTo(a.implYy));
        break;
    }

    setState(() {
      _filteredCertifications = filtered;
    });
  }

  Future<void> _searchCertifications(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _apiService.searchCertifications(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      debugPrint('검색 오류: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterCertifications();
  }

  void _onSortChanged(String? sortBy) {
    if (sortBy != null) {
      setState(() {
        _sortBy = sortBy;
      });
      _filterCertifications();
    }
  }

  void _navigateToCertificationDetail(Certification certification) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificationDetailScreen(
          certification: certification,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // 앱바
            SliverAppBar(
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              title: const Text(
                '자격증 탐색',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort, color: Colors.black87),
                  onSelected: _onSortChanged,
                  itemBuilder: (context) => _sortOptions.map((option) =>
                      PopupMenuItem(
                        value: option,
                        child: Row(
                          children: [
                            if (_sortBy == option)
                              Icon(Icons.check,
                                  color: Theme.of(context).primaryColor,
                                  size: 20),
                            if (_sortBy == option) const SizedBox(width: 8),
                            Text(option),
                          ],
                        ),
                      ),
                  ).toList(),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(160),
                child: Column(
                  children: [
                    // 검색바
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '자격증 이름을 검색해보세요',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchCertifications('');
                            },
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: _searchCertifications,
                      ),
                    ),

                    // 탭바
                    TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: Theme.of(context).primaryColor,
                      tabs: const [
                        Tab(text: '카테고리별'),
                        Tab(text: '검색결과'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // 카테고리별 탭
            _buildCategoryTab(),

            // 검색결과 탭
            _buildSearchTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab() {
    return Column(
      children: [
        // 카테고리 필터
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['name'];

                return GestureDetector(
                  onTap: () => _onCategorySelected(category['name']),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? category['color'].withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? category['color']
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category['icon'],
                          color: isSelected
                              ? category['color']
                              : Colors.grey[600],
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name'],
                          style: TextStyle(
                            color: isSelected
                                ? category['color']
                                : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 자격증 목록
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredCertifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
            onRefresh: _loadCertifications,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredCertifications.length,
              itemBuilder: (context, index) {
                final cert = _filteredCertifications[index];
                return CertificationListTile(
                  certification: cert,
                  onTap: () => _navigateToCertificationDetail(cert),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchTab() {
    if (_searchController.text.isEmpty) {
      return _buildSearchEmptyState();
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final cert = _searchResults[index];
        return CertificationListTile(
          certification: cert,
          onTap: () => _navigateToCertificationDetail(cert),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '해당 카테고리에\n자격증이 없습니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _onCategorySelected('전체'),
            child: const Text('전체 보기'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '자격증 이름을 입력해주세요',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '예: 정보처리기사, SQLD, 토익 등',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '검색 결과가 없습니다',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 키워드로 검색해보세요',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              _searchCertifications('');
            },
            child: const Text('검색어 지우기'),
          ),
        ],
      ),
    );
  }
}