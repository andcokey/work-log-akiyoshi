# work-log-akiyoshi

勤務時間ダッシュボード | Slack の日報から出退勤時刻を自動抽出

## 機能

✅ **期間指定検索** — HTML 上で日付を選択  
✅ **自動勤務時間計算** — タスク時刻から自動計算  
✅ **残業管理** — 9時間超の残業をカウント  
✅ **残業予算追跡** — 月45時間枠の消費状況を表示  
✅ **ワンクリック同期** — 「Slack データ更新」ボタンで最新情報を取得  

## セットアップ

詳細は [セットアップガイド](./SETUP.md) を参照

### クイックスタート

1. **Slack Token を取得**
   - https://api.slack.com/apps → Create New App → OAuth Token コピー

2. **GitHub Secrets に登録**
   - Settings → Secrets → `SLACK_TOKEN` を追加

3. **GitHub Pages を有効化**
   - Settings → Pages → Branch: `main` / `root`

4. **ダッシュボードにアクセス**
   - `https://YOUR_USERNAME.github.io/work-log-akiyoshi/`

## 使い方

### ボタンで更新

1. 「🔄 Slack データ更新」をクリック
2. GitHub Personal Access Token を入力
3. 2～3 秒待機（GitHub Actions が実行）
4. ページ自動リロード

### 検索・表示

1. 開始日・終了日を選択
2. 「表示」をクリック
3. 勤務時間 / 残業時間 / 残業可能時間を確認

## ファイル構成

```
work-log-akiyoshi/
├── index.html                          ダッシュボード UI
├── worklog.json                        Slack から抽出したデータ
├── .github/workflows/
│   └── sync-worklog.yml                GitHub Actions ワークフロー
├── scripts/
│   └── get-slack-reports.ps1           Slack 日報抽出スクリプト
└── README.md                           このファイル
```

## 仕組み

```
┌─────────────────────────────────────────┐
│ ダッシュボード (GitHub Pages)           │
│ → 「Slack データ更新」ボタン             │
└─────────────────────────────────────────┘
            ↓ GitHub API
┌─────────────────────────────────────────┐
│ GitHub Actions                          │
│ → PowerShell スクリプト実行             │
│ → Slack API で日報を取得               │
│ → JSON 生成＆コミット                   │
└─────────────────────────────────────────┘
            ↓ Fetch
┌─────────────────────────────────────────┐
│ worklog.json                            │
│ → ダッシュボードで表示                   │
└─────────────────────────────────────────┘
```

## トラブルシューティング

### Actions が失敗する

- **リポジトリ → Actions タブ** でエラーログを確認
- `SLACK_TOKEN` が正しく設定されているか確認
- Slack App に `conversations:history` 権限があるか確認

### JSON が更新されない

- **Actions ログで成功を確認**
- ブラウザをハードリロード（Ctrl+Shift+R）
- `worklog.json` ファイルが更新されているか確認

### Token 入力画面が出ない

- **ブラウザコンソール（F12）でエラーを確認**
- GitHub Token の有効期限を確認
- Token に `repo` スコープがあるか確認

## セキュリティ

- **Slack Token** は GitHub Secrets に保管（ログに表示されない）
- **GitHub Token** はブラウザで入力（1回限り）
- 定期的に Token を更新することを推奨

## ライセンス

MIT

## 参考

- [GitHub Actions ドキュメント](https://docs.github.com/ja/actions)
- [GitHub Pages ドキュメント](https://docs.github.com/ja/pages)
- [Slack API ドキュメント](https://api.slack.com/)
