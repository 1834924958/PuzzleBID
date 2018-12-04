# PuzzleBID游戏合约测试用例

---

### 测试数据


**管理员团队**

超级管理员地址：0xD134dd2a3c16Fb12885cd6FDc8a03D4bbe5d7031`

name：0x4163636f756e74310000000000000000（对应Account1）


**艺术家**

艺术家ID：`0xe28a246d965078e969553e85d38e4b28`

钱包地址：`0xC463a4BF8A57725Ee9Ff23E096f6C395BdB07b73`
`1FBAF18580190E046CD87040E78F23B1DCE5DA342A446BABACBBF4FC6232D33F`


**作品**

作品ID：`0x0701e6555cbb36e24c3c1f32cbf89ecf`

艺术家ID：`0xe28a246d965078e969553e85d38e4b28`

碎片数：`6`

开始时间戳：`1543894200`

游戏规则：
玩家首发最大购买数2个，冻结时间2分钟，作品保护时间5分钟，涨价110%，10分钟后降价，降价95%，
[艺术家80%, 平台2%, 奖池18%]，[艺术家10%（溢价部分）, 平台2%（总价）, 奖池65%（溢价部分）]，[游戏完成者80%, 首发购买者10%, 后续其他购买者10%]


**平台**
基金会钱包地址：`0xe95651358BeE7106a206Bb9B61D0BC406c58707a`
`0DF638C6D36869F5F176F8E0D78DBC30B86EC1AED77D5E2EEBBB1E09202C9D9D`


**玩家**

UnionID：`0x38363135323136363839353431000000` （对应8615216689541）
钱包地址：`0xfaCd69A6df3265dDF3F60A868D3B0086feb1597E`
`C0CE0E3587629BFC3E34A4745ADB2AF793DA58FEF5ED0B7327EA6FE8FC037970`

UnionID：`0x38363133373731373339313039000000`（对应8613771739109）


---

### 一、部署合约

进入remix，将以下合约粘贴并编译：
https://github.com/vsiryxm/PuzzleBID/blob/master/test/PuzzleBID.no.sol（无注释版，方便断点调试）

部署顺序：Team > Artist > Works > Platform > Player > PuzzleBID

#### 1.1 部署管理员团队合约

选择Team合约，开始部署：
```
Deploy("0xD134dd2a3c16Fb12885cd6FDc8a03D4bbe5d7031") //传入超级管理员钱包地址
//合约地址：0xb516090e1fc6bb8d5316901382d0549ff120577d
```
#### 1.2 部署艺术家合约

选择Artist合约，开始部署：
```
Deploy("0xb516090e1fc6bb8d5316901382d0549ff120577d") //传入管理员团队合约地址
//合约地址：0xbcdbdbf97503677947dc766f71f69170a0f58211
```

#### 1.3 部署作品碎片合约

选择Works合约，开始部署：
```
Deploy("0xb516090e1fc6bb8d5316901382d0549ff120577d","0xbcdbdbf97503677947dc766f71f69170a0f58211") //传入管理员团队、艺术家合约地址
//合约地址：0x8e918a992ab7aeec0b2d9e9eef96667df5204454
```

#### 1.4 部署平台合约

选择Platform合约，开始部署：
```
Deploy("0xe95651358BeE7106a206Bb9B61D0BC406c58707a","0xb516090e1fc6bb8d5316901382d0549ff120577d") //传入基金会钱包地址、管理员团队合约地址
//合约地址：0x8b20a6fe24bcc8766f8648eecc8e1cc30f20f154
```

#### 1.5 部署玩家合约

选择Player合约，开始部署：
```
Deploy("0xb516090e1fc6bb8d5316901382d0549ff120577d", "0x8e918a992ab7aeec0b2d9e9eef96667df5204454") //传入管理员团队、作品碎片合约地址
//合约地址：0x4349d1c01b2aa04b2ca187fa736ad3b05af7ef64
```

#### 1.6 部署游戏主合约

选择PuzzleBID合约，开始部署：
```
Deploy("0xb516090e1fc6bb8d5316901382d0549ff120577d", "0x8b20a6fe24bcc8766f8648eecc8e1cc30f20f154","0xbcdbdbf97503677947dc766f71f69170a0f58211","0x8e918a992ab7aeec0b2d9e9eef96667df5204454","0x4349d1c01b2aa04b2ca187fa736ad3b05af7ef64") //传入管理员团队、平台、艺术家、作品碎片、玩家合约地址
//合约地址：0x990840ed04984f9eba9cfc3cd0be1139da1d0727
```
---

### 二、开通开发者权限

#### 2.1 超级管理员

为了方便，将超级管理员Account1设成3个身份，在接下来的测试当中，都将以Account1作为主账号进行合约方法的单元测试：

```
addAdmin("0xD134dd2a3c16Fb12885cd6FDc8a03D4bbe5d7031",true,true,"0x4163636f756e74310000000000000000") 
//Account1的hex
```

#### 2.2 开发者

将以上部署好的合约地址，除管理员团队合约地址外，都加入到开发者列表中，以便合约之间具有更新权限，找到Team合约：

```
addAdmin("0xbcdbdbf97503677947dc766f71f69170a0f58211",false,true,"0x61727469737400000000000000000000") //artist
addAdmin("0x8e918a992ab7aeec0b2d9e9eef96667df5204454",false,true,"0x776f726b730000000000000000000000") //works
addAdmin("0x8b20a6fe24bcc8766f8648eecc8e1cc30f20f154",false,true,"0x706c6174666f726d0000000000000000") //platform
addAdmin("0x4349d1c01b2aa04b2ca187fa736ad3b05af7ef64",false,true,"0x706c6179657200000000000000000000") //player
addAdmin("0x990840ed04984f9eba9cfc3cd0be1139da1d0727",false,true,"0x70757a7a6c6562696400000000000000") //puzzlebid
```

---

### 三、管理员合约测试

#### 3.1 添加开发者

```
addAdmin("0xD134dd2a3c16Fb12885cd6FDc8a03D4bbe5d7777",true,true,"0x79616e67786d00000000000000000000")
```

#### 3.2 是否为管理员
```
isAdmin("0xD134dd2a3c16Fb12885cd6FDc8a03D4bbe5d7777") //true
```

#### 3.3 是否为开发者
```
isDev("0xD134dd2a3c16Fb12885cd6FDc8a03D4bbe5d7777") //true
```

#### 3.4 删除管理员或开发者
```
removeAdmin("0xD134dd2a3c16Fb12885cd6FDc8a03D4bbe5d7777")
```
再次查询是否存在该管理员

---

### 四、艺术家合约测试

#### 4.1 添加艺术家
```
addAdmin("0xe28a246d965078e969553e85d38e4b28","0xC463a4BF8A57725Ee9Ff23E096f6C395BdB00000") //艺术家ID，钱包地址
```

#### 4.2 查询艺术家ID是否存在
```
hasArtist("0xe28a246d965078e969553e85d38e4b28") //true
```

#### 4.3 查询艺术家的钱包地址
```
getAddress("0xe28a246d965078e969553e85d38e4b28") 
//0xC463a4BF8A57725Ee9Ff23E096f6C395BdB00000
```

#### 4.4 更新艺术家钱包地址
```
updateAddress("0xe28a246d965078e969553e85d38e4b28", "0xC463a4BF8A57725Ee9Ff23E096f6C395BdB07b73") 
//0xC463a4BF8A57725Ee9Ff23E096f6C395BdB07b73
```

---

### 五、作品碎片合约测试

#### 5.1 添加作品

```
addWorks("0x0701e6555cbb36e24c3c1f32cbf89ecf","0xe28a246d965078e969553e85d38e4b28","6","600000000000000","1543894200")
//作品ID，艺术家ID，分成6碎片，作品总价为0.0006ETH，时间戳为11:30
```


#### 5.2 添加规则
```
configRule("0x0701e6555cbb36e24c3c1f32cbf89ecf",2,120,300,110,600,95,[80, 2, 18],[10, 2, 65],[80, 10, 10])
//作品ID，玩家首发最大购买数2个，冻结时间2分钟，作品保护时间5分钟，涨价110%，10分钟后降价，降价95%，
[艺术家80%, 平台2%, 奖池18%]，[艺术家10%（溢价部分）, 平台2%（总价）, 奖池65%（溢价部分）]，[游戏完成者80%, 首发购买者10%, 后续其他购买者10%]
```

#### 5.3 查询、更新作品参数和规则
```
hasWorks("0x0701e6555cbb36e24c3c1f32cbf89ecf") //是否有这个作品 true
hasWorks("0x0701e6555cbb36e24c3c1f32cbf89999") //false
hasDebris("0x0701e6555cbb36e24c3c1f32cbf89ecf",0) //是否有这个碎片编号 false 碎片编号是从1开始的
hasDebris("0x0701e6555cbb36e24c3c1f32cbf89ecf",6) //是否有这个碎片编号 true

