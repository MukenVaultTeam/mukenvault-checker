#!/bin/bash

#================================================================
# MukenVault Pre-Installation Checker v1.3.1
# gccチェック機能追加、エラーハンドリング強化
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
║   MukenVault導入前システムチェッカー v1.3.1                 ║
║                                                              ║
║   あなたの環境でMukenVaultがどれだけの性能を発揮できるかを  ║
║   事前診断します                                            ║
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

# CPUコア数スコアリング
if [ "$CPU_CORES" -ge 8 ]; then
    echo -e "${GREEN}✅ CPUコア数: $CPU_CORES (十分)${NC}"
    CPU_SCORE=15
elif [ "$CPU_CORES" -ge 4 ]; then
    echo -e "${GREEN}✅ CPUコア数: $CPU_CORES (良好)${NC}"
    CPU_SCORE=10
elif [ "$CPU_CORES" -ge 2 ]; then
    echo -e "${YELLOW}⚠️  CPUコア数: $CPU_CORES (最低限)${NC}"
    CPU_SCORE=5
else
    echo -e "${RED}❌ CPUコア数: $CPU_CORES (不足)${NC}"
    CPU_SCORE=0
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
    AES_NI_SCORE=30
else
    echo -e "${RED}❌ AES-NI: 非サポート${NC}"
    echo -e "${RED}MukenVaultはAES-NIが必須です${NC}"
    exit 1
fi

# AVX2チェック
HAS_AVX2=$(grep -o 'avx2' /proc/cpuinfo | head -1)
if [ -n "$HAS_AVX2" ]; then
    echo -e "${GREEN}✅ AVX2: サポート ✅ 性能向上に有効${NC}"
    AVX2_SCORE=10
else
    echo -e "${YELLOW}⚠️  AVX2: 非サポート${NC}"
    AVX2_SCORE=0
fi

# VAESチェック
HAS_VAES=$(grep -o 'vaes' /proc/cpuinfo | head -1)
if [ -n "$HAS_VAES" ]; then
    echo -e "${GREEN}✅ VAES: サポート ✅ 最高性能を実現${NC}"
    VAES_SCORE=15
    VAES_AVAILABLE=1
else
    echo -e "${YELLOW}ℹ️  VAES: 非サポート${NC}"
    VAES_SCORE=0
    VAES_AVAILABLE=0
fi

# AVX-512チェック
HAS_AVX512=$(grep -o 'avx512f' /proc/cpuinfo | head -1)
if [ -n "$HAS_AVX512" ]; then
    echo -e "${GREEN}✅ AVX-512: サポート ✅ 高性能${NC}"
    AVX512_SCORE=5
else
    echo -e "${YELLOW}ℹ️  AVX-512: 非サポート${NC}"
    AVX512_SCORE=0
fi

INSTRUCTION_SCORE=$((AES_NI_SCORE + AVX2_SCORE + VAES_SCORE + AVX512_SCORE))

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

# メモリ容量スコアリング
MEM_TOTAL_INT=$(awk "BEGIN {print int($MEM_TOTAL_GB)}")
if [ "$MEM_TOTAL_INT" -ge 16 ]; then
    echo -e "${GREEN}✅ メモリ容量: $MEM_TOTAL_GB GB (十分)${NC}"
    MEM_CAPACITY_SCORE=10
elif [ "$MEM_TOTAL_INT" -ge 8 ]; then
    echo -e "${GREEN}✅ メモリ容量: $MEM_TOTAL_GB GB (良好)${NC}"
    MEM_CAPACITY_SCORE=7
elif [ "$MEM_TOTAL_INT" -ge 4 ]; then
    echo -e "${YELLOW}ℹ️  メモリ容量: $MEM_TOTAL_GB GB (標準)${NC}"
    echo "   ※ VPS料金プランの選定基準です。MukenVault性能には影響しません"
    MEM_CAPACITY_SCORE=5
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

