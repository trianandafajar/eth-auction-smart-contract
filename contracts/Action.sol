// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Auction {
    address payable public immutable owner;
    uint public immutable startBlock;
    uint public immutable endBlock;
    string public ipfsHash;

    enum State {Started, Running, Ended, Canceled}
    State public auctionState = State.Running;

    uint public highestBindingBid;
    address payable public highestBidder;
    mapping(address => uint) public bids;
    uint public constant bidIncrement = 1 ether;

    bool public ownerFinalized;
    bool private locked;

    event BidPlaced(address indexed bidder, uint amount);
    event AuctionCanceled();
    event AuctionFinalized(address indexed recipient, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier notOwner() {
        require(msg.sender != owner, "Owner cannot bid");
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock, "Auction not started");
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock, "Auction ended");
        _;
    }

    modifier noReentrancy() {
        require(!locked, "Reentrancy detected");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        owner = payable(msg.sender);
        startBlock = block.number;
        endBlock = startBlock + 3;
    }

    receive() external payable {
        placeBid();
    }

    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running, "Auction inactive");
        require(msg.value >= bidIncrement, "Insufficient bid");

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid, "Bid not high enough");

        bids[msg.sender] = currentBid;

        if (currentBid <= bids[highestBidder]) {
            highestBindingBid = _min(currentBid + bidIncrement, bids[highestBidder]);
        } else {
            highestBindingBid = _min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }

        emit BidPlaced(msg.sender, currentBid);
    }

    function cancelAuction() external onlyOwner beforeEnd {
        require(auctionState == State.Running, "Cannot cancel");
        auctionState = State.Canceled;
        emit AuctionCanceled();
    }

    function finalizeAuction() external noReentrancy {
        require(
            auctionState == State.Canceled || block.number > endBlock,
            "Auction not ended"
        );
        require(
            msg.sender == owner || bids[msg.sender] > 0,
            "Unauthorized"
        );

        address payable recipient;
        uint value;

        if (auctionState == State.Canceled) {
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else if (msg.sender == owner && !ownerFinalized) {
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

        bids[recipient] = 0;
        (bool sent, ) = recipient.call{value: value}("");
        require(sent, "Transfer failed");

        emit AuctionFinalized(recipient, value);
    }

    function _min(uint a, uint b) private pure returns (uint) {
        return a <= b ? a : b;
    }
}
