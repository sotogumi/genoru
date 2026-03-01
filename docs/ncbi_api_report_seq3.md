v# NCBI API 検証結果レポート — 配列 3

> 検証日: 2026-03-01  
> 対象配列: `CGTTGGTAGGTCCGGTGTGAGGGGCGTTGGTAGGTCCGTTGGCTGGTGCGTTGTCCGCGGCGTCGGTAGACGCGTTGCTCGGTTCGTTGGCTGGTGCGGTGAACGGGA`  
> 配列長: 108 bp  
> スクリプト: [`ncbi_api_test.py`](../scripts/ncbi_api_test.py)

---

## 結果サマリー

| # | API | 結果 |
|:-:|:----|:-----|
| 1 | **ESearch** (テキスト検索) | ⚠️ 0 件ヒット |
| 2 | **EFetch** / **ESummary** | ⏭️ スキップ |
| 3 | **BLAST (blastn)** 通常検索 | ✅ **18 件ヒット（部分一致、最高一致率 100% / カバレッジ 22.2%）** |

> [!IMPORTANT]
> この配列は **通常検索（megablast）でヒットが得られた**ため、緩和検索は実行されていない。
> ただし最高一致率 100% はクエリの一部（24bp / 108bp）のみの完全一致であり、**配列全体の一致ではない**。

---

## BLAST ヒット一覧（上位 10 件）

| # | Accession | E-value | Score | 一致率 | カバレッジ | 生物種・説明 |
|:-:|:----------|:--------|:------|:-------|:----------|:------------|
| 1 | **LR031570** | **2.90** | **44.6** | **100.0%** | **22.2%** | ***Brassica rapa*** (ハクサイ) ゲノム scaffold A05 |
| 2 | CP137599 | 2.90 | 44.6 | 88.2% | 31.5% | *Eragrostis tef* (テフ) chr 9B |
| 3 | OZ412611 | 2.90 | 45.5 | 86.5% | 34.3% | *Ostreococcus tauri* (緑藻) ゲノム |
| 4 | OZ412447 | 0.238 | 48.2 | 85.4% | 38.0% | *Pagellus bogaraveo* (タイ科魚類) chr 23 |
| 5 | OZ408914 | 0.830 | 46.4 | 84.8% | 42.6% | *Hydrurus foetidus* (黄褐藻) chr 1 |
| 6 | OZ392225 | 2.90 | 44.6 | 81.1% | 49.1% | *Aliger gallus* (巻貝) chr 19 |
| 7 | OZ253455 | 0.830 | 47.3 | 79.2% | 49.1% | 未培養 *Dehalococcoidia* |
| 8 | CP108298 | 0.830 | 46.4 | 75.4% | 60.2% | *Streptomyces* sp. NBC_00024 |
| 9 | CP109575 | 0.830 | 46.4 | 75.3% | 67.6% | *Streptomyces* sp. NBC_01369 |
| 10 | CP108082 | 0.830 | 46.4 | 75.3% | 67.6% | *Streptomyces* sp. NBC_00257 |

---

## 上位ヒットのアラインメント

### 1 位: LR031570 — *Brassica rapa*（ハクサイ / カブ）

```
一致率: 100.0% (24/24 bp)   カバレッジ: 22.2%   E-value: 2.90
配列長: 47,572,232 bp

Query:   CGTTGGCTGGTGCGTTGTCCGCGG
Match:   ||||||||||||||||||||||||
Subject: CGTTGGCTGGTGCGTTGTCCGCGG
```

クエリ 108bp のうち **24bp が完全一致**。E-value=2.90 は統計的に偶然起こりうるレベル。

### 2 位: CP137599 — *Eragrostis tef*（テフ、エチオピアの穀物）

```
一致率: 88.2% (30/34 bp)   カバレッジ: 31.5%   E-value: 2.90

Query:   CCGTTGGCTGGTGCGTTGTCCGCGGCGTCGGTAG
Match:   ||||||||||| |||||| ||| |||||| ||||
Subject: CCGTTGGCTGGCGCGTTGGCCGTGGCGTCCGTAG
```

### 3 位: OZ412611 — *Ostreococcus tauri*（超小型緑藻）

```
一致率: 86.5% (32/37 bp)   カバレッジ: 34.3%   E-value: 2.90

Query:   GCGTTGTCCGCGGCGTCGGTAGACGCGTTGCTCGGTT
Match:   |||| |||||||||||||  ||||||||| ||| |||
Subject: GCGTCGTCCGCGGCGTCGAGAGACGCGTTTCTCCGTT
```

