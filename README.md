# MukenVault Pre-Installation Checker

<div align="center">

![MukenVault](https://img.shields.io/badge/MukenVault-Checker-blue?style=for-the-badge)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-green.svg?style=for-the-badge)](https://www.linux.org/)

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
curl -fsSL https://raw.githubusercontent.com/MukenVaultTeam/mukenvault-checker/main/install.sh | sudo bash
```

## 🆕 v1.1 New Features (2025-11-11)

### VAES Performance Measurement

最新世代CPU（AMD EPYC Milan、Intel Ice Lake以降）で利用可能なVAES命令セットの実性能測定に対応しました！

**主な機能:**
- ✅ VAES実性能の測定（256MB暗号化テスト）
- ✅ AES-NIとの性能比較を自動表示
- ✅ ボーナススコアシステム（最高115点）
- ✅ より正確な性能予測

**測定例:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  5. AES-NI実性能測定
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

AES-NI暗号化速度: 10.68 GB/s
⚠️  AES-NI性能: 10.68 GB/s (標準)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  6. VAES実性能測定（最新CPUボーナス）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

VAES暗号化速度: 25.40 GB/s
✅ VAES性能: 25.40 GB/s (優秀！)

【VAES効果】
  AES-NI比: 2.38倍高速！
  → VAESは通常のAES-NIより大幅に高速です
```

**対応CPU:**
- AMD: EPYC Milan (第3世代) 以降
- Intel: Ice Lake (第10世代) 以降

**v1.1での変更点:**
- VAES実性能測定機能を追加
- 性能期待値をより現実的な値に調整
- ボーナススコアシステムの導入
- 性能比較表示の追加
```

---

## 🎉 **Step 4: リリースv1.1.0を作成**

### **手順**

1. **「Releases」→「Create a new release」**

2. **リリース情報を入力：**
```
Tag: v1.1.0
Title: v1.1.0 - VAES Performance Measurement Support

Description:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🆕 What's New in v1.1.0

### VAES Performance Measurement

最新世代CPUのVAES命令セットに対応し、実性能を測定できるようになりました！

### ✨ New Features

- **VAES実性能測定**: 256MB暗号化テストで実測速度を測定
- **性能比較表示**: AES-NIとの速度比較を自動表示
- **ボーナススコア**: VAES性能に応じて最大+15点
- **改善された評価**: より正確な性能予測と用途判定

### 📊 Performance Example
```
環境: AMD EPYC Milan 3コア / 2GB
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AES-NI性能:  10.68 GB/s
VAES性能:    25.40 GB/s ★
性能向上:    2.38倍！

総合スコア: 70点 → 78点（VAESボーナス+8点）
評価: B (良好) → B+ (より良好)
```

### 🎯 Who Benefits

- 最新世代CPU（EPYC Milan、Ice Lake以降）を使用中の方
- より高速な暗号化性能を求める方
- 正確なサーバー性能評価が必要な方

### 🔧 Technical Details

- VAES命令セット検出の改善
- 256bitレジスタによる8ブロック同時暗号化測定
- 性能期待値の現実的な調整（30GB/s以上）
- メモリ帯域とCPU性能の適切なバランス計算

### 📝 Compatibility

- v1.0との完全な互換性
- 既存環境での動作に影響なし
- VAES非対応CPUでも正常に動作

### 🚀 Installation
```bash
curl -fsSL https://raw.githubusercontent.com/MukenVaultTeam/mukenvault-checker/main/install.sh | sudo bash
```

### 🙏 Acknowledgments

実測データを提供いただいたユーザーの皆様に感謝します。

---

**Full Changelog**: v1.0.0...v1.1.0
```

