// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ITicketNFT} from "./interfaces/ITicketNFT.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract TicketNFT is ERC1155, ITicketNFT {
  address public owner;

  constructor() ERC1155("https://alireza.token.sh") {
    owner = msg.sender;
  }

  function mintFromMarketPlace(address to, uint256 nftId) external {
    _mint(to, nftId, 1, "");
  }

    // your code goes here (you can do it!)
}
