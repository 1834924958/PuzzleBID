1�����Ժ�Լ
1����Team.sol �����ŶӺ�Լ
2����Artist.sol �����Һ�Լ
3����TeamInterface.sol �����Լ�ӿ�
4����ArtistInterface.sol �����Һ�Լ�ӿ�


6��REMIX׼����
remixd -s D:\jusanban\doc\50-����ʵ��\BlockChain --remix-ide https://remix.ethereum.org
  
2���˻���Ϣ
TEAM: ����(���ӹ���Ա��)������Ա()��������(���������ң�)  

owner�������ܣ�0xca35b7d915458ef540ade6068dfe2f44e8fa733c
������ŷ����0x14723a09acff6d2a60dcdf7aa4aff308fddc160c
��˾����Ը磺0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db
�����Ҵ�����0x583031d1113ad414f02576bd6afabfb302140225
����ELLAС��㣺0xdd870fa1b7c4700f2bd7f44238821c26f7392148
ɽҩ�������������㣺0xe606672011764c10067cb5f60f9b8538ffeefc90
�����&��ż����ص�ַ��0x874013312e758038742f67284d9ecd8d0ae7e078

3,�����ŶӺ�Լ����Team.sol
1��constructor(address _owner) ��������Լ��owner���������˺��£�
constructor("0xca35b7d915458ef540ade6068dfe2f44e8fa733c")

Ԥ�ڽ�������ܲ����Զ��ͳ�Ϊ����Ա�ģ�ҪupdateAdmin��Ӳ��ܳ�Ϊ����Ա��
�������Լ��ַ-0x692a70d2e424a56d2c6c27aa97d1a86395877b3a

2��updateAdmin�����¹���Ա��Ա������������Ӹ����쳣����
1] ������ŷ���˺��£������Լ�Ϊ����Ա��"ouyangxinming"��MD5��6853fef6fa8ab419d2ae44bc857ce5f4
updateAdmin("0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", true, true, "0x6853fef6fa8ab419d2ae44bc857ce5f4")
Ԥ�ڽ����ʧ��
�����OK

2] owner���������˺��£�����ŷ���˺�Ϊ����Ա���ǿ����ߣ����ֳ��ȳ���32��Ϊ"ouyangxinmingshigejishudaniu!"
updateAdmin("0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", true, false, "ouyangxinmingshigejishudaniu")
Ԥ�ڽ��������
�����

3] owner���������˺��£�����ŷ���˺�Ϊ�ǹ���Ա��������,ouyangxinming��MD5:0x6853fef6fa8ab419d2ae44bc857ce5f4
updateAdmin("0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", false, true, "0x6853fef6fa8ab419d2ae44bc857ce5f4")
Ԥ�ڽ�����ɹ�
�����OK

4] owner���������˺��£��������ǻ�Ϊ����Ա���ǿ����ߣ�wangminghui��MD5:
updateAdmin("0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", true, false, "0xf2fff4d1f62b1a55b498a771f2070f9c")
Ԥ�ڽ�����ɹ�
�����

5] ��ѯ���ܣ����ǻԣ�ŷ���ĵ�ַ�Ƿ���������Ϣ
owner�������ܣ� "0xca35b7d915458ef540ade6068dfe2f44e8fa733c"
������ŷ���� "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c"
��˾�������ǻԣ� "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db"

isOwner���Ƿ�Ϊ����
isAdmin���Ƿ�Ϊ����Ա
isDev���Ƿ�Ϊ�����ߡ���Լ��ַ


4,�����Һ�Լ���� Artist.sol
1] constructor(address _teamAddress)�����������Һ�Լ,
���������˺ţ�"0xca35b7d915458ef540ade6068dfe2f44e8fa733c"���£�team��ַ���ϴδ����ĵ�ַ
constructor("0x692a70d2e424a56d2c6c27aa97d1a86395877b3a")
Ԥ�ƽ���������ɹ�
�����OK����Լ��ַΪ0x5e72914535f202659083db3a02c984188fa26e9f


2] add�����������, ����("0x583031d1113ad414f02576bd6afabfb302140225"),+8615756261450��MD5��0x43afeb855df1c81e1075bc633f134067
������ŷ��("0x14723a09acff6d2a60dcdf7aa4aff308fddc160c")�˺��²���:
add("0x43afeb855df1c81e1075bc633f134067", "0x583031d1113ad414f02576bd6afabfb302140225")
Ԥ�ƽ������ӳɹ�
�����OK

3] hasArtist���Ƿ���������� trueΪ����
hasArtist("0x43afeb855df1c81e1075bc633f134067")
Ԥ�ƽ����true
�����OK

4] getAddress������������ID��ȡǮ����ַ
getAddress("0x43afeb855df1c81e1075bc633f134067")
Ԥ�ƽ����true
�����OK
5] ��ETH�������Һ�Լ
���������˺ţ�"0xca35b7d915458ef540ade6068dfe2f44e8fa733c"���´�1��ETH�����ܺ�Լ��ַ("0x8c1ed7e19abaa9f23c476da86dc1577f1ef401f5")
���������ܺ�Լ���Ժ���
pragma solidity ^0.5.0;

