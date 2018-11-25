pragma solidity ^0.5.0;

/**
 * @dev PuzzleBID Game 艺术家合约接口
 * @website http://www.puzzlebid.com/
 * @author PuzzleBID Game Team
 *         Simon<vsiryxm@163.com>
 */
interface Artist {

    //根据艺术家ID获取钱包地址
    function getAddress(bytes32 _artistID) external view returns (address);

    //添加艺术家
    function add(bytes32 _artistID, address _address) external;

    //是否存在艺术家
    function isHasArtist(bytes32 _artistID) external view returns (bool);

}