// Davet kabul modeli (kullanıcı hükmü 2026-08-02):
//  - RET → hiçbir rehbere eklenmez.
//  - TEK YÖNLÜ kabul → davet eden beni AKTİF alır; ben onu yalnız PASİF alırım.
//  - ÇİFT YÖNLÜ kabul → ikimiz de birbirimizi AKTİF alırız.
// Ayrıca: kabul HER durumda davet edeni değil, "davet edeni kabul edileni"
// mantığıyla davet edenin aktif rehberine yazar (tekrar-davet döngüsü biter).
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/models/enums.dart';
import 'package:groupconnect/models/models.dart';
import 'package:groupconnect/state/app_state.dart';

Invitation _incoming(String id, String from, String to) => Invitation(
  id: id,
  kind: InviteKind.contact,
  direction: InviteDirection.incoming,
  fromMemberId: from,
  toMemberId: to,
);

void main() {
  test('ret → rehbere hiç eklemez', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555504'); // Merve
    s.selectTenant('uni');
    final inv = _incoming('r', 'u_can', 'u_merve');
    s.td.invitations.add(inv);
    s.rejectInvite(inv);
    expect(inv.status, InviteStatus.rejected);
    expect(s.isContact('u_can'), isFalse);
    expect(s.isPassive('u_can'), isFalse);
  });

  test('tek yönlü kabul → ben PASİF, davet eden beni AKTİF alır', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555504'); // Merve
    s.selectTenant('uni');
    final inv = _incoming('o', 'u_can', 'u_merve');
    s.td.invitations.add(inv);
    s.acceptInvite(inv, mutual: false);

    // Merve: u_can aktif DEĞİL, pasif.
    expect(s.isContact('u_can'), isFalse);
    expect(s.isPassive('u_can'), isTrue);
    expect(s.passiveContacts.map((m) => m.id), contains('u_can'));

    // Davet eden Arda (u_can): Merve'yi AKTİF almış.
    s.logout();
    s.setPendingPhone('+90', '5555555503'); // Arda
    s.selectTenant('uni');
    expect(s.isContact('u_merve'), isTrue);
  });

  test('çift yönlü kabul → ben de AKTİF alırım', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555504'); // Merve
    s.selectTenant('uni');
    final inv = _incoming('m', 'u_ayse', 'u_merve');
    s.td.invitations.add(inv);
    s.acceptInvite(inv, mutual: true);
    expect(s.isContact('u_ayse'), isTrue);
    expect(s.isPassive('u_ayse'), isFalse);
  });
}
