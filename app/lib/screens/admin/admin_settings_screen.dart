import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// PROTOTİP: kurum-admin ayarları paneli. Gerçek sürümde **Web Admin paneline**
/// taşınacak; burada yalnızca davranışları canlı denemek için var. Etiketler TR
/// (prototip iç panel). Bölümler docs/admin-settings.md ile birebir.
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final admin = state.adminSettings;
    final tenant = state.activeTenant!;
    final scheme = Theme.of(context).colorScheme;
    // Admin'in belirlediği rol adı (yoksa tenant varsayılanı).
    String roleName(Role r) => admin.roleLabels[r.id] ?? r.label(state.language);

    return Scaffold(
      appBar: AppBar(title: Text(s.adminSettingsTitle)),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 48),
        children: [
          // Prototip uyarısı.
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prototip: bu ayarlar gerçek sürümde Web Admin paneline '
                    'taşınacak.',
                    style: TextStyle(color: scheme.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),

          // §1 Görünürlük varsayılanı.
          const _SectionHeader(
            'Görünürlük Varsayılanı',
            note: '🟡 Yeni-öğeye — mevcut üyeler korunur, yeni kayıtlara uygulanır',
          ),
          RadioListTile<MemberVisibility>(
            value: MemberVisibility.visible,
            groupValue: admin.defaultVisibility,
            onChanged: (v) => state.setDefaultVisibility(v!),
            title: const Text('Görünür (opt-out)'),
            subtitle: const Text('Üyeler varsayılan olarak dizinde görünür.'),
          ),
          RadioListTile<MemberVisibility>(
            value: MemberVisibility.hidden,
            groupValue: admin.defaultVisibility,
            onChanged: (v) => state.setDefaultVisibility(v!),
            title: const Text('Görünmez (opt-in)'),
            subtitle: const Text(
              'Üyeler açıkça açmadıkça dizinde görünmez.',
            ),
          ),

          const Divider(height: 28),

          // §2 Grup hiyerarşisi.
          const _SectionHeader(
            'Grup Hiyerarşisi',
            note: '🔴 Derinlik: kullanım-öncesi (kilit) · 🟢 Seviye adları: canlı',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Expanded(child: Text('Seviye sayısı')),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 1, label: Text('1')),
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 3, label: Text('3')),
                  ],
                  selected: {admin.groupMaxDepth},
                  onSelectionChanged: (v) => state.setGroupMaxDepth(v.first),
                ),
              ],
            ),
          ),
          // Kullanım-öncesi kilit: kullanımdaki en derin seviyenin altına inilemez.
          if (state.usedGroupDepth > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '🔒 Kullanımda: en az ${state.usedGroupDepth} seviye — azaltılamaz.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          // Seviye adları her zaman girilebilir (tek seviyede de o grubun adı).
          // Etiket SOLDA, girdi SAĞDA ("Seviye sayısı" düzeniyle aynı).
          for (var i = 0; i < admin.groupMaxDepth; i++)
            _LabeledField(
              label: '${i + 1}. seviye adı',
              fieldKey: ValueKey('level_$i'),
              initialValue: admin.levelLabels[i],
              onChanged: (v) => state.setLevelLabel(i, v),
            ),
          if (admin.groupMaxDepth == 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Tek seviye — alt grup yok.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

          const Divider(height: 28),

          // Roller — adlar admin tarafından belirlenir.
          const _SectionHeader(
            'Roller',
            note: '🔴 Rol çeşidi: baştan bir kez · 🟢 Adlar: canlı (dile göre)',
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Kurumdaki rollerin adlarını buradan belirle.'),
          ),
          for (final r in tenant.roles)
            _LabeledField(
              label: 'Rol adı',
              fieldKey: ValueKey('role_${r.id}'),
              initialValue: roleName(r),
              onChanged: (v) => state.setRoleLabel(r.id, v),
            ),

          const Divider(height: 28),

          // §3+§4'ün yerini alan TEK ayar: doğrudan görme/ekleme matrisi.
          const _SectionHeader(
            'Doğrudan Görme ve Ekleme',
            note: '🟢 Canlı — ileriye dönük',
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'Her rol için: hangi rolleri DOĞRUDAN görür (Kişiler → Herkes) '
              've sormadan rehberine ekler. İşaretli olmayan roller dizinde '
              'görünmez; onlara ekleme karşı tarafın ONAYIYLA olur (Davetler).',
            ),
          ),
          for (final viewer in tenant.roles)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${roleName(viewer)} şunları doğrudan görür:'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final target in tenant.roles)
                        FilterChip(
                          label: Text(roleName(target)),
                          selected:
                              admin.directRolesByRole[viewer.id]?.contains(
                                    target.id,
                                  ) ??
                                  false,
                          onSelected:
                              (_) => state.toggleDirectRole(
                                viewer.id,
                                target.id,
                              ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // §5 Görünüm (appearance) — admin varsayılanı + KİLİT.
          const _SectionHeader(
            'Görünüm',
            note: '🎨 Varsayılanı belirle; "Kilitli" ise kullanıcı '
                'değiştiremez, değilse kendine göre seçebilir',
          ),
          _AppearanceAdmin(state: state),
        ],
      ),
    );
  }
}