---

## 考察

### 配列の特徴

この配列は GC 含量が高く（G: 36, C: 27, T: 24, G+C = 58.3%）、`CGTTGG` や `GGTG` などのモチーフが繰り返し出現する。

### ヒット傾向

| 観点 | 分析 |
|:---|:---|
| **一致率 vs カバレッジ** | 一致率が高いヒットほどカバレッジが低い（短い部分一致） |
| **E-value** | 上位ヒットの E-value は 0.2〜2.9 で、統計的に有意とは言えない |
| **生物種** | 植物（ハクサイ、テフ）、藻類、魚類、細菌と多岐にわたる |
| **全体一致** | 配列全体(108bp)に対する完全一致・高カバレッジのヒットは存在しない |

### 3 配列の比較

| 項目 | 配列 1 (30bp) | 配列 2 (96bp) | 配列 3 (108bp) |
|:-----|:------------|:------------|:-------------|
| 通常検索 | 0 件 | 0 件 | **18 件** |
| 緩和検索 | 20 件 | 20 件 | *(不要)* |
| 最高一致率 | 100.0% | 83.7% | 100.0% |
| 最高カバレッジ | 100.0% | 95.8% | **22.2%** |
| ベスト E-value | 0.137 | 4.76e-15 | 2.90 |
| 最有力ヒット | 多種(偶然一致) | *X. longiventris* | *B. rapa* (部分一致) |

配列 3 は通常検索でヒットしたものの、最大カバレッジが 22.2%（24/108bp）にとどまり、**配列全体に対応するデータベースレコードは存在しない**。

---

## DB 統計

| 指標 | 値 |
|:---|:---|
| DB 配列数 | 122,348,708 |
| DB 総塩基数 | 1,068,532,645,866 (~1 兆 bp) |

---

## 参考

- 検証スクリプト: [`ncbi_api_test.py`](../scripts/ncbi_api_test.py)
- プロセス解説: [`blast_process.md`](./blast_process.md)
- 配列 1 レポート: [`ncbi_api_report.md`](./ncbi_api_report.md)
- 配列 2 レポート: [`ncbi_api_report_seq2.md`](./ncbi_api_report_seq2.md)

---

## 再検証: カバレッジ順ソート

> 再検証日: 2026-03-01  
> ソート変更: **カバレッジ（高い順）→ 一致率（高い順）**

### 結果サマリー

| # | API | 結果 |
|:-:|:----|:-----|
| 1 | **ESearch** | ⚠️ 0 件ヒット |
| 2 | **BLAST (blastn)** 通常検索 | ✅ **18 件ヒット（最高カバレッジ 99.1%、一致率 73.8%）** |

> [!IMPORTANT]
> カバレッジ順に変更したことで、**配列全体に近い範囲でマッチする配列が上位に来るようになった**。
> 前回1位の *Brassica rapa*（一致率100%/カバレッジ22.2%）は短い部分一致のため順位が大幅に下がった。

### BLAST ヒット一覧（上位 10 件 — カバレッジ順）

| # | Accession | E-value | Score | 一致率 | カバレッジ | 生物種・説明 |
|:-:|:----------|:--------|:------|:-------|:----------|:------------|
| 1 | **OZ413842** | **2.54e-07** | **68.0** | **73.8%** | **99.1%** | ***Symphodus mediterraneus*** (ベラ科魚類) |
| 2 | OZ406074 | 0.0195 | 51.8 | 72.5% | 94.4% | *Elacatinus chancei* (ハゼ科魚類) chr 4 |
| 3 | CP024941 | 3.77e-05 | 61.7 | 73.3% | 93.5% | *Paraburkholderia terricola* (細菌) |
| 4 | XM_076058954 | 0.00560 | 53.6 | 73.0% | 82.4% | *Petromyzon marinus* (ヤツメウナギ) |
| 5 | XM_076058961 | 0.238 | 49.1 | 71.9% | 82.4% | *Petromyzon marinus* (ヤツメウナギ) |
| 6 | OZ412295 | 2.90 | 45.5 | 71.3% | 80.6% | *Symphodus doderleini* (ベラ科魚類) |
| 7 | XM_069839993 | 0.0682 | 50.9 | 75.3% | 75.0% | *Periplaneta americana* (ワモンゴキブリ) |
| 8 | CP109575 | 0.830 | 46.4 | 75.3% | 67.6% | *Streptomyces* sp. NBC_01369 |
| 9 | CP108082 | 0.830 | 46.4 | 75.3% | 67.6% | *Streptomyces* sp. NBC_00257 |
| 10 | OZ392236 | 0.830 | 47.3 | 75.0% | 63.0% | *Aliger gallus* (巻貝) chr 30 |

