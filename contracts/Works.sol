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

    using SafeMath for *;

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
    event OnUpdateDebris(
        bytes32 worksID, 
        uint8 debrisID, 
        bytes32 unionID, 
        address indexed sender
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

    //初始化作品碎片 碎片编号从1开始
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
        uint8 _firstBuyLimit, //参考值：2
        uint256 _freezeGap, //参考值：3 
        uint256 _protectGap, //参考值：1800
        uint256 _increaseRatio, //参考值：110
        uint256 _discountGap, //参考值：3600
        uint256 _discountRatio, //参考值：95

        uint8[3] _firstAllot, //参考值：[80, 2, 18]
        uint8[3] _againAllot, //参考值：[10, 2, 65]
        uint8[3] _lastAllot //参考值：[80, 10, 10]
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

    //是否存在碎片 true为存在
    function isHasDebris(bytes32 _worksID, uint8 _debrisID) external view returns (bool) {
        return _debrisID > 0 && _debrisID <= works[_worksID].debrisNum;
    }

    //作品游戏是否发布 
    function isPublish(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].isPublish;
    }

    //作品游戏是否可以开玩 仅发布且到了开始时间才可以玩这个游戏
    function isStart(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].beginTime >= now;
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
    function isFinish(bytes32 _worksID, uint8 _debrisID, address _unionID) external view returns (bool) {
        bool isFinish = true; //收集完成标志
        uint8 i = 1;
        while(i <= works[_worksID].debrisNum) {
            if(debris[_worksID][_debrisID].lastUnionID != _unionID) {
                isFinish = false;
                break;
            }
            i++;
        }
        return isFinish;
    }    

    //获取碎片的实时价格
    function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {        
        uint256 discountGap = rules[_worksID].discountGap;
        uint256 discountRatio = rules[_worksID].discountRatio;
        uint256 increaseRatio = rules[_worksID].increaseRatio;
        uint256 lastPrice; //有可能为0

        if(debris[_worksID][_debrisID].buyNum > 0 && debris[_worksID][_debrisID].lastTime.add(discountGap) < now) { //降价

            //过去多个时间段时，乘以折扣的n次方
            uint256 n = (now.sub(debris[_worksID][_debrisID].lastTime)) / discountGap; //几个时间段
            if((now.sub(debris[_worksID][_debrisID].lastTime)) % discountGap > 0) { //有余数时多计1
                n = n.add(1);
            }
            for(uint256 i=0; i<n; i++) {
                if(0 == i) {
                    lastPrice = debris[_worksID][_debrisID].lastPrice.mul(discountRatio / 100);
                } else {
                    lastPrice = lastPrice.mul(discountRatio / 100);
                }                
            }            

        } else if (debris[_worksID][_debrisID].buyNum > 0) { //涨价
            lastPrice = debris[_worksID][_debrisID].lastPrice.mul(increaseRatio / 100);
        } else {
            lastPrice = debris[_worksID][_debrisID].lastPrice; //碎片第一次被购买，不降不涨
        }
        return lastPrice;
    }

    //获取碎片的最后被交易的价格
    function getLastPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        return debris[_worksID][_debrisID].lastPrice;
    }

    //获取玩家账号冻结时间 单位s
    function getFreezeGap(bytes32 _worksID) external view returns(uint256) {
        return rules[_worksID].freezeGap;
    }

    //获取玩家首发购买上限数
    function getFirstBuyLimit(bytes32 _worksID) external view returns(uint256) {
        return rules[_worksID].FirstBuyLimit;
    }

    //获取作品碎片游戏开始倒计时 单位s
    function getStartHourglass(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        if(works[_worksID].beginTime.sub(now) > 0 ) {
            return works[_worksID].beginTime.sub(now);
        }
        return 0;
    }

    //获取碎片保护期倒计时 单位s
    function getProtectHourglass(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        if(debris[_worksID][_debrisID].lastTime.add(rules[_worksID].protectGap).sub(now) > 0) {
            return debris[_worksID][_debrisID].lastTime.add(rules[_worksID].protectGap).sub(now);
        }
        return 0;
    }

    //获取碎片降价倒计时 单位s 无限个倒计时段 过了第一个倒计时段 进入下一个倒计时段...
    function getDiscountHourglass(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        uint256 discountGap = rules[_worksID].discountGap;
        //过去多个时间段时，乘以折扣的n次方
        uint256 n = (now.sub(debris[_worksID][_debrisID].lastTime)) / discountGap; //几个时间段
        if((now.sub(debris[_worksID][_debrisID].lastTime)) % discountGap > 0) { //有余数时多计1
            n = n.add(1);
        }
        return debris[_worksID][_debrisID].lastTime.add(discountGap.mul(n)).sub(now);
    }

    //更新碎片
    function updateDebris(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address _sender) external onlyDev() {
        debris[_worksID][_debrisID].lastPrice = this.getDebrisPrice(_worksID, _debrisID);
        debris[_worksID][_debrisID].lastUnionID = _unionID; //更新归属
        debris[_worksID][_debrisID].lastBuyer = _sender; //更新归属
        debris[_worksID][_debrisID].buyNum = debris[_worksID][_debrisID].buyNum.add(1); //更新碎片被购买次数
        debris[_worksID][_debrisID].lastTime = now; //更新最后被交易时间
        emit OnUpdateDebris(_worksID, _debrisID, _unionID, _sender);
    }


 }