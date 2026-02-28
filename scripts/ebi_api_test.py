#!/usr/bin/env python3
"""
EMBL-EBI API 検証スクリプト (NCBI E-utilities 代替)

対象配列: ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA
以下のAPIを順番に検証します:
  1. ENA Text Search  — ENA nucleotide データベースで配列をテキスト検索 (ESearch 代替)
  2. ENA FASTA Fetch   — 検索結果のレコードを FASTA 形式で取得 (EFetch 代替)
  3. ENA XML Fetch     — 検索結果のドキュメントサマリーを取得 (ESummary 代替)
  4. EBI BLAST          — 配列類似性検索（blastn）を実行し結果を取得 (NCBI BLAST 代替)

参考:
  - ENA Browser API: https://www.ebi.ac.uk/ena/browser/api/
  - EBI Job Dispatcher: https://www.ebi.ac.uk/Tools/services/rest/ncbiblast
"""

import json
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime
from typing import Optional, List, Dict, Any

# ─── 設定 ───────────────────────────────────────────────
SEQUENCE = "ATGCTAGCTAGCTAGCTAGCTAGCTAGCTA"
ENA_BROWSER_URL = "https://www.ebi.ac.uk/ena/browser/api"
ENA_PORTAL_URL = "https://www.ebi.ac.uk/ena/portal/api"
BLAST_BASE_URL = "https://www.ebi.ac.uk/Tools/services/rest/ncbiblast"

# EBI は email パラメータの使用を推奨
TOOL = "genoru_api_test"
EMAIL = "test@example.com"  # BLAST ジョブ投入に必要

SEPARATOR = "=" * 70

# 結果を格納するグローバル辞書
RESULTS: Dict[str, Any] = {}


def log(msg: str) -> None:
    """タイムスタンプ付きログ出力"""
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] {msg}")


