pragma solidity ^0.5.0;

import "./library/SafeMath.sol"; //导入安全运算库
import "./library/Datasets.sol"; //导入结构库
import "./interface/TeamInterface.sol"; //导入管理员团队合约接口
import "./interface/ArtistInterface.sol"; //导入艺术家合约接口

/**
 * @dev PuzzleBID Game 作品碎片合约
 * @website http://www.puzzlebid.com/
 * @author PuzzleBID Game Team
 *         Simon<vsiryxm@163.com>
 */
contract Works {

    TeamInterface private team; //引入管理员，正式发布时可定义成常量
    ArtistInterface private artist; //引入艺术家

    constructor(address _teamAddress, address _artistAddress) public {
        team = TeamInterface(_teamAddress);
        artist = ArtistInterface(_artistAddress);
    }

    //不接收ETH
    function() external payable {
        revert();
    }

    //事件
    event OnInitDebris(
        bytes32 _worksID,
        uint8 _debrisNum,
        uint256 initPrice
    );

    //定义作品碎片结构Works，见library/Datasets.sol
    //定义作品游戏规则结构Rule，见library/Datasets.sol

    mapping(bytes32 => Datasets.Works) private works; //作品集 (worksID => Datasets.Works)
    mapping(bytes32 => Rule) private rules; //游戏规则集 (worksID => Rule)
    mapping(bytes32 => uint256) private pools; //作品对应的奖池累计 (worksID => amount)
    mapping(bytes32 => mapping(uint8 => Datasets.Debris)) public debris; //作品碎片列表 如(worksID => (debrisID => Datasets.Debris))

    //当作品存在时
    modifier whenHasWorks(bytes32 _worksID) {
        require(works[_worksID].beginTime != 0);
        _;
    }

    //当作品不存在时
    modifier whenNotHasWorks(bytes32 _worksID) {
        require(works[_worksID].beginTime == 0);
        _;
    }

    //当艺术家存在时
    modifier whenHasArtist(bytes32 _artistID) {
        require(artist.isHasArtist(_artistID));
        _;
    }

    //仅管理员可操作
    modifier onlyAdmin() {
        require(team.isAdmin(msg.sender));
        _;
    }

    //添加一个作品游戏 仅管理员可操作
    //前置操作：先添加艺术家
    function addWorks(
        bytes32 _worksID,
        bytes32 _artistID, 
        uint8 _debrisNum, 
        uint256 _price, 
        uint256 _beginTime
    ) 
        external 
        onlyAdmin()
        whenNotHasWorks(_worksID)
        whenHasArtist(_artistID)
    {
        require(
            _debrisNum >= 2 && _debrisNum < 256 && //碎片数2~255
            _price > 0 && //价格必须大于0
            _beginTime > 0 && _beginTime > now //开始时间必须大于0和现在时间
        ); 

        works[_worksID] = Datasets.Works(
            _worksID, 
            _artistID, 
            _debrisNum, 
            _price, 
            _beginTime, 
            0,
            false
        );  //添加作品

        emit OnAddWorks(
            _worksID,
            _artistID, 
            _debrisNum, 
            _price, 
            _beginTime,
            false,
            _firstBuyLimit);  //添加作品事件

        initDebris(_worksID, _price, _debrisNum); //初始化作品碎片
    }

    //初始化作品碎片
    function initDebris(bytes32 _worksID, uint256 _price, uint8 _debrisNum) internal {      
        uint256 initPrice = _price / _debrisNum;
        for(uint8 i=1; i<=_debrisNum; i++) {
            debris[_worksID][i].worksID = _worksID;
            debris[_worksID][i].initPrice = initPrice;
        }
        emit OnInitDebris(
            _worksID,
            _debrisNum,
            initPrice
        );
    }

    //配置作品游戏参数
    //前置操作：先添加一个作品游戏
    function configRule(
        bytes32 _worksID,
        uint8 _firstBuyLimit,
        uint256 _freezeGap, 
        uint256 _protectGap, 
        uint256 _increaseRatio,
        uint256 _discountGap,
        uint256 _discountRatio,

        uint8[3] _firstAllot,
        uint8[3] _againAllot,
        uint8[3] _lastAllot
    ) 
        external
        onlyAdmin()
        whenHasWorks(_worksID)
    {

        require(
            _firstBuyLimit > 0 && //首发最多购买数必须大于0
            _freezeGap > 0 && //账号冻结时间必须大于0
            _protectGap > 0 && //作品保护时间必须大于0
            _increaseRatio > 0 && //作品涨价百分比分子必须大于0
            _discountGap > 0 && //作品降价时间必须大于0
            _discountRatio > 0 //作品降价百分比分子必须大于0
        );

        require(
            _firstAllot[0] > 0 && _firstAllot[1] > 0 && _firstAllot[2] > 0 &&
            _againAllot[0] > 0 && _againAllot[1] > 0 && _againAllot[2] > 0 &&
            _lastAllot[0] > 0 && _lastAllot[1] > 0 && _lastAllot[2] > 0
        ); //分配规则 百分比分子必须大于0

        rules[_worksID] = Rule(
            _firstBuyLimit,
            _freezeGap,
            _protectGap,
            _increaseRatio,
            _discountGap,    
            _discountRatio
        );

        rules[_worksID].firstAllot = _firstAllot;
        rules[_worksID].againAllot = _againAllot;
        rules[_worksID].lastAllot = _lastAllot;

    }

    //发布作品游戏 才能开始玩这个游戏 仅管理员可操作
    function publish(bytes32 _worksID, uint256 _beginTime) external onlyAdmin() {
        require(works[_worksID].beginTime != 0 && works[_worksID].isPublish == false);
        if(_beginTime > 0 && _beginTime > now) {
            works[_worksID].beginTime = _beginTime;
        }
        works[_worksID].isPublish = true; //开启这个游戏
    }

    //关闭一个作品游戏 紧急情况关闭
    function close(bytes32 _worksID) external onlyAdmin() {
        works[_worksID].isPublish = false;
    }

    //是否存在作品 true为存在
    function isHasWorks(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].beginTime != 0;
    }

    //作品游戏是否发布 仅发布时才可以玩这个游戏
    function isPublish(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].isPublish;
    }

    //作品游戏是否结束
    function isGameOver(bytes32 _worksID, address _sender) external view returns (bool) {
        if(works[_worksID].endTime != 0) {
            return true;
        }
        bool isFinished = true; //游戏完成标志
        uint8 i = 1;
        while(i <= works[_worksID].debrisNum) {
            if(debris[_worksID][_debrisID].lastBuyer != _sender) {
                isFinished = false;
                break;
            }
            i++;
        }
        return isFinished;
    }

    //获取碎片的最新价格
    function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) public view returns(uint256) {
        
    }

    //更新碎片
    function updateDebris(bytes32 _worksID, uint8 _debrisID) internal {
        
    }


 }

