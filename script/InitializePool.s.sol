// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {console} from "forge-std/console.sol";

contract InitializePool is Script {
    // Sepolia PoolManager
    address constant POOL_MANAGER = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;

    function run() external {
        vm.startBroadcast();

        address BYTECODE20 = 0x9E4363A9c52298bef1ef30479CC537d0E003cd51; // ← PASTE YOUR BYTECODE20 ADDRESS HERE
        address HOOK = 0x17e5508c2dad1c0065b4cb348C475A3Fb8856888;       // ← PASTE YOUR HOOK ADDRESS HERE

        require(BYTECODE20 != address(0), "Bytecode20 address not set");
        require(HOOK != address(0), "Hook address not set");

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),     // ETH
            currency1: Currency.wrap(BYTECODE20),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        // Starting price: ~1 ETH = 1,000,000 VULT (adjust as needed)
        uint160 sqrtPriceX96 = 79228162514264337593543950336000;

        IPoolManager(POOL_MANAGER).initialize(key, sqrtPriceX96);

        console.log("Pool Initialized Successfully");
        console.log("Bytecode20:", BYTECODE20);
        console.log("Hook:", HOOK);

        vm.stopBroadcast();
    }
}