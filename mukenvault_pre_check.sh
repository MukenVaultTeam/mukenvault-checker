#!/bin/bash

#================================================================
# MukenVault導入前システムチェッカー v1.0
#================================================================
# 目的: MukenVaultの導入可能性と期待性能を事前診断
# 対象: Linux VPS/サーバー環境
# 実行: sudo ./mukenvault_pre_check.sh
#================================================================

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# スコア管理
SCORE=0
MAX_SCORE=100

# 結果保存
RESULTS_FILE="mukenvault_check_$(date +%Y%m%d_%H%M%S).txt"

#================================================================
# ヘルパー関数
#================================================================

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

add_score() {
    SCORE=$((SCORE + $1))
    echo "[+$1点] $2" >> "$RESULTS_FILE"
}

#================================================================
# メイン処理開始
#================================================================

clear
echo -e "${CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   MukenVault導入前システムチェッカー v1.0                   ║
║                                                              ║
║   あなたの環境でMukenVaultがどれだけの性能を発揮できるかを  ║
║   事前診断します                                            ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo "診断を開始します..."
echo "結果は ${RESULTS_FILE} に保存されます"
echo ""

# 結果ファイルの初期化
cat > "$RESULTS_FILE" << EOF
MukenVault導入前システムチェック結果
実行日時: $(date)
ホスト名: $(hostname)
OS: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "不明")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
詳細結果
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

#================================================================
# 1. 基本システム情報
#================================================================

print_header "1. 基本システム情報"

echo "OS情報:"
cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "不明"
echo ""

echo "カーネルバージョン:"
uname -r
echo ""

echo "アーキテクチャ:"
uname -m
echo ""

if [[ $(uname -m) == "x86_64" ]]; then
    print_success "x86_64アーキテクチャ: 対応"
    add_score 5 "x86_64アーキテクチャ"
else
    print_error "非対応アーキテクチャ: $(uname -m)"
    echo "MukenVaultはx86_64専用です"
    exit 1
fi

#================================================================
# 2. CPU性能チェック
#================================================================

print_header "2. CPU性能チェック"

# CPU情報取得
CPU_MODEL=$(cat /proc/cpuinfo | grep "model name" | head -1 | cut -d: -f2 | xargs)
CPU_CORES=$(nproc)
CPU_MHZ=$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | cut -d: -f2 | xargs)

echo "CPUモデル: $CPU_MODEL"
echo "CPUコア数: $CPU_CORES"
echo "CPU周波数: ${CPU_MHZ} MHz"
echo ""

# スコア加算
if [ $CPU_CORES -ge 16 ]; then
    print_success "CPUコア数: $CPU_CORES (最高)"
    add_score 15 "CPUコア数16以上"
elif [ $CPU_CORES -ge 8 ]; then
    print_success "CPUコア数: $CPU_CORES (優秀)"
    add_score 12 "CPUコア数8以上"
elif [ $CPU_CORES -ge 4 ]; then
    print_success "CPUコア数: $CPU_CORES (良好)"
    add_score 10 "CPUコア数4以上"
elif [ $CPU_CORES -ge 2 ]; then
    print_warning "CPUコア数: $CPU_CORES (最低限)"
    add_score 7 "CPUコア数2以上"
else
    print_error "CPUコア数: $CPU_CORES (不足)"
    add_score 0 "CPUコア数1"
fi

#================================================================
# 3. CPU命令セットチェック（最重要）
#================================================================

print_header "3. CPU命令セットチェック（最重要）"

HAS_AES=0
HAS_AVX2=0
HAS_VAES=0
HAS_AVX512=0

# AES-NI
if grep -q aes /proc/cpuinfo; then
    print_success "AES-NI: サポート ✅ 必須機能"
    add_score 25 "AES-NIサポート（必須）"
    HAS_AES=1
else
    print_error "AES-NI: 非サポート ❌ MukenVault導入には工夫が必要"
    add_score 0 "AES-NI非サポート"
    HAS_AES=0
fi

# AVX2
if grep -q avx2 /proc/cpuinfo; then
    print_success "AVX2: サポート ✅ 性能向上に有効"
    add_score 10 "AVX2サポート"
    HAS_AVX2=1
else
    print_info "AVX2: 非サポート（性能が制限される可能性）"
    add_score 0 "AVX2非サポート"
    HAS_AVX2=0
