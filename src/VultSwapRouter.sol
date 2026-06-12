// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {IUnlockCallback} from "v4-core/interfaces/callback/IUnlockCallback.sol";
import {IERC20Minimal} from "v4-core/interfaces/external/IERC20Minimal.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {SwapParams} from "v4-core/types/PoolOperation.sol";   // ← Important import

interface IZKVerifier {
    function verifyProof(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[6] calldata input
    ) external view returns (bool);
}

contract VultSwapRouter is IUnlockCallback {
    IPoolManager public immutable manager;
    address public deployer;
    address public zkVerifier = 0x81d16229c9678D20a5e2a1054375f00E378F3a4F; // Address of your IZKVerifier deployment

   // === Replay Protection ===
    mapping(uint256 => bool) public spentNullifiers;
    bool public isBuyVerifierOn = true;
    bool public isSellVerifierOn = false;

    enum Direction { Buy, Sell }

    struct Action {
        Direction direction;
        PoolKey key;
        address swapper;
        address recipient;
        uint256 amountIn;
        bytes hookData;
    }

    error NotManager();
    error NotDeployer();
    error TransferFailed();
    error InvalidZKProof();
    error  NullifierAlreadySpent();

    constructor(IPoolManager _manager) {
        manager = _manager;
        deployer = msg.sender;
    }

    function buy(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[6] calldata input,
        PoolKey calldata key, 
        address swapper, 
        address recipient, 
        bytes calldata hookData
    ) external payable returns (uint256 vultOut) {
        
       
    if(isBuyVerifierOn){
        // 1. ZK Proof Verification
        bool isValid = IZKVerifier(zkVerifier).verifyProof(a, b, c, input);
        if (!isValid) revert InvalidZKProof();

        // 2. Replay Protection (Nullifier)
        uint256 nullifier = input[2]; // pubNullifier is at index 2
        if (spentNullifiers[nullifier]) revert NullifierAlreadySpent();
        spentNullifiers[nullifier] = true;   // Mark as spent
    }
    
        // 3. Proceed to Uniswap V4
        bytes memory data = abi.encode(Action({
            direction: Direction.Buy,
            key: key,
            swapper: swapper,
            recipient: recipient,
            amountIn: msg.value,
            hookData: hookData
        }));

        bytes memory ret = manager.unlock(data);
        vultOut = abi.decode(ret, (uint256));
    }

    /// @notice Sell VULT ETH. Caller must approve this router for at least `vultIn`
    ///         beforehand. `swapper` is recorded on the hook (same-block-as-last-buy
    ///         cooldown applies).
    function sell(        
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[6] calldata input,
        PoolKey calldata key,
        address swapper,
        address recipient,
        uint256 vultIn,  
        bytes calldata hookData
        ) external returns (uint256 ethOut)
    {
 
    if(isSellVerifierOn){
        // 1. ZK Proof Verification
        bool isValid = IZKVerifier(zkVerifier).verifyProof(a, b, c, input);
        if (!isValid) revert InvalidZKProof();

        // 2. Replay Protection (Nullifier)
        uint256 nullifier = input[2]; // pubNullifier is at index 2
        if (spentNullifiers[nullifier]) revert NullifierAlreadySpent();
        spentNullifiers[nullifier] = true;   // Mark as spent
    }
    

        IERC20Minimal vult = IERC20Minimal(Currency.unwrap(key.currency1));
        if (!vult.transferFrom(msg.sender, address(this), vultIn)) revert TransferFailed();
        bytes memory data = abi.encode(Action({
            direction: Direction.Sell,
            key: key,
            swapper: swapper,
            recipient: recipient,
            amountIn: vultIn,
            hookData: hookData
        }));
        bytes memory ret = manager.unlock(data);
        ethOut = abi.decode(ret, (uint256));
    }

    function unlockCallback(bytes calldata raw) external returns (bytes memory) {
        if (msg.sender != address(manager)) revert NotManager();

        Action memory a = abi.decode(raw, (Action));

        if (a.direction == Direction.Buy) {
            manager.settle{value: a.amountIn}();

            BalanceDelta delta = manager.swap(
                a.key,
                SwapParams({                          // ← Fixed
                    zeroForOne: true,
                    amountSpecified: -int256(a.amountIn),
                    sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
                }),
                a.hookData
            );

            int256 amount1 = delta.amount1();
            uint256 vultOut = uint256(amount1 > 0 ? amount1 : -amount1);
            manager.take(a.key.currency1, a.recipient, vultOut);
            return abi.encode(vultOut);
        } else {
            // Sell (optional)
            IERC20Minimal vult = IERC20Minimal(Currency.unwrap(a.key.currency1));
            manager.sync(a.key.currency1);
            if (!vult.transfer(address(manager), a.amountIn)) revert TransferFailed();
            manager.settle();

            BalanceDelta delta = manager.swap(
                a.key,
                SwapParams({
                    zeroForOne: false,
                    amountSpecified: -int256(a.amountIn),
                    sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
                }),
                a.hookData
            );

            int256 amount0 = delta.amount0();
            uint256 ethOut = uint256(amount0 > 0 ? amount0 : -amount0);
            manager.take(a.key.currency0, a.recipient, ethOut);
            return abi.encode(ethOut);
        }
    }

    function modifyVerifier(bool _Buystate, bool _Sellstate) external  {
    if (msg.sender != address(deployer)) revert NotDeployer();

        isBuyVerifierOn = _Buystate;
        isSellVerifierOn = _Sellstate;
    }

    receive() external payable {}
}