### 上位ヒットのアラインメント

#### 1 位: OZ413842 — *Symphodus mediterraneus*（地中海産ベラ科魚類）

```
一致率: 73.8% (79/107 bp)   カバレッジ: 99.1%   E-value: 2.54e-07
配列長: 19,244,124 bp

Query:   CGTTGGTAGGTCCGGTGTGAGGGGCGTTGGTAGGTCCGTTGGCTGGTGCGTTGTCCGCGGCGTCGGTAGACGCGTTGCTCGGTTCGTTGGCTGGTGCGGTGAACGGG
Match:   ||||||| ||  || ||   ||||||||||| ||  |||||| ||| ||||||   | ||||| ||| || || ||| ||||  |||||| ||| ||| ||  ||||
Subject: CGTTGGTTGGGGCGTTGGTCGGGGCGTTGGTTGGGGCGTTGGTTGGGGCGTTGGTTGGGGCGTTGGTTGAGGCTTTGATCGGGGCGTTGGTTGGGGCGTTGGTCGGG
```

クエリ 108bp のうち **107bp がアラインメントされ（カバレッジ 99.1%）、79bp が一致**。
Subject 側に `CGTTGGTTGGGG` の繰り返しパターンが見られる。

#### 2 位: OZ406074 — *Elacatinus chancei*（ハゼ科の小型魚）

```
一致率: 72.5% (74/102 bp)   カバレッジ: 94.4%   E-value: 0.0195

Query:   CGTTGGTAGGTCCGGT-GTGAGGGGCGTTGGTAGGTCCGTTGGCTGGTGCGTTGTCCGCGGCGTCGGTAGACGCGTTGCTCGGTTCGTTGGCTGGTGCGGTG
Match:   ||||||| ||| || | ||| ||  ||||||||||| ||||||  ||| |||||   |   ||| ||| |   ||||| | ||||||||||  ||| || ||
Subject: CGTTGGTGGGTTCGTTAGTG-GGTTCGTTGGTAGGTTCGTTGGTGGGTTCGTTGGTGGGTTCGTTGGTGGGTTCGTTGGTGGGTTCGTTGGTGGGTTCGTTG
```

#### 3 位: CP024941 — *Paraburkholderia terricola*（土壌細菌）

```
一致率: 73.3% (74/101 bp)   カバレッジ: 93.5%   E-value: 3.77e-05

Query:   CGTTGGTAGGTCCGGTGTGAGGGGCGTTGGTAGGTCCGTTGGCTGGTGCGTTGTCCGCGGCGTCGGTAGACGCGTTGCTCGGTTCGTTGGCTGGTGCGGTG
Match:   ||||||| ||  || ||   ||||||||||| ||  |||||| ||| ||||||   | ||||| ||| |  |||||| | ||  |||||| ||| ||| ||
Subject: CGTTGGTTGGGGCGTTGGTTGGGGCGTTGGTTGGGGCGTTGGTTGGGGCGTTGGTTGGGGCGTTGGTTGGGGCGTTGGTTGGGGCGTTGGTTGGGGCGTTG
```

### 前回との順位変動

| 生物種 | 前回 (一致率順) | 今回 (カバレッジ順) | 変動 |
|:-------|:---:|:---:|:---:|
| *Brassica rapa* | 1 位 | — (圏外) | ⬇ **大幅下降** |
| *Symphodus mediterraneus* | — (圏外) | **1 位** | ⬆ **大幅上昇** |
| *Elacatinus chancei* | — (圏外) | **2 位** | ⬆ **大幅上昇** |
| *Paraburkholderia terricola* | — (圏外) | **3 位** | ⬆ **大幅上昇** |

### 考察

- **カバレッジ順にすることで、配列全体にわたって類似性のある配列が上位に浮上した**
- 上位ヒットの Subject 配列には `CGTTGG(T/A)` の繰り返しパターンが共通して見られ、クエリ配列中の `CGTTGG` リピートとマッチしている
- E-value も上位 3 件が 2.54e-07〜3.77e-05 と統計的に有意な範囲
- 前回 1 位の *Brassica rapa* は一致率 100% だがカバレッジ 22.2% のため、実質的にはクエリのごく一部の偶然一致に過ぎない

