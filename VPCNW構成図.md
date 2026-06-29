# AWS VPC基本設計ラボ

## 目的

このラボは、AWS上で小規模なVPCネットワーク設計を学習することを目的とした個人学習ラボである。

既存の「AWS空調管理・異常監視システム」は、React、S3、CloudFront、API Gateway、Lambda、DynamoDB、CloudWatch Logsを利用したサーバーレス構成で作成済みである。

一方で、AWS運用、インフラ運用、構築補助、社内SE、サーバ／ネットワーク運用では、VPC、サブネット、ルートテーブル、インターネットゲートウェイ、セキュリティグループの理解が重要になる。

そのため、本ラボではEC2やNAT Gatewayなどの課金リスクがあるリソースを極力使用せず、VPC設計、作成、確認、ドキュメント化を中心に行う。

本内容は実務経験ではなく、個人学習として作成したものである。

---

## 前提条件

| 項目 | 内容 |
|---|---|
| AWSアカウント | 利用可能であること |
| AWSマネジメントコンソール | ログイン済みであること |
| 作業リージョン | バージニア北部 `us-east-1` |
| 既存システム | AWS空調管理・異常監視システムとは別リソースとして作成 |
| 課金方針 | NAT Gateway、EC2常時起動、RDS、ALB、EIP放置は行わない |
| ドキュメント保存先 | `docs/aws-vpc-basic-design.md` |

---

## 構成図

```text
VPC: aircon-lab-vpc 10.0.0.0/16
│
├─ Internet Gateway: aircon-lab-igw
│
├─ Public Subnet A: aircon-lab-public-subnet-a 10.0.1.0/24
│   └─ Route Table: aircon-lab-public-rt
│      ├─ 10.0.0.0/16 -> local
│      └─ 0.0.0.0/0  -> aircon-lab-igw
│
├─ Private Subnet A: aircon-lab-private-subnet-a 10.0.11.0/24
│   └─ Route Table: aircon-lab-private-rt
│      └─ 10.0.0.0/16 -> local
│
└─ Security Group: aircon-lab-sg
    ├─ Inbound: なし
    └─ Outbound: すべて許可 0.0.0.0/0
```

画像版の構成図を使用する場合は、以下のように配置する。

```text
docs/
  aws-vpc-basic-design.md
  images/
    aws-vpc-basic-design.png
```

Markdown上では以下のように参照する。

```markdown
![AWS VPC基本設計ラボ](images/aws-vpc-basic-design.png)
```

---

## パラメータ表

### VPC

| 項目 | 値 |
|---|---|
| Name tag | `aircon-lab-vpc` |
| VPC ID | `vpc-0a755d81fff0930c5` |
| IPv4 CIDR | `10.0.0.0/16` |
| IPv6 | なし |
| Tenancy | `default` |
| State | `Available` |
| Region | `us-east-1` |
| Default VPC | いいえ |
| DNS 解決 | 有効 |
| DNS ホスト名 | 無効 |

### Subnet

| 種別 | Name tag | Subnet ID | CIDR | AZ | Auto-assign public IPv4 |
|---|---|---|---|---|---|
| Public Subnet A | `aircon-lab-public-subnet-a` | `subnet-0df3bf4f0bd417ec0` | `10.0.1.0/24` | `us-east-1a` | いいえ |
| Private Subnet A | `aircon-lab-private-subnet-a` | `subnet-091e2980729ce7167` | `10.0.11.0/24` | `us-east-1a` | いいえ |

### Internet Gateway

| 項目 | 値 |
|---|---|
| Name tag | `aircon-lab-igw` |
| Internet Gateway ID | `igw-08e1bc11abd08c2eb` |
| State | `Attached` |
| Attach先VPC | `vpc-0a755d81fff0930c5 / aircon-lab-vpc` |

### Route Table

| 種別 | Name tag | Route Table ID | 関連付け | ルート |
|---|---|---|---|---|
| Public Route Table | `aircon-lab-public-rt` | `rtb-010af3735bb435952` | `aircon-lab-public-subnet-a` | `10.0.0.0/16 -> local` / `0.0.0.0/0 -> igw-08e1bc11abd08c2eb` |
| Private Route Table | `aircon-lab-private-rt` | `rtb-049faa8fb0e286c65` | `aircon-lab-private-subnet-a` | `10.0.0.0/16 -> local` |

