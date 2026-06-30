# AWS CLI読み取り系運用確認ラボ

## 1. 目的

このドキュメントは、AWS運用設計ラボの一部として、AWS CLIを使用したAWSリソース確認作業を学習するためのものである。

証券会社向け運用設計案件では、AWS上のLinux/Windowsサーバ、EBS、Aurora、ALBなどの運用設計やバックアップ確認、ジョブ設計、手順書作成が求められる。

本ラボでは、いきなりAWSリソースを作成・変更・削除するのではなく、まずは読み取り系コマンドを中心に、AWS上の構成情報を安全に確認することを目的とする。

---

## 2. 想定する業務との関係

想定求人では、以下のような業務が含まれている。

* AWS上のLinux/Windowsサーバ向けシステム運用設計
* AWS CLIコマンドでのAurora/EBSバックアップ確認
* ALB割振制御
* Bashでのスクリプト設計、製造、テスト
* JP1/AJSでのジョブ設計、製造、テスト
* 運用手順書、設計書、テスト仕様書の作成

本ラボでは、これらのうち、まず以下の基礎部分を学習対象とする。

* AWS CLIの基本操作
* AWSアカウント・認証情報の確認
* VPC、サブネット、セキュリティグループの確認
* EBSボリューム、スナップショットの確認
* RDS/Auroraクラスター、スナップショットの確認
* ALB、ターゲットグループ、ターゲットヘルスの確認
* 読み取り系コマンドの実行結果を運用確認の証跡として整理すること

---

## 3. 安全方針

本ラボでは、以下の安全方針を守る。

### 実行するコマンド

* `get`
* `list`
* `describe`

などの読み取り系コマンドを中心に使用する。

### 実行しないコマンド

以下のような作成・変更・削除系コマンドは、本ラボの初期段階では実行しない。

* `create`
* `delete`
* `modify`
* `update`
* `put`
* `attach`
* `detach`
* `start`
* `stop`
* `reboot`
* `terminate`

### 注意事項

* AWSアクセスキー、シークレットアクセスキーはGitHubに記載しない。
* `aws sts get-caller-identity` の結果に含まれるAWSアカウントIDは、公開前にマスクする。
* 出力結果をGitHubに掲載する場合、アカウントID、ARN、ユーザー名、リソースIDなどは必要に応じてマスクする。
* EC2、NAT Gateway、RDS、ALBなど課金が発生する可能性のあるリソースは作成しない。
* 本ラボは個人学習であり、実務環境では実行しない。

---

## 4. 前提条件

本ラボでは、以下の環境を想定する。

* OS：WSL2 Ubuntu
* AWS CLI：インストール済み
* AWS認証情報：設定済み
* 対象リージョン：us-east-1
* GitHubリポジトリ：hyamada-cloud1258
* 作業フォルダ：AWS運用設計ラボ

---

## 5. 事前確認

### 5.1 AWS CLIのバージョン確認

```bash
aws --version
```

目的：

AWS CLIが使用できる状態か確認する。

確認ポイント：

* コマンドがエラーにならないこと
* AWS CLIのバージョンが表示されること

---

### 5.2 AWS認証情報の確認

```bash
aws sts get-caller-identity
```

目的：

現在使用しているAWS認証情報が有効か確認する。

確認ポイント：

* `UserId` が表示されること
* `Account` が表示されること
* `Arn` が表示されること

注意：

このコマンド結果にはAWSアカウントIDやARNが含まれるため、GitHubにそのまま貼り付けない。

公開する場合は以下のようにマスクする。

```text
Account: 123456789012 → Account: ************
Arn: arn:aws:iam::123456789012:user/example-user → arn:aws:iam::************:user/********
```

---

### 5.3 現在のAWS CLI設定確認

```bash
aws configure list
```

目的：

AWS CLIがどの認証情報、リージョン、出力形式を使用しているか確認する。

確認ポイント：

* access_key が設定されていること
* secret_key が設定されていること
* region が想定どおりであること
* output が設定されていること

注意：

アクセスキーそのものは画面に一部しか表示されないが、GitHubやREADMEには記載しない。

---

## 6. S3確認

