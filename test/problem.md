### 自测发现的问题

1、作品碎片_element分支数字错误
function getAllot(bytes32 _worksID, uint8 _flag, uint8 _element)

2、多了碎片ID参数，去除了
function isFinish(bytes32 _worksID, bytes32 _unionID)

3、>=等于改成<=
function isStart(bytes32 _worksID) external view returns (bool)
works[_worksID].beginTime <= now

4、第3个分支.lastPrice修改成.initPrice
function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
lastPrice = debris[_worksID][_debrisID].initPrice;

5、getLastAddress的address增加payable
function getLastAddress(bytes32 _unionID) external view returns (address payable);

6、增加条件判断：在游戏刚开始时作品应该不处于保护时间期
function isProtect(bytes32 _worksID, uint8 _debrisID) external view returns (bool) {
        if(debris[_worksID][_debrisID].lastTime == 0) { //在游戏刚开始时作品应该不处于保护时间期
            return false;
        }

7、增加条件判断：开始时间必须大于0
function getStartHourglass(bytes32 _worksID) external view returns (uint256) {

8、增加条件判断：最后交易时间为0时，保护倒计时无意义
function getProtectHourglass(bytes32 _worksID, uint8 _debrisID) external view returns (uint256) {