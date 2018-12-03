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


### 三、平台
接第二章导入的合约，将以下合约粘贴并编译：
1、Works.sol
2、WorksInterface.sol


### 四、玩家
接第二章导入的合约，将以下合约粘贴并编译：
1、Works.sol
2、WorksInterface.sol


### 五、游戏








