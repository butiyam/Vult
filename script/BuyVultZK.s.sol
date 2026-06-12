// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {console} from "forge-std/console.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {VultSwapRouter} from "../src/VultSwapRouter.sol";

contract BuyVultZK is Script {
    address constant POOL_MANAGER = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;

    function run() external {
        vm.startBroadcast();

        address BYTECODE20 = 0x9E4363A9c52298bef1ef30479CC537d0E003cd51; // ← PASTE YOUR BYTECODE20 ADDRESS HERE
        address HOOK = 0x17e5508c2dad1c0065b4cb348C475A3Fb8856888;       // ← PASTE YOUR HOOK ADDRESS HERE

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(BYTECODE20),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        uint256 amountIn = 0.001 ether;

        // Your current proof components
        uint[2] memory a = [9638775851031408561619241716875239046898456284777719569902277596116414459401, 18515911940949068271194957682717823022581833280059249596741646871007881616509];
        uint[2][2] memory b = [[17959214504539433406909082710003564377141881241642517852910637165296001232367, 9165347602183150198456890979486924001888380558749235918641429190223596043316], [7177981580981901654220430267268135955506581669942833661533792410728432542384, 3340233051039477039438797640867668449084470178990837216532455955646045339036]];
        uint[2] memory c = [20718475064043218665914480355299616288053255028954765703141064220801539760381, 17198204555201889728262180581918645424820582523596433151906735890885044480319];

        uint[6] memory publicInputs = [
            uint256(keccak256(abi.encode(key))),
            amountIn,
            16832421271961222550979173996485995711342823810308835997146707681980704453417,
            0,
            0,
            block.number
        ];

        console.log("=== Sending ZK Buy via Router ===");
        console.log("ETH Amount :", amountIn);
        console.log("pubPoolId  :", publicInputs[0]);

        VultSwapRouter router =  VultSwapRouter( payable(0xC9bA5Bd06BC1D5b644b073d841C8295dAAbc4744));

       // Pass dummy hookData with swapper (to avoid MissingSwapperInHookData)
        bytes memory hookData = abi.encode(msg.sender);

        router.buy{value: amountIn}(
            a, b, c, publicInputs,
            key, 
            msg.sender, 
            msg.sender, 
            hookData
        );

        console.log("Transaction sent!");
        vm.stopBroadcast();
    }
}