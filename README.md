# HipParticle
![image](https://user-images.githubusercontent.com/15693656/96622528-060b3100-1345-11eb-80c4-7ede0fd26057.png)

## Description
ヒッパルコス星表に記録された星の位置、色、明るさを立体的に描画するシェーダーです。おまけとして立体的な星座線、星の名称パネルが含まれています。

## Usage
1. [Releases](https://github.com/Kuwamai/HipParticle/releases)からUnitypackageをダウンロードします
1. Unity projectにUnitypackageをimportします
1. [HipParticle/Prefabs](https://github.com/Kuwamai/HipParticle/tree/main/Assets/HipParticle/Prefabs)内のHipParticle.prefabをHierarchieに配置します
1. 星の大きさはInspectorで変更できます
    * Mag_param
        * 星の大きさ
    * Mag_min
        * 大きさの最小値
1. StarName.prefabは星の名前が書かれたプレートです
1. ConstellationLine.prefabは星座線です

## References & Includings
* HipParticle.shaderはPhi16_さんが書いてくださった[pointcloud.shader](https://twitter.com/phi16_/status/1041256230545612800)を一部改変して作成しました

* 表示フォントにM PLUS Rounded 1c (https://fonts.google.com/specimen/M+PLUS+Rounded+1c) を使用しています
   * Licensed under SIL Open Font License 1.1 (http://scripts.sil.org/OFL)  
   * Copyright 2016 The Rounded M+ Project Authors.

## Collaborators
本パッケージは以下のメンバーの協力の元制作しました  
* [天野ステラ](https://twitter.com/stellagear): 星の名称パネル作成

## License
This repository is licensed under the MIT license, see [LICENSE](./LICENSE).
