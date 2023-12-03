// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {FundMeScript} from "../script/FundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address private immutable i_vella = makeAddr("vella");
    address private immutable i_aziz = makeAddr("aziz");
    uint256 private constant SEND_AMOUNT = 0.1 ether;
    uint256 private constant STARTING_BALANCE = 10 ether;
    uint256 private constant MINIMUM_USD = 5e18;
    uint256 private constant GAS_PRICE = 1;

    modifier funded() {
        // uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(i_vella);
        fundMe.fund{value: SEND_AMOUNT}();
        _;
        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);
    }

    function setUp() external {
        FundMeScript deployment = new FundMeScript();
        fundMe = deployment.run();

        vm.deal(i_vella, STARTING_BALANCE);
    }

    function test_MinimumDollarIs5() public {
        assertEq(fundMe.getMinimumUsd(), MINIMUM_USD);
    }

    function test_OwnerIsContractDeployer() public {
        assertEq(fundMe.getContractOwner(), msg.sender);
    }

    function test_PriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        uint8 priceFeedVersion = block.chainid == 31337 ? 0 : 4;
        assertEq(version, priceFeedVersion);
    }

    function testFail_FundingWithoutEnoughtEth() public {
        fundMe.fund();
    }

    function test_FundingEnoughtEth() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(i_vella);
        assertEq(amountFunded, SEND_AMOUNT);
    }

    function test_AddFunderToListOfFunders() public funded {
        address funders = fundMe.getFunders()[0];
        assertEq(funders, i_vella);
    }

    function testFail_OnlyOwnerCanWithdraw() public funded {
        fundMe.withdraw();
    }

    function test_WithdrawAsOwner() public funded {
        address contractOwner = fundMe.getContractOwner();
        uint256 startingOwnerBalance = contractOwner.balance;
        uint256 startingContractBalance = address(fundMe).balance;

        vm.prank(fundMe.getContractOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = contractOwner.balance;
        uint256 endingContractBalance = address(fundMe).balance;
        assertEq(endingContractBalance, 0);
        assertEq(
            startingContractBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function test_WithdrawingFromManyFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_AMOUNT}();
        }

        address contractOwner = fundMe.getContractOwner();
        uint256 startingOwnerBalance = contractOwner.balance;
        uint256 startingContractBalance = address(fundMe).balance;

        vm.prank(fundMe.getContractOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = contractOwner.balance;
        uint256 endingContractBalance = address(fundMe).balance;

        assertEq(endingContractBalance, 0);
        assertEq(
            startingContractBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }
}
