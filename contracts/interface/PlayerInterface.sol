pragma solidity ^0.5.0;

/**
 * @title PuzzleBID Game 玩家合约接口
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
interface PlayerInterface {

    //注册玩家 静默
    function register(bytes32 _unionID, address _ethAddress, address _referrer) external;

    //根据unionID查询玩家信息
    function getInfoByUnionId(uint256 _unionID) external view returns (address, uint256);

    //根据玩家address查询unionID
    function getUnionIdByAddress(address _address) external view returns (bytes32);

    //获取玩家对作品的首发投入累计
    function getFirstInvest(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    //获取玩家对作品的再次投入累计
    function getReinvest(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    //获取玩家对作品的累计奖励
    function getReward(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    //获取我的藏品列表
    function getMyWorks(bytes32 _unionID) external view returns (address, bytes32, uint256, uint256, uint256);   

    //更新玩家对作品的首轮投入累计
    function updateFirstInvest(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    //更新玩家对作品的再次投入累计    
    function updateReinvest(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    //更新玩家获得作品的累计奖励
    function updateReward(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    //更新我的藏品列表
    function updateMyWorks(
        bytes32 _unionID, 
        address _address, 
        bytes32 _worksID, 
        uint256 _totalInput, 
        uint256 _totalOutput
    ) external;

}