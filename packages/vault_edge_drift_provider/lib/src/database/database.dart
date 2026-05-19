import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Profiles, Items, FileContents, Credentials, ConsentRecords],
)
/// Database class to access drift tables
class Database extends _$Database {
  /// Constructor
  Database(super.e);

  /// Returns the current schema version
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(consentRecords);
      }
    },
  );
}

/// Table definition to hold folders and files with a hierarchy
@DataClassName('Item')
class Items extends Table {
  /// An item identifier
  TextColumn get id => text().clientDefault(const Uuid().v4)();

  /// Profile id to which the item belongs
  TextColumn get profileId => text().references(Profiles, #id)();

  /// An item friendly name
  TextColumn get name => text()();

  /// Item parent id - defines the hierarchy
  TextColumn get parentId => text().nullable()();

  /// Item type - can be folder or file
  IntColumn get itemType => integer().map(const ItemTypeConverter())();

  /// Creation timestamp of the item.
  DateTimeColumn get createdAt => dateTime().clientDefault(clock.now)();

  /// Last modification timestamp of the item.
  DateTimeColumn get modifiedAt => dateTime().clientDefault(clock.now)();

  @override
  Set<Column> get primaryKey => {id};
}

/// ItemTypes can be of type folder or file
enum ItemType {
  /// an item of type File
  file(1),

  /// an item of type Folder
  folder(2);

  const ItemType(this.value);

  /// value used to persist in db
  final int value;
}

/// Converter from enum ItemType to an int
class ItemTypeConverter extends TypeConverter<ItemType, int> {
  /// Creates an instance of an [ItemTypeConverter]
  const ItemTypeConverter();

  @override
  ItemType fromSql(int fromDb) {
    return ItemType.values.firstWhere((type) => type.value == fromDb);
  }

  @override
  int toSql(ItemType value) {
    return value.value;
  }
}

/// Table definition to hold profiles
@DataClassName('Profile')
class Profiles extends Table {
  /// A profile identifier
  TextColumn get id => text().clientDefault(const Uuid().v4)();

  /// A profile name
  TextColumn get name => text()();

  /// A profile description
  TextColumn get description => text().nullable()();

  /// Account index
  IntColumn get accountIndex => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table definition to hold file content data
@DataClassName('FileContent')
class FileContents extends Table {
  /// A file content identifier - same as the file item id
  TextColumn get id => text().references(Items, #id)();

  /// The actual file content as a blob
  BlobColumn get content => blob()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table definition to hold credential data
@DataClassName('Credential')
class Credentials extends Table {
  /// A credential identifier
  TextColumn get id => text().clientDefault(const Uuid().v4)();

  /// Profile id to which the credential belongs
  TextColumn get profileId => text().references(Profiles, #id)();

  /// A credential friendly name
  TextColumn get name => text()();

  /// The actual credential data as a blob
  BlobColumn get content => blob()();

  /// Creation timestamp of the credential
  DateTimeColumn get createdAt => dateTime().clientDefault(clock.now)();

  /// Last modification timestamp of the credential
  DateTimeColumn get modifiedAt => dateTime().clientDefault(clock.now)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table definition to hold Iota OID4VP consent records.
@DataClassName('ConsentRecord')
class ConsentRecords extends Table {
  /// Hash of the share request: `sha1(clientId | presentationDefinition)`.
  ///
  /// Stable across repeat requests from the same verifier with the same PD.
  TextColumn get requestHash => text()();

  /// The holder's DID used to sign the Verifiable Presentation.
  TextColumn get did => text()();

  /// Full fingerprint of the share event.
  TextColumn get hash => text()();

  /// URL of the verifier's logo image, if available.
  TextColumn get logo => text().nullable()();

  /// Origin (base URL) of the verifier's site, if available.
  TextColumn get siteUrl => text().nullable()();

  /// ISO 8601 timestamp of when the share was first completed.
  TextColumn get sharedAt => text()();

  /// Display name of the profile used for this share.
  TextColumn get profileName => text()();

  /// Identifier of the profile used for this share.
  TextColumn get profileId => text()();

  /// The verifier's `client_id` from the OID4VP authorization request.
  TextColumn get clientId => text()();

  /// Whether the user has enabled automatic sharing for this verifier.
  BoolColumn get isAutoShareEnabled => boolean()();

  /// Identifiers of the shared VCs, stored as a comma-separated string.
  TextColumn get sharedVcIds => text()();

  /// Comma-separated list of VC types included in the VP.
  TextColumn get sharedVcTypesCsv => text()();

  @override
  Set<Column> get primaryKey => {requestHash, did};
}
