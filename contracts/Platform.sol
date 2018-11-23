pragma solidity ^0.5.0;

import "./interface/TeamInterface.sol"; //导入管理员团队接口

/**
 * @dev PuzzleBID Game 平台合约
 * @website http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 *         Simon<vsiryxm@163.com>
 */
contract Platform {

	address foundation; //基金会address
    TeamInterface private Team; //引入管理员，正式发布时可定义成常量

	constructor(address _foundAddress, address _teamAddress) public {
		require(_foundAddress != address(0));
		foundation = _foundAddress; //初始化基金会address
        Team = TeamInterface(_teamAddress);
	}

    //不接收ETH，deposit接管
	function() external payable {
        revert();
    }

    //事件
    event OnDeposit(bytes32 _worksID, address indexed _address, uint256 _amount); //作品ID，操作的合约地址，存进来的ETH数量
    event OnUpdateTurnover(bytes32 _worksID, uint256 _amount);
    event OnRegisterWorks(bytes32 _worksID, address _contractAddress);
    event OnUpdateAllTurnover(uint256 _amount);

    //仅开发者、合约地址可操作
    modifier onlyDev() {
        require(Team.isDev(msg.sender));
        _;
    }

    uint256 allTurnover; //平台总交易额
    mapping(bytes32 => uint256) turnover; //作品的交易额 (worksID => amount)
    mapping(bytes32 => address) worksContract;//作品的合约地址集 (worksID => contractAddress)

    //获取平台总交易额
    function getAllTurnover() external returns (uint256) {
    	return allTurnover;
    }

    //更新平台总交易额
    function updateAllTurnover(uint256 _amount) internal {
    	allTurnover = allTurnover.add(_amount); 
        emit OnUpdateAllTurnover(uint256 _amount);
    }

    //获取作品的交易额
    function getTurnover(bytes32 _worksID) external returns (uint256) {
    	return turnover[_worksID];
    }

    //更新作品的交易额
    function updateTurnover(bytes32 _worksID, uint256 _amount) internal {
    	allTurnover = allTurnover.add(_amount); 
        emit OnUpdateTurnover(_worksID, _amount);
    }

    //平台合约代为保管奖池中的ETH
    function deposit(bytes32 _worksID) external payable {
    	require(this.isHasWorks(_worksID)); //不接受非法合约地址存款
    	emit OnDeposit(_worksID, msg.sender, msg.value);
    }   

    //注册作品对应的合约
    function registerWorks(bytes32 _worksID, address _contractAddress) external onlyDev() {
    	worksContract[_worksID] = _contractAddress; //废弃一个作品合约后，允许管理员迁移升级作品合约，直接覆盖即可
        emit OnRegisterWorks(_worksID, _contractAddress);
    }

    //是否已经存在该作品合约地址
    function isHasWorks(bytes32 _worksID) external returns (bool) {
    	return worksContract[_worksID] != address(0);
    }

    //获取基金会address
    function getFoundation() external returns (address) {
        return foundation;
    }

    //查询奖池实际余额
    function getThisBalance() external returns (uint256) {
        return address(this).balance;
    }

}