getAllot("0x0701e6555cbb36e24c3c1f32cbf89ecf",0) //查询某一阶段分红的数组参数
getAllot("0x0701e6555cbb36e24c3c1f32cbf89ecf",0,1) //查询某一阶段分红的其中一个元素的分子值

getArtistId("0x0701e6555cbb36e24c3c1f32cbf89ecf") //按作品ID查询艺术家ID
getDebrisNum("0x0701e6555cbb36e24c3c1f32cbf89ecf") //按作品ID查询碎片总数

isGameOver("0x0701e6555cbb36e24c3c1f32cbf89ecf") //游戏是否结束 false
isProtect("0x0701e6555cbb36e24c3c1f32cbf89ecf",1) //碎片是否处于保护时间段
isPublish("0x0701e6555cbb36e24c3c1f32cbf89ecf") //是否发布
isSecond("0x0701e6555cbb36e24c3c1f32cbf89ecf",1) //碎片是否为二手交易
isStart("0x0701e6555cbb36e24c3c1f32cbf89ecf") //游戏是否到了开始时间

getPrice("0x0701e6555cbb36e24c3c1f32cbf89ecf") //获取作品价格 600000000000000 wei
getInitPrice("0x0701e6555cbb36e24c3c1f32cbf89ecf",1) //获取碎片的初始价格 100000000000000 wei
```

#### 5.4 开启作品游戏
```
publish("0x0701e6555cbb36e24c3c1f32cbf89ecf",1543902723) //发布作品游戏
```

#### 5.5 查询、更新奖池累计
```
updatePools("0x0701e6555cbb36e24c3c1f32cbf89ecf",123) //更新作品奖池
getPools("0x0701e6555cbb36e24c3c1f32cbf89ecf") //查询作品奖池累计 123
```

#### 5.6 结束游戏（或手工关闭）
```
updateEndTime("0x0701e6555cbb36e24c3c1f32cbf89ecf") //游戏结束，更新结束时间
```

#### 5.7 获取倒计时沙漏
```
//作品保护倒计时
//作品开始倒计时
//作品降价倒计时
```
 
### 六、平台合约测试

#### 6.1 给平台合约存款
```
deposit("0x0701e6555cbb36e24c3c1f32cbf89ecf") //给平台合约存款，在msg.value中填写0.0001ETH
balances() //查询合约余额，可以查询到刚才存入的
```

#### 6.2 查询、更新基金会地址
```

