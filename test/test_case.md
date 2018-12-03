# PuzzleBID游戏合约测试用例

---

### 测试数据
超级管理员地址：`0xca35b7d915458ef540ade6068dfe2f44e8fa733c`
管理员地址：`0x14723a09acff6d2a60dcdf7aa4aff308fddc160c`

---

### 一、管理员与艺术家
进入remix，将以下合约粘贴并编译：
1、SafeMath.sol
2、Datasets.sol
3、Team.sol
4、TeamInterface.sol
5、Artist.sol
分别部署第3、5个合约

#### 添加开发者
```
"0x14723a09acff6d2a60dcdf7aa4aff308fddc160c",false,true,"0x6f7579616e6700000000000000000000" //ouyang的hex
```

#### 是否为管理员
```
isAdmin("0x14723a09acff6d2a60dcdf7aa4aff308fddc160c")
false
```

#### 是否为开发者
```
isDev("0x14723a09acff6d2a60dcdf7aa4aff308fddc160c")
true
```

#### 添加艺术家
```
add("0xe10adc3949ba59abbe56e057f20f883e","0x14723a09acff6d2a60dcdf7aa4aff308fddc160c") //艺术家ID，钱包地址
```

#### 查询艺术家ID是否存在
```
hasArtist("0xe10adc3949ba59abbe56e057f20f883e")
```

#### 查询艺术家的钱包地址
```
getAddress("0xe10adc3949ba59abbe56e057f20f883e")
```

#### 更新艺术家钱包地址
```
updateAddress("0xe10adc3949ba59abbe56e057f20f883e", "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db")
```

---

### 二、作品碎片
接第一章导入的合约，将以下合约粘贴并编译：
1、Works.sol
2、WorksInterface.sol
部署
```
Deploy("0x692a70d2e424a56d2c6c27aa97d1a86395877b3a","0x0dcd2f752394c41875e259e00bb44fd505297caf")
```


### 


### 三、平台
接第二章导入的合约，将以下合约粘贴并编译：
1、Works.sol
2、WorksInterface.sol


### 四、玩家
接第二章导入的合约，将以下合约粘贴并编译：
1、Works.sol
2、WorksInterface.sol


### 五、游戏






管理员地址：
```
0xd134dd2a3c16fb12885cd6fdc8a03d4bbe5d7031
6D7BA1846D5BEE5138418701138998CDC7D8B4D3386D432D2351449541334FE0
```

管理员团队合约：0xb516090e1fc6bb8d5316901382d0549ff120577d
艺术家合约：0xbcdbdbf97503677947dc766f71f69170a0f58211
```
"0xbcdbdbf97503677947dc766f71f69170a0f58211",false,true,"0x61727469737400000000000000000000" //artist
```
作品碎片合约：0x8e918a992ab7aeec0b2d9e9eef96667df5204454
```
"0x8e918a992ab7aeec0b2d9e9eef96667df5204454",false,true,"0x776f726b730000000000000000000000" //works
```
基金会地址：0xfaCd69A6df3265dDF3F60A868D3B0086feb1597E

平台合约：0x8b20a6fe24bcc8766f8648eecc8e1cc30f20f154
```
"0x8b20a6fe24bcc8766f8648eecc8e1cc30f20f154",false,true,"0x706c6174666f726d0000000000000000" //platform
```
玩家合约：0x4349d1c01b2aa04b2ca187fa736ad3b05af7ef64
```
"0x4349d1c01b2aa04b2ca187fa736ad3b05af7ef64",false,true,"0x706c6179657200000000000000000000" //player
```
主合约：0x990840ed04984f9eba9cfc3cd0be1139da1d0727
```
"0x990840ed04984f9eba9cfc3cd0be1139da1d0727",false,true,"0x70757a7a6c6562696400000000000000" //puzzlebid
```

部署主合约：
```
"0xb516090e1fc6bb8d5316901382d0549ff120577d","0x8b20a6fe24bcc8766f8648eecc8e1cc30f20f154","0xbcdbdbf97503677947dc766f71f69170a0f58211","0x8e918a992ab7aeec0b2d9e9eef96667df5204454","0x4349d1c01b2aa04b2ca187fa736ad3b05af7ef64"
```

