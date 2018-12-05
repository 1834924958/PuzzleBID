pragma solidity ^0.5.0;

import "./library/SafeMath.sol"; //导入安全运算库
import "./library/Datasets.sol"; //导入公共结构库
import "./interface/TeamInterface.sol"; //导入管理员团队合约接口
import "./interface/ArtistInterface.sol"; //导入艺术家合约接口


/**
 * @title PuzzleBID Game 作品碎片合约
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
contract Works {

    using SafeMath for *;

    TeamInterface private team; //实例化管理员团队合约，正式发布时可定义成常量
    ArtistInterface private artist; //实例化艺术家合约

    constructor(address _teamAddress, address _artistAddress) public {
        team = TeamInterface(_teamAddress);
        artist = ArtistInterface(_artistAddress);
    }

    //不接收ETH
    function() external payable {
        revert();
    }

    //事件
    event OnAddWorks(
        bytes32 _worksID,
        bytes32 _artistID, 
        uint8 _debrisNum, 
        uint256 _price, 
        uint256 _beginTime,
        bool _isPublish
    );
    event OnInitDebris(
        bytes32 _worksID,
        uint8 _debrisNum,
        uint256 _initPrice
    );
    event OnUpdateDebris(
        bytes32 _worksID, 
        uint8 _debrisID, 
        bytes32 _unionID, 
        address indexed _sender
    );
    event OnUpdateFirstBuyer(
        bytes32 _worksID, 
        uint8 _debrisID, 
        bytes32 _unionID, 
        address indexed _sender
    );
    event OnUpdateLastBuyer(
        bytes32 _worksID, 
        uint8 _debrisID, 
        bytes32 _unionID, 
        address indexed _sender
    );
    event OnUpdateEndTime(bytes32 _worksID, uint256 _time);
    event OnUpdatePools(bytes32 _worksID, uint256 _value);
    event OnUpdateFirstUnionId(bytes32 _worksID, bytes32 _unionID);
    event OnUpdateSecondUnionId(bytes32 _worksID, bytes32 _unionID);

    //定义作品碎片结构Works，见library/Datasets.sol
    //定义作品游戏规则结构Rule，见library/Datasets.sol

    mapping(bytes32 => Datasets.Works) private works; //作品集 (worksID => Datasets.Works)
    mapping(bytes32 => Datasets.Rule) private rules; //游戏规则集 (worksID => Rule)
    mapping(bytes32 => uint256) private pools; //作品对应的奖池累计 (worksID => amount)
    mapping(bytes32 => mapping(uint8 => Datasets.Debris)) private debris; //作品碎片列表 如(worksID => (debrisID => Datasets.Debris))
    mapping(bytes32 => bytes32[]) firstUnionID; //作品首发购买者名单 (worksID => unionID[]) 去重复 辅助游戏结束时结算
    mapping(bytes32 => bytes32[]) secondUnionID; //作品二次购买者名单 (worksID => unionID[]) 去重复 辅助游戏结束时结算

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
        require(artist.hasArtist(_artistID));
        _;
    }

    //仅管理员可操作
    modifier onlyAdmin() {
        require(team.isAdmin(msg.sender));
        _;
    }

    //仅开发者、合约地址可操作
    modifier onlyDev() {
        require(team.isDev(msg.sender));
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
            _price.mul(1 wei), 
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
            false
        );  //添加作品事件

        initDebris(_worksID, _price, _debrisNum); //初始化作品碎片
    }

    //初始化作品碎片 碎片编号从1开始
    function initDebris(bytes32 _worksID, uint256 _price, uint8 _debrisNum) private {      
        uint256 initPrice = (_price / _debrisNum).mul(1 wei);
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
        uint8 _firstBuyLimit, //参考值：2
        uint256 _freezeGap, //参考值：180s 
        uint256 _protectGap, //参考值：1800s
        uint256 _increaseRatio, //参考值：110
        uint256 _discountGap, //参考值：3600s
        uint256 _discountRatio, //参考值：95

        uint8[3] calldata _firstAllot, //参考值：[80, 2, 18]
        uint8[3] calldata _againAllot, //参考值：[10, 2, 65]
        uint8[3] calldata _lastAllot //参考值：[80, 10, 10]
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
            _firstAllot[0] > 0 && _firstAllot[1] > 0 && _firstAllot[2] > 0 && //% 首发购买分配百分比 顺序对应：艺术家80、平台2、奖池18
            _againAllot[0] > 0 && _againAllot[1] > 0 && _againAllot[2] > 0 && //% 再次购买分配百分比 顺序对应：艺术家10（溢价部分）、平台2（总价）、奖池65（溢价部分）
            _lastAllot[0] > 0 && _lastAllot[1] > 0 && _lastAllot[2] > 0 //% 完成购买分配百分比 顺序对应：游戏完成者80、首发购买者10、后续其他购买者10
        ); //分配规则 百分比分子必须大于0

        rules[_worksID] = Datasets.Rule(
            _firstBuyLimit,
            _freezeGap.mul(1 seconds),
            _protectGap.mul(1 seconds),
            _increaseRatio,
            _discountGap.mul(1 seconds),    
            _discountRatio,
            _firstAllot,
            _againAllot,
            _lastAllot
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

    //获取作品、规则全部信息
    function getWorks(bytes32 _worksID) external view returns (uint8, uint256, uint256, uint256, bool) {
        return (
            works[_worksID].debrisNum,
            works[_worksID].price,
            works[_worksID].beginTime,
            works[_worksID].endTime,
            works[_worksID].isPublish
        );
    }

    //获取作品碎片全部信息
    function getDebris(bytes32 _worksID, uint8 _debrisID) external view 
        returns (uint256, address, address, bytes32, bytes32, uint256) {
        return (
            debris[_worksID][_debrisID].buyNum,
            debris[_worksID][_debrisID].firstBuyer,
            debris[_worksID][_debrisID].lastBuyer,
            debris[_worksID][_debrisID].firstUnionID,
            debris[_worksID][_debrisID].lastUnionID,
            debris[_worksID][_debrisID].lastTime
        );
    }

    //获取作品规则全部信息
    function getRule(bytes32 _worksID) external view 
        returns (uint256, uint256, uint256, uint8[3] memory, uint8[3] memory, uint8[3] memory) {
            return (
                rules[_worksID].increaseRatio,
                rules[_worksID].discountGap,
                rules[_worksID].discountRatio,
                rules[_worksID].firstAllot,
                rules[_worksID].againAllot,
                rules[_worksID].lastAllot
            );
    }

    //是否存在作品 true为存在
    function hasWorks(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].beginTime != 0;
    }

    //是否存在碎片 true为存在
    function hasDebris(bytes32 _worksID, uint8 _debrisID) external view returns (bool) {
        return _debrisID > 0 && _debrisID <= works[_worksID].debrisNum;
    }

    //作品游戏是否发布 
    function isPublish(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].isPublish;
    }

    //作品游戏是否可以开玩 仅发布且到了开始时间才可以玩这个游戏
    function isStart(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].beginTime <= now;
    }

    //作品碎片是否在保护期时间段内 true为被保护状态
    function isProtect(bytes32 _worksID, uint8 _debrisID) external view returns (bool) {
        uint256 protectGap = rules[_worksID].protectGap;
        return debris[_worksID][_debrisID].lastTime.add(protectGap) < now ? false : true;
    }

    //作品碎片是否为二手交易 true为二手交易
    function isSecond(bytes32 _worksID, uint8 _debrisID) external view returns (bool) {
        return debris[_worksID][_debrisID].buyNum > 0;
    }

    //作品游戏是否结束 true为已结束
    function isGameOver(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].endTime != 0;
    }
    
    //作品碎片是否收集完成
    function isFinish(bytes32 _worksID, bytes32 _unionID) external view returns (bool) {
        bool finish = true; //收集完成标志
        uint8 i = 1;
        while(i <= works[_worksID].debrisNum) {
            if(debris[_worksID][i].lastUnionID != _unionID) {
                finish = false;
                break;
            }
            i++;
        }
        return finish;
    } 

    //是否存在首发购买者名单中
    function hasFirstUnionId(bytes32 _worksID, bytes32 _unionID) external view returns (bool) {
        if(0 == firstUnionID[_worksID].length) {
            return false;
        }
        bool isHas = false;
        for(uint256 i=0; i<firstUnionID[_worksID].length; i++) {
            if(firstUnionID[_worksID][i] == _unionID) {
                isHas = true;
                break;
            }
        }
        return isHas;
    }

    //是否存在二次购买者名单中
    function hasSecondUnionId(bytes32 _worksID, bytes32 _unionID) external view returns (bool) {
        if(0 == secondUnionID[_worksID].length) {
            return false;
        }
        bool isHas = false;
        for(uint256 i=0; i<secondUnionID[_worksID].length; i++) {
            if(secondUnionID[_worksID][i] == _unionID) {
                isHas = true;
                break;
            }
        }
        return isHas;
    }  

    //获取作品的首发购买者名单
    function getFirstUnionId(bytes32 _worksID) external view returns (bytes32[] memory) {
        return firstUnionID[_worksID];
    }

    //获取作品的二次购买者名单
    function getSecondUnionId(bytes32 _worksID) external view returns (bytes32[] memory) {
        return secondUnionID[_worksID];
    }

    //获取作品的初始总价
    function getPrice(bytes32 _worksID) external view returns (uint256) {
        return works[_worksID].price;
    }

    //获取碎片的实时价格 有可能为0
    function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) external view returns (uint256) {        
        uint256 discountGap = rules[_worksID].discountGap;
        uint256 discountRatio = rules[_worksID].discountRatio;
        uint256 increaseRatio = rules[_worksID].increaseRatio;
        uint256 lastPrice;

        if(debris[_worksID][_debrisID].buyNum > 0 && debris[_worksID][_debrisID].lastTime.add(discountGap) < now) { //降价

            //过去多个时间段时，乘以折扣的n次方
            uint256 n = (now.sub(debris[_worksID][_debrisID].lastTime)) / discountGap; //几个时间段
            if((now.sub(debris[_worksID][_debrisID].lastTime)) % discountGap > 0) { //有余数时多计1
                n = n.add(1);
            }
            lastPrice = lastPrice.mul((discountRatio / 100).pwr(n)); //n次方 

        } else if (debris[_worksID][_debrisID].buyNum > 0) { //涨价
            lastPrice = debris[_worksID][_debrisID].lastPrice.mul(increaseRatio / 100);
        } else {
            lastPrice = debris[_worksID][_debrisID].initPrice; //碎片第一次被购买，不降不涨
        }

        return lastPrice;
    }

    //获取碎片的初始价格
    function getInitPrice(bytes32 _worksID, uint8 _debrisID) external view returns (uint256) {
        return debris[_worksID][_debrisID].initPrice;
    }

    //获取碎片的最后被交易的价格
    function getLastPrice(bytes32 _worksID, uint8 _debrisID) external view returns (uint256) {
        return debris[_worksID][_debrisID].lastPrice;
    }

    //获取碎片的最后购买者address
    function getLastBuyer(bytes32 _worksID, uint8 _debrisID) external view returns (address payable) {
        return debris[_worksID][_debrisID].lastBuyer;
    }

    //获取碎片的最后购买者unionID
    function getLastUnionId(bytes32 _worksID, uint8 _debrisID) external view returns (bytes32) {
        return debris[_worksID][_debrisID].lastUnionID;
    }

    //获取玩家账号冻结时间 单位s
    function getFreezeGap(bytes32 _worksID) external view returns (uint256) {
        return rules[_worksID].freezeGap;
    }

    //获取玩家首发购买上限数
    function getFirstBuyLimit(bytes32 _worksID) external view returns (uint256) {
        return rules[_worksID].firstBuyLimit;
    }

    //获取作品对应的艺术家ID
    function getArtistId(bytes32 _worksID) external view returns (bytes32) {
        return works[_worksID].artistID;
    }

    //获取作品分割的碎片数
    function getDebrisNum(bytes32 _worksID) external view returns (uint8) {
        return works[_worksID].debrisNum;
    }

    //获取首发购买分配百分比分子 返回数组
    function getAllot(bytes32 _worksID, uint8 _flag) external view returns (uint8[3] memory) {
        require(_flag < 3);
        if(0 == _flag) {
            return rules[_worksID].firstAllot;
        } else if(1 == _flag) {
            return rules[_worksID].againAllot;
        } else {
            return rules[_worksID].lastAllot;
        }        
    }

    //获取首发购买分配百分比分子 返回整型
    function getAllot(bytes32 _worksID, uint8 _flag, uint8 _element) external view returns (uint8) {
        require(_flag < 3 && _element < 3);
        if(0 == _flag) {
            return rules[_worksID].firstAllot[_element];
        } else if(1 == _flag) {
            return rules[_worksID].againAllot[_element];
        } else {
            return rules[_worksID].lastAllot[_element];
        }        
    }

    //获取作品奖池累计
    function getPools(bytes32 _worksID) external view returns (uint256) {
        return pools[_worksID];
    }

    //获取作品碎片游戏开始倒计时 单位s
    function getStartHourglass(bytes32 _worksID) external view returns (uint256) {
        if(works[_worksID].beginTime > 0 && works[_worksID].beginTime.sub(now) > 0 ) {
            return works[_worksID].beginTime.sub(now);
        }
        return 0;
    }

    //获取碎片保护期倒计时 单位s
    function getProtectHourglass(bytes32 _worksID, uint8 _debrisID) external view returns (uint256) {
        if(
            debris[_worksID][_debrisID].lastTime > 0 && 
            debris[_worksID][_debrisID].lastTime.add(rules[_worksID].protectGap).sub(now) > 0
        ) {
            return debris[_worksID][_debrisID].lastTime.add(rules[_worksID].protectGap).sub(now);
        }
        return 0;
    }

    //获取碎片降价倒计时 单位s 无限个倒计时段 过了第一个倒计时段 进入下一个倒计时段...
    function getDiscountHourglass(bytes32 _worksID, uint8 _debrisID) external view returns (uint256) {
        if(debris[_worksID][_debrisID].lastTime == 0) {
            return 0;
        }
        uint256 discountGap = rules[_worksID].discountGap;
        //过去多个时间段时，乘以折扣的n次方
        uint256 n = (now.sub(debris[_worksID][_debrisID].lastTime)) / discountGap; //几个时间段
        if((now.sub(debris[_worksID][_debrisID].lastTime)) % discountGap > 0) { //有余数时多计1
            n = n.add(1);
        }
        return debris[_worksID][_debrisID].lastTime.add(discountGap.mul(n)).sub(now);
    }

    //更新碎片
    function updateDebris(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address payable _sender) external onlyDev() {
        debris[_worksID][_debrisID].lastPrice = this.getDebrisPrice(_worksID, _debrisID);
        debris[_worksID][_debrisID].lastUnionID = _unionID; //更新归属
        debris[_worksID][_debrisID].lastBuyer = _sender; //更新归属
        debris[_worksID][_debrisID].buyNum = debris[_worksID][_debrisID].buyNum.add(1); //更新碎片被购买次数
        debris[_worksID][_debrisID].lastTime = now; //更新最后被交易时间
        emit OnUpdateDebris(_worksID, _debrisID, _unionID, _sender);
    }

    //更新作品碎片的首发购买者
    function updateFirstBuyer(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address payable _sender) external onlyDev() {
        debris[_worksID][_debrisID].firstBuyer = _sender;
        debris[_worksID][_debrisID].firstUnionID = _unionID;
        emit OnUpdateFirstBuyer(_worksID, _debrisID, _unionID, _sender);
    }

    //更新作品碎片的最后购买者
    function updateLastBuyer(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address payable _sender) external onlyDev() {
        debris[_worksID][_debrisID].lastBuyer = _sender;
        debris[_worksID][_debrisID].lastUnionID = _unionID;
        emit OnUpdateLastBuyer(_worksID, _debrisID, _unionID, _sender);
    }

    //更新作品碎片游戏结束时间
    function updateEndTime(bytes32 _worksID) external onlyDev() {
        works[_worksID].endTime = now;
        emit OnUpdateEndTime(_worksID, now);
    }

    //更新作品奖池累计
    function updatePools(bytes32 _worksID, uint256 _value) external onlyDev() {
        pools[_worksID] = pools[_worksID].add(_value);
        emit OnUpdatePools(_worksID, _value);
    }

    //更新作品的首发购买者名单
    function updateFirstUnionId(bytes32 _worksID, bytes32 _unionID) external onlyDev() {
        if(this.hasFirstUnionId(_worksID, _unionID) == false) {
            firstUnionID[_worksID].push(_unionID);
            emit OnUpdateFirstUnionId(_worksID, _unionID);
        }
    }

    //更新作品的二次购买者名单
    function updateSecondUnionId(bytes32 _worksID, bytes32 _unionID) external onlyDev() {
        if(this.hasSecondUnionId(_worksID, _unionID) == false) {
            secondUnionID[_worksID].push(_unionID);
            emit OnUpdateSecondUnionId(_worksID, _unionID);
        }
    }

 }