### Security Group

| 項目 | 値 |
|---|---|
| Name | `aircon-lab-sg` |
| Security Group ID | `sg-0542f89faf43abb10` |
| Description | `Security group for aircon lab VPC design` |
| VPC ID | `vpc-0a755d81fff0930c5` |
| Inbound rules | なし |
| Outbound rules | すべてのトラフィック / すべて / すべて / `0.0.0.0/0` |

---

## VPC設計

| 項目 | 値 |
|---|---|
| Name tag | `aircon-lab-vpc` |
| IPv4 CIDR | `10.0.0.0/16` |
| IPv6 | なし |
| Tenancy | `default` |
| リージョン | `us-east-1` |

### VPC設定の設計理由

| 設定項目 | 設定値 | 設計理由 |
|---|---|---|
| Name tag | `aircon-lab-vpc` | 空調管理システム関連の学習用VPCであることを分かりやすくするため |
| リージョン | `us-east-1` | 既存のAWS学習環境と合わせ、作業対象を明確にするため |
| IPv4 CIDR | `10.0.0.0/16` | Public Subnet、Private Subnet、将来の拡張用サブネットを分割しやすくするため |
| IPv6 CIDR | なし | 今回はIPv4によるVPC、サブネット、ルートテーブル設計の基礎理解に集中するため |
| Tenancy | `default` | 専有ハードウェアを必要としない学習用途のため |
| DNS解決 | 有効 | 将来EC2やVPC内サービスを利用する場合に、名前解決を利用できるようにするため |
| DNSホスト名 | 無効 | 今回はEC2を起動せず、パブリックDNS名も使用しないため |
| デフォルトVPC | いいえ | AWSが自動作成した既存VPCではなく、自分で設計した学習用VPCとして管理するため |

---

## サブネット設計

| 種別 | 名前 | CIDR | 用途 |
|---|---|---|---|
| Public Subnet A | `aircon-lab-public-subnet-a` | `10.0.1.0/24` | インターネット接続可能なサブネット設計の練習 |
| Private Subnet A | `aircon-lab-private-subnet-a` | `10.0.11.0/24` | インターネットから直接到達させないサブネット設計の練習 |

### サブネット設定の設計理由

`10.0.0.0/16` のVPC内から、Public用として `10.0.1.0/24`、Private用として `10.0.11.0/24` を切り出した。

Public系は `10.0.1.0/24`、Private系は `10.0.11.0/24` のように番号を分けることで、後から見ても用途が分かりやすい設計にした。

今回は初心者向けのVPC基礎ラボであるため、Availability Zoneはどちらも `us-east-1a` とし、構成を複雑にしすぎないようにした。

---

## ルートテーブル設計

| 種別 | 名前 | 関連付け | ルート |
|---|---|---|---|
| Public Route Table | `aircon-lab-public-rt` | Public Subnet A | `10.0.0.0/16 -> local` / `0.0.0.0/0 -> Internet Gateway` |
| Private Route Table | `aircon-lab-private-rt` | Private Subnet A | `10.0.0.0/16 -> local` |

### ルートテーブル設定の設計理由

VPC作成時にメインルートテーブルは自動作成されるが、今回はメインルートテーブルを直接編集せず、Public用とPrivate用のカスタムルートテーブルを作成した。

Public Route Tableには、VPC内通信の `10.0.0.0/16 -> local` に加えて、インターネット向け通信の `0.0.0.0/0 -> Internet Gateway` を設定した。

Private Route Tableには、`10.0.0.0/16 -> local` のみを設定し、インターネット向けルートは追加していない。

これにより、Public SubnetとPrivate Subnetの違いをルートテーブルで明確に分離した。

---

## インターネットゲートウェイ設計

| 項目 | 値 |
|---|---|
| Internet Gateway名 | `aircon-lab-igw` |
| 接続先VPC | `aircon-lab-vpc` |
| 用途 | Public Subnetをインターネットへ接続できる構成にするため |

### Internet Gateway設定の設計理由

Internet Gatewayは、VPCをインターネットへ接続するための出入口として作成した。

ただし、Internet GatewayをVPCにアタッチしただけでは、サブネットが自動的にインターネット接続可能になるわけではない。

