import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../models/translation_models.dart';
import '../services/translation_service.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TranslationService _translationService = TranslationService();

  Language _sourceLanguage = Language.supportedLanguages[1]; // English
  Language _targetLanguage = Language.supportedLanguages[0]; // Vietnamese

  bool _isLoading = false;
  bool _isListening = false;
  TranslationResult? _currentResult;

  late AnimationController _swapAnimationController;
  late Animation<double> _swapAnimation;

  @override
  void initState() {
    super.initState();
    _swapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _swapAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _swapAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    _swapAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Dịch văn bản',
          style: GoogleFonts.quattrocento(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black54),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildLanguageSelector(),
                  const SizedBox(height: 16),
                  _buildTranslationCard(),
                  if (_currentResult != null) ...[
                    const SizedBox(height: 16),
                    _buildResultCard(),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildLanguageButton(_sourceLanguage, true)),
          const SizedBox(width: 16),
          AnimatedBuilder(
            animation: _swapAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _swapAnimation.value * 3.14159,
                child: GestureDetector(
                  onTap: _swapLanguages,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B61FF),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(child: _buildLanguageButton(_targetLanguage, false)),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(Language language, bool isSource) {
    return GestureDetector(
      onTap: () => _showLanguagePicker(isSource),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.nativeName,
                    style: GoogleFonts.quattrocento(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    language.name,
                    style: GoogleFonts.quattrocento(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // Source text input
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Nhập văn bản',
                      style: GoogleFonts.quattrocento(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    if (_sourceController.text.isNotEmpty)
                      Text(
                        '${_sourceController.text.length}/5000',
                        style: GoogleFonts.quattrocento(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sourceController,
                  maxLines: 6,
                  maxLength: 5000,
                  decoration: InputDecoration(
                    hintText: 'Nhập hoặc dán văn bản cần dịch...',
                    hintStyle: GoogleFonts.quattrocento(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  style: GoogleFonts.quattrocento(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  onChanged: (text) {
                    setState(() {});
                    if (text.isNotEmpty) {
                      _autoDetectLanguage(text);
                    }
                  },
                ),
                if (_sourceController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.clear,
                        onTap: () {
                          _sourceController.clear();
                          _targetController.clear();
                          setState(() {
                            _currentResult = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.content_copy,
                        onTap: () => _copyToClipboard(_sourceController.text),
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.mic,
                        onTap: _startListening,
                        isActive: _isListening,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: Colors.grey[200]),

          // Target text output
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Bản dịch',
                      style: GoogleFonts.quattrocento(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    if (_currentResult != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(_currentResult!.confidence * 100).toInt()}%',
                              style: GoogleFonts.quattrocento(
                                fontSize: 11,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_targetController.text.isEmpty)
                  Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: Text(
                      'Bản dịch sẽ xuất hiện ở đây',
                      style: GoogleFonts.quattrocento(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        _targetController.text,
                        style: GoogleFonts.quattrocento(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildActionButton(
                            icon: Icons.content_copy,
                            onTap: () =>
                                _copyToClipboard(_targetController.text),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.volume_up,
                            onTap: () => _speakText(_targetController.text),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.share,
                            onTap: () => _shareText(_targetController.text),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF7B61FF) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.translate, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Kết quả dịch',
                style: GoogleFonts.quattrocento(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
              const Spacer(),
              Text(
                'Độ tin cậy: ${(_currentResult!.confidence * 100).toInt()}%',
                style: GoogleFonts.quattrocento(
                  fontSize: 12,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentResult!.sourceLanguage.flag} ${_currentResult!.originalText}',
            style: GoogleFonts.quattrocento(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_currentResult!.targetLanguage.flag} ${_currentResult!.translatedText}',
            style: GoogleFonts.quattrocento(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _sourceController.text.isEmpty ? null : _translateText,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Dịch',
                      style: GoogleFonts.quattrocento(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _translateText() async {
    if (_sourceController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _translationService.translateText(
        text: _sourceController.text,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );

      setState(() {
        _currentResult = result;
        _targetController.text = result.translatedText;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi dịch: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _autoDetectLanguage(String text) async {
    try {
      final detectedLanguage = await _translationService.detectLanguage(text);
      if (detectedLanguage != _sourceLanguage) {
        setState(() {
          _sourceLanguage = detectedLanguage;
        });
      }
    } catch (e) {
      // Silent fail for auto-detection
    }
  }

  void _swapLanguages() {
    _swapAnimationController.forward().then((_) {
      setState(() {
        final temp = _sourceLanguage;
        _sourceLanguage = _targetLanguage;
        _targetLanguage = temp;

        final tempText = _sourceController.text;
        _sourceController.text = _targetController.text;
        _targetController.text = tempText;
      });
      _swapAnimationController.reset();
    });
  }

  void _showLanguagePicker(bool isSource) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Chọn ngôn ngữ',
                style: GoogleFonts.quattrocento(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: Language.supportedLanguages.length,
                  itemBuilder: (context, index) {
                    final language = Language.supportedLanguages[index];
                    final isSelected = isSource
                        ? language.code == _sourceLanguage.code
                        : language.code == _targetLanguage.code;

                    return ListTile(
                      leading: Text(
                        language.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        language.nativeName,
                        style: GoogleFonts.quattrocento(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      subtitle: Text(
                        language.name,
                        style: GoogleFonts.quattrocento(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: const Color(0xFF7B61FF))
                          : null,
                      onTap: () {
                        setState(() {
                          if (isSource) {
                            _sourceLanguage = language;
                          } else {
                            _targetLanguage = language;
                          }
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Về tính năng dịch',
          style: GoogleFonts.quattrocento(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Tính năng dịch văn bản hỗ trợ nhiều ngôn ngữ phổ biến. '
          'Tự động phát hiện ngôn ngữ và cung cấp bản dịch chính xác.',
          style: GoogleFonts.quattrocento(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Đóng',
              style: GoogleFonts.quattrocento(color: const Color(0xFF7B61FF)),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã sao chép')));
  }

  void _speakText(String text) {
    // TTS implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng đọc văn bản sẽ được thêm')),
    );
  }

  void _shareText(String text) {
    // Share implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng chia sẻ sẽ được thêm')),
    );
  }

  void _startListening() {
    // Speech recognition implementation
    setState(() {
      _isListening = !_isListening;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng nhận diện giọng nói sẽ được thêm'),
      ),
    );
  }
}
