import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';
import '../models/translation_models.dart';
import '../services/translation_service.dart';
import '../services/ocr_service.dart';

/// Multi-functional translation interface supporting text, voice, and OCR.
///
/// Integrates live translation services, camera-based character recognition,
/// and offline-first common phrase management for travelers.
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
  final OCRService _ocrService = OCRService();

  Language _sourceLanguage = Language.supportedLanguages[0]; // Auto Detect
  Language _targetLanguage = Language.supportedLanguages[1]; // Vietnamese

  bool _isLoading = false;
  bool _isListening = false;
  bool _isProcessingImage = false;
  TranslationResult? _currentResult;

  // Timer for auto-translation debouncing
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 800);

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
    _debounceTimer?.cancel();
    _sourceController.dispose();
    _targetController.dispose();
    _swapAnimationController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.skyBlue.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.dodgerBlue,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.skyBlue.withValues(alpha: 0.15),
                AppColors.dodgerBlue.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.skyBlue.withValues(alpha: 0.9),
                      AppColors.steelBlue.withValues(alpha: 0.8),
                      AppColors.dodgerBlue.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Translator',
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D2E),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.skyBlue.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.info_outline_rounded,
                color: AppColors.dodgerBlue,
              ),
              onPressed: _showInfo,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 80,
          20,
          20,
        ),
        child: Column(
          children: [
            _buildLanguageSelector(),
            const SizedBox(height: 24),
            _buildTranslationCard(),
            const SizedBox(height: 20),
            _buildBottomActions(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.skyBlue.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildLanguageButton(_sourceLanguage, true)),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _swapAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _swapAnimation.value * 3.14159,
                child: GestureDetector(
                  onTap: _swapLanguages,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.skyBlue.withValues(alpha: 0.9),
                          AppColors.steelBlue.withValues(alpha: 0.8),
                          AppColors.dodgerBlue.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.skyBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildLanguageButton(_targetLanguage, false)),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(Language language, bool isSource) {
    return GestureDetector(
      onTap: () => _showLanguagePicker(isSource),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.skyBlue.withValues(alpha: 0.05),
              AppColors.dodgerBlue.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.skyBlue.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.skyBlue.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(language.flag, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    language.nativeName,
                    style: const TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D2E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    language.name,
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.steelBlue.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.dodgerBlue,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.skyBlue.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Source text input
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  AppColors.skyBlue.withValues(alpha: 0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.skyBlue.withValues(alpha: 0.15),
                            AppColors.dodgerBlue.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            color: AppColors.dodgerBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Enter Text',
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.steelBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_sourceController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.skyBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_sourceController.text.length}/5000',
                          style: TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.steelBlue,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sourceController,
                  maxLines: 4,
                  maxLength: 5000,
                  decoration: InputDecoration(
                    hintText: 'Enter or paste text to translate...',
                    hintStyle: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      color: AppColors.steelBlue.withValues(alpha: 0.3),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  style: const TextStyle(
                    fontFamily: 'Urbanist-Regular',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1D2E),
                    height: 1.6,
                  ),
                  onChanged: (text) {
                    setState(() {});
                    if (text.isNotEmpty) {
                      _autoDetectLanguage(text);
                      _scheduleAutoTranslation();
                    } else {
                      // Clear translation when text is empty
                      _debounceTimer?.cancel();
                      _targetController.clear();
                      _currentResult = null;
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Action buttons row
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    // Prominent Image Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.skyBlue.withValues(alpha: 0.9),
                            AppColors.steelBlue.withValues(alpha: 0.85),
                            AppColors.dodgerBlue.withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.skyBlue.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isProcessingImage
                              ? null
                              : _showImageSourceDialog,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.photo_camera_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Scan Image',
                                  style: TextStyle(
                                    fontFamily: 'Urbanist-Regular',
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                if (_isProcessingImage) ...[
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Other action buttons
                    if (_sourceController.text.isNotEmpty) ...[
                      _buildModernActionButton(
                        icon: Icons.clear_rounded,
                        label: 'Clear',
                        onTap: () {
                          _debounceTimer?.cancel();
                          _sourceController.clear();
                          _targetController.clear();
                          setState(() {
                            _currentResult = null;
                          });
                        },
                      ),
                      _buildModernActionButton(
                        icon: Icons.content_copy_rounded,
                        label: 'Copy',
                        onTap: () => _copyToClipboard(_sourceController.text),
                      ),
                      _buildModernActionButton(
                        icon: Icons.mic_rounded,
                        label: 'Voice',
                        onTap: _startListening,
                        isActive: _isListening,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.skyBlue.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Target text output
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.dodgerBlue.withValues(alpha: 0.02),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.dodgerBlue.withValues(alpha: 0.15),
                            AppColors.skyBlue.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.translate_rounded,
                            color: AppColors.dodgerBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Translation',
                            style: TextStyle(
                              fontFamily: 'Urbanist-Regular',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.steelBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_currentResult != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.withValues(alpha: 0.15),
                              Colors.green.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${(_currentResult!.confidence * 100).toInt()}%',
                              style: TextStyle(
                                fontFamily: 'Urbanist-Regular',
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer rotating circle
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.skyBlue.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                            // Inner solid circle
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.skyBlue.withValues(alpha: 0.2),
                                    AppColors.dodgerBlue.withValues(
                                      alpha: 0.15,
                                    ),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.translate_rounded,
                                color: AppColors.dodgerBlue,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Translating text...',
                          style: TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.steelBlue.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.skyBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.dodgerBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Processing',
                                style: TextStyle(
                                  fontFamily: 'Urbanist-Regular',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dodgerBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_targetController.text.isEmpty)
                  Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.translate_rounded,
                          size: 48,
                          color: AppColors.skyBlue.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Translation will appear here',
                          style: TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            color: AppColors.steelBlue.withValues(alpha: 0.4),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        _targetController.text,
                        style: const TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1D2E),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildModernActionButton(
                            icon: Icons.content_copy_rounded,
                            label: 'Copy',
                            onTap: () =>
                                _copyToClipboard(_targetController.text),
                          ),
                          _buildModernActionButton(
                            icon: Icons.volume_up_rounded,
                            label: 'Read',
                            onTap: () => _speakText(_targetController.text),
                          ),
                          _buildModernActionButton(
                            icon: Icons.share_rounded,
                            label: 'Share',
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

  Widget _buildModernActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    AppColors.skyBlue.withValues(alpha: 0.3),
                    AppColors.dodgerBlue.withValues(alpha: 0.25),
                  ],
                )
              : null,
          color: isActive ? null : AppColors.skyBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.skyBlue.withValues(alpha: 0.4)
                : AppColors.skyBlue.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? AppColors.dodgerBlue
                  : AppColors.steelBlue.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? AppColors.dodgerBlue
                    : AppColors.steelBlue.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    // Show informational message about auto-translation
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.skyBlue.withValues(alpha: 0.1),
            AppColors.dodgerBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.skyBlue.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.skyBlue.withValues(alpha: 0.2),
                  AppColors.dodgerBlue.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: AppColors.dodgerBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Auto-translate when you type text',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.steelBlue.withValues(alpha: 0.8),
              ),
            ),
          ),
          if (_isLoading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.dodgerBlue),
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
      _targetController.clear();
      _currentResult = null;
    });

    try {
      // If source language is auto detect, detect it first
      Language actualSourceLanguage = _sourceLanguage;
      if (_sourceLanguage.code == 'auto') {
        actualSourceLanguage = await _translationService.detectLanguage(
          _sourceController.text,
        );
      }

      final result = await _translationService.translateText(
        text: _sourceController.text,
        sourceLanguage: actualSourceLanguage,
        targetLanguage: _targetLanguage,
      );

      if (mounted) {
        setState(() {
          _currentResult = result;
          _targetController.text = result.translatedText;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _targetController.text = 'Error: Unable to translate text';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _autoDetectLanguage(String text) async {
    // Only auto-detect if source language is set to auto
    if (_sourceLanguage.code != 'auto') return;
  }

  void _scheduleAutoTranslation() {
    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Start a new timer
    _debounceTimer = Timer(_debounceDuration, () {
      if (_sourceController.text.trim().isNotEmpty && mounted) {
        _translateText();
      }
    });
  }

  void _swapLanguages() {
    // Don't swap if source is auto detect
    if (_sourceLanguage.code == 'auto') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot swap when in auto-detect mode'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

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

      // Auto-translate after swapping
      if (_sourceController.text.trim().isNotEmpty) {
        _scheduleAutoTranslation();
      }
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
                'Select Language',
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
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

                    // Don't allow "auto" for target language
                    final isAutoDetect = language.code == 'auto';
                    final isDisabled = !isSource && isAutoDetect;

                    return ListTile(
                      leading: Text(
                        language.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        language.nativeName,
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isDisabled ? Colors.grey[400] : null,
                        ),
                      ),
                      subtitle: Text(
                        isDisabled
                            ? '${language.name} (Source language only)'
                            : language.name,
                        style: TextStyle(
                          fontFamily: 'Urbanist-Regular',
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.dodgerBlue,
                            )
                          : null,
                      enabled: !isDisabled,
                      onTap: isDisabled
                          ? null
                          : () {
                              setState(() {
                                if (isSource) {
                                  _sourceLanguage = language;
                                } else {
                                  _targetLanguage = language;
                                }
                              });
                              Navigator.pop(context);

                              // Auto-translate after language change
                              if (_sourceController.text.trim().isNotEmpty) {
                                _scheduleAutoTranslation();
                              }
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
          'About Translation Feature',
          style: TextStyle(
            fontFamily: 'Urbanist-Regular',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'The text translation feature supports many popular languages. '
          'Automatically detects language and provides accurate translation.',
          style: TextStyle(fontFamily: 'Urbanist-Regular'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                color: AppColors.dodgerBlue,
                fontWeight: FontWeight.w600,
              ),
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
    ).showSnackBar(const SnackBar(content: Text('Copied')));
  }

  void _speakText(String text) {
    // TTS implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text-to-speech feature will be added')),
    );
  }

  void _shareText(String text) {
    // Share implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature will be added')),
    );
  }

  void _startListening() {
    // Speech recognition implementation
    setState(() {
      _isListening = !_isListening;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice recognition feature will be added')),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Select Image Source',
              style: TextStyle(
                fontFamily: 'Urbanist-Regular',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.skyBlue.withValues(alpha: 0.15),
                      AppColors.dodgerBlue.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.dodgerBlue,
                ),
              ),
              title: Text(
                'Take Photo',
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Open camera to take photo',
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _extractTextFromCamera();
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.skyBlue.withValues(alpha: 0.15),
                      AppColors.dodgerBlue.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.dodgerBlue,
                ),
              ),
              title: Text(
                'Select from Gallery',
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Select image from your gallery',
                style: TextStyle(
                  fontFamily: 'Urbanist-Regular',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _extractTextFromGallery();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _extractTextFromCamera() async {
    setState(() {
      _isProcessingImage = true;
    });

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Đang xử lý ảnh và trích xuất văn bản...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: AppColors.skyBlue,
        ),
      );
    }

    try {
      final extractedText = await _ocrService.extractTextFromCamera();

      // Close loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (extractedText != null && extractedText.isNotEmpty) {
        setState(() {
          _sourceController.text = extractedText;
        });

        // Auto detect language and translate
        await _autoDetectLanguage(extractedText);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã quét văn bản từ ảnh thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  Future<void> _extractTextFromGallery() async {
    setState(() {
      _isProcessingImage = true;
    });

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Đang xử lý ảnh và trích xuất văn bản...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Color(0xFF7B61FF),
        ),
      );
    }

    try {
      // Pass language hint from source language (unless it's auto)
      final languageHint = _sourceLanguage.code == 'auto'
          ? null
          : _sourceLanguage.code;
      final extractedText = await _ocrService.extractTextFromGallery(
        languageHint: languageHint,
      );

      // Close loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (extractedText != null && extractedText.isNotEmpty) {
        setState(() {
          _sourceController.text = extractedText;
        });

        // Auto detect language and translate
        await _autoDetectLanguage(extractedText);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã quét văn bản từ ảnh thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }
}
