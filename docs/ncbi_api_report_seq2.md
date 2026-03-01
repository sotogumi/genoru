# NCBI API 検証結果レポート — 配列 2

> 検証日: 2026-03-01  
> 対象配列: `CGACGAATGCCTCGACGAATGGATCGACGAATGCCTCGACGAATGGATCGACGAATGGCGCGACGAATGGTACGACGAATGGGTCGACGAATGATA`  
> 配列長: 96 bp  
> スクリプト: [`ncbi_api_test.py`](../scripts/ncbi_api_test.py)

---

## 結果サマリー

| # | API | 結果 |
|:-:|:----|:-----|
| 1 | **ESearch** (テキスト検索) | ⚠️ 0 件ヒット |
| 2 | **EFetch** (FASTA 取得) | ⏭️ スキップ |
| 3 | **ESummary** (サマリー取得) | ⏭️ スキップ |
| 4 | **BLAST (blastn)** 通常検索 | ⚠️ 0 件ヒット |
| 5 | **BLAST (blastn)** 緩和検索 | ✅ **20 件ヒット（完全一致なし、最高一致率 83.7%）** |

---

## 1. ESearch

```
GET https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi
  db=nucleotide, term=<配列>, retmode=json
```

- **結果**: 0 件ヒット
- **理由**: ESearch はメタデータに対するテキスト検索であり、塩基配列文字列でのマッチは発生しない

---

## 2–3. EFetch / ESummary

ESearch が 0 件のため実行スキップ。

---

## 4. BLAST — 配列類似性検索

### ステップ 1: 通常検索 (megablast)

| パラメータ | 値 |
|:---|:---|
| PROGRAM | blastn (megablast) |
| DATABASE | nt |

**結果**: 0 件ヒット — megablast(WORD_SIZE=28)では、この配列に対する類似領域が見つからなかった。

### ステップ 2: 緩和検索

| パラメータ | 値 | 説明 |
|:---|:---|:---|
| PROGRAM | blastn | |
| MEGABLAST | no | megablast を無効化 |
| WORD_SIZE | 7 | 短い一致でも検出 |
| EXPECT | 100000 | 弱い一致も許容 |
| NUCL_PENALTY | -1 | ミスマッチペナルティ緩和 |
| NUCL_REWARD | 1 | マッチ報酬 |
| GAPCOSTS | 2 1 | ギャップコスト |
| FILTER | none | 低複雑度フィルタ無効 |
| HITLIST_SIZE | 20 | 最大ヒット数 |

**結果**: ✅ 20 件ヒット（完全一致なし）

---

## BLAST ヒット一覧（上位 10 件）

> ★ **完全一致なし** → 一致率の高い順にソートして表示

| # | Accession | E-value | Score | 一致率 | カバレッジ | 生物種・説明 |
|:-:|:----------|:--------|:------|:-------|:----------|:------------|
| 1 | **CP133773** | **4.76e-15** | **91.1** | **83.7%** | **95.8%** | ***Xantholinus longiventris*** ゲノム |
| 2 | OZ409966 | 3.44e-14 | 88.3 | 82.6% | 95.8% | *Virgichneumon dumeticola* ゲノム |
| 3 | OZ409967 | 9.27e-14 | 86.8 | 81.7% | 96.9% | *Virgichneumon dumeticola* ゲノム (別 chr) |
| 4 | XM_020060734 | 6.71e-13 | 84.0 | 80.6% | 96.9% | *Plasmodium coatneyi* (マラリア原虫) |
| 5 | OY282384 | 3.52e-11 | 78.3 | 79.1% | 94.8% | 未培養 *Acidimicrobiales* |
| 6 | OZ276517 | 9.48e-11 | 76.8 | 78.3% | 95.8% | *Pica pica* (カササギ) ゲノム chr19 |
| 7 | CP109485 | 1.85e-09 | 72.5 | 77.5% | 92.7% | *Streptomyces* sp. NBC_01445 |
| 8 | CP108585 | 1.85e-09 | 72.5 | 76.9% | 94.8% | *Streptomyces* sp. NBC_01186 |
| 9 | OY969693 | 1.85e-09 | 72.5 | 76.9% | 94.8% | 未培養 *Euryarchaeota* |
| 10 | CP109104 | 1.85e-09 | 72.5 | 76.9% | 94.8% | *Streptomyces* sp. NBC_01775 |

---

## 最高一致ヒットのアラインメント

### 1 位: OZ404939 — *Xantholinus longiventris* (ハネカクシ科甲虫)

