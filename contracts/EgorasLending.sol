// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.7.0;
import "./SafeMath.sol";
import "./EgorasLendingInterface.sol";
import './SafeDecimalMath.sol';
import "./Ownable.sol";

interface IERC20 {
    function totalSupply() external view  returns (uint256);
    function balanceOf(address account) external view  returns (uint256);
    function transfer(address recipient, uint256 amount) external  returns (bool);
    function allowance(address owner, address spender) external  view returns (uint256);
    function approve(address spender, uint256 amount) external  returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)  external  returns (bool);
    function mint(address account, uint256 amount) external  returns (bool);
    function burnFrom(address account, uint256 amount) external;
}




contract EgorasLending is EgorasLendingInterface, Ownable{
    using SafeDecimalMath for uint;
    mapping(uint => bool) activeRequest;
    mapping(uint => mapping(address => uint)) requestPower;
  
    struct Votters{
      address payable voter;
    }
    
     struct Requests{
      address creator;
      uint requestType;
      uint changeTo;
      uint votersCut;
      uint uploaderCut;
      string reason;
      uint positiveVote;
      uint negativeVote;
      bool stale;
      uint votingPeriod;
    }
    
    Requests[] requests;
    mapping(uint => Requests[]) listOfrequests;
    mapping(uint => Votters[]) listOfvoters;
    mapping(uint => Votters[]) activeVoters;
    mapping(uint => Votters[]) activeRequestVoters;
   
    mapping(uint => mapping(address => bool)) hasVoted;
    mapping(uint => mapping(address => bool)) manageRequestVoters;
    mapping(uint => bool) stale;
    mapping(uint => mapping(address => uint)) votePower;
    mapping(uint => uint) totalVotePower;
    mapping(address => address) uploaderRewardAddress;
    
    mapping(uint => uint) positiveVote;
    mapping(uint => uint) voteCountDown;
    mapping(uint => uint) negativeVote;
    mapping (uint => bool) isLoanApproved;
    mapping(uint => uint) votersReward;
    mapping(uint => uint) ownersReward;
    mapping(uint => uint) uploadersReward;
    mapping(address => bool)  uploader;
    Loan[] loans;
    Votters[] voters;
    using SafeMath for uint256;
    address private egorasEUSD;
    address private egorasEGR;
    uint private loanFee;
    uint private systemFeeBalance;
    uint private requestCreationPower;
    uint public ownerCut;
    uint public votersCut;
    uint public uploaderCut;
    constructor(address _egorasEusd, address _egorasEgr, uint _initialLoanFee
    , uint _ownerCut, uint _votersCut, uint _uploaderCut)  public {
        require(address(0) != _egorasEusd, "Invalid address");
        require(address(0) != _egorasEgr, "Invalid address");
        egorasEGR = _egorasEgr;
        egorasEUSD = _egorasEusd;
        loanFee = _initialLoanFee;
        ownerCut = _ownerCut;
        votersCut = _votersCut;
        uploaderCut = _uploaderCut;
    
    }
    
    function addUploader(address _uploader, address _uploaderRewardAddress) external onlyOwner returns(bool){
        uploader[_uploader] = true;
        uploaderRewardAddress[_uploader] = _uploaderRewardAddress;
        return true;
    }
    
   function suspendUploader(address _uploader) external onlyOwner returns(bool) {
       uploader[_uploader] = false;
       return true;
   }

      /*** Restrict access to Uploader role*/    
      modifier onlyUploader() {        
        require(uploader[msg.sender] == true, "Address is not allowed to upload a loan!");       
        _;}

/// Request
function createRequest(uint _requestType, uint _changeTo, uint _votersCut, uint _uploaderCut, string memory _reason) public onlyOwner override{
    require(_requestType >= 0 && _requestType <  2,  "Invalid request type!");
    require(!activeRequest[_requestType], "Another request is still active");
    Requests memory _request = Requests({
      creator: msg.sender,
      requestType: _requestType,
      changeTo: _changeTo,
      votersCut: _votersCut,
      uploaderCut: _uploaderCut,
      reason: _reason,
      positiveVote: 0,
      negativeVote: 0,
      stale: false,
      votingPeriod: block.timestamp.add(3 days)
    });
    
    requests.push(_request);
    uint256 newRequestID = requests.length - 1;
     Requests memory request = requests[newRequestID];
    emit RequestCreated(
      request.creator,
      request.requestType,
      request.changeTo,
      request.votersCut,
      request.uploaderCut,
      request.reason,
      request.positiveVote,
      request.negativeVote,
      request.stale,
      request.votingPeriod,
      newRequestID
      );
}

function governanceVote(uint _requestType, uint _requestID, uint _votePower, bool _accept) public override{
    Requests storage request = requests[_requestID];
    require(request.votingPeriod >= block.timestamp, "Voting period ended");
    require(_votePower > 0, "Power must be greater than zero!");
    require(_requestType == 0 || _requestType == 1 || _requestType == 2,  "Invalid request type!");
    IERC20 iERC20 = IERC20(egorasEGR);
    require(iERC20.allowance(msg.sender, address(this)) >= _votePower, "Insufficient EGR allowance for vote!");
    require(iERC20.transferFrom(msg.sender, address(this), _votePower), "Error");
    requestPower[_requestType][msg.sender] = requestPower[_requestType][msg.sender].add(_votePower);
     
     
       if(_accept){
            request.positiveVote = request.positiveVote.add(_votePower);
        }else{
            request.negativeVote = request.negativeVote.add(_votePower);  
        }
            manageRequestVoters[_requestID][msg.sender] = true;
            activeRequestVoters[_requestID].push(Votters(msg.sender));
           emit VotedForRequest(msg.sender, _requestID, request.positiveVote, request.negativeVote, _accept);
    
}

function validateRequest(uint _requestID) public override{
    Requests storage request = requests[_requestID];
    require(block.timestamp >= request.votingPeriod, "Voting period still active");
    require(!request.stale, "This has already been validated");
    
    IERC20 egr = IERC20(egorasEGR);
    if(request.requestType == 0){
        if(request.positiveVote >= request.negativeVote){
            loanFee = request.changeTo;
            request.stale = true;
        }
        
    }else if(request.requestType == 1){
        if(request.positiveVote >= request.negativeVote){
            ownerCut = request.changeTo;
            votersCut = request.votersCut;
            uploaderCut = request.uploaderCut;
            request.stale = true;
        }
        
    }
    
    for (uint256 i = 0; i < activeRequestVoters[_requestID].length; i++) {
           address voterAddress = activeRequestVoters[_requestID][i].voter;
           uint amount = requestPower[request.requestType][voterAddress];
           require(egr.transfer(voterAddress, amount), "Fail to refund voter");
           requestPower[request.requestType][voterAddress] = 0;
           emit Refunded(amount, voterAddress, _requestID, now);
    }
    
   
    emit ApproveRequest(_requestID, request.positiveVote >= request.negativeVote, msg.sender);
}
  // Loan

    function applyForLoan(
        string memory _title,
        string memory _story,
        string memory _branch_name,
        uint _amount,
        uint _length,
        string memory _image_url
        ) external onlyUploader override {
        require(_amount > 0, "Loan amount should be greater than zero");
        require(_length > 0, "Loan duration should be greater than zero");
        require(bytes(_title).length > 3, "Loan title should more than three characters long");
        uint getTotalWeeks = _length.div(6);
        uint amount = _amount.div(getTotalWeeks);
        uint reward = uint(uint(amount).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(loanFee)));
        require(votersCut.add(uploaderCut.add(ownerCut)) == 10000, "Invalid percent");
       
        uint  weekly_payment = reward.sub(amount);
         Loan memory _loan = Loan({
         title: _title,
         story: _story,
         branchName: _branch_name,
         amount: _amount,
         length: _length,
         min_weekly_returns: weekly_payment,
         total_returns: weekly_payment.mul(getTotalWeeks),
         image_url: _image_url,
         totalWeeks: getTotalWeeks,
         numWeekspaid: 0,
         totalPayment: 0,
         isApproved: false,
         loanFee: loanFee,
         creator: msg.sender,
         isConfirmed: false
        });
             loans.push(_loan);
             uint256 newLoanID = loans.length - 1;
             
             votersReward[newLoanID] = votersReward[newLoanID].add(uint(uint(reward).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(votersCut))));
             ownersReward[newLoanID] = ownersReward[newLoanID].add(uint(uint(reward).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(ownerCut))));
             uploadersReward[newLoanID] = uploadersReward[newLoanID].add(uint(uint(reward).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(uploaderCut))));
             voteCountDown[newLoanID] = block.timestamp.add(3 days);
             emit LoanCreated(newLoanID, _title, _story, _branch_name, _amount, _length, weekly_payment,_image_url, loanFee, block.timestamp.add(3 days), msg.sender);
        }

    function getLoanByID(uint _loanID) external override view returns(
        string memory _title, string memory _story, string memory _branchName, uint _amount,
        uint _length, string memory _image_url,
        uint _totalWeeks, uint _totalPayment, bool isApproved, address  _creator
        ){
         Loan memory loan = loans[_loanID];
         return (loan.title, loan.story,loan.branchName, loan.amount, 
         loan.length,  loan.image_url, loan.totalWeeks, loan.totalPayment,
          isApproved, loan.creator);
     }
     
  
      
     
     function getVotesByLoanID(uint _loanID) external override view returns(uint _accepted, uint _declined){
        return (positiveVote[_loanID], negativeVote[_loanID]);
    }

    function vote(uint _loanID, uint _votePower, bool _accept) external override{
            Loan memory loan = loans[_loanID];
            require(loan.isConfirmed, "Can't vote at the moment!");
            require(_votePower > 0, "Power must be greater than zero!");
            IERC20 iERC20 = IERC20(egorasEGR);
            require(iERC20.allowance(msg.sender, address(this)) >= _votePower, "Insufficient EGR allowance for vote!");
            require(iERC20.transferFrom(msg.sender, address(this), _votePower), "Error!");
            if(_accept){
                positiveVote[_loanID] = positiveVote[_loanID].add(_votePower);
            }else{
              negativeVote[_loanID] = negativeVote[_loanID].add(_votePower);  
            }
             votePower[_loanID][msg.sender] = votePower[_loanID][msg.sender].add(_votePower);
             totalVotePower[_loanID] = totalVotePower[_loanID].add(_votePower);
            hasVoted[_loanID][msg.sender] = true;
            listOfvoters[_loanID].push(Votters(msg.sender));
            emit Voted(msg.sender, _loanID,  positiveVote[_loanID],negativeVote[_loanID], _accept);
    } 
       
