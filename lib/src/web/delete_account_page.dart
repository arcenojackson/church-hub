import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _loading = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      final churchCode = _codeCtrl.text.trim().toUpperCase();

      // Verify church code exists before submitting
      final codeDoc = await FirebaseFirestore.instance
          .collection('invite_codes')
          .doc(churchCode)
          .get();
      if (!codeDoc.exists) {
        setState(() => _error = 'Código da igreja não encontrado.');
        return;
      }

      final churchId = codeDoc.data()!['churchId'] as String;

      // Write deletion request — processed async by Cloud Function trigger
      final docId = '${email.replaceAll('@', '_').replaceAll('.', '_')}_$churchCode';
      await FirebaseFirestore.instance
          .collection('deletion_requests')
          .doc(docId)
          .set({
        'email': email,
        'churchCode': churchCode,
        'churchId': churchId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _success = true);
    } on FirebaseException catch (e) {
      setState(() => _error = e.message ?? 'Ocorreu um erro. Tente novamente.');
    } catch (_) {
      setState(() => _error = 'Ocorreu um erro. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
            constraints: const BoxConstraints(maxWidth: 560),
            child: _success ? const _SuccessCard() : _PageContent(
              formKey: _formKey,
              emailCtrl: _emailCtrl,
              codeCtrl: _codeCtrl,
              loading: _loading,
              error: _error,
              onSubmit: _submit,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.formKey,
    required this.emailCtrl,
    required this.codeCtrl,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController codeCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Excluir minha conta',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Church Hub · desenvolvido por jackson.f205@gmail.com',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // ── Steps ────────────────────────────────────────
        _InfoCard(
          icon: Icons.list_alt_rounded,
          title: 'Como funciona',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Step(
                number: '1',
                text: 'Informe o e-mail cadastrado na sua conta Church Hub.',
              ),
              const SizedBox(height: 10),
              _Step(
                number: '2',
                text: 'Informe o código de convite da sua igreja (visível nas configurações do app).',
              ),
              const SizedBox(height: 10),
              _Step(
                number: '3',
                text: 'Clique em "Confirmar exclusão". Sua solicitação será processada em até 24 horas.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Data info ────────────────────────────────────
        _InfoCard(
          icon: Icons.storage_rounded,
          title: 'O que acontece com seus dados',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DataRow(
                label: 'Excluídos imediatamente',
                value: 'Conta, perfil, escalas e disponibilidade',
                color: Colors.redAccent,
              ),
              const SizedBox(height: 8),
              _DataRow(
                label: 'Excluídos em até 30 dias',
                value: 'Mensagens de chat e histórico de atividade',
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              _DataRow(
                label: 'Mantidos (não pessoais)',
                value: 'Eventos e músicas criados por você permanecem na biblioteca da igreja',
                color: Colors.white38,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Form ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF111828),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirmar exclusão',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 20),
                _Field(
                  controller: emailCtrl,
                  label: 'E-mail da conta',
                  hint: 'seu@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe seu e-mail';
                    if (!v.contains('@')) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _Field(
                  controller: codeCtrl,
                  label: 'Código da sua igreja',
                  hint: 'Ex: MINHA-IGREJA',
                  icon: Icons.church_outlined,
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o código da sua igreja';
                    return null;
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Confirmar exclusão'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111828),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white54),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, height: 1.5),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            prefixIcon: Icon(icon, size: 18, color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0B0F19),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: const Color(0xFF111828),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3E6C3E).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF7EBF7E), size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'Solicitação recebida',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sua conta será excluída em até 24 horas. Você receberá '
            'uma confirmação por e-mail quando o processo for concluído.',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Dados pessoais serão removidos imediatamente. Mensagens '
            'de chat podem levar até 30 dias para serem completamente excluídas.',
            style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Voltar ao início'),
          ),
        ],
      ),
    );
  }
}
