pragma solidity ^0.5.0;

import "./interface/TeamInterface.sol"; //导入管理员团队合约接口

/**
 * @title PuzzleBID Game 艺术家合约
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
contract Artist {

    TeamInterface private team; //实例化管理员合约，正式发布时可定义成常量
    mapping(bytes32 => address payable) private artists; //艺术家列表 (artistID => address)

    constructor(address _teamAddress) public {
        require(_teamAddress != address(0));
        team = TeamInterface(_teamAddress);
    }

    //不接收ETH
    function() external payable {
        revert();
    }

    //事件
    event OnUpgrade(address indexed _teamAddress);
    event OnAdd(bytes32 _artistID, address indexed _address);
    event OnUpdateAddress(bytes32 _artistID, address indexed _address);

    //仅管理员可操作
    modifier onlyAdmin() {
        require(team.isAdmin(msg.sender));
        _;
    }

    //更新升级
    function upgrade(address _teamAddress) external onlyAdmin() {
        require(_teamAddress != address(0));
        team = TeamInterface(_teamAddress);
        emit OnUpgrade(address _teamAddress);
    }

    //根据艺术家ID获取钱包地址
    function getAddress(bytes32 _artistID) external view returns (address payable) {
        return artists[_artistID];
    }

    //添加艺术家
    function add(bytes32 _artistID, address payable _address) external onlyAdmin() {
        require(this.hasArtist(_artistID) == false);
        artists[_artistID] = _address;
        emit OnAdd(_artistID, _address);
    }

    //是否存在艺术家 true为存在
    function hasArtist(bytes32 _artistID) external view returns (bool) {
        return artists[_artistID] != address(0);
    }

    //更新艺术家address
    function updateAddress(bytes32 _artistID, address payable _address) external onlyAdmin() {
        require(artists[_artistID] != address(0) && _address != address(0));
        artists[_artistID] = _address;
        emit OnUpdateAddress(_artistID, _address);
    }

}