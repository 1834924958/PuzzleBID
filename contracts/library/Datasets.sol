pragma solidity ^0.5.0;

library Datasets {

    //玩家结构
    struct Player {
        address[] ethAddress; //玩家address
        address referrer; //推荐人address
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
        uint256 isPublish; //作品游戏发布开关 true为开启
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

}