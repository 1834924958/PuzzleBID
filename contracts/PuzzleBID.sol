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
        bytes32 worksID; //作品ID
        bytes32 artistID; //归属艺术家ID
        uint8 debrisNum; //分割成游戏碎片总数
        uint8 price; //价格
        uint256 beginTime; //开售时间
        uint256 endTime; //中止出售时间
        bool isPublish; //是否上架
        address tokenID; //对应ERC721
    }

    //碎片结构
    struct Debris {
        uint8 debrisID; //碎片ID
        bytes32 worksID; //作品ID
        uint256 initPrice; //初始价格
        uint256 lastPrice; //最新价格
        uint256 buyNum; //被交易总次数
        address firstBuyer; //首发购买者，冗余
        address lastBuyer; //最后一次购买者，冗余
        uint256 lastTime; //最后一次被购买时间
    }

    //艺术家结构
    struct Artist {
        bytes32 artistID; //艺术家ID
        address ethAddress; //钱包地址
    }

    //玩家结构
    struct Player {
        address ethAddress; //玩家钱包地址
        bytes32 unionID; //唯一父级ID 可以是md5(手机+名字)  
        address referrer; //推荐人钱包地址
        uint256 time; //创建时间
    }

    //作品与奖池关系结构
    struct Pot {
        bytes32 worksID; //作品ID
        uint256 totalAmount; //总金额
    }

    //碎片交易记录结构    
    struct Transaction {        
        bytes32 worksID; //作品ID
        bytes32 debrisID; //碎片ID
        uint256 artistID; //艺术家ID
        uint256 dealPrice; //成交价格，ETH
        address fromAddress; //从地址
        address toAddress; //到地址
        uint256 time; //创建时间
    }

    //玩家与藏品关系结构
    struct MyWorks { 
        address playerAddress; //玩家ID
        bytes32 worksID; //碎片ID
        uint256 totalInput; //累计投入
        uint256 totalOutput; //累计回报
        uint256 time; //创建时间
    }

    //分配规则
    struct Divies { 
        address playerAddress; //玩家ID
        bytes32 worksID; //碎片ID
        uint256 totalInput; //累计投入
        uint256 totalOutput; //累计回报
        uint256 time; //创建时间
    }

}

/**
 * @dev PuzzleBID events
 */
