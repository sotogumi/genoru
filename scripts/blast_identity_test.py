#!/usr/bin/env python3
"""
配列類似性検索 + 一致率表示 検証スクリプト

対象配列: ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA
EBI NCBI BLAST+ API を使い、最も類似する配列とその一致率（identity）を取得する

検証目的:
  - 完全一致する配列がなくても、最も一致率の高い配列を見つけられるか
  - 一致率 (%) を表示できるか
"""

import json
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime
from typing import Optional

SEQUENCE = "ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA"
BLAST_BASE_URL = "https://www.ebi.ac.uk/Tools/services/rest/ncbiblast"
EMAIL = "test@example.com"

SEPARATOR = "=" * 70


def log(msg: str) -> None:
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] {msg}")


def fetch_url(url: str, data: Optional[dict] = None, method: str = "GET") -> str:
    if data and method == "GET":
        url = f"{url}?{urllib.parse.urlencode(data)}"
        req = urllib.request.Request(url)
    elif data and method == "POST":
        encoded = urllib.parse.urlencode(data).encode("utf-8")
        req = urllib.request.Request(url, data=encoded)
    else:
        req = urllib.request.Request(url)

    req.add_header("User-Agent", "genoru_api_test/1.0 (Python)")
    req.add_header("Accept", "*/*")

    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            return resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        log(f"  HTTP Error {e.code}: {e.reason}")
        log(f"  Response: {body[:500]}")
        raise


def check_previous_job(job_id: str) -> Optional[str]:
    """以前のジョブのステータスを確認"""
    try:
        status = fetch_url(f"{BLAST_BASE_URL}/status/{job_id}").strip()
        return status
    except Exception:
        return None


def submit_blast_job(database: str) -> Optional[str]:
    """BLAST ジョブを投入し、Job ID を返す"""
    params = {
        "email": EMAIL,
        "stype": "dna",
        "program": "blastn",
        "database": database,
        "sequence": f">query\n{SEQUENCE}",
        "exp": "10",        # E-value threshold
        "scores": 10,       # 上位10件のスコア表示
        "alignments": 5,    # 上位5件のアライメント表示
    }
    log(f"BLAST ジョブ投入: database={database}")
    try:
        job_id = fetch_url(f"{BLAST_BASE_URL}/run", params, method="POST").strip()
        log(f"Job ID: {job_id}")
        return job_id
    except Exception as e:
        log(f"⚠  ジョブ投入失敗: {e}")
        return None


def wait_for_job(job_id: str, max_polls: int = 60, interval: int = 10) -> str:
    """ジョブ完了を待機"""
    for i in range(max_polls):
        time.sleep(interval)
        try:
            status = fetch_url(f"{BLAST_BASE_URL}/status/{job_id}").strip()
        except Exception:
            continue

        log(f"  ポーリング {i + 1}/{max_polls}: {status}")

        if status == "FINISHED":
            return status
        elif status in ("ERROR", "FAILURE", "NOT_FOUND"):
            return status

    return "TIMEOUT"


def parse_blast_xml(xml_text: str) -> list:
    """BLAST XML 結果から一致率情報を抽出"""
    hits = []
    try:
        root = ET.fromstring(xml_text)
        # BLAST XML format の解析
        for iteration in root.findall(".//Iteration"):
            for hit in iteration.findall(".//Hit"):
                hit_def = hit.findtext("Hit_def", "N/A")
                hit_accession = hit.findtext("Hit_accession", "N/A")
                hit_len = hit.findtext("Hit_len", "0")

                for hsp in hit.findall(".//Hsp"):
                    identity = int(hsp.findtext("Hsp_identity", "0"))
                    align_len = int(hsp.findtext("Hsp_align-len", "1"))
                    gaps = int(hsp.findtext("Hsp_gaps", "0"))
                    evalue = hsp.findtext("Hsp_evalue", "N/A")
                    bit_score = hsp.findtext("Hsp_bit-score", "N/A")
                    qseq = hsp.findtext("Hsp_qseq", "")
                    hseq = hsp.findtext("Hsp_hseq", "")
                    midline = hsp.findtext("Hsp_midline", "")
                    query_from = hsp.findtext("Hsp_query-from", "")
                    query_to = hsp.findtext("Hsp_query-to", "")
                    hit_from = hsp.findtext("Hsp_hit-from", "")
                    hit_to = hsp.findtext("Hsp_hit-to", "")

                    identity_pct = (identity / align_len * 100) if align_len > 0 else 0

                    hits.append({
                        "accession": hit_accession,
                        "description": hit_def[:100],
                        "hit_length": hit_len,
                        "identity": identity,
                        "align_length": align_len,
                        "identity_pct": round(identity_pct, 2),
                        "gaps": gaps,
                        "evalue": evalue,
                        "bit_score": bit_score,
                        "query_range": f"{query_from}-{query_to}",
                        "hit_range": f"{hit_from}-{hit_to}",
                        "query_seq": qseq,
                        "hit_seq": hseq,
                        "midline": midline,
                    })

    except ET.ParseError as e:
        log(f"  XML パースエラー: {e}")

    # 一致率の高い順にソート
    hits.sort(key=lambda x: x["identity_pct"], reverse=True)
    return hits


