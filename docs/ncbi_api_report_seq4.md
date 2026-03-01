# NCBI API 検証結果レポート — 配列 4

> 検証日: 2026-03-01  
> 対象配列:
> ```
> TATGTAGTTAAGTAATCGACGAACGTAACGACGAAGGCGTCGACGAAGGCATCGACGAAC
> GAACCGACGAACGAGACGACGAACGTCACGACGAACGCCACGACGAACGGGCTTTCCGTG
> GTCTGGCCCGTAGCGGGAGACGGTGAATGCGACGTGGTTCGGTTCGTGGTCAGGCATTTG
> TTACCGGTGTCCGTACCGTTGTGCGCCT
> ```
> 配列長: 208 bp  
> スクリプト: [`ncbi_api_test.py`](../scripts/ncbi_api_test.py)

---

## 結果サマリー

| # | API | 結果 |
|:-:|:----|:-----|
| 1 | **ESearch** (テキスト検索) | ⚠️ 0 件ヒット |
| 2 | **EFetch** / **ESummary** | ⏭️ スキップ |
| 3 | **BLAST (blastn)** 通常検索 | ✅ **5 件ヒット（部分一致のみ、最高一致率 96.3% / カバレッジ 13.0%）** |

> [!NOTE]
> 通常検索で 5 件ヒットしたため緩和検索は実行されていない。
> 全ヒットがカバレッジ 22% 以下の部分一致であり、配列全体に対応するレコードは存在しない。

---

## BLAST ヒット一覧（全 5 件）

| # | Accession | E-value | Score | 一致率 | カバレッジ | 生物種・説明 |
|:-:|:----------|:--------|:------|:-------|:----------|:------------|
| 1 | **CP092431** | **6.94** | **45.5** | **96.3%** | **13.0%** | ***Streptomyces deccanensis*** KCTC 19241 |
| 2 | CP102950 | 6.94 | 44.6 | 88.9% | 17.3% | *Arthrobacter* sp. CJ23 |
| 3 | CP011509 | 6.94 | 44.6 | 88.2% | 16.3% | *Archangium gephyra* DSM 2261 |
| 4 | XM_025962093 | 0.570 | 49.1 | 84.8% | 22.1% | *Panicum hallii* β-1,3-ガラクトシル転移酵素 |
| 5 | CP094970 | 6.94 | 44.6 | 82.2% | 21.6% | *Solicola gregarius* A5X3R13 |

---

## 上位ヒットのアラインメント

### 1 位: CP092431 — *Streptomyces deccanensis*（放線菌）

```
一致率: 96.3% (26/27 bp)   カバレッジ: 13.0%   E-value: 6.94
配列長: 10,101,518 bp

Query:   CCCGTAGCGGGAGACGGTGAATGCGAC
Match:   ||||||||||| |||||||||||||||
Subject: CCCGTAGCGGGTGACGGTGAATGCGAC
```

27bp 中 26bp が一致（1 塩基のみ不一致: `A → T`）。カバレッジは 13.0%。

### 2 位: CP102950 — *Arthrobacter* sp. CJ23（放線菌）

```
一致率: 88.9% (32/36 bp)   カバレッジ: 17.3%   E-value: 6.94

Query:   GGGAGACGGTGAATGCGACGTGGTTCG-GTTCGTGG
Match:   ||||||||||||||||||  ||||||| ||||| ||
Subject: GGGAGACGGTGAATGCGATCTGGTTCGTGTTCGCGG
```

### 3 位: CP011509 — *Archangium gephyra*（粘液細菌）

```
一致率: 88.2% (30/34 bp)   カバレッジ: 16.3%   E-value: 6.94

Query:   CGGGAGACGGTGAATGCGACGTGGTTCGGTTCGT
Match:   |||||||||||||| ||| || | ||||||||||
Subject: CGGGAGACGGTGAAGGCGCCGAGCTTCGGTTCGT
```

---

## 考察

### 配列の特徴

| 項目 | 値 |
|:---|:---|
| 配列長 | 208 bp |
| GC 含量 | G: 64, C: 42, A: 33, T: 39 → **G+C = 51.0%** |
| 反復モチーフ | `CGACGAA` が前半に多数出現（7 回） |
| 後半の特徴 | GC リッチな非反復領域 |

### ヒットの特徴

- **全5件が部分一致**（最大カバレッジ 22.1%）
- **E-value が高い**（0.57〜6.94）→ 統計的に偶然起こりうるレベル
- ヒット生物は **放線菌**（*Streptomyces*, *Arthrobacter*）が中心で、細菌ゲノムの GC リッチ領域と部分的に一致
- アラインメントされた領域は主に配列後半の `CCCGTAGCGGGAGACGGTGAATGCGAC` 付近（GC リッチ領域）

### マッチ領域の分布

```
配列 (208bp):
|---- 前半: CGACGAA 反復領域 ----|---- 後半: 非反復・GC リッチ ----|

   マッチなし                      ▓▓▓ ← ヒットはここに集中
                                    (120bp〜160bp 付近)
```

### 4 配列の横断比較

