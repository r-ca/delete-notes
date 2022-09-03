# Misskey-Auto-NoteDelete
## 概要
Misskeyでノートを一括削除するシェルスクリプトです

## Features
- 対話モードで実行することができます
- crontabなどで定期実行するためのスクリプトモードがあります
- 実行時点から指定時間以内のノートを保護することができます

## 使い方
1. **任意のディレクトリにcloneする**  
`git clone https://github.com/melt-romcat/delete-notes/`

2. **実行権限を付与する**  
`chmod +x ./delete-note.sh`

3. **実行したいMisskeyアカウントのAPIキーを取得する**  
   現状必要な権限は以下
   * View your account infomation
   * Compose or delete notes  
  
4. **(スクリプトモードを使う場合)config.txtの作成**  
   同梱のconfig_template.txtを参考に必要な情報を記入します
   * address: インスタンスのアドレス
     * misskey.io、miss.nem.oneなど
   * userId: インスタンス上でのユーザーID
     * settings/account-infoから確認できます
   * token: 手順3で取得したアカウントのアクセストークン
   * limit: 全ノートを取得する処理の際、いちどのリクエストで取得するノートの数
     * 1~100で入力してください
   * protectionPeriod: ノートの保護期間
     * 秒で指定してください (1hr = 3600)  

5. **実行**  
    スクリプトモードで実行する場合は`-q`オプションを指定してください

## 既知の不具合
* config.txtのパース処理が頭悪いのでコメントアウト,空白を処理できない
* レートリミットに引っかかった際の処理が存在しないため、リミットにかかったあともリクエストを続けてしまう  (cronなどで定期実行する場合、次回実行時に再取得されて削除されるため動作しないわけではない)