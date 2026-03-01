#!/usr/bin/env python3
"""
NCBI E-utilities & BLAST API 検証スクリプト

対象配列: ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA
以下のAPIを順番に検証します:
  1. ESearch  — nucleotideデータベースで配列をテキスト検索
  2. EFetch   — 検索結果のレコードを取得
  3. BLAST    — 配列類似性検索（blastn）を実行し結果を取得

参考: https://www.ncbi.nlm.nih.gov/books/NBK25501/
"""

import gzip
import io
import json
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime
from typing import Optional, List

# ─── 設定 ───────────────────────────────────────────────
SEQUENCE = "ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA"
BASE_URL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
BLAST_URL = "https://blast.ncbi.nlm.nih.gov/blast/Blast.cgi"

# NCBI は tool / email パラメータの使用を推奨
TOOL = "genoru_api_test"
EMAIL = ""  # ← メールアドレスを指定すると推奨ガイドラインに準拠

SEPARATOR = "=" * 70


def log(msg: str) -> None:
    """タイムスタンプ付きログ出力"""
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] {msg}")


def fetch_url(url: str, data: Optional[dict] = None, method: str = "GET") -> str:
    """簡易HTTPリクエスト (GET/POST) — gzip圧縮レスポンスにも対応"""
    if data and method == "GET":
        url = f"{url}?{urllib.parse.urlencode(data)}"
        req = urllib.request.Request(url)
    elif data and method == "POST":
        encoded = urllib.parse.urlencode(data).encode("utf-8")
        req = urllib.request.Request(url, data=encoded)
    else:
        req = urllib.request.Request(url)

    req.add_header("User-Agent", f"{TOOL}/1.0 (Python)")
    req.add_header("Accept-Encoding", "gzip, identity")
    with urllib.request.urlopen(req, timeout=120) as resp:
        raw_bytes = resp.read()

        # gzip 圧縮レスポンスの解凍
        content_encoding = resp.headers.get("Content-Encoding", "")
        if content_encoding == "gzip" or raw_bytes[:2] == b'\x1f\x8b':
            try:
                raw_bytes = gzip.decompress(raw_bytes)
            except Exception:
                pass  # 解凍できない場合はそのまま

        # デコード (utf-8 → latin-1 フォールバック)
        try:
            return raw_bytes.decode("utf-8")
        except UnicodeDecodeError:
            return raw_bytes.decode("latin-1")


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. ESearch — nucleotide データベースでテキスト検索
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def test_esearch() -> List[str]:
    """配列をキーワードとして nucleotide DB を検索し、UID一覧を返す"""
    print(f"\n{SEPARATOR}")
    print("1. ESearch — nucleotide データベース検索")
    print(SEPARATOR)

    params = {
        "db": "nucleotide",
        "term": SEQUENCE,
        "retmode": "json",
        "retmax": 10,
        "usehistory": "y",
        "tool": TOOL,
        "email": EMAIL,
    }
    url = f"{BASE_URL}/esearch.fcgi"
    log(f"リクエスト: {url}")
    log(f"パラメータ: {json.dumps(params, indent=2)}")

    raw = fetch_url(url, params)
    result = json.loads(raw)

    print("\n--- レスポンス (JSON) ---")
    print(json.dumps(result, indent=2, ensure_ascii=False))

    id_list = result.get("esearchresult", {}).get("idlist", [])
    count = result.get("esearchresult", {}).get("count", "0")
    log(f"ヒット件数: {count}")
    log(f"取得した UID 一覧: {id_list}")
    return id_list


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. EFetch — 検索結果のレコードを FASTA 形式で取得
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def test_efetch(id_list: List[str]) -> None:
    """UID一覧から FASTA レコードを取得する"""
    print(f"\n{SEPARATOR}")
    print("2. EFetch — レコード取得 (FASTA)")
    print(SEPARATOR)

    if not id_list:
        log("⚠  ESearch の結果が 0 件のため、EFetch はスキップします")
        return

    # 最大3件まで取得
    ids_to_fetch = id_list[:3]
    params = {
        "db": "nucleotide",
        "id": ",".join(ids_to_fetch),
        "rettype": "fasta",
        "retmode": "text",
        "tool": TOOL,
        "email": EMAIL,
    }
    url = f"{BASE_URL}/efetch.fcgi"
    log(f"リクエスト: {url}")
    log(f"取得対象 UID: {ids_to_fetch}")

    raw = fetch_url(url, params)

    print("\n--- レスポンス (FASTA) ---")
    # 長い場合は先頭 2000 文字のみ表示
    if len(raw) > 2000:
        print(raw[:2000])
        print(f"\n... (残り {len(raw) - 2000} 文字省略)")
    else:
        print(raw)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. ESummary — 検索結果のドキュメントサマリーを取得
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def test_esummary(id_list: List[str]) -> None:
    """UID一覧からドキュメントサマリーを取得する"""
    print(f"\n{SEPARATOR}")
    print("3. ESummary — ドキュメントサマリー取得")
    print(SEPARATOR)

    if not id_list:
        log("⚠  ESearch の結果が 0 件のため、ESummary はスキップします")
        return

    ids_to_fetch = id_list[:3]
    params = {
        "db": "nucleotide",
        "id": ",".join(ids_to_fetch),
        "retmode": "json",
        "tool": TOOL,
        "email": EMAIL,
    }
    url = f"{BASE_URL}/esummary.fcgi"
    log(f"リクエスト: {url}")
    log(f"取得対象 UID: {ids_to_fetch}")

    raw = fetch_url(url, params)
    result = json.loads(raw)

    print("\n--- レスポンス (JSON) ---")
    print(json.dumps(result, indent=2, ensure_ascii=False))


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. BLAST — 配列類似性検索 (blastn)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def _submit_blast(params: dict) -> Optional[str]:
    """BLAST ジョブを投入し RID を返す。失敗時は None。"""
    log("BLAST ジョブを投入中...")
    log(f"リクエスト: {BLAST_URL}")
    log(f"パラメータ: {', '.join(f'{k}={v}' for k, v in params.items() if k not in ('CMD', 'TOOL', 'EMAIL'))}")

    raw = fetch_url(BLAST_URL, params, method="POST")

    rid = None
    rtoe = None
    for line in raw.splitlines():
        if line.strip().startswith("RID ="):
            rid = line.split("=")[1].strip()
        if line.strip().startswith("RTOE ="):
            rtoe = line.split("=")[1].strip()

    if not rid:
        log("⚠  BLAST ジョブの RID が取得できませんでした")
        print("\n--- レスポンス (raw) ---")
        print(raw[:3000])
        return None

    log(f"RID (Request ID): {rid}")
    log(f"RTOE (推定待ち時間): {rtoe} 秒")

    # ポーリング
    wait_sec = int(rtoe) if rtoe else 15
    log(f"推定待ち時間 {wait_sec} 秒を待機してからポーリング開始...")
    time.sleep(min(wait_sec, 30))

    max_polls = 20
    for i in range(max_polls):
        check_params = {
            "CMD": "Get",
            "FORMAT_OBJECT": "SearchInfo",
            "RID": rid,
        }
        status_raw = fetch_url(BLAST_URL, check_params)

        if "Status=WAITING" in status_raw:
            log(f"  ポーリング {i + 1}/{max_polls}: WAITING... (60秒後に再試行)")
            time.sleep(60)
        elif "Status=FAILED" in status_raw:
            log("⚠  BLAST ジョブが FAILED になりました")
            return None
        elif "Status=UNKNOWN" in status_raw:
            log("⚠  BLAST ジョブが UNKNOWN ステータスです")
            return None
        elif "Status=READY" in status_raw:
            log("✅ BLAST ジョブ完了 (READY)")
            return rid
    log("⚠  ポーリング上限に達しました")
    return rid


