pragma solidity ^0.4.24;

/**
 * @dev PuzzleBID Game 平台合约
 * @author Simon<vsiryxm@163.com>
 */
contract Platform {

	address foundation; //平台address

	constructor(address _address) public {
		require(_address != address(0));
		foundation = _address;
	}

	function() external payable {
        revert();
    }

    uint256 allTurnover; //平台总交易额
    mapping(bytes32 => uint256) turnover; //作品的交易额

    //获取平台总交易额
    function getAllTurnover() external returns (uint256) {
    	return allTurnover;
    }

    //更新平台总交易额
    function updateAllTurnover(uint256 _amount) internal {
    	allTurnover = allTurnover.add(_amount); 
    }

    //获取作品的交易额
    function getTurnover(bytes32 _worksID) external returns (uint256) {
    	return turnover[_worksID];
    }

    //更新作品的交易额
    function updateTurnover(bytes32 _worksID, uint256 _amount) internal {
    	allTurnover = allTurnover.add(_amount); 
    }


}