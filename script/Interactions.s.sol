// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract FundFundMe is Script {
    uint256 constant SEND_AMOUNT = 1 ether;
    address constant USER = address(1);

    function fundFundMe(address _mostRecentlyDeployedAddress) public {
        vm.deal(USER, 1 ether);
        vm.prank(USER);
        FundMe(payable(_mostRecentlyDeployedAddress)).fund{value: SEND_AMOUNT}();
        console.log("Funded with %s", SEND_AMOUNT);
    }

    function run() external {
        vm.startBroadcast();
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fundFundMe(mostRecentlyDeployed);
        vm.startBroadcast();
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address _mostRecentlyDeployedAddress) public {
        // vm.startBroadcast();
        vm.prank(FundMe(payable(_mostRecentlyDeployedAddress)).getOwner());
        FundMe(payable(_mostRecentlyDeployedAddress)).withdraw();
        vm.startBroadcast();
        // console.log("withdraw successful");
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        vm.startBroadcast();
        withdrawFundMe(mostRecentlyDeployed);
        vm.startBroadcast();
    }
}
