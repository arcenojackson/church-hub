import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modules/auth/presentation/login_page.dart';
import 'delete_account_page.dart';
import 'privacy_policy_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _featuresKey = GlobalKey();
  final _donationKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0D1220),
            pinned: true,
            title: Row(
              children: [
                const Icon(Icons.church_rounded, size: 28),
                const SizedBox(width: 10),
                const Text(
                  'Church Hub',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            actions: [
              if (MediaQuery.of(context).size.width > 600) ...[
                TextButton(
                  onPressed: () => _scrollTo(_featuresKey),
                  child: const Text('Funcionalidades',
                      style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () => _scrollTo(_donationKey),
                  child: const Text('Apoiar', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
                child: const Text('Entrar no app'),
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _HeroSection(),
              _FeaturesSection(key: _featuresKey),
              _DonationSection(key: _donationKey),
              _Footer(),
            ]),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 120 : 32,
        vertical: isDesktop ? 100 : 60,
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _HeroContent()),
                const SizedBox(width: 60),
                Expanded(child: _HeroImage()),
              ],
            )
          : Column(
              children: [
                _HeroContent(),
                const SizedBox(height: 40),
                _HeroImage(),
              ],
            ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF3E6C3E).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3E6C3E).withValues(alpha: 0.4),
            ),
          ),
          child: const Text(
            '✨ 100% gratuito',
            style: TextStyle(
              color: Color(0xFF7EBF7E),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Gerencie sua\nigreja com\nfacilidade',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Plataforma completa para igrejas: membros, cultos, '
          'música, escalas, chat e muito mais. Tudo em um só lugar.',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginPage(initialSignUp: true)),
          ),
          icon: const Icon(Icons.rocket_launch_rounded),
          label: const Text('Criar minha igreja'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroImage extends StatefulWidget {
  @override
  State<_HeroImage> createState() => _HeroImageState();
}

class _HeroImageState extends State<_HeroImage> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _lerp(double a, double b) => a + (b - a) * _anim.value;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final swapped = _anim.value >= 0.5;

          // Phone A (prev2/Mais): back-left → front-right on hover
          final phoneA = Transform.rotate(
            angle: _lerp(-0.08, 0.05),
            child: _PhoneMockup(imagePath: 'assets/prev2.png', height: _lerp(400, 440)),
          );
          // Phone B (prev1/liturgia): front-right → back-left on hover
          final phoneB = Transform.rotate(
            angle: _lerp(0.05, -0.08),
            child: _PhoneMockup(imagePath: 'assets/prev1.png', height: _lerp(440, 400)),
          );

          final posA = Positioned(left: _lerp(0, 120), right: _lerp(120, 0), child: phoneA);
          final posB = Positioned(left: _lerp(120, 0), right: _lerp(0, 120), child: phoneB);

          return SizedBox(
            height: 460,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              // swap z-order at midpoint so neither phone abruptly jumps over the other
              children: swapped ? [posB, posA] : [posA, posB],
            ),
          );
        },
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection({super.key});
  static const _features = [
    _Feature(
      icon: Icons.people_outline_rounded,
      title: 'Gestão de Membros',
      description: 'Cadastro completo, convites e controle de acesso.',
      imagePath: 'assets/images/membros.png',
    ),
    _Feature(
      icon: Icons.event_rounded,
      title: 'Eventos e Cultos',
      description: 'Planeje cultos com roteiro completo, escalas e equipes.',
      imagePath: 'assets/images/escalas.png',
    ),
    _Feature(
      icon: Icons.music_note_rounded,
      title: 'Biblioteca Musical',
      description: 'Cifras, letras, YouTube e tons para cada música.',
      imagePath: 'assets/images/musicas.png',
      imagePath2: 'assets/images/musicas2.png',
    ),
    _Feature(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Chat em Tempo Real',
      description: '@Menções, citações e busca por mensagens.',
      imagePath: 'assets/images/chat.png',
    ),
    _Feature(
      icon: Icons.calendar_month_rounded,
      title: 'Calendário',
      description: 'Visão mensal de todos os eventos da sua igreja.',
      imagePath: 'assets/images/calendario.png',
    ),
    _Feature(
      icon: Icons.groups_outlined,
      title: 'Grupos',
      description: 'Gerencie sua equipe de louvor e grupos da igreja.',
      imagePath: 'assets/images/grupos.png',
      imagePath2: 'assets/images/grupos2.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;
    final columns = isDesktop ? 3 : 1;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 120 : 32,
        vertical: 80,
      ),
      child: Column(
        children: [
          Text(
            'Tudo que sua igreja precisa',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.5,
            ),
            itemCount: _features.length,
            itemBuilder: (_, i) => _FeatureCard(feature: _features[i]),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.feature});
  final _Feature feature;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final imagePath = _hovered && widget.feature.imagePath2 != null
        ? widget.feature.imagePath2!
        : widget.feature.imagePath;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111828),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Stack(
              children: [
                if (imagePath != null)
                  Positioned(
                    right: -80,
                    top: -60,
                    bottom: -60,
                    width: 350,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: _hovered ? 0.35 : 0.55, end: _hovered ? 0.55 : 0.35),
                      duration: const Duration(milliseconds: 200),
                      builder: (_, opacity, __) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Image.asset(
                          imagePath,
                          key: ValueKey(imagePath),
                          height: double.infinity,
                          fit: BoxFit.cover,
                          alignment: Alignment.topLeft,
                          filterQuality: FilterQuality.high,
                          color: Colors.white.withValues(alpha: opacity),
                          colorBlendMode: BlendMode.modulate,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(widget.feature.icon, color: primary, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text(widget.feature.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 8),
                      Text(widget.feature.description,
                          style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
                    ],
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

class _DonationSection extends StatelessWidget {
  const _DonationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 120 : 32,
        vertical: 80,
      ),
      color: const Color(0xFF0D1220),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Icon(
                Icons.favorite_rounded,
                color: primary,
                size: 56,
              ),
              const SizedBox(height: 24),
              Text(
                'Apoie o Church Hub',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'O Church Hub é completamente gratuito e mantido com dedicação. '
                'Se ele tem ajudado sua igreja, considere fazer uma doação para '
                'manter o projeto vivo e crescendo.',
                style: TextStyle(color: Colors.white60, fontSize: 16, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://donate.stripe.com/test_dRmaEXdxW9qf8ht8xC1sQ00'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.volunteer_activism_rounded),
                label: const Text('Fazer uma doação'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pagamento seguro via Stripe • Qualquer valor ajuda 💙',
                style: TextStyle(color: Colors.white38, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: const Color(0xFF0D1220),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.church_rounded, size: 20, color: Colors.white38),
              const SizedBox(width: 8),
              const Text(
                'Church Hub',
                style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '© 2026 Church Hub. Todos os direitos reservados.',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                ),
                child: const Text('Privacidade', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Termos', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Contato', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeleteAccountPage()),
                ),
                child: const Text('Excluir conta', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({required this.imagePath, required this.height});

  final String imagePath;
  final double height;

  @override
  Widget build(BuildContext context) {
    final width = height * 0.462; // iPhone aspect ratio
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height * 0.06),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height * 0.06 - 1),
          child: Image.asset(imagePath, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
    this.imagePath,
    this.imagePath2,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? imagePath;
  final String? imagePath2;
}
