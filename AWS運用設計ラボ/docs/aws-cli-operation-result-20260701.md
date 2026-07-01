# AWS CLI読み取り系運用確認 実施結果

## 1. 文書情報

| 項目      | 内容                                       |
| ------- | ---------------------------------------- |
| 文書名     | AWS CLI読み取り系運用確認 実施結果                    |
| 実施日     | 2026年7月1日                                |
| 実施環境    | AWS CloudShell                           |
| 対象リージョン | us-east-1                                |
| 対象VPC   | aircon-lab-vpc                           |
| 目的      | AWS CLIを使用して、AWSリソースの構成確認を読み取り系コマンドで実施する |

---

## 2. 実施目的

本作業は、AWS運用設計ラボの一部として、AWS CLIを使用したAWSリソース確認作業を学習するために実施した。

作成・変更・削除系コマンドは実行せず、`describe`、`list`、`get` などの読み取り系コマンドを中心に使用した。

運用設計案件で必要になる、構成確認、証跡確認、バックアップ確認、通信経路確認の基礎を学習することを目的とした。

---

## 3. 安全方針

本作業では、以下の安全方針を守った。

* 作成系コマンドは実行しない
* 変更系コマンドは実行しない
* 削除系コマンドは実行しない
* 課金リソースは作成しない
* AWS CLIの読み取り系コマンドのみを実行する
* 実行結果に含まれるAWSアカウントID、ARN、VPC ID、Subnet ID、Security Group IDなどはGitHub公開時にマスクする

---

## 4. AWS CLI環境確認

### 4.1 AWS CLIバージョン確認

#### 実施コマンド

```bash
aws --version
```

#### 確認結果

AWS CloudShell上でAWS CLI v2が使用できることを確認した。

#### 確認できたこと

CloudShellにはAWS CLIがあらかじめインストールされており、追加インストールなしでAWS CLIコマンドを実行できることを確認した。

---

### 4.2 awsコマンド配置確認

#### 実施コマンド

```bash
which aws
```

#### 確認結果

`/usr/local/bin/aws` にAWS CLIコマンドが存在することを確認した。

---

### 4.3 AWS CLI設定確認

#### 実施コマンド

```bash
aws configure list
```

#### 確認結果

CloudShell上でAWS CLIの認証情報とリージョン設定が確認できた。

対象リージョンは `us-east-1` であることを確認した。

---

### 4.4 AWS認証情報確認

#### 実施コマンド

```bash
aws sts get-caller-identity
```

#### 確認結果

AWS CLIから現在の認証情報を取得できることを確認した。

#### 注意事項

実行結果にはAWSアカウントIDとARNが含まれるため、GitHubにはそのまま掲載しない。

また、確認時点ではARNがrootユーザーを示していたため、今後はIAMユーザー、IAMロール、IAM Identity Centerなどを利用した作業方法も検討する。

---

## 5. VPC確認

### 5.1 VPC一覧確認

#### 実施コマンド

```bash
aws ec2 describe-vpcs --region us-east-1
```

#### 確認結果

対象リージョン `us-east-1` に、以下のVPCが存在することを確認した。

| 種別          | CIDR          | 状態        |
| ----------- | ------------- | --------- |
| Default VPC | 172.31.0.0/16 | available |
| 学習用VPC      | 10.0.0.0/16   | available |

#### 確認できたこと

学習用VPC `aircon-lab-vpc` が存在し、CIDRが `10.0.0.0/16` であることを確認した。

---

## 6. Subnet確認

### 6.1 Subnet一覧確認

#### 実施コマンド

```bash
VPC_ID="vpc-xxxxxxxx"

aws ec2 describe-subnets \
  --region us-east-1 \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'Subnets[*].{Name:Tags[?Key==`Name`]|[0].Value,SubnetId:SubnetId,CidrBlock:CidrBlock,AZ:AvailabilityZone,PublicIp:MapPublicIpOnLaunch}' \
  --output table
```

#### 確認結果

学習用VPC内に、以下のSubnetが存在することを確認した。

| Subnet名                     | CIDR         | AZ         | Public IPv4自動割当 |
| --------------------------- | ------------ | ---------- | --------------- |
| aircon-lab-public-subnet-a  | 10.0.1.0/24  | us-east-1a | False           |
| aircon-lab-private-subnet-a | 10.0.11.0/24 | us-east-1a | False           |

