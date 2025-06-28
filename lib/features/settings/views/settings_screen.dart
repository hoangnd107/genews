import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:genews/features/settings/providers/settings_provider.dart';
import 'package:genews/app/themes/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isFontSizeExpanded = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(isDarkMode),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Tùy chọn ứng dụng', isDarkMode),
                    const SizedBox(height: 12),
                    _buildSettingsCard([
                      _buildThemeToggle(themeProvider, isDarkMode),
                      const Divider(height: 1),
                      _buildFontSizeSetting(
                        context,
                        fontSizeProvider,
                        isDarkMode,
                      ),
                      if (_isFontSizeExpanded) ...[
                        const Divider(height: 1),
                        _buildFontSizeOptions(fontSizeProvider, isDarkMode),
                      ],
                    ], isDarkMode),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Thông tin', isDarkMode),
                    const SizedBox(height: 12),
                    _buildSettingsCard([
                      _buildAboutTile(isDarkMode),
                      const Divider(height: 1),
                      _buildVersionTile(isDarkMode),
                    ], isDarkMode),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Hỗ trợ', isDarkMode),
                    const SizedBox(height: 12),
                    _buildSettingsCard([
                      _buildFeedbackTile(isDarkMode),
                      const Divider(height: 1),
                      _buildContactTile(isDarkMode),
                    ], isDarkMode),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDarkMode) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFF37474F),
      automaticallyImplyLeading: false,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {},
          tooltip: 'Thông báo',
        ),
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () => _showContactBottomSheet(context, isDarkMode),
          tooltip: 'Trợ giúp',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Cài đặt',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF37474F),
                Color(0xFF455A64),
                Color(0xFF546E7A),
                Color(0xFF607D8B),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildThemeToggle(ThemeProvider themeProvider, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: isDarkMode ? Colors.white : Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chế độ tối',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  themeProvider.isDarkMode ? 'Đang bật' : 'Đang tắt',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: (bool value) {
              themeProvider.setThemeMode(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
            activeColor: AppColors.primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSetting(
    BuildContext context,
    FontSizeProvider fontSizeProvider,
    bool isDarkMode,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _isFontSizeExpanded = !_isFontSizeExpanded;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.format_size,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cỡ chữ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fontSizeProvider.selectedFontSizeText,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                fontSizeProvider.selectedFontSizeText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: _isFontSizeExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeOptions(
    FontSizeProvider fontSizeProvider,
    bool isDarkMode,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        child: Column(
          children:
              AppFontSize.values.map((size) {
                final isSelected = fontSizeProvider.selectedFontSize == size;
                return InkWell(
                  onTap: () {
                    fontSizeProvider.setFontSize(size);
                    setState(() {
                      _isFontSizeExpanded = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                      border:
                          isSelected
                              ? Border.all(
                                color: AppColors.primaryColor.withOpacity(0.3),
                                width: 1,
                              )
                              : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primaryColor.withOpacity(0.2)
                                    : (isDarkMode
                                        ? Colors.grey[700]
                                        : Colors.grey.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.text_fields,
                            color:
                                isSelected
                                    ? AppColors.primaryColor
                                    : (isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600]),
                            size: _getIconSize(size),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getFontSizeText(size),
                                style: TextStyle(
                                  fontSize: _getPreviewFontSize(size),
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                  color:
                                      isSelected
                                          ? AppColors.primaryColor
                                          : (isDarkMode
                                              ? Colors.white
                                              : Colors.black87),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kích thước: ${_getPreviewFontSize(size).toInt()}px',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primaryColor.withOpacity(0.2)
                                    : (isDarkMode
                                        ? Colors.grey[700]
                                        : Colors.grey.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Aa',
                            style: TextStyle(
                              fontSize: _getPreviewFontSize(size),
                              fontWeight: FontWeight.w500,
                              color:
                                  isSelected
                                      ? AppColors.primaryColor
                                      : (isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          )
                        else
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    isDarkMode
                                        ? Colors.grey[600]!
                                        : Colors.grey[400]!,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildAboutTile(bool isDarkMode) {
    return InkWell(
      onTap: () => _showAboutBottomSheet(context, isDarkMode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Về ứng dụng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Thông tin chi tiết về GeNews',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionTile(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phiên bản',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Mới nhất',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTile(bool isDarkMode) {
    return InkWell(
      onTap: () => _showFeedbackBottomSheet(context, isDarkMode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.feedback_outlined,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gửi phản hồi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chia sẻ ý kiến của bạn với chúng tôi',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(bool isDarkMode) {
    return InkWell(
      onTap: () => _showContactBottomSheet(context, isDarkMode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.teal,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Liên hệ hỗ trợ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Nhận trợ giúp từ đội ngũ hỗ trợ',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  // Feedback bottom sheet method
  void _showFeedbackBottomSheet(BuildContext context, bool isDarkMode) {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    String selectedFeedbackType = 'Góp ý chung';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              isDarkMode ? Colors.grey[600] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.amber, Color(0xFFFF8F00)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.feedback_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gửi phản hồi',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Chia sẻ ý kiến của bạn với chúng tôi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.close,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Feedback Type Selection
                              _buildInfoCard(
                                isDarkMode: isDarkMode,
                                title: 'Loại phản hồi',
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        _buildFeedbackTypeOption(
                                          '💡',
                                          'Góp ý chung',
                                          'Chia sẻ ý kiến về ứng dụng',
                                          selectedFeedbackType == 'Góp ý chung',
                                          isDarkMode,
                                          () => setModalState(
                                            () =>
                                                selectedFeedbackType =
                                                    'Góp ý chung',
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildFeedbackTypeOption(
                                          '🐛',
                                          'Báo lỗi',
                                          'Thông báo về lỗi trong ứng dụng',
                                          selectedFeedbackType == 'Báo lỗi',
                                          isDarkMode,
                                          () => setModalState(
                                            () =>
                                                selectedFeedbackType =
                                                    'Báo lỗi',
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildFeedbackTypeOption(
                                          '⭐',
                                          'Đánh giá',
                                          'Đánh giá trải nghiệm sử dụng',
                                          selectedFeedbackType == 'Đánh giá',
                                          isDarkMode,
                                          () => setModalState(
                                            () =>
                                                selectedFeedbackType =
                                                    'Đánh giá',
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildFeedbackTypeOption(
                                          '🔧',
                                          'Yêu cầu tính năng',
                                          'Đề xuất tính năng mới',
                                          selectedFeedbackType ==
                                              'Yêu cầu tính năng',
                                          isDarkMode,
                                          () => setModalState(
                                            () =>
                                                selectedFeedbackType =
                                                    'Yêu cầu tính năng',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Subject Input
                              _buildInfoCard(
                                isDarkMode: isDarkMode,
                                title: 'Tiêu đề',
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    child: TextField(
                                      controller: subjectController,
                                      style: TextStyle(
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Nhập tiêu đề phản hồi...',
                                        hintStyle: TextStyle(
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[600]!
                                                    : Colors.grey[300]!,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[600]!
                                                    : Colors.grey[300]!,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.amber,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor:
                                            isDarkMode
                                                ? Colors.grey[800]
                                                : Colors.grey[50],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Message Input
                              _buildInfoCard(
                                isDarkMode: isDarkMode,
                                title: 'Nội dung phản hồi',
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    child: TextField(
                                      controller: messageController,
                                      maxLines: 6,
                                      style: TextStyle(
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Mô tả chi tiết phản hồi của bạn...\n\nVí dụ:\n- Vấn đề gặp phải\n- Đề xuất cải thiện\n- Trải nghiệm sử dụng',
                                        hintStyle: TextStyle(
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[600]!
                                                    : Colors.grey[300]!,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[600]!
                                                    : Colors.grey[300]!,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.amber,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor:
                                            isDarkMode
                                                ? Colors.grey[800]
                                                : Colors.grey[50],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Send Button
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _sendFeedbackEmail(
                                      selectedFeedbackType,
                                      subjectController.text,
                                      messageController.text,
                                      context,
                                    );
                                  },
                                  icon: const Icon(Icons.send, size: 20),
                                  label: const Text(
                                    'Gửi phản hồi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Info Note
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Phản hồi của bạn sẽ được gửi trực tiếp đến email hỗ trợ. Chúng tôi sẽ phản hồi trong vòng 24-48 giờ.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              isDarkMode
                                                  ? Colors.blue[300]
                                                  : Colors.blue[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  // Contact bottom sheet method
  void _showContactBottomSheet(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.65,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.teal, Color(0xFF00ACC1)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.support_agent,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hỗ trợ khách hàng',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'Chúng tôi luôn sẵn sàng hỗ trợ bạn',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Contact Methods Card
                        _buildInfoCard(
                          isDarkMode: isDarkMode,
                          title: 'Liên hệ trực tiếp',
                          children: [
                            const Divider(height: 1),
                            _buildContactMethodItem(
                              Icons.email,
                              'Email hỗ trợ',
                              'nduyhoang107@gmail.com',
                              'Phản hồi trong vòng 24 giờ',
                              Colors.blue,
                              isDarkMode,
                              onTap: () {
                                // Handle email
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // About bottom sheet method
  void _showAboutBottomSheet(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF37474F), Color(0xFF607D8B)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GeNews',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'Ứng dụng tổng hợp tin tức thông minh',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App Info Card
                        _buildInfoCard(
                          isDarkMode: isDarkMode,
                          title: 'Thông tin ứng dụng',
                          children: [
                            _buildInfoRow('Phiên bản', 'v1.0.0', isDarkMode),
                            _buildInfoRow(
                              'Nhà phát triển',
                              'Nguyễn Duy Hoàng',
                              isDarkMode,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // About Card
                        _buildInfoCard(
                          isDarkMode: isDarkMode,
                          title: 'Về GeNews',
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'GeNews là ứng dụng tổng hợp tin tức thông minh, giúp bạn cập nhật thông tin nhanh chóng và chính xác. Với giao diện hiện đại và tính năng AI tóm tắt, GeNews mang đến trải nghiệm đọc tin hoàn toàn mới.\n\nChúng tôi cam kết cung cấp thông tin chất lượng cao, đa dạng chủ đề từ thời sự, thể thao, công nghệ đến giải trí, phục vụ mọi nhu cầu của người dùng.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Legal
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? Colors.grey[800]?.withOpacity(0.5)
                                    : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '© 2025 Hoang Nguyen Duy. All rights reserved.',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Helper methods
  Widget _buildFeedbackTypeOption(
    String emoji,
    String title,
    String description,
    bool isSelected,
    bool isDarkMode,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.amber.withOpacity(0.1)
                  : (isDarkMode ? Colors.grey[800] : Colors.grey[50]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? Colors.amber
                    : (isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected
                              ? Colors.amber
                              : (isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                    width: 1,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethodItem(
    IconData icon,
    String title,
    String value,
    String description,
    Color color,
    bool isDarkMode, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDarkMode,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Email sending methods
  void _sendFeedbackEmail(
    String feedbackType,
    String subject,
    String message,
    BuildContext context,
  ) async {
    if (subject.trim().isEmpty || message.trim().isEmpty) {
      _showErrorDialog(
        context,
        'Vui lòng điền đầy đủ tiêu đề và nội dung phản hồi.',
      );
      return;
    }

    final String emailSubject = '[$feedbackType] $subject';
    final String emailBody = '''
Loại phản hồi: $feedbackType

Nội dung:
$message

---
Gửi từ ứng dụng GeNews
Thời gian: ${DateTime.now().toString()}
''';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'nduyhoang107@gmail.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': emailSubject,
        'body': emailBody,
      }),
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        Navigator.pop(context); // Đóng bottom sheet
        _showSuccessDialog(context);
      } else {
        _showErrorDialog(
          context,
          'Không thể mở ứng dụng email. Vui lòng gửi email thủ công đến: nduyhoang107@gmail.com',
        );
      }
    } catch (e) {
      _showErrorDialog(
        context,
        'Có lỗi xảy ra khi gửi email. Vui lòng thử lại sau.',
      );
    }
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Gửi thành công!', textAlign: TextAlign.center),
            content: const Text(
              'Cảm ơn bạn đã gửi phản hồi. Chúng tôi sẽ xem xét và phản hồi sớm nhất có thể.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: const Icon(Icons.error, color: Colors.red, size: 48),
            title: const Text('Có lỗi xảy ra', textAlign: TextAlign.center),
            content: Text(message, textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }

  // Font size helper methods
  String _getFontSizeText(AppFontSize size) {
    switch (size) {
      case AppFontSize.small:
        return 'Nhỏ';
      case AppFontSize.medium:
        return 'Vừa';
      case AppFontSize.large:
        return 'Lớn';
    }
  }

  double _getPreviewFontSize(AppFontSize size) {
    switch (size) {
      case AppFontSize.small:
        return 12.0;
      case AppFontSize.medium:
        return 16.0;
      case AppFontSize.large:
        return 20.0;
    }
  }

  double _getIconSize(AppFontSize size) {
    switch (size) {
      case AppFontSize.small:
        return 16.0;
      case AppFontSize.medium:
        return 20.0;
      case AppFontSize.large:
        return 24.0;
    }
  }
}
