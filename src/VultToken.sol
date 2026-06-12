// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title VultToken
/// @notice Plain ERC-20 with one designated minter that is locked in once and cannot be changed.
///         No owner. No pause. No blacklist. No fee logic. No upgrade path.
contract VultToken is ERC20 {
    /// @notice The designated minter (the VultHook). Locked once `setMinter` is called.
    address public minter;

    /// @notice The address that deployed this contract (only entity allowed to set the minter once).
    address public immutable DEPLOYER;

    /// @notice Marker that asserts this contract makes no use of any restriction primitive.
    bool public immutable RESTRICTIONS_FORBIDDEN = true;

    /// @notice The block at which this contract was deployed.
    uint256 public immutable GENESIS_BLOCK;

    /// @notice The hash of the block immediately preceding deployment. Burned into bytecode.
    bytes32 public immutable GENESIS_HASH;

    /// @notice Reverts when a caller other than the deployer tries to set the minter.
    error NotDeployer();

    /// @notice Reverts when a caller other than the locked-in minter tries to mint.
    error NotMinter();

    /// @notice Reverts when `setMinter` is called more than once.
    error MinterAlreadySet();

    /// @notice Reverts when a zero-address minter is supplied.
    error MinterIsZero();

    /// @notice Emitted exactly once, the moment the minter is permanently locked in.
    event MinterLocked(address indexed minter);

    /// @notice Construct the token. No constructor arguments.
    constructor() ERC20("Vult", "Vult") {
        DEPLOYER = msg.sender;
        GENESIS_BLOCK = block.number;
        GENESIS_HASH = blockhash(block.number - 1);
    }

    /// @notice Set the minter exactly once, then lock forever.
    /// @param newMinter The address (the VultHook) that will be the sole entity allowed to mint.
    function setMinter(address newMinter) external {
        if (msg.sender != DEPLOYER) revert NotDeployer();
        if (minter != address(0)) revert MinterAlreadySet();
        if (newMinter == address(0)) revert MinterIsZero();
        minter = newMinter;
        emit MinterLocked(newMinter);
    }

    /// @notice Mint VULT. Callable only by the locked-in minter.
    /// @param to Recipient of newly minted tokens.
    /// @param amount Amount in 1e18-scaled units.
    function mint(address to, uint256 amount) external {
        if (msg.sender != minter) revert NotMinter();
        _mint(to, amount);
    }

    /// @notice Burn VULT held by `from`. Callable only by the locked-in minter (the hook),
    ///         used to retire tokens during sells settled against the inverse curve.
    /// @param from Account whose tokens are burned.
    /// @param amount Amount in 1e18-scaled units.
    function burn(address from, uint256 amount) external {
        if (msg.sender != minter) revert NotMinter();
        _burn(from, amount);
    }
}
