// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {console} from "forge-std/console.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {VultSwapRouter} from "../src/VultSwapRouter.sol";

contract SellVultZK is Script {
    address constant POOL_MANAGER = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;

    function run() external {
        vm.startBroadcast();

        address BYTECODE20 = 0x79CEAcf59271D24b14Fe8b5A5020C7420D900E46;
        address HOOK = 0x17e5508c2dad1c0065b4cb348C475A3Fb8856888;
        address ROUTER = 0x88EF4a5cc45EC43E1Cd10C6d5660336e1b58601e;

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(BYTECODE20),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        uint256 sellAmount = 10 ether;   // ← Amount of VULT you want to sell

        console.log("=== Executing SELL ===");
        console.log("Selling VULT Amount :", sellAmount);

        VultSwapRouter router = VultSwapRouter(payable(ROUTER));

        bytes memory hookData = abi.encode(msg.sender);   // swapper for hook

        router.sell(
            key,           // 1. PoolKey
            msg.sender,    // 2. swapper
            msg.sender,    // 3. recipient (who gets ETH)
            sellAmount,    // 4. vultIn
            hookData       // 5. hookData
        );

        console.log("Sell transaction broadcasted successfully!");
        vm.stopBroadcast();
    }
}