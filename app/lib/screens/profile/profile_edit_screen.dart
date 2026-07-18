import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';

/// Kimlik kartı görünümü (FR-50). Adı "Profili Düzenle" olsa da burada
/// **düzenlenebilir hiçbir alan yoktur**: ad-soyad, üye no, bölüm ve rol
/// yöneticiye aittir ve üyeye salt-okunurdur (FR-58). Üyenin belirlediği tek
/// alan **profil fotoğrafı**dır ve o da Profil ekranından yönetilir. Bu yüzden
/// "Kaydet" butonu yoktur — kaydedilecek bir şey yok. Telefon no internal'dır,
/// hiçbir ekranda gösterilmez (NFR-5).
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _memberNo;
  late final TextEditingController _department;
  late String _roleId;

  @override
  void initState() {
    super.initState();
    final me = AppScope.of(context, listen: false).me;
    _name = TextEditingController(text: me.fullName);
    _memberNo = TextEditingController(text: me.memberNo);
    _department = TextEditingController(text: me.department);
    _roleId = me.roleId;
  }

  @override
  void dispose() {
    _name.dispose();
    _memberNo.dispose();
    _department.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.editProfile)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Kimlik alanları admin'e ait — kullanıcı görüntüler, değiştiremez.
          TextField(
            controller: _name,
            enabled: false,
            decoration: InputDecoration(labelText: s.fullName),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _memberNo,
            enabled: false,
            decoration: InputDecoration(labelText: s.memberNo),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _department,
            enabled: false,
            decoration: InputDecoration(labelText: s.department),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _roleId,
            decoration: InputDecoration(labelText: s.role),
            items: [
              for (final r in state.tenantRoles)
                DropdownMenuItem(
                  value: r.id,
                  child: Text(state.roleName(r)),
                ),
            ],
            // Rol admin tarafından atanır — değiştirilemez (disabled).
            onChanged: null,
          ),
        ],
      ),
    );
  }
}
