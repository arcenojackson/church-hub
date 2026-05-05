import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/holyrics_repository.dart';
import '../models/holyrics_model.dart';
import '../../../shared/state/app_state.dart';

class HolyricsSettingsPage extends StatefulWidget {
  const HolyricsSettingsPage({super.key});

  @override
  State<HolyricsSettingsPage> createState() => _HolyricsSettingsPageState();
}

class _HolyricsSettingsPageState extends State<HolyricsSettingsPage> {
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '8080');
  final _tokenCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool? _connectionStatus;
  HolyricsConfigModel? _config;

  late HolyricsRepository _repo;

  @override
  void initState() {
    super.initState();
    final churchId = context.read<AppState>().currentUser!.churchId!;
    _repo = HolyricsRepository(churchId: churchId);
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _loading = true);
    _config = await _repo.fetchConfig();
    if (_config != null) {
      _ipCtrl.text = _config!.ipAddress;
      _portCtrl.text = _config!.port.toString();
      _tokenCtrl.text = _config!.token ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      _config = await _repo.saveConfig(
        ipAddress: _ipCtrl.text.trim(),
        port: int.tryParse(_portCtrl.text.trim()) ?? 8080,
        token: _tokenCtrl.text.trim().isEmpty ? null : _tokenCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações salvas!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _testConnection() async {
    if (_config == null) {
      await _save();
    }
    if (_config == null) return;

    setState(() => _connectionStatus = null);
    final ok = await _repo.testConnection(_config!);
    setState(() => _connectionStatus = ok);
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Holyrics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(Icons.cast_rounded, size: 56, color: Colors.white60),
                const SizedBox(height: 16),
                Text(
                  'Configuração de Projeção',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Configure a integração com o software Holyrics\nna rede local da sua igreja.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 32),
                if (_connectionStatus != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_connectionStatus! ? Colors.green : Colors.red)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _connectionStatus!
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          color: _connectionStatus! ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _connectionStatus!
                              ? 'Conectado com sucesso!'
                              : 'Falha na conexão',
                          style: TextStyle(
                            color: _connectionStatus! ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _ipCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Endereço IP',
                    hintText: '192.168.1.100',
                    prefixIcon: Icon(Icons.computer_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _portCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Porta',
                    hintText: '8080',
                    prefixIcon: Icon(Icons.settings_ethernet_outlined),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tokenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Token (opcional)',
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testConnection,
                        icon: const Icon(Icons.wifi_tethering_rounded),
                        label: const Text('Testar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_rounded),
                        label: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