def fetch_url(url: str, data: Optional[dict] = None, method: str = "GET",
              content_type: Optional[str] = None) -> str:
    """簡易HTTPリクエスト (GET/POST)"""
    if data and method == "GET":
        url = f"{url}?{urllib.parse.urlencode(data)}"
        req = urllib.request.Request(url)
    elif data and method == "POST":
        encoded = urllib.parse.urlencode(data).encode("utf-8")
        req = urllib.request.Request(url, data=encoded)
        if content_type:
            req.add_header("Content-Type", content_type)
    else:
        req = urllib.request.Request(url)

    req.add_header("User-Agent", f"{TOOL}/1.0 (Python)")
    req.add_header("Accept", "*/*")

    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        log(f"  HTTP Error {e.code}: {e.reason}")
        log(f"  Response: {body[:500]}")
        raise


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. ENA Text Search — nucleotide データベースでテキスト検索
#    (NCBI ESearch の代替)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def test_ena_search() -> List[str]:
    """配列をキーワードとして ENA を検索し、アクセッション一覧を返す"""
    print(f"\n{SEPARATOR}")
    print("1. ENA Text Search — nucleotide データベース検索 (ESearch 代替)")
    print(SEPARATOR)

    params = {
        "result": "sequence",
        "query": f'description="*ATGCTAGC*"',
        "fields": "accession,description,base_count",
        "limit": 10,
        "format": "tsv",
    }
    url = f"{ENA_PORTAL_URL}/search"
    log(f"リクエスト: {url}")
    log(f"パラメータ: {json.dumps(params, indent=2)}")

    accessions = []
    result_info = {
        "api": "ENA Text Search",
        "url": url,
        "params": params,
        "status": "unknown",
        "response": None,
        "accessions": [],
        "error": None,
    }

    try:
        raw = fetch_url(url, params)
        print("\n--- レスポンス (TSV) ---")
        print(raw[:2000] if len(raw) > 2000 else raw)

        # TSV のパース: 1行目がヘッダー
        lines = raw.strip().split("\n")
        if len(lines) > 1:
            for line in lines[1:]:
                cols = line.split("\t")
                if cols:
                    accessions.append(cols[0])

        log(f"ヒット件数: {len(accessions)}")
        log(f"取得したアクセッション一覧: {accessions}")

        result_info["status"] = "success"
        result_info["response"] = raw[:2000]
        result_info["accessions"] = accessions
    except Exception as e:
        log(f"⚠ 検索エラー: {e}")
        result_info["status"] = "error"
        result_info["error"] = str(e)

    RESULTS["ena_search"] = result_info
    return accessions


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. ENA FASTA Fetch — レコードを FASTA 形式で取得
#    (NCBI EFetch の代替)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def test_ena_fetch(accessions: List[str]) -> None:
    """アクセッション一覧から FASTA レコードを取得する"""
    print(f"\n{SEPARATOR}")
    print("2. ENA FASTA Fetch — レコード取得 (EFetch 代替)")
    print(SEPARATOR)

    result_info = {
        "api": "ENA FASTA Fetch",
        "status": "unknown",
        "records": [],
        "error": None,
    }

    if not accessions:
        log("⚠  ENA Search の結果が 0 件のため、FASTA Fetch はスキップします")
        result_info["status"] = "skipped"
        result_info["error"] = "検索結果が 0 件"
        RESULTS["ena_fetch"] = result_info
        return

    # 最大3件まで取得
    accs_to_fetch = accessions[:3]

    for acc in accs_to_fetch:
        url = f"{ENA_BROWSER_URL}/fasta/{acc}"
        log(f"リクエスト: {url}")
        record = {"accession": acc, "url": url, "status": "unknown"}

        try:
            raw = fetch_url(url)
            print(f"\n--- {acc} (FASTA) ---")
            print(raw[:1000] if len(raw) > 1000 else raw)
            record["status"] = "success"
            record["response"] = raw[:1000]
        except Exception as e:
            log(f"⚠ {acc} の取得に失敗: {e}")
            record["status"] = "error"
            record["error"] = str(e)

        result_info["records"].append(record)

    result_info["status"] = "success" if any(
        r["status"] == "success" for r in result_info["records"]
    ) else "error"
    RESULTS["ena_fetch"] = result_info


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. ENA XML Fetch — ドキュメントサマリーを取得
#    (NCBI ESummary の代替)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def test_ena_summary(accessions: List[str]) -> None:
    """アクセッション一覧から XML サマリーを取得する"""
    print(f"\n{SEPARATOR}")
    print("3. ENA XML Fetch — サマリー取得 (ESummary 代替)")
    print(SEPARATOR)

    result_info = {
        "api": "ENA XML Fetch",
        "status": "unknown",
        "records": [],
        "error": None,
    }

    if not accessions:
        log("⚠  ENA Search の結果が 0 件のため、XML Fetch はスキップします")
        result_info["status"] = "skipped"
        result_info["error"] = "検索結果が 0 件"
        RESULTS["ena_summary"] = result_info
        return

    accs_to_fetch = accessions[:3]

    for acc in accs_to_fetch:
        url = f"{ENA_BROWSER_URL}/xml/{acc}"
        log(f"リクエスト: {url}")
        record = {"accession": acc, "url": url, "status": "unknown"}

        try:
            raw = fetch_url(url)
            print(f"\n--- {acc} (XML) ---")
            print(raw[:1500] if len(raw) > 1500 else raw)

            # XML から主要情報を抽出
            try:
                root = ET.fromstring(raw)
                entry = root.find(".//{http://www.ebi.ac.uk/ena/data/xsd}entry") or root.find(".//entry")
                if entry is not None:
                    record["accession_parsed"] = entry.get("accession", "N/A")
                    record["description"] = entry.get("description", "N/A")
                    record["sequence_length"] = entry.get("sequenceLength", "N/A")
            except ET.ParseError:
                pass

            record["status"] = "success"
            record["response"] = raw[:1500]
        except Exception as e:
            log(f"⚠ {acc} の取得に失敗: {e}")
            record["status"] = "error"
            record["error"] = str(e)

        result_info["records"].append(record)

    result_info["status"] = "success" if any(
        r["status"] == "success" for r in result_info["records"]
    ) else "error"
    RESULTS["ena_summary"] = result_info


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. EBI BLAST — 配列類似性検索 (blastn)
#    (NCBI BLAST REST API の代替)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def test_ebi_blast() -> None:
    """EBI Job Dispatcher BLAST API を使って blastn 検索を実行する"""
    print(f"\n{SEPARATOR}")
    print("4. EBI BLAST — 配列類似性検索 (blastn) (NCBI BLAST 代替)")
    print(SEPARATOR)

    result_info = {
        "api": "EBI NCBI BLAST+",
        "status": "unknown",
        "job_id": None,
        "hits": [],
        "error": None,
    }

    # --- 4a. ジョブ投入 (POST /run) ---
    run_params = {
        "email": EMAIL,
        "stype": "dna",
        "program": "blastn",
        "database": "em_all",
        "sequence": f">query\n{SEQUENCE}",
    }
    run_url = f"{BLAST_BASE_URL}/run"
    log("BLAST ジョブを投入中...")
    log(f"リクエスト: POST {run_url}")
    log(f"パラメータ: program=blastn, database=em_all, stype=dna")

    try:
        job_id = fetch_url(run_url, run_params, method="POST")
        job_id = job_id.strip()
    except Exception as e:
        log(f"⚠  BLAST ジョブ投入に失敗: {e}")
        result_info["status"] = "error"
        result_info["error"] = f"ジョブ投入失敗: {e}"
        RESULTS["ebi_blast"] = result_info
        return

    if not job_id:
        log("⚠  BLAST ジョブの Job ID が取得できませんでした")
        result_info["status"] = "error"
        result_info["error"] = "Job ID なし"
        RESULTS["ebi_blast"] = result_info
        return

    log(f"Job ID: {job_id}")
    result_info["job_id"] = job_id

    # --- 4b. ステータスポーリング ---
    status_url = f"{BLAST_BASE_URL}/status/{job_id}"
    log("ジョブ完了を待機中...")

    max_polls = 30
    poll_interval = 10  # 秒
    final_status = "UNKNOWN"

    for i in range(max_polls):
        time.sleep(poll_interval)
        try:
            status = fetch_url(status_url).strip()
        except Exception as e:
            log(f"  ポーリング {i + 1}/{max_polls}: ステータス確認エラー: {e}")
            continue

        log(f"  ポーリング {i + 1}/{max_polls}: {status}")

        if status == "FINISHED":
            final_status = status
            log("✅ BLAST ジョブ完了 (FINISHED)")
            break
        elif status in ("ERROR", "FAILURE", "NOT_FOUND"):
            final_status = status
            log(f"⚠  BLAST ジョブが {status} になりました")
            result_info["status"] = "error"
            result_info["error"] = f"ジョブステータス: {status}"
            RESULTS["ebi_blast"] = result_info
            return
        elif status == "RUNNING":
            continue
        else:
            log(f"  不明なステータス: {status}")
    else:
        log("⚠  ポーリング上限に達しました")
        result_info["status"] = "error"
        result_info["error"] = "ポーリング上限超過"
        RESULTS["ebi_blast"] = result_info
        return

    # --- 4c. 結果タイプ確認 ---
    try:
        types_url = f"{BLAST_BASE_URL}/resulttypes/{job_id}"
        types_raw = fetch_url(types_url)
        log(f"利用可能な結果タイプ:")
        try:
            root = ET.fromstring(types_raw)
            for t in root.findall(".//type"):
                identifier = t.find("identifier")
                label = t.find("label")
                if identifier is not None:
                    log(f"  - {identifier.text}: {label.text if label is not None else ''}")
        except ET.ParseError:
            log(f"  {types_raw[:500]}")
    except Exception:
        pass

    # --- 4d. テキスト結果取得 ---
    result_url = f"{BLAST_BASE_URL}/result/{job_id}/out"
    log(f"BLAST 結果を取得中 (テキスト)...")

    try:
        result_raw = fetch_url(result_url)
        print("\n--- BLAST 結果 (テキスト, 先頭部分) ---")
        if len(result_raw) > 5000:
            print(result_raw[:5000])
            print(f"\n... (残り {len(result_raw) - 5000} 文字省略)")
        else:
            print(result_raw)

        result_info["status"] = "success"
        result_info["response_text"] = result_raw[:5000]

        # ヒット情報を簡易パース
        hits = []
        in_hits = False
        for line in result_raw.splitlines():
            if "Sequences producing significant alignments" in line:
                in_hits = True
                continue
            if in_hits and line.strip() == "":
                if hits:
                    break
                continue
            if in_hits and line.strip():
                hits.append(line.strip())
        if hits:
            result_info["hits"] = hits[:10]
            log(f"ヒット件数 (上位): {len(hits)}")
            for j, h in enumerate(hits[:5]):
                log(f"  {j + 1}. {h[:100]}")
        else:
            log("ヒットなし、またはテキスト形式からの解析失敗")

    except Exception as e:
        log(f"⚠  結果取得エラー: {e}")
        result_info["status"] = "error"
        result_info["error"] = f"結果取得失敗: {e}"

    RESULTS["ebi_blast"] = result_info


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# メイン
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def main():
    print(SEPARATOR)
    print("  EMBL-EBI API 検証 (NCBI E-utilities 代替)")
    print(f"  配列: {SEQUENCE}")
    print(f"  配列長: {len(SEQUENCE)} bp")
    print(f"  実行日時: {datetime.now().isoformat()}")
    print(SEPARATOR)

    # --- 1. ENA Text Search ---
    try:
        accessions = test_ena_search()
    except Exception as e:
        log(f"❌ ENA Search エラー: {e}")
        RESULTS["ena_search"] = {"status": "error", "error": str(e)}
        accessions = []

    time.sleep(1)

    # --- 2. ENA FASTA Fetch ---
    try:
        test_ena_fetch(accessions)
    except Exception as e:
        log(f"❌ ENA Fetch エラー: {e}")
        RESULTS["ena_fetch"] = {"status": "error", "error": str(e)}

    time.sleep(1)

    # --- 3. ENA XML Fetch ---
    try:
        test_ena_summary(accessions)
    except Exception as e:
        log(f"❌ ENA Summary エラー: {e}")
        RESULTS["ena_summary"] = {"status": "error", "error": str(e)}

    time.sleep(1)

    # --- 4. EBI BLAST ---
    try:
        test_ebi_blast()
    except Exception as e:
        log(f"❌ EBI BLAST エラー: {e}")
        RESULTS["ebi_blast"] = {"status": "error", "error": str(e)}

    print(f"\n{SEPARATOR}")
    print("  検証完了")
    print(SEPARATOR)

    # --- 結果をJSONファイルに保存 ---
    import os
    results_path = os.path.join(os.path.dirname(__file__), "ebi_api_results.json")
    with open(results_path, "w", encoding="utf-8") as f:
        json.dump(RESULTS, f, indent=2, ensure_ascii=False, default=str)
    log(f"結果を {results_path} に保存しました")


if __name__ == "__main__":
    main()