Public Subnetをインターネット接続可能な構成にするため、Public Route Tableに `0.0.0.0/0 -> Internet Gateway` のルートを追加した。

---

## セキュリティグループ設計

| 項目 | 値 |
|---|---|
| Security Group名 | `aircon-lab-sg` |
| Description | `Security group for aircon lab VPC design` |
| VPC | `aircon-lab-vpc` |
| インバウンド | なし |
| アウトバウンド | デフォルト全許可を確認 |
| 用途 | 空調管理アプリ用サーバを想定した通信制御の設計練習 |

### Security Group設定の設計理由

今回はEC2を起動しないため、インバウンドルールは追加していない。

SSH、HTTP、HTTPSなどのインバウンド許可は設定せず、必要な通信だけを許可するという考え方を重視した。

アウトバウンドルールは、作成時のデフォルト設定として以下の1件を確認した。

```text
Outbound: すべてのトラフィック / すべて / すべて / 0.0.0.0/0
```

---

## 作業手順

### Phase 1：VPC作成

1. AWSマネジメントコンソールでVPCサービスを開く
2. リージョンが `us-east-1` であることを確認する
3. 「VPCを作成」をクリックする
4. 「VPCのみ」を選択する
5. Name tagに `aircon-lab-vpc` を入力する
6. IPv4 CIDRに `10.0.0.0/16` を入力する
7. IPv6はなし、Tenancyはdefaultで作成する

### Phase 2：サブネット作成

1. VPCサービスの「サブネット」を開く
2. `aircon-lab-vpc` を選択する
3. Public Subnet Aとして `aircon-lab-public-subnet-a` を作成する
4. CIDRは `10.0.1.0/24` とする
5. Private Subnet Aとして `aircon-lab-private-subnet-a` を作成する
6. CIDRは `10.0.11.0/24` とする

### Phase 3：Internet Gateway作成

1. VPCサービスの「インターネットゲートウェイ」を開く
2. `aircon-lab-igw` を作成する
3. 作成したInternet Gatewayを `aircon-lab-vpc` にアタッチする

### Phase 4：Route Table作成

1. Public Route Table `aircon-lab-public-rt` を作成する
2. `0.0.0.0/0 -> aircon-lab-igw` のルートを追加する
3. Public Subnet Aに関連付ける
4. Private Route Table `aircon-lab-private-rt` を作成する
5. インターネット向けルートは追加しない
6. Private Subnet Aに関連付ける

### Phase 5：Security Group作成

1. VPCサービスの「セキュリティグループ」を開く
2. `aircon-lab-sg` を作成する
3. VPCは `aircon-lab-vpc` を選択する
4. インバウンドルールは追加しない
5. アウトバウンドルールが全許可であることを確認する

---

## 確認結果

| 確認項目 | 確認内容 | 結果 |
|---|---|---|
| VPC | `aircon-lab-vpc` が作成されている | OK |
| VPC CIDR | `10.0.0.0/16` で作成されている | OK |
| Public Subnet | `aircon-lab-public-subnet-a` が作成されている | OK |
| Public Subnet CIDR | `10.0.1.0/24` で作成されている | OK |
| Private Subnet | `aircon-lab-private-subnet-a` が作成されている | OK |
| Private Subnet CIDR | `10.0.11.0/24` で作成されている | OK |
| Internet Gateway | `aircon-lab-igw` が作成されている | OK |
| IGW Attach | `aircon-lab-vpc` にアタッチされている | OK |
| Public Route Table | `aircon-lab-public-rt` が作成されている | OK |
| Public RT Route | `0.0.0.0/0` がInternet Gateway向き | OK |
| Public RT Association | Public Subnet Aに関連付け済み | OK |
| Private Route Table | `aircon-lab-private-rt` が作成されている | OK |
| Private RT Route | インターネット向けルートなし | OK |
| Private RT Association | Private Subnet Aに関連付け済み | OK |
| Security Group | `aircon-lab-sg` が作成されている | OK |
| SG Inbound | インバウンド許可なし | OK |
| SG Outbound | アウトバウンド全許可を確認 | OK |
| NAT Gateway | 作成していない | OK |
| EC2 | 作成していない | OK |
| Elastic IP | 作成していない | OK |
| RDS | 作成していない | OK |
| ALB | 作成していない | OK |

