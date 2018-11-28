pragma solidity ^0.5.0;

/**
 * @title PuzzleBID Game 管理员团队合约接口
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
interface TeamInterface {

    //更新管理员成员
    function updateAdmin(address _address, bool _isAdmin, bool _isDev, bytes32 _name) external;
    //抽象方法可以扩展modifer，已测

    //是否为超管
    function isOwner() external view returns (bool);

    //是否为管理员
    function isAdmin(address _sender) external view returns (bool);

    //是否为开发者、合约地址
    function isDev(address _sender) external view returns (bool);

}