# メモリ帯域スコアリング
MEM_BW_INT=$(awk "BEGIN {print int($MEM_BANDWIDTH)}")
if [ "$MEM_BW_INT" -ge 30 ]; then
    echo -e "${GREEN}✅ メモリ帯域: $MEM_BANDWIDTH GB/s (優秀)${NC}"
    MEM_BANDWIDTH_SCORE=10
elif [ "$MEM_BW_INT" -ge 15 ]; then
    echo -e "${GREEN}✅ メモリ帯域: $MEM_BANDWIDTH GB/s (良好)${NC}"
    MEM_BANDWIDTH_SCORE=7
elif [ "$MEM_BW_INT" -ge 8 ]; then
    echo -e "${YELLOW}⚠️  メモリ帯域: $MEM_BANDWIDTH GB/s (制限あり)${NC}"
    MEM_BANDWIDTH_SCORE=5
else
    echo -e "${RED}⚠️  メモリ帯域: $MEM_BANDWIDTH GB/s (低速)${NC}"
    MEM_BANDWIDTH_SCORE=2
fi

MEM_SCORE=$((MEM_CAPACITY_SCORE + MEM_BANDWIDTH_SCORE))
echo ""

# =================================================================
# 4.5 平文アクセス性能測定（NEW!）
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  4.5 平文アクセス性能測定（ベースライン）${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "平文アクセス速度を測定中..."
echo "（これは暗号化していない通常のメモリアクセス速度です）"
echo ""

# 8バイト単位平文アクセステスト（volatile修正版）
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

# 64バイト単位平文アクセステスト（volatile修正版）
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
        
        // 4ブロック並列処理
        for (size_t i = 0; i < SIZE; i += 64) {
            // プリフェッチ
            _mm_prefetch((char*)(data + i + 128), _MM_HINT_T0);
            
            // 4ブロック同時ロード
            __m128i b0 = _mm_loadu_si128((__m128i*)(data + i));
            __m128i b1 = _mm_loadu_si128((__m128i*)(data + i + 16));
            __m128i b2 = _mm_loadu_si128((__m128i*)(data + i + 32));
            __m128i b3 = _mm_loadu_si128((__m128i*)(data + i + 48));
            
            // 初期XOR
            b0 = _mm_xor_si128(b0, round_keys[0]);
            b1 = _mm_xor_si128(b1, round_keys[0]);
            b2 = _mm_xor_si128(b2, round_keys[0]);
            b3 = _mm_xor_si128(b3, round_keys[0]);
            
            // 10ラウンド並列暗号化
            for (int r = 1; r < 10; r++) {
                b0 = _mm_aesenc_si128(b0, round_keys[r]);
                b1 = _mm_aesenc_si128(b1, round_keys[r]);
                b2 = _mm_aesenc_si128(b2, round_keys[r]);
                b3 = _mm_aesenc_si128(b3, round_keys[r]);
            }
            
            // 最終ラウンド
            b0 = _mm_aesenclast_si128(b0, round_keys[10]);
            b1 = _mm_aesenclast_si128(b1, round_keys[10]);
            b2 = _mm_aesenclast_si128(b2, round_keys[10]);
            b3 = _mm_aesenclast_si128(b3, round_keys[10]);
            
            // 4ブロック同時書き込み
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

# AES性能スコアリング
AES_SPEED_INT=$(awk "BEGIN {print int($AES_SPEED)}")
if [ "$AES_SPEED_INT" -ge 20 ]; then
    echo -e "${GREEN}✅ AES-NI性能: $AES_SPEED GB/s (優秀)${NC}"
    AES_PERF_SCORE=15
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
# 6. VAES実性能測定（最新CPUボーナス）
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  6. VAES実性能測定（最新CPUボーナス）${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

VAES_BONUS=0

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
#include <immintrin.h>
#include <x86intrin.h>

#define SIZE (256 * 1024 * 1024)
#define ITERATIONS 5

double get_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec / 1000000.0;
}

#if defined(__AVX512F__) && defined(__VAES__)
void keyless_vaes_encrypt(uint8_t* data, size_t size, const uint8_t* key) {
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
    
    keyless_vaes_encrypt(data, SIZE, key);
    
    double best_speed = 0.0;
    for (int iter = 0; iter < ITERATIONS; iter++) {
        double start = get_time();
        keyless_vaes_encrypt(data, SIZE, key);
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

    gcc -O3 -march=native -mavx512f -mvaes -o "$TEMP_DIR/vaes_benchmark" "$TEMP_DIR/vaes_benchmark.c" 2>/dev/null
    if [ $? -eq 0 ]; then
        VAES_SPEED=$("$TEMP_DIR/vaes_benchmark" 2>/dev/null || echo "0")
        
        if [ "$VAES_SPEED" != "0" ]; then
            echo "VAES暗号化速度: $VAES_SPEED GB/s"
            echo ""
            
            # VAES vs AES-NI比較
            RATIO=$(awk "BEGIN {printf \"%.2f\", $VAES_SPEED / $AES_SPEED}")
            echo "【VAES効果】"
            echo "  AES-NI比: ${RATIO}倍高速！"
            echo "  → VAESは通常のAES-NIより大幅に高速です"
            echo ""
            
            # VAESボーナススコア計算（控えめに調整）
            VAES_SPEED_INT=$(awk "BEGIN {print int($VAES_SPEED)}")
            if [ "$VAES_SPEED_INT" -ge 60 ]; then
                VAES_BONUS=10
            elif [ "$VAES_SPEED_INT" -ge 50 ]; then
                VAES_BONUS=8
            elif [ "$VAES_SPEED_INT" -ge 40 ]; then
                VAES_BONUS=7
            elif [ "$VAES_SPEED_INT" -ge 30 ]; then
                VAES_BONUS=6
            elif [ "$VAES_SPEED_INT" -ge 20 ]; then
                VAES_BONUS=5
            elif [ "$VAES_SPEED_INT" -ge 10 ]; then
                VAES_BONUS=3
            else
                VAES_BONUS=2
            fi
            
            if [ "$VAES_SPEED_INT" -ge 20 ]; then
                echo -e "${GREEN}ℹ️  VAES性能: $VAES_SPEED GB/s${NC}"
            else
                echo -e "${YELLOW}ℹ️  VAES性能: $VAES_SPEED GB/s${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  VAES測定失敗${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  VAESベンチマーク コンパイル失敗${NC}"
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

# 仮想化チェック
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

# プロバイダー推定
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

# ボトルネックの特定
if [ "$VAES_AVAILABLE" -eq 1 ] && [ -n "$VAES_SPEED" ] && [ "$VAES_SPEED" != "0" ]; then
    BASE_SPEED=$VAES_SPEED
    PERF_BASIS="VAES"
else
    BASE_SPEED=$AES_SPEED
    PERF_BASIS="AES-NI"
fi

# メモリ帯域との比較（実測値ベース）
BOTTLENECK="CPU性能"
EXPECTED_SPEED=$BASE_SPEED

MEM_BW_FLOAT=$(awk "BEGIN {printf \"%.2f\", $MEM_BANDWIDTH}")
BASE_SPEED_FLOAT=$(awk "BEGIN {printf \"%.2f\", $BASE_SPEED}")
PLAINTEXT_64B_FLOAT=$(awk "BEGIN {printf \"%.2f\", $PLAINTEXT_64BYTE}")

# 実測平文性能を優先的に使用
if awk "BEGIN {exit !($PLAINTEXT_64B_FLOAT > $MEM_BW_FLOAT)}"; then
    # 平文64バイト測定値の方が信頼性が高い
    ACTUAL_MEM_PERF=$PLAINTEXT_64B_FLOAT
else
    ACTUAL_MEM_PERF=$MEM_BW_FLOAT
fi

if awk "BEGIN {exit !($ACTUAL_MEM_PERF < $BASE_SPEED_FLOAT)}"; then
    BOTTLENECK="メモリ帯域"
    # メモリがボトルネックの場合、平文性能とほぼ同じ
    # （VAES処理が十分速いため、オーバーヘッドはほぼゼロ）
    EXPECTED_SPEED=$(awk "BEGIN {printf \"%.2f\", $ACTUAL_MEM_PERF * 0.98}")
else
    # CPU性能の85%を期待値とする
    EXPECTED_SPEED=$(awk "BEGIN {printf \"%.2f\", $BASE_SPEED * 0.85}")
fi

# 性能ティアの決定
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

# 革新的な発見の表示
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
# 9. 体験品質の判定
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  9. 体験品質の判定${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# オーバーヘッド予測
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

if [ "$VAES_AVAILABLE" -eq 1 ] && [ -n "$VAES_SPEED" ] && [ "$VAES_SPEED" != "0" ]; then
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

# 総合スコア計算
TOTAL_SCORE=$((ARCH_SCORE + CPU_SCORE + INSTRUCTION_SCORE + MEM_SCORE + AES_PERF_SCORE + QUALITY_SCORE + VAES_BONUS))

# スコア表示
echo "総合スコア: $TOTAL_SCORE/$MAX_SCORE点 ($((TOTAL_SCORE * 100 / MAX_SCORE))%)"
echo ""

# 総合評価（期待性能ベース）
echo "【総合評価】"
EXPECTED_SPEED_INT=$(awk "BEGIN {print int($EXPECTED_SPEED)}")

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
# 11. 適合用途の判定
# =================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  11. 適合用途の判定${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "この環境で快適に使える用途:"
echo ""

if [ "$EXPECTED_SPEED_INT" -ge 30 ]; then
    echo -e "${GREEN}✅ エンタープライズWebアプリ${NC}"
    echo -e "${GREEN}✅ 高トラフィックAPIサーバー${NC}"
    echo -e "${GREEN}✅ データベースサーバー（大規模）${NC}"
    echo -e "${GREEN}✅ リアルタイム処理${NC}"
    echo -e "${GREEN}✅ AI/ML推論サーバー${NC}"
elif [ "$EXPECTED_SPEED_INT" -ge 15 ]; then
    echo -e "${GREEN}✅ Webアプリケーション${NC}"
    echo -e "${GREEN}✅ APIサーバー${NC}"
    echo -e "${GREEN}✅ データベースサーバー（中規模）${NC}"
    echo -e "${GREEN}✅ ファイルサーバー${NC}"
elif [ "$EXPECTED_SPEED_INT" -ge 8 ]; then
    echo -e "${GREEN}✅ 静的サイト・ブログ${NC}"
    echo -e "${GREEN}✅ ファイルサーバー${NC}"
    echo -e "${GREEN}✅ 開発・テスト環境${NC}"
    echo -e "${GREEN}✅ バックアップサーバー${NC}"
    echo -e "${YELLOW}⚠️  軽量Webアプリ（トライアル推奨）${NC}"
elif [ "$EXPECTED_SPEED_INT" -ge 4 ]; then
    echo -e "${GREEN}✅ 静的コンテンツ配信${NC}"
    echo -e "${GREEN}✅ 個人用途${NC}"
    echo -e "${YELLOW}⚠️  開発・検証環境（負荷制限あり）${NC}"
    echo -e "${RED}❌ 本番Webアプリ${NC}"
else
    echo -e "${YELLOW}⚠️  検証・学習用途のみ${NC}"
    echo -e "${RED}❌ 本番環境${NC}"
    echo -e "${RED}❌ 高負荷システム${NC}"
fi
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
    if [ "$VAES_AVAILABLE" -eq 1 ] && [ -n "$VAES_SPEED" ] && [ "$VAES_SPEED" != "0" ]; then
        echo "  VAES Speed: $VAES_SPEED GB/s"
        echo "  VAES vs AES-NI: ${RATIO}x faster"
    fi
    echo ""
    echo "Environment:"
    echo "  Virtual: $([ "$IS_VIRTUAL" -eq 1 ] && echo "Yes" || echo "No")"
    echo "  Provider: $PROVIDER"
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
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
