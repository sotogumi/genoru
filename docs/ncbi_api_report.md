# NCBI E-utilities & BLAST API 検証結果レポート

> 検証日: 2026-03-01  
> 対象配列: `ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA` (30 bp)  
> ドキュメント: [Entrez Programming Utilities Help](https://www.ncbi.nlm.nih.gov/books/NBK25501/)

---

## 概要

NCBI が提供する **E-utilities** (ESearch / EFetch / ESummary) と **BLAST REST API** を対象配列で検証した。  
E-utilities はテキストベース検索のためヒットなし。BLAST は通常検索で 0 件だったが、パラメータ緩和により **20 件ヒット（完全一致 19 件）** を確認した。

| # | API | 用途 | 結果 |
|:-:|:----|:-----|:-----|
| 1 | **ESearch** | nucleotide DB テキスト検索 | ⚠️ 0 件ヒット |
| 2 | **EFetch** | レコード FASTA 取得 | ⏭️ スキップ（ESearch 0件） |
| 3 | **ESummary** | ドキュメントサマリー取得 | ⏭️ スキップ（ESearch 0件） |
| 4 | **BLAST (blastn)** 通常検索 | 配列類似性検索 | ⚠️ 0 件ヒット |
| 5 | **BLAST (blastn)** 緩和検索 | 配列類似性検索（緩和） | ✅ **20 件ヒット** |

---

## 1. ESearch — nucleotide データベース検索

### エンドポイント
```
GET https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi
```

### パラメータ
| パラメータ | 値 | 説明 |
|:---|:---|:---|
| `db` | `nucleotide` | 検索対象データベース |
| `term` | `ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA` | 検索キーワード |
| `retmode` | `json` | レスポンス形式 |
| `retmax` | `10` | 最大取得件数 |
| `usehistory` | `y` | Web Environment を使用 |

### 検証結果
- **ステータス**: ✅ API 正常応答（HTTP 200）
- **ヒット件数**: **0 件**
- **querytranslation**: `(ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA[All Fields])`
- **理由**: ESearch はメタデータに対するテキスト検索。塩基配列文字列そのものは All Fields に含まれないためヒットしない

### レスポンス (抜粋)
```json
{
  "esearchresult": {
    "count": "0",
    "idlist": [],
    "errorlist": {
      "phrasesnotfound": ["ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA"]
    },
    "warninglist": {
      "outputmessages": ["No items found."]
    }
  }
}
```

---

## 2. EFetch — レコード取得 (FASTA)

### エンドポイント
```
GET https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi
```

### パラメータ
| パラメータ | 値 | 説明 |
|:---|:---|:---|
| `db` | `nucleotide` | データベース |
| `id` | `(UID リスト)` | 取得対象の UID |
| `rettype` | `fasta` | FASTA 形式 |
| `retmode` | `text` | テキスト |

### 検証結果
- **ステータス**: ⏭️ スキップ（ESearch が 0 件のため UID がない）
- **備考**: UID があれば FASTA 形式でレコードを取得可能

---

## 3. ESummary — ドキュメントサマリー取得

### エンドポイント
```
GET https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi
```

### パラメータ
| パラメータ | 値 | 説明 |
|:---|:---|:---|
| `db` | `nucleotide` | データベース |
| `id` | `(UID リスト)` | 取得対象の UID |
| `retmode` | `json` | JSON 形式 |

### 検証結果
- **ステータス**: ⏭️ スキップ（ESearch が 0 件のため）
- **備考**: UID を指定すればアクセッション、配列長、説明文などのサマリー情報を JSON で取得可能

---

## 4. BLAST — 配列類似性検索 (blastn)

### エンドポイント
```
POST https://blast.ncbi.nlm.nih.gov/blast/Blast.cgi   # ジョブ投入 & 結果取得
```

### ワークフロー
```
1. PUT (CMD=Put)   → RID 取得
2. GET (CMD=Get, FORMAT_OBJECT=SearchInfo) → ステータスポーリング
3. GET (CMD=Get, FORMAT_TYPE=XML)  → 結果取得
```

### 2 段階検索ロジック

完全一致がない場合に最も一致率の高い配列を出力するため、2段階の検索を実装した。

#### ステップ 1: 通常パラメータ（megablast）

| パラメータ | 値 |
|:---|:---|
| `PROGRAM` | `blastn` |
| `DATABASE` | `nt` |
| `QUERY` | `ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA` |

**結果**: 0 件ヒット（megablast はデフォルトで word size=28, 短い配列の弱い一致は検出しない）

#### ステップ 2: 緩和パラメータ（通常 blastn）

通常検索で 0 件の場合、以下のパラメータで自動的に再検索する:

| パラメータ | 値 | 説明 |
|:---|:---|:---|
| `PROGRAM` | `blastn` | |
| `MEGABLAST` | `no` | megablast を無効化 |
| `DATABASE` | `nt` | nucleotide collection |
| `WORD_SIZE` | `7` | 最小ワードサイズ（短い一致を検出） |
| `EXPECT` | `100000` | 高い E 値閾値（弱い一致も許容） |
| `NUCL_PENALTY` | `-1` | ミスマッチペナルティ緩和 |
| `NUCL_REWARD` | `1` | マッチ報酬 |
| `GAPCOSTS` | `2 1` | ギャップペナルティ |
| `HITLIST_SIZE` | `20` | 最大ヒット数 |
| `FILTER` | `none` | 低複雑度フィルタ無効化 |

**結果**: ✅ **20 件ヒット（完全一致 19 件）**

### BLAST ヒット一覧（上位 10 件）

| # | Accession | E-value | Score | 一致率 | カバレッジ | Description |
|:-:|:----------|:--------|:------|:-------|:----------|:------------|
| 1 | CP133773 | 0.137 | 45.4 | 100.0% | 100.0% | *Cryobacterium sp.* 10S3 chromosome |
| 2 | OZ409428 | 0.137 | 45.4 | 100.0% | 100.0% | *Phaedon cochleariae* genome, chr 1 |
| 3 | OZ180135 | 0.137 | 45.4 | 100.0% | 100.0% | *Melanogrammus aeglefinus* genome |
| 4 | OZ406001 | 0.137 | 45.4 | 100.0% | 100.0% | *Umbra krameri* genome, chr 5 |
| 5 | OE923931 | 0.137 | 45.4 | 100.0% | 100.0% | 5_Tge_b3v08 |
| 6 | OZ392216 | 0.137 | 45.4 | 100.0% | 100.0% | *Aliger gallus* genome, chr 10 |
| 7 | OZ405047 | 0.137 | 45.4 | 100.0% | 100.0% | *Spicara maena* genome, chr 2 |
| 8 | XM_063293690 | 0.137 | 45.4 | 100.0% | 100.0% | *Candoia aspera* COQ10A |
| 9 | OZ180133 | 0.137 | 45.4 | 100.0% | 100.0% | *Melanogrammus aeglefinus* genome |
| 10 | OC004398 | 0.137 | 45.4 | 100.0% | 100.0% | 2_Tsi_b3v08 |

### アラインメント例（1位: CP133773）
```
Query:   ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA
Match:   ||||||||||||||||||||||||||||||
Subject: ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA
```

### DB 統計情報
| 指標 | 値 |
|:---|:---|
| DB 配列数 | 122,348,708 |
| DB 総塩基数 | 1,068,532,645,866 (~1 兆 bp) |

---

## 考察

### 配列 `ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA` の特性

- **ATGC** の 4 塩基繰り返しパターン（7.5 リピート、30 bp）
- 生物学的に特定のタンパク質コード領域を想定した配列ではない
- にもかかわらず、**19/20 件が完全一致** → 約 1 兆 bp のデータベース内では統計的に偶然マッチする領域が複数存在
- マッチした生物種は細菌・昆虫・魚類・爬虫類・貝類と多岐にわたり、進化的保存ではなく偶然の一致

### 検索パラメータの影響

| 設定 | WORD_SIZE | EXPECT | FILTER | ヒット数 |
|:-----|:---------:|:------:|:------:|:--------:|
| 通常 (megablast) | 28 | 10 | ON | **0** |
| 緩和 (blastn) | 7 | 100000 | OFF | **20** |

- **WORD_SIZE=28** (megablast デフォルト) では 30 bp の配列に対して初期シード検索が厳しすぎる
- **WORD_SIZE=7** に下げることでシード検索の感度が大幅に向上
- **FILTER=none** により低複雑度領域のマスキングを無効化（繰り返し配列なので重要）
- **EXPECT=100000** により統計的に弱いマッチも報告対象に含める

---

## スクリプト使用方法

### 実行
```bash
python3 ncbi_api_test.py
```

### 処理フロー
```
ESearch (テキスト検索)
  ↓
EFetch (FASTA取得) ※ESearchでヒットした場合
  ↓
ESummary (サマリー取得) ※同上
  ↓
BLAST ステップ1 (通常検索)
  ↓ ヒットあり → 結果表示して終了
  ↓ ヒットなし
BLAST ステップ2 (緩和検索) → 一致率順にソートして表示
```

### 出力項目
- **一致率**: アラインメント内で一致した塩基数 / アラインメント長 (%)
- **カバレッジ**: アラインメント長 / クエリ配列長 (%)
- **E-value**: 偶然に同等以上のスコアが得られる期待回数
- **Score**: ビットスコア（高いほど良い一致）

---

## 参考リンク

- [Entrez Programming Utilities Help (NBK25501)](https://www.ncbi.nlm.nih.gov/books/NBK25501/)
- [E-utilities Quick Start](https://www.ncbi.nlm.nih.gov/books/n/helpeutils/chapter1/)
- [BLAST URL API](https://blast.ncbi.nlm.nih.gov/doc/blast-help/developerinfo.html)
- [BLAST URL API パラメータ](https://blast.ncbi.nlm.nih.gov/doc/blast-help/urlapi.html)
- 検証スクリプト: [`ncbi_api_test.py`](../ncbi_api_test.py)
