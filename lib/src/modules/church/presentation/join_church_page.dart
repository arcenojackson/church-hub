import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_exception.dart';
import '../../../shared/state/app_state.dart';
import '../data/church_repository.dart';
import '../../auth/models/user_model.dart';

class JoinChurchPage extends StatefulWidget {
  const JoinChurchPage({super.key});

  @override
  State<JoinChurchPage> createState() => _JoinChurchPageState();
}

class _JoinChurchPageState extends State<JoinChurchPage> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Digite o código de convite');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = context.read<ChurchRepository>();
      final churchId = await repo.findChurchIdByInviteCode(code);
      if (churchId == null) {
        setState(() {
          _error = 'Código inválido ou expirado';
          _loading = false;
        });
        return;
      }

      final appState = context.read<AppState>();
      // Assign first so the user gets churchId — then the church read is allowed.
      await appState.assignUserToChurch(churchId, UserRole.member);
      final church = await repo.fetchChurch(churchId);
      if (church != null) appState.setChurch(church);

      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AppException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao ingressar na igreja';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar em uma Igreja')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.group_add_outlined, size: 56, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'Código de Convite',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Peça o código ao administrador da sua igreja',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: 8,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'XXXXXXXX',
                hintStyle: TextStyle(
                  letterSpacing: 8,
                  color: Colors.white24,
                ),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _loading ? null : _join,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Ingressar'),
            ),
          ],
        ),
      ),
    );
  }
}
