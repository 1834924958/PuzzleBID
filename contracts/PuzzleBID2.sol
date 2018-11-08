pragma solidity ^0.4.24;

/**
 * @title PuzzleBID
 * @website http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 */

/**
 * @dev PuzzleBID data structure
 */
library PZB_Datasets {

    //作品结构
    struct Works {
        uint256 worksID; //作品ID
        uint256 artistID; //归属艺术家ID
        uint8 debrisNum; //分割成游戏碎片总数
        uint256 price; //价格
        uint256 beginTime; //开售时间
        uint256 endTime; //中止出售时间
        bool isPublish; //是否上架
        address tokenID; //对应ERC721
        uint8 firstBuyLimit; //首发最多能购买碎片数
    }

    //碎片结构
    struct Debris {
        uint8 debrisID; //碎片ID
        uint256 worksID; //作品ID
        uint256 initPrice; //初始价格
        uint256 lastPrice; //最新价格
        uint256 buyNum; //被交易总次数
        address firstBuyer; //首发购买者，冗余
        address lastBuyer; //最后一次购买者，冗余
        uint256 lastTime; //最后一次被购买时间
    }

    //艺术家结构
    struct Artist {
        uint256 artistID; //艺术家ID
        address ethAddress; //钱包地址
    }

    //玩家结构
    struct Player {
        address ethAddress; //玩家钱包地址
        uint256 unionID; //唯一父级ID 可以是md5(手机+名字)  
        address referrer; //推荐人钱包地址
        uint256 time; //创建时间
    }

    //作品与奖池关系结构
    struct Pot {
        uint256 worksID; //作品ID
        uint256 totalAmount; //总金额
    }

    //碎片交易记录结构    
    struct Transaction {        
        uint256 worksID; //作品ID
        uint256 debrisID; //碎片ID
        uint256 artistID; //艺术家ID
        uint256 dealPrice; //成交价格，ETH
        address fromAddress; //从地址
        address toAddress; //到地址
        uint256 time; //创建时间
    }

    //玩家与藏品关系结构
    struct MyWorks { 
        address playerAddress; //玩家ID
        uint256 worksID; //碎片ID
        uint256 totalInput; //累计投入
        uint256 totalOutput; //累计回报
        uint256 time; //创建时间
    }

    //玩家对作品购买行为的单元统计
    struct unitCount {
        uint256 lastTime; //同一作品同一玩家，最后一次购买时间
        uint256 firstBuyNum; //同一作品同一玩家，首发购买碎片数小计
        mapping(uint256 => uint256) debrisID; //同一作品同一玩家，购买的碎片号，用于判断是否完成了游戏
        uint256 secondAmount; //二手购买总计
    }

}

/**
 * @dev PuzzleBID events
 */
contract PZB_Events {

    event OnRegisterPlayer(
        address indexed ethAddress,
        uint256 unionID, 
        address indexed referrer,
        uint256 time); //当注册玩家时

    event OnAddWorks(
        uint256 worksID, 
        uint256 artistID, 
        uint8 debrisNum, 
        uint256 price, 
        uint256 beginTime, 
        bool isPublish, 
        address tokenID,
        uint8 firstBuyLimit); //当发布作品时

    event OnAddDebris(
        uint256 worksID,
        uint8 debrisNum,
        uint256 initPrice); //当发布作品并添加碎片时

    event OnAddArtist(
        uint256 _artistID,
        address _artistAddress); //当添加艺术家时
        
    event OnTransaction(); //当玩家交易时
    event OnWithdraw(); //当提现时
    event OnUpdatePot(); //当更新总奖池时
    event OnUpdateWorksPot(); //当更新作品奖池时
    event OnUpdateMyWorks(); //当更新作品奖池时
}

/**
 * @dev PuzzleBID Game Contract
 * @author Simon<vsiryxm@163.com>
 */
