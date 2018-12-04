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




library Datasets {

    struct Player {
        address[] ethAddress; 
        bytes32 referrer; 
        address lastAddress; 
        uint256 time;
    }

    struct MyWorks { 
        address ethAddress; 
        bytes32 worksID; 
        uint256 totalInput; 
        uint256 totalOutput; 
        uint256 time; 
    }


    struct Works {
        bytes32 worksID; 
        bytes32 artistID; 
        uint8 debrisNum; 
        uint256 price; 
        uint256 beginTime; 
        uint256 endTime;
        bool isPublish; 
    }

    struct Debris {
        uint8 debrisID; 
        bytes32 worksID; 
        uint256 initPrice; 
        uint256 lastPrice; 
        uint256 buyNum; 
        address payable firstBuyer; 
        address payable lastBuyer; 
        bytes32 firstUnionID; 
        bytes32 lastUnionID; 
        uint256 lastTime; 
    }
    
    struct Rule {
       
        uint8 firstBuyLimit; 
        uint256 freezeGap; 
        uint256 protectGap; 
        uint256 increaseRatio;
        uint256 discountGap; 
        uint256 discountRatio; 

        uint8[3] firstAllot; 
        uint8[3] againAllot;
        uint8[3] lastAllot; 
    }

    struct PlayerCount {
        uint256 lastTime; 
        uint256 firstBuyNum; 
        uint256 firstAmount; 
        uint256 secondAmount; 
    }

}


contract Team {

    address public owner; 
   
    struct Admin {
        bool isAdmin; 
        bool isDev;
        bytes32 name; 
    }

    mapping (address => Admin) admins;

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
    event OnRemoveAdmin(address _address);

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

    function isOwner() external view returns (bool) {
        return owner == msg.sender;
    }

    function isAdmin(address _sender) external view returns (bool) {
        return admins[_sender].isAdmin;
    }

    function isDev(address _sender) external view returns (bool) {
        return admins[_sender].isDev;
    }


}


interface TeamInterface {

    function addAdmin(address _address, bool _isAdmin, bool _isDev, bytes32 _name) external;

    function removeAdmin(address _address) external;

    function isOwner() external view returns (bool);

    function isAdmin(address _sender) external view returns (bool);

    function isDev(address _sender) external view returns (bool);

}

contract Artist {

    TeamInterface private team; 
    mapping(bytes32 => address payable) private artists; 

    constructor(address _teamAddress) public {
        team = TeamInterface(_teamAddress);
    }

    function() external payable {
        revert();
    }

    event OnAdd(bytes32 _artistID, address _address);
    event OnUpdateAddress(bytes32 _artistID, address _address);

    modifier onlyDev() {
        require(team.isDev(msg.sender));
        _;
    }

    function getAddress(bytes32 _artistID) external view returns (address payable) {
        return artists[_artistID];
    }
   
    function add(bytes32 _artistID, address payable _address) external onlyDev() {
        require(this.hasArtist(_artistID) == false);
        artists[_artistID] = _address;
        emit OnAdd(_artistID, _address);
    }

    function hasArtist(bytes32 _artistID) external view returns (bool) {
        return artists[_artistID] != address(0);
    }

    function updateAddress(bytes32 _artistID, address payable _address) external onlyDev() {
        require(_address != address(0));
        artists[_artistID] = _address;
        emit OnUpdateAddress(_artistID, _address);
    }

}



interface WorksInterface {

    function addWorks(
        bytes32 _worksID,
        bytes32 _artistID, 
        uint8 _debrisNum, 
        uint256 _price, 
        uint256 _beginTime
    ) 
        external;

    function configRule(
        bytes32 _worksID,
        uint8 _firstBuyLimit, 
        uint256 _freezeGap, 
        uint256 _protectGap, 
        uint256 _increaseRatio,
        uint256 _discountGap, 
        uint256 _discountRatio, 

        uint8[3] calldata _firstAllot, 
        uint8[3] calldata _againAllot, 
        uint8[3] calldata _lastAllot 
    ) 
        external;

    function publish(bytes32 _worksID, uint256 _beginTime) external;
    function close(bytes32 _worksID) external;
    function hasWorks(bytes32 _worksID) external view returns (bool);
    function hasDebris(bytes32 _worksID, uint8 _debrisID) external view returns (bool);
    function isPublish(bytes32 _worksID) external view returns (bool);

    function isStart(bytes32 _worksID) external view returns (bool);

