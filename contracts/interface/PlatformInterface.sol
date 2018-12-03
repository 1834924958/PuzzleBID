pragma solidity ^0.5.0;

/**
 * @title PuzzleBID Game 平台合约接口
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
interface PlatformInterface {

    //获取平台总交易额
    function getAllTurnover() external view returns (uint256);

    //获取作品的交易额
    function getTurnover(bytes32 _worksID) external view returns (uint256);

    //更新平台总交易额 仅开发者、合约地址可操作
    function updateAllTurnover(uint256 _amount) external;

    //更新作品的交易额 仅开发者、合约地址可操作
    function updateTurnover(bytes32 _worksID, uint256 _amount) external;

    //更新平台基金会address 仅管理员可操作
    function updateFoundAddress(address _foundation) external;

    //平台合约代为保管奖池中的ETH
    function deposit(bytes32 _worksID) external payable;

    //从奖池中转账ETH到指定address
    function transferTo(address _receiver, uint256 _amount) external;

    //获取基金会address
    function getFoundAddress() external view returns (address);

    //查询奖池实际余额 仅开发者、合约地址可操作
    function getThisBalance() external view returns (uint256);

}