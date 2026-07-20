import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/models.dart';
import '../state/mock_data.dart';

/// Circular avatar showing a member's initials over a deterministic colour.
/// There is no photo upload in the prototype.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.member, this.radius = 22});

  final Member member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: member.avatarColor,
      child: Text(
        member.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}

/// Circular avatar for a group (icon over accent colour).
class GroupAvatar extends StatelessWidget {
  const GroupAvatar({super.key, required this.group, this.radius = 22});

  final Group group;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          group.isOrganized
              ? scheme.primaryContainer
              : scheme.tertiaryContainer,
      child: Icon(
        group.logoIcon ?? Icons.groups_outlined,
        size: radius * 1.1,
        color:
            group.isOrganized
                ? scheme.onPrimaryContainer
                : scheme.onTertiaryContainer,
      ),
    );
  }
}

/// Full-screen empty placeholder with an icon, message and optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Small pill used for role / group-type badges.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.secondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Kutu kutu" tasarım dili (kullanıcı tercihi 2026-07-19) — uygulama geneli
/// paylaşımlı bileşenler: sekme kutuları, üye-sayısı kutusu, bilgi kutusu.

/// Boxed tab bar: standart TabBar yerine her sekme yuvarlatılmış bir kutu;
/// seçili olan dolgulu (secondaryContainer). DefaultTabController'a bağlanır.
/// Dar ekranda (393px) etiketler Expanded + ellipsis ile sığar.
class BoxedTabBar extends StatelessWidget implements PreferredSizeWidget {
  const BoxedTabBar({super.key, required this.labels});

