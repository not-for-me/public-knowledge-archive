# ODCS (Open Data Contract Standard) — 전체 스펙

> **Open Data Contract Standard v3.1.0**  
> **재단:** LF AI & Data Foundation (Linux Foundation)  
> **라이선스:** Apache 2.0  
> **깃허브:** https://github.com/bitol-io/open-data-contract-standard  
> **공식 문서:** https://bitol-io.github.io/open-data-contract-standard/v3.1.0/  
> **MIME 타입:** `application/odcs+yaml;version=3.1.0`

---

## 목차

1. [Fundamentals (기본 정보)](#1-fundamentals-기본-정보)
2. [Schema (스키마)](#2-schema-스키마)
3. [References (참조)](#3-references-참조)
4. [Data Quality (데이터 품질)](#4-data-quality-데이터-품질)
5. [Support & Communication Channels (지원 채널)](#5-support--communication-channels-지원-채널)
6. [Pricing (가격)](#6-pricing-가격)
7. [Team (팀)](#7-team-팀)
8. [Roles (역할 및 접근 권한)](#8-roles-역할-및-접근-권한)
9. [Service-Level Agreement (SLA)](#9-service-level-agreement-sla)
10. [Infrastructures & Servers (인프라 및 서버)](#10-infrastructures--servers-인프라-및-서버)
11. [Custom & Other Properties (커스텀 속성)](#11-custom--other-properties-커스텀-속성)
12. [Full Example (전체 예제)](#12-full-example-전체-예제)

---

## 1. Fundamentals (기본 정보)

컨트랙트 자체를 식별하고 설명하는 메타데이터 섹션입니다. 초기 버전에서는 `demographics`라고 불렸습니다.

### 예제

```yaml
apiVersion: v3.1.0
kind: DataContract

id: 53581432-6c55-4ba2-a65f-72344a91553a
name: seller_payments_v1
version: 1.1.0
status: active
domain: seller
tenant: ClimateQuantumInc

description:
  purpose: Views built on top of the seller tables.
  limitations: Cannot be used in conjunction with days with full moons.
  usage: Twice a day, preferable before meals.

tags: ['finance']
```

### 필드 정의

| 키 | 타입 | 필수 | 설명 |
|----|------|------|------|
| `apiVersion` | string | ✅ | 표준 버전 (현재 `v3.1.0`) |
| `kind` | string | ✅ | 고정값: `DataContract` |
| `id` | string | ✅ | UUID 등 고유 식별자 |
| `name` | string | ❌ | 컨트랙트 이름 |
| `version` | string | ✅ | 컨트랙트 자체 버전 |
| `status` | string | ✅ | `proposed`, `draft`, `active`, `deprecated`, `retired` |
| `tenant` | string | ❌ | 데이터가 속한 테넌트 (대소문자 구분 없음) |
| `domain` | string | ❌ | 논리적 데이터 도메인 이름 |
| `~~dataProduct~~` | string | ❌ | **v3.1.0부터 DEPRECATED** |
| `authoritativeDefinitions` | array | ❌ | 외부 정의 링크 목록 |
| `description.purpose` | string | ❌ | 데이터 제공 목적 |
| `description.limitations` | string | ❌ | 기술/규정/법적 제한사항 |
| `description.usage` | string | ❌ | 권장 사용법 |
| `tags` | array | ❌ | 태그 목록 |

---

## 2. Schema (스키마)

데이터 모델의 논리적/물리적 표현을 정의하는 핵심 섹션입니다.

### 용어

- **Object** — 데이터 구조 단위 (RDBMS의 테이블, NoSQL의 문서)
- **Property** — Object의 속성 (컬럼, 필드)
- **Element** — Object 또는 Property의 통칭

### 예제: 완전한 스키마

```yaml
schema:
  - id: tbl_obj
    name: tbl
    logicalType: object
    physicalType: table
    physicalName: tbl_1
    description: Provides core payment metrics
    dataGranularityDescription: Aggregation on columns txn_ref_dt, pmt_txn_id
    tags: ['finance']
    authoritativeDefinitions:
      - url: https://catalog.data.gov/dataset/air-quality
        type: businessDefinition
    properties:
      - id: txn_ref_dt_prop
        name: txn_ref_dt
        businessName: transaction reference date
        logicalType: date
        physicalType: date
        partitioned: true
        partitionKeyPosition: 1
        classification: public
        examples: [2022-10-03, 2020-01-28]
      - id: rcvr_id_prop
        name: rcvr_id
        primaryKey: true
        primaryKeyPosition: 1
        logicalType: string
        physicalType: varchar(18)
        classification: restricted
```

### 모든 Element 공통 필드

| 키 | 타입 | 필수 | 설명 |
|----|------|------|------|
| `id` | string | ❌ | 안전 참조용 고유 식별자 |
| `name` | string | ✅ | Element 이름 |
| `physicalName` | string | ❌ | 소스에서의 물리적 이름 |
| `physicalType` | string | ❌ | 소스 데이터 타입 (`VARCHAR(2)`, `table`) |
| `description` | string | ❌ | 설명 |
| `businessName` | string | ❌ | 비즈니스 친화적 이름 |
| `authoritativeDefinitions` | array | ❌ | 외부 정의 링크 |
| `quality` | array | ❌ | 데이터 품질 속성 |
| `tags` | array | ❌ | 태그 |
| `customProperties` | array | ❌ | 비표준 속성 |

### Object 전용 필드

| 키 | 타입 | 필수 | 설명 |
|----|------|------|------|
| `logicalType` | string | ❌ | `object` (고정) |
| `physicalType` | string | ❌ | `table`, `topic`, `file` 등 |
| `dataGranularityDescription` | string | ❌ | 데이터 세분성 설명 |

### Property 전용 필드

| 키 | 타입 | 필수 | 설명 |
|----|------|------|------|
| `logicalType` | string | ❌ | `string`, `date`, `timestamp`, `time`, `number`, `integer`, `object`, `array`, `boolean` |
| `logicalTypeOptions` | object | ❌ | 타입별 추가 메타데이터 |
| `physicalType` | string | ❌ | 물리적 데이터 타입 |
| `primaryKey` | boolean | ❌ | 기본키 여부 |
| `primaryKeyPosition` | integer | ❌ | 복합키 순서 (1부터 시작) |
| `required` | boolean | ❌ | Nullable 여부 |
| `unique` | boolean | ❌ | 유일성 제약 |
| `partitioned` | boolean | ❌ | 파티션 여부 |
| `partitionKeyPosition` | integer | ❌ | 파티션 키 순서 |
| `classification` | string | ❌ | `public`, `restricted`, `confidential`, `internal` |
| `encryptedName` | string | ❌ | 암호화된 컬럼 이름 |
| `examples` | array | ❌ | 예시 값 |
| `transformSourceObjects` | array | ❌ | 변환 원천 객체 |
| `transformLogic` | string | ❌ | 변환 로직 |
| `relationships` | array | ❌ | 외래키 관계 (아래 References 섹션 참조) |

### logicalTypeOptions 세부

| logicalType | Options | 설명 |
|-------------|---------|------|
| `string` | `format`, `minLength`, `maxLength`, `pattern`, `enum` | 문자열 제약 |
| `number` | `min`, `max`, `exclusiveMin`, `exclusiveMax` | 숫자 범위 |
| `integer` | `min`, `max` | 정수 범위 |
| `date` | `format` | 날짜 포맷 |
| `timestamp` | `format` | 타임스탬프 포맷 |
| `array` | `items` (하위 logicalType 지정) | 배열 아이템 타입 |
| `object` | `properties` | 중첩 객체 |

### 배열 예제

```yaml
# 단순 배열
schema:
  - name: AnObject
    logicalType: object
    properties:
      - name: street_lines
        logicalType: array
        items:
          logicalType: string

# 객체 배열
schema:
  - name: AnotherObject
    logicalType: object
    properties:
      - name: x
        logicalType: array
        items:
          logicalType: object
          properties:
            - name: id
              logicalType: string
            - name: zip
              logicalType: string
```

---

## 3. References (참조)

컨트랙트 내/외부 요소를 참조하는 메커니즘입니다.  
**v3.1.0에서는 외래키 관계(Foreign Key)에 대해서만 지원됩니다.**

### 참조 표기법

#### 정규 표기법 (권장)
- `id` 필드 기반, slash로 구분
- 이름 변경/리팩토링에도 안전
- `schema/customers_tbl/properties/cust_id_pk`

#### 약식 표기법
- `name` 필드 기반, dot으로 구분
- 간단한 컨트랙트에 적합
- `users.id`

### 외부 컨트랙트 참조

```yaml
# 동일 폴더
data-contract-v1.yaml#/schema/users_tbl

# URL
https://example.com/data-contract-v1.yaml#/schema/users_tbl
```

### Foreign Key 관계 정의

**Property 레벨** (from이 암시적):
```yaml
properties:
  - id: user_id_field
    name: user_id
    relationships:
      - to: schema/accounts_tbl/properties/owner_id_field
```

**Schema 레벨** (from과 to 모두 명시):
```yaml
schema:
  - id: users_tbl
    relationships:
      - from: schema/users_tbl/properties/user_account_id
        to: schema/accounts_tbl/properties/acct_id_pk
        type: foreignKey
```

### 규칙
- `from`과 `to`는 타입 일관성 유지 (둘 다 string 또는 둘 다 array)
- 배열(복합키) 사용 시 두 배열의 요소 수가 같아야 함
- Property 레벨에서 `from`은 금지 (암시적)

---

## 4. Data Quality (데이터 품질)

ODCS의 데이터 품질은 4가지 레벨로 정의됩니다.

### 4.1 Text (텍스트 설명)

사람이 읽는 품질 설명. 추후 AI나 도구에서 실행 가능한 체크로 변환 가능.

```yaml
quality:
  - id: email_verified_text
    type: text
    description: The email address was verified by the system.
```

### 4.2 Library (메트릭 라이브러리)

사전 정의된 품질 메트릭. 모든 주요 DQ 엔진과 호환.

| 메트릭 | 레벨 | 설명 | 인자 |
|--------|------|------|------|
| `nullValues` | Property | NULL 값 카운트 | 없음 |
| `missingValues` | Property | 누락 값 카운트 (빈 문자열, N/A 등) | `missingValues: [null, '', 'N/A']` |
| `invalidValues` | Property | 유효하지 않은 값 카운트 | `validValues: [...]` 또는 `pattern: 'regex'` |
| `duplicateValues` | Property | 중복 값 카운트 | 없음 |
| `duplicateValues` | Schema | 복합키 중복 카운트 | `properties: [col1, col2]` |
| `rowCount` | Schema | 전체 행 카운트 | 없음 |

**사용 예제:**

```yaml
# NULL 값 체크 (절대값)
quality:
  - metric: nullValues
    mustBe: 0

# NULL 값 체크 (퍼센트)
quality:
  - metric: nullValues
    mustBeLessThan: 1
    unit: percent

# 유효값 체크 (셋 기반)
quality:
  - metric: invalidValues
    arguments:
      validValues: ['pounds', 'kg']
    mustBeLessThan: 5
    unit: rows

# 행 개수 체크 (범위)
schema:
  - name: orders
    quality:
      - id: orders_row_count
        metric: rowCount
        mustBeBetween: [100, 120]
```

### 4.3 SQL (SQL 쿼리)

개별 SQL 쿼리 결과를 비교값으로 사용.  
`{object}`, `{property}` 플레이스홀더 자동 치환.

```yaml
quality:
  - id: sql_count_not_null
    type: sql
    query: |
      SELECT COUNT(*) FROM {object} WHERE {property} IS NOT NULL
    mustBeLessThan: 3600
    scheduler: cron
    schedule: "0 20 * * *"
```

### 4.4 Custom (벤더별 체크)

Soda, Great Expectations, dbt, Monte Carlo 등 각 도구의 포맷 그대로 사용.

```yaml
# Soda
quality:
  - id: soda_duplicate_percent
    type: custom
    engine: soda
    implementation: |
      type: duplicate_percent
      columns: [carrier, shipment_number]
      must_be_less_than: 1.0

# Great Expectations
quality:
  - id: row_count_btwn_10_50
    type: custom
    engine: greatExpectations
    implementation: |
      type: expect_table_row_count_to_be_between
      kwargs:
        minValue: 10000
        maxValue: 50000
```

### 품질 차원 & 심각도

각 품질 규칙에 차원(dimension)과 심각도(severity)를 지정할 수 있습니다:

```yaml
quality:
  - metric: nullValues
    mustBe: 0
    dimension: completeness        # completeness, uniqueness, timeliness, validity, consistency, accuracy
    severity: error                # error, warning, info
    businessImpact: operational    # operational, analytical, regulatory
```

### 스케줄링

품질 체크 실행 스케줄도 지정 가능:

```yaml
quality:
  - metric: rowCount
    mustBeGreaterThan: 1000000
    scheduler: cron
    schedule: "0 20 * * *"
```

---

## 5. Support & Communication Channels (지원 채널)

데이터 컨슈머가 도움을 받을 수 있는 채널 정의.

### 전체 예제

```yaml
support:
  - id: interactive_teams
    channel: my-data-contract-interactive
    tool: teams
    scope: interactive
    url: https://bitol.io/teams/channel/my-data-contract-interactive
  - id: email_announcements
    channel: datacontract-ann
    tool: email
    scope: announcements
    url: mailto:datacontract-ann@bitol.io
  - id: ticket_support
    channel: my-product-tickets
    tool: ticket
    url: https://bitol.io/ticket/my-product
```

### 필드 정의

| 키 | 타입 | 필수 | 설명 |
|----|------|------|------|
| `channel` | string | ✅ | 채널 이름 또는 식별자 |
| `url` | string | ❌ | 접근 URL |
| `description` | string | ❌ | 사람을 위한 설명 |
| `tool` | string | ❌ | `email`, `slack`, `teams`, `discord`, `ticket`, `googlechat`, `other` |
| `scope` | string | ❌ | `interactive`, `announcements`, `issues`, `notifications` |
| `invitationUrl` | string | ❌ | 초대 URL |

---

## 6. Pricing (가격)

데이터 사용에 대한 과금 정보 (선택 사항).

```yaml
price:
  priceAmount: 9.95
  priceCurrency: USD
  priceUnit: megabyte
```

| 키 | 타입 | 필수 | 설명 |
|----|------|------|------|
| `priceAmount` | number | ❌ | 단위당 구독 가격 |
| `priceCurrency` | string | ❌ | 통화 (ISO 4217) |
| `priceUnit` | string | ❌ | 과금 단위 (`megabyte`, `gigabyte`) |

---

## 7. Team (팀)

데이터 컨트랙트 담당 팀과 멤버 이력.

**v3.1.0부터 구조 변경:** 이전(v2.x/v3.x)에는 배열이었으나, v3.1.0부터는 객체(object) 구조로 마이그레이션 중. 이전 구조는 v4.0.0에서 제거 예정.

### 신규 구조 (v3.1.0+)

```yaml
team:
  id: tsc_team
  name: TSC
  description: The greatest team ever.
  members:
    - username: ceastwood
      role: Data Scientist
      dateIn: 2022-08-02
      dateOut: 2022-10-01
      replacedByUsername: mhopper
    - username: mhopper
      role: Data Scientist
      dateIn: 2022-10-01
    - username: daustin
      role: Owner
      name: David Austin
      dateIn: 2022-10-01
```

### 필드 정의 (members)

| 키 | 타입 | 필수 | 설명 |
|----|------|------|------|
| `username` | string | ✅ | 사용자 ID 또는 이메일 |
| `name` | string | ❌ | 사용자 이름 |
| `role` | string | ❌ | 역할 (Owner, Data Scientist 등) |
| `description` | string | ❌ | 책임 설명 |
| `dateIn` | string | ❌ | 합류일 |
| `dateOut` | string | ❌ | 탈퇴일 |
| `replacedByUsername` | string | ❌ | 대체자 |

---

## 8. Roles (역할 및 접근 권한)

컨슈머가 데이터 접근을 위해 신청할 수 있는 IAM 역할 목록.

```yaml
roles:
  - id: microstrategy_user_opr
    role: microstrategy_user_opr
    access: read
    firstLevelApprovers: Reporting Manager
    secondLevelApprovers: mandolorian
  - id: bq_unica_user_opr
    role: bq_unica_user_opr
    access: write
    firstLevelApprovers: Reporting Manager
    secondLevelApprovers: mickey
```

| 키 | 타입 | 필수 | 설명 |
|----|------|------|------|
| `role` | string | ✅ | IAM 역할 이름 |
| `access` | string | ❌ | 접근 유형 (`read`, `write`) |
| `description` | string | ❌ | 역할 설명 |
| `firstLevelApprovers` | string | ❌ | 1차 승인자 |
| `secondLevelApprovers` | string | ❌ | 2차 승인자 |

---

## 9. Service-Level Agreement (SLA)

데이터 QoS(Quality of Service) 속성을 정의합니다.

### 전체 예제

```yaml
slaProperties:
  - id: latency_4_days
    property: latency
    value: 4
    unit: d
    element: tab1.txn_ref_dt
    scheduler: cron
    schedule: 0 30 * * *
  - id: main_ga
    property: generalAvailability
    value: 2022-05-12T09:30:10-08:00
  - id: retention_3y
    property: retention
    value: 3
    unit: y
    element: tab1.txn_ref_dt
  - id: frequency_daily
    property: frequency
    value: 1
    unit: d
    element: tab1.txn_ref_dt
  - id: reg_toa
    property: timeOfAvailability
    value: 09:00-08:00
    element: tab1.txn_ref_dt
    driver: regulatory
```

### 필드 정의

| 키 | 타입 | 필수 | 설명 |
|----|------|------|------|
| `id` | string | ❌ | 고유 식별자 |
| `property` | string | ✅ | SLA 속성 (아래 표 참조) |
| `value` | string | ✅ | 약정 값 |
| `valueExt` | string | ❌ | 확장 값 |
| `unit` | string | ❌ | 단위 (`d`=일, `y`=년, ISO 표준) |
| `element` | string | ❌ | 체크 대상 Element (Object.Property) |
| `driver` | string | ❌ | 중요도 (`regulatory`, `operational`, `analytical`) |
| `description` | string | ❌ | 설명 |
| `scheduler` | string | ❌ | 스케줄러 이름 (`cron`) |
| `schedule` | string | ❌ | 스케줄 설정 |

### 사전 정의 SLA 속성 (Data QoS)

| 속성 | 동의어 | 설명 |
|------|--------|------|
| `latency` | `ly` | 데이터 지연 시간 |
| `frequency` | `fy` | 업데이트 주기 |
| `availability` | `av` | 가용성 |
| `throughput` | `th` | 처리량 |
| `errorRate` | `er` | 오류율 |
| `generalAvailability` | `ga` | GA 일시 |
| `endOfSupport` | `es` | 지원 종료일 |
| `endOfLife` | `el` | 수명 종료일 |
| `retention` | `re` | 데이터 보존 기간 |
| `timeOfAvailability` | - | 데이터 제공 가능 시간대 |
| `timeToDetect` | `td` | 장애 감지 시간 |
| `timeToNotify` | `tn` | 장애 통보 시간 |
| `timeToRepair` | `tr` | 장애 복구 시간 |

---

## 10. Infrastructures & Servers (인프라 및 서버)

데이터의 물리적 위치와 접근 정보를 정의합니다.  
**30+ 서버 타입을 지원**하며, 없는 경우 `custom` 타입 사용 가능.

### 공통 구조

```yaml
servers:
  - id: my_awesome_server
    server: production           # 필수
    type: bigquery               # 필수
    description: Production environment
    environment: prod
    roles:                       # 접근 역할
      - role: analyst_read
        access: read
    customProperties: []
```

### 서버별 필수 필드 (주요 타입)

| 타입 | 필수 필드 |
|------|----------|
| **PostgreSQL** | `host`, `database` (port 기본 5432) |
| **MySQL** | `host`, `database` (port 기본 3306) |
| **BigQuery** | `project`, `dataset` |
| **Snowflake** | `host`, `port`, `account`, `database`, `warehouse`, `schema` |
| **Redshift** | `database`, `schema` |
| **Databricks** | `catalog`, `schema` |
| **Kafka** | `host` (bootstrap server) |
| **S3** | `location` (`s3://...`) |
| **Athena** | `schema`, `stagingDir` |
| **Trino** | `host`, `port`, `catalog`, `schema` |
| **DuckDB** | `database` (파일 경로) |
| **SQL Server** | `host`, `database`, `schema` (port 기본 1433) |
| **Oracle** | `host`, `port`, `serviceName` |
| **API** | `location` (URL) |
| **Local Files** | `path`, `format` |
| **SFTP** | `location` (`sftp://...`), `format` |

### 환경별 분리

```yaml
servers:
  - server: dev
    type: postgres
    environment: dev
    host: dev-db.internal
    database: analytics_dev
  - server: prod
    type: postgres
    environment: prod
    host: prod-db.internal
    database: analytics
```

---

## 11. Custom & Other Properties (커스텀 속성)

### 11.1 Custom Properties

표준에 없는 비표준 속성을 추가할 수 있는 확장 포인트.

```yaml
customProperties:
  - id: rfc_ruleset_name
    property: refRulesetName
    value: gcsc.ruleset.name
  - id: data_proc_cluster
    property: dataprocClusterName
    value: my-cluster-name
    description: Cluster name for specific applications
```

| 키 | 타입 | 필수 | 설명 |
|----|------|------|------|
| `id` | string | ❌ | 참조용 고유 식별자 |
| `property` | string | ❌ | 속성 이름 (camelCase 권장) |
| `value` | any | ❌ | 값 (배열 가능) |
| `description` | string | ❌ | 설명 |

### 11.2 Authoritative Definitions

컨트랙트의 정의를 외부 시스템(카탈로그, 문서, 리포지토리)에 위임.

```yaml
authoritativeDefinitions:
  - url: https://catalog.data.gov/dataset/air-quality
    type: businessDefinition
    description: Business definition for the dataset.
  - url: https://youtu.be/Iq6SxdsIHHE
    type: videoTutorial
  - url: https://example.com/contract-latest
    type: canonicalUrl
```

| 키 | 타입 | 필수 | 설명 |
|----|------|------|------|
| `url` | string | ✅ | 외부 리소스 URL |
| `type` | string | ✅ | 정의 유형 (아래 참조) |
| `description` | string | ❌ | 설명 |

**권장 type 값:** `businessDefinition`, `transformationImplementation`, `videoTutorial`, `tutorial`, `implementation`, `canonicalUrl` (루트 레벨 전용)

### 11.3 Other Properties

| 키 | 타입 | 필수 | 설명 |
|----|------|------|------|
| `contractCreatedTs` | string | ❌ | 컨트랙트 생성 UTC 타임스탬프 (ISO 8601) |

---

## 12. Full Example (전체 예제)

### 완전한 ODCS v3.1.0 데이터 컨트랙트

```yaml
apiVersion: v3.1.0
kind: DataContract

id: 53581432-6c55-4ba2-a65f-72344a91553a
name: seller_payments_v1
version: 1.1.0
status: active
domain: seller
tenant: ClimateQuantumInc

description:
  purpose: Views built on top of the seller tables.
  limitations: Data based on seller perspective, no buyer information.
  usage: Predict sales over time.

tags: ['finance']

contractCreatedTs: 2022-11-15T02:59:43+00:00

# ============================================
# Schema
# ============================================
schema:
  - id: tbl_obj
    name: tbl
    logicalType: object
    physicalType: table
    physicalName: tbl_1
    description: Provides core payment metrics
    tags: ['finance', 'payments']
    dataGranularityDescription: Aggregation on columns txn_ref_dt, pmt_txn_id
    relationships:
      - type: foreignKey
        from:
          - tbl.rcvr_id
          - tbl.rcvr_cntry_code
        to:
          - receivers.id
          - receivers.country_code
    quality:
      - metric: rowCount
        mustBeGreaterThan: 1000000
        dimension: completeness
        severity: error
        scheduler: cron
        schedule: "0 20 * * *"
    properties:
      - id: txn_ref_dt_prop
        name: txn_ref_dt
        businessName: transaction reference date
        logicalType: date
        physicalType: date
        partitioned: true
        classification: public
        examples: [2022-10-03, 2020-01-28]
      - id: rcvr_id_prop
        name: rcvr_id
        primaryKey: true
        primaryKeyPosition: 1
        logicalType: string
        physicalType: varchar(18)
        classification: restricted
        relationships:
          - to: receivers.id
            type: foreignKey
        quality:
          - metric: nullValues
            mustBe: 0
            dimension: completeness
            severity: error

  - id: receivers_obj
    name: receivers
    physicalName: receivers_master
    logicalType: object
    description: Master data for all receivers
    properties:
      - name: id
        logicalType: string
        physicalType: varchar(18)
        primaryKey: true
        primaryKeyPosition: 1
        required: true
        classification: restricted
      - name: country_code
        logicalType: string
        physicalType: varchar(2)
        primaryKey: true
        primaryKeyPosition: 2
        required: true
        classification: public
      - name: receiver_name
        logicalType: string
        physicalType: varchar(255)
        required: true
        classification: restricted

# ============================================
# Pricing
# ============================================
price:
  priceAmount: 9.95
  priceCurrency: USD
  priceUnit: megabyte

# ============================================
# Team
# ============================================
team:
  name: Analytics Team
  members:
    - username: ceastwood
      role: Data Scientist
      dateIn: 2022-08-02
      dateOut: 2022-10-01
      replacedByUsername: mhopper
    - username: mhopper
      role: Data Scientist
      dateIn: 2022-10-01
    - username: daustin
      role: Owner
      name: David Austin
      dateIn: 2022-10-01

# ============================================
# Roles
# ============================================
roles:
  - role: microstrategy_user_opr
    access: read
    firstLevelApprovers: Reporting Manager
    secondLevelApprovers: mandolorian
  - role: risk_data_access_opr
    access: read
    firstLevelApprovers: Reporting Manager
    secondLevelApprovers: dathvador

# ============================================
# SLA
# ============================================
slaProperties:
  - id: latency_4d
    property: latency
    value: 4
    unit: d
    element: tab1.txn_ref_dt
  - id: retention_3y
    property: retention
    value: 3
    unit: y
    element: tab1.txn_ref_dt
  - id: frequency_daily
    property: frequency
    value: 1
    unit: d
    element: tab1.txn_ref_dt

# ============================================
# Servers
# ============================================
servers:
  - server: my-postgres
    type: postgres
    host: localhost
    port: 5432
    database: pypl-edw
    schema: pp_access_views

# ============================================
# Support
# ============================================
support:
  - channel: "#my-datachannel"
    tool: slack
    scope: interactive
  - channel: datacontract-announce
    tool: email
    scope: announcements
    url: mailto:datacontract-ann@bitol.io
```

---

## 부록: ODCS v3.1.0 주요 변경사항 (v3.0.0 → v3.1.0)

| 변경사항 | 설명 |
|---------|------|
| **Sections 분리** | 각 섹션을 독립 페이지로 분리 (가독성 향상) |
| **SLA Scheduling** | SLA에 `scheduler`/`schedule` 필드 추가 |
| **Team 구조 변경** | 배열 → 객체 구조로 마이그레이션 시작 |
| **dataProduct** | `dataProduct` 필드 DEPRECATED |
| **slaDefaultElement** | `slaDefaultElement` DEPRECATED (v4에서 제거 예정) |
| **관계(Relationships)** | Schema 레벨 외래키 지원 강화 |
| **품질 메트릭** | `missingValues`, `duplicateValues`(복합키) 메트릭 추가 |
| **로컬 파일 서버** | `local` 서버 타입 추가 |

---

## 참고 자료

- 공식 스펙: https://bitol-io.github.io/open-data-contract-standard/v3.1.0/
- GitHub: https://github.com/bitol-io/open-data-contract-standard
- JSON Schema: `schema/odcs-json-schema-latest.json`
- Bitol (재단): https://bitol.io/
- 전체 예제: https://bitol-io.github.io/open-data-contract-standard/v3.1.0/examples/all/full-example.odcs.yaml
- Data QoS 개념: https://medium.com/data-mesh-learning/what-is-data-qos-and-why-is-it-critical-c524b81e3cc1