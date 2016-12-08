pragma solidity ^0.4.6;

import "./AbstractCompany.sol";

import "./stocks/Stock.sol";

import "./stocks/IssueableStock.sol";
import "./stocks/GrantableStock.sol";
import "./votes/BinaryVoting.sol";

contract Company is AbstractCompany {
  mapping (uint8 => address) public stocks;
  uint8 public stockIndex;

  mapping (uint256 => address) public votings;
  mapping (address => uint256) public reverseVotings;
  mapping (uint256 => bool) public voteExecuted;
  uint256 public votingIndex;

  event Log(uint256 v);

  function Company() {
    votingIndex = 0;
  }

  modifier vote(uint8 option, uint256 support, uint256 base) {
    uint256 votingId = reverseVotings[msg.sender];

    if (votingId == 0) throw;
    if (voteExecuted[votingId]) throw;

    var (v, possibleVotings) = countVotes(votingId, option);
    uint256 neededVotings = possibleVotings * support / base;
    if (v < neededVotings) throw;

    voteExecuted[votingId] = true;
    _;
  }

  /*
  modifier onlyShareholder(uint256 withCapital, uint256 withVotings) {
  }
  */

  function countVotes(uint256 votingId, uint8 optionId) returns (uint256 votes, uint256 totalPossibleVotes) {
    for (uint8 i = 0; i < stockIndex; i++) {
      Stock stock = Stock(stocks[i]);
      votes += stock.votes(votingId, optionId);
      totalPossibleVotes += (stock.totalSupply() - stock.balanceOf(this)) * stock.votesPerShare();
    }
  }

  function beginPoll(address voting, uint64 closes) {
    Voting v = Voting(voting);
    Log(1);

    for (uint8 i = 0; i < stockIndex; i++) {
      Stock(stocks[i]).beginPoll(votingIndex, closes);
    }

    Log(2);

    votings[votingIndex] = voting;
    reverseVotings[voting] = votingIndex;
    votingIndex += 1;
  }

  event IssuedStock(address stockAddress, uint8 stockIndex);

  function addStock(address newStock, uint256 issue) public {
    if (Stock(newStock).company() != address(this)) throw;

    stocks[stockIndex] = newStock;
    stockIndex += 1;
    IssueableStock(newStock).issueStock(issue);

    IssuedStock(newStock, stockIndex - 1);
  }

  function issueStock(uint8 _stock, uint256 _amount) public vote(uint8(BinaryVoting.VotingOption.Favor), 2, 3) {
    IssueableStock(stocks[_stock]).issueStock(_amount);
    IssuedStock(stocks[_stock], _stock);
  }

  function grantStock(uint8 _stock, uint256 _amount, address _recipient) public {
    GrantableStock(stocks[_stock]).grantStock(_recipient, _amount);
  }
}