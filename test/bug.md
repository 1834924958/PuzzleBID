
### 自测发现的问题

1、作品碎片_element分支数字错误

```
function getAllot(bytes32 _worksID, uint8 _flag, uint8 _element)
```

2、多了碎片ID参数，去除了

```
function isFinish(bytes32 _worksID, bytes32 _unionID)
```

3、>=等于改成<=

```
function isStart(bytes32 _worksID) external view returns (bool)
works[_worksID].beginTime <= now
```

4、第3个分支.lastPrice修改成.initPrice

```
function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
lastPrice = debris[_worksID][_debrisID].initPrice;
```

5、getLastAddress的address增加payable

```
function getLastAddress(bytes32 _unionID) external view returns (address payable);
```

6、增加条件判断：在游戏刚开始时作品应该不处于保护时间期

```
function isProtect(bytes32 _worksID, uint8 _debrisID) external view returns (bool) {
        if(debris[_worksID][_debrisID].lastTime == 0) { //在游戏刚开始时作品应该不处于保护时间期
            return false;
        }
```

7、增加条件判断：开始时间必须大于0

```
function getStartHourglass(bytes32 _worksID) external view returns (uint256) {
```

8、增加条件判断：最后交易时间为0时，保护倒计时无意义

```
function getProtectHourglass(bytes32 _worksID, uint8 _debrisID) external view returns (uint256) {
```

9、碎片最小数修改成大于1

```
function hasDebris(bytes32 _worksID, uint8 _debrisID) external view returns (bool) {
        return _debrisID > 1 && _debrisID <= works[_worksID].debrisNum;
```

10、在碎片被首发购买后，获取碎片实时价格为0，重大错误

```
function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
第一个分支里，lastPrice修改成debris[_worksID][_debrisID].lastPrice.mul
```

11、开始倒计时、保护倒计时、玩家冻结倒计时在过了时间段后，不是返回0

```
function getStartHourglass
function getProtectHourglass
function getFreezeHourglass
```

12、修改第二个检查，条件设置不合理

```
function register(bytes32 _unionID, address payable _address, bytes32 _worksID, bytes32 _referrer)
require(playersByAddress[_address] == _unionID);
```

13、主合约中，重复更新了碎片的最后购买玩家 secondPlay

```
去除了updateLastBuyer()函数
```

14、主合约中，在判断是否二次购买前更新了碎片被购买的次数，有误 
改在了判断之后更新次数

15、碎片实时价格：在过了降价期后，计算价格为0
发现n次方运算时，底数不能是0.几

```
lastPrice = debris[_worksID][_debrisID].lastPrice.mul((discountRatio / 100).pwr(n)); 
修改成了for循环
```

16、碎片实时价格：在过了降价期后，降价的价格不准确
多算了一个降价期，即多乘了个95%

```
uint256 n = (now.sub(debris[_worksID][_debrisID].lastTime)) / discountGap;
修改成：
uint256 n = (now.sub(debris[_worksID][_debrisID].lastTime.add(discountGap))) / discountGap;
```

17、碎片实时价格：被第二次购买时，在涨价时间段内没有涨价

```
lastPrice = debris[_worksID][_debrisID].lastPrice.mul(increaseRatio / 100);
修改成
lastPrice = debris[_worksID][_debrisID].lastPrice.mul(increaseRatio) / 100;
```

18、函数中的乘除有问题：乘以一个分数时，要先乘以分子，而不是乘以（分子/分母）

```
function finishGame()
platform.transferTo(msg.sender, works.getPools(_worksID).mul(lastAllot / 100));
修改成
platform.transferTo(msg.sender, works.getPools(_worksID).mul(lastAllot) / 100);
```

类似地还有两处：

```
function firstSend(bytes32 _worksID) private {
tmpAmount = works.getPools(_worksID).mul(lastAllot / 100).mul(tmpAmount / works.getPrice(_worksID));
修改成：
tmpAmount = works.getPools(_worksID).mul(lastAllot).mul(tmpAmount) / 100 / works.getPrice(_worksID);
```

```
function secondSend(bytes32 _worksID) private {
tmpAmount = works.getPools(_worksID).mul(lastAllot / 100).mul(tmpAmount / platform.getTurnover(_worksID).sub(works.getPrice(_worksID)));
修改成：
tmpAmount = works.getPools(_worksID).mul(lastAllot).mul(tmpAmount) / 100 / (platform.getTurnover(_worksID).sub(works.getPrice(_worksID)));
```

19、碎片价格为小数的时候直接舍去了，导致碎片初始价格不准确
```
function addWorks()
加入条件_price % _debrisNum == 0 
保证价格大于0，且能整除碎片数
```

20、PuzzleBID合约中，lastUnionID先更新再去获取上一家，逻辑错误
已经增加:
bytes32 lastUnionID = works.getLastUnionId(_worksID, _debrisID); //获取碎片的最后玩家ID 

21、Works结构体增加了lastUnionID，初始化相应增加一个参数，在游戏结束时，将updateEndTime修改成了finish，更新结束时间和最后玩家ID

22、玩家注册时BUG

23、二次购买时获取碎片实时价格修改成最后成交价格，因为前面程序已经更新了碎片的成交价

```
function secondPlay
uint256 lastPrice = works.getDebrisPrice(_worksID, _debrisID);  
修改成
uint256 lastPrice = works.getLastPrice(_worksID, _debrisID);
```  

24、首发购买碎片时，只更新了碎片上的最后玩家，没有更新首发购买名单

```
在下面函数function updateFirstBuyer()中，加入了this.updateFirstUnionId(_worksID, _unionID);
```