---

## 削除手順

ラボ完了後、不要リソースを残さないため、以下の順番で削除する。

### 1. Security Group削除

1. VPCサービスの「セキュリティグループ」を開く
2. `aircon-lab-sg` を選択する
3. 「アクション」から削除する

### 2. Route Table削除

1. VPCサービスの「ルートテーブル」を開く
2. `aircon-lab-public-rt` のサブネット関連付けを解除する
3. `aircon-lab-public-rt` を削除する
4. `aircon-lab-private-rt` のサブネット関連付けを解除する
5. `aircon-lab-private-rt` を削除する

削除できない場合は、サブネット関連付けなどの依存関係が残っていないか確認する。

### 3. Internet Gateway削除

1. VPCサービスの「インターネットゲートウェイ」を開く
2. `aircon-lab-igw` を選択する
3. `aircon-lab-vpc` からデタッチする
4. デタッチ後、Internet Gatewayを削除する

### 4. Subnet削除

1. VPCサービスの「サブネット」を開く
2. `aircon-lab-public-subnet-a` を削除する
3. `aircon-lab-private-subnet-a` を削除する

### 5. VPC削除

1. VPCサービスの「VPC」を開く
2. `aircon-lab-vpc` を選択する
3. 「アクション」からVPCを削除する

---

## 料金注意点

今回作成した範囲では、EC2、NAT Gateway、Elastic IP、RDS、ALBは使用していない。

VPC、サブネット、ルートテーブル、セキュリティグループ自体は通常大きな課金要素ではない。

NAT Gatewayは時間課金とデータ処理課金が発生するため、今回のラボでは作成しない。

EC2を利用する場合は、起動時間、EBS、パブリックIPv4アドレスに注意する必要がある。

Elastic IPは放置すると課金リスクがあるため、今回のラボでは作成しない。

RDS、ALBは今回使わない。

ラボ完了後、不要になったリソースは削除手順に従って削除する。

---

## トラブル時の確認ポイント

| 症状 | 確認ポイント |
|---|---|
| VPCが見つからない | 作業リージョンが `us-east-1` になっているか確認する |
| サブネット作成時にCIDRエラーが出る | VPCのCIDR範囲 `10.0.0.0/16` 内に収まっているか確認する |
| IGWをアタッチできない | 対象VPCが `aircon-lab-vpc` か確認する |
| ルート追加ができない | IGWがVPCにアタッチ済みか確認する |
| Public Subnetが期待通りにならない | Public Route Tableに `0.0.0.0/0 -> IGW` があるか確認する |
| Private SubnetがPublic化している | Private Route Tableに `0.0.0.0/0` が入っていないか確認する |
| 削除できない | 依存関係が残っていないか確認する |
| 既存環境と混ざる | Nameタグで `aircon-lab-` を確認する |

---

## 学んだこと

- VPCはAWS上の仮想ネットワークである
- CIDRを使ってネットワーク範囲を設計する
- サブネットはVPC内のIPアドレス範囲である
- Public SubnetとPrivate Subnetは、主にルートテーブルの違いで役割が分かれる
- Internet GatewayはVPCをインターネットへ接続するために使う
- Public Route Tableには `0.0.0.0/0 -> Internet Gateway` のルートを設定する
- Private Route Tableにはインターネット向けルートを設定しない
- Security Groupはリソース単位の通信制御に使う
- インバウンドルールは必要な通信だけ許可することが重要である
- 課金リスクのあるリソースを避けながら、ネットワーク設計の基礎を学習できる

---

## 面談での説明例

AWS上で小規模VPC構成を設計し、VPC、パブリックサブネット、プライベートサブネット、インターネットゲートウェイ、ルートテーブル、セキュリティグループを作成しました。

CIDR設計、サブネット分割、Public/Privateの役割、ルートテーブルの違いを意識し、パラメータシートと作業手順をMarkdownで整理しました。

Public Subnetには `0.0.0.0/0` をInternet Gatewayへ向けるルートを設定し、Private Subnetにはインターネット向けルートを追加しない構成にしました。

実務経験ではありませんが、AWS運用・構築補助で必要となる基本的なネットワーク設計とドキュメント作成を意識して学習しました。
