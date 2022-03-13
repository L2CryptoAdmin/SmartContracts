// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './ValakasCoin.sol';

contract BetaKeyManager {

    address payable private admin;
    address payable private rewards_pool = payable('rewardspoolsaddress');
    uint256 public betaKeysSold;
    uint256 public maxBetaKeys;
    uint256 public totalBetaKeys;
    ValakasCoin public token;
    bool public is_destroyed;

    event KeySold (
        uint256 id,
        address bk_owner,
        string beta_key,
        string beta_type,
        uint256 delivered
    );

    struct Key {
        uint256 id;
        address bk_owner;
        string beta_key;
        string beta_type;
        uint256 delivered;
    }

    mapping (address => Key) public betaKeys;
    mapping (address => bool) public owners;
    mapping (address => uint256) public refers;

    constructor(ValakasCoin _token, uint256 _maxBetaKeys){
        admin = payable(msg.sender);
        maxBetaKeys = _maxBetaKeys;
        token = _token;
        is_destroyed = false;
    }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        _a = string(abi.encodePacked('0x', _a));
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function calcBetaPrice(string memory _betaType) public pure returns(int) {
            // 0.075 BNB
        int price = 750;
        if(compareStrings(_betaType, 'PRO')){
            // 0.1125 BNB
            price = 1125;
        } else if(compareStrings(_betaType, 'XTR')){
            // 0.2750 BNB
            price = 2750;
        }
        return price;
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function buyBetaKey(string memory _betaType, address payable _referAddress, string memory _stringBetaKey) public payable {
        // check if contract still live
        require(!is_destroyed);

        // check price
        int betakey_price = calcBetaPrice(_betaType);
        int betakey_price_final = betakey_price * 10 ** 14; // 14 because betakey_price * 10 ** 18 / 10000 ==> betakey_price * 10 ** 14

        // We verify that the sender has enough money to buy the betakey.
        require(int(msg.value) >= betakey_price_final);
        // We verify that the sender does not have a betakey
        require(owners[msg.sender] == false);
        // We verify that beta keys are available
        require(betaKeysSold < maxBetaKeys);
        // funds transfer
        rewards_pool.transfer(msg.value);

        // We distribute the VKC to the owner and the referrer.
        uint256 vkc_amount = 100000000000000000000;
        uint256 vkc_refer = 10000000000000000000;
        uint256 vkc_total = 110000000000000000000;
        if(compareStrings(_betaType, 'PRO')){
            vkc_amount = vkc_amount * 2;
            vkc_refer = vkc_refer * 2;
            vkc_total = vkc_total * 2;
        }
        if(compareStrings(_betaType, 'XTR')){
            vkc_amount = vkc_amount * 4;
            vkc_refer = vkc_refer * 4;
            vkc_total = vkc_total * 4;
        }
        require(token.balanceOf(address(this)) >= vkc_total);
        require(token.transfer(msg.sender, vkc_amount));
        require(token.transfer(_referAddress, vkc_refer));

        // Beta Key Register
        betaKeysSold++;
        totalBetaKeys++;
        betaKeys[msg.sender] = Key(totalBetaKeys, msg.sender, _stringBetaKey, _betaType, block.timestamp);
        owners[msg.sender] = true;
        refers[_referAddress] += vkc_refer;

        emit KeySold(totalBetaKeys, msg.sender, _stringBetaKey, _betaType, block.timestamp);
    }

    // if somebody wins a beta_key :)
    // This type of Beta Keys not affect maxBetaKeys or betaKeysSold
    function giftBetaKey(string memory _betaType, address payable _ownerBetaKey, string memory _stringBetaKey) public payable {
        require(msg.sender == admin);

        // check if contract still live
        require(!is_destroyed);

        // We verify that the _ownerBetaKey does not have a betakey
        require(owners[_ownerBetaKey] == false);

        // BetaKey Register
        totalBetaKeys++;
        betaKeys[_ownerBetaKey] = Key(totalBetaKeys, _ownerBetaKey, _stringBetaKey, _betaType, block.timestamp);
        owners[_ownerBetaKey] = true;

        emit KeySold(totalBetaKeys, msg.sender, _stringBetaKey, _betaType, block.timestamp);
    }

    // if i need extend the betakey sale
    function setNewMaxBetaKeys(uint256 _newMaxBetaKeys) public payable {
        require(msg.sender == admin);

        // check if contract still live
        require(!is_destroyed);

        maxBetaKeys = _newMaxBetaKeys;
    }

    // Getters [Only view]
    function getBetaKey(address _address) public view returns(Key memory){
        if(owners[_address] == true){
            Key memory _key = betaKeys[_address];
            return _key;
        } else {
            Key memory _key = Key(betaKeysSold, msg.sender, '', '', 0);
            return _key;
        }
    }

    function getTotalRefer(address _address) public view returns(uint256){
        uint256 vkc_refer = refers[_address];
        return vkc_refer;
    }

    function getBetaKeyBackend(string memory _stringAddress) public view returns(string memory){

        address _address = parseAddr(_stringAddress);

        if(owners[_address] == true){
            Key memory _key = betaKeys[_address];
            string memory resultado = string(abi.encodePacked(_key.beta_key, '-', _key.beta_type));
            return resultado;

        } else {
            string memory result = 'NOBK';
            return result;
        }
    }

    // Contract kill
    function endSale() public {
        require(msg.sender == admin);
        uint256 amount = token.balanceOf(address(this));
        require(token.transfer(admin, amount));
        is_destroyed = true;
    }

    function destroyContract() public {
        require(msg.sender == admin);
        is_destroyed = true;
        selfdestruct(payable(admin));
    }
}
