# 艺术拼图游戏V1.0

### 常见问题

测试合约时报异常可能的原因有：

1、没有给子合约授权开发者权限；

2、测试更新类函数时，gas费给得过低，如少于3000000 wei，works合约达到3600000左右；

3、需要支付ETH的函数没有填写ETH数量，或给得过高，不能超过100000000000000000000000 wei，如玩家开始玩游戏时；

4、玩家玩不存在的作品游戏；

5、发布作品时，开始时间填写的不是未来的时间戳；

6、发布作品后，没有配置游戏规则（游戏规则中的参数都必须大于0）；

7、发布作品和配置完游戏规则后，没有开启作品游戏；

8、玩家玩游戏时，如果是新用户会自动注册，钱包地址只能对应一个玩家unionID(国别号+手机号码生成的一串16进制数)，否则出错；

玩家在玩的过程中，报异常可能的原因有：

9、账号处于冻结期；

10、作品处于保护期；

11、账号已经达到首发购买上限；

12、支付的ETH少于当前碎片挂牌价格。


### 参考FOMO3D：

主合约：https://etherscan.io/address/0xA62142888ABa8370742bE823c1782D17A0389Da1#code

分红合约：https://etherscan.io/address/0xc7029Ed9EBa97A096e72607f4340c34049C7AF48#code

JIincForwarderInterface合约：  https://etherscan.io/address/0xdd4950F977EE28D2C132f1353D1595035Db444EE#code

玩家合约：https://etherscan.io/address/0xD60d353610D9a5Ca478769D371b53CEfAA7B6E4c#code

隐藏合约：https://etherscan.io/address/0x32967D6c142c2F38AB39235994e2DDF11c37d590#code

管理员合约：https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code

团队合约：https://etherscan.io/address/0x464904238b5CdBdCE12722A7E6014EC1C0B66928#code

### 文章解析

官网：https://exitscam.me/play

https://mp.weixin.qq.com/s/kT94y3kHZKa-JXXWWGqD_A

https://mp.weixin.qq.com/s/GIDwSMU8_usF13n3rFvW-g

http://www.bcfans.com/jishu/jinjie/93273.html