    function isProtect(bytes32 _worksID, uint8 _debrisID) external view returns (bool);

    function isSecond(bytes32 _worksID, uint8 _debrisID) external view returns (bool);

    function isGameOver(bytes32 _worksID) external view returns (bool);
    
    function isFinish(bytes32 _worksID, bytes32 _unionID) external view returns (bool);

    function hasFirstUnionId(bytes32 _worksID, bytes32 _unionID) external view returns (bool);

    function hasSecondUnionId(bytes32 _worksID, bytes32 _unionID) external view returns (bool);

    function getFirstUnionId(bytes32 _worksID) external view returns (bytes32[] memory);

    function getSecondUnionId(bytes32 _worksID) external view returns (bytes32[] memory);

    function getPrice(bytes32 _worksID) external view returns (uint256);

    function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    function getInitPrice(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    function getLastPrice(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    function getLastBuyer(bytes32 _worksID, uint8 _debrisID) external view returns (address payable);

    function getLastUnionId(bytes32 _worksID, uint8 _debrisID) external view returns (bytes32);

    function getFreezeGap(bytes32 _worksID) external view returns (uint256);

    function getFirstBuyLimit(bytes32 _worksID) external view returns (uint256);

    function getArtistId(bytes32 _worksID) external view returns (bytes32);

    function getDebrisNum(bytes32 _worksID) external view returns (uint8);

    function getAllot(bytes32 _worksID, uint8 _flag) external view returns (uint8[3] memory);

    function getAllot(bytes32 _worksID, uint8 _flag, uint8 _element) external view returns (uint8);

    function getPools(bytes32 _worksID) external view returns (uint256);

    function getStartHourglass(bytes32 _worksID) external view returns (uint256);

    function getProtectHourglass(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    function getDiscountHourglass(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    function updateDebris(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address _sender) external;

    function updateFirstBuyer(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address _sender) external;

    function updateLastBuyer(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address _sender) external;

    function updateEndTime(bytes32 _worksID) external;

    function updatePools(bytes32 _worksID, uint256 _value) external;

    function updateFirstUnionId(bytes32 _worksID, bytes32 _unionID) external;

    function updateSecondUnionId(bytes32 _worksID, bytes32 _unionID) external;

 }
 

interface ArtistInterface {

    function getAddress(bytes32 _artistID) external view returns (address payable);

    function add(bytes32 _artistID, address _address) external;

    function hasArtist(bytes32 _artistID) external view returns (bool);

    function updateAddress(bytes32 _artistID, address _address) external;

}



contract Works {

    using SafeMath for *;

    TeamInterface private team; 
    ArtistInterface private artist; 

    constructor(address _teamAddress, address _artistAddress) public {
        team = TeamInterface(_teamAddress);
        artist = ArtistInterface(_artistAddress);
    }

    function() external payable {
        revert();
    }

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
    event OnUpdateLastBuyer(
        bytes32 _worksID, 
        uint8 _debrisID, 
        bytes32 _unionID, 
        address indexed _sender
    );
    event OnUpdateEndTime(bytes32 _worksID, uint256 _time);
    event OnUpdatePools(bytes32 _worksID, uint256 _value);
    event OnUpdateFirstUnionId(bytes32 _worksID, bytes32 _unionID);
    event OnUpdateSecondUnionId(bytes32 _worksID, bytes32 _unionID);

    mapping(bytes32 => Datasets.Works) private works; 
    mapping(bytes32 => Datasets.Rule) private rules; 
    mapping(bytes32 => uint256) private pools; 
    mapping(bytes32 => mapping(uint8 => Datasets.Debris)) private debris; 
    mapping(bytes32 => bytes32[]) firstUnionID; 
    mapping(bytes32 => bytes32[]) secondUnionID; 

    modifier whenHasWorks(bytes32 _worksID) {
        require(works[_worksID].beginTime != 0);
        _;
    }

    modifier whenNotHasWorks(bytes32 _worksID) {
        require(works[_worksID].beginTime == 0);
        _;
    }

    modifier whenHasArtist(bytes32 _artistID) {
        require(artist.hasArtist(_artistID));
        _;
    }

    modifier onlyAdmin() {
        require(team.isAdmin(msg.sender));
        _;
    }

    modifier onlyDev() {
        require(team.isDev(msg.sender));
        _;
    }

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
            _debrisNum >= 2 && _debrisNum < 256 && 
            _price > 0 && 
            _beginTime > 0 && _beginTime > now 
        ); 

        works[_worksID] = Datasets.Works(
            _worksID, 
            _artistID, 
            _debrisNum, 
            _price, 
            _beginTime, 
            0,
            false
        ); 

        emit OnAddWorks(
            _worksID,
            _artistID, 
            _debrisNum, 
            _price, 
            _beginTime,
            false
        ); 

        initDebris(_worksID, _price, _debrisNum);
    }

    function initDebris(bytes32 _worksID, uint256 _price, uint8 _debrisNum) private {      
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

    function configRule(
        bytes32 _worksID,
        uint8 _firstBuyLimit, 
        uint256 _freezeGap, 
        uint256 _protectGap,
        uint256 _increaseRatio, 
        uint256 _discountGap,
        uint256 _discountRatio,

        uint8[3] calldata _firstAllot,
        uint8[3] calldata _againAllot, 
        uint8[3] calldata _lastAllot
    ) 
        external
        onlyAdmin()
        whenHasWorks(_worksID)
    {

        require(
            _firstBuyLimit > 0 &&
            _freezeGap > 0 &&
            _protectGap > 0 &&
            _increaseRatio > 0 && 
            _discountGap > 0 &&
            _discountRatio > 0 
        );

        require(
            _firstAllot[0] > 0 && _firstAllot[1] > 0 && _firstAllot[2] > 0 && 
            _againAllot[0] > 0 && _againAllot[1] > 0 && _againAllot[2] > 0 &&
            _lastAllot[0] > 0 && _lastAllot[1] > 0 && _lastAllot[2] > 0
        ); 

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

    function publish(bytes32 _worksID, uint256 _beginTime) external onlyAdmin() {
        require(works[_worksID].beginTime != 0 && works[_worksID].isPublish == false);
        if(_beginTime > 0 && _beginTime > now) {
            works[_worksID].beginTime = _beginTime;
        }
        works[_worksID].isPublish = true; //开启这个游戏
    }

    function close(bytes32 _worksID) external onlyAdmin() {
        works[_worksID].isPublish = false;
    }

    function hasWorks(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].beginTime != 0;
    }

    function hasDebris(bytes32 _worksID, uint8 _debrisID) external view returns (bool) {
        return _debrisID > 0 && _debrisID <= works[_worksID].debrisNum;
    }

    function isPublish(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].isPublish;
    }

    function isStart(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].beginTime >= now;
    }

    function isProtect(bytes32 _worksID, uint8 _debrisID) external view returns (bool) {
        uint256 protectGap = rules[_worksID].protectGap;
        return debris[_worksID][_debrisID].lastTime.add(protectGap) < now ? false : true;
    }

    function isSecond(bytes32 _worksID, uint8 _debrisID) external view returns (bool) {
        return debris[_worksID][_debrisID].buyNum > 0;
    }

    function isGameOver(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].endTime != 0;
    }