#### 確認できたこと

Public SubnetとPrivate Subnetがそれぞれ作成されていることを確認した。

`MapPublicIpOnLaunch` は両方とも `False` であり、EC2起動時にパブリックIPv4を自動付与しない設定であることを確認した。

ただし、Public SubnetかPrivate Subnetかはこの値だけでは判断せず、Route Tableの内容も確認する必要がある。

---

## 7. Route Table確認

### 7.1 Route Table関連付け確認

#### 実施コマンド

```bash
aws ec2 describe-route-tables \
  --region us-east-1 \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'RouteTables[*].{Name:Tags[?Key==`Name`]|[0].Value,RouteTableId:RouteTableId,Main:Associations[?Main==`true`]|[0].Main,AssociatedSubnets:Associations[?SubnetId!=`null`].SubnetId}' \
  --output table
```

#### 確認結果

学習用VPCには以下のRoute Tableが存在することを確認した。

| Route Table           | 関連付け           |
| --------------------- | -------------- |
| aircon-lab-public-rt  | Public Subnet  |
| aircon-lab-private-rt | Private Subnet |
| Main Route Table      | メインルートテーブル     |

---

### 7.2 Route Tableルート確認

#### 実施コマンド

```bash
aws ec2 describe-route-tables \
  --region us-east-1 \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'RouteTables[*].{Name:Tags[?Key==`Name`]|[0].Value,RouteTableId:RouteTableId,Routes:Routes}' \
  --output json
```

#### 確認結果

| 種別                  | 主なルート                                              |
| ------------------- | -------------------------------------------------- |
| Public Route Table  | 10.0.0.0/16 → local / 0.0.0.0/0 → Internet Gateway |
| Private Route Table | 10.0.0.0/16 → local                                |
| Main Route Table    | 10.0.0.0/16 → local                                |

#### 確認できたこと

Public Subnetに関連付いたRoute Tableには、`0.0.0.0/0` がInternet Gatewayへ向くルートが存在していた。

Private Subnetに関連付いたRoute Tableには、VPC内部向けの `local` ルートのみが存在しており、インターネット向けのデフォルトルートは存在しなかった。

このため、Public SubnetとPrivate Subnetが設計どおりに分離されていることを確認できた。

---

## 8. Internet Gateway確認

### 8.1 Internet Gateway確認

#### 実施コマンド

```bash
aws ec2 describe-internet-gateways \
  --region us-east-1 \
  --filters "Name=attachment.vpc-id,Values=${VPC_ID}" \
  --query 'InternetGateways[*].{Name:Tags[?Key==`Name`]|[0].Value,InternetGatewayId:InternetGatewayId,State:Attachments[0].State,VpcId:Attachments[0].VpcId}' \
  --output table
```

#### 確認結果

学習用VPCに、Internet Gateway `aircon-lab-igw` がアタッチされていることを確認した。

| 項目                | 確認内容           |
| ----------------- | -------------- |
| Internet Gateway名 | aircon-lab-igw |
| 状態                | available      |
| アタッチ先             | aircon-lab-vpc |

#### 確認できたこと

Public Route Tableの `0.0.0.0/0` が向いているInternet Gatewayが、学習用VPCにアタッチされていることを確認した。

---

## 9. Security Group確認

### 9.1 Security Group一覧確認

#### 実施コマンド

```bash
aws ec2 describe-security-groups \
  --region us-east-1 \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'SecurityGroups[*].{GroupName:GroupName,GroupId:GroupId,Description:Description,VpcId:VpcId}' \
  --output table
```

#### 確認結果

学習用VPCには、以下のSecurity Groupが存在することを確認した。

| Security Group名 | 用途                         |
| --------------- | -------------------------- |
| default         | VPC作成時のデフォルトSecurity Group |
| aircon-lab-sg   | 学習用Security Group          |

---

### 9.2 Security Groupルール確認

#### 実施コマンド

```bash
aws ec2 describe-security-groups \
  --region us-east-1 \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'SecurityGroups[*].{GroupName:GroupName,GroupId:GroupId,Ingress:IpPermissions,Egress:IpPermissionsEgress}' \
  --output json
```

#### 確認結果

| Security Group名 | Inbound                   | Outbound |
| --------------- | ------------------------- | -------- |
| default         | 同一Security Group内からの通信を許可 | すべて許可    |
| aircon-lab-sg   | 許可ルールなし                   | すべて許可    |

