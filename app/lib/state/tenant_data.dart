import '../models/models.dart';

/// All state for a single tenant (organization), kept as an isolated island so
/// that cross-tenant leakage is impossible by construction (FR-7, NFR-6).
///
/// Switching the active organization simply swaps which [TenantData] the UI
/// reads; nothing is shared between two instances.
class TenantData {
  TenantData({
    required this.tenant,
    required this.myId,
    required this.members,
    required this.groups,
    required this.invitations,
    Map<String, List<Message>>? threads,
    List<String>? contactIds,
    Set<String>? favoriteIds,
    Set<String>? favoriteGroupIds,
    Set<String>? blockedIds,
    Map<String, String>? notes,
    Set<String>? dmVisible,
    Set<String>? mutedDms,
    this.profileComplete = false,
  }) : threads = threads ?? {},
       contactIds = contactIds ?? [],
       favoriteIds = favoriteIds ?? {},
       favoriteGroupIds = favoriteGroupIds ?? {},
       blockedIds = blockedIds ?? {},
       notes = notes ?? {},
       dmVisible = dmVisible ?? {},
       mutedDms = mutedDms ?? {};

  final Tenant tenant;

  /// The current user's own [Member] id within this tenant. Mutable so the
  /// prototype can switch the logged-in identity by phone (MockData.identities).
  String myId;

  /// Directory: every member the admin provisioned, including [myId]
  /// (FR-12). Always populated.
  final Map<String, Member> members;

  final List<Group> groups;
  final List<Invitation> invitations;


  /// Message store, keyed by thread id (`dm:<memberId>` / `grp:<groupId>`).
  final Map<String, List<Message>> threads;

  /// Personal contacts / rehber. Starts **empty** for the current user
  /// (FR-20); grows as they add people through discovery.
  final List<String> contactIds;

  final Set<String> favoriteIds; // FR-54
  final Set<String> favoriteGroupIds; // favori gruplar
  final Set<String> blockedIds; // FR-18, FR-53
  final Map<String, String> notes; // FR-24: rehber owner's notes
  final Set<String> dmVisible; // 1:1 threads surfaced in the chat list
  final Set<String> mutedDms; // FR-49 for 1:1 threads

  /// False until the first-login profile setup is confirmed (FR-9).
  bool profileComplete;

  Member get me => members[myId]!;
  Member? member(String id) => members[id];
  Group? group(String id) {
    for (final g in groups) {
      if (g.id == id) return g;
    }
    return null;
  }
}