function repayLoan(uint _loanID) external override{
   Loan storage loan = loans[_loanID];
   require(loan.isApproved, "This loan is not approved yet.");
   require(loan.creator == msg.sender, "Unauthorized.");
   IERC20 iERC20 = IERC20(egorasEUSD);
   require(loan.totalWeeks > loan.numWeekspaid, "The loan fully paid!");
   uint fee = uint(uint(loan.min_weekly_returns).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(loan.loanFee)));
   require(iERC20.allowance(msg.sender, address(this)) >= loan.min_weekly_returns, "Insufficient EUSD allowance for repayment!");
   require(iERC20.transferFrom(msg.sender, address(this), fee), "Fail to transfer");
   iERC20.burnFrom(msg.sender, loan.min_weekly_returns.sub(fee));
   loan.totalPayment = loan.totalPayment.add(loan.min_weekly_returns);
   systemFeeBalance = systemFeeBalance.add(fee);
   loan.numWeekspaid = loan.numWeekspaid.add(1);
   emit Repay(loan.min_weekly_returns, now, loan.numWeekspaid, _loanID);
}

function approveLoan(uint _loanID) external override{
    Loan storage loan = loans[_loanID];
    require(loan.isConfirmed, "Can't vote at the moment!");
     require(isDue(_loanID), "Voting is not over yet!");
     require(!stale[_loanID], "The loan is either approve/declined");
     
     IERC20 eusd = IERC20(egorasEUSD);
     IERC20 egr = IERC20(egorasEGR);
     if(positiveVote[_loanID] > negativeVote[_loanID]){
     require(eusd.mint(loan.creator, loan.amount), "Fail to transfer fund");
     require(eusd.mint(owner(), ownersReward[_loanID]), "Fail to transfer fund");
     require(eusd.mint(uploaderRewardAddress[loan.creator], uploadersReward[_loanID]), "Fail to transfer fund");
    for (uint256 i = 0; i < listOfvoters[_loanID].length; i++) {
           address voterAddress = listOfvoters[_loanID][i].voter;


            // Start of reward calc
            uint totalUserVotePower = votePower[_loanID][voterAddress].mul(1000);
            uint currentTotalPower = totalVotePower[_loanID];
            uint percentage = totalUserVotePower.div(currentTotalPower);
            uint share = percentage.mul(votersReward[_loanID]).div(1000);
            // End of reward calc
            
           uint amount = votePower[_loanID][voterAddress];
           require(egr.transfer(voterAddress, amount), "Fail to refund voter");
           require(eusd.mint(voterAddress, share), "Fail to refund voter");
           emit Refunded(amount, voterAddress, _loanID, now);
    }
     loan.isApproved = true;
     stale[_loanID] = true;
     
     emit ApproveLoan(_loanID, true, msg.sender, now);
     }else{
        for (uint256 i = 0; i < listOfvoters[_loanID].length; i++) {
           address voterAddress = listOfvoters[_loanID][i].voter;
           uint amount = votePower[_loanID][voterAddress];
           require(egr.transfer(voterAddress, amount), "Fail to refund voter");
           emit Refunded(amount, voterAddress, _loanID, now);
    } 
     stale[_loanID] = true;
     emit ApproveLoan(_loanID, false, msg.sender, now);
     }
}

function isDue(uint _loanID) public override view returns (bool) {
        if (block.timestamp >= voteCountDown[_loanID])
            return true;
        else
            return false;
    }


function confirmLoan(uint _loanID)  external  onlyOwner returns(bool){
    Loan storage loan = loans[_loanID];
    loan.isConfirmed = true;
    emit Confirmed(_loanID);
}

function systemInfo() external view  returns(uint _requestpower, uint _loanFee, uint _ownerCut, uint _uploaderCut, uint _votersCut){
    return(requestCreationPower, loanFee, ownerCut, uploaderCut, votersCut);
}

}