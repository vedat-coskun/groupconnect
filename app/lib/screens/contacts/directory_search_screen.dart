import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// Organization directory search & discovery with **multi-select bulk add**
/// (FR-12..FR-15, FR-22/FR-23).
///
/// Search by name / member-no / department, filter by role/department/course/
/// group, tick people (left-hand checkbox), Hepsini Seç / Temizle, then Kaydet
/// to add them all at once — each honouring their add-policy (authority = added
/// directly, basic role = approval invite). Phone numbers are never shown
/// (FR-15).
class DirectorySearchScreen extends StatefulWidget {
  const DirectorySearchScreen({super.key, this.initialGroupId});

  /// Optional pre-applied group filter (e.g. Kurum Yapısı → Toplu Ekle).
  final String? initialGroupId;

  @override
  State<DirectorySearchScreen> createState() => _DirectorySearchScreenState();
}

class _DirectorySearchScreenState extends State<DirectorySearchScreen> {
  String _query = '';
  String? _roleId;
  String? _department;
  String? _course;
  String? _groupId;
  bool _sortByNumber = false;

  /// Member ids ticked for bulk add. Kept across filter/search changes so the
  /// user can gather people from several filtered views before saving.
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _groupId = widget.initialGroupId; // Kurum Yapısı'ndan gelen ön-filtre.
  }

  Future<String?> _pickOption(
    String title,
    List<(String value, String label)> options,
  ) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder:
          (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  title: Text(context.s.all),
                  onTap: () => Navigator.pop(context, ''),
                ),
                for (final o in options)
                  ListTile(
                    title: Text(o.$2),
                    onTap: () => Navigator.pop(context, o.$1),
                  ),
              ],
            ),
          ),
    );
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  /// Add every ticked member, tallying direct adds vs approval invites, then
  /// pop back with a summary (FR-22/FR-23).
  void _save() {
    final state = AppScope.of(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final s = context.s;
    var added = 0, invited = 0;
    for (final id in _selected) {
      final r = state.addContact(id);
      if (r == AddResult.added) {
        added++;
      } else if (r == AddResult.invited) {
        invited++;
      }
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text(s.contactsAddedSummary(added, invited))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final tenant = state.activeTenant!;
    final results = state.directorySearch(
      query: _query,
      roleId: _roleId,
      department: _department,
      course: _course,
      groupId: _groupId,
      sortByNumber: _sortByNumber,
    );

    // Rows that can be ticked = shown results not already in contacts.
    final shownSelectable =
        results.where((m) => !state.isContact(m.id)).map((m) => m.id).toSet();
    final allSelected =
        shownSelectable.isNotEmpty && shownSelectable.every(_selected.contains);
    final anySelected = shownSelectable.any(_selected.contains);
    // Ana checkbox durumu: hepsi=true, hiçbiri=false, kısmi=null (çizgi).
    final bool? masterValue =
        !anySelected ? false : (allSelected ? true : null);

    void toggleAll() => setState(() {
      if (allSelected) {
        _selected.removeAll(shownSelectable);
      } else {
        _selected.addAll(shownSelectable);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(s.directoryTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: '${s.fullName} · ${s.memberNoLabel} · ${s.department}',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: s.filterRole,
                  value:
                      _roleId == null
                          ? null
                          : state.roleName(tenant.roleById(_roleId!)),
                  onTap: () async {
                    final v = await _pickOption(s.filterRole, [
                      for (final r in tenant.roles)
                        (r.id, state.roleName(r)),
                    ]);
                    if (v != null) {
                      setState(() => _roleId = v.isEmpty ? null : v);
                    }
                  },
                ),
                _FilterChip(
                  label: s.filterDepartment,
                  value: _department,
                  onTap: () async {
                    final v = await _pickOption(s.filterDepartment, [
                      for (final d in state.directoryDepartments) (d, d),
                    ]);
                    if (v != null) {
                      setState(() => _department = v.isEmpty ? null : v);
                    }
                  },
                ),
                _FilterChip(
                  label: s.filterCourse,
                  value: _course,
                  onTap: () async {
                    final v = await _pickOption(s.filterCourse, [
                      for (final c in state.directoryCourses) (c, c),
                    ]);
                    if (v != null) {
                      setState(() => _course = v.isEmpty ? null : v);
                    }
                  },
                ),
                _FilterChip(
                  label: s.filterGroup,
                  value:
                      _groupId == null
                          ? null
                          : state.td.group(_groupId!)?.name,
                  onTap: () async {
                    final v = await _pickOption(s.filterGroup, [
                      for (final g in state.filterGroups) (g.id, g.name),
                    ]);
                    if (v != null) {
                      setState(() => _groupId = v.isEmpty ? null : v);
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // "5 ara" yerine ana seç/kaldır checkbox'ı — satır
                // checkbox'larıyla aynı sütunda hizalı.
                SizedBox(
                  width: 40,
                  child: Checkbox(
                    tristate: true,
                    value: masterValue,
                    onChanged:
                        shownSelectable.isEmpty ? null : (_) => toggleAll(),
                  ),
                ),
                const Spacer(),
                // Sort toggle. "By number" only when enabled by the tenant.
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: [
                    ButtonSegment(value: false, label: Text(s.sortByName)),
                    if (tenant.numberSearchEnabled)
                      ButtonSegment(
                        value: true,
                        label: Text(s.sortByNumber),
                      ),
                  ],
                  selected: {_sortByNumber && tenant.numberSearchEnabled},
                  onSelectionChanged:
                      (v) => setState(() => _sortByNumber = v.first),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child:
                results.isEmpty
                    ? EmptyState(
                      icon: Icons.search_off,
                      title: s.noResults,
                    )
                    : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder:
                          (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, i) {
                        final m = results[i];
                        final role = state.roleOf(m);
                        final inContacts = state.isContact(m.id);
                        final selected = _selected.contains(m.id);
                        return ListTile(
                          // Row toggles selection; already-added rows are inert.
                          onTap: inContacts ? null : () => _toggle(m.id),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 40,
                                child:
                                    inContacts
                                        ? Icon(
                                          Icons.check_circle,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        )
                                        : Checkbox(
                                          value: selected,
                                          onChanged: (_) => _toggle(m.id),
                                        ),
                              ),
                              MemberAvatar(member: m),
                            ],
                          ),
                          title: Text(
                            m.rowLabel(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Arama sonucu: rol satırda kalır (alaka için).
                          subtitle: Text(
                            '${state.roleName(role)} · ${m.memberNo}',
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      // Toplu ekleme aksiyonu — yalnız seçim varken görünür.
      bottomNavigationBar:
          _selected.isEmpty
              ? null
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton(
                    onPressed: _save,
                    child: Text('${s.save} (${_selected.length})'),
                  ),
                ),
              ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = value != null;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: active,
        label: Text(active ? '$label: $value' : label),
        avatar: active ? null : const Icon(Icons.expand_more, size: 18),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
