class OnboardingModel {
  final String title;
  final String description;
  final String iconName;

  const OnboardingModel({
    required this.title,
    required this.description,
    required this.iconName,
  });
}

// 온보딩 데이터
final List<OnboardingModel> onboardingPages = [
  const OnboardingModel(
    title: '설교를 듣고\n금방 잊으시나요?',
    description: 'AI 말씀비서가 매일 상기시켜드립니다',
    iconName: 'menu_book',
  ),
  const OnboardingModel(
    title: 'AI가 매일\n말씀을 \n챙겨드립니다',
    description: '월요일부터 금요일까지 함께',
    iconName: 'auto_awesome',
  ),
  const OnboardingModel(
    title: '신앙 성장을\n눈으로 확인하세요',
    description: 'AI 말씀비서와 함께 꾸준히',
    iconName: 'trending_up',
  ),
];
