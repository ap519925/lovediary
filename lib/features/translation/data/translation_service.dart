import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _baseUrl = 'https://api.mymemory.translated.net/get';
  
  /// Translates text from source language to target language
  /// Uses MyMemory Translation API (free tier)
  static Future<String> translateText({
    required String text,
    required String fromLang,
    required String toLang,
  }) async {
    try {
      if (text.trim().isEmpty) return text;
      
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': text,
        'langpair': '$fromLang|$toLang',
      });
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['responseStatus'] == 200) {
          return data['responseData']['translatedText'] ?? text;
        }
      }
      
      // Fallback: return original text if translation fails
      return text;
    } catch (e) {
      print('Translation error: $e');
      return text; // Return original text on error
    }
  }
  
  /// Translates from English to Chinese
  static Future<String> translateToChineseSimplified(String text) {
    return translateText(text: text, fromLang: 'en', toLang: 'zh-CN');
  }
  
  /// Translates from Chinese to English
  static Future<String> translateToEnglish(String text) {
    return translateText(text: text, fromLang: 'zh-CN', toLang: 'en');
  }
  
  /// Auto-detects language and translates accordingly
  static Future<String> autoTranslate(String text) async {
    if (text.trim().isEmpty) return text;
    
    // Simple detection: if contains Chinese characters, translate to English
    // Otherwise, translate to Chinese
    final containsChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
    
    if (containsChinese) {
      return translateToEnglish(text);
    } else {
      return translateToChineseSimplified(text);
    }
  }
  
  /// Batch translation for multiple texts
  static Future<List<String>> translateBatch({
    required List<String> texts,
    required String fromLang,
    required String toLang,
  }) async {
    final results = <String>[];
    
    for (final text in texts) {
      final translated = await translateText(
        text: text,
        fromLang: fromLang,
        toLang: toLang,
      );
      results.add(translated);
      
      // Add small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return results;
  }
  
  /// Supported language codes
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'zh-CN': 'Chinese (Simplified)',
    'zh-TW': 'Chinese (Traditional)',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'ja': 'Japanese',
    'ko': 'Korean',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'it': 'Italian',
    'nl': 'Dutch',
    'sv': 'Swedish',
    'da': 'Danish',
    'no': 'Norwegian',
    'fi': 'Finnish',
    'pl': 'Polish',
    'tr': 'Turkish',
  };
  
  /// Get language name from code
  static String getLanguageName(String code) {
    return supportedLanguages[code] ?? code;
  }
  
  /// Check if language is supported
  static bool isLanguageSupported(String code) {
    return supportedLanguages.containsKey(code);
  }
}

/// Extension to add translation capabilities to String
extension StringTranslation on String {
  Future<String> translateTo(String targetLang, {String? sourceLang}) {
    return TranslationService.translateText(
      text: this,
      fromLang: sourceLang ?? 'auto',
      toLang: targetLang,
    );
  }
  
  Future<String> translateToChineseSimplified() {
    return TranslationService.translateToChineseSimplified(this);
  }
  
  Future<String> translateToEnglish() {
    return TranslationService.translateToEnglish(this);
  }
  
  Future<String> autoTranslate() {
    return TranslationService.autoTranslate(this);
  }
}