### 6.1 S3バケット一覧確認

```bash
aws s3 ls
```

目的：

AWS CLIからS3にアクセスできるか確認する。

確認ポイント：

* バケット一覧が表示されること
* 権限がない場合はAccessDeniedになる可能性がある
* バケット名をGitHubに記載する場合は必要に応じてマスクする

運用観点：

S3は静的サイトホスティング、ログ保管、バックアップファイル置き場などで使われることが多いため、運用確認対象になりやすい。

---

## 7. EC2/VPC関連確認

### 7.1 利用可能リージョン確認

```bash
aws ec2 describe-regions
```

目的：

AWS CLIからEC2 APIを呼び出せるか確認する。

確認ポイント：

* リージョン一覧が表示されること
* us-east-1 が含まれていること

---

### 7.2 VPC一覧確認

```bash
aws ec2 describe-vpcs --region us-east-1
```

目的：

対象リージョンのVPC一覧を確認する。

確認ポイント：

* VPC ID
* CIDR Block
* Default VPCかどうか
* Tags

運用観点：

VPCはAWSネットワークの基本単位であり、サーバ、RDS、ALBなどの配置先を確認するうえで重要である。

---

### 7.3 サブネット一覧確認

```bash
aws ec2 describe-subnets --region us-east-1
```

目的：

対象リージョンのサブネット一覧を確認する。

確認ポイント：

* Subnet ID
* VPC ID
* CIDR Block
* Availability Zone
* MapPublicIpOnLaunch
* Tags

運用観点：

サブネットがPublic用かPrivate用かを確認することで、システム構成や通信経路を理解しやすくなる。

---

### 7.4 セキュリティグループ一覧確認

```bash
aws ec2 describe-security-groups --region us-east-1
```

目的：

セキュリティグループの一覧とインバウンド・アウトバウンドルールを確認する。

確認ポイント：

* Security Group ID
* Group Name
* Description
* VPC ID
* Inbound Rule
* Outbound Rule

運用観点：

障害対応や接続確認では、セキュリティグループの許可ルール確認が重要になる。

特に以下を確認する。

* 必要なポートが許可されているか
* 不要に広い許可がないか
* 0.0.0.0/0 が設定されている場合、意図したものか

---

## 8. EBS関連確認

### 8.1 EBSボリューム一覧確認

```bash
aws ec2 describe-volumes --region us-east-1
```

目的：

EBSボリュームの一覧を確認する。

確認ポイント：

* Volume ID
* Size
* Volume Type
* State
* Availability Zone
* Attached Instance ID
* Tags

運用観点：

EBSはEC2のディスクとして利用されるため、容量、状態、アタッチ先の確認が重要である。

---

### 8.2 自分のEBSスナップショット確認

```bash
aws ec2 describe-snapshots --owner-ids self --region us-east-1
```

目的：

自分のAWSアカウントが所有するEBSスナップショットを確認する。

確認ポイント：

* Snapshot ID
* Volume ID
* Start Time
* State
* Progress
* Description
* Tags

運用観点：

バックアップ運用では、スナップショットが取得されているか、取得日時が想定どおりかを確認することが重要である。

注意：

スナップショットは保持しているだけで課金対象になるため、実務では世代管理や削除ルールも重要になる。

本ラボでは削除操作は行わない。

---

## 9. RDS/Aurora関連確認

### 9.1 DBクラスター一覧確認

```bash
aws rds describe-db-clusters --region us-east-1
```

目的：

AuroraなどのRDS DBクラスター一覧を確認する。

確認ポイント：

* DBClusterIdentifier
* Engine
* Status
* Endpoint
* ReaderEndpoint
* BackupRetentionPeriod
* PreferredBackupWindow

運用観点：

Aurora運用では、クラスター状態、バックアップ保持期間、バックアップ時間帯の確認が重要である。

---

### 9.2 DBクラスターのスナップショット確認

```bash
aws rds describe-db-cluster-snapshots --region us-east-1
```

目的：

AuroraなどのDBクラスターのスナップショット一覧を確認する。

確認ポイント：