#### 確認できたこと

`aircon-lab-sg` にはInboundルールが存在しないため、外部からSSH、HTTP、HTTPSなどで接続できる状態ではないことを確認した。

Outboundは `0.0.0.0/0` が許可されていた。

ただし、実際にインターネットへ通信できるかどうかは、Security Groupだけでなく、Route Table、Internet Gateway、NAT Gateway、パブリックIPの有無も合わせて確認する必要がある。

---

## 10. Network ACL確認

### 10.1 Network ACL確認

#### 実施コマンド

```bash
aws ec2 describe-network-acls \
  --region us-east-1 \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'NetworkAcls[*].{NetworkAclId:NetworkAclId,IsDefault:IsDefault,Associations:Associations[*].SubnetId,Entries:Entries}' \
  --output json
```

#### 確認結果

学習用VPCでは、デフォルトNetwork ACLが使用されていることを確認した。

| 項目            | 確認内容                           |
| ------------- | ------------------------------ |
| Network ACL種別 | デフォルトNetwork ACL               |
| 関連付け          | Public Subnet / Private Subnet |
| Inbound       | すべて許可                          |
| Outbound      | すべて許可                          |
| 最終ルール         | 32767番でdeny                    |

#### 確認できたこと

今回のNetwork ACLでは、Inbound、Outboundともに `0.0.0.0/0` に対してすべてのプロトコルが許可されていた。

そのため、サブネット単位の通信制御は厳しく制限しておらず、通信制御は主にSecurity GroupとRoute Tableで行う構成であることを確認した。

Security Groupはリソース単位、Network ACLはサブネット単位の通信制御である。

また、Security Groupはステートフル、Network ACLはステートレスであるため、実務では両方の違いを理解して確認する必要がある。

---

## 11. EBS確認

### 11.1 EBS Volume確認

#### 実施コマンド

```bash
aws ec2 describe-volumes \
  --region us-east-1 \
  --query 'Volumes[*].{VolumeId:VolumeId,Size:Size,VolumeType:VolumeType,State:State,AZ:AvailabilityZone,Encrypted:Encrypted,AttachedInstance:Attachments[0].InstanceId}' \
  --output table
```

#### 確認結果

対象リージョン `us-east-1` では、EBS Volumeは存在しなかった。

#### 確認できたこと

未使用のEBS Volumeが残っていないことを確認できた。

EBS VolumeはEC2削除後に残る場合があり、保持しているだけで課金対象になるため、運用確認では重要な確認項目である。

---

## 12. EBS Snapshot確認

### 12.1 EBS Snapshot確認

#### 実施コマンド

```bash
aws ec2 describe-snapshots \
  --owner-ids self \
  --region us-east-1 \
  --query 'Snapshots[*].{SnapshotId:SnapshotId,VolumeId:VolumeId,StartTime:StartTime,State:State,Progress:Progress,Description:Description}' \
  --output table
```

#### 確認結果

対象リージョン `us-east-1` では、自分のAWSアカウントが所有するEBS Snapshotは存在しなかった。

#### 確認できたこと

不要なEBS Snapshotが残っていないことを確認できた。

Snapshotはバックアップ用途で利用され、保持しているだけで課金対象になるため、運用確認では取得状況や不要Snapshotの有無を確認することが重要である。

---

## 13. RDS/Aurora Snapshot確認

### 13.1 DBクラスターSnapshot確認

#### 実施コマンド

```bash
aws rds describe-db-cluster-snapshots \
  --region us-east-1 \
  --query 'DBClusterSnapshots[*].{SnapshotId:DBClusterSnapshotIdentifier,DBCluster:DBClusterIdentifier,SnapshotCreateTime:SnapshotCreateTime,Status:Status,Engine:Engine,SnapshotType:SnapshotType}' \
  --output table
```

#### 確認結果

対象リージョン `us-east-1` では、Aurora/RDS DBクラスターSnapshotは存在しなかった。

#### 確認できたこと

不要なAurora/RDS DBクラスターSnapshotが残っていないことを確認できた。

Aurora/RDS運用では、バックアップ保持期間、Snapshot取得状況、Snapshot状態、不要Snapshotの有無を確認することが重要である。

---

## 14. ALB/NLB確認

### 14.1 Load Balancer確認

