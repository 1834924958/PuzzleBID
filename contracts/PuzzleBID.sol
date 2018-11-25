pragma solidity ^0.5.0;

import "./library/SafeMath.sol"; //导入安全运算库
import "./library/Datasets.sol"; //导入结构库
import "./interface/TeamInterface.sol"; //导入管理员团队接口
import "./interface/PlatformInterface.sol"; //导入平台接口
import "./interface/ArtistInterface.sol"; //导入艺术家接口
import "./interface/WorksInterface.sol"; //导入作品碎片接口

/**
 * @dev PuzzleBID Game 作品合约（一作品一合约）
 * @author Simon<vsiryxm@163.com>
 */
contract PuzzleBID {
    using SafeMath for *;

    TeamInterface private team; //引入管理员，正式发布时可定义成常量
    PlatformInterface private platform; //引入平台
    ArtistInterface private artist; //引入艺术家
    WorksInterface private works; //引入作品碎片
    

    //初始化 连接一个作品合约
    constructor(address _WorksAddress) public {
    	//TODO：检查作品合约是否存在
    	works = WorksInterface(_WorksAddress);
    }  
    
    //=========================================================================
    //| Game data 
    //=========================================================================
    mapping(address => PZB_Datasets.Player) public players; //游戏玩家
    //mapping(bytes32 => mapping(uint256 => PZB_Datasets.Player)) public union_players; //一个手机号码对应多个玩家钱包 如md5(手机号码) => Player 
    mapping(bytes32 => PZB_Datasets.Works) public works; //作品列表 如(worksID => PZB_Datasets.Works)
    
    mapping(bytes32 => PZB_Datasets.Artist) public artists; //通过艺术家检索作品 如(artistID => PZB_Datasets.Artist)

    mapping(bytes32 => uint256) public pots; //各作品奖池 如(worksID => totalAmount)
    //mapping(uint256 => PZB_Datasets.Transaction) public transactions; //交易记录列表
    mapping(address => mapping(bytes32 => PZB_Datasets.MyWorks)) public myworks; //我的藏品列表 (playerAddress => (worksID => PZB_Datasets.MyWorks))
    uint256 public turnover; //所有作品的总交易额
    mapping(bytes32 => uint256) worksTurnover; //每个作品的累计交易额 如(worksID => amount) 
    mapping(bytes32 => address[]) secondAddress; //每个作品的再次购买玩家名单 如(worksID => playerAddress)
    mapping(address => uint256) firstCount; //首发购买按玩家统计各自投入

    //玩家购买记录检索表
    mapping(address => mapping(bytes32 => PZB_Datasets.UnitCount)) playerBuy; // 如(player => (worksID => PZB_Datasets.UnitCount))
    
    //注册游戏玩家 静默
    function registerPlayer(bytes32 _unionID, address _referrer) external {
        require(players[msg.sender].time == 0);
        require(_referrer != address(0));
        uint256 _now = now;
        players[msg.sender] = PZB_Datasets.Player(msg.sender, _unionID, _referrer, _now);
        //union_players[_unionID].push(players[msg.sender]); //属同一个用户塞一个篮子
        emit OnRegisterPlayer(msg.sender, _unionID, _referrer, _now);
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

    function()
        public
        payable
    {
        revert();
        //buyCore(bytes32 _worksID, uint8 _debrisID);
    }

    //获取碎片的最新价格
    function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) public view returns(uint256) {
        uint256 lastPrice;
        if(debris[_worksID][_debrisID].buyNum > 0 && debris[_worksID][_debrisID].lastTime.add(discountTime) < now) { //降价
            lastPrice = debris[_worksID][_debrisID].lastPrice.mul(discountRatio / 100);
        } else if (debris[_worksID][_debrisID].buyNum > 0) { //涨价
            lastPrice = debris[_worksID][_debrisID].lastPrice.mul(increaseRatio / 100);
        }
        return lastPrice;
    }

    //更新碎片
    function updateDebris(bytes32 _worksID, uint8 _debrisID) internal {
        //更新碎片价格
        //超过时间
        if(debris[_worksID][_debrisID].buyNum > 0 && debris[_worksID][_debrisID].lastTime.add(discountTime) < now) { //降价
            debris[_worksID][_debrisID].lastPrice = debris[_worksID][_debrisID].lastPrice.mul(discountRatio / 100);
        } 
        //未超过时间
        else if (debris[_worksID][_debrisID].buyNum > 0) { //涨价
            debris[_worksID][_debrisID].lastPrice = debris[_worksID][_debrisID].lastPrice.mul(increaseRatio / 100);
        }

        debris[_worksID][_debrisID].lastBuyer = msg.sender; //更新归属
        debris[_worksID][_debrisID].buyNum = debris[_worksID][_debrisID].buyNum.add(1); //更新碎片被购买次数
        debris[_worksID][_debrisID].lastTime = now; //更新最后被交易时间
        playerBuy[msg.sender][_worksID].lastTime = now; //更新玩家最后购买时间

    }

    //更新交易额
    function updateTurnover(bytes32 _worksID) internal {

        //更新所有作品累计交易额
        turnover = turnover.add(msg.value);

        //更新当前作品的累计交易额
        worksTurnover[_worksID] = worksTurnover[_worksID].add(msg.value);

    }

    //游戏前检查
    modifier checkPlay(bytes32 _worksID, uint8 _debrisID) {

        //检查支付，最小0.000000001ETH，最大100000ETH
        require(msg.value >= 1000000000);
        require(msg.value <= 100000000000000000000000);

        //检查该作品碎片能不能被买
        require(works[_worksID].beginTime != 0); //检查该作品游戏是否存在
        require(debris[_worksID][_debrisID].initPrice != 0); //检查该作品碎片是否存在
        require(works[_worksID].isPublish && works[_worksID].beginTime <= now); //检查该作品游戏是否发布并开始
        require(works[_worksID].endTime == 0); //检查该作品游戏是否已结束
        require(debris[_worksID][_debrisID].lastTime.add(protectTime) < now); //检查该作品碎片是否在30分钟保护期内
        
        //检查玩家能不能买该作品碎片
        require(playerBuy[msg.sender][_worksID].lastTime.add(freezeTime)  < now); //检查同一作品同一玩家是否超过5分钟冻结期

        //检查是否达到首发购买限制、该作品碎片是否为二手交易
        require((playerBuy[msg.sender][_worksID].firstBuyNum.add(1) > works[_worksID].firstBuyLimit) && (debris[_worksID][_debrisID].buyNum > 0)); //限制首发购买超出情况        

        //检查支付的ETH够不够？      
        require(msg.value >= getDebrisPrice(_worksID, _debrisID));
        _;
    }    

    //开始游戏 游戏入口
    function startPlay(bytes32 _worksID, uint8 _debrisID) 
        isHuman()
        isRegisteredGame()
        checkPlay(_worksID, _debrisID)
        external
        payable
    {

        uint256 lastPrice = debris[_worksID][_debrisID].lastPrice;

        //更新碎片：价格、归属、被购买次数、最后被交易时间
        updateDebris(_worksID, _debrisID);

        //更新交易额
        updateTurnover(_worksID);

        //分分分
        if(debris[_worksID][_debrisID].buyNum > 0) { 
            //如果是首发购买，按首发规则
            firstPlay(_worksID, _debrisID);
        } else { 
            //如果是再次购买，按再次规则
            secondPlay(_worksID, _debrisID, lastPrice);
            //完成游戏
            finishGame(_worksID, _debrisID);
        }

    }

    function firstPlay(bytes32 _worksID, uint8 _debrisID) private {

        //更新当前作品碎片首发购买名单
        debris[_worksID][_debrisID].firstBuyer = msg.sender; 

        //更新同一作品同一玩家首发购买数
        playerBuy[msg.sender][_worksID].firstBuyNum = playerBuy[msg.sender][_worksID].firstBuyNum.add(1); 
        
        //分配并转账
        artists[works[_worksID].artistID].ethAddress.transfer(msg.value.mul(firstAllot[0]) / 100); //销售价的80% 艺术家
        puzzlebidAddress.transfer(msg.value.mul(firstAllot[1]) / 100); //销售价的2% 平台
        pots[_worksID] = pots[_worksID].add(msg.value.mul(firstAllot[2]) / 100); //销售价的18% 奖池 即当前合约地址       
    
    }

    function secondPlay(bytes32 _worksID, uint8 _debrisID, uint256 _oldPrice) private {

        //更新当前作品碎片的最后购买者
        debris[_worksID][_debrisID].lastBuyer = msg.sender; 

        //更新当前作品的再次购买者名单
        if(playerBuy[msg.sender][_worksID].secondAmount == 0) { 
            secondAddress[_worksID].push(msg.sender);
        }

        //统计同一作品同一玩家的再次购买投入
        playerBuy[msg.sender][_worksID].secondAmount = playerBuy[msg.sender][_worksID].secondAmount.add(msg.value); 
        
        //有溢价才分分分     
        if(debris[_worksID][_debrisID].lastPrice > _oldPrice) { 
            uint256 overflow = debris[_worksID][_debrisID].lastPrice.sub(_oldPrice); //计算溢价
            artists[works[_worksID].artistID].ethAddress.transfer(overflow.mul(againAllot[0]) / 100); //溢价的10% 艺术家
            puzzlebidAddress.transfer(debris[_worksID][_debrisID].lastPrice.mul(againAllot[1]) / 100); //总价的2% 平台
            pots[_worksID] = pots[_worksID].add(overflow.mul(againAllot[2]) / 100); //溢价的18% 奖池
            debris[_worksID][_debrisID].lastBuyer.transfer(debris[_worksID][_debrisID].lastPrice.sub(overflow.mul(againAllot[0]) / 100).sub(debris[_worksID][_debrisID].lastPrice.mul(againAllot[1]) / 100).sub(overflow.mul(againAllot[2]) / 100)); //剩余部分归上一买家
        } 
        //无溢价，把此次打折后的ETH全额转给上一买家
        else { 
            debris[_worksID][_debrisID].lastBuyer.transfer(debris[_worksID][_debrisID].lastPrice);
        }

    }

    //检查游戏是否结束
    modifier checkGameOver(bytes32 _worksID, uint8 _debrisID) {
        //检查是否收集齐了
        uint256 i;
        bool isFinished = true; //游戏完成标志
        i = 1;
        while(i <= works[_worksID].debrisNum) {
            if(debris[_worksID][_debrisID].lastBuyer != msg.sender) {
                isFinished = false;
                break;
            }
            i++;
        }
        require(isFinished);
        _;
    }
    
    //完成游戏
    function finishGame(bytes32 _worksID, uint8 _debrisID) internal checkGameOver(_worksID, _debrisID)
    {              

        //更新作品游戏结束时间
        works[_worksID].endTime = now; 

        //收集碎片完成，按最后规则
        msg.sender.transfer(pots[_worksID].mul(lastAllot[0] / 100)); //当前作品奖池的80% 最后一次购买者

        //首发玩家统计发放        
        firstSend(_worksID, _debrisID);

        //后续玩家统计发放
        secondSend(_worksID, _debrisID);
        
        //处理成我的藏品
        myworks[msg.sender][_worksID] = PZB_Datasets.MyWorks(msg.sender, _worksID, 0, 0, now);

    }
    
    //首发玩家统计发放
    function firstSend(bytes32 _worksID, uint8 _debrisID) private {
        address[] storage firstAddress;
        uint8 i; 
        for(i=1; i<works[_worksID].debrisNum; i++) {
            if(firstCount[debris[_worksID][_debrisID].lastBuyer] == 0) {
                firstAddress.push(debris[_worksID][_debrisID].lastBuyer);
            }
            firstCount[debris[_worksID][_debrisID].lastBuyer] = firstCount[debris[_worksID][_debrisID].lastBuyer] + debris[_worksID][_debrisID].initPrice;
        }
        for(i=0; i<firstAddress.length; i++) {
            firstAddress[i].transfer((pots[_worksID].mul(lastAllot[1]) / 100).mul(firstCount[firstAddress[i]]) / works[_worksID].price);
            delete firstCount[firstAddress[i]];
        }
    }
    
    //后续玩家统计发放
    function secondSend(bytes32 _worksID, uint8 _debrisID) private {
        address[] tmpAddress = secondAddress[_worksID];
        for(uint256 i=0; i<=tmpAddress.length; i++) {
            tmpAddress[i].transfer((pots[_worksID].mul(lastAllot[1]) / 100).mul(playerBuy[tmpAddress[i]][_worksID].secondAmount) / worksTurnover[_worksID].sub(works[_worksID].price));
        }
    }


    //获取当前最新时间 倒计时以此为基准
    function getNowTime() external view returns(uint256) {
        return now;
    }


 }

