// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browser_profile_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBrowserProfileModelCollection on Isar {
  IsarCollection<BrowserProfileModel> get browserProfileModels =>
      this.collection();
}

const BrowserProfileModelSchema = CollectionSchema(
  name: r'BrowserProfileModel',
  id: -8103795997896669691,
  properties: {
    r'cookiesJson': PropertySchema(
      id: 0,
      name: r'cookiesJson',
      type: IsarType.string,
    ),
    r'lastUsed': PropertySchema(
      id: 1,
      name: r'lastUsed',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(id: 2, name: r'name', type: IsarType.string),
    r'platform': PropertySchema(
      id: 3,
      name: r'platform',
      type: IsarType.string,
    ),
    r'sessionState': PropertySchema(
      id: 4,
      name: r'sessionState',
      type: IsarType.string,
    ),
    r'userDataDir': PropertySchema(
      id: 5,
      name: r'userDataDir',
      type: IsarType.string,
    ),
  },
  estimateSize: _browserProfileModelEstimateSize,
  serialize: _browserProfileModelSerialize,
  deserialize: _browserProfileModelDeserialize,
  deserializeProp: _browserProfileModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {
    r'googleAccount': LinkSchema(
      id: 6302418318429302898,
      name: r'googleAccount',
      target: r'GoogleAccountModel',
      single: true,
    ),
  },
  embeddedSchemas: {},
  getId: _browserProfileModelGetId,
  getLinks: _browserProfileModelGetLinks,
  attach: _browserProfileModelAttach,
  version: '3.1.0+1',
);

int _browserProfileModelEstimateSize(
  BrowserProfileModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.cookiesJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.platform.length * 3;
  {
    final value = object.sessionState;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userDataDir.length * 3;
  return bytesCount;
}

void _browserProfileModelSerialize(
  BrowserProfileModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cookiesJson);
  writer.writeDateTime(offsets[1], object.lastUsed);
  writer.writeString(offsets[2], object.name);
  writer.writeString(offsets[3], object.platform);
  writer.writeString(offsets[4], object.sessionState);
  writer.writeString(offsets[5], object.userDataDir);
}

BrowserProfileModel _browserProfileModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BrowserProfileModel();
  object.cookiesJson = reader.readStringOrNull(offsets[0]);
  object.id = id;
  object.lastUsed = reader.readDateTimeOrNull(offsets[1]);
  object.name = reader.readString(offsets[2]);
  object.platform = reader.readString(offsets[3]);
  object.sessionState = reader.readStringOrNull(offsets[4]);
  object.userDataDir = reader.readString(offsets[5]);
  return object;
}

P _browserProfileModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _browserProfileModelGetId(BrowserProfileModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _browserProfileModelGetLinks(
  BrowserProfileModel object,
) {
  return [object.googleAccount];
}

void _browserProfileModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  BrowserProfileModel object,
) {
  object.id = id;
  object.googleAccount.attach(
    col,
    col.isar.collection<GoogleAccountModel>(),
    r'googleAccount',
    id,
  );
}

extension BrowserProfileModelByIndex on IsarCollection<BrowserProfileModel> {
  Future<BrowserProfileModel?> getByName(String name) {
    return getByIndex(r'name', [name]);
  }

  BrowserProfileModel? getByNameSync(String name) {
    return getByIndexSync(r'name', [name]);
  }

  Future<bool> deleteByName(String name) {
    return deleteByIndex(r'name', [name]);
  }

  bool deleteByNameSync(String name) {
    return deleteByIndexSync(r'name', [name]);
  }

  Future<List<BrowserProfileModel?>> getAllByName(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndex(r'name', values);
  }

  List<BrowserProfileModel?> getAllByNameSync(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'name', values);
  }

  Future<int> deleteAllByName(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'name', values);
  }

  int deleteAllByNameSync(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'name', values);
  }

  Future<Id> putByName(BrowserProfileModel object) {
    return putByIndex(r'name', object);
  }

  Id putByNameSync(BrowserProfileModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'name', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByName(List<BrowserProfileModel> objects) {
    return putAllByIndex(r'name', objects);
  }

  List<Id> putAllByNameSync(
    List<BrowserProfileModel> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'name', objects, saveLinks: saveLinks);
  }
}