contract Test {
    
    constructor() public {
        
    }

    function test2(address payable  _address) external payable{
        address(_address).transfer(msg.value);
    }

    
}
���ã�
test2("0x5e72914535f202659083db3a02c984188fa26e9f")
Ԥ�ƽ������Լִ��ʧ�ܣ�����ֵ
�����OK

6,ƽ̨��Լ���� Platform.sol
0] ��Լȫ�ֱ�����
��ƷworksIDΪ�ı�š��ξ�Ѥ�á�A20181102203# ��Ӧ��32λMD5���룺"0xfd461f4090c316248174cc479a8dab44"
uint256 allTurnover; //ƽ̨�ܽ��׶�
mapping(bytes32 => uint256) turnover; //��Ʒ�Ľ��׶� (worksID => amount)

1] owner���������˺Ŵ���ƽ̨��Լ��_teamAddressΪǩ��������TEAM���ܺ�Լ��ַ 0x692a70d2e424a56d2c6c27aa97d1a86395877b3a
constructor(address _foundAddress, address _teamAddress)
constructor("0x874013312e758038742f67284d9ecd8d0ae7e078","0x692a70d2e424a56d2c6c27aa97d1a86395877b3a")
Ԥ�ڽ���������ɹ�
�����OK����Լ��ַΪ0x08970fed061e7747cd9a38d680a601510cb659fb

2] owner���������˺Ŵ���ƽ̨��Լ,�쳣����
constructor()
constructor("0x874013312e758038742f67284d9ecd8d0ae7e078","0x0")
constructor("0x874013312e758038742f67284d9ecd8d0ae7e078",0x692a70d2e424a56d2c6c27aa97d1a86395877b3a)
Ԥ�ڽ����ʧ��
�����OK

3] updateFoundation()����ƽ̨�����address ������Ա�ɲ���
   �ڿ�����ŷ���˺��£��ڹ���Ա�˺����ǻ��˺��£��ѻ�����ַ����Ϊ������ַ��Ȼ����»���
updateFoundation(address _foundation)
updateFoundation("0x583031d1113ad414f02576bd6afabfb302140225");
updateFoundation("0x874013312e758038742f67284d9ecd8d0ae7e078");

Ԥ�ڽ������һ��ʧ�ܣ��ڶ����ɹ�
�����OK

4] getFoundAddress()��ȡ�����address
 getFoundAddress()
 Ԥ�ڽ������ַΪ "0x583031d1113ad414f02576bd6afabfb302140225"
 �����OK
 
�����¡� updateFoundation("0x874013312e758038742f67284d9ecd8d0ae7e078");

5] updateTurnover()������Ʒ�Ľ��׶� �������ߡ���Լ��ַ�ɲ���
updateTurnover(bytes32 _worksID, uint256 _amount)
_worksIDΪA20181102203��MD5ֵ��fd461f4090c316248174cc479a8dab44
_amount��1��ETH
updateTurnover("0xfd461f4090c316248174cc479a8dab44", "2,000000000000000000")
Ԥ�ڽ�����ɹ�
ʵ�ʽ����OK


6] getTurnover()��ȡ��Ʒ�Ľ��׶�
getTurnover(bytes32 _worksID) 
getTurnover("0xfd461f4090c316248174cc479a8dab44")
Ԥ�ڽ����ÿ���ۼ�����
�����OK

7] updateAllTurnover()����ƽ̨�ܽ��׶� �������ߡ���Լ��ַ�ɲ���
   �ڿ�����ŷ���˺��£��ڹ���Ա�˺����ǻ��˺��£�
updateAllTurnover(uint256 _amount)
10��ETH
updateAllTurnover("10,000000000000000000")
Ԥ�ڽ�����ɹ�
�����OK

8] getAllTurnover()��ȡƽ̨�ܽ��׶�
Ԥ�ڽ����ÿ���ۼ�����
�����OK

9] deposit()ƽ̨��Լ��Ϊ���ܽ����е�ETH
deposit(bytes32 _worksID)
deposit("0xfd461f4090c316248174cc479a8dab44")
��Ҫ���Ӳ��Ժ�������1��ETH

46�����ϣ�δ���14�����ѽ��32��

��ѯ�ʡ��ǲ���ֻ�п����߻������ܺ�Լ���ܱ��潱��ETH�أ���������˹�Ҳ���Ա��棬�����ʲô�����أ�
��ѯ�ʡ�OnDeposit(_worksID, msg.sender, msg.value); ŷ�����ڱ����õ���msg.value��ֵ�����ǽ��׵�ֵ�����������޸ġ�
���Ժ���ת�˵��õ�ַΪ1��ETH
Ԥ�ڽ����
�����
 
10] getThisBalance��ѯ����ʵ����� �������ߡ���Լ��ַ�ɲ���
   �ڿ�����ŷ���˺��£��ڹ���Ա�˺����ǻ��˺��£�
getThisBalance() external view onlyDev() 


11] ��ETH��ƽ̨��Լ



5,��Ʒ��Ƭ��Լ���� 

7����Һ�Լ����

