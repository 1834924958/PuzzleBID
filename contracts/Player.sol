pragma solidity ^0.4.24;

/**
 * @dev PuzzleBID Game 玩家合约
 * @author Simon<vsiryxm@163.com>
 */
contract Player {

	constructor() public {

	}

	function() external payable {
        revert();
    }

    //玩家结构
    struct Self {
        address[] ethAddress; //玩家address
        address referrer; //推荐人address
        uint256 time; //创建时间
    }

    //玩家与藏品关系结构
    struct MyWorks { 
        address ethAddress; //最终完成游戏的address
        bytes32 worksID; //碎片ID
        uint256 totalInput; //累计投入
        uint256 totalOutput; //累计回报
        uint256 time; //创建时间
    }

    //注册事件
    event OnRegister(
    	address ethAddress, 
    	bytes32 unionID, 
    	address referrer, 
    	uint256 time);

    mapping(bytes32 => Self) public playersByUnionId; //玩家信息 (unionID => Self)
    mapping(address => bytes32) public playersByAddress; //根据address查询玩家unionID

    mapping(bytes32 => mapping(bytes32 => uint256)) firstInvest; //玩家对作品的首轮投入累计 (unionID => (worksID => amount))
    mapping(bytes32 => mapping(bytes32 => uint256)) reinvest; //玩家对作品的再次投入累计 (unionID => (worksID => amount))
    mapping(bytes32 => mapping(bytes32 => uint256)) reward; //玩家获得作品的累计奖励 (unionID => (worksID => amount))

    mapping(bytes32 => MyWorks) myworks; //我的藏品 (unionID => MyWorks) 

    //注册玩家 静默
    function register(bytes32 _unionID, address _ethAddress, address _referrer) internal returns (bool) {
        require(_unionID != 0 && _ethAddress != address(0));
         
        playersByUnionId[_unionID].ethAddress.push(_ethAddress);
        if(_referrer != address(0)) {
        	playersByUnionId[_unionID].referrer = _referrer;
        }        
        playersByUnionId[_unionID].time = now;

        playersByAddress[_ethAddress] = _unionID;

        emit OnRegister(_ethAddress, _unionID, _referrer, now);
        return true;
    }

    //根据unionID查询玩家信息
    function getInfoByUnionId(uint256 _unionID) external returns (address, uint256) {
    	return (playersByUnionId[_unionID].referrer, 
    		    playersByUnionId[_unionID].time);
    }

    //根据玩家address查询unionID
    function getUserIdByAddress(address _address) external returns (bytes32) {
    	return playersByAddress[_address];
    }

    //获取玩家对作品的首发投入累计
    function getFirstInvest(bytes32 _unionID, bytes32 _worksID) external returns (uint256) {
    	return firstInvest[_unionID][_worksID];
    }

    //获取玩家对作品的再次投入累计
    function getReinvest(bytes32 _unionID, bytes32 _worksID) external returns (uint256) {
    	return reinvest[_unionID][_worksID];
    }

    //获取玩家对作品的累计奖励
    function getReward(bytes32 _unionID, bytes32 _worksID) internal {
    	return reward[_unionID][_worksID];
    }

    //更新玩家对作品的首轮投入累计
    function updateFirstInvest(bytes32 _unionID, bytes32 _worksID, uint256 _amount) internal {
    	firstInvest[_unionID][_worksID] = firstInvest[_unionID][_worksID].add(_amount);
    }

    //更新玩家对作品的再次投入累计    
    function updateReinvest(bytes32 _unionID, bytes32 _worksID, uint256 _amount) internal {
    	reinvest[_unionID][_worksID] = reinvest[_unionID][_worksID].add(_amount);
    }

    //更新玩家获得作品的累计奖励
    function updateReward(bytes32 _unionID, bytes32 _worksID, uint256 _amount) internal {
    	reward[_unionID][_worksID] = reward[_unionID][_worksID].add(_amount);
    }

    //获取我的藏品列表
    function getMyWorks(bytes32 _unionID) internal returns (address, bytes32, uint256, uint256, uint256) {
    	return (myworks[_unionID].ethAddress,
    		myworks[_unionID].worksID,
    		myworks[_unionID].totalInput,
    		myworks[_unionID].totalOutput,
    		myworks[_unionID].time);
    }

    //更新我的藏品列表
    function updateMyWorks(bytes32 _unionID, address _ethAddress, 
    	bytes32 _worksID, 
    	uint256 _totalInput, 
    	uint256 _totalOutput) {
    	myworks[_unionID] = MyWorks(_ethAddress, _worksID, _totalInput, _totalOutput);
    }


}