pragma solidity ^0.5.0;

import "./interface/TeamInterface.sol"; //导入管理员团队接口

/**
 * @dev PuzzleBID Game 艺术家合约
 * @author Simon<vsiryxm@163.com>
 */
contract Artist {

    TeamInterface private Team; //引入管理员，正式发布时可定义成常量
    mapping(bytes32 => address) private artists; //艺术家列表 (artistID => address)

	constructor(address _teamAddress) public {
        Team = TeamInterface(_teamAddress);
	}	

    //不接收ETH
	function() external payable {
        revert();
    }

    //事件
    event OnAdd(bytes32 _artistID, address _address);

    //仅开发者、合约地址可操作
    modifier onlyDev() {
        require(Team.isDev(msg.sender));
        _;
    }

    //根据艺术家ID获取钱包地址
    function getAddress(bytes32 _artistID) external view returns (address) {
    	return artists[_artistID];
    }

    //添加艺术家
    function add(bytes32 _artistID, address _address) external onlyDev() {
        require(this.isHasArtist(_artistID) == false); //this用法 已测
        artists[_artistID] = _address;
        emit OnAdd(_artistID, _address);
    }

    //是否存在艺术家 true为存在
    function isHasArtist(bytes32 _artistID) external view returns (bool) {
        return artists[_artistID] != address(0);
    }

}