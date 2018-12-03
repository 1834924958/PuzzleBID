pragma solidity ^0.5.0;

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
    function isFinish(bytes32 _worksID, uint8 _debrisID, address _unionID) external view returns (bool);

    //是否存在首发购买者名单中
    function hasFirstUnionId(bytes32 _worksID, bytes32 _unionID) external returns (bool);

    //是否存在二次购买者名单中
    function hasSecondUnionId(bytes32 _worksID, bytes32 _unionID) external returns (bool);

    //获取作品的首发购买者名单
    function getFirstUnionId(bytes32 _worksID) external returns (bytes32[] memory);

    //获取作品的二次购买者名单
    function getSecondUnionId(bytes32 _worksID) external returns (bytes32[] memory);

    //获取作品的初始总价
    function getPrice(bytes32 _worksID) external returns (uint256);

    //获取碎片的实时价格 有可能为0
    function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256);

    //获取碎片的初始价格
    function getInitPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256);

    //获取碎片的最后被交易的价格
    function getLastPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256);

    //获取碎片的最后购买者address
    function getLastBuyer(bytes32 _worksID, uint8 _debrisID) external view returns(address);

    //获取碎片的最后购买者unionID
    function getLastUnionId(bytes32 _worksID, uint8 _debrisID) external view returns(address);

    //获取玩家账号冻结时间 单位s
    function getFreezeGap(bytes32 _worksID) external view returns(uint256);

    //获取玩家首发购买上限数
    function getFirstBuyLimit(bytes32 _worksID) external view returns(uint256);

    //获取作品对应的艺术家ID
    function getArtistId(bytes32 _worksID) external view returns(bytes32);

    //获取作品分割的碎片数
    function getDebrisNum(bytes32 _worksID) external view returns(uint8);

    //获取首发购买分配百分比分子 返回数组
    function getAllot(bytes32 _worksID, uint8 _flag) external view returns(uint8[3] memory);

    //获取首发购买分配百分比分子 返回整型
    function getAllot(bytes32 _worksID, uint8 _flag, uint8 _element) external view returns(uint8);

    //获取作品奖池累计
    function getPools(bytes32 _worksID) external view returns (uint256);

    //获取作品碎片游戏开始倒计时 单位s
    function getStartHourglass(bytes32 _worksID, uint8 _debrisID) external view returns(uint256);

    //获取碎片保护期倒计时 单位s
    function getProtectHourglass(bytes32 _worksID, uint8 _debrisID) external view returns(uint256);

    //获取碎片降价倒计时 单位s 无限个倒计时段 过了第一个倒计时段 进入下一个倒计时段...
    function getDiscountHourglass(bytes32 _worksID, uint8 _debrisID) external view returns(uint256);

    //更新碎片
    function updateDebris(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address _sender) external;

    //更新作品碎片的首发购买者
    function updateFirstBuyer(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address _sender) external;

    //更新作品碎片的最后购买者
    function updateLastBuyer(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address _sender) external;

    //更新作品碎片游戏结束时间
    function updateEndTime(bytes32 _worksID) external;

    //更新作品奖池累计
    function updatePools(bytes32 _worksID, uint256 _value) external;

    //更新作品的首发购买者名单
    function updateFirstUnionId(bytes32 _worksID, bytes32 _unionID) external;

    //更新作品的二次购买者名单
    function updateSecondUnionId(bytes32 _worksID, bytes32 _unionID) external;

 }