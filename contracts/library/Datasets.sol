pragma solidity ^0.5.0;

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