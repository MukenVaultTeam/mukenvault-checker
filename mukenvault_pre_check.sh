#!/bin/bash

#================================================================
# MukenVault Pre-Installation Checker v1.4.0
# 新機能:
# - CPU世代自動判定
# - プロバイダー戦略分析
# - スコアリング精緻化
#================================================================

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Root権限チェック
if [[ $EUID -ne 0 ]]; then
   echo "このスクリプトはroot権限で実行する必要があります"
   echo "使用方法: sudo $0"
   exit 1
fi

# gccチェック
if ! command -v gcc &> /dev/null; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  エラー: gccが見つかりません${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "このスクリプトを実行するには、gccコンパイラが必要です。"
    echo ""
    echo -e "${CYAN}【インストール方法】${NC}"
    echo ""
    echo "  Ubuntu/Debian系:"
    echo -e "    ${GREEN}sudo apt-get update${NC}"
    echo -e "    ${GREEN}sudo apt-get install build-essential${NC}"
    echo ""
    echo "  CentOS/RHEL系:"
    echo -e "    ${GREEN}sudo yum install gcc${NC}"
    echo ""
    echo "  Fedora系:"
    echo -e "    ${GREEN}sudo dnf install gcc${NC}"
    echo ""
    echo "インストール後、再度このスクリプトを実行してください。"
    echo ""
    exit 1
fi

# 一時ディレクトリ作成
TEMP_DIR=$(mktemp -d)
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# レポートファイル名
REPORT_FILE="mukenvault_check_$(date +%Y%m%d_%H%M%S).txt"

# ヘッダー表示
clear
echo -e "${CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   MukenVault導入前システムチェッカー v1.4.0                 ║
║                                                              ║
║   あなたの環境でMukenVaultがどれだけの性能を発揮できるかを  ║
║   事前診断します                                            ║
║                                                              ║
║   🆕 CPU世代判定 / プロバイダー分析機能追加                ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""
echo "診断を開始します..."
echo "結果は $REPORT_FILE に保存されます"
echo ""
echo ""

# スコア変数初期化
TOTAL_SCORE=0
MAX_SCORE=100

#================================================================
# CPU世代判定関数
#================================================================
detect_cpu_generation() {
    local cpu_model="$1"
    local generation=""
    local year=""
    local arch=""
    local gen_score=0
    
    # Intel系の判定
    if echo "$cpu_model" | grep -qi "Sapphire Rapids"; then
        generation="Sapphire Rapids"
        year="2023"
        arch="Golden Cove"
        gen_score=10
    elif echo "$cpu_model" | grep -qi "Icelake\|Ice Lake"; then
        generation="Ice Lake"
        year="2019-2021"
        arch="Sunny Cove"
        gen_score=9
    elif echo "$cpu_model" | grep -qi "Cascade Lake"; then
        generation="Cascade Lake"
        year="2019"
        arch="Skylake改良版"
        gen_score=7
    elif echo "$cpu_model" | grep -qi "Skylake"; then
        generation="Skylake"
        year="2015-2017"
        arch="Skylake"
        gen_score=5
    elif echo "$cpu_model" | grep -qi "Broadwell"; then
        generation="Broadwell"
        year="2014-2015"
        arch="Broadwell"
        gen_score=4
    elif echo "$cpu_model" | grep -qi "Haswell"; then
        generation="Haswell"
        year="2013-2014"
        arch="Haswell"
        gen_score=3
    # Xeon型番からの判定
    elif echo "$cpu_model" | grep -qiE "E3-[0-9]{4} v6"; then
        generation="Kaby Lake"
        year="2017"
        arch="Kaby Lake"
        gen_score=6
    elif echo "$cpu_model" | grep -qiE "E3-[0-9]{4} v5"; then
        generation="Skylake"
        year="2015-2016"
        arch="Skylake"
        gen_score=5
    elif echo "$cpu_model" | grep -qiE "E5-[0-9]{4} v4"; then
        generation="Broadwell"
        year="2016"
        arch="Broadwell-EP"
        gen_score=4
    elif echo "$cpu_model" | grep -qiE "E5-[0-9]{4} v3"; then
        generation="Haswell"
        year="2014"
        arch="Haswell-EP"
        gen_score=3
    
    # AMD系の判定
    elif echo "$cpu_model" | grep -qi "EPYC.*Genoa"; then
        generation="EPYC Genoa"
        year="2022-2023"
        arch="Zen 4"
        gen_score=10
    elif echo "$cpu_model" | grep -qi "EPYC-Milan\|Milan"; then
        generation="EPYC Milan"
        year="2021"
        arch="Zen 3"
        gen_score=9
    elif echo "$cpu_model" | grep -qi "EPYC-Rome\|Rome"; then
        generation="EPYC Rome"
        year="2019"
        arch="Zen 2"
        gen_score=7
    elif echo "$cpu_model" | grep -qi "EPYC-Naples\|Naples"; then
        generation="EPYC Naples"
        year="2017"
        arch="Zen 1"
        gen_score=5
    
    else
        generation="Unknown"
        year="不明"
        arch="不明"
        gen_score=0
    fi
    
    echo "$generation|$year|$arch|$gen_score"
}

#================================================================
# プロバイダー戦略分析関数
#================================================================
analyze_provider_strategy() {
    local cpu_gen="$1"
    local cpu_year="$2"
    local vaes_support="$3"
    local expected_speed="$4"
    
    local strategy=""
    local target=""
    local stars=0
    
    # CPU世代から戦略を判定
    local year_int=$(echo "$cpu_year" | grep -oE "[0-9]{4}" | head -1)
    
    if [ -z "$year_int" ]; then
        year_int=0
    fi
    
    if [ "$year_int" -ge 2021 ] && [ "$vaes_support" = "yes" ]; then
        strategy="🟢 最新世代重視"
        target="本番環境・高付加価値サービス"
        stars=5
    elif [ "$year_int" -ge 2019 ] && [ "$vaes_support" = "yes" ]; then
        strategy="🟡 バランス型"
        target="中規模本番環境・開発環境"
        stars=4
    elif [ "$year_int" -ge 2017 ]; then
        strategy="🟠 コスト重視"
        target="開発・ステージング環境"
        stars=3
    elif [ "$year_int" -ge 2015 ]; then
        strategy="🔴 格安特化"
        target="バックアップ・検証環境のみ"
        stars=2
    else
        strategy="⚪ 不明"
        target="判定不可"
        stars=1
    fi
    
    echo "$strategy|$target|$stars"
}

#================================================================
# 推奨用途判定関数（改良版: スペック総合評価）
#================================================================
get_recommended_use_cases() {
    local expected_speed_int="$1"
    local cpu_gen="$2"
    local provider="$3"
    
    local use_cases=""
    
    # スペック総合評価
    local spec_tier="basic"
    if [ "$CPU_CORES" -ge 8 ] && [ "$MEM_TOTAL_INT" -ge 16 ] && [ "$VAES_AVAILABLE" -eq 1 ]; then
        spec_tier="enterprise"
    elif [ "$CPU_CORES" -ge 4 ] && [ "$MEM_TOTAL_INT" -ge 8 ] && [ "$VAES_AVAILABLE" -eq 1 ]; then
        spec_tier="business"
    elif [ "$CPU_CORES" -ge 4 ] && [ "$MEM_TOTAL_INT" -ge 4 ]; then
        spec_tier="standard"
    fi
    
    # Enterprise tier (8コア以上 + 16GB以上 + VAES)
    if [ "$spec_tier" = "enterprise" ]; then
        if [ "$expected_speed_int" -ge 20 ]; then
            use_cases="✅ エンタープライズWebアプリケーション
✅ 高トラフィックAPIサーバー
✅ データベースサーバー（大規模）
✅ コンテナオーケストレーション（Kubernetes）
✅ リアルタイム処理・ストリーミング

【エンタープライズクラス】
このスペックは、以下のような本番環境に最適です:
• 中堅〜大企業の基幹システム
• SaaS製品の本番環境
• 24/365稼働の重要システム
• 月間100万PV超のWebサービス"
        elif [ "$expected_speed_int" -ge 12 ]; then
            use_cases="✅ ビジネスWebアプリケーション
✅ APIサーバー（中〜高トラフィック）
✅ データベースサーバー（中〜大規模）
✅ コンテナ環境（Docker Compose/小規模K8s）
✅ CI/CDパイプライン

【ビジネスクラス】
このスペックは、以下のような用途に最適です:
• 中小企業の本番システム
• スタートアップのプロダクション環境
• 月間10万〜100万PVのWebサービス
• 部門サーバー・グループウェア"
        else
            use_cases="✅ Webアプリケーション
✅ APIサーバー
✅ データベースサーバー（中規模）
✅ 開発・ステージング環境
⚠️  高負荷本番環境（ベンチマーク推奨）

【準ビジネスクラス】
このスペックは、以下のような用途に適しています:
• 中小規模の本番システム
• 開発・ステージング環境
• 社内向けWebアプリケーション"
        fi
    
    # Business tier (4コア以上 + 8GB以上 + VAES)
    elif [ "$spec_tier" = "business" ]; then
        if [ "$expected_speed_int" -ge 15 ]; then
            use_cases="✅ Webアプリケーション
✅ APIサーバー
✅ データベースサーバー（中規模）
✅ ファイルサーバー

【ビジネス向け】
このクラスの性能は、以下のような用途に最適です:
• 中小企業の業務システム
• スタートアップのMVP環境
• 中規模ECサイト"
        else
            use_cases="✅ 軽量Webアプリケーション
✅ 開発・テスト環境
✅ ファイルサーバー
✅ CI/CD環境

【開発・テスト向け】
このクラスの性能は、以下のような用途に適しています:
• 開発・検証環境
• 社内ツール
• プロトタイプ"
        fi
    
    # Standard tier
    elif [ "$spec_tier" = "standard" ]; then
        use_cases="✅ 静的サイト・ブログ
✅ ファイルサーバー
✅ 開発・テスト環境
✅ バックアップサーバー
⚠️  軽量Webアプリ（トライアル推奨）

【標準向け】
このクラスの性能は、以下のような用途に最適です:
• 個人プロジェクト
• 社内ツール・イントラネット
• CI/CD環境"
    
    # Basic tier
    else
        use_cases="✅ 静的コンテンツ配信
✅ 個人用途
⚠️  開発・検証環境（負荷制限あり）
❌ 本番Webアプリ

【エントリー向け】
このクラスの性能は、以下のような用途に限定されます:
• 個人ブログ
• 学習用環境
• デモ・プロトタイプ"
    fi
    
    echo "$use_cases"
}

# =================================================================
# 1. 基本システム情報
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  1. 基本システム情報${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# OS情報
OS_INFO=$(cat /etc/os-release 2>/dev/null | grep "PRETTY_NAME" | cut -d'"' -f2 || echo "Unknown")
echo "OS情報:"
echo "$OS_INFO"
echo ""

# カーネルバージョン
KERNEL=$(uname -r)
echo "カーネルバージョン:"
echo "$KERNEL"
echo ""

# アーキテクチャ
ARCH=$(uname -m)
echo "アーキテクチャ:"
echo "$ARCH"
echo ""

if [ "$ARCH" = "x86_64" ]; then
    echo -e "${GREEN}✅ x86_64アーキテクチャ: 対応${NC}"
    ARCH_SCORE=5
else
    echo -e "${RED}❌ x86_64アーキテクチャ: 非対応${NC}"
    echo "MukenVaultはx86_64アーキテクチャでのみ動作します"
    exit 1
fi
echo ""

# =================================================================
# 2. CPU性能チェック
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  2. CPU性能チェック${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# CPUモデル
CPU_MODEL=$(cat /proc/cpuinfo | grep "model name" | head -1 | cut -d':' -f2 | xargs)
if [ -z "$CPU_MODEL" ]; then
    CPU_MODEL="Unknown CPU"
fi
echo "CPUモデル: $CPU_MODEL"

# CPUコア数
CPU_CORES=$(nproc)
echo "CPUコア数: $CPU_CORES"

# CPU周波数
CPU_FREQ=$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | cut -d':' -f2 | xargs)
if [ -z "$CPU_FREQ" ]; then
    CPU_FREQ="Unknown"
else
    CPU_FREQ="${CPU_FREQ} MHz"
fi
echo "CPU周波数: $CPU_FREQ"
echo ""

# CPUコア数スコアリング（調整: 重みを軽減）
if [ "$CPU_CORES" -ge 8 ]; then
    echo -e "${GREEN}✅ CPUコア数: $CPU_CORES (十分)${NC}"
    CPU_SCORE=8
elif [ "$CPU_CORES" -ge 4 ]; then
    echo -e "${GREEN}✅ CPUコア数: $CPU_CORES (良好)${NC}"
    CPU_SCORE=6
elif [ "$CPU_CORES" -ge 2 ]; then
    echo -e "${YELLOW}⚠️  CPUコア数: $CPU_CORES (最低限)${NC}"
    CPU_SCORE=4
else
    echo -e "${RED}❌ CPUコア数: $CPU_CORES (不足)${NC}"
    CPU_SCORE=0
fi
echo ""

# =================================================================
# 2.5 CPU世代判定（新機能）
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  2.5 CPU世代分析（新機能）${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# CPU世代判定
IFS='|' read -r CPU_GENERATION CPU_YEAR CPU_ARCH CPU_GEN_SCORE <<< "$(detect_cpu_generation "$CPU_MODEL")"

echo "【世代判定】"
echo "  世代名: $CPU_GENERATION"
echo "  リリース年: $CPU_YEAR"
echo "  アーキテクチャ: $CPU_ARCH"
echo ""

if [ "$CPU_GENERATION" != "Unknown" ]; then
    # 世代評価の表示
    CPU_YEAR_NUM=$(echo "$CPU_YEAR" | grep -oE "[0-9]{4}" | head -1)
    if [ -n "$CPU_YEAR_NUM" ] && [ "$CPU_YEAR_NUM" -ge 2021 ]; then
        echo -e "  世代評価: ${GREEN}🟢 最新世代${NC}"
        echo "  MukenVault適合度: ★★★★★ (最高)"
    elif [ -n "$CPU_YEAR_NUM" ] && [ "$CPU_YEAR_NUM" -ge 2019 ]; then
        echo -e "  世代評価: ${GREEN}🟡 現行世代${NC}"
        echo "  MukenVault適合度: ★★★★☆ (優秀)"
    elif [ -n "$CPU_YEAR_NUM" ] && [ "$CPU_YEAR_NUM" -ge 2017 ]; then
        echo -e "  世代評価: ${YELLOW}🟠 準現行世代${NC}"
        echo "  MukenVault適合度: ★★★☆☆ (標準)"
    elif [ -n "$CPU_YEAR_NUM" ] && [ "$CPU_YEAR_NUM" -ge 2015 ]; then
        echo -e "  世代評価: ${YELLOW}🔴 旧世代${NC}"
        echo "  MukenVault適合度: ★★☆☆☆ (制限あり)"
    else
        echo -e "  世代評価: ${RED}⚪ 古い世代${NC}"
        echo "  MukenVault適合度: ★☆☆☆☆ (非推奨)"
    fi
else
    echo "  世代評価: 判定できませんでした"
    CPU_GEN_SCORE=0
fi
echo ""

# =================================================================
# 3. CPU命令セットチェック（最重要）
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  3. CPU命令セットチェック（最重要）${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# AES-NIチェック
HAS_AES_NI=$(grep -o 'aes' /proc/cpuinfo | head -1)
if [ -n "$HAS_AES_NI" ]; then
    echo -e "${GREEN}✅ AES-NI: サポート ✅ 必須機能${NC}"
    AES_NI_SCORE=15
else
    echo -e "${RED}❌ AES-NI: 非サポート${NC}"
    echo -e "${RED}MukenVaultはAES-NIが必須です${NC}"
    exit 1
fi

# AVX2チェック
HAS_AVX2=$(grep -o 'avx2' /proc/cpuinfo | head -1)
if [ -n "$HAS_AVX2" ]; then
    echo -e "${GREEN}✅ AVX2: サポート ✅ 性能向上に有効${NC}"
    AVX2_SCORE=5
else
    echo -e "${YELLOW}⚠️  AVX2: 非サポート${NC}"
    AVX2_SCORE=0
fi

# VAESチェック
HAS_VAES=$(grep -o 'vaes' /proc/cpuinfo | head -1)
if [ -n "$HAS_VAES" ]; then
    echo -e "${GREEN}✅ VAES: サポート ✅ 最高性能を実現${NC}"
    VAES_DETECT_SCORE=10
    VAES_AVAILABLE=1
    VAES_SUPPORT_STR="yes"
else
    echo -e "${YELLOW}ℹ️  VAES: 非サポート${NC}"
    VAES_DETECT_SCORE=0
    VAES_AVAILABLE=0
    VAES_SUPPORT_STR="no"
fi

# AVX-512チェック
HAS_AVX512=$(grep -o 'avx512f' /proc/cpuinfo | head -1)
if [ -n "$HAS_AVX512" ]; then
    echo -e "${GREEN}✅ AVX-512: サポート ✅ 高性能${NC}"
    AVX512_SCORE=3
    HAS_AVX512_FLAG=1
else
    echo -e "${YELLOW}ℹ️  AVX-512: 非サポート${NC}"
    AVX512_SCORE=0
    HAS_AVX512_FLAG=0
fi

INSTRUCTION_SCORE=$((AES_NI_SCORE + AVX2_SCORE + VAES_DETECT_SCORE + AVX512_SCORE + CPU_GEN_SCORE))

echo ""
echo "【命令セット評価】"
if [ "$VAES_AVAILABLE" -eq 1 ]; then
    echo -e "${GREEN}最高性能環境: VAES対応で30GB/s以上の性能が期待できます${NC}"
elif [ "$AVX2_SCORE" -gt 0 ]; then
    echo "標準性能環境: AVX2対応で10-20GB/sの性能が期待できます"
else
    echo "基本性能環境: AES-NIのみで5-10GB/sの性能が期待できます"
fi
echo ""

# =================================================================
# 4. メモリ性能チェック
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  4. メモリ性能チェック${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# メモリ容量
MEM_TOTAL_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_TOTAL_GB=$(awk "BEGIN {printf \"%.2f\", $MEM_TOTAL_KB / 1048576}")

echo "総メモリ: $MEM_TOTAL_GB GB"
echo ""

# メモリ容量スコアリング（調整: VPS規模判定に使用、性能影響は小）
MEM_TOTAL_INT=$(awk "BEGIN {print int($MEM_TOTAL_GB)}")
if [ "$MEM_TOTAL_INT" -ge 16 ]; then
    echo -e "${GREEN}✅ メモリ容量: $MEM_TOTAL_GB GB (十分)${NC}"
    MEM_CAPACITY_SCORE=5
elif [ "$MEM_TOTAL_INT" -ge 8 ]; then
    echo -e "${GREEN}✅ メモリ容量: $MEM_TOTAL_GB GB (良好)${NC}"
    MEM_CAPACITY_SCORE=4
elif [ "$MEM_TOTAL_INT" -ge 4 ]; then
    echo -e "${YELLOW}ℹ️  メモリ容量: $MEM_TOTAL_GB GB (標準)${NC}"
    echo "   ※ VPS料金プランの選定基準です。MukenVault性能には影響しません"
    MEM_CAPACITY_SCORE=3
else
    echo -e "${YELLOW}ℹ️  メモリ容量: $MEM_TOTAL_GB GB (小規模VPS)${NC}"
    echo "   ※ VPS料金プランの選定基準です。MukenVault性能には影響しません"
    MEM_CAPACITY_SCORE=2
fi

# メモリ帯域測定
echo "メモリ帯域を測定中..."

cat > "$TEMP_DIR/mem_bandwidth.c" << 'EOFCODE'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

#define SIZE (256 * 1024 * 1024)
#define ITERATIONS 3

double get_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec / 1000000.0;
}

int main() {
    char *src = aligned_alloc(64, SIZE);
    char *dst = aligned_alloc(64, SIZE);
    memset(src, 0x42, SIZE);
    
    double best_speed = 0.0;
    for (int i = 0; i < ITERATIONS; i++) {
        double start = get_time();
        memcpy(dst, src, SIZE);
        double end = get_time();
        double speed = (SIZE / (1024.0 * 1024.0 * 1024.0)) / (end - start);
        if (speed > best_speed) best_speed = speed;
    }
    
    printf("%.2f\n", best_speed);
    free(src);
    free(dst);
    return 0;
}
EOFCODE

gcc -O2 -o "$TEMP_DIR/mem_bandwidth" "$TEMP_DIR/mem_bandwidth.c" 2>/dev/null
MEM_BANDWIDTH=$("$TEMP_DIR/mem_bandwidth")

echo "メモリ帯域: $MEM_BANDWIDTH GB/s"
echo ""

# メモリ帯域スコアリング（調整: 重要度を上げる）
MEM_BW_INT=$(awk "BEGIN {print int($MEM_BANDWIDTH)}")
if [ "$MEM_BW_INT" -ge 30 ]; then
    echo -e "${GREEN}✅ メモリ帯域: $MEM_BANDWIDTH GB/s (優秀)${NC}"
    MEM_BANDWIDTH_SCORE=12
elif [ "$MEM_BW_INT" -ge 15 ]; then
    echo -e "${GREEN}✅ メモリ帯域: $MEM_BANDWIDTH GB/s (良好)${NC}"
    MEM_BANDWIDTH_SCORE=10
elif [ "$MEM_BW_INT" -ge 8 ]; then
    echo -e "${YELLOW}⚠️  メモリ帯域: $MEM_BANDWIDTH GB/s (制限あり)${NC}"
    MEM_BANDWIDTH_SCORE=7
else
    echo -e "${RED}⚠️  メモリ帯域: $MEM_BANDWIDTH GB/s (低速)${NC}"
    MEM_BANDWIDTH_SCORE=4
fi

MEM_SCORE=$((MEM_CAPACITY_SCORE + MEM_BANDWIDTH_SCORE))
echo ""

# =================================================================
# 4.5 平文アクセス性能測定
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  4.5 平文アクセス性能測定（ベースライン）${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "平文アクセス速度を測定中..."
echo "（これは暗号化していない通常のメモリアクセス速度です）"
echo ""

# 8バイト単位平文アクセステスト
cat > "$TEMP_DIR/plaintext_8byte.c" << 'EOFCODE'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <stdint.h>

#define DATA_SIZE (512 * 1024 * 1024)
#define ITERATIONS 3

double get_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec / 1000000.0;
}

int main() {
    uint64_t *data = (uint64_t *)aligned_alloc(64, DATA_SIZE);
    if (!data) return 1;
    
    memset(data, 0x42, DATA_SIZE);
    volatile uint64_t sum = 0;
    size_t count = DATA_SIZE / sizeof(uint64_t);
    double best_speed = 0.0;
    
    for (int iter = 0; iter < ITERATIONS; iter++) {
        double start = get_time();
        for (size_t i = 0; i < count; i++) {
            sum += data[i];
        }
        double end = get_time();
        double speed = (DATA_SIZE / (1024.0 * 1024.0 * 1024.0)) / (end - start);
        if (speed > best_speed) best_speed = speed;
    }
    
    printf("%.2f\n", best_speed);
    free(data);
    return 0;
}
EOFCODE

gcc -O2 -march=native -o "$TEMP_DIR/plaintext_8byte" "$TEMP_DIR/plaintext_8byte.c" 2>/dev/null
PLAINTEXT_8BYTE=$("$TEMP_DIR/plaintext_8byte")

echo "平文アクセス（8バイト単位）: $PLAINTEXT_8BYTE GB/s"

# 64バイト単位平文アクセステスト
cat > "$TEMP_DIR/plaintext_64byte.c" << 'EOFCODE'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <stdint.h>
#include <emmintrin.h>

#define DATA_SIZE (512 * 1024 * 1024)
#define ITERATIONS 3

double get_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec / 1000000.0;
}

int main() {
    __m128i *data = (__m128i *)aligned_alloc(64, DATA_SIZE);
    if (!data) return 1;
    
    memset(data, 0x42, DATA_SIZE);
    volatile uint64_t sum = 0;
    size_t count = DATA_SIZE / 64;
    double best_speed = 0.0;
    
    for (int iter = 0; iter < ITERATIONS; iter++) {
        double start = get_time();
        for (size_t i = 0; i < count * 4; i += 4) {
            __m128i v0 = _mm_load_si128(&data[i]);
            __m128i v1 = _mm_load_si128(&data[i + 1]);
            __m128i v2 = _mm_load_si128(&data[i + 2]);
            __m128i v3 = _mm_load_si128(&data[i + 3]);
            sum += ((uint64_t*)&v0)[0] + ((uint64_t*)&v1)[0] + 
                   ((uint64_t*)&v2)[0] + ((uint64_t*)&v3)[0];
        }
        double end = get_time();
        double speed = (DATA_SIZE / (1024.0 * 1024.0 * 1024.0)) / (end - start);
        if (speed > best_speed) best_speed = speed;
    }
    
    printf("%.2f\n", best_speed);
    free(data);
    return 0;
}
EOFCODE

gcc -O2 -march=native -msse2 -o "$TEMP_DIR/plaintext_64byte" "$TEMP_DIR/plaintext_64byte.c" 2>/dev/null
PLAINTEXT_64BYTE=$("$TEMP_DIR/plaintext_64byte")

echo "平文アクセス（64バイト単位・最適化）: $PLAINTEXT_64BYTE GB/s"
echo ""

echo "【平文性能の意味】"
echo "この数値はMukenVault「なし」の状態でのメモリアクセス速度です。"
echo "後ほど測定する暗号化速度と比較することで、実際のオーバーヘッドがわかります。"
echo ""


# =================================================================
# 5. AES-NI実性能測定
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  5. AES-NI実性能測定${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "AES-NI暗号化性能を測定中..."

cat > "$TEMP_DIR/aes_benchmark.c" << 'EOFCODE'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wmmintrin.h>
#include <sys/time.h>

#define SIZE (256 * 1024 * 1024)
#define ITERATIONS 5

double get_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec / 1000000.0;
}

__m128i AES_128_key_expansion(__m128i key, __m128i key_gen) {
    key_gen = _mm_shuffle_epi32(key_gen, 0xff);
    key = _mm_xor_si128(key, _mm_slli_si128(key, 4));
    key = _mm_xor_si128(key, _mm_slli_si128(key, 4));
    key = _mm_xor_si128(key, _mm_slli_si128(key, 4));
    return _mm_xor_si128(key, key_gen);
}

int main() {
    unsigned char *data = aligned_alloc(16, SIZE);
    memset(data, 0x42, SIZE);
    
    __m128i key = _mm_set_epi32(0x12345678, 0x9ABCDEF0, 0x12345678, 0x9ABCDEF0);
    __m128i round_keys[11];
    
    round_keys[0] = key;
    round_keys[1] = AES_128_key_expansion(round_keys[0], _mm_aeskeygenassist_si128(round_keys[0], 0x01));
    round_keys[2] = AES_128_key_expansion(round_keys[1], _mm_aeskeygenassist_si128(round_keys[1], 0x02));
    round_keys[3] = AES_128_key_expansion(round_keys[2], _mm_aeskeygenassist_si128(round_keys[2], 0x04));
    round_keys[4] = AES_128_key_expansion(round_keys[3], _mm_aeskeygenassist_si128(round_keys[3], 0x08));
    round_keys[5] = AES_128_key_expansion(round_keys[4], _mm_aeskeygenassist_si128(round_keys[4], 0x10));
    round_keys[6] = AES_128_key_expansion(round_keys[5], _mm_aeskeygenassist_si128(round_keys[5], 0x20));
    round_keys[7] = AES_128_key_expansion(round_keys[6], _mm_aeskeygenassist_si128(round_keys[6], 0x40));
    round_keys[8] = AES_128_key_expansion(round_keys[7], _mm_aeskeygenassist_si128(round_keys[7], 0x80));
    round_keys[9] = AES_128_key_expansion(round_keys[8], _mm_aeskeygenassist_si128(round_keys[8], 0x1B));
    round_keys[10] = AES_128_key_expansion(round_keys[9], _mm_aeskeygenassist_si128(round_keys[9], 0x36));
    
    double best_speed = 0.0;
    for (int iter = 0; iter < ITERATIONS; iter++) {
        double start = get_time();
        
        for (size_t i = 0; i < SIZE; i += 64) {
            _mm_prefetch((char*)(data + i + 128), _MM_HINT_T0);
            
            __m128i b0 = _mm_loadu_si128((__m128i*)(data + i));
            __m128i b1 = _mm_loadu_si128((__m128i*)(data + i + 16));
            __m128i b2 = _mm_loadu_si128((__m128i*)(data + i + 32));
            __m128i b3 = _mm_loadu_si128((__m128i*)(data + i + 48));
            
            b0 = _mm_xor_si128(b0, round_keys[0]);
            b1 = _mm_xor_si128(b1, round_keys[0]);
            b2 = _mm_xor_si128(b2, round_keys[0]);
            b3 = _mm_xor_si128(b3, round_keys[0]);
            
            for (int r = 1; r < 10; r++) {
                b0 = _mm_aesenc_si128(b0, round_keys[r]);
                b1 = _mm_aesenc_si128(b1, round_keys[r]);
                b2 = _mm_aesenc_si128(b2, round_keys[r]);
                b3 = _mm_aesenc_si128(b3, round_keys[r]);
            }
            
            b0 = _mm_aesenclast_si128(b0, round_keys[10]);
            b1 = _mm_aesenclast_si128(b1, round_keys[10]);
            b2 = _mm_aesenclast_si128(b2, round_keys[10]);
            b3 = _mm_aesenclast_si128(b3, round_keys[10]);
            
            _mm_storeu_si128((__m128i*)(data + i), b0);
            _mm_storeu_si128((__m128i*)(data + i + 16), b1);
            _mm_storeu_si128((__m128i*)(data + i + 32), b2);
            _mm_storeu_si128((__m128i*)(data + i + 48), b3);
        }
        
        double end = get_time();
        double speed = (SIZE / (1024.0 * 1024.0 * 1024.0)) / (end - start);
        if (speed > best_speed) best_speed = speed;
    }
    
    printf("%.2f\n", best_speed);
    free(data);
    return 0;
}
EOFCODE

gcc -O3 -march=native -maes -o "$TEMP_DIR/aes_benchmark" "$TEMP_DIR/aes_benchmark.c" 2>/dev/null
AES_SPEED=$("$TEMP_DIR/aes_benchmark")

echo "AES-NI暗号化速度: $AES_SPEED GB/s"
echo ""

# AES性能スコアリング（調整: 実測性能を重視）
AES_SPEED_INT=$(awk "BEGIN {print int($AES_SPEED)}")
if [ "$AES_SPEED_INT" -ge 20 ]; then
    echo -e "${GREEN}✅ AES-NI性能: $AES_SPEED GB/s (優秀)${NC}"
    AES_PERF_SCORE=12
elif [ "$AES_SPEED_INT" -ge 10 ]; then
    echo -e "${YELLOW}⚠️  AES-NI性能: $AES_SPEED GB/s (標準)${NC}"
    AES_PERF_SCORE=10
elif [ "$AES_SPEED_INT" -ge 5 ]; then
    echo -e "${YELLOW}⚠️  AES-NI性能: $AES_SPEED GB/s (やや低速)${NC}"
    AES_PERF_SCORE=7
else
    echo -e "${RED}⚠️  AES-NI性能: $AES_SPEED GB/s (低速)${NC}"
    AES_PERF_SCORE=5
fi
echo ""

# =================================================================
# 6. VAES実性能測定（256bit/512bit両対応）
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  6. VAES実性能測定（最新CPUボーナス）${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

VAES_PERF_BONUS=0
VAES_SPEED="0"

if [ "$VAES_AVAILABLE" -eq 1 ]; then
    echo "VAES暗号化性能を測定中..."
    echo "（これは最新世代CPUのみの特別機能です）"
    echo ""
    
    cat > "$TEMP_DIR/vaes_benchmark.c" << 'EOFCODE'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <stdint.h>

#define SIZE (256 * 1024 * 1024)
#define ITERATIONS 5

double get_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec / 1000000.0;
}

#if defined(__AVX512F__) && defined(__VAES__)
#include <immintrin.h>

void keyless_vaes_encrypt_512(uint8_t* data, size_t size, const uint8_t* key) {
    __m128i base_key = _mm_loadu_si128((__m128i*)key);
    __m512i round_keys[15];
    
    for (int i = 0; i < 15; i++) {
        round_keys[i] = _mm512_broadcast_i32x4(base_key);
    }
    
    size_t blocks = size / 256;
    __m512i* ptr = (__m512i*)data;
    
    for (size_t i = 0; i < blocks; i += 4) {
        _mm_prefetch((char*)&ptr[i + 8], _MM_HINT_T0);
        
        __m512i b0 = _mm512_loadu_si512(&ptr[i]);
        __m512i b1 = _mm512_loadu_si512(&ptr[i + 1]);
        __m512i b2 = _mm512_loadu_si512(&ptr[i + 2]);
        __m512i b3 = _mm512_loadu_si512(&ptr[i + 3]);
        
        b0 = _mm512_xor_si512(b0, round_keys[0]);
        b1 = _mm512_xor_si512(b1, round_keys[0]);
        b2 = _mm512_xor_si512(b2, round_keys[0]);
        b3 = _mm512_xor_si512(b3, round_keys[0]);
        
        for (int r = 1; r < 14; r++) {
            b0 = _mm512_aesenc_epi128(b0, round_keys[r]);
            b1 = _mm512_aesenc_epi128(b1, round_keys[r]);
            b2 = _mm512_aesenc_epi128(b2, round_keys[r]);
            b3 = _mm512_aesenc_epi128(b3, round_keys[r]);
        }
        
        b0 = _mm512_aesenclast_epi128(b0, round_keys[14]);
        b1 = _mm512_aesenclast_epi128(b1, round_keys[14]);
        b2 = _mm512_aesenclast_epi128(b2, round_keys[14]);
        b3 = _mm512_aesenclast_epi128(b3, round_keys[14]);
        
        _mm512_storeu_si512(&ptr[i], b0);
        _mm512_storeu_si512(&ptr[i + 1], b1);
        _mm512_storeu_si512(&ptr[i + 2], b2);
        _mm512_storeu_si512(&ptr[i + 3], b3);
    }
}

#elif defined(__AVX2__) && defined(__VAES__)
#include <immintrin.h>

void keyless_vaes_encrypt_256(uint8_t* data, size_t size, const uint8_t* key) {
    __m128i base_key = _mm_loadu_si128((__m128i*)key);
    __m256i round_keys[15];
    
    for (int i = 0; i < 15; i++) {
        round_keys[i] = _mm256_broadcastsi128_si256(base_key);
    }
    
    size_t blocks = size / 128;
    __m256i* ptr = (__m256i*)data;
    
    for (size_t i = 0; i < blocks; i += 4) {
        _mm_prefetch((char*)&ptr[i + 8], _MM_HINT_T0);
        
        __m256i b0 = _mm256_loadu_si256(&ptr[i]);
        __m256i b1 = _mm256_loadu_si256(&ptr[i + 1]);
        __m256i b2 = _mm256_loadu_si256(&ptr[i + 2]);
        __m256i b3 = _mm256_loadu_si256(&ptr[i + 3]);
        
        b0 = _mm256_xor_si256(b0, round_keys[0]);
        b1 = _mm256_xor_si256(b1, round_keys[0]);
        b2 = _mm256_xor_si256(b2, round_keys[0]);
        b3 = _mm256_xor_si256(b3, round_keys[0]);
        
        for (int r = 1; r < 14; r++) {
            b0 = _mm256_aesenc_epi128(b0, round_keys[r]);
            b1 = _mm256_aesenc_epi128(b1, round_keys[r]);
            b2 = _mm256_aesenc_epi128(b2, round_keys[r]);
            b3 = _mm256_aesenc_epi128(b3, round_keys[r]);
        }
        
        b0 = _mm256_aesenclast_epi128(b0, round_keys[14]);
        b1 = _mm256_aesenclast_epi128(b1, round_keys[14]);
        b2 = _mm256_aesenclast_epi128(b2, round_keys[14]);
        b3 = _mm256_aesenclast_epi128(b3, round_keys[14]);
        
        _mm256_storeu_si256(&ptr[i], b0);
        _mm256_storeu_si256(&ptr[i + 1], b1);
        _mm256_storeu_si256(&ptr[i + 2], b2);
        _mm256_storeu_si256(&ptr[i + 3], b3);
    }
}
#endif

int main() {
#if defined(__AVX512F__) && defined(__VAES__)
    uint8_t* data = aligned_alloc(64, SIZE);
    uint8_t key[16] = {0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
                       0x11, 0x11, 0x11, 0x11, 0x22, 0x22, 0x22, 0x22};
    
    if (!data) {
        printf("0.0\n");
        return 1;
    }
    
    memset(data, 0xAA, SIZE);
    keyless_vaes_encrypt_512(data, SIZE, key);
    
    double best_speed = 0.0;
    for (int iter = 0; iter < ITERATIONS; iter++) {
        double start = get_time();
        keyless_vaes_encrypt_512(data, SIZE, key);
        double end = get_time();
        double speed = (SIZE / (1024.0 * 1024.0 * 1024.0)) / (end - start);
        if (speed > best_speed) best_speed = speed;
    }
    
    printf("%.2f\n", best_speed);
    free(data);
    return 0;
    
#elif defined(__AVX2__) && defined(__VAES__)
    uint8_t* data = aligned_alloc(64, SIZE);
    uint8_t key[16] = {0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
                       0x11, 0x11, 0x11, 0x11, 0x22, 0x22, 0x22, 0x22};
    
    if (!data) {
        printf("0.0\n");
        return 1;
    }
    
    memset(data, 0xAA, SIZE);
    keyless_vaes_encrypt_256(data, SIZE, key);
    
    double best_speed = 0.0;
    for (int iter = 0; iter < ITERATIONS; iter++) {
        double start = get_time();
        keyless_vaes_encrypt_256(data, SIZE, key);
        double end = get_time();
        double speed = (SIZE / (1024.0 * 1024.0 * 1024.0)) / (end - start);
        if (speed > best_speed) best_speed = speed;
    }
    
    printf("%.2f\n", best_speed);
    free(data);
    return 0;
#else
    printf("0.0\n");
    return 1;
#endif
}
EOFCODE

    # 512bit版を試行
    if [ "$HAS_AVX512_FLAG" -eq 1 ]; then
        gcc -O3 -march=native -mavx512f -mvaes -o "$TEMP_DIR/vaes_benchmark" "$TEMP_DIR/vaes_benchmark.c" 2>/dev/null
        if [ $? -eq 0 ]; then
            VAES_SPEED=$("$TEMP_DIR/vaes_benchmark" 2>/dev/null || echo "0")
            if [ "$VAES_SPEED" != "0" ] && [ -n "$VAES_SPEED" ]; then
                echo -e "${GREEN}✅ VAES 512bit版（AVX-512）で測定成功${NC}"
            else
                VAES_SPEED="0"
            fi
        fi
    fi
    
    # 256bit版にフォールバック
    if [ "$VAES_SPEED" = "0" ]; then
        gcc -O3 -march=native -mavx2 -mvaes -o "$TEMP_DIR/vaes_benchmark" "$TEMP_DIR/vaes_benchmark.c" 2>/dev/null
        if [ $? -eq 0 ]; then
            VAES_SPEED=$("$TEMP_DIR/vaes_benchmark" 2>/dev/null || echo "0")
            if [ "$VAES_SPEED" != "0" ] && [ -n "$VAES_SPEED" ]; then
                echo -e "${GREEN}✅ VAES 256bit版（AVX2）で測定成功${NC}"
            fi
        fi
    fi
    
    # 結果表示とスコア計算（調整: VAES性能ボーナス大幅増）
    if [ "$VAES_SPEED" != "0" ] && [ -n "$VAES_SPEED" ]; then
        echo "VAES暗号化速度: $VAES_SPEED GB/s"
        echo ""
        
        RATIO=$(awk "BEGIN {printf \"%.2f\", $VAES_SPEED / $AES_SPEED}")
        echo "【VAES効果】"
        echo "  AES-NI比: ${RATIO}倍高速！"
        echo "  → VAESは通常のAES-NIより大幅に高速です"
        echo ""
        
        # VAES性能ボーナス（調整: 最大25点に増）
        VAES_SPEED_INT=$(awk "BEGIN {print int($VAES_SPEED)}")
        if [ "$VAES_SPEED_INT" -ge 60 ]; then
            VAES_PERF_BONUS=25
            echo -e "${GREEN}✅ VAES性能: $VAES_SPEED GB/s (驚異的！)${NC}"
        elif [ "$VAES_SPEED_INT" -ge 40 ]; then
            VAES_PERF_BONUS=20
            echo -e "${GREEN}✅ VAES性能: $VAES_SPEED GB/s (優秀)${NC}"
        elif [ "$VAES_SPEED_INT" -ge 30 ]; then
            VAES_PERF_BONUS=18
            echo -e "${GREEN}✅ VAES性能: $VAES_SPEED GB/s (良好)${NC}"
        elif [ "$VAES_SPEED_INT" -ge 20 ]; then
            VAES_PERF_BONUS=15
            echo -e "${GREEN}✅ VAES性能: $VAES_SPEED GB/s (標準)${NC}"
        elif [ "$VAES_SPEED_INT" -ge 10 ]; then
            VAES_PERF_BONUS=10
            echo -e "${YELLOW}ℹ️  VAES性能: $VAES_SPEED GB/s${NC}"
        else
            VAES_PERF_BONUS=5
            echo -e "${YELLOW}ℹ️  VAES性能: $VAES_SPEED GB/s${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  VAES測定失敗${NC}"
        echo "（VAES命令セット検出: +10点、測定失敗: +0点）"
    fi
else
    echo -e "${YELLOW}ℹ️  VAES非対応CPUのため、この測定はスキップされます${NC}"
fi
echo ""


# =================================================================
# 7. 環境種別の判定
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  7. 環境種別の判定${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -e /sys/hypervisor/type ]; then
    HYPERVISOR=$(cat /sys/hypervisor/type)
    echo -e "${YELLOW}ℹ️  仮想化環境: はい（$HYPERVISOR）${NC}"
    IS_VIRTUAL=1
elif grep -q "hypervisor" /proc/cpuinfo; then
    echo -e "${YELLOW}ℹ️  仮想化環境: はい（VPS/VM）${NC}"
    IS_VIRTUAL=1
else
    echo -e "${GREEN}ℹ️  仮想化環境: いいえ（物理マシン）${NC}"
    IS_VIRTUAL=0
fi

PROVIDER="不明"
if [ -e /sys/devices/virtual/dmi/id/sys_vendor ]; then
    SYS_VENDOR=$(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null)
    case "$SYS_VENDOR" in
        *"Amazon"*) PROVIDER="AWS" ;;
        *"Google"*) PROVIDER="Google Cloud" ;;
        *"Microsoft"*) PROVIDER="Azure" ;;
        *"DigitalOcean"*) PROVIDER="DigitalOcean" ;;
        *"Vultr"*) PROVIDER="Vultr" ;;
        *"Linode"*) PROVIDER="Linode" ;;
    esac
