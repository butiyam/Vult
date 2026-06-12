// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Groth16Verifier} from "../src/Groth16Verifier.sol";

contract DeployVerifier is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy the verifier (no constructor args in most snarkjs verifiers)
        Groth16Verifier verifier = new Groth16Verifier();

        console.log("Groth16Verifier deployed at:", address(verifier));

        vm.stopBroadcast();
    }
}