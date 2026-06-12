// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VultToken} from"../src/VultToken.sol";


contract DepositToVult is Script {
    function run() external {
        vm.startBroadcast();

        address Vult_Token = 0x9E4363A9c52298bef1ef30479CC537d0E003cd51;// ← Paste your VultToken address
        address Hook = 0x17e5508c2dad1c0065b4cb348C475A3Fb8856888;

        uint256 depositAmount = 21_000_000 * 1e18;   // 21,000,000 VULT (adjust as needed)

        console.log("Depositing", depositAmount / 1e18, "VULT to Hook");

        // Approve first
        VultToken(Vult_Token).approve(Hook, depositAmount);

        // Call transfer
        VultToken(Vult_Token).transfer(Hook, depositAmount);

        console.log("Transfer successful!");
        console.log("Hook balance:", VultToken(Vult_Token).balanceOf(Hook));

        vm.stopBroadcast();
    }
}