fi

# VAES
if grep -q vaes /proc/cpuinfo; then
    print_success "VAES: サポート ✅ 最高性能を実現"
    add_score 10 "VAESサポート"
    HAS_VAES=1
else
    print_info "VAES: 非サポート（最新CPUのみ対応）"
    add_score 0 "VAES非サポート"
    HAS_VAES=0
fi

# AVX-512
if grep -q avx512f /proc/cpuinfo; then
    print_success "AVX-512: サポート ✅ 高性能"
    add_score 5 "AVX-512サポート"
    HAS_AVX512=1
else
    print_info "AVX-512: 非サポート（一般的なCPU）"
    add_score 0 "AVX-512非サポート"
    HAS_AVX512=0
fi

echo ""
echo "【命令セット評価】"
if [ $HAS_VAES -eq 1 ]; then
    echo -e "${GREEN}最高性能環境: VAES対応で50GB/s以上の性能が期待できます${NC}"
    PERF_TIER="Premium"
elif [ $HAS_AVX2 -eq 1 ] && [ $HAS_AES -eq 1 ]; then
    echo -e "${GREEN}高性能環境: AVX2+AES-NI対応で30-50GB/sの性能が期待できます${NC}"
    PERF_TIER="High"
elif [ $HAS_AES -eq 1 ]; then
    echo -e "${YELLOW}標準性能環境: AES-NI対応で10-30GB/sの性能が期待できます${NC}"
    PERF_TIER="Standard"
else
    echo -e "${RED}要カスタマイズ環境: AES-NI非対応、専門サポートが必要です${NC}"
    PERF_TIER="Custom"
fi

#================================================================
# 4. メモリチェック
#================================================================

print_header "4. メモリ性能チェック"

# メモリ容量
TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEM_GB=$(echo "scale=2; $TOTAL_MEM_KB / 1024 / 1024" | bc)

echo "総メモリ: ${TOTAL_MEM_GB} GB"
echo ""

if (( $(echo "$TOTAL_MEM_GB >= 32" | bc -l) )); then
    print_success "メモリ容量: ${TOTAL_MEM_GB} GB (最高)"
    add_score 8 "メモリ32GB以上"
elif (( $(echo "$TOTAL_MEM_GB >= 16" | bc -l) )); then
    print_success "メモリ容量: ${TOTAL_MEM_GB} GB (優秀)"
    add_score 7 "メモリ16GB以上"
elif (( $(echo "$TOTAL_MEM_GB >= 8" | bc -l) )); then
    print_success "メモリ容量: ${TOTAL_MEM_GB} GB (良好)"
    add_score 5 "メモリ8GB以上"
elif (( $(echo "$TOTAL_MEM_GB >= 4" | bc -l) )); then
    print_warning "メモリ容量: ${TOTAL_MEM_GB} GB (最低限)"
    add_score 3 "メモリ4GB以上"
else
    print_error "メモリ容量: ${TOTAL_MEM_GB} GB (不足)"
    add_score 0 "メモリ4GB未満"
fi

# メモリ帯域測定
echo "メモリ帯域を測定中..."

# コンパイラチェック
if ! command -v gcc &> /dev/null; then
    print_warning "gccが見つかりません。インストールします..."
    if command -v apt-get &> /dev/null; then
        apt-get update -qq
        apt-get install -y gcc build-essential > /dev/null 2>&1
    elif command -v yum &> /dev/null; then
        yum install -y gcc make > /dev/null 2>&1
    fi
fi

cat > /tmp/mem_bandwidth_test.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

static inline double get_time(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec * 1e-6;
}

int main() {
    size_t size = 256 * 1024 * 1024;
    char* src = malloc(size);
    char* dst = malloc(size);
    
    if (!src || !dst) {
        printf("0.0\n");
        return 1;
    }
    
    memset(src, 0xAA, size);
    
    double best = 0;
    for (int i = 0; i < 3; i++) {
        double start = get_time();
        memcpy(dst, src, size);
        double end = get_time();
        double speed = (size / (1024.0 * 1024.0 * 1024.0)) / (end - start);
        if (speed > best) best = speed;
    }
    
    printf("%.2f\n", best);
    
    free(src);
    free(dst);
    return 0;
}
EOF

