class JobMatchingService {
  static const List<String> standardSkillCategories = [
    'Washing Machine',
    'Refrigerator',
    'Water Purifier',
    'AC Repair',
    'Kitchen Chimney',
    'Air Cooler',
    'Geyser',
    'Microwave Oven',
    'Electrician',
    'Plumbing',
  ];

  /// Returns true if technician has 80%+ (8 or more) standard skills selected.
  static bool isAllAppliancesExpert(List<String> activeSkills) {
    if (activeSkills.contains('All Appliances Specialist')) return true;

    int matchCount = 0;
    for (final stdCat in standardSkillCategories) {
      if (activeSkills.any(
        (s) => s.toLowerCase().trim() == stdCat.toLowerCase().trim(),
      )) {
        matchCount++;
      }
    }
    return matchCount >= 8; // 80%+ of 10 skills
  }

  /// Format category label based on skills count
  static String getCategoryDisplayLabel(
    List<String> activeSkills,
    String fallbackCategory,
  ) {
    if (isAllAppliancesExpert(activeSkills)) {
      return "All Appliances Specialist 🏅";
    }

    if (activeSkills.isNotEmpty) {
      return activeSkills.join(", ");
    }

    if (fallbackCategory.isNotEmpty &&
        fallbackCategory != 'All Appliances Specialist') {
      return fallbackCategory;
    }

    return "Appliance Specialist";
  }

  /// Checks strictly if a job request matches any of the technician's active skills.
  static bool isTechnicianExpertForJob(
    Map<String, dynamic> techData,
    Map<String, dynamic> jobData,
  ) {
    // 1. Extract explicitly enabled skills array
    final List<dynamic> skillsRaw =
        (techData['skills'] as List<dynamic>?) ?? [];
    List<String> activeSkills = skillsRaw
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Fallback to category field if skills array is missing
    final String fallbackCategory = (techData['category'] ?? '')
        .toString()
        .trim();
    if (activeSkills.isEmpty &&
        fallbackCategory.isNotEmpty &&
        fallbackCategory != 'All Appliances Specialist') {
      activeSkills = [fallbackCategory];
    }

    // If technician has no skills configured at all, return false
    if (activeSkills.isEmpty) {
      return false;
    }

    // 2. Check 80-90% rule for All Appliances Specialist
    if (isAllAppliancesExpert(activeSkills)) {
      return true; // 80%+ skills active, can handle all appliance requests
    }

    // 3. Extract exact Job Info
    final String jobTitle = (jobData['title'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final String jobCategory =
        (jobData['category'] ?? jobData['categoryName'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
    final String jobSubCategory =
        (jobData['subCategory'] ?? jobData['subCategoryName'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
    final String jobServiceTitle =
        (jobData['serviceTitle'] ?? jobData['subCategoryTitle'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
    final String fullJobText =
        '$jobTitle $jobCategory $jobSubCategory $jobServiceTitle'
            .toLowerCase()
            .trim();

    if (fullJobText.isEmpty) {
      return false;
    }

    // 4. Strict keyword dictionary mapping for each appliance category
    final Map<String, List<String>> strictSkillKeywords = {
      'washing machine': [
        'wash',
        'washing',
        'laundry',
        'front load',
        'top load',
        'dryer',
        'spin',
      ],
      'refrigerator': [
        'fridge',
        'refrigerator',
        'freezer',
        'single door',
        'double door',
        'deep freezer',
        'compressor',
      ],
      'ac repair': [
        'ac',
        'air conditioner',
        'split ac',
        'window ac',
        'hvac',
        'cassette ac',
        'gas charging',
      ],
      'water purifier': [
        'purifier',
        'ro',
        'water filter',
        'kent',
        'aquaguard',
        'uv filter',
      ],
      'kitchen chimney': ['chimney', 'kitchen exhaust', 'hood'],
      'air cooler': ['cooler', 'air cooler'],
      'geyser': ['geyser', 'water heater', 'instant heater'],
      'microwave oven': ['microwave', 'oven', 'micro oven', 'otg'],
      'electrician': [
        'electrical',
        'wire',
        'switch',
        'socket',
        'fan',
        'light',
        'mcb',
        'fuse',
      ],
      'plumbing': [
        'plumber',
        'pipe',
        'tap',
        'leak',
        'drain',
        'basin',
        'toilet',
        'flush',
        'valve',
      ],
    };

    // 5. Strict matching: Job MUST contain a keyword belonging to one of activeSkills
    for (final skill in activeSkills) {
      final skillLower = skill.toLowerCase();

      List<String> searchKeywords = [skillLower];
      for (final entry in strictSkillKeywords.entries) {
        if (skillLower.contains(entry.key) || entry.key.contains(skillLower)) {
          searchKeywords.addAll(entry.value);
        }
      }

      for (final kw in searchKeywords) {
        if (kw.length >= 3 && fullJobText.contains(kw)) {
          return true; // Match found!
        }
      }
    }

    // Job does not match any of technician's explicitly enabled skills
    return false;
  }
}
