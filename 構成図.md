# AWS空調管理・異常監視システム

設備管理業務を題材に、AWSサーバーレスアーキテクチャで構築した
空調機の監視・管理システムです。
React画面から疑似データを入力し、異常検知・アラート登録・
定期点検バッチまでを一貫して実装しています。


React (S3 + CloudFront)
API Gateway HTTP API
Lambda（CRUD処理）
DynamoDB
EventBridge Scheduler
Lambda（定期点検）
Lambda（異常検知時）
SQS
Lambda（アラート登録）
CloudWatch Logs

## 機能一覧
- 空調機一覧表示
- 空調機登録
- 温度・湿度データ登録（疑似データ入力）
- 異常アラート一覧表示
- 定期点検バッチ（EventBridge Schedulerによる自動実行）
- CloudWatch Logsによるログ確認

## 使用サービス
S3
CloudFront
Cognito
API Gateway HTTP API
Lambda
DynamoDB
EventBridge Scheduler
SQS
CloudWatch Logs