def _fetch_blast_hits(rid: str) -> list:
    """RID から BLAST 結果 (XML) を取得し、Hit 要素のリストを返す。"""
    get_params = {
        "CMD": "Get",
        "FORMAT_TYPE": "XML",
        "RID": rid,
    }
    log("BLAST 結果を取得中 (XML形式)...")
    result_raw = fetch_url(BLAST_URL, get_params)

    try:
        root = ET.fromstring(result_raw)
        return root.findall('.//Hit'), root
    except ET.ParseError as e:
        log(f"XML パースエラー: {e}")
        print(result_raw[:3000])
        return [], None


def _print_hits(hits: list, root, title: str, show_top_n: int = 10) -> None:
    """BLAST ヒット一覧を見やすく表示する"""
    query_len = len(SEQUENCE)

    if not hits:
        log("ヒットなし")
        return

    # --- ヒット情報を収集 ---
    hit_data = []
    for hit in hits:
        hit_def = hit.findtext('Hit_def', 'N/A')
        hit_accession = hit.findtext('Hit_accession', 'N/A')
        hit_len = hit.findtext('Hit_len', 'N/A')

        hsp = hit.find('.//Hsp')
        if hsp is not None:
            bit_score = hsp.findtext('Hsp_bit-score', 'N/A')
            evalue = hsp.findtext('Hsp_evalue', 'N/A')
            identity = int(hsp.findtext('Hsp_identity', '0'))
            align_len = int(hsp.findtext('Hsp_align-len', '1'))
            qseq = hsp.findtext('Hsp_qseq', '')
            hseq = hsp.findtext('Hsp_hseq', '')
            midline = hsp.findtext('Hsp_midline', '')
            identity_pct = (identity / align_len) * 100 if align_len > 0 else 0.0
            # クエリカバレッジ = アラインメント長 / クエリ長
            coverage = (align_len / query_len) * 100 if query_len > 0 else 0.0

            hit_data.append({
                "accession": hit_accession,
                "description": hit_def,
                "hit_len": hit_len,
                "bit_score": bit_score,
                "evalue": evalue,
                "identity": identity,
                "align_len": align_len,
                "identity_pct": identity_pct,
                "coverage": coverage,
                "qseq": qseq,
                "hseq": hseq,
                "midline": midline,
            })

    if not hit_data:
        log("ヒットなし")
        return

    # カバレッジ(高い順) → 一致率(高い順) でソート
    hit_data.sort(key=lambda x: (x["coverage"], x["identity_pct"]), reverse=True)

    # 完全一致があるか確認
    perfect = [h for h in hit_data if h["identity_pct"] >= 100.0 and h["coverage"] >= 100.0]

    print(f"\n--- {title} ---")
    log(f"ヒット件数: {len(hit_data)}")

    if perfect:
        log(f"★ 完全一致: {len(perfect)} 件")
    else:
        best = hit_data[0]
        log(f"★ 完全一致なし → 最も一致率の高い配列を表示します")
        log(f"  最高一致率: {best['identity_pct']:.1f}% "
            f"(一致: {best['identity']}/{best['align_len']}bp, "
            f"カバレッジ: {best['coverage']:.1f}%)")

    # テーブル表示
    print(f"\n{'#':<4} {'Accession':<18} {'E-value':<12} {'Score':<8} "
          f"{'一致率':<10} {'カバレッジ':<10} {'Description'}")
    print("-" * 110)

    for j, h in enumerate(hit_data[:show_top_n]):
        desc_short = h["description"][:50] if h["description"] else 'N/A'
        ident_str = f"{h['identity_pct']:.1f}%"
        cov_str = f"{h['coverage']:.1f}%"
        print(f"{j+1:<4} {h['accession']:<18} {h['evalue']:<12} "
              f"{h['bit_score']:<8} {ident_str:<10} {cov_str:<10} {desc_short}")

        # 上位3件はアラインメントも表示
        if j < 3:
            print(f"     配列長: {h['hit_len']} bp | "
                  f"一致: {h['identity']}/{h['align_len']}bp")
            print(f"     Query:   {h['qseq']}")
            print(f"     Match:   {h['midline']}")
            print(f"     Subject: {h['hseq']}")
            print()

    # 統計情報
    if root is not None:
        stat = root.find('.//Statistics')
        if stat is not None:
            print("--- BLAST 統計情報 ---")
            print(f"  DB 配列数:    {stat.findtext('Statistics_db-num', 'N/A')}")
            print(f"  DB 総塩基数:  {stat.findtext('Statistics_db-len', 'N/A')}")


