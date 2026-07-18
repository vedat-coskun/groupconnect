/// Domain enumerations for the GroupConnect member app.
///
/// These types encode the locked requirement decisions so the rest of the UI
/// can reason about them in a type-safe way. See docs/requirements.md.
library;

/// UI language. At least Turkish and English are required (FR-11, NFR-15).
enum AppLanguage { tr, en }

/// Directory visibility of a member (FR-16, FR-17, FR-51).
///
/// A [hidden] member cannot be found in discovery/search.
enum MemberVisibility { visible, hidden }

/// Policy that governs how *this* member may be added to someone's personal
/// contacts (FR-22, FR-23, FR-52).
///
/// * [everyone] – can be added directly after discovery (authority roles such
///   as academics default to this).
/// * [approval] – requires the member to approve an invitation first (basic
///   roles such as students default to this).
enum AddPolicy { everyone, approval }

/// The two — and only two — kinds of group (FR-34..FR-41).
///
/// * [organized] – created and membership-managed by the Organization Admin.
///   Members cannot self-join or self-leave (FR-35).
/// * private – created by a member who becomes its Group Admin (FR-37).
enum GroupType { organized, private }

/// Kind of invitation (FR-28, FR-38).
enum InviteKind { contact, group }

/// Direction of an invitation relative to the current user.
enum InviteDirection { incoming, outgoing }

/// Lifecycle status of an invitation.
enum InviteStatus { pending, accepted, rejected }
