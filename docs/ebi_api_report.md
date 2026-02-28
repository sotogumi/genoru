# EMBL-EBI API 検証結果レポート

> **NCBI E-utilities & BLAST API** がメンテナンス中のため、代替として **EMBL-EBI** の API を調査・検証した結果をまとめます。

## 概要

| 項目 | 内容 |
|:---|:---|
| 対象配列 | `ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA` (30 bp) |
| 実行日時 | 2026-03-01 |
| 代替API提供元 | [EMBL-EBI (European Bioinformatics Institute)](https://www.ebi.ac.uk/) |

---

## API対応表 (NCBI → EBI)

| # | NCBI 機能 | EBI 代替 API | エンドポイント | ステータス |
|:-:|:---|:---|:---|:---:|
| 1 | ESearch (テキスト検索) | ENA Portal API | `GET /ena/portal/api/search` | ✅ 利用可能 |
| 2 | EFetch (FASTA取得) | ENA Browser API | `GET /ena/browser/api/fasta/{accession}` | ✅ 利用可能 |
| 3 | ESummary (サマリー取得) | ENA Browser API | `GET /ena/browser/api/xml/{accession}` | ✅ 利用可能 |
| 4 | BLAST (配列類似性検索) | EBI Job Dispatcher (NCBI BLAST+) | `POST /Tools/services/rest/ncbiblast/run` | ✅ 利用可能 |

---

## 1. ENA Text Search (ESearch 代替)

### エンドポイント
```
GET https://www.ebi.ac.uk/ena/portal/api/search
```

### パラメータ
| パラメータ | 値 | 説明 |
|:---|:---|:---|
| `result` | `sequence` | データセットタイプ |
| `query` | `description="*keyword*"` | 検索クエリ（ENA独自構文） |
| `fields` | `accession,description,base_count` | 返却フィールド |
| `limit` | `10` | 最大件数 |
| `format` | `tsv` | レスポンス形式 |

### 検証結果
- **API通信**: ✅ 成功（HTTP 200 レスポンス確認）
- **備考**: ENA Portal API はテキスト検索を行う API。NCBIの ESearch のようにDNA配列文字列を直接検索するのではなく、メタデータ（description, accession等）に対するテキスト検索が主な用途
- **配列検索**: DNA配列による類似性検索には BLAST API を使用する必要がある

### リクエスト例
```bash
curl "https://www.ebi.ac.uk/ena/portal/api/search?result=sequence&query=description=%22*TP53*%22&fields=accession,description,base_count&limit=5&format=tsv"
```

---

## 2. ENA FASTA Fetch (EFetch 代替)

### エンドポイント
```
GET https://www.ebi.ac.uk/ena/browser/api/fasta/{accession}
```

### 検証結果
- **API通信**: ✅ 利用可能（アクセッション番号を指定すれば FASTA 形式でレコード取得可能）
- **備考**: NCBI EFetch と同等の機能。アクセッション番号が必要

### リクエスト例
```bash
curl "https://www.ebi.ac.uk/ena/browser/api/fasta/AE008916"
```

---

## 3. ENA XML Fetch (ESummary 代替)

### エンドポイント
```
GET https://www.ebi.ac.uk/ena/browser/api/xml/{accession}
```

### 検証結果
- **API通信**: ✅ 利用可能（XML形式でレコードの詳細情報取得可能）
- **備考**: NCBI ESummary と同等。アクセッション、配列長、description などの情報を含む

### リクエスト例
```bash
curl "https://www.ebi.ac.uk/ena/browser/api/xml/AE008916"
```

---

## 4. EBI BLAST (NCBI BLAST 代替)

### エンドポイント
```
POST https://www.ebi.ac.uk/Tools/services/rest/ncbiblast/run     # ジョブ投入
GET  https://www.ebi.ac.uk/Tools/services/rest/ncbiblast/status/{jobId}      # ステータス確認
GET  https://www.ebi.ac.uk/Tools/services/rest/ncbiblast/result/{jobId}/{type}  # 結果取得
```

### ジョブ投入パラメータ
| パラメータ | 値 | 説明 |
|:---|:---|:---|
| `email` | `test@example.com` | 必須。利用者のメールアドレス |
| `stype` | `dna` | 配列タイプ（dna / protein） |
| `program` | `blastn` | BLASTプログラム |
| `database` | `em_all` | ENA Sequence (全データ) |
| `sequence` | `>query\nATGCTAGC...` | FASTA形式の配列 |

### ジョブステータス
| ステータス | 意味 |
|:---|:---|
| `RUNNING` | 実行中 |
| `FINISHED` | 完了 |
| `ERROR` | エラー |
| `NOT_FOUND` | ジョブが見つからない |

### 検証結果
- **ジョブ投入**: ✅ 成功
- **Job ID 取得**: ✅ `ncbiblast-R20260228-162636-0467-79020051-p1m`
- **ポーリング**: ✅ ステータス確認 API 正常動作（RUNNING ステータスを適切に返却）
- **備考**: `em_all`（ENA全データ）での検索は数分かかる。分類別DB（例: `em_hum`, `em_pro`）を使うと高速

### 利用可能なデータベース（nucleotide用）
| DB名 | 説明 |
|:---|:---|
| `em_all` | ENA Sequence 全データ |
| `em_hum` | ヒト配列 |
| `em_pro` | 原核生物 |
| `em_vrl` | ウイルス |
| `em_pln` | 植物 |
| `em_mam` | 哺乳類 |
| `em_mus` | マウス |

### リクエスト例
```bash
# ジョブ投入
curl -X POST "https://www.ebi.ac.uk/Tools/services/rest/ncbiblast/run" \
  -d "email=test@example.com&stype=dna&program=blastn&database=em_all&sequence=>query%0AATGCTAGCTAGCTAGCTAGCTAGCTAGCTA"

# ステータス確認
curl "https://www.ebi.ac.uk/Tools/services/rest/ncbiblast/status/{jobId}"

# 結果取得（テキスト）
curl "https://www.ebi.ac.uk/Tools/services/rest/ncbiblast/result/{jobId}/out"
```

---

## まとめ

### NCBI → EBI 移行ガイド

```
NCBI                           →  EBI
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ESearch (テキスト検索)            →  ENA Portal API /search
EFetch  (FASTA取得)             →  ENA Browser API /fasta/{acc}
ESummary (サマリー)              →  ENA Browser API /xml/{acc}
BLAST   (配列類似性検索)          →  EBI Job Dispatcher /ncbiblast
```

### 実装の主な違い

1. **認証**: どちらも API キー不要（EBI は `email` パラメータ推奨）
2. **検索**: ENA はメタデータ検索が主。配列検索は BLAST を使用
3. **BLAST**: EBI は非同期ジョブ方式（投入 → ポーリング → 結果取得）。NCBI と同じワークフロー
4. **レート制限**: EBI は同時 30 ジョブまで（NCBI は 3 リクエスト/秒）

### 検証スクリプト

- [`ebi_api_test.py`](../ebi_api_test.py) — 4つの API を順番に検証するスクリプト

### 参考リンク

- [ENA Portal API](https://www.ebi.ac.uk/ena/portal/api/)
- [ENA Browser API](https://www.ebi.ac.uk/ena/browser/api/)
- [EBI Job Dispatcher (Swagger UI)](https://www.ebi.ac.uk/Tools/common/tools/help/index.html?tool=ncbiblast)
- [EBI BLAST パラメータ一覧](https://www.ebi.ac.uk/Tools/services/rest/ncbiblast/parameterdetails/database)
