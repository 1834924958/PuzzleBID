pragma solidity ^0.4.24;


contract Test{

    uint256 public val;
    
    modifier onlyDevs() {
        //TODO:
        require(
            msg.sender == 0x006B332340d355280B3F7aa2b33ea0AB0f5706E9 ||
            msg.sender == 0x006b079229BbEd6233d032334F859AC5712A6255 ||
            msg.sender == 0x0092E2EEEca35da462cEc54F5CF4C2C6fc950483 ||
            msg.sender == 0x002843c23d08e1A1f1597B2A2fe860e26e3a0C21,
            "only team just can activate"
        );
        _;
    }

    event Set(address add, uint256 val);

    constructor()
        public
    {
    }

    function setVal(uint256 _val)
        onlyDevs()
        public
        {
            emit Set(msg.sender, _val);
            val = _val;
    }
}