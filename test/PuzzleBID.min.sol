pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }

}



/**
 * @title PuzzleBID Game 公共结构库
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
library Datasets {

    //玩家结构
    struct Player {
        address[] ethAddress; //玩家address
        bytes32 referrer; //推荐人unionID
        address payable lastAddress; //多个address时，最近使用的address
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

    //作品碎片结构
    struct Works {
        bytes32 worksID; //作品编号
        bytes32 artistID; //碎片编号
        uint8 debrisNum; //作品分割成碎片数
        uint256 price; //作品初始价格
        uint256 beginTime; //作品游戏开始时间
        uint256 endTime; //作品游戏结束时间
        bool isPublish; //作品游戏发布开关 true为开启
        bytes32 lastUnionID; //最后结束游戏玩家ID
    }

    //碎片结构
    struct Debris {
        uint8 debrisID; //碎片ID
        bytes32 worksID; //作品ID
        uint256 initPrice; //初始价格
        uint256 lastPrice; //最新成交价格
        uint256 buyNum; //被交易总次数
        address payable firstBuyer; //首发购买者，冗余
        address payable lastBuyer; //最后一次购买者，冗余
        bytes32 firstUnionID; //首发购买者ID，冗余
        bytes32 lastUnionID; //最后一次购买者ID，冗余
        uint256 lastTime; //最后一次被购买时间
    }
    
    //作品游戏规则结构
    struct Rule {
        //=========================================================================
        //| 游戏配置参数 特殊情况以创建作品游戏时为准
        //=========================================================================
        uint8 firstBuyLimit; //一个作品的首发最多购买数
        uint256 freezeGap; //玩家购买一个作品中的一个碎片后冻结3分钟
        uint256 protectGap; //碎片保护时间30分钟
        uint256 increaseRatio; //% 碎片价格调整为上一次价格的110%
        uint256 discountGap; //碎片开始打折时间，被购买1小时后    
        uint256 discountRatio; //% 碎片价格调整为首发价格的95%

        //=========================================================================
        //| 游戏分红比例规则 特殊情况以创建作品游戏时为准
        //=========================================================================
        uint8[3] firstAllot; //% 首发购买分配百分比 顺序对应：艺术家80、平台2、奖池18
        uint8[3] againAllot; //% 再次购买分配百分比 顺序对应：艺术家10（溢价部分）、平台2（总价）、奖池65（溢价部分）
        uint8[3] lastAllot;  //% 完成购买分配百分比 顺序对应：游戏完成者80、首发购买者10、后续其他购买者10
    }

    //玩家对作品购买行为的单元统计
    struct PlayerCount {
        uint256 lastTime; //同一作品同一玩家，最后一次购买时间
        uint256 firstBuyNum; //同一作品同一玩家，首发购买碎片数小计
        uint256 firstAmount; //同一作品同一玩家，首发购买总计金额
        uint256 secondAmount; //同一作品同一玩家，二次购买总计金额
        uint256 rewardAmount; //同一作品同一玩家，奖励总计金额
    }

}


/**
 * @title PuzzleBID Game 管理员团队合约
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
contract Team {

    address public owner; //超级管理员

    //管理员角色：开发团队、管理员
    struct Admin {
        bool isAdmin; //true 为超级管理员 有关后台函数设计，都需要管理员权限
        bool isDev; //true 为开发团队 有关合约间通信，都需要开发团队权限
        bytes32 name; //管理员名字
    }

    mapping (address => Admin) admins; //管理员列表

    constructor(address _owner) public {
        owner = _owner;

    }

    //事件
    event OnAddAdmin(
        address indexed _address, 
        bool _isAdmin, 
        bool _isDev, 
        bytes32 _name
    );
    event OnRemoveAdmin(address indexed _address);

    //仅超级管理员可操作
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //添加管理员成员
    function addAdmin(address _address, bool _isAdmin, bool _isDev, bytes32 _name) external onlyOwner() {
        admins[_address] = Admin(_isAdmin, _isDev, _name);        
        emit OnAddAdmin(_address, _isAdmin, _isDev, _name);
    }

    //更新管理员成员
    function removeAdmin(address _address) external onlyOwner() {
        delete admins[_address];        
        emit OnRemoveAdmin(_address);
    }

    //是否为超管
    function isOwner() external view returns (bool) {
        return owner == msg.sender;
    }

    //是否为管理员
    function isAdmin(address _sender) external view returns (bool) {
        return admins[_sender].isAdmin;
    }

    //是否为开发者、合约地址
    function isDev(address _sender) external view returns (bool) {
        return admins[_sender].isDev;
    }


}


interface TeamInterface {

    //添加、更新管理员成员
    function addAdmin(address _address, bool _isAdmin, bool _isDev, bytes32 _name) external;

    //删除管理员成员
    function removeAdmin(address _address) external;

    //是否为超管
    function isOwner() external view returns (bool);

    //是否为管理员
    function isAdmin(address _sender) external view returns (bool);

    //是否为开发者、合约地址
    function isDev(address _sender) external view returns (bool);

}

/**
 * @title PuzzleBID Game 艺术家合约
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
contract Artist {

    TeamInterface private team; //实例化管理员合约，正式发布时可定义成常量
    mapping(bytes32 => address payable) private artists; //艺术家列表 (artistID => address)

    constructor(address _teamAddress) public {
        team = TeamInterface(_teamAddress);
    }

    //不接收ETH
    function() external payable {
        revert();
    }

    //事件
    event OnAdd(bytes32 _artistID, address indexed _address);
    event OnUpdateAddress(bytes32 _artistID, address indexed _address);

    //仅管理员可操作
    modifier onlyAdmin() {
        require(team.isAdmin(msg.sender));
        _;
    }

    //根据艺术家ID获取钱包地址
    function getAddress(bytes32 _artistID) external view returns (address payable) {
        return artists[_artistID];
    }

    //添加艺术家
    function add(bytes32 _artistID, address payable _address) external onlyAdmin() {
        require(this.hasArtist(_artistID) == false);
        artists[_artistID] = _address;
        emit OnAdd(_artistID, _address);
    }

    //是否存在艺术家 true为存在
    function hasArtist(bytes32 _artistID) external view returns (bool) {
        return artists[_artistID] != address(0);
    }

    //更新艺术家address
    function updateAddress(bytes32 _artistID, address payable _address) external onlyAdmin() {
        require(artists[_artistID] != address(0) && _address != address(0));
        artists[_artistID] = _address;
        emit OnUpdateAddress(_artistID, _address);
    }

}


/**
 * @title PuzzleBID Game 作品碎片合约接口
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
interface WorksInterface {

    //添加一个作品游戏 仅管理员可操作
    //前置操作：先添加艺术家
    function addWorks(
        bytes32 _worksID,
        bytes32 _artistID, 
        uint8 _debrisNum, 
        uint256 _price, 
        uint256 _beginTime
    ) 
        external;

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
        external;

    //发布作品游戏 才能开始玩这个游戏 仅管理员可操作
    function publish(bytes32 _worksID, uint256 _beginTime) external;

    //关闭一个作品游戏 紧急情况关闭
    function close(bytes32 _worksID) external;

    //获取作品、规则全部信息
    function getWorks(bytes32 _worksID) external view returns (uint8, uint256, uint256, uint256, bool);

    //获取作品碎片全部信息
    function getDebris(bytes32 _worksID, uint8 _debrisID) external view 
        returns (uint256, address, address, bytes32, bytes32, uint256);

    //获取作品规则全部信息
    function getRule(bytes32 _worksID) external view 
        returns (uint256, uint256, uint256, uint8[3] memory, uint8[3] memory, uint8[3] memory);

    //是否存在作品 true为存在
    function hasWorks(bytes32 _worksID) external view returns (bool);

    //是否存在碎片 true为存在
    function hasDebris(bytes32 _worksID, uint8 _debrisID) external view returns (bool);

    //作品游戏是否发布 
    function isPublish(bytes32 _worksID) external view returns (bool);

    //作品游戏是否可以开玩 仅发布且到了开始时间才可以玩这个游戏
    function isStart(bytes32 _worksID) external view returns (bool);

    //作品碎片是否在保护期时间段内 true为被保护状态
    function isProtect(bytes32 _worksID, uint8 _debrisID) external view returns (bool);

    //作品碎片是否为二手交易 true为二手交易
    function isSecond(bytes32 _worksID, uint8 _debrisID) external view returns (bool);

    //作品游戏是否结束 true为已结束
    function isGameOver(bytes32 _worksID) external view returns (bool);
    
    //作品碎片是否收集完成
    function isFinish(bytes32 _worksID, bytes32 _unionID) external view returns (bool);

    //是否存在首发购买者名单中
    function hasFirstUnionId(bytes32 _worksID, bytes32 _unionID) external view returns (bool);

    //是否存在二次购买者名单中
    function hasSecondUnionId(bytes32 _worksID, bytes32 _unionID) external view returns (bool);

    //获取作品的首发购买者名单
    function getFirstUnionId(bytes32 _worksID) external view returns (bytes32[] memory);

    //获取作品的二次购买者名单
    function getSecondUnionId(bytes32 _worksID) external view returns (bytes32[] memory);

    //获取作品的初始总价
    function getPrice(bytes32 _worksID) external view returns (uint256);

    //获取碎片的实时价格 有可能为0
    function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    //返回碎片状态信息 专供游戏主页
    function getDebrisStatus(bytes32 _worksID, uint8 _debrisID) external view returns (uint256[4] memory, uint256, uint256, bytes32);

    //获取碎片的初始价格
    function getInitPrice(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    //获取碎片的最后被交易的价格
    function getLastPrice(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    //获取碎片的最后购买者address
    function getLastBuyer(bytes32 _worksID, uint8 _debrisID) external view returns (address payable);

    //获取碎片的最后购买者unionID
    function getLastUnionId(bytes32 _worksID, uint8 _debrisID) external view returns (bytes32);

    //获取玩家账号冻结时间 单位s
    function getFreezeGap(bytes32 _worksID) external view returns (uint256);

    //获取玩家首发购买上限数
    function getFirstBuyLimit(bytes32 _worksID) external view returns (uint256);

    //获取作品对应的艺术家ID
    function getArtistId(bytes32 _worksID) external view returns (bytes32);

    //获取作品分割的碎片数
    function getDebrisNum(bytes32 _worksID) external view returns (uint8);

    //获取首发购买分配百分比分子 返回数组
    function getAllot(bytes32 _worksID, uint8 _flag) external view returns (uint8[3] memory);

    //获取首发购买分配百分比分子 返回整型
    function getAllot(bytes32 _worksID, uint8 _flag, uint8 _element) external view returns (uint8);

    //获取作品奖池累计
    function getPools(bytes32 _worksID) external view returns (uint256);

    //获取作品碎片游戏开始倒计时 单位s
    function getStartHourglass(bytes32 _worksID) external view returns (uint256);

    //获取作品状态 用于判断是否开始、开始倒计时、是否结束、结束后作品最终归属谁
    function getWorksStatus(bytes32 _worksID) external view returns (uint256, uint256, uint256, bytes32);

    //获取碎片保护期倒计时 单位s
    function getProtectHourglass(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    //获取碎片降价倒计时 单位s 无限个倒计时段 过了第一个倒计时段 进入下一个倒计时段...
    function getDiscountHourglass(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    //更新碎片
    function updateDebris(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address _sender) external;

    //更新作品碎片的首发购买者
    function updateFirstBuyer(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address _sender) external;

    //更新作品碎片被购买的次数
    function updateBuyNum(bytes32 _worksID, uint8 _debrisID) external;

    //更新作品碎片游戏结束时间、游戏完成者
    function finish(bytes32 _worksID, bytes32 _unionID) external;

    //更新作品奖池累计
    function updatePools(bytes32 _worksID, uint256 _value) external;

    //更新作品的首发购买者名单
    function updateFirstUnionId(bytes32 _worksID, bytes32 _unionID) external;

    //更新作品的二次购买者名单
    function updateSecondUnionId(bytes32 _worksID, bytes32 _unionID) external;

 }
 
/**
 * @title PuzzleBID Game 艺术家合约
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
interface ArtistInterface {

    //根据艺术家ID获取钱包地址
    function getAddress(bytes32 _artistID) external view returns (address payable);

    //添加艺术家
    function add(bytes32 _artistID, address _address) external;

    //是否存在艺术家 true为存在
    function hasArtist(bytes32 _artistID) external view returns (bool);

    //更新艺术家address
    function updateAddress(bytes32 _artistID, address _address) external;

}


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
    event OnUpdateBuyNum(bytes32 _worksID, uint8 _debrisID);
    event OnFinish(bytes32 _worksID, bytes32 _unionID, uint256 _time);
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
            _price > 0 && _price % _debrisNum == 0 && //价格必须大于0，且应该能整除碎片数
            _beginTime > 0 && _beginTime > now //开始时间必须大于0和现在时间
        ); 

        works[_worksID] = Datasets.Works(
            _worksID, 
            _artistID, 
            _debrisNum, 
            _price.mul(1 wei), 
            _beginTime, 
            0,
            false,
            bytes32(0)
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
            _discountRatio > 0 && //作品降价百分比分子必须大于0
            _discountGap > _protectGap //作品降价时长必须大于作品保护时长
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
        require(this.getAllot(_worksID, 0, 0) != 0); //检查游戏规则，以免遗忘后开启游戏
        if(_beginTime > 0) {
            require(_beginTime > now);
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
        if(debris[_worksID][_debrisID].lastTime == 0) { //在游戏刚开始时作品应该不处于保护时间期
            return false;
        }
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
    function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {        
        uint256 discountGap = rules[_worksID].discountGap;
        uint256 discountRatio = rules[_worksID].discountRatio;
        uint256 increaseRatio = rules[_worksID].increaseRatio;
        uint256 lastPrice;

        if(debris[_worksID][_debrisID].buyNum > 0 && debris[_worksID][_debrisID].lastTime.add(discountGap) < now) { //降价

            //过去多个时间段时，乘以折扣的n次方
            uint256 n = (now.sub(debris[_worksID][_debrisID].lastTime.add(discountGap))) / discountGap; 
            if((now.sub(debris[_worksID][_debrisID].lastTime.add(discountGap))) % discountGap > 0) { 
                n = n.add(1);
            }
            //lastPrice = debris[_worksID][_debrisID].lastPrice.mul((discountRatio / 100).pwr(n)); //n次方 = 0
            for(uint256 i=0; i<n; i++) {
                if(0 == i) {
                    lastPrice = debris[_worksID][_debrisID].lastPrice.mul(increaseRatio).mul(discountRatio) / 10000; //1210需求修改：降前先涨110%
                } else {
                    lastPrice = lastPrice.mul(discountRatio) / 100;
                }
            }

        } else if (debris[_worksID][_debrisID].buyNum > 0) { //涨价
            lastPrice = debris[_worksID][_debrisID].lastPrice.mul(increaseRatio) / 100;
        } else {
            lastPrice = debris[_worksID][_debrisID].initPrice; //碎片第一次被购买，不降不涨
        }

        return lastPrice;
    }

    //返回碎片状态信息 专供游戏主页
    function getDebrisStatus(bytes32 _worksID, uint8 _debrisID) external view returns (uint256[4] memory, uint256, uint256, bytes32)  {
        uint256 gap = 0;
        uint256 status = 0; //碎片状态：0首发购买中，1保护中，2降价中

        if(this.isProtect(_worksID, _debrisID)) { //保护中
            gap = rules[_worksID].protectGap;
            status = 1;
        } else { //降价中

            if(debris[_worksID][_debrisID].lastTime.add(rules[_worksID].discountGap) > now) {
                gap = rules[_worksID].discountGap; //在第一个降价期
            } else {
                uint256 n = (now.sub(debris[_worksID][_debrisID].lastTime)) / rules[_worksID].discountGap; 
                if((now.sub(debris[_worksID][_debrisID].lastTime.add(rules[_worksID].discountGap))) % rules[_worksID].discountGap > 0) { 
                    n = n.add(1);
                }
                gap = rules[_worksID].discountGap.mul(n); //无限降价期时 n倍间隔时长
            }
            status = 2;

        }
        uint256 price = this.getDebrisPrice(_worksID, _debrisID);
        bytes32 lastUnionID = bytes32(debris[_worksID][_debrisID].lastUnionID);
        uint256[4] memory state = [status, debris[_worksID][_debrisID].lastTime, gap, now];
        //返回：[碎片状态，最后交易时间戳，时间间隔，最新时间戳]，当前价格，被交易次数，碎片归属
        return (state, price, debris[_worksID][_debrisID].buyNum, lastUnionID);
    }

    //获取碎片的初始价格
    function getInitPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        return debris[_worksID][_debrisID].initPrice;
    }

    //获取碎片的最后被交易的价格
    function getLastPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        return debris[_worksID][_debrisID].lastPrice;
    }

    //获取碎片的最后购买者address
    function getLastBuyer(bytes32 _worksID, uint8 _debrisID) external view returns(address) {
        return debris[_worksID][_debrisID].lastBuyer;
    }

    //获取碎片的最后购买者unionID
    function getLastUnionId(bytes32 _worksID, uint8 _debrisID) external view returns(bytes32) {
        return debris[_worksID][_debrisID].lastUnionID;
    }

    //获取玩家账号冻结时间 单位s
    function getFreezeGap(bytes32 _worksID) external view returns(uint256) {
        return rules[_worksID].freezeGap;
    }

    //获取玩家首发购买上限数
    function getFirstBuyLimit(bytes32 _worksID) external view returns(uint256) {
        return rules[_worksID].firstBuyLimit;
    }

    //获取作品对应的艺术家ID
    function getArtistId(bytes32 _worksID) external view returns(bytes32) {
        return works[_worksID].artistID;
    }

    //获取作品分割的碎片数
    function getDebrisNum(bytes32 _worksID) external view returns(uint8) {
        return works[_worksID].debrisNum;
    }

    //获取首发购买分配百分比分子 返回数组
    function getAllot(bytes32 _worksID, uint8 _flag) external view returns(uint8[3] memory) {
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
    function getAllot(bytes32 _worksID, uint8 _flag, uint8 _element) external view returns(uint8) {
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
    function getStartHourglass(bytes32 _worksID) external view returns(uint256) {
        if(works[_worksID].beginTime > 0 && works[_worksID].beginTime > now ) {
            return works[_worksID].beginTime.sub(now);
        }
        return 0;
    }

    //获取作品状态 用于判断是否开始、开始倒计时、是否结束、结束后作品最终归属谁
    function getWorksStatus(bytes32 _worksID) external view returns (uint256, uint256, uint256, bytes32) {
        return (works[_worksID].beginTime, works[_worksID].endTime, now, works[_worksID].lastUnionID);
    }

    //获取碎片保护期倒计时 单位s
    function getProtectHourglass(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        if(
            debris[_worksID][_debrisID].lastTime > 0 && 
            debris[_worksID][_debrisID].lastTime.add(rules[_worksID].protectGap) > now
        ) {
            return debris[_worksID][_debrisID].lastTime.add(rules[_worksID].protectGap).sub(now);
        }
        return 0;
    }

    //获取碎片降价倒计时 单位s 无限个倒计时段 过了第一个倒计时段 进入下一个倒计时段...
    function getDiscountHourglass(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
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
        debris[_worksID][_debrisID].lastTime = now; //更新最后被交易时间
        emit OnUpdateDebris(_worksID, _debrisID, _unionID, _sender);
    }

    //更新作品碎片的首发购买者
    function updateFirstBuyer(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address payable _sender) external onlyDev() {
        debris[_worksID][_debrisID].firstBuyer = _sender;
        debris[_worksID][_debrisID].firstUnionID = _unionID;
        emit OnUpdateFirstBuyer(_worksID, _debrisID, _unionID, _sender);
    }

    //更新作品碎片被购买的次数
    function updateBuyNum(bytes32 _worksID, uint8 _debrisID) external onlyDev() {
        debris[_worksID][_debrisID].buyNum = debris[_worksID][_debrisID].buyNum.add(1); //更新碎片被购买次数
        emit OnUpdateBuyNum(_worksID, _debrisID);
    }

    //更新作品碎片游戏结束时间、游戏完成者
    function finish(bytes32 _worksID, bytes32 _unionID) external onlyDev() {
        works[_worksID].endTime = now;
        works[_worksID].lastUnionID = _unionID;
        emit OnFinish(_worksID, _unionID, now);
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
    function getFoundAddress() external view returns (address payable);

    //查询奖池实际余额 仅开发者、合约地址可操作
    function balances() external view returns (uint256);

}


/**
 * @title PuzzleBID Game 平台合约
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
contract Platform {

    using SafeMath for *;

    address payable private foundAddress; //基金会address
    TeamInterface private team; //实例化管理员团队合约，正式发布时可定义成常量

    constructor(address payable _foundAddress, address _teamAddress) public {
        require(
            _foundAddress != address(0) &&
            _teamAddress != address(0)
        );
        foundAddress = _foundAddress;
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
    event OnUpdateFoundAddress(address indexed _sender, address indexed _address);
    event OnTransferTo(address indexed _receiver, uint256 _amount);

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
    function updateFoundAddress(address payable _foundAddress) external onlyAdmin() {
        foundAddress = _foundAddress;
        emit OnUpdateFoundAddress(msg.sender, _foundAddress);
    }

    //平台合约代为保管奖池中的ETH
    function deposit(bytes32 _worksID) external payable {
        require(_worksID != bytes32(0)); 
        emit OnDeposit(_worksID, msg.sender, msg.value);
    }

    //从奖池中转账ETH到指定address
    function transferTo(address payable _receiver, uint256 _amount) external onlyDev() {
        require(_amount <= address(this).balance);
        _receiver.transfer(_amount);
        emit OnTransferTo(_receiver, _amount);
    }

    //获取基金会address
    function getFoundAddress() external view returns (address payable) {
        return foundAddress;
    }

    //查询奖池实际余额 仅开发者、合约地址可操作
    function balances() external view onlyDev() returns (uint256) {
        return address(this).balance;
    }

}


/**
 * @title PuzzleBID Game 玩家合约接口
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
interface PlayerInterface {

    //是否存在这个address   address存在则被认为是老用户
    function hasAddress(address _address) external view returns (bool);

    //是否存在这个unionID unionID存在则被认为是老用户
    function hasUnionId(bytes32 _unionID) external view returns (bool);

    //根据unionID查询玩家信息
    function getInfoByUnionId(bytes32 _unionID) external view returns (address payable, bytes32, uint256);

    //根据玩家address查询unionID
    function getUnionIdByAddress(address _address) external view returns (bytes32);

    //玩家账号是否处于冻结期 true为处在冻结期
    function isFreeze(bytes32 _unionID, bytes32 _worksID) external view returns (bool);

    //获取玩家已经购买首发数
    function getFirstBuyNum(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    //获取玩家对作品碎片的二次购买累计金额
    function getSecondAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    //获取玩家对作品的首发投入累计
    function getFirstAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    //获取玩家最近使用的address
    function getLastAddress(bytes32 _unionID) external view returns (address payable);

    //获取玩家对作品的累计奖励
    function getRewardAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    //获取玩家账号冻结倒计时
    function getFreezeHourglass(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    //获取玩家账号冻结开始时间、冻结时长、当前时间
    function getFreezeTimestamp(bytes32 _unionID, bytes32 _worksID) external view returns (uint256, uint256, uint256);

    //获取我的藏品列表
    function getMyWorks(bytes32 _unionID) external view returns (address, bytes32, uint256, uint256, uint256);

    //是否为合法绑定关系的玩家 避免address被多个unionID绑定 true为合法
    function isLegalPlayer(bytes32 _unionID, address _address) external view returns (bool);

    //注册玩家 静默
    function register(bytes32 _unionID, address payable _address, bytes32 _worksID, bytes32 _referrer) external returns (bool);

    //更新玩家最近使用的address
    function updateLastAddress(bytes32 _unionID, address payable _sender) external;

    //更新玩家对作品碎片的最后购买时间
    function updateLastTime(bytes32 _unionID, bytes32 _worksID) external;

    //更新玩家对作品碎片的首发购买累计
    function updateFirstBuyNum(bytes32 _unionID, bytes32 _worksID) external;

    //更新玩家对作品碎片的二次购买累计金额
    function updateSecondAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    //更新玩家对作品的首轮投入累计
    function updateFirstAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    //更新玩家获得作品的累计奖励
    function updateRewardAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    //更新我的藏品列表 记录完成游戏时的address
    function updateMyWorks(
        bytes32 _unionID, 
        address _address, 
        bytes32 _worksID, 
        uint256 _totalInput, 
        uint256 _totalOutput
    ) external;


}


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
    function getInfoByUnionId(bytes32 _unionID) external view returns (address payable, bytes32, uint256) {
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
    function getFreezeHourglass(bytes32 _unionID, bytes32 _worksID) external view returns(uint256) {
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
        if(this.hasUnionId(_unionID) == false) {
            playersUnionIdSets.push(_unionID);
            playerCount[_unionID][_worksID] = Datasets.PlayerCount(0, 0, 0, 0, 0); //初始化玩家单元统计数据
        }

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


/**
 * @title PuzzleBID Game 主合约
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
contract PuzzleBID {

    using SafeMath for *;

    string constant public name = "PuzzleBID Game";
    string constant public symbol = "PZB";

    TeamInterface private team; //实例化管理员团队合约，正式发布时可定义成常量
    PlatformInterface private platform; //实例化平台合约
    ArtistInterface private artist; //实例化艺术家合约
    WorksInterface private works; //实例化作品碎片合约
    PlayerInterface private player; //实例化玩家合约
    
    
    //初始化 接入各子合约
    constructor(
        address _teamAddress,
        address _platformAddress,
        address _artistAddress,
        address _worksAddress,
        address _playerAddress
    ) public {
        team = TeamInterface(_teamAddress);
        platform = PlatformInterface(_platformAddress);
        artist = ArtistInterface(_artistAddress);
        works = WorksInterface(_worksAddress);
        player = PlayerInterface(_playerAddress);

    }  

    //不接收ETH，startPlay接管
    function() external payable {
        revert();
    }

    //玩家不能是合约地址
    modifier isHuman() {
        address _address = msg.sender;
        uint256 _size;

        assembly {_size := extcodesize(_address)}
        require(_size == 0, "sorry humans only");
        _;
    }

    //游戏前检查
    modifier checkPlay(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID) {
        //检查支付，最小0.000000001ETH，最大100000ETH
        require(msg.value >= 1000000000);
        require(msg.value <= 100000000000000000000000);

        //检查该作品碎片能不能被买
        require(works.hasWorks(_worksID)); //检查该作品游戏是否存在
        require(works.hasDebris(_worksID, _debrisID)); //检查该作品碎片是否存在
        require(works.isGameOver(_worksID) == false); //检查游戏是否已结束
        require(works.isPublish(_worksID) && works.isStart(_worksID)); //检查该作品游戏是否发布并开始
        require(works.isProtect(_worksID, _debrisID) == false); //检查该作品碎片是否在30分钟保护期内
        
        //检查玩家能不能买该作品碎片 
        require(player.isFreeze(_unionID, _worksID) == false); //检查同一作品同一玩家是否超过5分钟冻结期
        if(player.getFirstBuyNum(_unionID, _worksID).add(1) > works.getFirstBuyLimit(_worksID)) {
            require(works.isSecond(_worksID, _debrisID));
        } //检查是否达到首发购买上限、该作品碎片是否为二手交易        
        require(msg.value >= works.getDebrisPrice(_worksID, _debrisID)); //检查支付的ETH够不够？
        _;
    }    

    //开始游戏 游戏入口
    function startPlay(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, bytes32 _referrer) 
        isHuman()
        checkPlay(_worksID, _debrisID, _unionID)
        external
        payable
    {
        player.register(_unionID, msg.sender, _worksID, _referrer); //静默注册

        uint256 lastPrice = works.getLastPrice(_worksID, _debrisID); //获取碎片的最后被交易的价格  

        bytes32 lastUnionID = works.getLastUnionId(_worksID, _debrisID); //获取碎片的最后玩家ID  

        works.updateDebris(_worksID, _debrisID, _unionID, msg.sender); //更新碎片：价格、归属、被购买次数

        player.updateLastTime(_unionID, _worksID); //更新玩家在一个作品中的最后购买碎片时间
        
        platform.updateTurnover(_worksID, msg.value); //更新作品的交易额

        platform.updateAllTurnover(msg.value); //更新平台总交易额
        
        //分红业务
        if(works.isSecond(_worksID, _debrisID)) { 
            //碎片如果是被玩家再次购买，按再次规则
            secondPlay(_worksID, _debrisID, _unionID, lastUnionID, lastPrice);            
        } else { 
            //更新碎片被购买次数
            works.updateBuyNum(_worksID, _debrisID);
            //碎片如果是被玩家第一次购买，按首发规则
            firstPlay(_worksID, _debrisID, _unionID);       
        }
        //碎片如果被同一玩家收集完成，结束游戏
        if(works.isFinish(_worksID, _unionID)) {
            works.finish(_worksID, _unionID); //更新作品游戏结束时间
            finishGame(_worksID); //游戏收尾
            collectWorks(_worksID, _unionID); //我的藏品
        }

    }

    //碎片被首发购买
    function firstPlay(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID) private {
                
        works.updateFirstBuyer(_worksID, _debrisID, _unionID, msg.sender); //更新当前作品碎片首发购买名单       
        player.updateFirstBuyNum(_unionID, _worksID); //更新同一作品同一玩家首发购买数
        player.updateFirstAmount(_unionID, _worksID, msg.value); //更新同一作品同一玩家的首发购买投入
        
        //分配并转账
        uint8[3] memory firstAllot = works.getAllot(_worksID, 0); //首发购买分配百分比 0-首发 1-再次 2-最后
        artist.getAddress(works.getArtistId(_worksID)).transfer(msg.value.mul(firstAllot[0]) / 100); //销售价的80% 归艺术家
        platform.getFoundAddress().transfer(msg.value.mul(firstAllot[1]) / 100); //销售价的2% 归平台

        works.updatePools(_worksID, msg.value.mul(firstAllot[2]) / 100); //销售价的18% 归奖池
        platform.deposit.value(msg.value.mul(firstAllot[2]) / 100)(_worksID); //平台合约代为保管奖池ETH

    }

    //碎片被二次购买
    function secondPlay(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, bytes32 _oldUnionID, uint256 _oldPrice) private {

        //更新当前作品的再次购买者名单
        if(0 == player.getSecondAmount(_unionID, _worksID)) {
            works.updateSecondUnionId(_worksID, _unionID);
        }

        //更新同一作品同一玩家的再次购买投入
        player.updateSecondAmount(_unionID, _worksID, msg.value);
             
        uint256 lastPrice = works.getDebrisPrice(_worksID, _debrisID);        
        //有溢价才分红
        if(lastPrice > _oldPrice) { 
            uint8[3] memory againAllot = works.getAllot(_worksID, 1);
            uint256 overflow = lastPrice.sub(_oldPrice); //计算溢价
            artist.getAddress(works.getArtistId(_worksID)).transfer(overflow.mul(againAllot[0]) / 100); //溢价的10% 归艺术家
            platform.getFoundAddress().transfer(lastPrice.mul(againAllot[1]) / 100); //总价的2% 归平台
            works.updatePools(_worksID, overflow.mul(againAllot[2]) / 100); //溢价的18% 归奖池
            platform.deposit.value(overflow.mul(againAllot[2]) / 100)(_worksID); //溢价的10% 平台合约代为保管奖池ETH

            player.getLastAddress(works.getLastUnionId(_worksID, _debrisID)).transfer(
                lastPrice.sub(overflow.mul(againAllot[0]) / 100)
                .sub(lastPrice.mul(againAllot[1]) / 100)
                .sub(overflow.mul(againAllot[2]) / 100)
            ); //剩余部分归上一买家
        } 
        //无溢价，把此次降价后的ETH全额转给上一买家
        else { 
            player.getLastAddress(_oldUnionID).transfer(lastPrice);
        }

    }

    //完成游戏
    function finishGame(bytes32 _worksID) private {              
        //收集碎片完成，按最后规则
        uint8 lastAllot = works.getAllot(_worksID, 2, 0);
        platform.transferTo(msg.sender, works.getPools(_worksID).mul(lastAllot) / 100); //当前作品奖池的80% 最后一次购买者 平台合约代为发放奖池中的ETH
        firstSend(_worksID); //首发玩家统计发放
        secondSend(_worksID); //后续玩家统计发放
    }

    //处理成我的藏品
    function collectWorks(bytes32 _worksID, bytes32 _unionID) private {
        player.updateMyWorks(_unionID, msg.sender, _worksID, 0, 0);
    }
    
    //首发玩家统计发放
    function firstSend(bytes32 _worksID) private {
        uint8 i;
        bytes32[] memory tmpFirstUnionId = works.getFirstUnionId(_worksID); //首发玩家名单
        address tmpAddress; //玩家最近使用的address
        uint256 tmpAmount; //首发玩家应得分红
        uint8 lastAllot = works.getAllot(_worksID, 2, 1);
        for(i=0; i<tmpFirstUnionId.length; i++) {
            tmpAddress = player.getLastAddress(tmpFirstUnionId[i]);
            tmpAmount = player.getFirstAmount(tmpFirstUnionId[i], _worksID); //玩家首发投入累计
            //应得分红 = 作品对应的奖池 * 10% * (玩家首发投入累计 / 作品初始价格即首发总投入)
            tmpAmount = works.getPools(_worksID).mul(lastAllot).mul(tmpAmount) / 100 / works.getPrice(_worksID);
            platform.transferTo(tmpAddress, tmpAmount); //平台合约代为发放奖池中的ETH
        }
    }
    
    //后续玩家统计发放
    function secondSend(bytes32 _worksID) private {
        uint8 i;
        bytes32[] memory tmpSecondUnionId = works.getSecondUnionId(_worksID); //二次购买玩家名单
        address tmpAddress; //玩家最近使用的address
        uint256 tmpAmount; //二次玩家应得分红
        uint8 lastAllot = works.getAllot(_worksID, 2, 2);
        for(i=0; i<tmpSecondUnionId.length; i++) {
            tmpAddress = player.getLastAddress(tmpSecondUnionId[i]);
            tmpAmount = player.getSecondAmount(tmpSecondUnionId[i], _worksID); //玩家二次投入累计
            //应得分红 = 作品对应的奖池 * 10% * (玩家二次投入累计 / 作品二次总投入)
            //作品二次总投入 = 作品的总交易额 - 作品初始价格即首发总投入
            tmpAmount = works.getPools(_worksID).mul(lastAllot).mul(tmpAmount) / 100 / (platform.getTurnover(_worksID).sub(works.getPrice(_worksID)));
            platform.transferTo(tmpAddress, tmpAmount); //平台合约代为发放奖池中的ETH
        }
    }

    //获取游戏当前最新时间
    function getNowTime() external view returns (uint256) {
        return now;
    }

 }
 
 