fi

echo "推定プロバイダー: $PROVIDER"
echo ""
echo ""

# =================================================================
# 8. 期待性能の算出
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  8. 期待性能の算出${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$VAES_AVAILABLE" -eq 1 ] && [ "$VAES_SPEED" != "0" ] && [ -n "$VAES_SPEED" ]; then
    BASE_SPEED=$VAES_SPEED
    PERF_BASIS="VAES"
else
    BASE_SPEED=$AES_SPEED
    PERF_BASIS="AES-NI"
fi

BOTTLENECK="CPU性能"
EXPECTED_SPEED=$BASE_SPEED

MEM_BW_FLOAT=$(awk "BEGIN {printf \"%.2f\", $MEM_BANDWIDTH}")
BASE_SPEED_FLOAT=$(awk "BEGIN {printf \"%.2f\", $BASE_SPEED}")
PLAINTEXT_64B_FLOAT=$(awk "BEGIN {printf \"%.2f\", $PLAINTEXT_64BYTE}")

if awk "BEGIN {exit !($PLAINTEXT_64B_FLOAT > $MEM_BW_FLOAT)}"; then
    ACTUAL_MEM_PERF=$PLAINTEXT_64B_FLOAT
else
    ACTUAL_MEM_PERF=$MEM_BW_FLOAT
fi

if awk "BEGIN {exit !($ACTUAL_MEM_PERF < $BASE_SPEED_FLOAT)}"; then
    BOTTLENECK="メモリ帯域"
    EXPECTED_SPEED=$(awk "BEGIN {printf \"%.2f\", $ACTUAL_MEM_PERF * 0.98}")
else
    EXPECTED_SPEED=$(awk "BEGIN {printf \"%.2f\", $BASE_SPEED * 0.85}")
fi

EXPECTED_SPEED_INT=$(awk "BEGIN {print int($EXPECTED_SPEED)}")
if [ "$EXPECTED_SPEED_INT" -ge 30 ]; then
    PERF_TIER="Enterprise"
elif [ "$EXPECTED_SPEED_INT" -ge 15 ]; then
    PERF_TIER="Premium"
elif [ "$EXPECTED_SPEED_INT" -ge 8 ]; then
    PERF_TIER="Standard"
else
    PERF_TIER="Basic"
fi

echo "【期待性能】"
echo "  MukenVault導入後の予想速度: $EXPECTED_SPEED GB/s"
echo "  性能基準: $PERF_BASIS"
echo "  ボトルネック: $BOTTLENECK"
echo "  性能ティア: $PERF_TIER"
echo ""

if [ "$BOTTLENECK" = "メモリ帯域" ] && awk "BEGIN {exit !($BASE_SPEED_FLOAT > $ACTUAL_MEM_PERF * 2)}"; then
    echo "【革新的発見】"
    echo "  平文アクセス:    ${PLAINTEXT_64B_FLOAT} GB/s"
    echo "  ${PERF_BASIS}暗号化: ${BASE_SPEED_FLOAT} GB/s"
    echo "  期待性能:        $EXPECTED_SPEED GB/s"
    echo ""
    echo -e "${GREEN}→ 暗号化してもほぼ同じ速度で動作します！${NC}"
    echo -e "${GREEN}  （CPU処理が十分速いため、オーバーヘッドほぼゼロ）${NC}"
    echo ""
fi
echo ""

# =================================================================
# 8.5 プロバイダー戦略分析（新機能）
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  8.5 プロバイダー戦略分析（新機能）${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

IFS='|' read -r STRATEGY TARGET STARS <<< "$(analyze_provider_strategy "$CPU_GENERATION" "$CPU_YEAR" "$VAES_SUPPORT_STR" "$EXPECTED_SPEED")"

echo "【このプロバイダーの特性】"
if [ "$PROVIDER" != "不明" ]; then
    echo "  プロバイダー名: $PROVIDER"
else
    echo "  プロバイダー名: （自動検出できませんでした）"
fi
echo ""
echo "  ハードウェア戦略: $STRATEGY"
echo "  └─ CPU世代: $CPU_GENERATION ($CPU_YEAR)"
if [ "$VAES_AVAILABLE" -eq 1 ] && [ "$VAES_SPEED" != "0" ]; then
    echo "     → 最新世代CPUへの投資が確認できます"
elif [ "$VAES_AVAILABLE" -eq 1 ]; then
    echo "     → VAES対応CPUですが、性能は控えめです"
else
    echo "     → コスト重視の構成です"
fi
echo ""
echo "  想定ターゲット: $TARGET"
echo "  └─ このクラスのVPSが想定する用途"
echo ""
echo "  MukenVault適合度: $(printf '★%.0s' $(seq 1 $STARS))$(printf '☆%.0s' $(seq $(($STARS + 1)) 5))"
echo ""

# プロバイダー別の推奨事項
echo "【MukenVault導入における位置づけ】"
if [ "$STARS" -ge 5 ]; then
    echo -e "${GREEN}✅ 最高クラス: エンタープライズ本番環境に推奨${NC}"
    echo "   • 金融・医療系システム"
    echo "   • コンプライアンス要求の厳しい環境"
    echo "   • 24/365稼働の重要システム"
elif [ "$STARS" -ge 4 ]; then
    echo -e "${GREEN}✅ 優良クラス: 本番環境に十分対応${NC}"
    echo "   • 中小企業の業務システム"
    echo "   • スタートアップのプロダクション環境"
    echo "   • 中規模Webサービス"
elif [ "$STARS" -ge 3 ]; then
    echo -e "${YELLOW}🟡 標準クラス: 開発・ステージング向き${NC}"
    echo "   • 開発環境・テスト環境"
    echo "   • 社内ツール・イントラネット"
    echo "   • 軽量本番環境（要検証）"
elif [ "$STARS" -ge 2 ]; then
    echo -e "${RED}🔴 低コストクラス: 限定用途のみ${NC}"
    echo "   • バックアップサーバー"
    echo "   • 静的コンテンツ配信"
    echo "   • 学習・検証環境"
else
    echo -e "${RED}⚠️  要検討: より高スペックな環境を推奨${NC}"
fi
echo ""
echo ""

# =================================================================
# 9. 体験品質の判定
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  9. 体験品質の判定${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$EXPECTED_SPEED_INT" -ge 30 ]; then
    QUALITY="🟢 快適"
    OVERHEAD="1-3%"
    QUALITY_SCORE=10
elif [ "$EXPECTED_SPEED_INT" -ge 15 ]; then
    QUALITY="🟢 良好"
    OVERHEAD="3-8%"
    QUALITY_SCORE=8
elif [ "$EXPECTED_SPEED_INT" -ge 8 ]; then
    QUALITY="🟡 実用的"
    OVERHEAD="5-15%"
    QUALITY_SCORE=6
elif [ "$EXPECTED_SPEED_INT" -ge 4 ]; then
    QUALITY="🟠 要検討"
    OVERHEAD="10-30%"
    QUALITY_SCORE=4
else
    QUALITY="🔴 推奨せず"
    OVERHEAD="30%以上"
    QUALITY_SCORE=2
fi

echo "【体験品質】"
echo "  判定: $QUALITY"
echo "  予想オーバーヘッド: $OVERHEAD"
if [ "$EXPECTED_SPEED_INT" -ge 15 ]; then
    echo "  快適度: ほぼ体感できない遅延"
elif [ "$EXPECTED_SPEED_INT" -ge 8 ]; then
    echo "  快適度: 通常利用では気にならない"
elif [ "$EXPECTED_SPEED_INT" -ge 4 ]; then
    echo "  快適度: 用途によって快適度が変わる"
else
    echo "  快適度: 負荷が高い用途では遅延を感じる可能性"
fi
echo ""

if [ "$VAES_AVAILABLE" -eq 1 ] && [ "$VAES_SPEED" != "0" ] && [ -n "$VAES_SPEED" ]; then
    echo -e "${GREEN}🌟 VAES対応の恩恵 🌟${NC}"
    echo "  この環境は最新世代CPUを搭載しており、"
    echo "  MukenVaultが最高のパフォーマンスを発揮できます！"
    echo ""
fi
echo ""

# =================================================================
# 10. 総合診断結果
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  10. 総合診断結果${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 総合スコア計算（調整版）
TOTAL_SCORE=$((ARCH_SCORE + CPU_SCORE + INSTRUCTION_SCORE + MEM_SCORE + AES_PERF_SCORE + QUALITY_SCORE + VAES_PERF_BONUS))

# スコア上限を100に制限
if [ "$TOTAL_SCORE" -gt 100 ]; then
    TOTAL_SCORE=100
fi

echo "総合スコア: $TOTAL_SCORE/$MAX_SCORE点 ($((TOTAL_SCORE * 100 / MAX_SCORE))%)"
echo ""

# 総合評価（期待性能ベースで判定、スコアとの整合性を確保）
echo "【総合評価】"

if [ "$EXPECTED_SPEED_INT" -ge 30 ]; then
    echo -e "  評価: ${GREEN}S (最高)${NC}"
    echo "  ✅ 完璧！この環境ならMukenVaultが最高のパフォーマンスを発揮します"
elif [ "$EXPECTED_SPEED_INT" -ge 15 ]; then
    echo -e "  評価: ${GREEN}A (優秀)${NC}"
    echo "  ✅ 優秀！MukenVaultに最適な環境です"
elif [ "$EXPECTED_SPEED_INT" -ge 8 ]; then
    echo -e "  評価: ${CYAN}B (良好)${NC}"
    echo "  ✅ 良好！この環境でもMukenVaultは実用的に動作します"
elif [ "$EXPECTED_SPEED_INT" -ge 4 ]; then
    echo -e "  評価: ${YELLOW}C (可)${NC}"
    echo "  ⚠️  用途を選べば問題なく使えます"
else
    echo -e "  評価: ${RED}D (要改善)${NC}"
    echo "  ⚠️  より高スペックな環境をお勧めします"
fi
echo ""
echo ""

# =================================================================
# 11. 適合用途の判定（プロバイダー特性反映版）
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  11. 適合用途の判定${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "この環境で快適に使える用途:"
echo ""

USE_CASES=$(get_recommended_use_cases "$EXPECTED_SPEED_INT" "$CPU_GENERATION" "$PROVIDER")
echo "$USE_CASES"
echo ""

# =================================================================
# レポート保存
# =================================================================
{
    echo "=========================================="
    echo "MukenVault Pre-Installation Check Report"
    echo "Generated: $(date)"
    echo "=========================================="
    echo ""
    echo "System Information:"
    echo "  OS: $OS_INFO"
    echo "  Kernel: $KERNEL"
    echo "  Architecture: $ARCH"
    echo "  CPU: $CPU_MODEL"
    echo "  CPU Generation: $CPU_GENERATION ($CPU_YEAR)"
    echo "  CPU Architecture: $CPU_ARCH"
    echo "  CPU Cores: $CPU_CORES"
    echo "  Memory: $MEM_TOTAL_GB GB"
    echo "  Memory Bandwidth: $MEM_BANDWIDTH GB/s"
    echo ""
    echo "CPU Features:"
    echo "  AES-NI: $([ -n "$HAS_AES_NI" ] && echo "Yes" || echo "No")"
    echo "  AVX2: $([ -n "$HAS_AVX2" ] && echo "Yes" || echo "No")"
    echo "  VAES: $([ -n "$HAS_VAES" ] && echo "Yes" || echo "No")"
    echo "  AVX-512: $([ -n "$HAS_AVX512" ] && echo "Yes" || echo "No")"
    echo ""
    echo "Performance:"
    echo "  Plaintext 8-byte: $PLAINTEXT_8BYTE GB/s"
    echo "  Plaintext 64-byte: $PLAINTEXT_64BYTE GB/s"
    echo "  AES-NI Speed: $AES_SPEED GB/s"
    if [ "$VAES_AVAILABLE" -eq 1 ] && [ "$VAES_SPEED" != "0" ] && [ -n "$VAES_SPEED" ]; then
        RATIO=$(awk "BEGIN {printf \"%.2f\", $VAES_SPEED / $AES_SPEED}")
        echo "  VAES Speed: $VAES_SPEED GB/s"
        echo "  VAES vs AES-NI: ${RATIO}x faster"
    fi
    echo ""
    echo "Environment:"
    echo "  Virtual: $([ "$IS_VIRTUAL" -eq 1 ] && echo "Yes" || echo "No")"
    echo "  Provider: $PROVIDER"
    echo "  Provider Strategy: $STRATEGY"
    echo "  Target Market: $TARGET"
    echo "  MukenVault Stars: $STARS/5"
    echo ""
    echo "Expected Performance:"
    echo "  Speed: $EXPECTED_SPEED GB/s"
    echo "  Basis: $PERF_BASIS"
    echo "  Bottleneck: $BOTTLENECK"
    echo "  Tier: $PERF_TIER"
    echo "  Quality: $QUALITY"
    echo "  Overhead: $OVERHEAD"
    echo ""
    echo "Score:"
    echo "  Total: $TOTAL_SCORE/$MAX_SCORE ($((TOTAL_SCORE * 100 / MAX_SCORE))%)"
    if [ "$TOTAL_SCORE" -ge 90 ]; then
        echo "  Grade: S (Excellent)"
    elif [ "$TOTAL_SCORE" -ge 75 ]; then
        echo "  Grade: A (Very Good)"
    elif [ "$TOTAL_SCORE" -ge 60 ]; then
        echo "  Grade: B (Good)"
    elif [ "$TOTAL_SCORE" -ge 45 ]; then
        echo "  Grade: C (Fair)"
    else
        echo "  Grade: D (Needs Improvement)"
    fi
    echo ""
} > "$REPORT_FILE"

echo -e "${GREEN}✅ 詳細レポートを $REPORT_FILE に保存しました${NC}"
echo ""
echo ""

# =================================================================
# 13. 次のステップ
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  13. 次のステップ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "【MukenVault導入の流れ】"
echo ""
echo "1. このレポートを確認"
echo "   → 保存場所: $REPORT_FILE"
echo ""
echo "2. 用途に応じた判断"
echo "   → あなたの用途を教えてください"
echo "   → 最適な導入方法をアドバイスします"
echo ""
echo "3. お問い合わせ"
echo "   📧 support@mukenvault.com"
echo "   💬 https://github.com/MukenVaultTeam/mukenvault-checker"
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}診断完了！ご利用ありがとうございました${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo ""
echo -e "${GREEN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║  MukenVault Pre-Check completed successfully!               ║
║                                                              ║
║  🆕 v1.4.0 新機能:                                          ║
║     • CPU世代自動判定                                       ║
║     • プロバイダー戦略分析                                  ║
║     • より精密なスコアリング                                ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
