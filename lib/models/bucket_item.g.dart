// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bucket_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBucketItemCollection on Isar {
  IsarCollection<BucketItem> get bucketItems => this.collection();
}

const BucketItemSchema = CollectionSchema(
  name: r'BucketItem',
  id: 2428134091996516569,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'doneAt': PropertySchema(
      id: 1,
      name: r'doneAt',
      type: IsarType.dateTime,
    ),
    r'personId': PropertySchema(
      id: 2,
      name: r'personId',
      type: IsarType.long,
    ),
    r'sourceQuestionId': PropertySchema(
      id: 3,
      name: r'sourceQuestionId',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 4,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _bucketItemEstimateSize,
  serialize: _bucketItemSerialize,
  deserialize: _bucketItemDeserialize,
  deserializeProp: _bucketItemDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _bucketItemGetId,
  getLinks: _bucketItemGetLinks,
  attach: _bucketItemAttach,
  version: '3.1.0+1',
);

int _bucketItemEstimateSize(
  BucketItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.sourceQuestionId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _bucketItemSerialize(
  BucketItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeDateTime(offsets[1], object.doneAt);
  writer.writeLong(offsets[2], object.personId);
  writer.writeString(offsets[3], object.sourceQuestionId);
  writer.writeString(offsets[4], object.title);
}

BucketItem _bucketItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BucketItem();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.doneAt = reader.readDateTimeOrNull(offsets[1]);
  object.id = id;
  object.personId = reader.readLongOrNull(offsets[2]);
  object.sourceQuestionId = reader.readStringOrNull(offsets[3]);
  object.title = reader.readString(offsets[4]);
  return object;
}

P _bucketItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _bucketItemGetId(BucketItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _bucketItemGetLinks(BucketItem object) {
  return [];
}

void _bucketItemAttach(IsarCollection<dynamic> col, Id id, BucketItem object) {
  object.id = id;
}

extension BucketItemQueryWhereSort
    on QueryBuilder<BucketItem, BucketItem, QWhere> {
  QueryBuilder<BucketItem, BucketItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BucketItemQueryWhere
    on QueryBuilder<BucketItem, BucketItem, QWhereClause> {
  QueryBuilder<BucketItem, BucketItem, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<BucketItem, BucketItem, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension BucketItemQueryFilter
    on QueryBuilder<BucketItem, BucketItem, QFilterCondition> {
  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> doneAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'doneAt',
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      doneAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'doneAt',
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> doneAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'doneAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> doneAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'doneAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> doneAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'doneAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> doneAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'doneAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> personIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'personId',
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      personIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'personId',
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> personIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personId',
        value: value,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      personIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'personId',
        value: value,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> personIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'personId',
        value: value,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> personIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'personId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      sourceQuestionIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sourceQuestionId',
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      sourceQuestionIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sourceQuestionId',
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      sourceQuestionIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceQuestionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      sourceQuestionIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceQuestionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      sourceQuestionIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceQuestionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      sourceQuestionIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceQuestionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      sourceQuestionIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceQuestionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      sourceQuestionIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceQuestionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      sourceQuestionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceQuestionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      sourceQuestionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceQuestionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      sourceQuestionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceQuestionId',
        value: '',
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      sourceQuestionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceQuestionId',
        value: '',
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension BucketItemQueryObject
    on QueryBuilder<BucketItem, BucketItem, QFilterCondition> {}

extension BucketItemQueryLinks
    on QueryBuilder<BucketItem, BucketItem, QFilterCondition> {}

extension BucketItemQuerySortBy
    on QueryBuilder<BucketItem, BucketItem, QSortBy> {
  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> sortByDoneAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'doneAt', Sort.asc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> sortByDoneAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'doneAt', Sort.desc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> sortByPersonId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.asc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> sortByPersonIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.desc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> sortBySourceQuestionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceQuestionId', Sort.asc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy>
      sortBySourceQuestionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceQuestionId', Sort.desc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension BucketItemQuerySortThenBy
    on QueryBuilder<BucketItem, BucketItem, QSortThenBy> {
  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> thenByDoneAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'doneAt', Sort.asc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> thenByDoneAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'doneAt', Sort.desc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> thenByPersonId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.asc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> thenByPersonIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.desc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> thenBySourceQuestionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceQuestionId', Sort.asc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy>
      thenBySourceQuestionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceQuestionId', Sort.desc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension BucketItemQueryWhereDistinct
    on QueryBuilder<BucketItem, BucketItem, QDistinct> {
  QueryBuilder<BucketItem, BucketItem, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<BucketItem, BucketItem, QDistinct> distinctByDoneAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'doneAt');
    });
  }

  QueryBuilder<BucketItem, BucketItem, QDistinct> distinctByPersonId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personId');
    });
  }

  QueryBuilder<BucketItem, BucketItem, QDistinct> distinctBySourceQuestionId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceQuestionId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BucketItem, BucketItem, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension BucketItemQueryProperty
    on QueryBuilder<BucketItem, BucketItem, QQueryProperty> {
  QueryBuilder<BucketItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BucketItem, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<BucketItem, DateTime?, QQueryOperations> doneAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'doneAt');
    });
  }

  QueryBuilder<BucketItem, int?, QQueryOperations> personIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personId');
    });
  }

  QueryBuilder<BucketItem, String?, QQueryOperations>
      sourceQuestionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceQuestionId');
    });
  }

  QueryBuilder<BucketItem, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}