    function isFinish(bytes32 _worksID, bytes32 _unionID) external view returns (bool) {
        bool finish = true; 
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

    function getFirstUnionId(bytes32 _worksID) external view returns (bytes32[] memory) {
        return firstUnionID[_worksID];
    }

    function getSecondUnionId(bytes32 _worksID) external view returns (bytes32[] memory) {
        return secondUnionID[_worksID];
    }

    function getPrice(bytes32 _worksID) external view returns (uint256) {
        return works[_worksID].price;
    }

    function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {        
        uint256 discountGap = rules[_worksID].discountGap;
        uint256 discountRatio = rules[_worksID].discountRatio;
        uint256 increaseRatio = rules[_worksID].increaseRatio;
        uint256 lastPrice;

        if(debris[_worksID][_debrisID].buyNum > 0 && debris[_worksID][_debrisID].lastTime.add(discountGap) < now) { 

            uint256 n = (now.sub(debris[_worksID][_debrisID].lastTime)) / discountGap; 
            if((now.sub(debris[_worksID][_debrisID].lastTime)) % discountGap > 0) { 
                n = n.add(1);
            }
            lastPrice = lastPrice.mul((discountRatio / 100).pwr(n)); 

        } else if (debris[_worksID][_debrisID].buyNum > 0) { 
            lastPrice = debris[_worksID][_debrisID].lastPrice.mul(increaseRatio / 100);
        } else {
            lastPrice = debris[_worksID][_debrisID].lastPrice; 
        }

        return lastPrice;
    }

    function getInitPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        return debris[_worksID][_debrisID].initPrice;
    }

