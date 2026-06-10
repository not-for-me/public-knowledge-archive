# ODCS (Open Data Contract Standard) 개요

> **Open Data Contract Standard** — 데이터 프로듀서와 컨슈머 간의 계약을 표준화하는 오픈 프레임워크
> **버전:** v3.1.0 (2025.12) | **라이선스:** Apache 2.0 | **재단:** LF AI & Data (Linux Foundation)

---

## 1. ODCS란?

ODCS는 **데이터 컨트랙트(Data Contract)** 의 구조와 포맷을 정의하는 개방형 표준입니다.  
데이터를 제공하는 쪽(Producer)과 사용하는 쪽(Consumer) 사이의 **명시적인 약속**을 YAML로 기술합니다.

### 탄생 배경

- **PayPal**에서 내부적으로 사용하던 **Data Contract Template**이 시초
- **Bitol** (Linux Foundation AI & Data incubation 프로젝트)이 표준화 주도
- v2.x → v3.0.0 (2024) → **v3.1.0 (2025.12)** 로 진화 중
- Apache 2.0 라이선스로 누구나 자유롭게 사용 및 기여 가능

### 핵심 가치

```
데이터 계약 = "이 데이터는 이런 형태로, 이런 품질로, 이 시간까지 제공됩니다"
```

데이터 계약이 없을 때: "이 컬럼 어디 갔지?", "이거 주문 건수 맞아?", "어제까지 데이터 언제 와?"  
데이터 계약이 있을 때: 명세, 품질 기준, SLA가 **코드로 명시**되어 있음

---

## 2. ODCS 데이터 컨트랙트 구조 (11개 섹션)

```yaml
apiVersion: v3.1.0
kind: DataContract
```

### 📋 01. Fundamentals (기본 정보)
컨트랙트 자체의 메타데이터

| 항목 | 설명 | 예시 |
|------|------|------|
| `id` | 고유 식별자 (UUID) | `53581432-6c55-...` |
| `name` | 컨트랙트 이름 | `seller_payments_v1` |
| `version` | 버전 | `1.1.0` |
| `status` | 상태 | `proposed`, `active`, `deprecated`, `retired` |
| `domain` | 도메인 | `seller`, `checkout`, `finance` |
| `description` | 목적/제한사항/사용법 | 자유 텍스트 |

### 🗂️ 02. Schema (스키마)
데이터 모델의 논리적/물리적 표현

- **Object** = 테이블(RDBMS), 문서(NoSQL) 등 데이터 구조 단위
- **Property** = 컬럼, 필드
- **지원 타입:** `string`, `date`, `timestamp`, `number`, `integer`, `object`, `array`, `boolean`
- **관계(Relationship):** 외래키(Foreign Key) 표현 가능
- **복합 구조:** JSON, Avro 등 nested type 지원(v3+)

### 🔗 03. References (참조)
- 컨트랙트 내/외부 요소 참조 (id 기반 안전 참조)
- 외래키 관계 표현에 사용
- 정규 표기법: `schema/users_tbl/properties/user_id_pk`
- 약식 표기법: `users.id`

### ✅ 04. Data Quality (데이터 품질)
**4가지 품질 정의 방식:**

| 방식 | 설명 | 예시 |
|------|------|------|
| **Text** | 사람이 읽는 설명 | "이메일은 반드시 검증되어야 함" |
| **Library** | 사전 정의 메트릭 | `nullValues`, `duplicateValues`, `rowCount`, `invalidValues` |
| **SQL** | SQL 쿼리 반환값 기반 | `SELECT COUNT(*) FROM {object} WHERE {property} IS NOT NULL` |
| **Custom** | 벤더별 체크 | Soda, Great Expectations, dbt, Monte Carlo |

### 📞 05. Support & Communication (지원 채널)
컨슈머가 도움을 받을 수 있는 채널 정의

- **tool:** `email`, `slack`, `teams`, `discord`, `ticket`, `googlechat`
- **scope:** `interactive`, `announcements`, `issues`, `notifications`

### 💰 06. Pricing (가격)
데이터 사용에 대한 과금 정보 (선택 사항)

```yaml
price:
  priceAmount: 9.95
  priceCurrency: USD
  priceUnit: megabyte
```

### 👥 07. Team (팀)
데이터 컨트랙트를 담당하는 팀과 멤버 이력

| 필드 | 설명 |
|------|------|
| `username` | 사용자 ID 또는 이메일 |
| `role` | 역할 (Owner, Data Scientist, Data Steward 등) |
| `dateIn` / `dateOut` | 합류/탈퇴 일자 |
| `replacedByUsername` | 대체자 |

### 🔑 08. Roles (역할 & 접근 권한)
데이터 접근을 위한 IAM 역할 목록

```yaml
roles:
  - role: analyst_us_read
    access: read
    firstLevelApprovers: Reporting Manager
```

### 📊 09. SLA (서비스 수준 계약)
데이터 QoS 속성 정의 (12가지 사전 정의 속성)

| 속성 | 설명 |
|------|------|
| `latency` | 데이터 지연 허용 시간 |
| `frequency` | 업데이트 주기 |
| `retention` | 데이터 보존 기간 |
| `generalAvailability` | GA 일시 |
| `endOfLife` / `endOfSupport` | EOL / EOS 일시 |
| `timeOfAvailability` | 데이터 제공 가능 시간대 |
| `timeToDetect` / `timeToNotify` / `timeToRepair` | 장애 대응 SLA |

### 🖥️ 10. Infrastructures & Servers (인프라)
데이터가 물리적으로 위치한 서버 정보

**지원 타입 (30+):** PostgreSQL, MySQL, BigQuery, Snowflake, Redshift, Kafka, S3, Databricks, Athena, Trino, Presto, Oracle, SQL Server, DuckDB, ...

```yaml
servers:
  - server: production
    type: bigquery
    project: acme_prod
    dataset: shipments_v1
```

### 🧩 11. Custom & Other Properties (커스텀 속성)
표준에 없는 추가 속성 + 외부 정의 링크(Authoritative Definitions)

---

## 3. ODCS vs 유사 표준

| 표준 | 초점 | 산업 | 특징 |
|------|------|------|------|
| **ODCS** (Bitol) | Data Contract (schema + quality + SLA) | 범용 | 가장 상세한 품질/SLA, LF 프로젝트 |
| **ODPS** (Bitol) | Data Product metadata | 범용 | 데이터 제품 카탈로그용 |
| **Data Contract Spec** (datacontract.com) | YAML 기반 계약 | 범용 | 경량, CLI 도구 제공 |

---

## 4. Quick Start

```yaml
# 최소 컨트랙트 예제
apiVersion: v3.1.0
kind: DataContract
id: a1b2c3d4-...-uuid
name: orders_v1
version: 1.0.0
status: active
domain: checkout

schema:
  - name: orders
    logicalType: object
    properties:
      - name: order_id
        logicalType: string
        primaryKey: true
      - name: amount
        logicalType: number

team:
  members:
    - username: data.owner@company.com
      role: Owner

servers:
  - server: prod
    type: postgres
    host: db.company.com
    database: analytics
    schema: public
```

---

## 5. 함께 보면 좋은 자료

| 자료 | 링크 |
|------|------|
| 공식 스펙 문서 | https://bitol-io.github.io/open-data-contract-standard/v3.1.0/ |
| GitHub 저장소 | https://github.com/bitol-io/open-data-contract-standard |
| JSON Schema (IDE 검증용) | `schema/odcs-json-schema-latest.json` |
| 전체 예제 YAML | https://bitol-io.github.io/open-data-contract-standard/v3.1.0/examples/all/full-example.odcs.yaml |