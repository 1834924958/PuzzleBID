pragma solidity ^0.5.0;

import "./library/SafeMath.sol"; //导入安全运算库

/**
 * @dev PuzzleBID Game 作品合约（一作品一合约）
 * @author Simon<vsiryxm@163.com>
 */
contract Works {

    //=========================================================================
    //| 游戏配置参数
    //=========================================================================
    uint256 private freezeTime; //玩家购买一个作品中的一个碎片后冻结3分钟
    uint256 private protectTime; //碎片保护时间30分钟
    uint256 private increaseRatio; //% 碎片价格调整为上一次价格的110%
    uint256 private discountTime; //碎片开始打折时间，被购买1小时后    
    uint256 private discountRatio; //% 碎片价格调整为首发价格的95%

    //=========================================================================
    //| 游戏分红比例
    //=========================================================================
    uint8[3] firstAllot; //% 首发购买分配百分比 顺序对应艺术家80、平台2、奖池18
    uint8[3] againAllot; //% 再次购买分配百分比 艺术家10（溢价部分）、平台2（总价）、奖池65（溢价部分）
    uint8[3] lastAllot; //% 完成购买分配百分比 游戏完成者80、首发购买者10、后续其他购买者10

    //=========================================================================
    //| 初始化游戏参数
    //=========================================================================
    constructor(
    	uint256 _freezeGap, 
    	uint256 _protectGap, 
    	uint256 _increaseRatio,
    	uint256 _discountGap,
    	uint256 _discountRatio,
    	uint8[3] _firstAllot,
    	uint8[3] _againAllot,
    	uint8[3] _lastAllot,
    	) public {
    	freezeGap = _freezeGap.mul(1 seconds); //180 seconds
    	protectGap = _protectGap.mul(1 seconds); //1800 seconds
    	increaseRatio = _increaseRatio; //110
    	discountGap = _discountGap.mul(1 seconds); //3600 seconds
    	discountRatio = _discountRatio; //95

    	firstAllot = _firstAllot; //[80, 2, 18]
    	againAllot = _againAllot; //[10, 2, 65]
    	lastAllot = _lastAllot; //[80, 10, 10]
    }

    //添加一局作品游戏 管理员操作
    function add(
        bytes32 _worksID,
        bytes32 _artistID, 
        uint8 _debrisNum, 
        uint256 _price, 
        uint256 _beginTime, 
        address _tokenID,
        address _artistAddress,
        uint8 _firstBuyLimit) external onlyDev() {

        require(works[_worksID].beginTime == 0);
        require(artists[_artistID].ethAddress == address(0));
        require(_debrisNum >= 2 && _debrisNum < 256);
        require(_price > 0);   
        require(_beginTime > 0 && _beginTime > now); 

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
        for(uint8 i=1; i<=_debrisNum; i++) {
            debris[_worksID][i].worksID = _worksID;
            debris[_worksID][i].initPrice = initPrice;
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
        require(works[_worksID].beginTime != 0 && works[_worksID].isPublish == false);
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

    function() external payable {
        revert();
    }

    //获取碎片的最新价格
    function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) public view returns(uint256) {
        
    }

    //更新碎片
    function updateDebris(bytes32 _worksID, uint8 _debrisID) internal {
        
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

    //购买碎片
    function buyCore(bytes32 _worksID, uint8 _debrisID) 
        isHuman()
        isRegisteredGame()
        checkPlay(_worksID, _debrisID)
        public
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


 }

