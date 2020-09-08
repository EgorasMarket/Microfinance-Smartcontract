pragma solidity >=0.4.0 <0.7.0;
// SPDX-License-Identifier: MIT
interface EgorasLendingInterface {
    struct Loan{
        uint amount;
        string title;
        uint length;
        uint min_weekly_returns;
        uint total_returns;
        string image_url;
        string companyName;
        uint totalWeeks;
        uint numWeekspaid;
        uint totalPayment;
        bool isApproved;
        uint loanFee;
        address creator;
    }
event LoanCreated(uint newLoanID, uint _amount, string _title, uint _length, uint _min_weekly_returns, uint _total_returns,  
string _image_url, string _companyName, uint getTotalWeeks, uint _loanFee, uint countDown, address _creator);
 
    struct Company{
        bool isApproved;
        uint positiveVote;
        uint negativeVote;
        uint votingPeriod;
        bool stale;
        string companyName;
        uint registeredDate;
    }

    event Rewarded(
        address voter, 
        uint share, 
        uint currentVotingPeriod, 
        uint time
        );
        
      
    event CompanyCreated(
        address owner,
        string companyName,
        uint votingPeriod
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
      string _reason,
      uint _positiveVote,
      uint _negativeVote,
      uint _powerUsed,
      bool _stale,
      uint _votingPeriod,
      uint _requestID
      );
    event CompanyApproved(
    address companyAddress,
    uint now,
    bool state,
    address _initiator
    );
    event VoteInCompany(
    address _company,
    address voter,
    bool _accept,
    uint _negativeVote,
    uint _positiveVote);
  
    event ApproveLoan(uint _loanID, bool state, address initiator, uint time);
    event ApproveRequest(uint _requestID, bool _state, address _initiator);    
    event LoanRepayment(
        uint loanID,
        uint amount,
        address remitter,
        uint time
    );
    
    event Refunded(uint amount, address voterAddress, uint _loanID, uint time);

    event Voted(address voter,  uint loanID, uint _positiveVote, uint _negativeVote, bool _accept);
    event Repay(uint _amount, uint _time, uint _week, uint _loanID);

    function applyForLoan(
        uint _amount,
        string calldata _title,
        uint _length,
        string calldata _image_url
        ) external;

    function approveLoanCompany(address companyAddress) external;
    function registerLoanCompany(string calldata companyName) external;
    function getLoanByID(uint _loanID) external view returns(uint _amount, uint _min_weekly_returns, uint _totalWeeks, 
    uint _length, string memory _title, uint _total_returns, string memory _image_url, string memory _companyName,  uint _numWeekspaid, uint _totalPayment, bool _isApproved, address _creator);
    function claimable() external view returns (bool);
    function isDue(uint _loanID) external view returns (bool);
    function getVotesByLoanID(uint _loanID) external view returns(uint _accepted, uint _declined);
    function repayLoan(uint _loanID) external;
    function approveLoan(uint _loanID) external;
    function rewardHoldersByVotePower() external;
    function distributeFee() external;
    function vote(uint _loanID, uint _votePower, bool _accept) external;
    function voteinCompany(address _company, uint _votePower, bool _accept) external;
    function createRequest(uint _requestType, uint _changeTo, string calldata _reason, bool _withdrawEGR) external;
    function governanceVote(uint _requestType, uint _requestID, uint _votePower, bool _accept) external;
    function validateRequest(uint _requestID) external;
    
}


