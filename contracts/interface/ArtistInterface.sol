pragma solidity ^0.5.0;

/**
 * @title PuzzleBID Game 艺术家合约
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<vsiryxm@163.com>
 */
interface ArtistInterface {

    //根据艺术家ID获取钱包地址
    function getAddress(bytes32 _artistID) external view returns (address payable);

    //添加艺术家
    function add(bytes32 _artistID, address _address) external;

    //是否存在艺术家 true为存在
    function hasArtist(bytes32 _artistID) external view returns (bool);

    //更新艺术家address
    function updateAddress(bytes32 _artistID, address _address) external;

}