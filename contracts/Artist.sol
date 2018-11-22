pragma solidity ^0.4.24;

/**
 * @dev PuzzleBID Game Artist
 * @author Simon<vsiryxm@163.com>
 */
contract Artist {

	constructor() public {

	}

	mapping(bytes32 => address) artists; //艺术家列表 (id => address)

	function() external payable {
        revert();
    }

    //根据艺术家ID获取钱包地址
    function getAddress(bytes32 _artistID) external returns (address) {
    	return artists[_artistID];
    }

    //添加艺术家
    function add() {

    }

}