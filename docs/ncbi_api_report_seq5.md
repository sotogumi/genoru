# NCBI API 検証結果レポート — 配列 5

> 検証日: 2026-03-04  
> 対象配列: `CTGTTGATGCCGTTTCC...` (660 bp、`TGTTGATGCCGTTTCC` 繰り返しパターン)  
> スクリプト: [`ncbi_api_test.py`](../scripts/ncbi_api_test.py)

---

## 結果サマリー

| # | API | 結果 |
|:-:|:----|:-----|
| 1 | **ESearch** | ⚠️ 0 件ヒット |
| 2 | **BLAST (blastn)** 通常検索 | ✅ **10 件ヒット（最高カバレッジ 115.5%、一致率 71.8%）** |

> [!IMPORTANT]
> 通常検索（megablast）で **高カバレッジのヒットが多数得られた**。緩和検索は不要だった。  
> カバレッジが 100% を超えているのは、ギャップを含むアラインメントにより Subject 配列がクエリより長い領域にマッチしているため。

---

## BLAST ヒット一覧（上位 10 件 — カバレッジ順）

| # | Accession | E-value | Score | 一致率 | カバレッジ | 生物種・説明 |
|:-:|:----------|:--------|:------|:-------|:----------|:------------|
| 1 | **OZ078405** | **3.20e-93** | **357.5** | **71.8%** | **115.5%** | ***Lampetra fluviatilis*** (ヨーロッパカワヤツメ) |
| 2 | OZ078405 | 3.20e-93 | 357.5 | 71.8% | 115.5% | *Lampetra fluviatilis* (別領域) |
| 3 | OZ408726 | 2.30e-63 | 258.3 | 66.8% | 114.6% | *Tylodina rafinesquii* (ウミウシ目) |
| 4 | XM_072500567 | 7.54e-38 | 173.5 | 66.8% | 114.4% | *Scyliorhinus torazame* (トラザメ) |
| 5 | OZ078325 | 2.46e-31 | 151.9 | 68.8% | 109.5% | *Lampetra planeri* (ヨーロッパスナヤツメ) |
| 6 | XR_012931291 | 5.80e-33 | 156.4 | 66.2% | 106.1% | *Petromyzon marinus* (ウミヤツメ) |
| 7 | XR_012931292 | 5.80e-33 | 156.4 | 66.2% | 106.1% | *Petromyzon marinus* (ウミヤツメ) |
| 8 | XM_076057702 | 5.80e-33 | 156.4 | 66.2% | 106.1% | *Petromyzon marinus* (ウミヤツメ) |
| 9 | XM_076057701 | 5.80e-33 | 156.4 | 66.2% | 106.1% | *Petromyzon marinus* (ウミヤツメ) |
| 10 | XM_023271605 | 1.28e-47 | 205.1 | 70.0% | 105.1% | *Amphiprion ocellaris* (カクレクマノミ) |

---

## 上位ヒットのアラインメント

### 1 位: OZ078405 — *Lampetra fluviatilis*（ヨーロッパカワヤツメ）

```
一致率: 71.8% (569/792 bp)   カバレッジ: 115.5%   E-value: 3.20e-93
配列長: 37,001,432 bp

Query:   GTTGATGCCGTTTCCGAT---GTTGATGCCGTTTCCTAT---GTTGATGCCGTTTCCGAT...
Match:   ||||||||||| |||| |   ||||||||||| |||  |   ||||||||||| |||| |...
Subject: GTTGATGCCGTGTCCGCTGTGGTTGATGCCGTGTCCACTGTGGTTGATGCCGTGTCCGCT...
```

クエリ中の `TGTTGATGCCGTTTCC` リピートが、Subject 側の `TGTTGATGCCGTGTCC` リピートに対応。
主な塩基差異: クエリ `TTT` → Subject `TGT`、クエリ末尾 `GAT/TAT` → Subject `GCT/ACT`。

### 3 位: OZ408726 — *Tylodina rafinesquii*（ウミウシ目巻貝）

```
一致率: 66.8% (525/786 bp)   カバレッジ: 114.6%   E-value: 2.30e-63

Query:   TGTTGATGCCGTTTCCGATGTTGATGCCGTTTC------CTATGTTGATGCCGTTTCC...
Match:   ||||||||||||  | | ||||||||| ||  |        |||||||||||||  | |...
Subject: TGTTGATGCCGTGCCAGCTGTTGATGCTGTGACAGTGGTGGATGTTGATGCCGTGCCA...
```

---

## 考察

### 配列の特徴

| 項目 | 値 |
|:---|:---|
| 配列長 | 660 bp |
| GC 含量 | G: 173, C: 135, T: 220, A: 32 → **G+C = 46.7%** |
| 反復単位 | `TGTTGATGCCGTTTCC` (16 bp) × 約 41 リピート |
| バリエーション | 末尾が `GAT` / `TAT` で交互に出現 |

### ヒットの特徴

- **全 10 件が高カバレッジ（105〜115%）** — 配列全体にわたってマッチする既知配列が存在
- **E-value が極めて低い**（10^-93 〜 10^-31）→ **統計的に非常に有意**
- ヒット生物は **ヤツメウナギ科** が圧倒的に多い（*Lampetra*, *Petromyzon*）

### ヒット生物種の分類

| 分類群 | 生物種 | ヒット数 |
|:---|:---|:---:|
| **ヤツメウナギ目** | *Lampetra fluviatilis*, *L. planeri*, *Petromyzon marinus* | **7 件** |
| 軟骨魚類 | *Scyliorhinus torazame* (トラザメ) | 1 件 |
| 腹足類 | *Tylodina rafinesquii* (ウミウシ) | 1 件 |
| 硬骨魚類 | *Amphiprion ocellaris* (カクレクマノミ) | 1 件 |

> [!NOTE]
> ヤツメウナギは脊椎動物の中でも最も原始的な無顎類に属する。このリピート配列がヤツメウナギ科に集中してヒットすることは、**原始的な脊椎動物に共通するゲノムリピート構造**の存在を示唆する可能性がある。

### 全配列の横断比較

| 項目 | 配列 1 | 配列 2 | 配列 3 | 配列 4 | **配列 5** |
|:-----|:---:|:---:|:---:|:---:|:---:|
| 配列長 | 30bp | 96bp | 108bp | 208bp | **660bp** |
| 通常検索 | 0 | 0 | 18 | 5 | **10** |
| 最高カバレッジ | 100% | 95.8% | 99.1% | 22.1% | **115.5%** |
| 最高一致率 | 100% | 83.7% | 73.8% | 84.8% | **71.8%** |
| ベスト E-value | 0.137 | 4.76e-15 | 2.54e-07 | 0.570 | **3.20e-93** |
| 統計的有意性 | 低 | 高 | やや高 | 低 | **非常に高** |

**配列 5 は全検証中で最も統計的に有意な結果**。E-value が 10^-93 と極めて低く、ヤツメウナギ科ゲノムに実在するリピート配列との強い類似性が確認された。

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
- 過去のレポート: [配列 1](./ncbi_api_report.md) / [配列 2](./ncbi_api_report_seq2.md) / [配列 3](./ncbi_api_report_seq3.md) / [配列 4](./ncbi_api_report_seq4.md)