    function getLastPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        return debris[_worksID][_debrisID].lastPrice;
    }

    function getLastBuyer(bytes32 _worksID, uint8 _debrisID) external view returns(address) {
        return debris[_worksID][_debrisID].lastBuyer;
    }

    function getLastUnionId(bytes32 _worksID, uint8 _debrisID) external view returns(bytes32) {
        return debris[_worksID][_debrisID].lastUnionID;
    }

    function getFreezeGap(bytes32 _worksID) external view returns(uint256) {
        return rules[_worksID].freezeGap;
    }

    function getFirstBuyLimit(bytes32 _worksID) external view returns(uint256) {
        return rules[_worksID].firstBuyLimit;
    }

    function getArtistId(bytes32 _worksID) external view returns(bytes32) {
        return works[_worksID].artistID;
    }

    function getDebrisNum(bytes32 _worksID) external view returns(uint8) {
        return works[_worksID].debrisNum;
    }

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

    function getPools(bytes32 _worksID) external view returns (uint256) {
        return pools[_worksID];
    }

    function getStartHourglass(bytes32 _worksID) external view returns(uint256) {
        if(works[_worksID].beginTime.sub(now) > 0 ) {
            return works[_worksID].beginTime.sub(now);
        }
        return 0;
    }

    function getProtectHourglass(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        if(debris[_worksID][_debrisID].lastTime.add(rules[_worksID].protectGap).sub(now) > 0) {
            return debris[_worksID][_debrisID].lastTime.add(rules[_worksID].protectGap).sub(now);
        }
        return 0;
    }

    function getDiscountHourglass(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        uint256 discountGap = rules[_worksID].discountGap;
        uint256 n = (now.sub(debris[_worksID][_debrisID].lastTime)) / discountGap; 
        if((now.sub(debris[_worksID][_debrisID].lastTime)) % discountGap > 0) { 
            n = n.add(1);
        }
        return debris[_worksID][_debrisID].lastTime.add(discountGap.mul(n)).sub(now);
    }

    function updateDebris(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address payable _sender) external onlyDev() {
        debris[_worksID][_debrisID].lastPrice = this.getDebrisPrice(_worksID, _debrisID);
        debris[_worksID][_debrisID].lastUnionID = _unionID; 
        debris[_worksID][_debrisID].lastBuyer = _sender; 
        debris[_worksID][_debrisID].buyNum = debris[_worksID][_debrisID].buyNum.add(1); 
        debris[_worksID][_debrisID].lastTime = now; 
        emit OnUpdateDebris(_worksID, _debrisID, _unionID, _sender);
    }

    function updateFirstBuyer(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address payable _sender) external onlyDev() {
        debris[_worksID][_debrisID].firstBuyer = _sender;
        debris[_worksID][_debrisID].firstUnionID = _unionID;
        emit OnUpdateFirstBuyer(_worksID, _debrisID, _unionID, _sender);
    }

    function updateLastBuyer(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address payable _sender) external onlyDev() {
        debris[_worksID][_debrisID].lastBuyer = _sender;
        debris[_worksID][_debrisID].lastUnionID = _unionID;
        emit OnUpdateLastBuyer(_worksID, _debrisID, _unionID, _sender);
    }

    function updateEndTime(bytes32 _worksID) external onlyDev() {
        works[_worksID].endTime = now;
        emit OnUpdateEndTime(_worksID, now);
    }

    function updatePools(bytes32 _worksID, uint256 _value) external onlyDev() {
        pools[_worksID] = pools[_worksID].add(_value);
        emit OnUpdatePools(_worksID, _value);
    }

    function updateFirstUnionId(bytes32 _worksID, bytes32 _unionID) external onlyDev() {
        if(this.hasFirstUnionId(_worksID, _unionID) == false) {
            firstUnionID[_worksID].push(_unionID);
            emit OnUpdateFirstUnionId(_worksID, _unionID);
        }
    }

    function updateSecondUnionId(bytes32 _worksID, bytes32 _unionID) external onlyDev() {
        if(this.hasSecondUnionId(_worksID, _unionID) == false) {
            secondUnionID[_worksID].push(_unionID);
            emit OnUpdateSecondUnionId(_worksID, _unionID);
        }
    }

 }

