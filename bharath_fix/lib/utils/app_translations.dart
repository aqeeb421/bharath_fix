class AppTranslations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'BharathFix',
      'hi': 'Hi',
      'service_installation': 'Service & Installation',
      'edit_profile': 'Edit Profile Details',
      'wallet': 'BharathFix Wallet',
      'offers_coupons': 'Offers & Coupons',
      'saved_addresses': 'Saved Addresses',
      'help_support': 'Help & Support',
      'about': 'About BharathFix',
      'app_theme': 'Dark Theme',
      'language': 'App Language',
      'logout': 'Log Out',
      'login': 'Sign In',
      'view_cart': 'View Cart',
      'services_added': 'Services Added',
      'select_language': 'Select App Language / ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ',
    },
    'kn': {
      'app_name': 'ಭಾರತ್ ಫಿಕ್ಸ್',
      'hi': 'ನಮಸ್ಕಾರ',
      'service_installation': 'ಸೇವೆ ಮತ್ತು ಅಳವಡಿಕೆ',
      'edit_profile': 'ಪ್ರೊಫೈಲ್ ವಿವರಗಳನ್ನು ತಿದ್ದುಪಡಿ ಮಾಡಿ',
      'wallet': 'ಭಾರತ್ ಫಿಕ್ಸ್ ವಾಲೆಟ್',
      'offers_coupons': 'ಆಫರ್ಗಳು ಮತ್ತು ಕೂಪನ್‌ಗಳು',
      'saved_addresses': 'ಉಳಿಸಿದ ವಿಳಾಸಗಳು',
      'help_support': 'ಸಹಾಯ ಮತ್ತು ಬೆಂಬಲ',
      'about': 'ಭಾರತ್ ಫಿಕ್ಸ್ ಕುರಿತು',
      'app_theme': 'ಡಾರ್ಕ್ ಥೀಮ್ (ಇರುಳು)',
      'language': 'ಅಪ್ಲಿಕೇಶನ್ ಭಾಷೆ (ಕನ್ನಡ)',
      'logout': 'ಹೊರಹೋಗಿ (Log Out)',
      'login': 'ಸೈನ್ ಇನ್ ಮಾಡಿ',
      'view_cart': 'ಕಾರ್ಟ್ ನೋಡಿ',
      'services_added': 'ಸೇವೆಗಳನ್ನು ಸೇರಿಸಲಾಗಿದೆ',
      'select_language': 'ಅಪ್ಲಿಕೇಶನ್ ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ',
    },
  };

  static String getText(String key, String langCode) {
    final lang = _localizedValues.containsKey(langCode) ? langCode : 'en';
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}