contract PZB_Events {

    event OnRegisterPlayer(
        address indexed ethAddress,
        bytes32 unionID, 
        address indexed referrer,
        uint256 time); //当注册玩家时

    event OnAddWorks(
        bytes32 worksID, 
        string artistID, 
        uint8 debrisNum, 
        uint256 price, 
        uint256 beginTime, 
        bool isPublish, 
        address tokenID); //当发布作品时

    event OnAddDebris(
        bytes32 worksID,
        uint8 debrisNum,
        uint256 initPrice); //当发布作品并添加碎片时

    event OnAddArtist(
        bytes32 _artistID,
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
contract PuzzleBID is PZB_Events,Pausable {
    using SafeMath for *;

    //=========================================================================
    //| Game config
    //=========================================================================
    string constant public name = "PuzzleBID Game";
    string constant public symbol = "PZD";
    uint8 constant private maxDebris = 9; //作品被分割成最大碎片数
    uint8 constant private firstBuyNum = maxDebris.mul(1/3); //首发最多能购买一个作品的碎片数
    uint256 constant private freezeTime = 300 seconds; //玩家购买一个作品中的一个碎片后冻结5分钟
    uint256 constant private protectTime = 1800 seconds; //碎片保护时间30分钟
    uint256 constant private increaseRatio = 110; //% 碎片价格调整为上一次价格的110%
    uint256 constant private discountTime = 3600 seconds; //碎片开始打折时间，被购买1小时后    
    uint256 constant private discountRatio = 95; //% 碎片价格调整为首发价格的95%

    //=========================================================================
    //| Dividend rule
    //=========================================================================
    uint8[3] firstAllot = [80, 2, 18]; //% 首发购买分配百分比 顺序对应艺术家、平台、奖池
    uint8[3] againAllot = [10, 2, 65]; //% 再次购买分配百分比 后续购买者、平台、奖池
    uint8[3] lastAllot = [80, 10, 10]; //% 完成购买分配百分比 游戏完成者、首发购买者、后续其他购买者

    //=========================================================================
    //| Game data 
    //=========================================================================
    mapping(address => PZB_Datasets.Player) public players; //游戏玩家列
    mapping(bytes32 => mapping(uint256 => PZB_Datasets.Player)) public union_players; //一个手机号码对应多个玩家钱包 比如 md5(手机号码) => Player 
    mapping(bytes32 => PZB_Datasets.Works) public works; //作品列
    mapping(bytes32 => mapping(uint8 => PZB_Datasets.Debris)) public debris; //作品碎片列 (worksID => (1 => PZB_Datasets.Debris))
    mapping(bytes32 => PZB_Datasets.Artist) public artists; //通过艺术家检索作品

    mapping(bytes32 => totalAmount) public pots; //各作品奖池 (worksID => totalAmount)
    mapping(uint256 => PZB_Datasets.Transaction) public transactions; //交易记录列
    mapping(uint256 => PZB_Datasets.MyWorks) public myworks; //我的藏品列
    uint256 turnover; //游戏总交易额  

    //=========================================================================
    //| Player initialization 
    //=========================================================================
    modifier isRegisteredGame()
    {
        require(players[msg.sender] != 0);
        _;
    }

    //注册游戏玩家
    function registerPlayer(bytes32 _unionID, address _referrer) external {
        require(players[msg.sender] == 0);
        require(_referrer != address(0));
        uint256 _now = now;
        players[msg.sender] = PZB_Datasets.Player(_ethAddress, _unionID, _referrer, _now);
        union_players[_unionID].push(players[msg.sender]); //属同一个用户塞一个篮子
        emit OnRegisterPlayer(_ethAddress, _unionID, _referrer, _now);
    }

    //=========================================================================
    //| Game initialization
    //=========================================================================
    //添加一局游戏 管理员操作
    function addGame(
        bytes32 _worksID,
        bytes32 _artistID, 
        uint8 _debrisNum, 
        uint256 _price, 
        uint256 _beginTime, 
        address _tokenID,
        bytes32 _artistID,
        address _artistAddress
        ) external {

        require(works[_worksID] == 0, "Existing works~");
        require(artists[_artistID] == 0, "Existing artist~");
        require(_debrisNum >= 2 && _debrisNum <= maxDebris, "Out of range~");
        require(_price > 0, "Must be greater than 0~");   
        require(_beginTime > 0 && _beginTime > now, "Start time format is incorrect~");     
                
        works[_worksID] = PZB_Datasets.Works(
            _worksID, 
            _artistID, 
            _debrisNum, 
            _price, 
            _beginTime, 
            0,
            false, 
            _tokenID);  //添加作品  

        emit OnAddWorks(
            _worksID,
            _artistID, 
            _debrisNum, 
            _price, 
            _beginTime,
            0, 
            false, 
            _tokenID);  //添加作品事件  

        //初始化作品碎片
        uint256 initPrice = _price / _debrisNum;
        for(uint256 i=1; i<=maxDebris; i++) {
            debris[_worksID][i] = PZB_Datasets.Debris(_worksID, initPrice);
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
    function publishGame(bytes32 _worksID, uint256 _beginTime) external {
        require(works[_worksID] != 0 && !works[_worksID].isPublish);
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
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "Calm down, don't stud");
        _;    
    }

    /**
     * @dev emergency buy uses last stored affiliate ID and team snek
     */
    function(bytes32 _workID, uint8 _debrisID)
        isHuman()
        isWithinLimits(msg.value)
        isRegisteredGame()
        public
        payable
    {
        buyCore(bytes32 _workID, uint8 _debrisID);
    }

    function buyCore(bytes32 _workID, uint8 _debrisID) 
        isHuman()
        isWithinLimits(msg.value)
        isRegisteredGame()
        public
        payable
    {
        uint256 _now = now; //记录当前时间
        require(works[_workID] != 0); //检查该作品游戏是否存在
        require(debris[_workID][_debrisID].initPrice != 0); //检查该作品碎片是否存在
        require(works[_workID].isPublish && works[_workID].beginTime <= _now); //检查该作品游戏是否发布并开始
        require(debris[_workID][_debrisID].lastTime + protectTime < _now); //检查作品是否在30分钟保护期内

        //检查玩家是否第一次购买该作品碎片

        require(); //检查玩家购买该作品碎片是否超过1/3限制
        //检查玩家是否在5分钟内再次购买该作品
        
        

        
        //检查当前账号有没有购买行为，如果有，有没有过5分钟

        //涨价 or 降价  支付的够不够？
        
        if(true) { //如果是首发购买，按首发规则

        } else if () { //如果是再次购买，按再次规则

        } else {
            //如果是完成了作品，按最后规则
        }

    }

    /**
     * @dev returns time left.  dont spam this, you'll ddos yourself from your node 
     * provider
     * -functionhash- 0xc7e284b8
     * @return time left in seconds
     */
    function getTimeLeft()
        public
        view
        returns(uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;
        
        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt + rndGap_)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt + rndGap_).sub(_now) );
        else
            return(0);
    }


    /**
     * @dev return the price buyer will pay for next 1 individual key.
     * -functionhash- 0x018a25e8
     * @return price for next key bought (in wei format)
     */
    function getBuyPrice()
        public 
        view 
        returns(uint256)
    {  
        // setup local rID
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;
        
        // are we in a round?
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else // rounds over.  need price for new round
            return ( 75000000000000 ); // init
    }

    /**
     * @dev returns player info based on address.  if no address is given, it will 
     * use msg.sender 
     * -functionhash- 0xee0b5d8b
     * @param _addr address of the player you want to lookup 
     * @return player ID 
     * @return player name
     * @return keys owned (current round)
     * @return winnings vault
     * @return general vault 
     * @return affiliate vault 
	 * @return player round eth
     */
    function getPlayerInfoByAddress(address _addr)
        public 
        view 
        returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];
        
        return
        (
            _pID,                               //0
            plyr_[_pID].name,                   //1
            plyrRnds_[_pID][_rID].keys,         //2
            plyr_[_pID].win,                    //3
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),       //4
            plyr_[_pID].aff,                    //5
            plyrRnds_[_pID][_rID].eth           //6
        );
    }

    /**
     * @dev updates round timer based on number of whole keys bought.
     */
    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
        // grab time
        uint256 _now = now;
        
        // calculate time based on number of keys bought
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);
        
        // compare to max and set new end time
        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
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

