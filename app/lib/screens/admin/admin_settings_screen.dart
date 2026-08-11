import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

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

          // §2 Grup hiyerarşisi.
          const _SectionHeader(
            'Grup Hiyerarşisi',
            note: '🔴 Derinlik: kullanım-öncesi (kilit) · 🟢 Seviye adları: canlı',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: BoxedChoice<int>(
              title: 'Seviye sayısı',
              value: admin.groupMaxDepth,
              onChanged: state.setGroupMaxDepth,
              segments: const [(1, '1'), (2, '2'), (3, '3')],
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

          // Kurumsal grup açıklamaları — Web-Admin girdisinin karşılığı.
          const _SectionHeader(
            'Grup Açıklamaları',
            note: '🟢 Canlı · Grup Bilgisi ekranında görünür',
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'Kurumsal grupların açıklamasını buradan düzenle. Boş bırakılan '
              'açıklama Grup Bilgisi ekranında gizlenir.',
            ),
          ),
          _GroupDescriptionsAdmin(state: state),

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

          // GÖRÜNÜRLÜK — iki İLİŞKİLİ ayar birlikte (kullanıcı hükmü 2026-08-02):
          // önce "varsayılan görünürlük", hemen altında "otomatik görme matrisi".
          const _SectionHeader(
            'Görünürlük Varsayılanı',
            note: '🟡 Yeni-öğeye — mevcut üyeler korunur, yeni kayıtlara uygulanır',
          ),
          // Segmented toggle: sol=Görünür, sağ=Görünmez (value=hidden).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: BoxedBinaryChoice(
              value: admin.defaultVisibility == MemberVisibility.hidden,
              onChanged: (v) => state.setDefaultVisibility(
                v ? MemberVisibility.hidden : MemberVisibility.visible,
              ),
              falseLabel: 'Görünür (opt-out)',
              trueLabel: 'Görünmez (opt-in)',
            ),
          ),

          // Rol-başına görünürlük KİLİDİ (kullanıcı hükmü 2026-08-02): kilitli
          // rolün üyeleri Profil'de kendi görünürlük/ekleme ayarını göremez;
          // etkin görünürlük admin varsayılanına sabitlenir.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            child: Text(
              'Rol görünürlük kilidi — kilitli rol üyeleri kendi ayarını '
              'değiştiremez.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final r in tenant.roles)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
              child: Row(
                children: [
                  Expanded(child: Text(roleName(r))),
                  _LockChip(
                    locked: state.isRoleVisibilityLocked(r.id),
                    onChanged: (v) => state.setRoleVisibilityLocked(r.id, v),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // §3+§4'ün yerini alan TEK ayar: otomatik görme/ekleme matrisi.
          const _SectionHeader(
            'Otomatik Görme ve Ekleme',
            note: '🟢 Canlı — ileriye dönük',
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'İşaretli roller birbirini OTOMATİK görür (Kişiler → Herkes) ve '
              'sormadan rehbere eklenir. İşaretsizler ancak KARŞI TARAF kendini '
              '"Görünür" yaptığında görünür ve ekleme ONAYLA olur (Davetler). '
              '"Tamamen gizli" yoktur — herkes en azından kendi ayarıyla '
              'görünebilir.',
            ),
          ),
          for (final viewer in tenant.roles)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${roleName(viewer)} şunları otomatik görür:'),
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

/// Kurumsal grupların açıklamalarını düzenleyen admin bölümü. Her grup için
/// hiyerarşi yolu (breadcrumb) + çok satırlı açıklama girdisi. Açıklama seed'i
/// kurumsal gruplarda admin'in Web-Admin girdisi sayılır (bkz.
/// [AppState.setOrganizedGroupDescription]).
class _GroupDescriptionsAdmin extends StatelessWidget {
  const _GroupDescriptionsAdmin({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final groups = state.organizedGroupsForAdmin;
    final scheme = Theme.of(context).colorScheme;
    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Text(
          'Bu kurumda henüz kurumsal grup yok.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return Column(
      children: [
        for (final g in groups)
          _GroupDescriptionField(
            key: ValueKey('grpdesc_${g.id}'),
            name: g.name,
            // Hiyerarşi yolu (kök → grup): aynı adlı grupları ayırt eder.
            // Tek düzeyli/düz grupta yol sadece grubun kendisidir → gizle.
            path: state.groupPath(g).map((n) => n.name).join(' › '),
            initialValue: g.description,
            onChanged: (v) => state.setOrganizedGroupDescription(g.id, v),
          ),
      ],
    );
  }
}

/// Tek bir kurumsal grubun açıklama satırı: üstte ad + (varsa) yol, altta
/// çok satırlı düzenlenebilir açıklama alanı.
class _GroupDescriptionField extends StatelessWidget {
  const _GroupDescriptionField({
    super.key,
    required this.name,
    required this.path,
    required this.initialValue,
    required this.onChanged,
  });

  final String name;
  final String path;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Yol grubun kendi adından ibaretse (düz grup / kök) breadcrumb gösterme.
    final showPath = path.isNotEmpty && path != name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (showPath) ...[
            const SizedBox(height: 2),
            Text(
              path,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 6),
          TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Açıklama (boş bırakılabilir)',
              border: OutlineInputBorder(),
            ),
          ),
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
        // Arkaplan rengi paleti — başlık elipsi (+ kilit sağda).
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: boxedChoiceTitle(
            context,
            'Arkaplan rengi',
            trailing: _LockChip(
              locked: admin.accentLocked,
              onChanged: state.setAccentLocked,
            ),
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

        // Yazı boyutu — eşit-genişlik toggle (+ kilit sağda).
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: BoxedChoice<AppTextScale>(
            title: 'Yazı boyutu',
            titleTrailing: _LockChip(
              locked: admin.textScaleLocked,
              onChanged: state.setTextScaleLocked,
            ),
            value: admin.textScale,
            onChanged: state.setAdminTextScale,
            segments: [
              for (final sc in AppTextScale.values) (sc, sc.labelTr),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Yazı tipi — eşit-genişlik toggle (+ kilit sağda).
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: BoxedChoice<String?>(
            title: 'Yazı tipi',
            titleTrailing: _LockChip(
              locked: admin.fontLocked,
              onChanged: state.setFontLocked,
            ),
            value: admin.fontFamily,
            onChanged: state.setAdminFont,
            segments: [
              for (final (label, family) in kFontOptions) (family, label),
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
