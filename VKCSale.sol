// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ValakasCoin.sol';

contract VKCSale {
    address payable private admin;
    address payable private ethFunds;
    ValakasCoin public token;
    uint256 public tokensSold;
    uint256 public transactionCount;
    bool public is_destroyed;

    event Sell(address _buyer, uint256 _amount);

    struct Transaction {
        address buyer;
        uint256 amount;
    }

    mapping(uint256 => Transaction) public transaction;

    constructor(ValakasCoin _token) {
        admin = payable(msg.sender);
        ethFunds = payable(msg.sender);
        token = _token;
        is_destroyed = false;
    }

    function buyToken(uint256 _amount) public payable {
        // Check if contract still live.
        require(!is_destroyed);
        
        // Price 50 -> 0.0005
        int token_price_inbnb = 50 * 10**13;
        require(int(msg.value) >= token_price_inbnb * int(_amount));

        uint256 amountWithDecimals = _amount * 10 **18;

        // Check this contract balance
        require(token.balanceOf(address(this)) >= amountWithDecimals);

        // Transfer tokens to buyer
        require(token.transfer(msg.sender, amountWithDecimals));

        // Trasnfer BNB to owner
        ethFunds.transfer(msg.value);

        // Transaction register
        tokensSold += amountWithDecimals;
        transaction[transactionCount] = Transaction(msg.sender, amountWithDecimals);
        transactionCount++;
        emit Sell(msg.sender, amountWithDecimals);
    }

    function endSale() public {
        require(msg.sender == admin);
        uint256 amount = token.balanceOf(address(this));
        require(token.transfer(admin, amount));
    }

    function destroyContract() public {
        require(msg.sender == admin);
        is_destroyed = true;
        selfdestruct(payable(admin));
    }

}
