pragma solidity ^0.5.0;

contract Player {
    
    constructor() public {
        
    }
    
    mapping(uint256 => address) players;
    
    modifier test() {
        require(false);
        _;
    }

    function updatePlayer(uint256 _number, address _address) external test()  {
        players[_number] = _address;
    }
    
    function getPlayer(uint256 _number) external view returns (address) {
        return players[_number];
    }
    
    function getSender() external view returns (address) {
        return msg.sender;
    }
    
}

interface PlayerInterface {
    function updatePlayer(uint256 _number, address _address) external;
    function getPlayer(uint256 _number) external view returns (address);
    function getSender() external view returns (address);
}

contract PuzzleBID {
    
    PlayerInterface private player;
    
    constructor(address tokenID) public {
        player = PlayerInterface(tokenID);
    }

    function update1(uint256 _number, address _address) public {
        player.updatePlayer(_number, _address);
    }
    
    function get1() external view returns (address) {
        return player.getSender();
    }
    
    function get2() external view returns (address) {
        return this.get1();
    }
    
}

