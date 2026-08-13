import 'package:equatable/equatable.dart';

/// A label in both languages, exactly as the server sends it.
///
/// Not a `LocaleKeys` lookup: these strings name *resources and actions the
/// server declares*, which a client build cannot know in advance. That is the
/// whole point of the module — a backend that starts guarding invoices tomorrow
/// gets a labelled "Invoices" card in a build shipped today, and no translation
/// file needs editing here.
class LocalizedLabel extends Equatable {
  const LocalizedLabel({required this.ar, required this.en});

  final String ar;
  final String en;

  /// Picks by language code, falling back to English for anything else — an
  /// app that adds a third locale sees English, not an empty string.
  String resolve(String languageCode) => languageCode == 'ar' ? ar : en;

  @override
  List<Object?> get props => [ar, en];
}

/// One permission, as the roles screen renders it.
class PermissionDescriptor extends Equatable {
  const PermissionDescriptor({
    required this.key,
    required this.action,
    required this.label,
    required this.labelInferred,
    required this.implies,
    required this.synthetic,
  });

  /// `notes.update` — what a grant stores and what `requirePermission` checks.
  final String key;
  final String action;
  final LocalizedLabel label;

  /// The server guessed this label from the action name. Rendered normally; an
  /// audit screen can list what still needs real wording.
  final bool labelInferred;

  /// Keys this one grants on its own, so a tick's real consequence is shown
  /// **before** it is saved rather than discovered afterwards.
  final List<String> implies;

  /// The `*.manage` master switch, which no route declares.
  ///
  /// Rendered differently on purpose: ticking it means "everything on this
  /// resource, **including actions added next year**", which is a different
  /// promise from ticking every box currently on screen.
  final bool synthetic;

  @override
  List<Object?> get props => [key, action, label, labelInferred, implies, synthetic];
}

/// Every permission of one resource — one card in the roles screen.
class PermissionGroup extends Equatable {
  const PermissionGroup({
    required this.resource,
    required this.label,
    required this.labelInferred,
    required this.permissions,
  });

  final String resource;
  final LocalizedLabel label;
  final bool labelInferred;
  final List<PermissionDescriptor> permissions;

  @override
  List<Object?> get props => [resource, label, labelInferred, permissions];
}

/// The whole vocabulary this server enforces.
///
/// **Nothing in this app enumerates permissions.** The catalog is fetched, and
/// the roles screen is drawn from it — which is why a new guarded feature costs
/// zero Dart, and why a feature deleted server-side stops appearing here
/// without anyone remembering to remove it.
class PermissionCatalog extends Equatable {
  const PermissionCatalog({required this.groups, required this.enforced});

  final List<PermissionGroup> groups;

  /// Whether the server enforces anything yet. When false the roles screen says
  /// so — grants are recorded but nothing is refused, and a deployment
  /// mid-rollout otherwise looks like a broken one.
  final bool enforced;

  /// Every key in the catalog, synthetic `manage` entries included.
  Set<String> get allKeys =>
      groups.expand((g) => g.permissions).map((p) => p.key).toSet();

  @override
  List<Object?> get props => [groups, enforced];
}