gcc -O2 -o /tmp/mem_bw /tmp/mem_bandwidth_test.c 2>/dev/null
MEM_BANDWIDTH=$(/tmp/mem_bw)

echo "メモリ帯域: ${MEM_BANDWIDTH} GB/s"
echo ""

# メモリ帯域評価
if (( $(echo "$MEM_BANDWIDTH >= 30" | bc -l) )); then
    print_success "メモリ帯域: ${MEM_BANDWIDTH} GB/s (最高)"
    add_score 12 "メモリ帯域30GB/s以上"
    MEM_QUALITY="最高"
elif (( $(echo "$MEM_BANDWIDTH >= 25" | bc -l) )); then
    print_success "メモリ帯域: ${MEM_BANDWIDTH} GB/s (優秀)"
    add_score 10 "メモリ帯域25GB/s以上"
    MEM_QUALITY="優秀"
elif (( $(echo "$MEM_BANDWIDTH >= 20" | bc -l) )); then
    print_success "メモリ帯域: ${MEM_BANDWIDTH} GB/s (良好)"
    add_score 8 "メモリ帯域20GB/s以上"
    MEM_QUALITY="良好"
elif (( $(echo "$MEM_BANDWIDTH >= 15" | bc -l) )); then
    print_warning "メモリ帯域: ${MEM_BANDWIDTH} GB/s (標準)"
    add_score 6 "メモリ帯域15GB/s以上"
    MEM_QUALITY="標準"
elif (( $(echo "$MEM_BANDWIDTH >= 10" | bc -l) )); then
    print_warning "メモリ帯域: ${MEM_BANDWIDTH} GB/s (制限あり)"
    add_score 4 "メモリ帯域10GB/s以上"
    MEM_QUALITY="制限あり"
else
    print_error "メモリ帯域: ${MEM_BANDWIDTH} GB/s (低速)"
    add_score 0 "メモリ帯域10GB/s未満"
    MEM_QUALITY="低速"
fi

#================================================================
# 5. AES-NI実性能測定
#================================================================

print_header "5. AES-NI実性能測定"

if [ $HAS_AES -eq 1 ]; then
    echo "AES-NI暗号化性能を測定中..."

    cat > /tmp/aes_benchmark.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <sys/time.h>
#include <immintrin.h>
#include <wmmintrin.h>

static inline double get_time(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec * 1e-6;
}

void aes_encrypt_4blocks(uint8_t* data, size_t size) {
    __m128i key = _mm_set_epi32(0x12345678, 0x9abcdef0, 0x11111111, 0x22222222);
    size_t blocks = size / 16;
    __m128i* ptr = (__m128i*)data;
    
    for (size_t i = 0; i + 3 < blocks; i += 4) {
        __m128i b0 = _mm_loadu_si128(&ptr[i + 0]);
        __m128i b1 = _mm_loadu_si128(&ptr[i + 1]);
        __m128i b2 = _mm_loadu_si128(&ptr[i + 2]);
        __m128i b3 = _mm_loadu_si128(&ptr[i + 3]);
        
        b0 = _mm_xor_si128(b0, key);
        b1 = _mm_xor_si128(b1, key);
        b2 = _mm_xor_si128(b2, key);
        b3 = _mm_xor_si128(b3, key);
        
        for (int r = 0; r < 9; r++) {
            b0 = _mm_aesenc_si128(b0, key);
            b1 = _mm_aesenc_si128(b1, key);
            b2 = _mm_aesenc_si128(b2, key);
            b3 = _mm_aesenc_si128(b3, key);
        }
        
        b0 = _mm_aesenclast_si128(b0, key);
        b1 = _mm_aesenclast_si128(b1, key);
        b2 = _mm_aesenclast_si128(b2, key);
        b3 = _mm_aesenclast_si128(b3, key);
        
        _mm_storeu_si128(&ptr[i + 0], b0);
        _mm_storeu_si128(&ptr[i + 1], b1);
        _mm_storeu_si128(&ptr[i + 2], b2);
        _mm_storeu_si128(&ptr[i + 3], b3);
    }
}

