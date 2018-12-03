1，测试合约
1），Team.sol 管理团队合约
2），Artist.sol 艺术家合约
3），TeamInterface.sol 管理合约接口
4），ArtistInterface.sol 艺术家合约接口


6）REMIX准备：
remixd -s D:\jusanban\doc\50-编码实现\BlockChain --remix-ide https://remix.ethereum.org
  
2，账户信息
TEAM: 超管(增加管理员用)，管理员()，开发者(增加艺术家，)  

owner超管王总：0xca35b7d915458ef540ade6068dfe2f44e8fa733c
开发者欧阳：0x14723a09acff6d2a60dcdf7aa4aff308fddc160c
公司经理辉哥：0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db
艺术家大明：0x583031d1113ad414f02576bd6afabfb302140225
富婆ELLA小姐姐：0xdd870fa1b7c4700f2bd7f44238821c26f7392148
山药批发商土豪丁恒：0xe606672011764c10067cb5f60f9b8538ffeefc90
基金会&存放激励池地址：0x874013312e758038742f67284d9ecd8d0ae7e078

3,管理团队合约用例Team.sol
1）constructor(address _owner) ：构建合约，owner超管王总账号下，
constructor("0xca35b7d915458ef540ade6068dfe2f44e8fa733c")

预期结果：超管不是自动就成为管理员的，要updateAdmin添加才能成为管理员。
结果：合约地址-0x692a70d2e424a56d2c6c27aa97d1a86395877b3a

2）updateAdmin：更新管理员成员，这儿可以增加各种异常测试
1] 开发者欧阳账号下，增加自己为管理员，"ouyangxinming"的MD5：6853fef6fa8ab419d2ae44bc857ce5f4
updateAdmin("0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", true, true, "0x6853fef6fa8ab419d2ae44bc857ce5f4")
预期结果：失败
结果：OK

2] owner超管王总账号下，增加欧阳账号为管理员，非开发者，名字长度超过32，为"ouyangxinmingshigejishudaniu!"
updateAdmin("0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", true, false, "ouyangxinmingshigejishudaniu")
预期结果：报错
结果：

3] owner超管王总账号下，增加欧阳账号为非管理员，开发者,ouyangxinming的MD5:0x6853fef6fa8ab419d2ae44bc857ce5f4
updateAdmin("0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", false, true, "0x6853fef6fa8ab419d2ae44bc857ce5f4")
预期结果：成功
结果：OK

4] owner超管王总账号下，增加王登辉为管理员，非开发者，wangminghui的MD5:
updateAdmin("0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", true, false, "0xf2fff4d1f62b1a55b498a771f2070f9c")
预期结果：成功
结果：

5] 查询王总，王登辉，欧阳的地址是否是以下信息
owner超管王总： "0xca35b7d915458ef540ade6068dfe2f44e8fa733c"
开发者欧阳： "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c"
公司经理王登辉： "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db"

isOwner：是否为超管
isAdmin：是否为管理员
isDev：是否为开发者、合约地址


4,艺术家合约用例 Artist.sol
1] constructor(address _teamAddress)：构建艺术家合约,
超管王总账号（"0xca35b7d915458ef540ade6068dfe2f44e8fa733c"）下，team地址用上次创建的地址
constructor("0x692a70d2e424a56d2c6c27aa97d1a86395877b3a")
预计结果：创建成功
结果：OK，合约地址为0x5e72914535f202659083db3a02c984188fa26e9f


2] add：添加艺术家, 大明("0x583031d1113ad414f02576bd6afabfb302140225"),+8615756261450的MD5：0x43afeb855df1c81e1075bc633f134067
开发者欧阳("0x14723a09acff6d2a60dcdf7aa4aff308fddc160c")账号下操作:
add("0x43afeb855df1c81e1075bc633f134067", "0x583031d1113ad414f02576bd6afabfb302140225")
预计结果：添加成功
结果：OK

3] hasArtist：是否存在艺术家 true为存在
hasArtist("0x43afeb855df1c81e1075bc633f134067")
预计结果：true
结果：OK

4] getAddress：根据艺术家ID获取钱包地址
getAddress("0x43afeb855df1c81e1075bc633f134067")
预计结果：true
结果：OK
5] 打ETH给艺术家合约
超管王总账号（"0xca35b7d915458ef540ade6068dfe2f44e8fa733c"）下打1个ETH给智能合约地址("0x8c1ed7e19abaa9f23c476da86dc1577f1ef401f5")
方法：智能合约测试函数
pragma solidity ^0.5.0;

