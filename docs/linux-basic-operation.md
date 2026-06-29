# Linux基本操作ラボ

## 目的

Windows上のWSL Ubuntu環境を使用し、Linuxサーバ運用で必要となる基本操作を学習する。

本ラボでは、Linuxユーザ作成、グループ作成、ユーザのグループ追加、ファイル作成、権限確認、サービス状態確認、ログ確認を実施する。

なお、本内容は個人学習用のラボであり、実務経験ではない。

---

## 前提条件

| 項目       | 内容                         |
| -------- | -------------------------- |
| PC       | Windows 11                 |
| Linux環境  | WSL2 Ubuntu                |
| 作業ユーザ    | hirotaka                   |
| 作業ディレクトリ | `/home/hirotaka/linux-lab` |
| 作成ユーザ    | `aircon-operator`          |
| 作成グループ   | `operation-team`           |

---

## 構成図

```text
Windows 11
  |
  | WSL2
  v
Ubuntu
  |
  |-- 作業ユーザ: hirotaka
  |-- 作成ユーザ: aircon-operator
  |-- 作成グループ: operation-team
  |-- 作業ディレクトリ: /home/hirotaka/linux-lab
  |-- 確認ファイル: operation-check.txt
```

---

## パラメータ表

| 種別     | 名前                         | 用途                          |
| ------ | -------------------------- | --------------------------- |
| ユーザ    | `aircon-operator`          | 空調管理システムの運用担当者を想定したLinuxユーザ |
| グループ   | `operation-team`           | 運用チームを想定したグループ              |
| ディレクトリ | `/home/hirotaka/linux-lab` | Linux基本操作ラボ用の作業ディレクトリ       |
| ファイル   | `operation-check.txt`      | ファイル作成・権限確認用の確認ファイル         |
| 結果ファイル | `linux-lab-result.txt`     | 作業結果を保存する確認用ファイル            |

---

## 作業手順

### 1. Ubuntu環境の確認

Ubuntu上で以下を実行し、現在のユーザ、作業場所、Linux環境を確認した。

```bash
whoami
pwd
uname -a
```

確認結果：

```text
current user: hirotaka
current directory: /home/hirotaka/linux-lab
kernel: Linux DESKTOP-3E8RPTM 6.18.33.2-microsoft-standard-WSL2
```

---

### 2. 作業ディレクトリ作成

```bash
mkdir -p ~/linux-lab
cd ~/linux-lab
pwd
```

確認結果：

```text
/home/hirotaka/linux-lab
```

---

### 3. ファイル作成と権限確認

```bash
touch operation-check.txt
ls -l
```

確認結果：

```text
-rw-r--r-- 1 hirotaka hirotaka 0 Jun 28 23:48 operation-check.txt
```

`operation-check.txt` を作成し、所有者、所有グループ、権限を確認した。

---

### 4. Linuxユーザ作成

```bash
sudo adduser aircon-operator
```

確認コマンド：

```bash
id aircon-operator
```

確認結果：

```text
uid=1001(aircon-operator) gid=1001(aircon-operator) groups=1001(aircon-operator),100(users)
```

`aircon-operator` ユーザが作成されたことを確認した。

---

### 5. グループ作成

```bash
sudo groupadd operation-team
```

確認コマンド：

```bash
getent group operation-team
```

確認結果：

```text
operation-team:x:1002:
```

`operation-team` グループが作成されたことを確認した。

---

### 6. ユーザをグループへ追加

```bash
sudo usermod -aG operation-team aircon-operator
```

確認コマンド：

```bash
id aircon-operator
```

確認結果：

```text
uid=1001(aircon-operator) gid=1001(aircon-operator) groups=1001(aircon-operator),100(users),1002(operation-team)
```

`aircon-operator` が `operation-team` に所属していることを確認した。

---

### 7. sudo権限確認

```bash
sudo -l -U aircon-operator
```

確認結果：

```text
User aircon-operator is not allowed to run sudo on DESKTOP-3E8RPTM.
```

本ラボでは、不要な管理者権限を付与しない方針とし、`aircon-operator` にsudo権限がないことを確認した。

---

### 8. サービス状態確認

```bash
systemctl --version
systemctl is-system-running
systemctl status systemd-journald --no-pager
systemctl status ssh --no-pager
```

確認結果：

```text
systemd 259 (259.5-0ubuntu3)
running
systemd-journald: active (running)
ssh.service: Unit ssh.service could not be found.
```

WSL2 Ubuntu上でsystemdが動作していること、ログ管理サービスである `systemd-journald` が稼働していることを確認した。

SSHサービスについては、本環境では未導入であることを確認した。