| 項目 | 配列 1 (30bp) | 配列 2 (96bp) | 配列 3 (108bp) | 配列 4 (208bp) |
|:-----|:------------|:------------|:-------------|:-------------|
| 通常検索 | 0 件 | 0 件 | 18 件 | **5 件** |
| 緩和検索 | 20 件 | 20 件 | *(不要)* | *(不要)* |
| 最高一致率 | 100.0% | 83.7% | 100.0% | **96.3%** |
| 最高カバレッジ | 100.0% | 95.8% | 22.2% | **13.0%** |
| ベスト E-value | 0.137 | 4.76e-15 | 2.90 | **6.94** |
| 最有力ヒット | 多種 | *X. longiventris* | *B. rapa* | ***S. deccanensis*** |
| 統計的有意性 | 低い | **高い** | 低い | 低い |

配列が長い（208bp）にもかかわらず、ヒット数は最少の 5 件。カバレッジも最大 22% と低く、**この配列全体にマッチする既知の配列はデータベースに存在しない**。

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
- 過去のレポート: [配列 1](./ncbi_api_report.md) / [配列 2](./ncbi_api_report_seq2.md) / [配列 3](./ncbi_api_report_seq3.md)

---

## 再検証: カバレッジ順ソート

> 再検証日: 2026-03-01  
> ソート変更: **カバレッジ（高い順）→ 一致率（高い順）**

### 結果サマリー

| # | API | 結果 |
|:-:|:----|:-----|
| 1 | **ESearch** | ⚠️ 0 件ヒット |
| 2 | **BLAST (blastn)** 通常検索 | ✅ **5 件ヒット（最高カバレッジ 22.1%、一致率 84.8%）** |

### BLAST ヒット一覧（全 5 件 — カバレッジ順）

| # | Accession | E-value | Score | 一致率 | カバレッジ | 生物種・説明 |
|:-:|:----------|:--------|:------|:-------|:----------|:------------|
| 1 | **XM_025962093** | **0.570** | **49.1** | **84.8%** | **22.1%** | ***Panicum hallii*** β-1,3-ガラクトシル転移酵素 |
| 2 | CP094970 | 6.94 | 44.6 | 82.2% | 21.6% | *Solicola gregarius* A5X3R13 |
| 3 | CP102950 | 6.94 | 44.6 | 88.9% | 17.3% | *Arthrobacter* sp. CJ23 |
| 4 | CP011509 | 6.94 | 44.6 | 88.2% | 16.3% | *Archangium gephyra* DSM 2261 |
| 5 | CP092431 | 6.94 | 45.5 | 96.3% | 13.0% | *Streptomyces deccanensis* KCTC 19241 |

### 上位ヒットのアラインメント

#### 1 位: XM_025962093 — *Panicum hallii*（キビ属イネ科植物）

```
一致率: 84.8% (39/46 bp)   カバレッジ: 22.1%   E-value: 0.570
配列長: 2,133 bp

Query:   AGCGGGAGACGGTGAATGCGA-CGTGGTTCGGTTCGTGGTCAGGCA
Match:   ||| |||||||| ||| | || |||||||||||||||| || ||||
Subject: AGCTGGAGACGGAGAAGGGGATCGTGGTTCGGTTCGTGATCGGGCA
```

#### 2 位: CP094970 — *Solicola gregarius*（好塩性放線菌）

```
一致率: 82.2% (37/45 bp)   カバレッジ: 21.6%   E-value: 6.94

Query:   CCGTGGTCTGGCCCGTAGCGGGAGACGGTGAATGCGACGTGGTTC
Match:   |||||||| ||| ||   |||||||||  || ||||||||||||
Subject: CCGTGGTCCGGCTCG---CGGGAGACGCCGACTGCGACGTGGTTC
```

#### 3 位: CP102950 — *Arthrobacter* sp. CJ23（放線菌）

```
一致率: 88.9% (32/36 bp)   カバレッジ: 17.3%   E-value: 6.94

Query:   GGGAGACGGTGAATGCGACGTGGTTCG-GTTCGTGG
Match:   ||||||||||||||||||  ||||||| ||||| ||
Subject: GGGAGACGGTGAATGCGATCTGGTTCGTGTTCGCGG
```

### 前回との順位変動

| 生物種 | 前回 (一致率順) | 今回 (カバレッジ順) | 変動 |
|:-------|:---:|:---:|:---:|
| *Streptomyces deccanensis* | 1 位 | **5 位** | ⬇ |
| *Panicum hallii* | 4 位 | **1 位** | ⬆ |
| *Solicola gregarius* | 5 位 | **2 位** | ⬆ |

### 考察

- カバレッジ順では *Panicum hallii*（イネ科植物, 46bp/22.1%）が 1 位に浮上
- ただし**最大カバレッジは 22.1% と依然として低く**、208bp の配列全体にマッチする既知配列は存在しない
- 前回 1 位の *S. deccanensis* は一致率 96.3% と高いが、27bp のみの部分一致（カバレッジ 13.0%）のため 5 位に下降
- 全ヒットの E-value が 0.57〜6.94 で統計的に有意とは言えず、偶然の部分一致の可能性が高い

