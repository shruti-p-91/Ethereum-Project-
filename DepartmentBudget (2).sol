// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Department Budget Approval System
 * @author Student
 * @notice Ensures department expenses execute only after committee approval
 * @dev Designed for Ethereum Local Geth Network deployment
 */

contract DepartmentBudgetApproval {

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// Emitted when committee member registered
    event MemberRegistered(address member);

    /// Emitted when new expense proposed
    event ExpenseProposed(
        uint proposalId,
        string description,
        uint amount,
        address recipient
    );

    /// Emitted when member approves proposal
    event ProposalApproved(uint proposalId, address member);

    /// Emitted when proposal rejected
    event ProposalRejected(uint proposalId, address member);

    /// Emitted when expense executed
    event ExpenseExecuted(
        uint proposalId,
        address recipient,
        uint amount
    );

    /*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public admin;
    uint public requiredApprovals;

    struct Proposal {
        string description;
        uint amount;
        address payable recipient;
        uint approvalCount;
        bool executed;
    }

    Proposal[] public proposals;

    mapping(address => bool) public isMember;

    mapping(uint => mapping(address => bool)) public hasApproved;
    mapping(uint => mapping(address => bool)) public hasRejected;

    address[] public members;

    /*//////////////////////////////////////////////////////////////
                        MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin allowed");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Not a committee member");
        _;
    }

    modifier proposalExists(uint _id) {
        require(_id < proposals.length, "Proposal does not exist");
        _;
    }

    modifier notExecuted(uint _id) {
        require(!proposals[_id].executed, "Already executed");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @param _requiredApprovals Number of approvals required
     */
    constructor(uint _requiredApprovals) payable {
        require(_requiredApprovals > 0, "Invalid approvals");

        admin = msg.sender;
        requiredApprovals = _requiredApprovals;
    }

    /*//////////////////////////////////////////////////////////////
                    MEMBER REGISTRATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register committee member
     */
    function registerMember(address _member)
        public
        onlyAdmin
    {
        require(!isMember[_member], "Already member");

        isMember[_member] = true;
        members.push(_member);

        emit MemberRegistered(_member);
    }

    /*//////////////////////////////////////////////////////////////
                    PROPOSE EXPENSE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Propose department expense
     * @param _description Expense description
     * @param _amount Requested amount in wei
     * @param _recipient Recipient wallet
     */
    function proposeExpense(
        string memory _description,
        uint _amount,
        address payable _recipient
    )
        public
        onlyMember
    {
        proposals.push(
            Proposal({
                description: _description,
                amount: _amount,
                recipient: _recipient,
                approvalCount: 0,
                executed: false
            })
        );

        emit ExpenseProposed(
            proposals.length - 1,
            _description,
            _amount,
            _recipient
        );
    }

    /*//////////////////////////////////////////////////////////////
                    APPROVE PROPOSAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Approve expense proposal
     */
    function approveProposal(uint _id)
        public
        onlyMember
        proposalExists(_id)
        notExecuted(_id)
    {
        require(!hasApproved[_id][msg.sender],
            "Already approved");

        require(!hasRejected[_id][msg.sender],
            "Already rejected");

        hasApproved[_id][msg.sender] = true;

        proposals[_id].approvalCount++;

        emit ProposalApproved(_id, msg.sender);

        // Execute automatically if approvals reached
        if (proposals[_id].approvalCount >= requiredApprovals) {
            _executeExpense(_id);
        }
    }

    /*//////////////////////////////////////////////////////////////
                    REJECT PROPOSAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Reject expense proposal
     */
    function rejectProposal(uint _id)
        public
        onlyMember
        proposalExists(_id)
        notExecuted(_id)
    {
        require(!hasRejected[_id][msg.sender],
            "Already rejected");

        require(!hasApproved[_id][msg.sender],
            "Already approved");

        hasRejected[_id][msg.sender] = true;

        emit ProposalRejected(_id, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                    EXECUTE EXPENSE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Internal execution logic
     */
    function _executeExpense(uint _id) internal {

        Proposal storage proposal = proposals[_id];

        require(
            proposal.approvalCount >= requiredApprovals,
            "Not enough approvals"
        );

        require(
            address(this).balance >= proposal.amount,
            "Insufficient contract balance"
        );

        proposal.executed = true;

        (bool success, ) =
            proposal.recipient.call{value: proposal.amount}("");

        require(success, "Transfer failed");

        emit ExpenseExecuted(
            _id,
            proposal.recipient,
            proposal.amount
        );
    }

    /*//////////////////////////////////////////////////////////////
                    CONTRACT FUNDING
    //////////////////////////////////////////////////////////////*/

    /// Receive ETH
    receive() external payable {}

    /// Deposit funds manually
    function deposit() public payable {}

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getProposalCount()
        public
        view
        returns(uint)
    {
        return proposals.length;
    }

    function getContractBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
}