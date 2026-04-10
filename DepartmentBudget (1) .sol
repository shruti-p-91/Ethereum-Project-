// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DepartmentBudgetApproval
 * @author Student
 * @notice Manages department expenses with committee approval
 */
contract DepartmentBudgetApproval {

    /// @notice committee member mapping
    mapping(address => bool) public isMember;

    /// @notice total members count
    uint public memberCount;

    /// @notice required approvals
    uint public requiredApprovals;

    struct Expense {
        string description;
        uint amount;
        address payable recipient;
        uint approvals;
        bool executed;
        mapping(address => bool) approvedBy;
    }

    Expense[] public expenses;

    /// EVENTS
    event MemberRegistered(address member);
    event ExpenseProposed(uint expenseId, string description, uint amount);
    event ExpenseApproved(address member, uint expenseId);
    event ExpenseExecuted(uint expenseId, address recipient, uint amount);

    modifier onlyMember() {
        require(isMember[msg.sender], "Not committee member");
        _;
    }

    constructor(uint _requiredApprovals) payable {
        requiredApprovals = _requiredApprovals;
    }

    /// Register committee member
    function registerMember(address _member) public {
        require(!isMember[_member], "Already member");

        isMember[_member] = true;
        memberCount++;

        emit MemberRegistered(_member);
    }

    /// Propose budget expense
    function proposeExpense(
        string memory _description,
        uint _amount,
        address payable _recipient
    ) public onlyMember {

        Expense storage newExpense = expenses.push();

        newExpense.description = _description;
        newExpense.amount = _amount;
        newExpense.recipient = _recipient;
        newExpense.executed = false;

        emit ExpenseProposed(
            expenses.length - 1,
            _description,
            _amount
        );
    }

    /// Approve proposal
    function approveExpense(uint _expenseId)
        public
        onlyMember
    {
        Expense storage expense = expenses[_expenseId];

        require(!expense.executed, "Already executed");
        require(
            !expense.approvedBy[msg.sender],
            "Already approved"
        );

        expense.approvedBy[msg.sender] = true;
        expense.approvals++;

        emit ExpenseApproved(msg.sender, _expenseId);

        if (expense.approvals >= requiredApprovals) {
            executeExpense(_expenseId);
        }
    }
function getContractBalance() public view returns(uint) {
    return address(this).balance;
}
    /// Execute payment
    function executeExpense(uint _expenseId) internal {

        Expense storage expense = expenses[_expenseId];

        require(!expense.executed, "Executed already");
        require(
            address(this).balance >= expense.amount,
            "Insufficient funds"
        );

        expense.executed = true;

        (bool success, ) = expense.recipient.call{value: expense.amount}("");
require(success, "Transfer failed");

        emit ExpenseExecuted(
            _expenseId,
            expense.recipient,
            expense.amount
        );
    }

    /// Deposit funds to contract
    receive() external payable {}
}