* DBClusterSnapshotIdentifier
* DBClusterIdentifier
* SnapshotCreateTime
* Status
* Engine
* SnapshotType

運用観点：

データベース運用では、バックアップが取得されているか、スナップショットの状態がavailableかを確認することが重要である。

注意：

本ラボではスナップショットの作成・削除は行わない。

---

## 10. ALB関連確認

### 10.1 ロードバランサー一覧確認

```bash
aws elbv2 describe-load-balancers --region us-east-1
```

目的：

ALB/NLBの一覧を確認する。

確認ポイント：

* LoadBalancerName
* LoadBalancerArn
* DNSName
* Scheme
* VpcId
* State
* Type

運用観点：

ALBはWebシステムの入口になるため、障害時には状態、DNS名、VPC、Scheme、リスナー、ターゲットグループの確認が重要になる。

---

### 10.2 ターゲットグループ一覧確認

```bash
aws elbv2 describe-target-groups --region us-east-1
```

目的：

ターゲットグループ一覧を確認する。

確認ポイント：

* TargetGroupName
* TargetGroupArn
* Protocol
* Port
* VpcId
* HealthCheckProtocol
* HealthCheckPath

運用観点：

ALB配下のEC2やコンテナが正常に振り分け対象になっているか確認するために重要である。

---

### 10.3 ターゲットヘルス確認

ターゲットグループARNを指定して確認する。

```bash
aws elbv2 describe-target-health \
  --target-group-arn <ターゲットグループARN> \
  --region us-east-1
```

目的：

ターゲットグループ配下のターゲット状態を確認する。

確認ポイント：

* Target ID
* Port
* TargetHealth State
* Reason
* Description

運用観点：

ALB配下のサーバが `healthy` か `unhealthy` かを確認することで、障害時の切り分けに利用できる。

注意：

ターゲットグループARNには実際のARNが含まれるため、GitHubに掲載する場合はマスクする。

---

## 11. 出力結果の保存方法

AWS CLIの結果を証跡として保存したい場合は、以下のようにリダイレクトする。

```bash
aws ec2 describe-vpcs --region us-east-1 > aws-vpcs-result.json
```

ただし、AWSアカウントID、ARN、リソースID、バケット名などが含まれる可能性があるため、GitHubに公開する前に内容を確認し、必要に応じてマスクする。

---

## 12. GitHub公開時のマスク方針

公開前に以下の情報はマスク対象とする。

* AWSアカウントID
* IAMユーザー名
* IAMロール名
* ARN
* アクセスキー
* バケット名
* VPC ID
* Subnet ID
* Security Group ID
* Snapshot ID
* DB Cluster Identifier
* Load Balancer ARN
* Target Group ARN

例：

```text
Account: ************
VpcId: vpc-xxxxxxxx
SubnetId: subnet-xxxxxxxx
SecurityGroupId: sg-xxxxxxxx
SnapshotId: snap-xxxxxxxx
```

---

## 13. 面談で説明するポイント

AWS CLIについては、まず読み取り系コマンドを中心に学習しています。

具体的には、VPC、サブネット、セキュリティグループ、EBS、スナップショット、RDS/Aurora、ALB、ターゲットグループなどを `describe` 系コマンドで確認する練習をしています。

作成・変更・削除系コマンドは誤操作や課金リスクがあるため、最初は実行せず、構成確認や運用確認に使う読み取り系コマンドに限定しています。

実務経験としては、金融系システム運用監視、障害一次対応、エスカレーション、手順書整備の経験があります。

現在はその経験をもとに、AWS CLIで構成情報を確認し、結果を証跡として残す学習を進めています。

---

## 14. 今後の改善予定

今後は、以下の内容を追加する予定である。

* AWS CLI確認結果を整理するMarkdownテンプレート作成
* 読み取り系AWS CLIコマンドをまとめたBashスクリプト作成
* 実行ログの保存
* 正常系・異常系のテスト仕様書作成
* AWS CLI実行結果のマスク済みサンプル作成
* EBSバックアップ確認手順書
* Auroraバックアップ確認手順書
* ALBターゲットヘルス確認手順書
* JP1/AJSのジョブ設計を想定した終了コード整理
