pragma solidity ^0.5.0;

import "./library/SafeMath.sol"; //导入安全运算库
import "./library/Datasets.sol"; //导入公共结构库
import "./interface/TeamInterface.sol"; //导入管理员团队合约接口
import "./interface/PlatformInterface.sol"; //导入平台合约接口
import "./interface/ArtistInterface.sol"; //导入艺术家合约接口
import "./interface/WorksInterface.sol"; //导入作品碎片合约接口
import "./interface/PlayerInterface.sol"; //导入玩家合约接口

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
        require(works.isGameOver(_worksID)); //检查游戏是否已结束
        require(works.isPublish(_worksID) && works.isStart(_worksID)); //检查该作品游戏是否发布并开始
        require(works.isProtect(_worksID, _debrisID)); //检查该作品碎片是否在30分钟保护期内
        
        //检查玩家能不能买该作品碎片 
        require(player.isFreeze(_unionID, _worksID)); //检查同一作品同一玩家是否超过5分钟冻结期
        require(
            (player.getFirstBuyNum(_unionID, _worksID).add(1) > works.getFirstBuyLimit(_worksID)) && 
            works.isSecond(_worksID, _debrisID)
        ); //检查是否达到首发购买上限、该作品碎片是否为二手交易        
        require(msg.value >= works.getDebrisPrice(_worksID, _debrisID)); //检查支付的ETH够不够？
        _;
    }    

    //开始游戏 游戏入口
    function startPlay(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID) 
        isHuman()
        checkPlay(_worksID, _debrisID, _unionID)
        external
        payable
    {
        player.register(_unionID, msg.sender, _worksID, _unionID); //静默注册

        uint256 lastPrice = works.getLastPrice(_worksID, _debrisID); //获取碎片的最后被交易的价格    

        works.updateDebris(_worksID, _debrisID, _unionID, msg.sender); //更新碎片：价格、归属、被购买次数

        player.updateLastTime(_unionID, _worksID); //更新玩家在一个作品中的最后购买碎片时间
        
        platform.updateTurnover(_worksID, msg.value); //更新作品的交易额

        platform.updateAllTurnover(msg.value); //更新平台总交易额
        
        //分红业务
        if(works.isSecond(_worksID, _debrisID)) { 
            //碎片如果是被玩家再次购买，按再次规则
            secondPlay(_worksID, _debrisID, _unionID, lastPrice);            
        } else { 
            //碎片如果是被玩家第一次购买，按首发规则
            firstPlay(_worksID, _debrisID, _unionID);       
        }
        //碎片如果被同一玩家收集完成，结束游戏
        if(works.isFinish(_worksID, _debrisID, _unionID)) {
            works.updateEndTime(_worksID); //更新作品游戏结束时间
            finishGame(_worksID, _debrisID); //游戏收尾
            collectWorks(_worksID, _unionID); //我的藏品
        }

    }

    //首发购买
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

    //二次购买
    function secondPlay(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, uint256 _oldPrice) private {

        works.updateLastBuyer(_worksID, _debrisID, _unionID, msg.sender); //更新当前作品碎片的最后购买者

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
            platform.deposit.value(overflow.mul(againAllot[2]) / 100)(_worksID); //平台合约代为保管奖池ETH

            works.getLastBuyer(_worksID, _debrisID).transfer(
                lastPrice.sub(overflow.mul(againAllot[0]) / 100)
                .sub(lastPrice.mul(againAllot[1]) / 100)
                .sub(overflow.mul(againAllot[2]) / 100)
            ); //剩余部分归上一买家
        } 
        //无溢价，把此次降价后的ETH全额转给上一买家
        else { 
            works.getLastBuyer(_worksID, _debrisID).transfer(lastPrice);
        }

    }

    //完成游戏
    function finishGame(bytes32 _worksID, uint8 _debrisID) private {              
        //收集碎片完成，按最后规则
        uint8 lastAllot = works.getAllot(_worksID, 2, 0);
        msg.sender.transfer(works.getPools(_worksID).mul(lastAllot / 100)); //当前作品奖池的80% 最后一次购买者  
        firstSend(_worksID, _debrisID); //首发玩家统计发放
        secondSend(_worksID, _debrisID); //后续玩家统计发放
    }

    //处理成我的藏品
    function collectWorks(bytes32 _worksID, bytes32 _unionID) private {
        player.updateMyWorks(_unionID, msg.sender, _worksID, 0, 0);
    }
    
    //首发玩家统计发放
    function firstSend(bytes32 _worksID, uint8 _debrisID) private {
        uint8 i;
        bytes32[] tmpFirstUnionId = works.getFirstUnionId(_worksID); //首发玩家名单
        address tmpAddress; //玩家最近使用的address
        uint256 tmpAmount; //首发玩家应得分红
        uint8 lastAllot = works.getAllot(_worksID, 2, 1);
        for(i=0; i<tmpFirstUnionId.length; i++) {
            tmpAddress = player.getLastAddress(tmpFirstUnionId[i]);
            tmpAmount = player.getFirstAmount(tmpFirstUnionId[i], _worksID); //玩家首发投入累计
            //应得分红 = 作品对应的奖池 * 10% * (玩家首发投入累计 / 作品初始价格即首发总投入)
            tmpAmount = works.getPools(_worksID).mul(lastAllot / 100).mul(tmpAmount / works.getPrice(_worksID));
            platform.transferTo(tmpAddress, tmpAmount); //平台合约代为发放奖池中的ETH
        }
    }
    
    //后续玩家统计发放
    function secondSend(bytes32 _worksID, uint8 _debrisID) private {
        uint8 i;
        bytes32[] tmpSecondUnionId = works.getSecondUnionId(_worksID); //二次购买玩家名单
        address tmpAddress; //玩家最近使用的address
        uint256 tmpAmount; //首发玩家应得分红
        uint8 lastAllot = works.getAllot(_worksID, 2, 2);
        for(i=0; i<tmpSecondUnionId.length; i++) {
            tmpAddress = player.getLastAddress(tmpSecondUnionId[i]);
            tmpAmount = player.getSecondAmount(tmpSecondUnionId[i], _worksID); //玩家二次投入累计
            //应得分红 = 作品对应的奖池 * 10% * (玩家二次投入累计 / 作品二次总投入)
            //作品二次总投入 = 作品的总交易额 - 作品初始价格即首发总投入
            tmpAmount = works.getPools(_worksID).mul(lastAllot / 100).mul(tmpAmount / works.getTurnover(_worksID).sub(works.getPrice(_worksID)));
            platform.transferTo(tmpAddress, tmpAmount); //平台合约代为发放奖池中的ETH
        }
    }

    //获取游戏当前最新时间
    function getNowTime() external view returns(uint256) {
        return now;
    }

 }