def test_blast() -> None:
    """NCBI BLAST REST API を使って blastn 検索を実行する。
    完全一致がない場合は、パラメータを緩和して再検索し、
    最も一致率の高い配列を出力する。"""
    print(f"\n{SEPARATOR}")
    print("4. BLAST — 配列類似性検索 (blastn)")
    print(SEPARATOR)

    # ================================================================
    # ステップ 1: 通常パラメータで検索
    # ================================================================
    log("── ステップ 1: 通常パラメータで検索 ──")
    params_normal = {
        "CMD": "Put",
        "PROGRAM": "blastn",
        "DATABASE": "nt",
        "QUERY": SEQUENCE,
        "TOOL": TOOL,
        "EMAIL": EMAIL,
    }
    rid = _submit_blast(params_normal)
    if not rid:
        return

    hits, root = _fetch_blast_hits(rid)

    if hits:
        _print_hits(hits, root, "BLAST ヒット一覧 (通常検索)")
        return  # ヒットがあればここで終了

    # ================================================================
    # ステップ 2: ヒットなし → 緩和パラメータで再検索
    # ================================================================
    log("")
    log("── ステップ 2: 通常検索でヒットなし → パラメータを緩和して再検索 ──")
    log("  WORD_SIZE=7, EXPECT=100000, FILTER=none, NUCL_PENALTY=-1, NUCL_REWARD=1")
    log("  (短い配列・部分一致でもヒットしやすい設定)")

    time.sleep(10)  # NCBI レート制限対応

    params_relaxed = {
        "CMD": "Put",
        "PROGRAM": "blastn",
        "MEGABLAST": "no",
        "DATABASE": "nt",
        "QUERY": SEQUENCE,
        "WORD_SIZE": "7",
        "EXPECT": "100000",
        "NUCL_PENALTY": "-1",
        "NUCL_REWARD": "1",
        "GAPCOSTS": "2 1",
        "HITLIST_SIZE": "20",
        "FILTER": "none",
        "TOOL": TOOL,
        "EMAIL": EMAIL,
    }
    rid2 = _submit_blast(params_relaxed)
    if not rid2:
        log("⚠  緩和検索でもジョブ投入に失敗しました")
        return

    hits2, root2 = _fetch_blast_hits(rid2)
    if hits2:
        _print_hits(hits2, root2, "BLAST ヒット一覧 (緩和検索 — 最も一致率の高い配列)")
    else:
        log("⚠  緩和パラメータでもヒットが見つかりませんでした")
        log("  この配列はデータベース上のどの配列とも有意な類似性がありません")
        if root2 is not None:
            stat = root2.find('.//Statistics')
            if stat is not None:
                print("\n--- BLAST 統計情報 ---")
                print(f"  DB 配列数:    {stat.findtext('Statistics_db-num', 'N/A')}")
                print(f"  DB 総塩基数:  {stat.findtext('Statistics_db-len', 'N/A')}")


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# メイン
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def main():
    print(SEPARATOR)
    print("  NCBI E-utilities & BLAST API 検証")
    print(f"  配列: {SEQUENCE}")
    print(f"  配列長: {len(SEQUENCE)} bp")
    print(f"  実行日時: {datetime.now().isoformat()}")
    print(SEPARATOR)

    # --- E-utilities ---
    try:
        id_list = test_esearch()
    except Exception as e:
        log(f"❌ ESearch エラー: {e}")
        id_list = []

    time.sleep(1)  # NCBI レート制限対応

    try:
        test_efetch(id_list)
    except Exception as e:
        log(f"❌ EFetch エラー: {e}")

    time.sleep(1)

    try:
        test_esummary(id_list)
    except Exception as e:
        log(f"❌ ESummary エラー: {e}")

    time.sleep(1)

    # --- BLAST ---
    try:
        test_blast()
    except Exception as e:
        log(f"❌ BLAST エラー: {e}")

    print(f"\n{SEPARATOR}")
    print("  検証完了")
    print(SEPARATOR)


if __name__ == "__main__":
    main()
