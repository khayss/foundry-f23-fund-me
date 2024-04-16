// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract TestFundMe is Test {
    address TEST_USER = vm.addr(123);
    uint256 private constant TEST_AMOUNT = 0.1 ether;

    FundMe fundMe;

    function setUp() external {
        vm.deal(TEST_USER, 10 ether);
        DeployFundMe deployFundMe = new DeployFundMe();
        (fundMe,) = deployFundMe.run();
    }

    function testMinimumUsdIsFive() public view {
        assertEq(fundMe.getMinimumContribution(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsFour() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundRevertWhenNotEnoughEthSent() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundsAreSentToTheFundMeContract() public {
        vm.prank(TEST_USER);
        fundMe.fund{value: TEST_AMOUNT}();
        uint256 amount = fundMe.getFunderAmountByAddress(TEST_USER);
        assertEq(amount, TEST_AMOUNT);
    }

    function testFunderAddedToFunders() public funded {
        address funder = fundMe.getFunderByIndex(0);
        assertEq(funder, TEST_USER);
    }

    modifier funded() {
        vm.prank(TEST_USER);
        fundMe.fund{value: TEST_AMOUNT}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(TEST_USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testOwnerCanWithdraw() public funded {
        uint256 contractBalance = address(fundMe).balance;
        uint256 ownerBalance = fundMe.getOwner().balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 finalContractBalance = address(fundMe).balance;
        uint256 finalOwnerBalance = fundMe.getOwner().balance;

        assertEq(finalContractBalance, 0);
        assertEq(finalOwnerBalance, ownerBalance + contractBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 startingIndex = 1;
        uint160 endingIndex = 10;
        for (uint160 i = startingIndex; i < endingIndex; i++) {
            hoax(address(i));
            fundMe.fund{value: TEST_AMOUNT}();
        }

        uint256 contractBalance = address(fundMe).balance;
        uint256 ownerBalance = fundMe.getOwner().balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 finalContractBalance = address(fundMe).balance;
        uint256 finalOwnerBalance = fundMe.getOwner().balance;

        assert(finalContractBalance == 0);
        assert(finalOwnerBalance == ownerBalance + contractBalance);
    }

    function testCheaperWithdrawFromMultipleFunders() public funded {
        uint160 startingIndex = 1;
        uint160 endingIndex = 10;
        for (uint160 i = startingIndex; i < endingIndex; i++) {
            hoax(address(i));
            fundMe.fund{value: TEST_AMOUNT}();
        }

        uint256 contractBalance = address(fundMe).balance;
        uint256 ownerBalance = fundMe.getOwner().balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        uint256 finalContractBalance = address(fundMe).balance;
        uint256 finalOwnerBalance = fundMe.getOwner().balance;

        assert(finalContractBalance == 0);
        assert(finalOwnerBalance == ownerBalance + contractBalance);
    }
}