#### 実施コマンド

```bash
aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --query 'LoadBalancers[*].{Name:LoadBalancerName,Type:Type,Scheme:Scheme,State:State.Code,VpcId:VpcId,DNSName:DNSName}' \
  --output table
```

#### 確認結果

対象リージョン `us-east-1` では、ALB/NLBは存在しなかった。

#### 確認できたこと

学習環境に不要なLoad Balancerが存在しないことを確認できた。

Load Balancerは稼働していると課金対象になるため、学習環境では不要なリソースが残っていないか確認することが重要である。

---

## 15. Target Group確認

### 15.1 Target Group確認

#### 実施コマンド

```bash
aws elbv2 describe-target-groups \
  --region us-east-1 \
  --query 'TargetGroups[*].{Name:TargetGroupName,Protocol:Protocol,Port:Port,VpcId:VpcId,HealthCheckProtocol:HealthCheckProtocol,HealthCheckPath:HealthCheckPath,TargetGroupArn:TargetGroupArn}' \
  --output table
```

#### 確認結果

対象リージョン `us-east-1` では、Target Groupは存在しなかった。

#### 確認できたこと

学習環境に不要なTarget Groupが存在しないことを確認できた。

ALB運用では、Load Balancer、Listener、Target Group、Target Healthの関係を確認する必要がある。

今回はALB/NLBおよびTarget Groupが存在しないことを確認したため、Target Health確認は対象外とした。

---

## 16. 今回確認できたこと

今回のAWS CLI読み取り系運用確認では、以下を確認できた。

* AWS CloudShell上でAWS CLIを使用できること
* AWS CLIの認証情報とリージョン設定を確認できること
* 学習用VPCが存在すること
* Public SubnetとPrivate Subnetが存在すること
* Public SubnetはInternet Gateway向けのデフォルトルートを持つこと
* Private Subnetはインターネット向けのデフォルトルートを持たないこと
* Internet Gatewayが学習用VPCにアタッチされていること
* Security GroupのInbound/Outboundルールを確認できること
* Network ACLの関連付けとルールを確認できること
* EBS Volumeが存在しないこと
* EBS Snapshotが存在しないこと
* Aurora/RDS DBクラスターSnapshotが存在しないこと
* ALB/NLBが存在しないこと
* Target Groupが存在しないこと

---

## 17. 運用観点で学んだこと

AWS CLIを使用することで、AWSマネジメントコンソール上の情報をコマンドで確認できることを学習した。

運用確認では、単一の情報だけで判断せず、複数の設定を組み合わせて確認する必要がある。

例として、Public SubnetかどうかはSubnet名だけで判断せず、Route Tableで `0.0.0.0/0` がInternet Gatewayへ向いているかを確認する必要がある。

また、Security GroupでOutboundが許可されていても、Route Tableに外向き経路がなければインターネットへ通信できない。

このように、VPC、Subnet、Route Table、Internet Gateway、Security Group、Network ACLを組み合わせて確認することが重要である。

---

## 18. 面談で説明するポイント

AWS CLIを使用して、CloudShell上からAWSリソースの構成確認を行いました。

作成・変更・削除系コマンドは実行せず、`describe` 系を中心とした読み取り系コマンドのみを使用しています。

VPC、Subnet、Route Table、Internet Gateway、Security Group、Network ACLを確認し、Public SubnetとPrivate Subnetの通信経路の違いをRoute Tableから確認しました。

また、EBS Volume、EBS Snapshot、Aurora/RDS Snapshot、ALB/NLB、Target Groupについても存在有無を確認し、不要な課金リソースが残っていないことを確認しました。

実務経験としてAWS CLIを多用していたわけではありませんが、金融系システム運用監視で経験した確認作業、障害一次対応、証跡確認、手順書整備の考え方をもとに、AWS CLIによる構成確認を個人学習として実施しました。

---

## 19. 今後の改善予定

今後は、以下の内容を追加する予定である。

* AWS CLI確認コマンドをまとめたBashスクリプト作成
* 実行結果ログの保存
* マスク済み実行結果サンプルの作成
* EBSバックアップ確認手順書の作成
* Auroraバックアップ確認手順書の作成
* ALB Target Health確認手順書の作成
* JP1/AJSでのジョブ実行を意識した終了コード設計
* PowerShell版のWindowsサーバ確認スクリプト作成
