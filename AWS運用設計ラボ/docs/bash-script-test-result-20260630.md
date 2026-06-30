# Bashスクリプト テスト実施結果

## 対象スクリプト

`scripts/system-check.sh`

## 実施日

2026年6月30日

## 実施環境

| 項目 | 内容 |
|---|---|
| 実行環境 | WSL2 Ubuntu |
| OS | Ubuntu 26.04 LTS |
| ホスト名 | DESKTOP-3E8RPTM |
| 実行ユーザー | hirotaka |
| 作業リポジトリ | hyamada-cloud1258 |
| 作業フォルダ | AWS運用設計ラボ |

## 実施結果一覧

| No | テスト内容 | 実行コマンド | 期待結果 | 実行結果 | 判定 |
|---:|---|---|---|---|---|
| 1 | 通常実行 | `./scripts/system-check.sh` | 正常終了し、`exit 0` を返す | `System check completed successfully.` / `exit 0` | OK |
| 2 | ログファイル作成確認 | `ls -l logs/` | ログファイルが作成される | `system-check-YYYYMMDD-HHMMSS.log` が作成された | OK |
| 3 | ログ内容確認 | `cat logs/system-check-*.log` | 実行結果がログに出力される | ディスク、メモリ、プロセス確認結果が出力された | OK |
| 4 | ディスク使用率異常テスト | `DISK_THRESHOLD=1 ./scripts/system-check.sh` | 異常終了し、`exit 1` を返す | `Disk usage is over threshold.` / `exit 1` | OK |
| 5 | 存在するプロセス確認 | `PROCESS_NAME=bash ./scripts/system-check.sh` | 正常終了し、`exit 0` を返す | `Process is running: bash` / `exit 0` | OK |
| 6 | 存在しないプロセス確認 | `PROCESS_NAME=no-such-process-999 ./scripts/system-check.sh` | 異常終了し、`exit 1` を返す | `Process is not running: no-such-process-999` / `exit 1` | OK |

## 確認できたこと

本テストにより、Linuxサーバ運用を想定した状態確認スクリプトとして、以下の動作を確認した。

- ディスク使用率を確認できる
- メモリ使用率を確認できる
- 任意のプロセス存在確認ができる
- 実行結果をログファイルに出力できる
- 正常時は `exit 0` を返す
- 異常時は `exit 1` を返す
- しきい値を変更して異常系テストを実施できる

## 学習メモ

今回の確認では、単にBashスクリプトを実行するだけでなく、ログ出力、正常終了、異常終了、終了コード確認まで行った。

特に、運用監視やジョブ管理では、画面上の表示だけでなく `exit 0` / `exit 1` のような終了コードが重要になるため、正常系と異常系の両方を確認した。

## 補足

本スクリプトおよびテスト結果は、実務環境で使用したものではなく、個人学習用に作成したものである。

Linuxサーバ運用、Bashスクリプト、ログ確認、終了コード判定、設計書・テスト仕様書作成の基礎理解を目的としている。