updateFoundAddress("0xe95651358BeE7106a206Bb9B61D0BC406c58707a") //更新平台基金会钱包地址
getFoundAddress() //0xe95651358BeE7106a206Bb9B61D0BC406c58707a
```

#### 6.3 平台合约将存款转出
```
transferTo("0xD134dd2a3c16Fb12885cd6FDc8a03D4bbe5d7031", "100000000000000") //将平台合约的余额转出
```

#### 6.4 查询、更新平台交易额与作品交易额
```
updateAllTurnover("100000000000000")
updateTurnover("0x0701e6555cbb36e24c3c1f32cbf89ecf", "100000000000000") //手动更新作品奖池余额0.0001ETH（100000000000000 wei）
getAllTurnover() //100000000000000
getTurnover() //100000000000000
```



### 七、玩家合约测试
#### 7.1 注册（静默或手工）
```
register("0x38363135323136363839353431000000","0xfaCd69A6df3265dDF3F60A868D3B0086feb1597E","0x0701e6555cbb36e24c3c1f32cbf89ecf","0x38363133373731373339313039000000")
```

#### 7.2 判断UnionID与Address是否为合法绑定关系
```
isLegalPlayer("0x38363135323136363839353431000000","0xfaCd69A6df3265dDF3F60A868D3B0086feb1597E")
//true
```

#### 7.3 更新玩家的最后交易时间
```
updateLastTime("0x0701e6555cbb36e24c3c1f32cbf89ecf",1)
```

#### 7.4 更新玩家的最后使用钱包地址
```
updateLastAddress("0x38363135323136363839353431000000","0xfaCd69A6df3265dDF3F60A868D3B0086feb1597E")
```

#### 7.5 玩家账号是否处于冻结期
```
isFreeze("0x38363135323136363839353431000000", "0x0701e6555cbb36e24c3c1f32cbf89ecf")
```

#### 7.6 更新玩家首发、二次投入金额

用于完成游戏时结算分红。

```
updateFirstAmount("0x38363135323136363839353431000000", "0x0701e6555cbb36e24c3c1f32cbf89ecf", 10000)
getFirstAmount("0x38363135323136363839353431000000", "0x0701e6555cbb36e24c3c1f32cbf89ecf")

