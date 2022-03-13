// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract ValakasCoin is ERC20 {
    constructor() ERC20('Valakas Coin', "VKC"){
        _mint(msg.sender, 21000000 * 10 ** 18);
    }
}