---

### 9. ログ確認

```bash
tail -n 20 /var/log/dpkg.log
```

確認結果：

```text
2026-04-20 18:07:11 status installed libc-bin:amd64 2.43-2ubuntu2
2026-04-20 18:07:11 status installed dbus:amd64 1.16.2-2ubuntu4
```

`/var/log/dpkg.log` を確認し、Ubuntu上のパッケージ導入・設定履歴を確認した。

---

## 確認結果

| 確認項目       | 確認コマンド                         | 結果                         |
| ---------- | ------------------------------ | -------------------------- |
| 作業ユーザ確認    | `whoami`                       | `hirotaka`                 |
| 作業ディレクトリ確認 | `pwd`                          | `/home/hirotaka/linux-lab` |
| Linux環境確認  | `uname -a`                     | WSL2上のLinux環境を確認           |
| ファイル作成確認   | `ls -l`                        | `operation-check.txt` を確認  |
| ユーザ確認      | `id aircon-operator`           | `aircon-operator` 作成済み     |
| グループ確認     | `getent group operation-team`  | `operation-team` 作成済み      |
| グループ所属確認   | `id aircon-operator`           | `operation-team` 所属を確認     |
| sudo権限確認   | `sudo -l -U aircon-operator`   | sudo権限なしを確認                |
| systemd確認  | `systemctl is-system-running`  | `running`                  |
| ログ確認       | `tail -n 20 /var/log/dpkg.log` | パッケージ管理ログを確認               |

---

## 実行したコマンド一覧

```bash
cd ~
pwd
whoami
uname -a

mkdir -p ~/linux-lab
cd ~/linux-lab
pwd

touch operation-check.txt
ls -l

sudo adduser aircon-operator
id aircon-operator

sudo groupadd operation-team
getent group operation-team

sudo usermod -aG operation-team aircon-operator
id aircon-operator

sudo -l -U aircon-operator

systemctl --version
systemctl is-system-running
systemctl status systemd-journald --no-pager
systemctl status ssh --no-pager

tail -n 20 /var/log/dpkg.log
```

---

## トラブル時の確認ポイント

| 事象                           | 原因                              | 対応                                                   |
| ---------------------------- | ------------------------------- | ---------------------------------------------------- |
| `getnet` が見つからない             | `getent` の入力ミス                  | 正しいコマンド `getent group operation-team` を実行する          |
| `aircon-operatar` が存在しない     | ユーザ名の入力ミス                       | 正しいユーザ名 `aircon-operator` を指定する                      |
| `sudo -1` がエラーになる            | `-l` の入力ミス。数字の1ではなく小文字のL        | `sudo -l -U aircon-operator` を実行する                   |
| `systemct1` が見つからない          | `systemctl` の入力ミス。末尾が数字の1になっている | `systemctl --version` を実行する                          |
| `is-system-runnning` がエラーになる | `running` の `n` が多い             | `systemctl is-system-running` を実行する                  |
| `systemd-jpurnald` が見つからない   | `journald` の入力ミス                | `systemctl status systemd-journald --no-pager` を実行する |
| `ssh.service` が見つからない        | SSHサービスが未導入                     | 本ラボでは未導入として記録する                                      |

---

## 学んだこと

* Linuxではユーザとグループを分けて権限管理することを学んだ。
* `id` コマンドでユーザID、グループID、所属グループを確認できることを学んだ。
* `getent group` により、作成したグループ情報を確認できることを学んだ。
* `usermod -aG` により、既存の所属グループを維持したまま追加グループを設定できることを学んだ。
* `sudo -l -U` により、指定ユーザのsudo権限を確認できることを学んだ。
* `ls -l` により、ファイルの所有者、所有グループ、権限を確認できることを学んだ。
* `systemctl` により、systemdやサービス状態を確認できることを学んだ。
* `/var/log/dpkg.log` により、Ubuntuのパッケージ管理ログを確認できることを学んだ。
* コマンド入力ミスが発生した場合でも、エラーメッセージを確認して修正することが重要だと学んだ。

---

## 面談での説明例

WSL2上のUbuntu環境を使用して、Linuxの基本操作ラボを実施しました。

具体的には、Linuxユーザ作成、グループ作成、ユーザのグループ追加、ファイル作成、権限確認、sudo権限確認、systemdサービス状態確認、ログ確認を行いました。

作業結果はMarkdownに整理し、目的、パラメータ表、作業手順、確認結果、トラブル時の確認ポイントとしてまとめています。

実務経験ではありませんが、Linuxサーバ運用や構築補助で必要となる基本操作と、作業手順書の作成を意識して学習しました。
