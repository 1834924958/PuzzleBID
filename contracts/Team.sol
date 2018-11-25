pragma solidity ^0.5.0;

/**
 * @dev PuzzleBID Game 管理员团队合约
 * @website http://www.puzzlebid.com/
 * @author PuzzleBID Game Team
 *         Simon<vsiryxm@163.com>
 */
contract Team {

	address public owner; //超级管理员

	//管理员角色：开发团队、管理员
	struct Admin {
        bool isAdmin; //true 为超级管理员 有关后台函数设计，都需要管理员权限
        bool isDev; //true 为开发团队 有关合约间通信，都需要开发团队权限
        bytes32 name; //管理员名字
    }

    mapping (address => Admin) admins; //管理员列表

    constructor(address _owner) public {
    	//游戏基金会成员地址
    	//主要权限：多签、成员罢免、合约升级迁移
        //address inventor = 0x00B04d6D08748B073E4D827A7DA515Cb13921c0c;
        //address mantso   = 0x00D8E8CCb4A29625D299798036825f3fa349f2b4;
        //address justo    = 0x00E878b353127CF93BfC864422222785A27E290a;
        //address sumpunk  = 0x0020116131498D968DeBCF75E5A11F77e7e1CadE;
        
        //admins[inventor] = Admin(true, true, "inventor");
        //admins[mantso]   = Admin(true, true, "mantso");
        //admins[justo]    = Admin(true, true, "justo");
        //admins[sumpunk]  = Admin(true, true, "sumpunk");

        //adminCount_ = 4;
        //devCount_ = 4;
        //requiredSignatures_ = 1;
        //requiredDevSignatures_ = 1;
        owner = _owner;

    }

    //仅超级管理员可操作
    modifier onlyOwner() {
    	require(msg.sender == owner);
    	_;
    }

    //更新管理员成员
    function updateAdmin(address _address, bool _isAdmin, bool _isDev, bytes32 _name) external onlyOwner() {
    	admins[_address] = Admin(_isAdmin, _isDev, _name);
    }

    //是否为超管
    function isOwner() external view returns (bool) {
    	return owner == msg.sender;
    }

    //是否为管理员
    function isAdmin(address _sender) external view returns (bool) {
    	return admins[_sender].isAdmin;
    }

    //是否为开发者、合约地址
    function isDev(address _sender) external view returns (bool) {
    	return admins[_sender].isDev;
    }


}

