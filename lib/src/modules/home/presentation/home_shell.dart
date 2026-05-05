import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../auth/models/user_model.dart';
import '../../auth/presentation/settings_page.dart';
import '../../events/presentation/agenda_section.dart';
import '../../events/presentation/planning_section.dart';
import '../../events/presentation/calendar_page.dart';
import '../../musics/presentation/musics_section.dart';
import '../../music_evaluations/presentation/evaluations_list_page.dart';
import '../../people/presentation/people_section.dart';
import '../../profiles/data/profiles_repository.dart';
import '../../profiles/models/profile_model.dart';
import '../../societies/presentation/societies_page.dart';
import '../../../shared/permissions/app_permission.dart';
import '../../../shared/state/app_state.dart';

enum HomeSection { agenda, planning, calendar, musics, people, societies, evaluations, settings }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialSection});
  final HomeSection? initialSection;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _currentIndex = 0;
  late List<_Destination> _destinations;
  StreamSubscription<List<ProfileModel>>? _profilesSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.read<AppState>();
    _destinations = _buildDestinations(appState.currentUser!, appState);

    if (widget.initialSection != null) {
      final idx = _destinations.indexWhere((d) => d.section == widget.initialSection);
      if (idx != -1) _currentIndex = idx;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<ProfilesRepository>();
      final appState = context.read<AppState>();
      _profilesSub = repo.watchProfiles().listen((profiles) {
        appState.setChurchProfiles(profiles);
      });
    });
  }

  @override
  void dispose() {
    _profilesSub?.cancel();
    super.dispose();
  }

  List<_Destination> _buildDestinations(UserModel user, AppState appState) {
    return [
      _Destination(
        section: HomeSection.agenda,
        icon: Icons.calendar_month_outlined,
        label: 'Agenda',
        builder: (_) => AgendaSection(user: user),
      ),
      if (appState.can(AppPermission.planEvents))
        _Destination(
          section: HomeSection.planning,
          icon: Icons.edit_calendar_outlined,
          label: 'Planejar',
          builder: (_) => PlanningSection(user: user),
        ),
      if (appState.can(AppPermission.viewSocieties))
        _Destination(
          section: HomeSection.societies,
          icon: Icons.groups_outlined,
          label: 'Grupos',
          builder: (_) => const SocietiesPage(),
        ),
      _Destination(
        section: HomeSection.settings,
        icon: Icons.person_outline_rounded,
        label: 'Mais',
        builder: (_) => const SettingsSection(),
      ),
      if (appState.can(AppPermission.viewCalendar))
        _Destination(
          section: HomeSection.calendar,
          icon: Icons.calendar_month_rounded,
          label: 'Calendário',
          builder: (_) => const CalendarPage(),
        ),
      if (appState.can(AppPermission.viewMusics))
        _Destination(
          section: HomeSection.musics,
          icon: Icons.music_note_rounded,
          label: 'Músicas',
          builder: (_) => MusicsSection(
            canEdit: appState.can(AppPermission.editMusics),
          ),
        ),
      if (appState.can(AppPermission.viewPeople))
        _Destination(
          section: HomeSection.people,
          icon: Icons.people_outline_rounded,
          label: 'Pessoas',
          builder: (_) => const PeopleSection(),
        ),
      if (appState.can(AppPermission.viewEvaluations))
        _Destination(
          section: HomeSection.evaluations,
          icon: Icons.star_outline_rounded,
          label: 'Avaliações musicais',
          builder: (_) => const EvaluationsListPage(),
        ),
    ];
  }

  // Primary destinations shown in the mobile bottom pill nav
  List<_Destination> get _primaryDestinations {
    const primarySections = {
      HomeSection.agenda,
      HomeSection.planning,
      HomeSection.societies,
      HomeSection.settings,
    };
    return _destinations.where((d) => primarySections.contains(d.section)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width > 1024) {
      return _DesktopLayout(
        destinations: _destinations,
        currentIndex: _currentIndex,
        onSelect: (i) => setState(() => _currentIndex = i),
      );
    } else if (width > 768) {
      return _TabletLayout(
        destinations: _destinations,
        currentIndex: _currentIndex,
        onSelect: (i) => setState(() => _currentIndex = i),
      );
    } else {
      return _MobileLayout(
        primaryDestinations: _primaryDestinations,
        currentDestination: _destinations[_currentIndex.clamp(0, _destinations.length - 1)],
        currentPrimaryIndex: _primaryDestinations.indexOf(
          _primaryDestinations.firstWhere(
            (d) => d.section == _destinations[_currentIndex.clamp(0, _destinations.length - 1)].section,
            orElse: () => _primaryDestinations.first,
          ),
        ),
        onSelect: (i) => setState(() {
          final section = _primaryDestinations[i].section;
          _currentIndex = _destinations.indexWhere((d) => d.section == section);
        }),
      );
    }
  }
}

// -------- Mobile --------
class _MobileLayout extends StatefulWidget {
  const _MobileLayout({
    required this.primaryDestinations,
    required this.currentDestination,
    required this.currentPrimaryIndex,
    required this.onSelect,
  });

  final List<_Destination> primaryDestinations;
  final _Destination currentDestination;
  final int currentPrimaryIndex;
  final ValueChanged<int> onSelect;

