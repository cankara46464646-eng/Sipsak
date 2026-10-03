import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../config.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Yeni grup kurma penceresi.
Future<void> showCreateSheet(BuildContext context, {required void Function(Group) onCreated}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _CreateSheet(onCreated: onCreated),
  );
}

/// Kodla katılma penceresi.
Future<void> showJoinSheet(BuildContext context, {required void Function(Group) onJoined}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _JoinSheet(onJoined: onJoined),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}

class _CreateSheet extends StatefulWidget {
  const _CreateSheet({required this.onCreated});
  final void Function(Group) onCreated;

  @override
  State<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends State<_CreateSheet> {
  final _name = TextEditingController();
  bool _busy = false;
  Group? _created;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().length < 2) return;
    setState(() => _busy = true);
    try {
      final g = await app.createGroup(_name.text);
      if (mounted) setState(() => _created = g);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _share(Group g) {
    Share.share(
      'Şipşak\'ta grubuma katıl! Her gün bir an, bir saat, tek kazanan.\n\n'
      'Grup: ${g.name}\nKod: ${g.code}\n\nUygulamayı al:\n${AppConfig.getAppText}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = _created;
    if (g != null) {
      return _SheetFrame(children: [
        Text('${g.name} hazır!', style: display(24)),
        const SizedBox(height: 6),
        Text('Bu kodu arkadaşlarına at, uygulamada "Kodla katıl" deyip girsinler.', style: body(14, color: C.muted)),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: g.code));
            showInfo(context, 'Kod kopyalandı');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: C.flash, width: 2),
            ),
            child: Column(
              children: [
                Text(g.code, style: mono(40, color: C.flash, spacing: 6)),
                const SizedBox(height: 4),
                Text('Kopyalamak için dokun', style: body(12, color: C.muted)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        BigButton(label: 'Arkadaşlarına gönder', icon: Icons.ios_share, onPressed: () => _share(g)),
        const SizedBox(height: 10),
        GhostButton(
          label: 'Gruba git',
          onPressed: () {
            Navigator.of(context).pop();
            widget.onCreated(g);
          },
        ),
      ]);
    }
    return _SheetFrame(children: [
      Text('Yeni grup kur', style: display(24)),
      const SizedBox(height: 6),
      Text('Arkadaş grubun, sınıfın, halı saha ekibin... Ne istersen.', style: body(14, color: C.muted)),
      const SizedBox(height: 16),
      TextField(
        controller: _name,
        autofocus: true,
        maxLength: 30,
        textCapitalization: TextCapitalization.sentences,
        style: body(16),
        decoration: const InputDecoration(hintText: 'Örn. Mahalle Ekibi', counterText: ''),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _create(),
      ),
      const SizedBox(height: 14),
      BigButton(label: 'Kur', busy: _busy, onPressed: _name.text.trim().length >= 2 ? _create : null),
    ]);
  }
}

class _JoinSheet extends StatefulWidget {
  const _JoinSheet({required this.onJoined});
  final void Function(Group) onJoined;

  @override
  State<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<_JoinSheet> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _code.text.trim().toUpperCase();
    if (code.length < 4) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final g = await app.joinGroup(code);
      if (!mounted) return;
      if (g == null) {
        setState(() => _error = 'Bu kodla bir grup bulunamadı.');
      } else {
        Navigator.of(context).pop();
        widget.onJoined(g);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(children: [
      Text('Kodla katıl', style: display(24)),
      const SizedBox(height: 6),
      Text(
        app.isDemo ? 'Demo modunda deneme kodu: DEMO42' : 'Arkadaşının sana attığı 6 haneli kodu yaz.',
        style: body(14, color: C.muted),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _code,
        autofocus: true,
        maxLength: 6,
        textCapitalization: TextCapitalization.characters,
        textAlign: TextAlign.center,
        style: mono(28, spacing: 6),
        decoration: const InputDecoration(hintText: 'ABC123', counterText: ''),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _join(),
      ),
      if (_error != null) ...[
        const SizedBox(height: 8),
        Text(_error!, style: body(14, color: C.danger)),
      ],
      const SizedBox(height: 14),
      BigButton(label: 'Katıl', busy: _busy, onPressed: _code.text.trim().length >= 4 ? _join : null),
    ]);
  }
}