/**
 * @title PuzzleBID Game 
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
interface PlatformInterface {

    function getAllTurnover() external view returns (uint256);

    function getTurnover(bytes32 _worksID) external view returns (uint256);

    function updateAllTurnover(uint256 _amount) external;

    function updateTurnover(bytes32 _worksID, uint256 _amount) external;

    function updateFoundAddress(address _foundation) external;

    function deposit(bytes32 _worksID) external payable;

    function transferTo(address _receiver, uint256 _amount) external;

    function getFoundAddress() external view returns (address payable);

    function balances() external view returns (uint256);

}


/**
 * @title PuzzleBID Game 
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
contract Platform {

    using SafeMath for *;

    address payable private foundAddress; 
    TeamInterface private team; 

    constructor(address payable _foundAddress, address _teamAddress) public {
        require(
            _foundAddress != address(0) &&
            _teamAddress != address(0)
        );
        foundAddress = _foundAddress;
        team = TeamInterface(_teamAddress);
    }

    function() external payable {
        revert();
    }

    event OnDeposit(bytes32 _worksID, address indexed _address, uint256 _amount); 
    event OnUpdateTurnover(bytes32 _worksID, uint256 _amount);
    event OnUpdateAllTurnover(uint256 _amount);
    event OnUpdateFoundAddress(address indexed _sender, address indexed _address);
    event OnTransferTo(address indexed _receiver, uint256 _amount);

    modifier onlyDev() {
        require(team.isDev(msg.sender));
        _;
    }

    modifier onlyAdmin() {
        require(team.isAdmin(msg.sender));
        _;
    }

    uint256 allTurnover; 
    mapping(bytes32 => uint256) turnover; 

    function getAllTurnover() external view returns (uint256) {
        return allTurnover;
    }

    function getTurnover(bytes32 _worksID) external view returns (uint256) {
        return turnover[_worksID];
    }

    function updateAllTurnover(uint256 _amount) external onlyDev() {
        allTurnover = allTurnover.add(_amount); 
        emit OnUpdateAllTurnover(_amount);
    }   

    function updateTurnover(bytes32 _worksID, uint256 _amount) external onlyDev() {
        turnover[_worksID] = turnover[_worksID].add(_amount); 
        emit OnUpdateTurnover(_worksID, _amount);
    }

    function updateFoundAddress(address payable _foundAddress) external onlyAdmin() {
        foundAddress = _foundAddress;
        emit OnUpdateFoundAddress(msg.sender, _foundAddress);
    }

    function deposit(bytes32 _worksID) external payable {
        require(_worksID != bytes32(0)); 
        emit OnDeposit(_worksID, msg.sender, msg.value);
    }

    function transferTo(address payable _receiver, uint256 _amount) external onlyDev() {
        require(_amount <= address(this).balance);
        _receiver.transfer(_amount);
        emit OnTransferTo(_receiver, _amount);
    }

    function getFoundAddress() external view returns (address payable) {
        return foundAddress;
    }

    function balances() external view onlyDev() returns (uint256) {
        return address(this).balance;
    }

}


/**
 * @title PuzzleBID Game
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
interface PlayerInterface {

    function hasAddress(address _address) external view returns (bool);

    function hasUnionId(bytes32 _unionID) external view returns (bool);

    function getInfoByUnionId(bytes32 _unionID) external view returns (address, bytes32, uint256);

    function getUnionIdByAddress(address _address) external view returns (bytes32);

    function isFreeze(bytes32 _unionID, bytes32 _worksID) external view returns (bool);

    function getFirstBuyNum(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    function getSecondAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    function getFirstAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    function getLastAddress(bytes32 _unionID) external view returns (address);

    function getReward(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    function getFreezeHourglass(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    function getMyWorks(bytes32 _unionID) external view returns (address, bytes32, uint256, uint256, uint256);

    function isLegalPlayer(bytes32 _unionID, address _address) external view returns (bool);

    function register(bytes32 _unionID, address _address, bytes32 _worksID, bytes32 _referrer) external returns (bool);

    function updateLastAddress(bytes32 _unionID, address _sender) external;

    function updateLastTime(bytes32 _unionID, bytes32 _worksID) external;

    function updateFirstBuyNum(bytes32 _unionID, bytes32 _worksID) external;

    function updateSecondAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    function updateFirstAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    function updateReward(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    function updateMyWorks(
        bytes32 _unionID, 
        address _address, 
        bytes32 _worksID, 
        uint256 _totalInput, 
        uint256 _totalOutput
    ) external;


}


/**
 * @title PuzzleBID Game 
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
contract Player {

    using SafeMath for *;

    TeamInterface private team; 
    WorksInterface private works; 
    
    constructor(address _teamAddress, address _worksAddress) public {
        team = TeamInterface(_teamAddress);
        works = WorksInterface(_worksAddress);
    }

    function() external payable {
        revert();
    }

    event OnRegister(
        address indexed _address, 
        bytes32 _unionID, 
        bytes32 _referrer, 
        uint256 time
    );
    event OnUpdateLastAddress(bytes32 _unionID, address _sender);
    event OnUpdateLastTime(bytes32 _unionID, bytes32 _worksID, uint256 _time);
    event OnUpdateFirstBuyNum(bytes32 _unionID, bytes32 _worksID, uint256 _firstBuyNum);
    event OnUpdateSecondAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateFirstAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateReinvest(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateReward(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateMyWorks(
        bytes32 _unionID, 
        address indexed _address, 
        bytes32 _worksID, 
        uint256 _totalInput, 
        uint256 _totalOutput,
        uint256 _time
    );

    modifier onlyDev() {
        require(team.isDev(msg.sender));
        _;
    }

    mapping(bytes32 => Datasets.Player) private playersByUnionId; 
    mapping(address => bytes32) private playersByAddress; 
    address[] private playerAddressSets; 
    bytes32[] private playersUnionIdSets; 

    mapping(bytes32 => mapping(bytes32 => Datasets.PlayerCount)) playerCount; 
    mapping(bytes32 => mapping(bytes32 => uint256)) private reward; //TODO

    mapping(bytes32 => Datasets.MyWorks) myworks; 

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

    function getInfoByUnionId(bytes32 _unionID) external view returns (address, bytes32, uint256) {
        return (
            playersByUnionId[_unionID].lastAddress,
            playersByUnionId[_unionID].referrer, 
            playersByUnionId[_unionID].time
        );
    }

    function getUnionIdByAddress(address _address) external view returns (bytes32) {
        return playersByAddress[_address];
    }

    function isFreeze(bytes32 _unionID, bytes32 _worksID) external view returns (bool) {
        uint256 freezeGap = works.getFreezeGap(_worksID);
        return playerCount[_unionID][_worksID].lastTime.add(freezeGap) < now ? false : true;
    }

    function getFirstBuyNum(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return playerCount[_unionID][_worksID].firstBuyNum;
    }

    function getSecondAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return playerCount[_unionID][_worksID].secondAmount;
    }

    function getFirstAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return playerCount[_unionID][_worksID].firstAmount;
    }

    function getLastAddress(bytes32 _unionID) external view returns (address) {
        return playersByUnionId[_unionID].lastAddress;
    }

    function getReward(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return reward[_unionID][_worksID];
    }

    function getFreezeHourglass(bytes32 _unionID, bytes32 _worksID) external view returns(uint256) {
        uint256 freezeGap = works.getFreezeGap(_worksID);
        if(playerCount[_unionID][_worksID].lastTime.add(freezeGap).sub(now) > 0) {
            return playerCount[_unionID][_worksID].lastTime.add(freezeGap).sub(now);
        }
        return 0;
    }

    function getMyWorks(bytes32 _unionID) external view returns (address, bytes32, uint256, uint256, uint256) {
        return (
            myworks[_unionID].ethAddress,
            myworks[_unionID].worksID,
            myworks[_unionID].totalInput,
            myworks[_unionID].totalOutput,
            myworks[_unionID].time
        );
    }

    function isLegalPlayer(bytes32 _unionID, address _address) external view returns (bool) {
        return (this.hasUnionId(_unionID) || this.hasAddress(_address)) && playersByAddress[_address] == _unionID;
    }

    function register(bytes32 _unionID, address _address, bytes32 _worksID, bytes32 _referrer) external returns (bool) {
        require(_unionID != 0 && _address != address(0) && _worksID != bytes32(0));

        require (
            (this.hasUnionId(_unionID) || this.hasAddress(_address)) && 
            playersByAddress[_address] == _unionID
        ); 

        if(this.hasAddress(_address)) {
            return false;
        }
         
        playersByUnionId[_unionID].ethAddress.push(_address);
        if(_referrer != bytes32(0)) {
            playersByUnionId[_unionID].referrer = _referrer;
        }
        playersByUnionId[_unionID].lastAddress = _address;
        playersByUnionId[_unionID].time = now;

        playersByAddress[_address] = _unionID;

        playerAddressSets.push(_address);
        playersUnionIdSets.push(_unionID);
        playerCount[_unionID][_worksID] = Datasets.PlayerCount(0, 0, 0, 0); 

        emit OnRegister(_address, _unionID, _referrer, now);

        return true;
    }

    function updateLastAddress(bytes32 _unionID, address _sender) external {
        if(playersByUnionId[_unionID].lastAddress != _sender) {
            playersByUnionId[_unionID].lastAddress = _sender;
            emit OnUpdateLastAddress(_unionID, _sender);
        }
    }

    function updateLastTime(bytes32 _unionID, bytes32 _worksID) external onlyDev() {
        playerCount[_unionID][_worksID].lastTime = now;
        emit OnUpdateLastTime(_unionID, _worksID, now);
    }

    function updateFirstBuyNum(bytes32 _unionID, bytes32 _worksID) external onlyDev() {
        playerCount[_unionID][_worksID].firstBuyNum = playerCount[_unionID][_worksID].firstBuyNum.add(1);
        emit OnUpdateFirstBuyNum(_unionID, _worksID, playerCount[_unionID][_worksID].firstBuyNum);
    }

    function updateSecondAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external onlyDev() {
        playerCount[_unionID][_worksID].secondAmount = playerCount[_unionID][_worksID].secondAmount.add(_amount);
        emit OnUpdateSecondAmount(_unionID, _worksID, _amount);
    }

    function updateFirstAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external onlyDev() {
        playerCount[_unionID][_worksID].firstAmount = playerCount[_unionID][_worksID].firstAmount.add(_amount);
        emit OnUpdateFirstAmount(_unionID, _worksID, _amount);
    }

    function updateReward(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external onlyDev() {
        reward[_unionID][_worksID] = reward[_unionID][_worksID].add(_amount);
        emit OnUpdateReward(_unionID, _worksID, _amount);
    }   

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
 * @title PuzzleBID Game 
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
contract PuzzleBID {

    using SafeMath for *;

    string constant public name = "PuzzleBID Game";
    string constant public symbol = "PZB";

    TeamInterface private team; 
    PlatformInterface private platform; 
    ArtistInterface private artist; 
    WorksInterface private works; 
    PlayerInterface private player; 
    
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

    function() external payable {
        revert();
    }

    modifier isHuman() {
        address _address = msg.sender;
        uint256 _size;

        assembly {_size := extcodesize(_address)}
        require(_size == 0, "sorry humans only");
        _;
    }

    modifier checkPlay(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID) {
        require(msg.value >= 1000000000);
        require(msg.value <= 100000000000000000000000);

        require(works.hasWorks(_worksID)); 
        require(works.hasDebris(_worksID, _debrisID)); 
        require(works.isGameOver(_worksID)); 
        require(works.isPublish(_worksID) && works.isStart(_worksID)); 
        require(works.isProtect(_worksID, _debrisID)); 
        
        require(player.isFreeze(_unionID, _worksID)); 
        require(
            (player.getFirstBuyNum(_unionID, _worksID).add(1) > works.getFirstBuyLimit(_worksID)) && 
            works.isSecond(_worksID, _debrisID)
        );       
        require(msg.value >= works.getDebrisPrice(_worksID, _debrisID)); 
        _;
    }    

    function startPlay(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, bytes32 _referrer) 
        isHuman()
        checkPlay(_worksID, _debrisID, _unionID)
        external
        payable
    {
        player.register(_unionID, msg.sender, _worksID, _referrer); 

        uint256 lastPrice = works.getLastPrice(_worksID, _debrisID); 

        works.updateDebris(_worksID, _debrisID, _unionID, msg.sender); 

        player.updateLastTime(_unionID, _worksID); 
        
        platform.updateTurnover(_worksID, msg.value); 

        platform.updateAllTurnover(msg.value); 
        
        if(works.isSecond(_worksID, _debrisID)) {
            secondPlay(_worksID, _debrisID, _unionID, lastPrice);            
        } else { 
            
            firstPlay(_worksID, _debrisID, _unionID);       
        }

        if(works.isFinish(_worksID, _debrisID, _unionID)) {
            works.updateEndTime(_worksID); 
            finishGame(_worksID);
            collectWorks(_worksID, _unionID); 
        }

    }


    function firstPlay(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID) private {    
        works.updateFirstBuyer(_worksID, _debrisID, _unionID, msg.sender);    
        player.updateFirstBuyNum(_unionID, _worksID); 
        player.updateFirstAmount(_unionID, _worksID, msg.value); 

        uint8[3] memory firstAllot = works.getAllot(_worksID, 0); 
        artist.getAddress(works.getArtistId(_worksID)).transfer(msg.value.mul(firstAllot[0]) / 100); 
        platform.getFoundAddress().transfer(msg.value.mul(firstAllot[1]) / 100); 

        works.updatePools(_worksID, msg.value.mul(firstAllot[2]) / 100); 
        platform.deposit.value(msg.value.mul(firstAllot[2]) / 100)(_worksID); 


    
    }

    function secondPlay(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, uint256 _oldPrice) private {

        works.updateLastBuyer(_worksID, _debrisID, _unionID, msg.sender);

        if(0 == player.getSecondAmount(_unionID, _worksID)) {
            works.updateSecondUnionId(_worksID, _unionID);
        }

        player.updateSecondAmount(_unionID, _worksID, msg.value);
             
        uint256 lastPrice = works.getDebrisPrice(_worksID, _debrisID);        
        if(lastPrice > _oldPrice) { 
            uint8[3] memory againAllot = works.getAllot(_worksID, 1);
            uint256 overflow = lastPrice.sub(_oldPrice); 
            artist.getAddress(works.getArtistId(_worksID)).transfer(overflow.mul(againAllot[0]) / 100); 
            platform.getFoundAddress().transfer(lastPrice.mul(againAllot[1]) / 100); 
            works.updatePools(_worksID, overflow.mul(againAllot[2]) / 100); 
            platform.deposit.value(overflow.mul(againAllot[2]) / 100)(_worksID); 

            works.getLastBuyer(_worksID, _debrisID).transfer(
                lastPrice.sub(overflow.mul(againAllot[0]) / 100)
                .sub(lastPrice.mul(againAllot[1]) / 100)
                .sub(overflow.mul(againAllot[2]) / 100)
            ); 
        } 
        else { 
            works.getLastBuyer(_worksID, _debrisID).transfer(lastPrice);
        }

    }

    function finishGame(bytes32 _worksID) private {              
        uint8 lastAllot = works.getAllot(_worksID, 2, 0);
        msg.sender.transfer(works.getPools(_worksID).mul(lastAllot / 100)); 
        firstSend(_worksID); 
        secondSend(_worksID); 
    }

    function collectWorks(bytes32 _worksID, bytes32 _unionID) private {
        player.updateMyWorks(_unionID, msg.sender, _worksID, 0, 0);
    }
    
    function firstSend(bytes32 _worksID) private {
        uint8 i;
        bytes32[] memory tmpFirstUnionId = works.getFirstUnionId(_worksID); 
        address tmpAddress; 
        uint256 tmpAmount;
        uint8 lastAllot = works.getAllot(_worksID, 2, 1);
        for(i=0; i<tmpFirstUnionId.length; i++) {
            tmpAddress = player.getLastAddress(tmpFirstUnionId[i]);
            tmpAmount = player.getFirstAmount(tmpFirstUnionId[i], _worksID);
            tmpAmount = works.getPools(_worksID).mul(lastAllot / 100).mul(tmpAmount / works.getPrice(_worksID));
            platform.transferTo(tmpAddress, tmpAmount); 
        }
    }

    function secondSend(bytes32 _worksID) private {
        uint8 i;
        bytes32[] memory tmpSecondUnionId = works.getSecondUnionId(_worksID); 
        address tmpAddress; 
        uint256 tmpAmount;
        uint8 lastAllot = works.getAllot(_worksID, 2, 2);
        for(i=0; i<tmpSecondUnionId.length; i++) {
            tmpAddress = player.getLastAddress(tmpSecondUnionId[i]);
            tmpAmount = player.getSecondAmount(tmpSecondUnionId[i], _worksID);

            tmpAmount = works.getPools(_worksID).mul(lastAllot / 100).mul(tmpAmount / platform.getTurnover(_worksID).sub(works.getPrice(_worksID)));
            platform.transferTo(tmpAddress, tmpAmount); 
        }
    }

    function getNowTime() external view returns (uint256) {
        return now;
    }

 }
 
 
