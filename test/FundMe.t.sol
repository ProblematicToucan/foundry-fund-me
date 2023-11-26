// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {FundMeScript} from "../script/FundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    function setUp() external {
        FundMeScript deployment = new FundMeScript();
        fundMe = deployment.run();
    }

    function test_MinimumDollarIs5() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function test_OwnerIsContractDeployer() public {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function test_PriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        uint8 priceFeedVersion = block.chainid == 31337 ? 0 : 4;
        assertEq(version, priceFeedVersion);
    }
}
