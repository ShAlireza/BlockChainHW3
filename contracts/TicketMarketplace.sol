// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
// import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {
  address public owner;
  uint128 private eventCounter;
  uint128 public currentEventId;
  TicketNFT public nftContract;
  IERC20 public ERC20Address;

  struct Event {
    uint128 id;
    uint128 maxTickets;
    uint256 pricePerTicket;
    uint256 pricePerTicketERC20;
    uint128 nextTicketToSell;
  }

  mapping(uint128 => Event) public events;

  constructor(address erc20Address) {
    owner = msg.sender;
    eventCounter = 0;
    currentEventId = 0;
    nftContract = new TicketNFT();
    ERC20Address = IERC20(erc20Address);
  }

  modifier authorization() {
    require(msg.sender == owner, "Unauthorized access");
    _;
  }

  function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external override authorization {

    Event memory newEvent = Event({
      id: currentEventId,
      maxTickets: maxTickets,
      pricePerTicket: pricePerTicket,
      pricePerTicketERC20: pricePerTicketERC20,
      nextTicketToSell: 0
    });

    // events.push(newEvent);
    events[newEvent.id] = newEvent;

    currentEventId += 1;

    emit EventCreated(newEvent.id, maxTickets, pricePerTicket, pricePerTicketERC20);
  }
  
  function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external override authorization {
    require(newMaxTickets >= events[eventId].maxTickets, "The new number of max tickets is too small!");

    events[eventId].maxTickets = newMaxTickets;
  
    emit MaxTicketsUpdate(eventId, newMaxTickets);
  }
  
  function setPriceForTicketETH(uint128 eventId, uint256 price) external override authorization {
    events[eventId].pricePerTicket = price;
    emit PriceUpdate(eventId, price, "ETH");
  }
  
  function setPriceForTicketERC20(uint128 eventId, uint256 price) external override authorization {
    events[eventId].pricePerTicketERC20 = price;
  
    emit PriceUpdate(eventId, price, "ERC20");
  }
  
  function buyTickets(uint128 eventId, uint128 ticketCount) payable external {
    uint256 total;

    try this.totalPrice(ticketCount, events[eventId].pricePerTicket) returns (uint256 out) {
      total = out;
    } catch {
      revert("Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
    }

    require(msg.value >= total, "Not enough funds supplied to buy the specified number of tickets.");

    uint128 ticketsLeft = events[eventId].maxTickets - events[eventId].nextTicketToSell;
    require(ticketCount <= ticketsLeft, "We don't have that many tickets left to sell!");

    for (uint128 i = 0; i < ticketCount; i++) {
      nftContract.mintFromMarketPlace(
        msg.sender,
        (uint256(eventId) << 128) | uint256(events[eventId].nextTicketToSell + i)
      );
    }

    events[eventId].nextTicketToSell += ticketCount;
  
    emit TicketsBought(eventId, ticketCount, "ETH");
  }
  
  function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external {
    uint256 total;

    try this.totalPrice(ticketCount, events[eventId].pricePerTicketERC20) returns (uint256 out) {
      total = out;
    } catch {
      revert("Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
    }
  
    uint128 ticketsLeft = events[eventId].maxTickets - events[eventId].nextTicketToSell;

    require(ticketCount <= ticketsLeft, "We don't have that many tickets left to sell!");

    bool success = ERC20Address.transferFrom(msg.sender, address(this), total);
    require(success);

    for (uint128 i = 0; i < ticketCount; i++) {
      nftContract.mintFromMarketPlace(
        msg.sender, 
        (uint256(eventId) << 128) | uint256(events[eventId].nextTicketToSell + i)
      );
    }

    events[eventId].nextTicketToSell += ticketCount;

    emit TicketsBought(eventId, ticketCount, "ERC20");
  }
 
  function totalPrice(uint128 ticketCount, uint256 ticketPrice) external pure returns (uint256) {
    return ticketCount * ticketPrice;
  } 

  function setERC20Address(address newERC20Address) external override authorization {
    require(msg.sender == owner);
    ERC20Address = IERC20(newERC20Address);

    emit ERC20AddressUpdate(newERC20Address);
  }
  
  // your code goes here (you can do it!)
}