int main() {
    size_t size = 256 * 1024 * 1024;
    uint8_t* data = aligned_alloc(16, size);
    
    if (!data) {
        printf("0.0\n");
        return 1;
    }
    
    memset(data, 0xAA, size);
    
    double best = 0;
    for (int i = 0; i < 3; i++) {
        double start = get_time();
        aes_encrypt_4blocks(data, size);
        double end = get_time();
        double speed = (size / (1024.0 * 1024.0 * 1024.0)) / (end - start);
        if (speed > best) best = speed;
    }
    
    printf("%.2f\n", best);
    
    free(data);
    return 0;
}
EOF

    gcc -O2 -march=native -maes -o /tmp/aes_bench /tmp/aes_benchmark.c 2>/dev/null
    AES_SPEED=$(/tmp/aes_bench)

    echo "AES-NI暗号化速度: ${AES_SPEED} GB/s"
    echo ""

    # AES性能評価
    if (( $(echo "$AES_SPEED >= 40" | bc -l) )); then
        print_success "AES-NI性能: ${AES_SPEED} GB/s (最高性能)"
        add_score 10 "AES性能40GB/s以上"
        AES_QUALITY="最高性能"
    elif (( $(echo "$AES_SPEED >= 30" | bc -l) )); then
        print_success "AES-NI性能: ${AES_SPEED} GB/s (高性能)"
        add_score 8 "AES性能30GB/s以上"
        AES_QUALITY="高性能"
    elif (( $(echo "$AES_SPEED >= 20" | bc -l) )); then
        print_success "AES-NI性能: ${AES_SPEED} GB/s (良好)"
        add_score 6 "AES性能20GB/s以上"
        AES_QUALITY="良好"
    elif (( $(echo "$AES_SPEED >= 10" | bc -l) )); then
        print_warning "AES-NI性能: ${AES_SPEED} GB/s (標準)"
        add_score 4 "AES性能10GB/s以上"
        AES_QUALITY="標準"
    else
        print_warning "AES-NI性能: ${AES_SPEED} GB/s (制限あり)"
        add_score 2 "AES性能10GB/s未満"
        AES_QUALITY="制限あり"
    fi
else
    print_error "AES-NI非対応のため測定をスキップ"
    AES_SPEED="0.0"
    AES_QUALITY="非対応"
fi

#================================================================
# 6. VAES実性能測定（ボーナス）
#================================================================

if [ $HAS_VAES -eq 1 ]; then
    print_header "6. VAES実性能測定（ボーナス）"
    
    echo "VAES暗号化性能を測定中..."
    echo "（この機能は次バージョンで実装予定）"
    echo ""
    
    VAES_SPEED="0.0"
else
    VAES_SPEED="0.0"
fi

#================================================================
# 7. 環境種別の判定
#================================================================

print_header "7. 環境種別の判定"

# 仮想化チェック
if [ -f /proc/cpuinfo ]; then
    if grep -q "hypervisor" /proc/cpuinfo; then
        print_info "仮想化環境: はい（VPS/VM）"
        IS_VIRTUAL=1
        
        # VPSプロバイダー推定
        if dmesg 2>/dev/null | grep -qi "vultr"; then
            PROVIDER="Vultr"
        elif dmesg 2>/dev/null | grep -qi "digitalocean"; then
            PROVIDER="DigitalOcean"
        elif dmesg 2>/dev/null | grep -qi "amazon\|aws"; then
            PROVIDER="AWS"
        elif dmesg 2>/dev/null | grep -qi "google"; then
            PROVIDER="Google Cloud"
        elif dmesg 2>/dev/null | grep -qi "microsoft\|azure"; then
            PROVIDER="Azure"
        elif dmesg 2>/dev/null | grep -qi "conoha"; then
            PROVIDER="ConoHa"
        else
            PROVIDER="不明"
        fi
        
        echo "推定プロバイダー: $PROVIDER"
    else
        print_info "仮想化環境: いいえ（物理サーバー）"
        IS_VIRTUAL=0
        PROVIDER="物理サーバー"
    fi
else
    print_warning "仮想化判定: 不明"
    IS_VIRTUAL=-1
    PROVIDER="不明"
fi

echo ""

#================================================================
# 8. 期待性能の算出
#================================================================

print_header "8. 期待性能の算出"

