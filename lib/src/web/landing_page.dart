import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modules/auth/presentation/login_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

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
              TextButton(
                onPressed: () => _scrollTo('features'),
                child: const Text('Funcionalidades',
                    style: TextStyle(color: Colors.white70)),
              ),
              TextButton(
                onPressed: () => _scrollTo('donation'),
                child: const Text('Apoiar', style: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(width: 8),
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
              _FeaturesSection(),
              _DonationSection(),
              _CtaSection(),
              _Footer(),
            ]),
          ),
        ],
      ),
    );
  }

  void _scrollTo(String section) {
    // TODO: implement scroll to section
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
          onPressed: () {},
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

class _HeroImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3E6C3E).withValues(alpha: 0.3),
            const Color(0xFF1B2435),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.church_rounded, size: 100, color: Colors.white30),
            SizedBox(height: 16),
            Text(
              'App Preview',
              style: TextStyle(color: Colors.white30, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  static const _features = [
    _Feature(
      icon: Icons.people_outline_rounded,
      title: 'Gestão de Membros',
      description: 'Cadastro completo, convites e controle de acesso.',
    ),
    _Feature(
      icon: Icons.event_rounded,
      title: 'Eventos e Cultos',
      description: 'Planeje cultos com roteiro completo, escalas e equipes.',
    ),
    _Feature(
      icon: Icons.music_note_rounded,
      title: 'Biblioteca Musical',
      description: 'Cifras, letras, YouTube e tons para cada música.',
    ),
    _Feature(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Chat em Tempo Real',
      description: '@Menções, citações e busca por mensagens.',
    ),
    _Feature(
      icon: Icons.calendar_month_rounded,
      title: 'Calendário',
      description: 'Visão mensal de todos os eventos da sua igreja.',
    ),
    _Feature(
      icon: Icons.groups_outlined,
      title: 'ELO e Sociedades',
      description: 'Gerencie sua equipe de louvor e grupos da igreja.',
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});
  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111828),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(feature.icon, color: primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(feature.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              )),
          const SizedBox(height: 8),
          Text(feature.description,
              style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

class _DonationSection extends StatelessWidget {
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

class _CtaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.3), primary.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Pronto para começar?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Gratuito para sempre. Sua igreja merece uma gestão simples.',
            style: TextStyle(color: Colors.white60, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.church_rounded),
            label: const Text('Criar minha igreja gratuitamente'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
                onPressed: () {},
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
            ],
          ),
        ],
      ),
    );
  }
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
