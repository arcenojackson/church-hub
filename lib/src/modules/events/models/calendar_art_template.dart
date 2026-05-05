enum CalendarArtColorScheme {
  light('Claro'),
  dark('Escuro'),
  primary('Tema do app'),
  custom('Personalizado');

  const CalendarArtColorScheme(this.label);
  final String label;

  static CalendarArtColorScheme fromString(String? value) {
    if (value == null) return CalendarArtColorScheme.primary;
    return CalendarArtColorScheme.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CalendarArtColorScheme.primary,
    );
  }
}

enum CalendarArtBackgroundType {
  solid('Cor sólida'),
  gradient2('Gradiente (2 cores)'),
  gradient3('Gradiente (3 cores)');

  const CalendarArtBackgroundType(this.label);
  final String label;

  static CalendarArtBackgroundType fromString(String? value) {
    if (value == null) return CalendarArtBackgroundType.gradient2;
    return CalendarArtBackgroundType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CalendarArtBackgroundType.gradient2,
    );
  }
}

enum CalendarArtCalendarStyle {
  minimal('Minimalista'),
  marked('Marcado (círculos nos dias com evento)'),
  bordered('Com bordas'),
  clean('Sem bordas');

  const CalendarArtCalendarStyle(this.label);
  final String label;

  static CalendarArtCalendarStyle fromString(String? value) {
    if (value == null) return CalendarArtCalendarStyle.marked;
    return CalendarArtCalendarStyle.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CalendarArtCalendarStyle.marked,
    );
  }
}

enum CalendarArtEventsLayout {
  listBelow('Abaixo do calendário'),
  listAbove('Acima do calendário');

  const CalendarArtEventsLayout(this.label);
  final String label;

  static CalendarArtEventsLayout fromString(String? value) {
    if (value == null) return CalendarArtEventsLayout.listBelow;
    if (value == 'listAbove') return CalendarArtEventsLayout.listAbove;
    return CalendarArtEventsLayout.listBelow;
  }
}

enum LogoDisplaySize {
  small('Pequena', 40),
  medium('Média', 50),
  large('Grande', 60);

  const LogoDisplaySize(this.label, this.height);
  final String label;
  final double height;

  static LogoDisplaySize fromString(String? value) {
    if (value == null) return LogoDisplaySize.medium;
    return LogoDisplaySize.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LogoDisplaySize.medium,
    );
  }
}

const List<int> kCalendarArtGradientColorOptions = [
  0xFF1a237e,
  0xFF1B5E20,
  0xFF4A148C,
  0xFFB71C1C,
  0xFFE65100,
  0xFF004D40,
  0xFF283593,
  0xFF880E4F,
  0xFF006064,
  0xFFBF360C,
  0xFF311B92,
  0xFF0D47A1,
  0xFFAD1457,
  0xFF33691E,
  0xFF4E342E,
];

class CalendarArtTemplate {
  const CalendarArtTemplate({
    this.colorScheme = CalendarArtColorScheme.primary,
    this.backgroundType = CalendarArtBackgroundType.gradient2,
    this.backgroundColors = const [0xFF1a237e, 0xFF0d47a1],
    this.calendarStyle = CalendarArtCalendarStyle.marked,
    this.eventsLayout = CalendarArtEventsLayout.listBelow,
    this.titleText,
    this.gradientColor,
    this.logoImageUrl,
    this.logoDisplaySize = LogoDisplaySize.medium,
  });

  final CalendarArtColorScheme colorScheme;
  final CalendarArtBackgroundType backgroundType;
  final List<int> backgroundColors;
  final CalendarArtCalendarStyle calendarStyle;
  final CalendarArtEventsLayout eventsLayout;
  final String? titleText;
  final int? gradientColor;
  final String? logoImageUrl;
  final LogoDisplaySize logoDisplaySize;

  factory CalendarArtTemplate.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const CalendarArtTemplate();
    final colorsRaw = json['backgroundColors'];
    List<int> colors = const [0xFF1a237e, 0xFF0d47a1];
    if (colorsRaw is List) {
      colors = colorsRaw
          .map((e) =>
              e is int ? e : int.tryParse(e.toString(), radix: 16) ?? 0xFF1a237e)
          .toList();
      if (colors.isEmpty) colors = const [0xFF1a237e, 0xFF0d47a1];
    }
    return CalendarArtTemplate(
      colorScheme:
          CalendarArtColorScheme.fromString(json['colorScheme']?.toString()),
      backgroundType: CalendarArtBackgroundType.fromString(
          json['backgroundType']?.toString()),
      backgroundColors: colors,
      calendarStyle: CalendarArtCalendarStyle.fromString(
          json['calendarStyle']?.toString()),
      eventsLayout:
          CalendarArtEventsLayout.fromString(json['eventsLayout']?.toString()),
      titleText: json['titleText']?.toString(),
      gradientColor: _parseGradientColor(json['gradientColor']),
      logoImageUrl: json['logoImageUrl']?.toString(),
      logoDisplaySize:
          LogoDisplaySize.fromString(json['logoDisplaySize']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'colorScheme': colorScheme.name,
        'backgroundType': backgroundType.name,
        'backgroundColors': backgroundColors,
        'calendarStyle': calendarStyle.name,
        'eventsLayout': eventsLayout.name,
        if (titleText != null && titleText!.isNotEmpty) 'titleText': titleText,
        if (gradientColor != null) 'gradientColor': gradientColor,
        if (logoImageUrl != null && logoImageUrl!.isNotEmpty)
          'logoImageUrl': logoImageUrl,
        'logoDisplaySize': logoDisplaySize.name,
      };

  static int? _parseGradientColor(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value, radix: 16);
    return null;
  }

  CalendarArtTemplate copyWith({
    CalendarArtColorScheme? colorScheme,
    CalendarArtBackgroundType? backgroundType,
    List<int>? backgroundColors,
    CalendarArtCalendarStyle? calendarStyle,
    CalendarArtEventsLayout? eventsLayout,
    String? titleText,
    int? gradientColor,
    String? logoImageUrl,
    LogoDisplaySize? logoDisplaySize,
  }) {
    return CalendarArtTemplate(
      colorScheme: colorScheme ?? this.colorScheme,
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundColors: backgroundColors ?? this.backgroundColors,
      calendarStyle: calendarStyle ?? this.calendarStyle,
      eventsLayout: eventsLayout ?? this.eventsLayout,
      titleText: titleText ?? this.titleText,
      gradientColor: gradientColor ?? this.gradientColor,
      logoImageUrl: logoImageUrl ?? this.logoImageUrl,
      logoDisplaySize: logoDisplaySize ?? this.logoDisplaySize,
    );
  }
}
