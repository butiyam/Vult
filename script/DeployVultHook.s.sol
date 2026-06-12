// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";
import {HookMiner} from "v4-periphery/test/shared/HookMiner.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import "../src/VultToken.sol";
import {VultHook} from "../src/VultHook.sol";

contract DeployVultHook is Script {
    address constant POOL_MANAGER = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;

    address constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    address constant VULT_TOKEN = 0x9E4363A9c52298bef1ef30479CC537d0E003cd51;

    address constant Verifier = 0x81d16229c9678D20a5e2a1054375f00E378F3a4F;


    function run() external {
        vm.startBroadcast();

        uint160 flags =
        Hooks.BEFORE_INITIALIZE_FLAG |
        Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
        Hooks.BEFORE_SWAP_FLAG |
        Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG;

        VultToken token = VultToken(VULT_TOKEN);

        bytes32[8] memory manifesto = [
            bytes32("Verified"),
            bytes32("without"),
            bytes32("revealing"),
            bytes32(0),
            bytes32(0),
            bytes32(0),
            bytes32(0),
            bytes32(0)
        ];

        bytes memory args = abi.encode(
            IPoolManager(POOL_MANAGER),
            token,
            manifesto
        );

        (address predicted, bytes32 salt) =
            HookMiner.find(
                CREATE2_DEPLOYER,
                flags,
                type(VultHook).creationCode,
                args
            );

        VultHook hook = new VultHook{salt: salt}(
            IPoolManager(POOL_MANAGER),
            token,
            manifesto
        );

        require(address(hook) == predicted, "HOOK ADDRESS MISMATCH");

        console.log("Hook deployed:");
        console.logAddress(address(hook));

        vm.stopBroadcast();
    }
}