pragma solidity ^0.5.0;

/**
 * @title PuzzleBID Game 玩家合约接口
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
interface PlayerInterface {

    //是否存在这个address   address存在则被认为是老用户
    function hasAddress(address _address) external view returns (bool);

    //是否存在这个unionID unionID存在则被认为是老用户
    function hasUnionId(bytes32 _unionID) external view returns (bool);

    //根据unionID查询玩家信息
    function getInfoByUnionId(bytes32 _unionID) external view returns (address, bytes32, uint256);

    //根据玩家address查询unionID
    function getUnionIdByAddress(address _address) external view returns (bytes32);

    //玩家账号是否处于冻结期 true为处在冻结期
    function isFreeze(bytes32 _unionID, bytes32 _worksID) external view returns (bool);

    //获取玩家已经购买首发数
    function getFirstBuyNum(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    //获取玩家对作品碎片的二次购买累计金额
    function getSecondAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    //获取玩家对作品的首发投入累计
    function getFirstAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    //获取玩家最近使用的address
    function getLastAddress(bytes32 _unionID) external view returns (address);

    //获取玩家对作品的累计奖励
    function getReward(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    //获取玩家账号冻结倒计时
    function getFreezeHourglass(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    //获取我的藏品列表
    function getMyWorks(bytes32 _unionID) external view returns (address, bytes32, uint256, uint256, uint256);

    //是否为合法绑定关系的玩家 避免address被多个unionID绑定 true为合法
    function isLegalPlayer(bytes32 _unionID, address _address) external view returns (bool);

    //注册玩家 静默
    function register(bytes32 _unionID, address _address, bytes32 _worksID, bytes32 _referrer) external returns (bool);

    //更新玩家最近使用的address
    function updateLastAddress(bytes32 _unionID, address _sender) external;

    //更新玩家对作品碎片的最后购买时间
    function updateLastTime(bytes32 _unionID, bytes32 _worksID) external;

    //更新玩家对作品碎片的首发购买累计
    function updateFirstBuyNum(bytes32 _unionID, bytes32 _worksID) external;

    //更新玩家对作品碎片的二次购买累计金额
    function updateSecondAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    //更新玩家对作品的首轮投入累计
    function updateFirstAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    //更新玩家获得作品的累计奖励
    function updateReward(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    //更新我的藏品列表 记录完成游戏时的address
    function updateMyWorks(
        bytes32 _unionID, 
        address _address, 
        bytes32 _worksID, 
        uint256 _totalInput, 
        uint256 _totalOutput
    ) external;


}
