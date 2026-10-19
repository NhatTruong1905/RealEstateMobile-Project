part of '../PropertyList.dart';

extension PropertyListView on _PropertyListScreenState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _showScrollToTop ? 1.0 : 0.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          scale: _showScrollToTop ? 1.0 : 0.0,
          child: GestureDetector(
            onTap: _showScrollToTop ? _scrollToTop : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFBFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1A1918),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.pageTitle,
          style: const TextStyle(
            color: Color(0xFF1A1918),
            fontFamily: 'Georgia',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF945331),
          onRefresh: _refreshData,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.only(left: 14, right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4EEE6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (_) => _triggerSearch(),
                                textInputAction: TextInputAction.search,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Tìm kiếm bất động sản...',
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintStyle: TextStyle(
                                    color: Color(0xFF78736D),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  size: 18,
                                  color: Color(0xFF78736D),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _triggerSearch();
                                },
                              ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _triggerSearch,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF945331),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _showFilterBottomSheet,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4EEE6),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE8E3DC)),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF945331),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildTypeChip('Tất cả', null),
                    const SizedBox(width: 8),
                    _buildTypeChip('Mua Bán', 1),
                    const SizedBox(width: 8),
                    _buildTypeChip('Cho Thuê', 2),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTypeId == 1
                          ? 'Bất động sản Cho Bán'
                          : _selectedTypeId == 2
                          ? 'Bất động sản Cho Thuê'
                          : 'Tất cả Bất động sản',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1918),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    Text(
                      '$_totalItems kết quả',
                      style: const TextStyle(
                        color: Color(0xFF78736D),
                        fontSize: 13,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF945331),
                        ),
                      )
                    : _properties.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Text(
                              'Không tìm thấy bất động sản phù hợp',
                              style: TextStyle(
                                color: Color(0xFF78736D),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _properties.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _properties.length) {
                            if (_isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF945331),
                                  ),
                                ),
                              );
                            }
                            if (!_hasMore && _properties.isNotEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'Đã hiển thị tất cả bất động sản',
                                    style: TextStyle(
                                      color: Color(0xFF78736D),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          final property = _properties[index];
                          return _buildVerticalCard(property);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