  @override
  State<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<_MobileLayout> {
  bool _compact = false;

  @override
  void didUpdateWidget(_MobileLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDestination.section != widget.currentDestination.section) {
      setState(() => _compact = false);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      final goingDown = notification.direction == ScrollDirection.reverse;
      if (goingDown && !_compact) {
        setState(() => _compact = true);
      } else if (!goingDown && _compact) {
        setState(() => _compact = false);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1220), Color(0xFF05070D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: Stack(
              children: [
                Column(
                  children: [
                    _AppHeader(label: widget.currentDestination.label),
                    const SizedBox(height: 8),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Padding(
                          key: ValueKey(widget.currentDestination.section),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: widget.currentDestination.builder(context),
                        ),
                      ),
                    ),
                    SizedBox(height: 80 + bottomInset),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _FloatingPillNav(
                    primaryDestinations: widget.primaryDestinations,
                    currentIndex: widget.currentPrimaryIndex,
                    onSelect: widget.onSelect,
                    bottomInset: bottomInset,
                    compact: _compact,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------- Tablet --------
class _TabletLayout extends StatelessWidget {
  const _TabletLayout({
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<_Destination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final current = destinations[currentIndex];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onSelect,
            labelType: NavigationRailLabelType.all,
            backgroundColor: const Color(0xFF111828),
            destinations: destinations.map((d) => NavigationRailDestination(
              icon: Icon(d.icon),
              label: Text(d.label),
            )).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey(current.section),
                padding: const EdgeInsets.all(24),
                child: current.builder(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------- Desktop --------
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<_Destination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final current = destinations[currentIndex];
    final appState = context.read<AppState>();
    final user = appState.currentUser!;
    final church = appState.currentChurch;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: Container(
              color: const Color(0xFF0D1220),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.church_rounded, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            church?.name ?? 'Church Hub',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: destinations.length,
                      itemBuilder: (ctx, i) {
                        final dest = destinations[i];
                        final selected = i == currentIndex;
                        return ListTile(
                          leading: Icon(dest.icon,
                              color: selected
                                  ? Theme.of(ctx).colorScheme.primary
                                  : Colors.white54),
                          title: Text(dest.label,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.white54,
                                fontWeight: selected ? FontWeight.w600 : null,
                              )),
                          selected: selected,
                          selectedTileColor:
                              Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onTap: () => onSelect(i),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          _initials(user.name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(user.name,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 20),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsPage()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey(current.section),
                padding: const EdgeInsets.all(32),
                child: current.builder(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
  }
}

// ---- Header ----
class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Text(
        label,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---- Floating Pill Nav (Instagram-style, with scrubbing) ----
class _FloatingPillNav extends StatefulWidget {
  const _FloatingPillNav({
    required this.primaryDestinations,
    required this.currentIndex,
    required this.onSelect,
    required this.bottomInset,
    required this.compact,
  });

  final List<_Destination> primaryDestinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final double bottomInset;
  final bool compact;

  @override
  State<_FloatingPillNav> createState() => _FloatingPillNavState();
}

class _FloatingPillNavState extends State<_FloatingPillNav> {
  double _pillWidth = 0;

  int _indexFromDx(double dx) {
    if (_pillWidth == 0) return widget.currentIndex;
    final itemWidth = _pillWidth / widget.primaryDestinations.length;
    return (dx / itemWidth).floor().clamp(0, widget.primaryDestinations.length - 1);
  }

  void _handleDrag(double dx) {
    final index = _indexFromDx(dx);
    if (index != widget.currentIndex) {
      HapticFeedback.selectionClick();
      widget.onSelect(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final user = appState.currentUser!;
    final colorScheme = Theme.of(context).colorScheme;
    final compact = widget.compact;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: compact ? 40 : 24,
        right: compact ? 40 : 24,
        bottom: widget.bottomInset + (compact ? 6 : 12),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final index = _indexFromDx(d.localPosition.dx);
          widget.onSelect(index);
        },
        onPanStart: (d) => _handleDrag(d.localPosition.dx),
        onPanUpdate: (d) => _handleDrag(d.localPosition.dx),
        child: LayoutBuilder(
          builder: (_, constraints) {
            _pillWidth = constraints.maxWidth;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: compact ? 48 : 64,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: compact ? 0.35 : 0.5),
                    blurRadius: compact ? 16 : 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              child: Row(
                children: widget.primaryDestinations.asMap().entries.map((e) {
                  final idx = e.key;
                  final dest = e.value;
                  final selected = idx == widget.currentIndex;

                  if (dest.section == HomeSection.settings) {
                    return Expanded(
                      child: _AvatarPillItem(
                        userName: user.name,
                        selected: selected,
                        colorScheme: colorScheme,
                        compact: compact,
                      ),
                    );
                  }

                  return Expanded(
                    child: _PillNavItem(
                      icon: dest.icon,
                      selected: selected,
                      colorScheme: colorScheme,
                      compact: compact,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PillNavItem extends StatelessWidget {
  const _PillNavItem({
    required this.icon,
    required this.selected,
    required this.colorScheme,
    required this.compact,
  });

  final IconData icon;
  final bool selected;
  final ColorScheme colorScheme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: compact ? 20 : 26,
          color: selected ? colorScheme.primary : Colors.white38,
        ),
      ),
    );
  }
}

class _AvatarPillItem extends StatelessWidget {
  const _AvatarPillItem({
    required this.userName,
    required this.selected,
    required this.colorScheme,
    required this.compact,
  });

  final String userName;
  final bool selected;
  final ColorScheme colorScheme;
  final bool compact;

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 13.0 : 16.0;
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: selected
              ? colorScheme.primary
              : colorScheme.primary.withValues(alpha: 0.5),
          child: Text(
            _initials(userName),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.section,
    required this.icon,
    required this.label,
    required this.builder,
  });

  final HomeSection section;
  final IconData icon;
  final String label;
  final Widget Function(BuildContext) builder;
}
