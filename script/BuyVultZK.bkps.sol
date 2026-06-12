// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {console} from "forge-std/console.sol";

contract BuyVultZK is Script {
    address constant POOL_MANAGER = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;

    struct ZKProofData {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
    }

    function run() external {
        vm.startBroadcast();

        // ←←← UPDATE THESE ADDRESSES
        address HOOK = 0xdFf95461a46f1898D2B2314EBfd296460e556888;
        address BYTECODE20 = 0x9D1FEA4BEA6DFe6378FeF732362855F72c848F6e;

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(BYTECODE20),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        uint256 amountIn = 0.001 ether;

        ZKProofData memory proof = ZKProofData({
            a: [9638775851031408561619241716875239046898456284777719569902277596116414459401, 18515911940949068271194957682717823022581833280059249596741646871007881616509],
            b: [[17959214504539433406909082710003564377141881241642517852910637165296001232367, 9165347602183150198456890979486924001888380558749235918641429190223596043316], [7177981580981901654220430267268135955506581669942833661533792410728432542384, 3340233051039477039438797640867668449084470178990837216532455955646045339036]],
            c: [20718475064043218665914480355299616288053255028954765703141064220801539760381, 17198204555201889728262180581918645424820582523596433151906735890885044480319]
        });

        uint[6] memory publicInputs = [
            uint256(keccak256(abi.encode(key))), // pubPoolId
            amountIn,                            // pubAmountHash
            16832421271961222550979173996485995711342823810308835997146707681980704453417, // nullifier
            0,
            0,
            block.number                         // pubBlockNumber
        ];

        bytes memory hookData = abi.encode(msg.sender, proof, publicInputs);

        console.log("=== Sending Real ZK Buy ===");
        console.log("ETH Amount     :", amountIn);
        console.log("Hook           :", HOOK);
        console.log("Block Number   :", block.number);
        console.log("pubPoolId      :", publicInputs[0]);
        console.log("pubAmountHash  :", publicInputs[1]);

        bytes memory data = abi.encode(key, amountIn, hookData);
        IPoolManager(POOL_MANAGER).unlock(data);

        console.log("Transaction sent!");
        vm.stopBroadcast();
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == POOL_MANAGER, "Only PoolManager");

        (PoolKey memory key, uint256 amountIn, bytes memory hookData) = 
            abi.decode(data, (PoolKey, uint256, bytes));

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: -int256(amountIn),
            sqrtPriceLimitX96: 0
        });

        IPoolManager(POOL_MANAGER).swap(key, params, hookData);
        return "";
    }
}