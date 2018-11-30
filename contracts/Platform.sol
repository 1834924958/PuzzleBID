pragma solidity ^0.5.0;

import "./library/SafeMath.sol"; //导入安全运算库
import "./interface/TeamInterface.sol"; //导入管理员团队接口

/**
 * @title PuzzleBID Game 平台合约
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
contract Platform {

    using SafeMath for *;

    address private foundation; //基金会address
    TeamInterface private team; //实例化管理员团队合约，正式发布时可定义成常量

    constructor(address _foundAddress, address _teamAddress) public {
        require(
            _foundAddress != address(0) &&
            _teamAddress != address(0)
        );
        foundation = _foundAddress;
        team = TeamInterface(_teamAddress);
    }

    //不接收ETH，deposit接管
    function() external payable {
        revert();
    }

    //事件
    event OnDeposit(bytes32 _worksID, address indexed _address, uint256 _amount); //作品ID，操作的合约地址，存进来的ETH数量
    event OnUpdateTurnover(bytes32 _worksID, uint256 _amount);
    event OnUpdateAllTurnover(uint256 _amount);
    event OnUpdateFoundation(address indexed _sender, address indexed _foundation);

    //仅开发者、合约地址可操作
    modifier onlyDev() {
        require(team.isDev(msg.sender));
        _;
    }

    //仅管理员可操作
    modifier onlyAdmin() {
        require(team.isAdmin(msg.sender));
        _;
    }

    uint256 allTurnover; //平台总交易额
    mapping(bytes32 => uint256) turnover; //作品的交易额 (worksID => amount)

    //获取平台总交易额
    function getAllTurnover() external view returns (uint256) {
        return allTurnover;
    }

    //获取作品的交易额
    function getTurnover(bytes32 _worksID) external view returns (uint256) {
        return turnover[_worksID];
    }

    //更新平台总交易额 仅开发者、合约地址可操作
    function updateAllTurnover(uint256 _amount) external onlyDev() {
        allTurnover = allTurnover.add(_amount); 
        emit OnUpdateAllTurnover(_amount);
    }   

    //更新作品的交易额 仅开发者、合约地址可操作
    function updateTurnover(bytes32 _worksID, uint256 _amount) external onlyDev() {
        turnover[_worksID] = turnover[_worksID].add(_amount); 
        emit OnUpdateTurnover(_worksID, _amount);
    }

    //更新平台基金会address 仅管理员可操作
    function updateFoundation(address _foundation) external onlyAdmin() {
        foundation = _foundation;
        emit OnUpdateFoundation(msg.sender, _foundation);
    }

    //平台合约代为保管奖池中的ETH
    function deposit(bytes32 _worksID) external payable {
        require(_worksID != bytes32(0)); 
        emit OnDeposit(_worksID, msg.sender, msg.value);
    }

    //获取基金会address
    function getFoundAddress() external view returns (address) {
        return foundation;
    }

    //查询奖池实际余额 仅开发者、合约地址可操作
    function getThisBalance() external view onlyDev() returns (uint256) {
        return address(this).balance;
    }

}