extension BrowserProfileModelQueryWhereSort
    on QueryBuilder<BrowserProfileModel, BrowserProfileModel, QWhere> {
  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BrowserProfileModelQueryWhere
    on QueryBuilder<BrowserProfileModel, BrowserProfileModel, QWhereClause> {
  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterWhereClause>
  nameEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'name', value: [name]),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterWhereClause>
  nameNotEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'name',
                lower: [],
                upper: [name],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'name',
                lower: [name],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'name',
                lower: [name],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'name',
                lower: [],
                upper: [name],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension BrowserProfileModelQueryFilter
    on
        QueryBuilder<
          BrowserProfileModel,
          BrowserProfileModel,
          QFilterCondition
        > {
  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  cookiesJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'cookiesJson'),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  cookiesJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'cookiesJson'),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  cookiesJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cookiesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  cookiesJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cookiesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  cookiesJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cookiesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  cookiesJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cookiesJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  cookiesJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cookiesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  cookiesJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cookiesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  cookiesJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cookiesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  cookiesJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cookiesJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  cookiesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cookiesJson', value: ''),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  cookiesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cookiesJson', value: ''),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  lastUsedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastUsed'),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  lastUsedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastUsed'),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  lastUsedEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUsed', value: value),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  lastUsedGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastUsed',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  lastUsedLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastUsed',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  lastUsedBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastUsed',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  nameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  nameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  nameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  platformEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'platform',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  platformGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'platform',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  platformLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'platform',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  platformBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'platform',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  platformStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'platform',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  platformEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'platform',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  platformContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'platform',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  platformMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'platform',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  platformIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'platform', value: ''),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  platformIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'platform', value: ''),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  sessionStateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sessionState'),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  sessionStateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sessionState'),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  sessionStateEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sessionState',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  sessionStateGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sessionState',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  sessionStateLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sessionState',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  sessionStateBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sessionState',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  sessionStateStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sessionState',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  sessionStateEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sessionState',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  sessionStateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sessionState',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  sessionStateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sessionState',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  sessionStateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sessionState', value: ''),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  sessionStateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sessionState', value: ''),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  userDataDirEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userDataDir',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  userDataDirGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userDataDir',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  userDataDirLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userDataDir',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  userDataDirBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userDataDir',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  userDataDirStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userDataDir',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  userDataDirEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userDataDir',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  userDataDirContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userDataDir',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  userDataDirMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userDataDir',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  userDataDirIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userDataDir', value: ''),
      );
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  userDataDirIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userDataDir', value: ''),
      );
    });
  }
}

extension BrowserProfileModelQueryObject
    on
        QueryBuilder<
          BrowserProfileModel,
          BrowserProfileModel,
          QFilterCondition
        > {}

extension BrowserProfileModelQueryLinks
    on
        QueryBuilder<
          BrowserProfileModel,
          BrowserProfileModel,
          QFilterCondition
        > {
  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  googleAccount(FilterQuery<GoogleAccountModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'googleAccount');
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterFilterCondition>
  googleAccountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'googleAccount', 0, true, 0, true);
    });
  }
}

extension BrowserProfileModelQuerySortBy
    on QueryBuilder<BrowserProfileModel, BrowserProfileModel, QSortBy> {
  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  sortByCookiesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cookiesJson', Sort.asc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  sortByCookiesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cookiesJson', Sort.desc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  sortByLastUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsed', Sort.asc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  sortByLastUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsed', Sort.desc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  sortByPlatform() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.asc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  sortByPlatformDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.desc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  sortBySessionState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionState', Sort.asc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  sortBySessionStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionState', Sort.desc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  sortByUserDataDir() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userDataDir', Sort.asc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  sortByUserDataDirDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userDataDir', Sort.desc);
    });
  }
}

extension BrowserProfileModelQuerySortThenBy
    on QueryBuilder<BrowserProfileModel, BrowserProfileModel, QSortThenBy> {
  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  thenByCookiesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cookiesJson', Sort.asc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  thenByCookiesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cookiesJson', Sort.desc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  thenByLastUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsed', Sort.asc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  thenByLastUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsed', Sort.desc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  thenByPlatform() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.asc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  thenByPlatformDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.desc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  thenBySessionState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionState', Sort.asc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  thenBySessionStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionState', Sort.desc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  thenByUserDataDir() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userDataDir', Sort.asc);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QAfterSortBy>
  thenByUserDataDirDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userDataDir', Sort.desc);
    });
  }
}

extension BrowserProfileModelQueryWhereDistinct
    on QueryBuilder<BrowserProfileModel, BrowserProfileModel, QDistinct> {
  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QDistinct>
  distinctByCookiesJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cookiesJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QDistinct>
  distinctByLastUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUsed');
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QDistinct>
  distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QDistinct>
  distinctByPlatform({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'platform', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QDistinct>
  distinctBySessionState({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionState', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BrowserProfileModel, BrowserProfileModel, QDistinct>
  distinctByUserDataDir({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userDataDir', caseSensitive: caseSensitive);
    });
  }
}

extension BrowserProfileModelQueryProperty
    on QueryBuilder<BrowserProfileModel, BrowserProfileModel, QQueryProperty> {
  QueryBuilder<BrowserProfileModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BrowserProfileModel, String?, QQueryOperations>
  cookiesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cookiesJson');
    });
  }

  QueryBuilder<BrowserProfileModel, DateTime?, QQueryOperations>
  lastUsedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUsed');
    });
  }

  QueryBuilder<BrowserProfileModel, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<BrowserProfileModel, String, QQueryOperations>
  platformProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'platform');
    });
  }

  QueryBuilder<BrowserProfileModel, String?, QQueryOperations>
  sessionStateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionState');
    });
  }

  QueryBuilder<BrowserProfileModel, String, QQueryOperations>
  userDataDirProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userDataDir');
    });
  }
}