updateSecondAmount("0x38363135323136363839353431000000", "0x0701e6555cbb36e24c3c1f32cbf89ecf", 20000)
getSecondAmount("0x38363135323136363839353431000000", "0x0701e6555cbb36e24c3c1f32cbf89ecf")
```

#### 7.7 关联成我的藏品

```
updateMyWorks("0x38363135323136363839353431000000", "0x0701e6555cbb36e24c3c1f32cbf89ecf", 0, 0)
```

#### 7.8 其他
```
updateFirstBuyNum("0x38363135323136363839353431000000", "0x0701e6555cbb36e24c3c1f32cbf89ecf") //更新玩家首发购买碎片的数量

updateReward("0x38363135323136363839353431000000", "0x0701e6555cbb36e24c3c1f32cbf89ecf", 10000) //更新玩家对作品的累计奖励
getReward("0x38363135323136363839353431000000", "0x0701e6555cbb36e24c3c1f32cbf89ecf") //查询玩家对作品的累计奖励

getFirstAmount("0x38363135323136363839353431000000", "0x0701e6555cbb36e24c3c1f32cbf89ecf") //获取玩家的首发投入金额

getFreezeHourglass("0x38363135323136363839353431000000", "0x0701e6555cbb36e24c3c1f32cbf89ecf") //获取玩家账号冻结倒计时

getInfoByUnionId("0x38363135323136363839353431000000") //通过UnionID查询玩家注册信息

getUnionIdByAddress("0xfaCd69A6df3265dDF3F60A868D3B0086feb1597E") //按钱包地址查询UnionID

hasAddress("0xfaCd69A6df3265dDF3F60A868D3B0086feb1597E") //是否存在这个钱包地址

hasUnionId("0x38363135323136363839353431000000") //是否存在这个UnionID

```

### 八、游戏主合约测试

#### 8.1 游戏入口
```

```

#### 8.2 分红

#### 8.3 获取游戏名称
```
name() //PuzzleBID Game
symbol() //PZB
```

#### 8.4 获取游戏当前最新时间
```
getNowTime() //1543964844
```



















