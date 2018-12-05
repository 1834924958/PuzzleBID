pragma solidity ^0.5.0;


/**
 * @title PuzzleBID Game 管理员团队合约
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
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
        owner = _owner;

    }

    //事件
    event OnAddAdmin(
        address indexed _address, 
        bool _isAdmin, 
        bool _isDev, 
        bytes32 _name
    );
    event OnRemoveAdmin(address indexed _address);

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