/// Admin görünüm bölümü: vurgu rengi + yazı boyutu + font, her biri kilit
/// anahtarıyla (kullanıcı tercihi 2026-07-19).
class _AppearanceAdmin extends StatelessWidget {
  const _AppearanceAdmin({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final admin = state.adminSettings;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arkaplan rengi paleti.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              const Expanded(child: Text('Arkaplan rengi')),
              _LockChip(
                locked: admin.accentLocked,
                onChanged: state.setAccentLocked,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final c in kAccentPalette)
                _ColorDot(
                  color: c,
                  selected: admin.accentColor.toARGB32() == c.toARGB32(),
                  onTap: () => state.setAdminAccent(c),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Yazı boyutu.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              const Expanded(child: Text('Yazı boyutu')),
              _LockChip(
                locked: admin.textScaleLocked,
                onChanged: state.setTextScaleLocked,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            children: [
              for (final sc in AppTextScale.values)
                ChoiceChip(
                  label: Text(sc.labelTr),
                  selected: admin.textScale == sc,
                  onSelected: (_) => state.setAdminTextScale(sc),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Yazı tipi.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              const Expanded(child: Text('Yazı tipi')),
              _LockChip(
                locked: admin.fontLocked,
                onChanged: state.setFontLocked,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            children: [
              for (final (label, family) in kFontOptions)
                ChoiceChip(
                  label: Text(
                    label,
                    style: TextStyle(fontFamily: family),
                  ),
                  selected: admin.fontFamily == family,
                  onSelected: (_) => state.setAdminFont(family),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Kilitli eksenler kullanıcıda salt-okur görünür.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Küçük renk noktası (palet seçimi).
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.onSurface : Colors.transparent,
              width: 3,
            ),
          ),
          child:
              selected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
        ),
      ),
    );
  }
}

/// "Kilitli" anahtarı (kompakt).
class _LockChip extends StatelessWidget {
  const _LockChip({required this.locked, required this.onChanged});

  final bool locked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          locked ? Icons.lock_outline : Icons.lock_open,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        const Text('Kilitli'),
        Switch(value: locked, onChanged: onChanged),
      ],
    );
  }
}

/// Etiketi SOLDA, metin girdisini SAĞDA gösteren satır ("Seviye sayısı" ile
/// aynı düzen — kullanıcı tercihi 2026-07-19).
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.fieldKey,
    required this.initialValue,
    required this.onChanged,
  });

  final String label;
  final Key fieldKey;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label)),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              key: fieldKey,
              initialValue: initialValue,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.note});

  final String title;

  /// Küçük kategori notu (değişim/kilit semantiği — docs/admin-settings.md).
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(
              note!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
