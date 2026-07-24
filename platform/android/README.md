# Android ランチャーアイコン

このリポジトリは現在 **iOS ネイティブ(SwiftUI)専用**で、Android/クロスプラットフォームの
ビルド対象はまだありません。ここには、将来 Android 版(素の Android プロジェクト、
または Flutter / React Native / Kotlin Multiplatform などのラッパー)を用意したときに
そのまま使えるよう、ランチャーアイコン一式を用意してあります。

## 内容

- `res/mipmap-anydpi-v26/ic_launcher.xml` … アダプティブアイコン定義(API 26+)
- `res/mipmap-anydpi-v26/ic_launcher_round.xml` … 丸型アダプティブ定義
- `res/mipmap-<density>/ic_launcher_foreground.png` … アダプティブ前景(錨)
- `res/mipmap-<density>/ic_launcher_background.png` … アダプティブ背景(深海グラデ)
- `res/mipmap-<density>/ic_launcher.png` / `ic_launcher_round.png` … 旧端末用の完成形
- `ic_launcher-web-512.png` … Google Play ストア掲載用 512px

密度: mdpi / hdpi / xhdpi / xxhdpi / xxxhdpi

## 使い方

1. Android プロジェクトの `app/src/main/res/` に、この `res/` の中身をマージする。
2. `AndroidManifest.xml` の `<application>` に以下を設定する:

   ```xml
   android:icon="@mipmap/ic_launcher"
   android:roundIcon="@mipmap/ic_launcher_round"
   ```

3. リビルドすればランチャーにアイコンが反映される。

## 再生成

アイコンは `scripts/make_app_icon.swift` で CoreGraphics により生成しています(外部ツール不要)。
配色や錨の形を変えたい場合はスクリプトを編集し、再実行して差し替えてください。

    swift scripts/make_app_icon.swift <出力先ディレクトリ>
