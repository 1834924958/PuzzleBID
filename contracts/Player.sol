pragma solidity ^0.5.0;

import "./library/SafeMath.sol"; //导入安全运算库
import "./library/Datasets.sol"; //导入公共结构库
import "./interface/TeamInterface.sol"; //导入管理员团队合约接口
import "./interface/WorksInterface.sol"; //导入作品碎片合约接口

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
        address indexed _address, 
        bytes32 _unionID, 
        bytes32 _referrer, 
        uint256 time
    );
    event OnUpdateLastAddress(bytes32 _unionID, address indexed _sender);
    event OnUpdateLastTime(bytes32 _unionID, bytes32 _worksID, uint256 _time);
    event OnUpdateFirstBuyNum(bytes32 _unionID, bytes32 _worksID, uint256 _firstBuyNum);
    event OnUpdateSecondAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateFirstAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateReinvest(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateRewardAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateMyWorks(
        bytes32 _unionID, 
        address indexed _address, 
        bytes32 _worksID, 
        uint256 _totalInput, 
        uint256 _totalOutput,
        uint256 _time
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
    
    mapping(bytes32 => Datasets.MyWorks) myworks; //我的藏品 (unionID => Datasets.MyWorks)

    //是否存在这个address   address存在则被认为是老用户
    function hasAddress(address _address) external view returns (bool) {
        bool has = false;
        for(uint256 i=0; i<playerAddressSets.length; i++) {
            if(playerAddressSets[i] == _address) {
                has = true;
                break;
            }
        }
        return has;
    }

    //是否存在这个unionID unionID存在则被认为是老用户
    function hasUnionId(bytes32 _unionID) external view returns (bool) {
        bool has = false;
        for(uint256 i=0; i<playersUnionIdSets.length; i++) {
            if(playersUnionIdSets[i] == _unionID) {
                has = true;
                break;
            }
        }
        return has;
    }

    //根据unionID查询玩家信息
    function getInfoByUnionId(bytes32 _unionID) external view returns (address, bytes32, uint256) {
        return (
            playersByUnionId[_unionID].lastAddress,
            playersByUnionId[_unionID].referrer, 
            playersByUnionId[_unionID].time
        );
    }

    //根据玩家address查询unionID
    function getUnionIdByAddress(address _address) external view returns (bytes32) {
        return playersByAddress[_address];
    }

    //玩家账号是否处于冻结期 true为处在冻结期
    function isFreeze(bytes32 _unionID, bytes32 _worksID) external view returns (bool) {
        uint256 freezeGap = works.getFreezeGap(_worksID);
        return playerCount[_unionID][_worksID].lastTime.add(freezeGap) < now ? false : true;
    }

    //获取玩家已经购买首发数
    function getFirstBuyNum(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return playerCount[_unionID][_worksID].firstBuyNum;
    }

    //获取玩家对作品碎片的二次购买累计金额
    function getSecondAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return playerCount[_unionID][_worksID].secondAmount;
    }

    //获取玩家对作品的首发投入累计
    function getFirstAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return playerCount[_unionID][_worksID].firstAmount;
    }

    //获取玩家最近使用的address
    function getLastAddress(bytes32 _unionID) external view returns (address payable) {
        return playersByUnionId[_unionID].lastAddress;
    }

    //获取玩家对作品的累计奖励
    function getRewardAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return playerCount[_unionID][_worksID].rewardAmount;
    }

    //获取玩家账号冻结倒计时
    function getFreezeHourglass(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        uint256 freezeGap = works.getFreezeGap(_worksID);
        if(playerCount[_unionID][_worksID].lastTime.add(freezeGap) > now) {
            return playerCount[_unionID][_worksID].lastTime.add(freezeGap).sub(now);
        }
        return 0;
    }

    //获取玩家账号冻结开始时间、冻结时长、当前时间
    function getFreezeTimestamp(bytes32 _unionID, bytes32 _worksID) external view returns (uint256, uint256, uint256) {
        uint256 freezeGap = works.getFreezeGap(_worksID);        
        return (playerCount[_unionID][_worksID].lastTime, freezeGap, now);
    }

    //获取我的累计投入、累计奖励、收集完成将获得金额
    function getMyReport(bytes32 _unionID, bytes32 _worksID) external view returns (uint256, uint256, uint256) {
        this.getFirstAmount(_unionID, _worksID).add(this.getSecondAmount(_unionID, _worksID));
        this.getRewardAmount(_unionID, _worksID);
        0

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

    //是否为合法绑定关系的玩家 避免address被多个unionID绑定 true为合法
    function isLegalPlayer(bytes32 _unionID, address _address) external view returns (bool) {
        return (this.hasUnionId(_unionID) || this.hasAddress(_address)) && playersByAddress[_address] == _unionID;
    }

    //注册玩家 静默
    function register(bytes32 _unionID, address payable _address, bytes32 _worksID, bytes32 _referrer) external onlyDev() returns (bool) {
        require(_unionID != bytes32(0) && _address != address(0) && _worksID != bytes32(0));

        //检查address和unionID是否为合法绑定关系 避免address被多个unionID绑定
        if(this.hasAddress(_address)) {
            if(playersByAddress[_address] != _unionID) {
                revert();
            } else {
                return true;
            }
        }
         
        playersByUnionId[_unionID].ethAddress.push(_address);
        if(_referrer != bytes32(0)) {
            playersByUnionId[_unionID].referrer = _referrer;
        }
        playersByUnionId[_unionID].lastAddress = _address;
        playersByUnionId[_unionID].time = now;

        playersByAddress[_address] = _unionID;

        playerAddressSets.push(_address);
        playersUnionIdSets.push(_unionID);
        playerCount[_unionID][_worksID] = Datasets.PlayerCount(0, 0, 0, 0, 0); //初始化玩家单元统计数据

        emit OnRegister(_address, _unionID, _referrer, now);

        return true;
    }

    //更新玩家最近使用的address
    function updateLastAddress(bytes32 _unionID, address payable _sender) external onlyDev() {
        if(playersByUnionId[_unionID].lastAddress != _sender) {
            playersByUnionId[_unionID].lastAddress = _sender;
            emit OnUpdateLastAddress(_unionID, _sender);
        }
    }

    //更新玩家对作品碎片的最后购买时间
    function updateLastTime(bytes32 _unionID, bytes32 _worksID) external onlyDev() {
        playerCount[_unionID][_worksID].lastTime = now;
        emit OnUpdateLastTime(_unionID, _worksID, now);
    }

    //更新玩家对作品碎片的首发购买累计
    function updateFirstBuyNum(bytes32 _unionID, bytes32 _worksID) external onlyDev() {
        playerCount[_unionID][_worksID].firstBuyNum = playerCount[_unionID][_worksID].firstBuyNum.add(1);
        emit OnUpdateFirstBuyNum(_unionID, _worksID, playerCount[_unionID][_worksID].firstBuyNum);
    }

    //更新玩家对作品碎片的二次购买累计金额
    function updateSecondAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external onlyDev() {
        playerCount[_unionID][_worksID].secondAmount = playerCount[_unionID][_worksID].secondAmount.add(_amount);
        emit OnUpdateSecondAmount(_unionID, _worksID, _amount);
    }

    //更新玩家对作品的首轮投入累计
    function updateFirstAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external onlyDev() {
        playerCount[_unionID][_worksID].firstAmount = playerCount[_unionID][_worksID].firstAmount.add(_amount);
        emit OnUpdateFirstAmount(_unionID, _worksID, _amount);
    }

    //更新玩家获得作品的累计奖励
    function updateRewardAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external onlyDev() {
        playerCount[_unionID][_worksID].rewardAmount = playerCount[_unionID][_worksID].rewardAmount.add(_amount);
        emit OnUpdateRewardAmount(_unionID, _worksID, _amount);
    }   

    //更新我的藏品列表 记录完成游戏时的address
    function updateMyWorks(
        bytes32 _unionID, 
        address _address, 
        bytes32 _worksID, 
        uint256 _totalInput, 
        uint256 _totalOutput
    ) external onlyDev() {
        myworks[_unionID] = Datasets.MyWorks(_address, _worksID, _totalInput, _totalOutput, now);
        emit OnUpdateMyWorks(_unionID, _address, _worksID, _totalInput, _totalOutput, now);
    }


}