# 期待性能の計算
if [ $HAS_AES -eq 1 ]; then
    if (( $(echo "$AES_SPEED > $MEM_BANDWIDTH" | bc -l) )); then
        # メモリがボトルネック
        EXPECTED_PERF=$(echo "scale=2; $MEM_BANDWIDTH * 0.5" | bc)
        BOTTLENECK="メモリ帯域"
    else
        # CPUがボトルネック
        EXPECTED_PERF=$(echo "scale=2; $AES_SPEED * 0.8" | bc)
        BOTTLENECK="CPU性能"
    fi
    
    # 仮想化オーバーヘッドの考慮
    if [ $IS_VIRTUAL -eq 1 ]; then
        EXPECTED_PERF=$(echo "scale=2; $EXPECTED_PERF * 0.9" | bc)
    fi
else
    EXPECTED_PERF="1.0"
    BOTTLENECK="AES-NI非対応"
fi

echo "【期待性能】"
echo "  MukenVault導入後の予想速度: ${EXPECTED_PERF} GB/s"
echo "  ボトルネック: ${BOTTLENECK}"
echo "  性能ティア: ${PERF_TIER}"
echo ""

#================================================================
# 9. 体験品質の判定
#================================================================

print_header "9. 体験品質の判定"

# 体験品質の判定
if [ $HAS_AES -eq 0 ]; then
    EXPERIENCE="🔴 要カスタマイズ"
    OVERHEAD="40-60%"
    COMFORT="要サポート相談"
elif (( $(echo "$EXPECTED_PERF >= 30" | bc -l) )); then
    EXPERIENCE="🟢 快適動作"
    OVERHEAD="<3%"
    COMFORT="どんな用途でも快適"
elif (( $(echo "$EXPECTED_PERF >= 10" | bc -l) )); then
    EXPERIENCE="🟡 実用的"
    OVERHEAD="3-10%"
    COMFORT="ほとんどの用途で快適"
elif (( $(echo "$EXPECTED_PERF >= 1" | bc -l) )); then
    EXPERIENCE="🟠 要検討"
    OVERHEAD="10-30%"
    COMFORT="用途によって快適度が変わる"
else
    EXPERIENCE="🔴 要カスタマイズ"
    OVERHEAD="40-60%"
    COMFORT="要サポート相談"
fi

echo "【体験品質】"
echo "  判定: ${EXPERIENCE}"
echo "  予想オーバーヘッド: ${OVERHEAD}"
echo "  快適度: ${COMFORT}"
echo ""

#================================================================
# 10. 総合診断
#================================================================

print_header "10. 総合診断結果"

# パーセンテージ計算
PERCENTAGE=$((SCORE * 100 / MAX_SCORE))

echo "総合スコア: ${SCORE}/${MAX_SCORE}点 (${PERCENTAGE}%)"
echo ""

# 評価
if [ $PERCENTAGE -ge 90 ]; then
    RATING="S (最高)"
    COLOR=$GREEN
    RECOMMENDATION="🎉 素晴らしい！この環境はMukenVaultの導入に最適です！"
elif [ $PERCENTAGE -ge 75 ]; then
    RATING="A (優秀)"
    COLOR=$GREEN
    RECOMMENDATION="✅ 優秀！この環境はMukenVaultの導入に適しています"
elif [ $PERCENTAGE -ge 60 ]; then
    RATING="B (良好)"
    COLOR=$YELLOW
    RECOMMENDATION="✅ 良好！この環境でもMukenVaultは実用的に動作します"
elif [ $PERCENTAGE -ge 40 ]; then
    RATING="C (可)"
    COLOR=$YELLOW
    RECOMMENDATION="⚠️  用途によります。軽量サービスなら快適に動作します"
else
    RATING="D (要検討)"
    COLOR=$RED
    RECOMMENDATION="💡 軽量サービス向け。高負荷用途はサポートにご相談ください"
fi

echo -e "${COLOR}【総合評価】${NC}"
echo -e "${COLOR}  評価: ${RATING}${NC}"
echo -e "${COLOR}  ${RECOMMENDATION}${NC}"
echo ""

#================================================================
# 11. 適合用途の判定
#================================================================

print_header "11. 適合用途の判定"

echo "この環境で快適に使える用途:"
echo ""

if (( $(echo "$EXPECTED_PERF >= 30" | bc -l) )); then
    echo -e "${GREEN}✅ 大規模Webサービス${NC}"
    echo -e "${GREEN}✅ 高負荷データベース${NC}"
    echo -e "${GREEN}✅ 大規模キャッシュサーバー${NC}"
    echo -e "${GREEN}✅ エンタープライズアプリケーション${NC}"
    echo -e "${GREEN}✅ リアルタイム処理${NC}"
    echo -e "${GREEN}✅ すべての用途に最適${NC}"
    TARGET_MARKET="大規模・高負荷システム"
