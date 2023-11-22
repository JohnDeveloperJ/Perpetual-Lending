// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LoanContract
 * @dev Implements a basic loan management system where users can create loans,
 * pay interest, and handle defaults.
 */
contract LoanContract is ReentrancyGuard, Ownable(msg.sender) {
    struct Loan {
        uint256 id;
        address borrower;
        uint256 amount;
        uint256 interestRate;
        uint256 duration;
        uint256 start;
        bool isDefaulted;
    }

    uint256 public nextLoanId;
    mapping(uint256 => Loan) public loans;
    mapping(address => uint256[]) private borrowerLoans;

    event LoanCreated(uint256 indexed id, address indexed borrower, uint256 amount);
    event LoanDefaulted(uint256 indexed id, address indexed borrower);
    event InterestPaid(uint256 indexed id, uint256 interestAmount);

    /**
     * @dev Creates a new loan with specified details.
     * @param amount The amount of the loan.
     * @param interestRate The interest rate of the loan.
     * @param duration The duration of the loan in seconds.
     */
    function createLoan(uint256 amount, uint256 interestRate, uint256 duration) external nonReentrant {
        require(amount > 0, "Loan amount must be greater than 0");
        require(interestRate > 0, "Interest rate must be positive");
        require(duration > 0, "Duration must be positive");

        loans[nextLoanId] = Loan(nextLoanId, msg.sender, amount, interestRate, duration, block.timestamp, false);
        borrowerLoans[msg.sender].push(nextLoanId);
        emit LoanCreated(nextLoanId, msg.sender, amount);
        nextLoanId++;
    }

    /**
     * @dev Allows borrowers to pay interest on a specific loan.
     * @param loanId The ID of the loan on which interest is paid.
     */
    function payInterest(uint256 loanId) external payable nonReentrant {
        Loan storage loan = loans[loanId];
        require(block.timestamp < loan.start + loan.duration, "Loan term has ended");
        require(!loan.isDefaulted, "Loan is defaulted");
        uint256 interestAmount = calculateInterest(loan.amount, loan.interestRate);
        // Logic to transfer interest to lender (not implemented here)
        emit InterestPaid(loanId, interestAmount);
    }

    /**
     * @dev Calculates interest for a given amount and interest rate.
     * @param amount The principal amount.
     * @param interestRate The interest rate.
     * @return The calculated interest.
     */
    function calculateInterest(uint256 amount, uint256 interestRate) public pure returns (uint256) {
        return amount * interestRate / 100;
    }

    /**
     * @dev Checks if a loan is in default and marks it as defaulted if conditions are met.
     * @param loanId The ID of the loan to check.
     */
    function checkAndHandleDefault(uint256 loanId) external nonReentrant {
        Loan storage loan = loans[loanId];
        if (block.timestamp > loan.start + loan.duration) {
            loan.isDefaulted = true;
            emit LoanDefaulted(loanId, loan.borrower);
            // Additional logic for handling default
        }
    }

    // Additional functions and modifiers can be added here
}