  final List<String> labels;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final index = controller.index;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
          child: Row(
            children: [
              for (final (i, label) in labels.indexed)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Material(
                      color:
                          i == index
                              ? scheme.secondaryContainer
                              : scheme.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => controller.animateTo(i),
                        child: Container(
                          // Sabit yükseklik + iki satıra izin: uzun etiketler
                          // (ör. "Kurumsal Gruplar") taşmadan sarar.
                          height: 48,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Center(
                            child: Text(
                              label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.15,
                                fontWeight:
                                    i == index
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                color:
                                    i == index
                                        ? scheme.onSecondaryContainer
                                        : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Üye sayısını sade bir rakam-kutusunda gösterir (kişi ikonu + rakam) — eski
/// tür rozeti + "n üye" metni yerine (kullanıcı tercihi).
class CountBox extends StatelessWidget {
  const CountBox({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sayfa başlığı — dolgulu (primary) tam-genişlik KUTU (kullanıcı tercihi
/// 2026-07-19): Menü başlığıyla aynı dil. AppBar yerine gövdenin en üstünde
/// kullanılır. Sağdaki eylem (ör. "+") [onAction] ile verilir; ikon, çevresinde
/// AYNI RENKTE (onPrimary) bir ÇEMBER ile çizilir (kullanıcı hükmü) — tüm
/// "+"lar tek yerden bu görünümü alır.
class BoxedPageHeader extends StatelessWidget {
  const BoxedPageHeader({
    super.key,
    required this.title,
    this.onAction,
    this.actionIcon = Icons.add,
    this.actionTooltip,
  });

  final String title;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final String? actionTooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(18, onAction == null ? 16 : 10, 12, 10),
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
            if (onAction != null)
              CircleIconButton(
                icon: actionIcon,
                onTap: onAction!,
                tooltip: actionTooltip,
                color: scheme.onPrimary,
              ),
          ],
        ),
      ),
    );
  }
}

/// İkonun çevresinde AYNI RENKTE ince bir çember olan yuvarlak buton
/// (kullanıcı hükmü 2026-07-19): sayfa başlıklarındaki "+" bunu kullanır.
/// Renk, içinde bulunduğu yüzeyin metin rengini (IconTheme/onPrimary) devralır.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onPrimary;
    final button = Material(
      color: Colors.transparent,
      shape: CircleBorder(side: BorderSide(color: c, width: 2)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: c, size: 22),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// İki-seçenekli KUTU toggle (kullanıcı tercihi 2026-07-19): yan yana iki kutu,
/// seçili olan dolgulu. Her kutuda başlık + (varsa) alt satırda küçük fontlu
/// AÇIKLAMA. Switch/radyo yerine (ör. Açık/Kapalı grup, yazma yetkisi).
class BoxedBinaryChoice extends StatelessWidget {
  const BoxedBinaryChoice({
    super.key,
    required this.value,
    required this.onChanged,
    required this.falseLabel,
    required this.trueLabel,
    this.falseDesc,
    this.trueDesc,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String falseLabel;
  final String trueLabel;
  final String? falseDesc;
  final String? trueDesc;

  @override
  Widget build(BuildContext context) {
    return Row(
      // Her iki kutu en uzun açıklamaya göre eşit yükseklikte.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _box(context, false, falseLabel, falseDesc)),
        const SizedBox(width: 8),
        Expanded(child: _box(context, true, trueLabel, trueDesc)),
      ],
    );
  }

  Widget _box(BuildContext context, bool v, String label, String? desc) {
    final scheme = Theme.of(context).colorScheme;
    final selected = value == v;
    final fg =
        selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Material(
      color:
          selected ? scheme.secondaryContainer : scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(v),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, color: fg),
              ),
              if (desc != null) ...[
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    color: fg.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Rol/bölüm başlığı — **ince kutu** içinde (kullanıcı tercihi 2026-07-19),
/// isteğe bağlı **katlanır** (chevron): Kişiler → Herkes/Rehberim ve Kurum
/// Yapısı yaprak üye rol başlıkları bunu kullanır. [collapsed] null ise katlanmaz
/// (chevron yok). [indent] hiyerarşik girinti.
class BoxedRoleHeader extends StatelessWidget {
  const BoxedRoleHeader(
    this.title, {
    super.key,
    this.collapsed,
    this.onToggle,
    this.indent = 0,
    this.dimLastWord = false,
  });

  final String title;
  final bool? collapsed;
  final VoidCallback? onToggle;
  final double indent;

  /// true ise başlık BÜYÜTÜLMEZ ve SON sözcük (ör. "sohbetleri") daha sönük
  /// çizilir — Sohbetler kategori başlıkları için (kullanıcı tercihi).
  final bool dimLastWord;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.bold,
    );
    final Widget label;
    if (dimLastWord) {
      final i = title.lastIndexOf(' ');
      final main = i >= 0 ? title.substring(0, i) : title;
      final last = i >= 0 ? title.substring(i + 1) : '';
      label = Text.rich(
        TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: main),
            if (last.isNotEmpty)
              TextSpan(
                text: ' $last',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      );
    } else {
      label = Text(context.upper(title), style: baseStyle);
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(12 + indent, 5, 12, 5),
      child: Material(
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onToggle,
          child: Padding(
            // "İnce kutu" — düşük dikey dolgu.
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(child: label),
                if (collapsed != null)
                  Icon(
                    collapsed! ? Icons.expand_more : Icons.expand_less,
                    size: 18,
                    color: scheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bir liste satırının ad/bilgi metnini yumuşak dolgulu, yuvarlatılmış bir
/// kutuya alır (kullanıcı tercihi — "isimleri kutula"). İçine tek bir Text ya
/// da ad+açıklama gibi bir Column verilir; genelde Expanded ile sarılır.
class InfoBox extends StatelessWidget {
  const InfoBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// Formats a message timestamp compactly (HH:mm, or a weekday/date).
String formatTime(DateTime? time) {
  if (time == null) return '';
  final now = DateTime.now();
  final sameDay =
      time.year == now.year && time.month == now.month && time.day == now.day;
  String two(int v) => v.toString().padLeft(2, '0');
  if (sameDay) return '${two(time.hour)}:${two(time.minute)}';
  return '${two(time.day)}.${two(time.month)}';
}

/// Liste satırındaki İSİM DÜZENİ (tek yerde):
/// "Mehmet KAYA, Doç. Dr., Elektrik-Elektronik Müh." — SOYADI büyük (Türkçe
/// kasing ile), ünvan ismin ARKASINDA, sonra bölüm; en sonda (varsa) login
/// rakamı (prototip kısayolu). Ünvan başa yazılmadığı için listeler ad-soyada
/// göre doğru sıralanır.
extension MemberRowLabel on Member {
  /// "Ad SOYAD" — soyad Türkçe kurallarıyla büyük harfe çevrilir (FR-94).
  /// Bildirim/snackbar gibi kısa yerlerde (ünvan/bölümsüz) kullanılır.
  String nameSurnameUpper(BuildContext context) {
    final parts = fullName.trim().split(RegExp(r'\s+')).toList();
    final surname = parts.isEmpty ? '' : context.upper(parts.removeLast());
    return [...parts, surname].join(' ');
  }

  /// Ad SOYAD / Ünvan / Bölüm ayrı renkte — üçü tek bakışta ayrışsın diye.
  /// Ad SOYAD çağıranın temel stilini (ör. kalın) miras alır; ünvan ve bölüm
  /// kendi rengini taşır.
  TextSpan rowLabelSpan(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final children = <TextSpan>[TextSpan(text: nameSurnameUpper(context))];
    if (title.isNotEmpty) {
      children.add(
        TextSpan(text: ', $title', style: TextStyle(color: scheme.tertiary)),
      );
    }
    if (department.isNotEmpty) {
      children.add(
        TextSpan(
          text: ', $department',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    final d = loginDigit;
    if (d != null) {
      children.add(
        TextSpan(text: ' $d', style: TextStyle(color: scheme.onSurfaceVariant)),
      );
    }
    return TextSpan(children: children);
  }

  /// Sohbet balonu / başlık: "Ayşe Demir, Prof. Dr." (bölümsüz, rakamsız).
  String get namePlusTitle =>
      title.isEmpty ? fullName : '$fullName, $title';
}

/// KİŞİ LİSTELERİNİN ORTAK KURALI — tek yerde tanımlıdır, her liste bunu kullanır.
///
/// Kişiler her zaman **rol (kategori) başlıkları** altında, **admin'in tanımladığı
/// rol sırasında** listelenir (ör. Akademisyen → Öğrenci); her rolün içinde ada
/// göre sıralanır. Boş rol atlanır (başlık tek başına kalmaz).
///
/// **Rol satırda TEKRARLANMAZ:** başlıkta yazdığı için satırın alt-yazısı yalnız
/// bölüm/birimdir. ("AKADEMİSYEN" başlığının altında her satıra "Akademisyen ·
/// Bilgisayar Müh." yazmak aynı bilgiyi iki kez söylemektir.)
List<Widget> roleSections({
  required BuildContext context,
  required List<Member> members,
  required List<Role> roles,
  required String Function(Role) roleName,
  required Widget Function(Member) row,
  required Widget Function(String) header,
  String? otherLabel,
  // Verilirse her bölümün İÇİNDE bu kişiler üste sabitlenir (favoriler).
  bool Function(Member)? pinned,
  // Verilirse ve bir bölümün (tam) başlık etiketi için true dönerse, o
  // bölümün satırları gizlenir — başlık yine de eklenir (katlanır başlık).
  bool Function(String label)? collapsed,
}) {
  final out = <Widget>[];
  final known = <String>{};
  List<Member> order(List<Member> list) {
    final sorted = _byName(list);
    if (pinned == null) return sorted;
    return [
      ...sorted.where(pinned),
      ...sorted.where((m) => !pinned(m)),
    ];
  }

  for (final r in roles) {
    known.add(r.id);
    final inRole = order(members.where((m) => m.roleId == r.id).toList());
    if (inRole.isEmpty) continue;
    final label = '${roleName(r)} (${inRole.length})';
    out.add(header(label));
    if (collapsed != null && collapsed(label)) continue;
    out.addAll(inRole.map(row));
  }
  // Kurum rollerinde olmayan (beklenmez) üyeler en sona.
  final rest = order(members.where((m) => !known.contains(m.roleId)).toList());
  if (rest.isNotEmpty && otherLabel != null) {
    final label = '$otherLabel (${rest.length})';
    out.add(header(label));
    if (!(collapsed != null && collapsed(label))) {
      out.addAll(rest.map(row));
    }
  }
  return out;
}

List<Member> _byName(List<Member> list) {
  final sorted = [...list];
  sorted.sort(
    (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
  );
  return sorted;
}

/// Kişi listelerinin ortak bölüm başlığı.
class RoleHeader extends StatelessWidget {
  const RoleHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        context.upper(text),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
