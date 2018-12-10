pragma solidity ^0.4.24;
// 看不到代码 合约地址:  0x4C7B8591C50F4AD308d07D6294F2945e074420F5
// 根据链上的数据把结果放在这里
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';


contract JekyllIsland is Ownable {
    using SafeMath for uint256;

    event RefundValue(address, uint256 value);
    event DepositValue(address investor, uint256 value);

    address public wallet;


    modifier validAddress( address addr ) {
        require(addr != address(0x0));
        _;
    }


    constructor(address _wallet)
        validAddress(_wallet)
        public
    {
        wallet = _wallet;
    }

    mapping (address => uint256) public deposited;

    function deposit(address investor) 
        validAddress(investor)
        external payable 
        returns (bool){
        deposited[investor] = deposited[investor].add(msg.value);

        emit DepositValue(investor, msg.value);

        return true;
    }

    function migrationReceiver_setup() external 
        returns (bool){
        return (wallet != address(0));
    }

    function setWallet(address _wallet) onlyOwner public  {
        require(_wallet != address(0));
        wallet = _wallet;
    }

    function refund() onlyOwner public {
        emit RefundValue(wallet, address(this).balance);
        wallet.transfer(address(this).balance);
    }
}
