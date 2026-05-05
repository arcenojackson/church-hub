import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1220),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Voltar',
        ),
        title: Row(
          children: [
            const Icon(Icons.church_rounded, size: 22),
            const SizedBox(width: 8),
            const Text('Church Hub', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 0 : 24,
          vertical: 48,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: const _PolicyContent(),
          ),
        ),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Política de Privacidade',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Última atualização: maio de 2026',
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
        const SizedBox(height: 40),
        const _Section(
          title: '1. Sobre o Church Hub',
          body:
              'O Church Hub é uma plataforma de gestão para igrejas que permite organizar '
              'membros, eventos, cultos, escalas, biblioteca musical, chat e muito mais. '
              'Esta política descreve como coletamos, usamos e protegemos seus dados '
              'ao usar nosso aplicativo e website.',
        ),
        const _Section(
          title: '2. Dados coletados',
          body:
              'Coletamos apenas os dados necessários para o funcionamento do app:\n\n'
              '• Dados de conta: nome, endereço de e-mail e foto de perfil (opcional).\n'
              '• Dados da sua igreja: nome, localização, logotipo e configurações.\n'
              '• Dados de membros: nome, e-mail, telefone, função e permissões dentro da igreja.\n'
              '• Conteúdo do app: eventos, cultos, músicas, escalas e mensagens de chat '
              'criados por você ou por sua equipe.\n'
              '• Arquivos e imagens enviados por você para o armazenamento da plataforma.\n'
              '• Token de notificação push (FCM) para envio de notificações ao seu dispositivo.',
        ),
        const _Section(
          title: '3. Como usamos seus dados',
          body:
              'Seus dados são usados exclusivamente para:\n\n'
              '• Autenticar sua conta e mantê-la segura.\n'
              '• Exibir e sincronizar o conteúdo da sua igreja entre os membros.\n'
              '• Enviar notificações sobre eventos e avisos importantes.\n'
              '• Melhorar a plataforma com base em uso anônimo e agregado.',
        ),
        const _Section(
          title: '4. Compartilhamento de dados',
          body:
              'Não vendemos, alugamos nem compartilhamos seus dados pessoais com terceiros '
              'para fins comerciais. Os dados podem ser processados por:\n\n'
              '• Google Firebase (autenticação, banco de dados, armazenamento e notificações) '
              '— sujeito à Política de Privacidade do Google.\n'
              '• Stripe (processamento de doações voluntárias) — sujeito à Política de '
              'Privacidade da Stripe.\n\n'
              'Podemos divulgar dados quando exigido por lei ou para proteger direitos legais.',
        ),
        const _Section(
          title: '5. Armazenamento e segurança',
          body:
              'Todos os dados são armazenados em servidores do Google Firebase com criptografia '
              'em trânsito (HTTPS/TLS) e em repouso. O acesso aos dados é controlado por '
              'regras de segurança que garantem que cada membro acesse apenas os dados '
              'da sua própria igreja.',
        ),
        const _Section(
          title: '6. Seus direitos',
          body:
              'Você tem o direito de:\n\n'
              '• Acessar os dados que temos sobre você.\n'
              '• Corrigir informações incorretas no seu perfil.\n'
              '• Solicitar a exclusão da sua conta e dados associados.\n'
              '• Exportar seus dados mediante solicitação.\n\n'
              'Para exercer esses direitos, entre em contato pelo e-mail abaixo.',
        ),
        const _Section(
          title: '7. Retenção de dados',
          body:
              'Mantemos seus dados enquanto sua conta estiver ativa. Após a exclusão da conta, '
              'os dados são removidos permanentemente em até 30 dias, exceto onde a retenção '
              'for exigida por lei.',
        ),
        const _Section(
          title: '8. Menores de idade',
          body:
              'O Church Hub não é destinado a crianças com menos de 13 anos. '
              'Não coletamos intencionalmente dados de menores. Se identificarmos '
              'dados de um menor, procederemos com a exclusão imediata.',
        ),
        const _Section(
          title: '9. Alterações nesta política',
          body:
              'Podemos atualizar esta política periodicamente. Quando houver mudanças '
              'relevantes, notificaremos os usuários pelo app ou por e-mail. '
              'O uso continuado do app após as alterações implica aceitação da nova política.',
        ),
        const _Section(
          title: '10. Contato',
          body:
              'Dúvidas, solicitações ou reclamações relacionadas a esta política podem '
              'ser enviadas para:\n\n'
              'jackson.f205@gmail.com',
        ),
        const SizedBox(height: 64),
        const _Footer(),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: Colors.white12),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.church_rounded, size: 16, color: Colors.white38),
            const SizedBox(width: 6),
            const Text(
              'Church Hub · © 2026',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