contract PuzzleBID is PZB_Events {
    using SafeMath for *;

    //=========================================================================
    //| Game config
    //=========================================================================
    string constant public name = "PuzzleBID Game";
    string constant public symbol = "PZD";
    address puzzlebidAddress; //平台钱包地址
    uint256 constant private freezeTime = 300 seconds; //玩家购买一个作品中的一个碎片后冻结5分钟
    uint256 constant private protectTime = 1800 seconds; //碎片保护时间30分钟
    uint256 constant private increaseRatio = 110; //% 碎片价格调整为上一次价格的110%
    uint256 constant private discountTime = 3600 seconds; //碎片开始打折时间，被购买1小时后    
    uint256 constant private discountRatio = 95; //% 碎片价格调整为首发价格的95%

    //=========================================================================
    //| Dividend rule
    //=========================================================================
    uint8[3] firstAllot = [80, 2, 18]; //% 首发购买分配百分比 顺序对应艺术家、平台、奖池
    uint8[3] againAllot = [10, 2, 65]; //% 再次购买分配百分比 艺术家（溢价部分）、平台（总价）、奖池（溢价部分）
    uint8[3] lastAllot = [80, 10, 10]; //% 完成购买分配百分比 游戏完成者、首发购买者、后续其他购买者

    //=========================================================================
    //| Game data 
    //=========================================================================
    mapping(address => PZB_Datasets.Player) public players; //游戏玩家
    //mapping(uint256 => mapping(uint256 => PZB_Datasets.Player)) public union_players; //一个手机号码对应多个玩家钱包 如md5(手机号码) => Player 
    mapping(uint256 => PZB_Datasets.Works) public works; //作品列表 如(worksID => PZB_Datasets.Works)
    mapping(uint256 => mapping(uint8 => PZB_Datasets.Debris)) public debris; //作品碎片列表 如(worksID => (1 => PZB_Datasets.Debris))
    mapping(uint256 => PZB_Datasets.Artist) public artists; //通过艺术家检索作品 如(artistID => PZB_Datasets.Artist)

    mapping(uint256 => uint256) public pots; //各作品奖池 如(worksID => totalAmount)
    mapping(uint256 => PZB_Datasets.Transaction) public transactions; //交易记录列表
    mapping(address => mapping(uint256 => PZB_Datasets.MyWorks)) public myworks; //我的藏品列表 (playerAddress => (worksID => PZB_Datasets.MyWorks))
    uint256 public turnover; //所有作品的总交易额
    mapping(uint256 => uint256) worksTurnover; //每个作品的累计交易额 如(worksID => amount) 
    mapping(uint256 => address) secondAddress; //每个作品的再次购买玩家名单 如(worksID => playerAddress)

    //玩家购买记录检索表
    mapping(address => mapping(uint256 => PZB_Datasets.unitCount)) playerBuy; // 如(player => (worksID => PZB_Datasets.unitCount))
    
    constructor(address _platform) public {
        puzzlebidAddress = _platform; //游戏平台钱包地址
    }

    //=========================================================================
    //| Player initialization 
    //=========================================================================
    modifier isRegisteredGame()
    {
        require(players[msg.sender].time != 0);
        _;
    }

    //注册游戏玩家
    function registerPlayer(uint256 _unionID, address _referrer) external {
        require(players[msg.sender].time == 0);
        require(_referrer != address(0));
        uint256 _now = now;
        players[msg.sender] = PZB_Datasets.Player(msg.sender, _unionID, _referrer, _now);
        //union_players[_unionID].push(players[msg.sender]); //属同一个用户塞一个篮子
        emit OnRegisterPlayer(msg.sender, _unionID, _referrer, _now);
    }

    //=========================================================================
    //| Game initialization
    //=========================================================================
    //添加一局游戏 管理员操作
    function addGame(
        uint256 _worksID,
        uint256 _artistID, 
        uint8 _debrisNum, 
        uint256 _price, 
        uint256 _beginTime, 
        address _tokenID,
        address _artistAddress,
        uint8 _firstBuyLimit) public {

        //require(works[_worksID] == 0);
        //require(artists[_artistID] == 0);
        require(_debrisNum >= 2 && _debrisNum < 256);
        require(_price > 0);   
        require(_beginTime > 0 && _beginTime > now); 
        
        uint256 i;
        
        works[_worksID] = PZB_Datasets.Works(
            _worksID, 
            _artistID, 
            _debrisNum, 
            _price, 
            _beginTime, 
            0,
            false, 
            _tokenID,
            _firstBuyLimit);  //添加作品  

        emit OnAddWorks(
            _worksID,
            _artistID, 
            _debrisNum, 
            _price, 
            _beginTime,
            false,
            _tokenID,
            _firstBuyLimit);  //添加作品事件  

        //初始化作品碎片
        
        uint256 initPrice = _price / _debrisNum;
        for(i=1; i<=_debrisNum; i++) {
            debris[_worksID][uint8(i)].worksID = _worksID;
            debris[_worksID][uint8(i)].initPrice = initPrice;
        } 

        emit OnAddDebris(
            _worksID,
            _debrisNum,
            initPrice
        ); //添加作品碎片事件

        //初始化艺术家
        artists[_artistID] = PZB_Datasets.Artist(_artistID, _artistAddress);

        emit OnAddArtist(_artistID, _artistAddress); //添加艺术家事件

        pots[_worksID] = 0; //初始化该作品奖池       

    }

    //发布游戏 管理员操作
    function publishGame(uint256 _worksID, uint256 _beginTime) external {
        require(works[_worksID].beginTime != 0 && !works[_worksID].isPublish);
        if(_beginTime > 0) {
            works[_worksID].beginTime = _beginTime;
        }
        works[_worksID].isPublish = true; //开启这个游戏
    }

    //=========================================================================
    //| Game business
    //=========================================================================

    /**
     * @dev prevents contracts from interacting with PuzzleBID 
     */
    modifier isHuman() {
        address _address = msg.sender;
        uint256 _size;

        assembly {_size := extcodesize(_address)}
        require(_size == 0, "sorry humans only");
        _;
    }

    /**
     * @dev sets boundaries for incoming tx
     * 支付最小0.000000001ETH，最大100000ETH
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000);
        require(_eth <= 100000000000000000000000);
        _;    
    }

    /**
     * @dev emergency buy uses last stored affiliate ID and team snek
     */
    function()
        public
        payable
    {
        revert();
        //buyCore(uint256 _worksID, uint8 _debrisID);
    }

    function buyCore(uint256 _worksID, uint8 _debrisID) 
        isHuman()
        isWithinLimits(msg.value)
        isRegisteredGame()
        public
        payable
    {
        uint256 _now = now; //记录当前时间
        uint256 i; //循环变量

        //检查该作品碎片能不能被买
        require(works[_worksID].beginTime != 0); //检查该作品游戏是否存在
        require(debris[_worksID][_debrisID].initPrice != 0); //检查该作品碎片是否存在
        require(works[_worksID].isPublish && works[_worksID].beginTime <= _now); //检查该作品游戏是否发布并开始
        require(works[_worksID].endTime == 0); //检查该作品游戏是否已结束
        require(debris[_worksID][_debrisID].lastTime.add(protectTime) < _now); //检查该作品碎片是否在30分钟保护期内
        
        //检查玩家能不能买该作品碎片
        require(playerBuy[msg.sender][_worksID].lastTime.add(freezeTime)  < _now); //检查同一作品同一玩家是否超过5分钟冻结期
        playerBuy[msg.sender][_worksID].lastTime = _now;

        bool isFirstLimit = false; //检查是否达到首发购买限制 true为已经达到
        if(playerBuy[msg.sender][_worksID].firstBuyNum.add(1) > works[_worksID].firstBuyLimit) {
            isFirstLimit = true;
        }
        bool isSecondhand = false; //检查该作品碎片是否为二手交易
        if(debris[_worksID][_debrisID].buyNum > 0) {
            isSecondhand = true;
        }

        require(isFirstLimit && isSecondhand); //限制首发购买超出情况
        
        //更新碎片价格 涨价 or 降价 首发忽略
        uint256 oldPrice = debris[_worksID][_debrisID].lastPrice;
        if(isSecondhand && oldPrice.add(discountTime) < _now) { //降价
            debris[_worksID][_debrisID].lastPrice = oldPrice.mul(discountRatio / 100);
        } else if (isSecondhand) { //涨价
            debris[_worksID][_debrisID].lastPrice = oldPrice.mul(increaseRatio / 100);
        }

        require(msg.value >= debris[_worksID][_debrisID].lastPrice); //支付的ETH够不够？

        //更新统计
        debris[_worksID][_debrisID].lastBuyer = msg.sender; //更新归属
        debris[_worksID][_debrisID].buyNum = debris[_worksID][_debrisID].buyNum.add(1);
        debris[_worksID][_debrisID].lastTime = _now;
        playerBuy[msg.sender][_worksID].lastTime = _now;

        //更新所有作品累计交易额
        turnover = turnover.add(msg.value);

        //更新当前作品的累计交易额
        worksTurnover[_worksID] = worksTurnover[_worksID].add(msg.value);

        //分分分
        if(!isSecondhand) { //如果是首发购买，按首发规则
            playerBuy[msg.sender][_worksID].firstBuyNum = playerBuy[msg.sender][_worksID].firstBuyNum.add(1); //更新同一作品同一玩家首发购买数
            debris[_worksID][_debrisID].firstBuyer = msg.sender;
            artists[works[_worksID].artistID].ethAddress.transfer(msg.value.mul(firstAllot[0]) / 100); //销售价的80% 艺术家
            puzzlebidAddress.transfer(msg.value.mul(firstAllot[1]) / 100); //销售价的2% 平台
            pots[_worksID] = pots[_worksID].add(msg.value.mul(firstAllot[2]) / 100); //销售价的18% 奖池 即当前合约地址            

        } else { 

            debris[_worksID][_debrisID].lastBuyer = msg.sender; //更新当前作品碎片的最后购买者
            
            if(playerBuy[msg.sender][_worksID].secondAmount == 0) { //更新当前作品的再次购买者名单
                secondAddress[_worksID] = msg.sender;
            }
            playerBuy[msg.sender][_worksID].secondAmount = playerBuy[msg.sender][_worksID].secondAmount.add(msg.value); //统计同一作品同一玩家的再次购买投入
            
            //如果是再次购买，按再次规则
            if(debris[_worksID][_debrisID].lastPrice > oldPrice) { //有溢价才分分分
                uint256 overflow = debris[_worksID][_debrisID].lastPrice.sub(oldPrice); //计算溢价

                uint256 income1 = overflow.mul(againAllot[0]) / 100;
                artists[works[_worksID].artistID].ethAddress.transfer(income1); //溢价的10% 艺术家

                uint256 income2  = debris[_worksID][_debrisID].lastPrice.mul(againAllot[1]) / 100;
                puzzlebidAddress.transfer(income2); //总价的2% 平台
                
                uint256 income3 = overflow.mul(againAllot[2]) / 100;
                pots[_worksID] = pots[_worksID].add(income3); //溢价的18% 奖池

                uint256 last = debris[_worksID][_debrisID].lastPrice.sub(income1).sub(income2).sub(income3);
                debris[_worksID][_debrisID].lastBuyer.transfer(last); //剩余部分归上一买家

            } else { //无溢价，把此次打折后的ETH全额转给上一买家
                debris[_worksID][_debrisID].lastBuyer.transfer(debris[_worksID][_debrisID].lastPrice);
            }
            
            //检查是否收集齐了
            bool isFinish = true; //游戏完成标志
            i = 1;
            while(i<=works[_worksID].debrisNum) {
                if(debris[_worksID][_debrisID].lastBuyer != msg.sender) {
                    isFinish = false;
                    break;
                }
                i++;
            }
            if(isFinish) { //游戏结束
                works[_worksID].endTime = _now; //更新作品游戏结束时间
                //如果收集碎片完成，按最后规则
                msg.sender.transfer(pots[_worksID].mul(lastAllot[0] / 100)); //当前作品奖池的80% 最后一次购买者

                //首发玩家统计发放
                mapping(address => uint256) tmp;
                address[] firstAddress;
                for(i=1; i<works[_worksID].debrisNum; i++) {
                    if(tmp[debris[_worksID][_debrisID].lastBuyer] == 0 ) {
                        firstAddress.push(debris[_worksID][_debrisID].lastBuyer);
                    }
                    tmp[debris[_worksID][_debrisID].lastBuyer] = tmp[debris[_worksID][_debrisID].lastBuyer] + debris[_worksID][_debrisID].initPrice;
                }
                for(i=0; i<firstAddress.length; i++) {
                    firstAddress[i].transfer((pots[_worksID].mul(lastAllot[1]) / 100).mul(tmp[firstAddress[i]]) / works[_worksID].price);
                }

                //后续玩家统计发放
                address[] memory tmpAddress = secondAddress[_worksID];
                for(i=0; i<=tmpAddress.length; i++) {
                    tmpAddress[i].transfer((pots[_worksID].mul(lastAllot[1]) / 100).mul(playerBuy[tmpAddress[i]][_worksID].secondAmount) / worksTurnover[_worksID].sub(works[_worksID].price));
                }
                
                //处理成我的藏品
                myworks[msg.sender][_worksID] = PZB_Datasets.MyWorks(msg.sender, _worksID, 0, 0, _now);
            }            

        }

    }


 }

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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable 
{
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
  
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable 
{
  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpauseunpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }

}
