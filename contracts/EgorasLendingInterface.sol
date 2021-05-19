pragma solidity >=0.4.0 <0.7.0;
// SPDX-License-Identifier: MIT
interface EgorasLendingInterface {
    struct Loan{
        string title;
        string story;
        string branchName;
        uint amount;
        uint length;
        uint min_weekly_returns;
        uint total_returns;
        string image_url;
        uint totalWeeks;
        uint numWeekspaid;
        uint totalPayment;
        bool isApproved;
        uint loanFee;
        address creator;
        bool isConfirmed;
    }
event LoanCreated(uint newLoanID, string _title, string _story, string _branchName, uint _amount, uint _length, uint _min_weekly_returns, 
string _image_url, uint _loanFee, uint countDown, address _creator);

 event Rewarded(
        address voter, 
        uint share, 
        uint currentVotingPeriod, 
        uint time
        );

    event VotedForRequest(
        address _voter,
        uint _requestID,
        uint _positiveVote,
        uint _negativeVote,
        bool _accept
    );
    event RequestCreated(
      address _creator,
      uint _requestType,
      uint _changeTo,
      uint _votersCut,
      uint _uploaderCut,
      string _reason,
      uint _positiveVote,
      uint _negativeVote,
      bool _stale,
      uint _votingPeriod,
      uint _requestID
      );
  
  
  
    event ApproveLoan(uint _loanID, bool state, address initiator, uint time);
    event ApproveRequest(uint _requestID, bool _state, address _initiator);    
    event LoanRepayment(
        uint loanID,
        uint amount,
        address remitter,
        uint time
    );
    event Confirmed(uint _loanID);
    
    event Refunded(uint amount, address voterAddress, uint _loanID, uint time);

    event Voted(address voter,  uint loanID, uint _positiveVote, uint _negativeVote, bool _accept);
    event Repay(uint _amount, uint _time, uint _week, uint _loanID);

    function applyForLoan(
        string calldata _title,
        string calldata _story,
        string calldata _branch_name,
        uint _amount,
        uint _length,
        string calldata _image_url
        ) external;

    function getLoanByID(uint _loanID) external view returns(string memory _title, string memory _story, string memory _branchName, uint _amount,
        uint _length,  string memory _image_url,
        uint _totalWeeks,  uint _totalPayment, bool isApproved, address  _creator);
    function isDue(uint _loanID) external view returns (bool);
    function getVotesByLoanID(uint _loanID) external view returns(uint _accepted, uint _declined);
    function repayLoan(uint _loanID) external;
    function approveLoan(uint _loanID) external;
    function vote(uint _loanID, uint _votePower, bool _accept) external;
    function createRequest(uint _requestType, uint _changeTo, uint _votersCut, uint _uploaderCut, string calldata _reason) external;
    function governanceVote(uint _requestType, uint _requestID, uint _votePower, bool _accept) external;
    function validateRequest(uint _requestID) external;
    
}