```
一致率: 83.7% (77/92 bp)   カバレッジ: 95.8%   E-value: 4.76e-15
配列長: 38,063,004 bp

Query:   GACGAATGCCTCGACGAATGGATCGACGAATGCCTCGACGAATGGATCGACGAATGGCGCGACGAATGGTACGACGAATGGGTCGACGAATG
Match:   ||||||||  | ||||||||||| ||||||||  | ||||||||||| |||||||||   |||||||||   ||||||||||| ||||||||
Subject: GACGAATGGATGGACGAATGGATGGACGAATGGATGGACGAATGGATGGACGAATGGATGGACGAATGGATAGACGAATGGGTGGACGAATG
```

### 2 位: OZ409966 — *Virgichneumon dumeticola* (ヒメバチ科)

```
一致率: 82.6% (76/92 bp)   カバレッジ: 95.8%   E-value: 3.44e-14

Query:   CGACGAATGCCTCGACGAATGGATCGACGAATGCCTCGACGAATGGATCGACGAATGGCGCGACGAATGGTACGACGAATGGGTCGACGAAT
Match:   ||||||||   ||||||||| |||||||||||   ||||||||| ||||||||||| |  |||||||| |  |||||||| | |||||||||
Subject: CGACGAATCGATCGACGAATCGATCGACGAATCGATCGACGAATCGATCGACGAATCGATCGACGAATCGATCGACGAATCGATCGACGAAT
```

### 3 位: OZ409967 — *Virgichneumon dumeticola* (別染色体)

```
一致率: 81.7% (76/93 bp)   カバレッジ: 96.9%   E-value: 9.27e-14

Query:   CGACGAATGCCTCGACGAATGGATCGACGAATGCCTCGACGAATGGATCGACGAATGGCGCGACGAATGGTACGACGAATGGGTCGACGAATG
Match:   ||| |||||  |||| ||||||||||| |||||  |||| ||||||||||| ||||||  ||| ||||||  ||| |||||| |||| |||||
Subject: CGAGGAATGAATCGAGGAATGGATCGAGGAATGGATCGAGGAATGGATCGAGGAATGGATCGAGGAATGGATCGAGGAATGGATCGAGGAATG
```

---

## 考察

### 配列の特徴

この配列には `CGACGAATG` という 9 塩基モチーフが繰り返し出現する:

```
CGACGAATG CCT
CGACGAATG GAT
CGACGAATG CCT
CGACGAATG GAT
CGACGAATG GCG
CGACGAATG GTA
CGACGAATG GGT
CGACGAATG ATA
```

この繰り返し構造により、ゲノム中に類似のリピート領域を持つ複数の生物種がヒットした。

### ヒットした生物種の分布

| 分類群 | 例 |
|:---|:---|
| 昆虫 | *Xantholinus longiventris*（ハネカクシ）、*Virgichneumon dumeticola*（ヒメバチ） |
| 原生動物 | *Plasmodium coatneyi*（マラリア原虫） |
| 鳥類 | *Pica pica*（カササギ） |
| 細菌 | *Streptomyces* 複数種 |
| 古細菌 | *Euryarchaeota* |

多様な分類群にまたがっているため、機能的保存ではなくリピート配列の偶然の類似と考えられる。

### 前回配列との比較

| 項目 | 配列 1 (前回) | 配列 2 (今回) |
|:-----|:------------|:------------|
| 配列長 | 30 bp | 96 bp |
| パターン | `ATGC` × 7.5 | `CGACGAATG` + 変異 × 8 |
| 通常検索 | 0 件 | 0 件 |
| 緩和検索 | 20 件（完全一致 19 件） | 20 件（完全一致 0 件） |
| 最高一致率 | 100.0% | 83.7% |
| E-value | 0.137 | 4.76e-15 |

今回の配列は長い（96 bp）にもかかわらず完全一致がなく、E-value は遥かに低い（統計的に有意）。これは、より複雑な配列パターンのため完全一致は偶然には生じにくいが、部分的な類似は強く検出されることを示す。

---

## DB 統計

| 指標 | 値 |
|:---|:---|
| DB 配列数 | 122,348,708 |
| DB 総塩基数 | 1,068,532,645,866 (~1 兆 bp) |

---

## 参考

- [Entrez Programming Utilities Help](https://www.ncbi.nlm.nih.gov/books/NBK25501/)
- [BLAST URL API](https://blast.ncbi.nlm.nih.gov/doc/blast-help/developerinfo.html)
- 検証スクリプト: [`ncbi_api_test.py`](../scripts/ncbi_api_test.py)
- 前回レポート: [`ncbi_api_report.md`](./ncbi_api_report.md)
