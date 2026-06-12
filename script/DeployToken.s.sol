// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VultBytecode20} from "../src/VultBytecode20.sol";

contract DeployToken is Script {
    function run() external {
        vm.startBroadcast();

        VultBytecode20 minter = new VultBytecode20(21000000000000000000000000, 18, "vult", "1.0", "Vult");

        console.log("Token deployed at:", address(minter));
        
        vm.stopBroadcast();
    }
}