contract Test {
    
    constructor() public {
        
    }

    function test2(address payable  _address) external payable{
        address(_address).transfer(msg.value);
    }

    
}
调用：
test2("0x5e72914535f202659083db3a02c984188fa26e9f")
预计结果：合约执行失败，返回值
结果：OK

6,平台合约用例 Platform.sol
0] 合约全局变量，
作品worksID为的编号《梦境绚烂》A20181102203# 对应的32位MD5编码："0xfd461f4090c316248174cc479a8dab44"
uint256 allTurnover; //平台总交易额
mapping(bytes32 => uint256) turnover; //作品的交易额 (worksID => amount)

1] owner超管王总账号创建平台合约，_teamAddress为签名创建的TEAM智能合约地址 0x692a70d2e424a56d2c6c27aa97d1a86395877b3a
constructor(address _foundAddress, address _teamAddress)
constructor("0x874013312e758038742f67284d9ecd8d0ae7e078","0x692a70d2e424a56d2c6c27aa97d1a86395877b3a")
预期结果：创建成功
结果：OK，合约地址为0x08970fed061e7747cd9a38d680a601510cb659fb

2] owner超管王总账号创建平台合约,异常参数
constructor()
constructor("0x874013312e758038742f67284d9ecd8d0ae7e078","0x0")
constructor("0x874013312e758038742f67284d9ecd8d0ae7e078",0x692a70d2e424a56d2c6c27aa97d1a86395877b3a)
预期结果：失败
结果：OK

3] updateFoundation()更新平台基金会address 仅管理员可操作
   在开发者欧阳账号下，在管理员账号王登辉账号下，把基金会地址更新为大明地址，然后更新回来
updateFoundation(address _foundation)
updateFoundation("0x583031d1113ad414f02576bd6afabfb302140225");
updateFoundation("0x874013312e758038742f67284d9ecd8d0ae7e078");

预期结果：第一个失败，第二个成功
结果：OK

4] getFoundAddress()获取基金会address
 getFoundAddress()
 预期结果：地址为 "0x583031d1113ad414f02576bd6afabfb302140225"
 结果：OK
 
【更新】 updateFoundation("0x874013312e758038742f67284d9ecd8d0ae7e078");

5] updateTurnover()更新作品的交易额 仅开发者、合约地址可操作
updateTurnover(bytes32 _worksID, uint256 _amount)
_worksID为A20181102203的MD5值：fd461f4090c316248174cc479a8dab44
_amount：1个ETH
updateTurnover("0xfd461f4090c316248174cc479a8dab44", "2,000000000000000000")
预期结果：成功
实际结果：OK


6] getTurnover()获取作品的交易额
getTurnover(bytes32 _worksID) 
getTurnover("0xfd461f4090c316248174cc479a8dab44")
预期结果：每次累计增加
结果：OK

7] updateAllTurnover()更新平台总交易额 仅开发者、合约地址可操作
   在开发者欧阳账号下，在管理员账号王登辉账号下，
updateAllTurnover(uint256 _amount)
10个ETH
updateAllTurnover("10,000000000000000000")
预期结果：成功
结果：OK

8] getAllTurnover()获取平台总交易额
预期结果：每次累计增加
结果：OK

9] deposit()平台合约代为保管奖池中的ETH
deposit(bytes32 _worksID)
deposit("0xfd461f4090c316248174cc479a8dab44")
需要增加测试函数，打1个ETH

46个故障，未解决14个，已解决32个

【询问】是不是只有开发者或者智能合约才能保存奖池ETH呢？如果其他人工也可以保存，会出现什么问题呢？
【询问】OnDeposit(_worksID, msg.sender, msg.value); 欧阳现在保存用的是msg.value的值，不是交易的值。后面再做修改。
测试函数转账到该地址为1个ETH
预期结果：
结果：
 
10] getThisBalance查询奖池实际余额 仅开发者、合约地址可操作
   在开发者欧阳账号下，在管理员账号王登辉账号下，
getThisBalance() external view onlyDev() 


11] 打ETH给平台合约



5,作品碎片合约用例 

7，玩家合约用例

