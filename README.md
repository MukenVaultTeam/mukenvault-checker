# MukenVault Pre-Installation Checker

<div align="center">

![MukenVault](https://img.shields.io/badge/MukenVault-Checker-blue?style=for-the-badge)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-green.svg?style=for-the-badge)](https://www.linux.org/)
[![Version](https://img.shields.io/badge/version-1.2.1-blue.svg?style=for-the-badge)](https://github.com/MukenVaultTeam/mukenvault-checker/releases)

**サーバー選び、もう迷わない**

MukenVaultがあなたの環境でどれだけ快適に動作するか、  
1分で診断します。

[🚀 クイックスタート](#クイックスタート) • [📖 ドキュメント](#使い方) • [💬 サポート](#サポート)

</div>

---

## 🎯 これは何？

**MukenVault導入前チェッカー**は、革新的なメモリ暗号化システム「MukenVault」を導入する前に、あなたのサーバー環境で期待できる性能を自動診断するツールです。

### ✨ できること

- ✅ **性能予測** - 実際の暗号化速度を測定・予測
- ✅ **サーバー選定支援** - 最適なサーバープラン選びをサポート
- ✅ **用途別判定** - あなたのサービスに適しているか診断
- ✅ **詳細レポート** - 環境情報と推奨事項をファイル出力
- ✅ **完全無料** - オープンソース、自由に利用可能

---

## 🚀 クイックスタート

```bash
curl -fsSL https://raw.githubusercontent.com/MukenVaultTeam/mukenvault-checker/main/mukenvault_pre_check.sh | sudo bash
```

---

## 🆕 v1.2.1 New Features (2025-11-11)

### VAES AVX-512 Optimization - 60GB/s達成！

VAES実装をAVX2からAVX-512に完全移行し、**驚異的な60GB/s超**の暗号化速度を実現しました！

**主な改善:**
- ✅ **VAES AVX-512実装** - 512bit幅の並列処理で2倍高速化
- ✅ **キー展開最適化** - ループ外移動で4.7倍のパフォーマンス向上
- ✅ **正確な性能予測** - 平文性能ベースの期待値算出
- ✅ **オーバーヘッド2%** - 暗号化してもほぼ同じ速度！

**実測例:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  6. VAES実性能測定（最新CPUボーナス）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

VAES暗号化速度: 57.56 GB/s

【VAES効果】
  AES-NI比: 6.02倍高速！
  → VAESは通常のAES-NIより大幅に高速です

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  8. 期待性能の算出
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【期待性能】
  MukenVault導入後の予想速度: 24.78 GB/s
  性能基準: VAES
  ボトルネック: メモリ帯域
  性能ティア: Premium

【革新的発見】
  平文アクセス:    25.29 GB/s
  VAES暗号化:      57.56 GB/s
  期待性能:        24.78 GB/s

→ 暗号化してもほぼ同じ速度で動作します！
  （CPU処理が十分速いため、オーバーヘッドほぼゼロ）

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  10. 総合診断結果
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

総合スコア: 100/100点 (100%)

【総合評価】
  評価: A (優秀)
  ✅ 優秀！MukenVaultに最適な環境です
```

**技術的詳細:**
- AVX-512命令セット（512bit幅）
- 4ブロック同時処理
- 14ラウンド暗号化（AES-256相当）
- プリフェッチ活用によるレイテンシ隠蔽

**対応CPU:**
- AMD: EPYC Milan (第3世代) 以降
- Intel: Ice Lake (第10世代) 以降

**v1.2.1での変更点:**
- VAES実装をAVX2（256bit）からAVX-512（512bit）に変更
- キー展開最適化による4.7倍高速化
- 平文ベースライン測定（8バイト/64バイト）の追加
- 期待性能計算アルゴリズムの完全刷新
- メモリ容量評価の調整（VPS選定基準を明示）
- CPU情報取得の安定化（/proc/cpuinfo使用）
- 評価ロジックを実性能ベースに変更

---

## 💡 革新的発見

### **暗号化してもほぼ同じ速度！**

CPU処理速度（57.56 GB/s）がメモリ速度（25.29 GB/s）より
2倍以上速いため、**暗号化オーバーヘッドがほぼゼロ**です。

これがMukenVaultの革新性です。

```
従来の暗号化技術:
  オーバーヘッド: 30-50%
  体感: 明らかに遅い
  
KeyLess VAES:
  オーバーヘッド: 2%
  体感: ほぼ変わらない
```

---

## 📊 診断項目

診断は**10のカテゴリー**で実施されます：

### 1. 基本システム情報
- OS、カーネルバージョン
- アーキテクチャ（x86_64）

### 2. CPU性能チェック
- CPUモデル、コア数、周波数

### 3. CPU命令セットチェック ⭐️
- **AES-NI** (必須)
- **AVX2** (推奨)
- **VAES** (最高性能)
- **AVX-512** (高性能)

### 4. メモリ性能チェック
- メモリ容量
- メモリ帯域測定

### 4.5 平文アクセス性能測定 🆕
- 8バイト単位アクセス
- 64バイト単位最適化アクセス

### 5. AES-NI実性能測定
- 実際の暗号化速度測定

### 6. VAES実性能測定 🆕
- AVX-512による超高速暗号化測定
- AES-NIとの比較

### 7. 環境種別の判定
- 仮想化環境検出
- プロバイダー推定

### 8. 期待性能の算出 🆕
- MukenVault導入後の予想速度
- ボトルネック検出
- 革新的発見の表示

### 9. 体験品質の判定
- オーバーヘッド予測
- 快適度評価

### 10. 総合診断結果
- 総合スコア（100点満点）
- 評価ランク（S/A/B/C/D）

### 11. 適合用途の判定
- 用途別適合性評価

---

## 📈 性能比較表

| CPU世代 | 命令セット | VAES速度 | 期待性能 | OH | 評価 |
|---------|-----------|----------|---------|-----|------|
| AMD EPYC Milan | VAES + AVX-512 | 50-60 GB/s | 20-25 GB/s | 2% | S/A |
| Intel Ice Lake | VAES + AVX-512 | 40-50 GB/s | 15-20 GB/s | 3-5% | A |
| AMD Zen2 | AES-NI + AVX2 | - | 8-15 GB/s | 10-20% | B |
| Intel Skylake | AES-NI + AVX2 | - | 8-12 GB/s | 15-25% | B/C |
| 旧世代 | AES-NI | - | 4-8 GB/s | 25-40% | C |

*OH = オーバーヘッド

---

## 🔧 使い方

### 方法1: ワンライナー（推奨）

```bash
curl -fsSL https://raw.githubusercontent.com/MukenVaultTeam/mukenvault-checker/main/mukenvault_pre_check.sh | sudo bash
```

### 方法2: ダウンロードして実行

```bash
# ダウンロード
wget https://raw.githubusercontent.com/MukenVaultTeam/mukenvault-checker/main/mukenvault_pre_check.sh

# または
curl -O https://raw.githubusercontent.com/MukenVaultTeam/mukenvault-checker/main/mukenvault_pre_check.sh

# 実行権限付与
chmod +x mukenvault_pre_check.sh

# 実行
sudo ./mukenvault_pre_check.sh
```

### 方法3: Gitクローン

```bash
git clone https://github.com/MukenVaultTeam/mukenvault-checker.git
cd mukenvault-checker
chmod +x mukenvault_pre_check.sh
sudo ./mukenvault_pre_check.sh
```

---

## 📋 要件

- **OS**: Linux（Ubuntu、CentOS、Debian等）
- **CPU**: x86_64アーキテクチャ
- **必須**: AES-NI対応CPU
- **推奨**: VAES + AVX-512対応CPU（最高性能）
- **権限**: root権限（sudo）
- **ツール**: gcc、基本的なビルドツール

---

## 🛠️ トラブルシューティング

### Q: gccが見つからない

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install build-essential

# CentOS/RHEL
sudo yum install gcc make

# Fedora
sudo dnf install gcc make
```

### Q: 権限エラーが出る

```bash
# sudoを使用してください
sudo ./mukenvault_pre_check.sh
```

### Q: VAESが測定されない

VAES非対応CPUの場合は正常な動作です。AES-NIベースで性能が算出されます。

### Q: 性能が低い

メモリ帯域がボトルネックの可能性があります。より高性能なVPSプランへのアップグレードを検討してください。

---

## 🎯 対応環境

### ✅ 完全対応（S/A評価）
- **最新CPU**: AMD EPYC Milan以降、Intel Ice Lake以降
- **VAES + AVX-512**: 50-60 GB/s
- **期待性能**: 20-25 GB/s
- **オーバーヘッド**: 2-3%

### ✅ 推奨（A/B評価）
- **標準CPU**: AMD Zen2以降、Intel Skylake以降
- **AES-NI + AVX2**: 測定なし
- **期待性能**: 8-15 GB/s
- **オーバーヘッド**: 10-20%

### ⚠️ 動作可能（B/C評価）
- **古いCPU**: AES-NI対応のみ
- **AES-NI**: 測定なし
- **期待性能**: 4-8 GB/s
- **オーバーヘッド**: 25-40%

### ❌ 非対応
- AES-NI非対応CPU
- x86_64以外のアーキテクチャ

---

## 🤝 コントリビューション

プルリクエスト大歓迎！

1. このリポジトリをフォーク
2. 機能ブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

---

## 📝 ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照

---

## 🔗 リンク

- **MukenVault**: [公式サイト](https://mukenvault.com)
- **ドキュメント**: [ドキュメント](https://docs.mukenvault.com)
- **お問い合わせ**: support@mukenvault.com

---

## 🌟 スター歓迎！

このツールが役に立ったら、ぜひ⭐️スターをお願いします！

---

**Made with ❤️ by Superasystem株式会社**