def display_results(hits: list) -> None:
    """結果を見やすく表示"""
    if not hits:
        log("ヒットなし — 類似配列が見つかりませんでした")
        return

    print(f"\n{'─' * 70}")
    print(f"  配列類似性検索結果 — 上位 {min(len(hits), 10)} 件")
    print(f"  クエリ配列: {SEQUENCE} ({len(SEQUENCE)} bp)")
    print(f"{'─' * 70}")

    print(f"\n{'No':>3} | {'一致率':>8} | {'Identity':>10} | {'E-value':>12} | {'Accession':<15} | 説明")
    print(f"{'─' * 100}")

    for i, hit in enumerate(hits[:10]):
        pct_bar = "█" * int(hit["identity_pct"] / 5) + "░" * (20 - int(hit["identity_pct"] / 5))
        print(
            f"{i + 1:>3} | {hit['identity_pct']:>6.1f}% | "
            f"{hit['identity']:>3}/{hit['align_length']:<4} | "
            f"{hit['evalue']:>12} | "
            f"{hit['accession']:<15} | "
            f"{hit['description'][:50]}"
        )

    # 最高一致率のヒットの詳細を表示
    best = hits[0]
    print(f"\n{'─' * 70}")
    print(f"  最高一致率ヒット詳細")
    print(f"{'─' * 70}")
    print(f"  Accession  : {best['accession']}")
    print(f"  説明       : {best['description']}")
    print(f"  一致率     : {best['identity_pct']}% ({best['identity']}/{best['align_length']})")
    print(f"  E-value    : {best['evalue']}")
    print(f"  Bit Score  : {best['bit_score']}")
    print(f"  クエリ範囲 : {best['query_range']}")
    print(f"  ヒット範囲 : {best['hit_range']}")
    print(f"  Gaps       : {best['gaps']}")
    print(f"\n  アライメント:")
    print(f"    Query: {best['query_seq']}")
    print(f"           {best['midline']}")
    print(f"    Sbjct: {best['hit_seq']}")


def main():
    print(SEPARATOR)
    print("  EBI BLAST — 配列類似性検索 + 一致率検証")
    print(f"  配列: {SEQUENCE}")
    print(f"  配列長: {len(SEQUENCE)} bp")
    print(f"  実行日時: {datetime.now().isoformat()}")
    print(SEPARATOR)

    # --- 以前のジョブをチェック ---
    previous_jobs = [
        "ncbiblast-R20260228-162636-0467-79020051-p1m",
        "ncbiblast-R20260228-163338-0860-34679689-p1m",
    ]

    job_id = None
    for prev_id in previous_jobs:
        log(f"以前のジョブを確認: {prev_id}")
        status = check_previous_job(prev_id)
        if status:
            log(f"  ステータス: {status}")
            if status == "FINISHED":
                job_id = prev_id
                log(f"✅ 以前のジョブが完了しています！ 結果を取得します")
                break

    # --- ジョブが完了していなければ新規投入 ---
    if not job_id:
        log("新規 BLAST ジョブを投入します...")
        # em_vrl (ウイルス) は小さいので高速
        job_id = submit_blast_job("em_vrl")
        if not job_id:
            log("❌ ジョブ投入に失敗しました")
            return

        status = wait_for_job(job_id, max_polls=60, interval=10)
        if status != "FINISHED":
            log(f"❌ ジョブが完了しませんでした: {status}")
            return

    # --- 結果タイプ確認 ---
    log("利用可能な結果タイプを確認中...")
    try:
        types_xml = fetch_url(f"{BLAST_BASE_URL}/resulttypes/{job_id}")
        types_root = ET.fromstring(types_xml)
        available_types = []
        for t in types_root.findall(".//type"):
            identifier = t.findtext("identifier", "")
            label = t.findtext("label", "")
            available_types.append(identifier)
            log(f"  - {identifier}: {label}")
    except Exception as e:
        log(f"  結果タイプ取得エラー: {e}")
        available_types = ["xml", "out"]

    # --- XML形式で結果取得 (一致率の詳細パース用) ---
    log("BLAST 結果を XML 形式で取得中...")
    try:
        xml_result = fetch_url(f"{BLAST_BASE_URL}/result/{job_id}/xml")
        hits = parse_blast_xml(xml_result)
        display_results(hits)
    except Exception as e:
        log(f"  XML 結果取得エラー: {e}")
        hits = []

    # --- テキスト形式でも結果取得 ---
    log("\nBLAST 結果をテキスト形式でも取得中...")
    try:
        text_result = fetch_url(f"{BLAST_BASE_URL}/result/{job_id}/out")
        print(f"\n{'─' * 70}")
        print("  BLAST テキスト出力 (先頭 3000 文字)")
        print(f"{'─' * 70}")
        print(text_result[:3000])
        if len(text_result) > 3000:
            print(f"\n... (残り {len(text_result) - 3000} 文字省略)")
    except Exception as e:
        log(f"  テキスト結果取得エラー: {e}")

    # --- 結果保存 ---
    import os
    results = {
        "query_sequence": SEQUENCE,
        "query_length": len(SEQUENCE),
        "job_id": job_id,
        "timestamp": datetime.now().isoformat(),
        "hits_count": len(hits),
        "best_identity_pct": hits[0]["identity_pct"] if hits else None,
        "hits": hits[:10],
    }
    results_path = os.path.join(os.path.dirname(__file__), "blast_identity_results.json")
    with open(results_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    log(f"\n結果を {results_path} に保存しました")

    print(f"\n{SEPARATOR}")
    print("  検証完了")
    print(SEPARATOR)


if __name__ == "__main__":
    main()