elif (( $(echo "$EXPECTED_PERF >= 20" | bc -l) )); then
    echo -e "${GREEN}✅ 中規模Webサービス${NC}"
    echo -e "${GREEN}✅ 中規模データベース${NC}"
    echo -e "${GREEN}✅ APIサーバー${NC}"
    echo -e "${GREEN}✅ 一般的なアプリケーション${NC}"
    echo -e "${YELLOW}⚠️  大規模システム（条件付き）${NC}"
    TARGET_MARKET="中規模システム"
elif (( $(echo "$EXPECTED_PERF >= 10" | bc -l) )); then
    echo -e "${GREEN}✅ 小中規模Webサービス${NC}"
    echo -e "${GREEN}✅ 小規模データベース${NC}"
    echo -e "${GREEN}✅ APIサーバー${NC}"
    echo -e "${GREEN}✅ 開発環境${NC}"
    echo -e "${YELLOW}⚠️  中規模データベース（条件付き）${NC}"
    echo -e "${RED}❌ 大規模システム${NC}"
    TARGET_MARKET="小中規模システム"
else
    echo -e "${GREEN}✅ 静的サイト・ブログ${NC}"
    echo -e "${GREEN}✅ ファイルサーバー${NC}"
    echo -e "${GREEN}✅ 開発・テスト環境${NC}"
    echo -e "${GREEN}✅ バックアップサーバー${NC}"
    echo -e "${YELLOW}⚠️  軽量Webアプリ（トライアル推奨）${NC}"
    echo -e "${RED}❌ 高負荷システム${NC}"
    TARGET_MARKET="軽量サービス・開発環境"
fi

echo ""

#================================================================
# 12. レポート保存
#================================================================

cat >> "$RESULTS_FILE" << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
最終評価
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

総合スコア: ${SCORE}/${MAX_SCORE}点 (${PERCENTAGE}%)
評価ランク: ${RATING}
期待性能:   ${EXPECTED_PERF} GB/s
ボトルネック: ${BOTTLENECK}
体験品質:   ${EXPERIENCE}
適合市場:   ${TARGET_MARKET}

【システム構成】
CPU: $CPU_MODEL
CPUコア数: $CPU_CORES
メモリ: ${TOTAL_MEM_GB} GB
メモリ帯域: ${MEM_BANDWIDTH} GB/s
AES-NI性能: ${AES_SPEED} GB/s
環境: $PROVIDER

【命令セット】
AES-NI:  $([ $HAS_AES -eq 1 ] && echo "✅" || echo "❌")
AVX2:    $([ $HAS_AVX2 -eq 1 ] && echo "✅" || echo "❌")
VAES:    $([ $HAS_VAES -eq 1 ] && echo "✅" || echo "❌")
AVX-512: $([ $HAS_AVX512 -eq 1 ] && echo "✅" || echo "❌")

【結論】
$RECOMMENDATION

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

print_success "詳細レポートを ${RESULTS_FILE} に保存しました"
echo ""

#================================================================
# 13. 次のステップ
#================================================================

print_header "13. 次のステップ"

echo "【MukenVault導入の流れ】"
echo ""
echo "1. このレポートを確認"
echo "   → 保存場所: ${RESULTS_FILE}"
echo ""
echo "2. 用途に応じた判断"
if (( $(echo "$EXPECTED_PERF >= 30" | bc -l) )); then
    echo "   → 今すぐMukenVaultを導入できます！"
elif (( $(echo "$EXPECTED_PERF >= 10" | bc -l) )); then
    echo "   → ほとんどの用途で快適に使えます"
    echo "   → トライアルで実環境テスト推奨"
else
    echo "   → あなたの用途を教えてください"
    echo "   → 最適な導入方法をアドバイスします"
fi
echo ""
echo "3. お問い合わせ"
echo "   📧 support@mukenvault.com"
echo "   💬 https://github.com/MukenVaultTeam/mukenvault-checker"
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}診断完了！ご利用ありがとうございました${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# クリーンアップ
rm -f /tmp/mem_bandwidth_test.c /tmp/mem_bw /tmp/aes_benchmark.c /tmp/aes_bench

exit 0
