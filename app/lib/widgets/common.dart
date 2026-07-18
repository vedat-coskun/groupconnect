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
  String rowLabel(BuildContext context) {
    final parts = fullName.trim().split(RegExp(r'\s+')).toList();
    final surname = parts.isEmpty ? '' : context.upper(parts.removeLast());
    final name = [...parts, surname].join(' ');
    final buf = StringBuffer(name);
    if (title.isNotEmpty) buf.write(', $title');
    if (department.isNotEmpty) buf.write(', $department');
    final d = loginDigit;
    if (d != null) buf.write(' $d');
    return buf.toString();
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
    out.add(header('${roleName(r)} (${inRole.length})'));
    out.addAll(inRole.map(row));
  }
  // Kurum rollerinde olmayan (beklenmez) üyeler en sona.
  final rest = order(members.where((m) => !known.contains(m.roleId)).toList());
  if (rest.isNotEmpty && otherLabel != null) {
    out.add(header('$otherLabel (${rest.length})'));
    out.addAll(rest.map(row));
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
