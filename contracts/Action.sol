// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Auction {
    address payable public owner;
    uint256 public startBlock;
    uint256 public endBlock;
    string public ipfsHash;

    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    uint256 public highestBindingBid;
    address payable public highestBidder;
    mapping(address => uint256) public bids;
    uint256 public bidIncrement;

    bool public ownerFinalized = false;
    bool internal locked; // for reentrancy guard

    // Events
    event BidPlaced(address indexed bidder, uint256 bid);
    event AuctionCanceled();
    event AuctionFinalized(address indexed recipient, uint256 value);

    constructor() {
        owner = payable(msg.sender);
        auctionState = State.Running;

        startBlock = block.number;
        endBlock = startBlock + 3;

        ipfsHash = "";
        bidIncrement = 1 ether;
    }

    // Modifiers
    modifier notOwner() {
        require(msg.sender != owner, "Owner cannot perform this action");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock, "Auction has not started yet");
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock, "Auction has ended");
        _;
    }

    modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    // Fallback to receive ETH directly
    receive() external payable {
        placeBid();
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function cancelAuction() public onlyOwner beforeEnd {
        require(auctionState == State.Running, "Auction must be running");
        auctionState = State.Canceled;
        emit AuctionCanceled();
    }

    function placeBid() public payable notOwner afterStart beforeEnd returns (bool) {
        require(auctionState == State.Running, "Auction is not running");
        require(msg.value >= bidIncrement, "Minimum bid increment not met");

        uint256 currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid, "Bid too low");

        bids[msg.sender] = currentBid;

        if (currentBid <= bids[highestBidder]) {
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else {
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }

        emit BidPlaced(msg.sender, currentBid);
        return true;
    }

    function finalizeAuction() public noReentrancy {
        require(
            auctionState == State.Canceled || block.number > endBlock,
            "Auction is not over or canceled"
        );
        require(
            msg.sender == owner || bids[msg.sender] > 0,
            "Not authorized to finalize"
        );

        address payable recipient;
        uint256 value;

        if (auctionState == State.Canceled) {
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            if (msg.sender == owner && !ownerFinalized) {
                recipient = owner;
                value = highestBindingBid;
                ownerFinalized = true;
            } else if (msg.sender == highestBidder) {
                recipient = highestBidder;
                value = bids[highestBidder] - highestBindingBid;
            } else {
                recipient = payable(msg.sender);
                value = bids[msg.sender];
            }
        }

        bids[recipient] = 0;

        (bool sent, ) = recipient.call{value: value}("");
        require(sent, "Failed to send Ether");

        emit AuctionFinalized(recipient, value);
    }
}
