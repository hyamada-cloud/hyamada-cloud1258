# Bashスクリプトテスト仕様書: system-check.sh

## 1. 文書情報

| 項目 | 内容 |
|---|---|
| 文書名 | Bashスクリプトテスト仕様書 |
| 対象スクリプト | `scripts/system-check.sh` |
| 対象設計書 | `docs/bash-script-design.md` |
| 作成区分 | 個人学習・ポートフォリオ |

## 2. テスト目的

`system-check.sh` が設計どおりに動作することを確認します。

確認観点は以下です。

- スクリプトが実行できること
- ログファイルが作成されること
- ディスク使用率を確認できること
- メモリ使用率を確認できること
- プロセス確認をスキップできること
- 指定プロセスの存在確認ができること
- 異常時に `exit 1` で終了すること
- 正常時に `exit 0` で終了すること

## 3. 前提条件

- WSL2 Ubuntu、Ubuntu Server、Amazon Linux系などのBash環境で実行する
- リポジトリ直下で作業する
- `scripts/system-check.sh` が存在する
- Bash、df、free、pgrepなどの基本コマンドが利用できる

## 4. 事前準備

```bash
cd aws-operation-design-lab
chmod +x scripts/system-check.sh
mkdir -p logs
```

## 5. テストケース一覧

| No | 観点 | 実行コマンド | 期待結果 |
|---:|---|---|---|
| 1 | 通常実行 | `./scripts/system-check.sh` | 正常に実行され、終了コードが `0` になる |
| 2 | ログ作成 | `ls -l logs/` | `system-check-YYYYMMDD-HHMMSS.log` 形式のログが作成される |
| 3 | ディスク異常判定 | `DISK_THRESHOLD=1 ./scripts/system-check.sh` | ディスク使用率が1%以上の場合、終了コードが `1` になる |
| 4 | メモリ異常判定 | `MEM_THRESHOLD=1 ./scripts/system-check.sh` | メモリ使用率が1%以上の場合、終了コードが `1` になる |
| 5 | プロセス確認スキップ | `PROCESS_NAME= ./scripts/system-check.sh` | プロセス確認がスキップされる |
| 6 | 存在するプロセス確認 | `PROCESS_NAME=bash ./scripts/system-check.sh` | `bash` が存在する場合、正常または他項目の結果に応じた終了になる |
| 7 | 存在しないプロセス確認 | `PROCESS_NAME=no_such_process ./scripts/system-check.sh` | 指定プロセスなしとして終了コードが `1` になる |
| 8 | ログ内容確認 | `tail -n 20 logs/system-check-*.log` | INFO、ERRORなどのログが確認できる |

## 6. 詳細テスト手順

### No.1 通常実行

#### コマンド

```bash
./scripts/system-check.sh
echo $?
```

#### 期待結果

- スクリプトが実行できる
- ディスク使用率、メモリ使用率が表示される
- 異常がなければ `0` が表示される

#### 確認ポイント

```text
System check completed successfully.
```

が表示されること。

---

### No.2 ログ作成確認

#### コマンド

```bash
ls -l logs/
```

#### 期待結果

以下のようなログファイルが作成されること。

```text
system-check-20260630-090000.log
```

---

### No.3 ディスク異常判定

#### コマンド

```bash
DISK_THRESHOLD=1 ./scripts/system-check.sh
echo $?
```

#### 期待結果

通常、ルートディスク使用率は1%以上のため、異常判定されます。

- `Disk usage is over threshold.` が表示される
- 終了コードが `1` になる

---

### No.4 メモリ異常判定

#### コマンド

```bash
MEM_THRESHOLD=1 ./scripts/system-check.sh
echo $?
```

#### 期待結果

通常、メモリ使用率は1%以上のため、異常判定されます。

- `Memory usage is over threshold.` が表示される
- 終了コードが `1` になる

---

### No.5 プロセス確認スキップ

#### コマンド

```bash
PROCESS_NAME= ./scripts/system-check.sh
```

#### 期待結果

以下のようなログが出力されること。

```text
PROCESS_NAME is not set. Process check was skipped.
```

---

### No.6 存在するプロセス確認

#### コマンド

```bash
PROCESS_NAME=bash ./scripts/system-check.sh
```

#### 期待結果

`bash` プロセスが存在する環境では、以下のようなログが出力されます。

```text
Process is running: bash
```

※環境によっては確認対象プロセス名を変更してください。

---

### No.7 存在しないプロセス確認

#### コマンド

```bash
PROCESS_NAME=no_such_process ./scripts/system-check.sh
echo $?
```

#### 期待結果

- `Process is not running: no_such_process` が表示される
- 終了コードが `1` になる

---

### No.8 ログ内容確認

#### コマンド

```bash
tail -n 20 logs/system-check-*.log
```

#### 期待結果

直近ログに以下のような内容が含まれること。

- 実行日時
- ホスト名
- OS情報
- ディスク使用率
- メモリ使用率
- プロセス確認結果
- 最終結果

## 7. テスト結果記録表

| No | 実施日 | 実施者 | 結果 | 備考 |
|---:|---|---|---|---|
| 1 |  |  | 未実施 |  |
| 2 |  |  | 未実施 |  |
| 3 |  |  | 未実施 |  |
| 4 |  |  | 未実施 |  |
| 5 |  |  | 未実施 |  |
| 6 |  |  | 未実施 |  |
| 7 |  |  | 未実施 |  |
| 8 |  |  | 未実施 |  |

## 8. 面談で説明するポイント

このテスト仕様書では、単にスクリプトを作るだけでなく、正常系、異常系、ログ出力、終了コードの確認まで整理しています。

運用設計業務では、作業手順だけでなく、異常時にどう検知し、どう判断し、どう記録するかが重要だと考えています。そのため、個人学習としても設計書とテスト仕様書を分けて作成し、実務に近い形で整理することを意識しました。
