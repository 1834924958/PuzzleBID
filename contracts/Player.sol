pragma solidity ^0.5.0;

import "./library/SafeMath.sol"; //导入安全运算库
import "./library/Datasets.sol"; //导入公共结构库
import "./interface/TeamInterface.sol"; //导入管理员团队接口
import "./interface/WorksInterface.sol"; //导入管理员团队接口

/**
 * @title PuzzleBID Game 玩家合约
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
contract Player {

    using SafeMath for *;

    TeamInterface private team; //实例化管理员团队合约，正式发布时可定义成常量
    WorksInterface private works; //实例化作品碎片合约
    
    //定义玩家结构Player，见library/Datasets.sol
    //定义玩家与藏品关系结构MyWorks，见library/Datasets.sol
    
    constructor(address _teamAddress, address _worksAddress) public {
        team = TeamInterface(_teamAddress);
        works = WorksInterface(_worksAddress);
    }

    //不接收ETH
    function() external payable {
        revert();
    }

    //事件
    event OnRegister(
        address ethAddress, 
        bytes32 unionID, 
        address referrer, 
        uint256 time
    );
    event OnUpdateFirstInvest(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateReinvest(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateReward(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateMyWorks(
        bytes32 _unionID, 
        address _address, 
        bytes32 _worksID, 
        uint256 _totalInput, 
        uint256 _totalOutput
    );

    //仅开发者、合约地址可操作
    modifier onlyDev() {
        require(team.isDev(msg.sender));
        _;
    }

    mapping(bytes32 => Datasets.Player) private playersByUnionId; //玩家信息 (unionID => Datasets.Player)
    mapping(address => bytes32) private playersByAddress; //根据address查询玩家unionID (address => unionID)
    address[] private playerAddressSets; //检索辅助 玩家address集 查询address是否已存在
    bytes32[] private playersUnionIdSets; //检索辅助 玩家unionID集 查询unionID是否已存在

    mapping(bytes32 => mapping(bytes32 => Datasets.PlayerCount)) playerCount; //玩家购买统计 (unionID => (worksID => Datasets.PlayerCount))
    mapping(bytes32 => mapping(bytes32 => uint256)) private firstInvest; //玩家对作品的首轮投入累计 (unionID => (worksID => amount))
    mapping(bytes32 => mapping(bytes32 => uint256)) private reinvest; //玩家对作品的再次投入累计 (unionID => (worksID => amount))
    mapping(bytes32 => mapping(bytes32 => uint256)) private reward; //玩家获得作品的累计奖励 (unionID => (worksID => amount))

    mapping(bytes32 => Datasets.MyWorks) myworks; //我的藏品 (unionID => Datasets.MyWorks)

    //是否存在这个address   address存在则被认为是老用户
    function isHasAddress(address _address) external view returns (bool) {
        bool isHasAddress = false;
        for(uint256 i=0; i<playerAddressSets.length; i++) {
            if(playerAddressSets[i] == _address) {
                isHasAddress = true;
                break;
            }
        }
        return isHasAddress;
    }

    //是否存在这个unionID unionID存在则被认为是老用户
    function isHasUnionId(bytes32 _unionID) external view returns (bool) {
        bool isHasUnionId = false;
        for(uint256 i=0; i<playersUnionIdSets.length; i++) {
            if(playersUnionIdSets[i] == _unionID) {
                isHasUnionId = true;
                break;
            }
        }
        return isHasUnionId;
    }

    //注册玩家 静默
    function register(bytes32 _unionID, address _address, address _referrer) external returns (bool) {
        require(_unionID != 0 && _address != address(0));

        require (
            (this.isHasUnionId(_unionID) || this.isHasAddress(_address)) && 
            playersByAddress[_address] == _unionID
        ); //检查address和unionID是否为合法绑定关系 避免address被多个unionID绑定

        if(this.isHasAddress(_address)) {
            return false;
        }
         
        playersByUnionId[_unionID].ethAddress.push(_address);
        if(_referrer != address(0)) {
            playersByUnionId[_unionID].referrer = _referrer;
        }        
        playersByUnionId[_unionID].time = now;

        playersByAddress[_address] = _unionID;

        playerAddressSets.push(_address);
        playersUnionIdSets.push(_unionID);

        emit OnRegister(_address, _unionID, _referrer, now);

        return true;
    }

    //根据unionID查询玩家信息
    function getInfoByUnionId(uint256 _unionID) external view returns (address, uint256) {
        return (
            playersByUnionId[_unionID].referrer, 
            playersByUnionId[_unionID].time
        );
    }

    //根据玩家address查询unionID
    function getUnionIdByAddress(address _address) external view returns (bytes32) {
        return playersByAddress[_address];
    }

    //玩家账号是否处于冻结期 true为处在冻结期
    function isFreeze(address _unionID, bytes32 _worksID, uint256 _freezeGap) external view returns (bool) {
        uint256 freezeGap = works.getFreezeGap(_worksID);
        return playerCount[_unionID][_worksID].lastTime.add(freezeGap) < now ? false : true;
    }

    //获取玩家已经购买首发数
    function getFirstBuyNum(address _sender, bytes32 _worksID) external view returns (uint256) {
        return playerCount[_sender][_worksID].firstBuyNum;
    }

    //获取玩家对作品的首发投入累计
    function getFirstInvest(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return firstInvest[_unionID][_worksID];
    }

    //获取玩家对作品的再次投入累计
    function getReinvest(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return reinvest[_unionID][_worksID];
    }

    //获取玩家对作品的累计奖励
    function getReward(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return reward[_unionID][_worksID];
    }

    //获取玩家账号冻结倒计时
    function getFreezeSeconds(bytes32 _unionID, bytes32 _worksID) external view returns(uint256) {
        uint256 freezeGap = works.getFreezeGap(_worksID);
        if(playerCount[_unionID][_worksID].lastTime.add(freezeGap).sub(now) > 0) {
            return playerCount[_unionID][_worksID].lastTime.add(freezeGap).sub(now);
        }
        return 0;
    }

    //获取我的藏品列表
    function getMyWorks(bytes32 _unionID) external view returns (address, bytes32, uint256, uint256, uint256) {
        return (
            myworks[_unionID].ethAddress,
            myworks[_unionID].worksID,
            myworks[_unionID].totalInput,
            myworks[_unionID].totalOutput,
            myworks[_unionID].time
        );
    }

    //更新玩家对作品碎片的最后购买时间
    function updateLastTime(bytes32 _unionID, bytes32 _worksID) external onlyDev() {
        playerCount[_unionID][_worksID].lastTime = now;
    }

    //更新玩家对作品碎片的首发购买累计
    function updateFirstBuyNum(bytes32 _unionID, bytes32 _worksID, uint256 _firstBuyNum) external onlyDev() {
        playerCount[_unionID][_worksID].firstBuyNum = playerCount[_unionID][_worksID].firstBuyNum.add(_firstBuyNum);
    }

    //更新玩家对作品碎片的二次购买累计金额
    function updateSecondAmount(bytes32 _unionID, bytes32 _worksID, uint256 _secondAmount) external onlyDev() {
        playerCount[_unionID][_worksID].secondAmount = playerCount[_unionID][_worksID].secondAmount.add(_secondAmount);
    }

    //更新玩家对作品的首轮投入累计
    function updateFirstInvest(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external onlyDev() {
        firstInvest[_unionID][_worksID] = firstInvest[_unionID][_worksID].add(_amount);
        emit OnUpdateFirstInvest(_unionID, _worksID, _amount);
    }

    //更新玩家对作品的再次投入累计    
    function updateReinvest(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external onlyDev() {
        reinvest[_unionID][_worksID] = reinvest[_unionID][_worksID].add(_amount);
        emit OnUpdateReinvest(_unionID, _worksID, _amount);
    }

    //更新玩家获得作品的累计奖励
    function updateReward(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external onlyDev() {
        reward[_unionID][_worksID] = reward[_unionID][_worksID].add(_amount);
        emit OnUpdateReward(_unionID, _worksID, _amount);
    }   

    //更新我的藏品列表 记录完成游戏时的address
    function updateMyWorks(
        bytes32 _unionID, 
        address _address, 
        bytes32 _worksID, 
        uint256 _totalInput, 
        uint256 _totalOutput
    ) internal onlyDev() {
        myworks[_unionID] = Datasets.MyWorks(_address, _worksID, _totalInput, _totalOutput);
        emit OnUpdateMyWorks(_address, _worksID, _totalInput, _totalOutput);
    }


}
