// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {UD60x18, ud, exp, ln} from "@prb/math/src/UD60x18.sol";

/// @title Curve
/// @notice Bonding-curve math for vult. Total supply is unbounded above by K_SUPPLY,
///         and the cumulative ETH spent moves the curve forward.
/// @dev    Forward curve:   totalMinted(eth) = K * (1 - e^{-eth / S})
///         Inverse curve:   eth(total)       = -S * ln(1 - total / K)
///         Marginal price:  dP/dQ            = S / (K * e^{-eth / S}) = S * e^{eth / S} / K
///         All values are 1e18-scaled (UD60x18).
library Curve {
    /// @notice Total cap on supply. Asymptote of the forward curve.
    uint256 internal constant K_SUPPLY = 21_000_000e18;

    /// @notice Curve scale (ETH at which 1 - 1/e of supply has minted).
    uint256 internal constant S = 500e18;

    /// @notice Maximum eth/S value at which the curve is treated as fully exhausted.
    ///         exp(-50) ≈ 1.9e-22, which is below the UD60x18 precision floor of 1e-18, so
    ///         the residual unminted supply is indistinguishable from zero.
    uint256 internal constant MAX_EXP_X = 50e18;

    /// @notice Reverts on invalid sell amount (more than circulating supply).
    error SellExceedsSupply();

    /// @notice Reverts when the curve ratio collapses to a non-positive log argument.
    error InverseDomainError();

    /// @notice Cumulative tokens minted after `eth` total ETH has been spent into the curve.
    /// @param eth Cumulative ETH (1e18 scaled).
    /// @return Cumulative VULT minted (1e18 scaled). Asymptotic to K_SUPPLY.
    function totalMinted(uint256 eth) internal pure returns (uint256) {
        if (eth == 0) return 0;
        UD60x18 sUd = ud(S);
        UD60x18 e = ud(eth);
        UD60x18 x = _div(e, sUd); // eth/S, UD60x18
        if (x.unwrap() >= MAX_EXP_X) return K_SUPPLY; // saturated
        UD60x18 expPos = exp(x);                       // e^{eth/S}
        UD60x18 invExp = _div(ud(1e18), expPos);       // e^{-eth/S}
        UD60x18 oneMinus = _sub(ud(1e18), invExp);     // 1 - e^{-eth/S}
        return _mul(ud(K_SUPPLY), oneMinus).unwrap();
    }

    /// @notice VULT minted for a buy of `eth` ETH on top of `ethBefore` cumulative ETH.
    /// @param ethBefore Cumulative ETH before this buy.
    /// @param eth ETH being spent on this buy.
    /// @return VULT minted to the buyer.
    function mintFor(uint256 ethBefore, uint256 eth) internal pure returns (uint256) {
        if (eth == 0) return 0;
        uint256 a = totalMinted(ethBefore);
        uint256 b = totalMinted(ethBefore + eth);
        // The curve is monotonically increasing in eth, so b >= a, but UD60x18 rounding at
        // sub-wei scales can occasionally produce a == b + epsilon. Saturate at zero.
        return b > a ? b - a : 0;
    }

    /// @notice Marginal price (ETH per token, 1e18 scaled) at curve position `eth`.
    /// @param eth Cumulative ETH at the point of evaluation.
    /// @return ETH per VULT, 1e18 scaled.
    function marginalPrice(uint256 eth) internal pure returns (uint256) {
        UD60x18 sUd = ud(S);
        UD60x18 e = ud(eth);
        UD60x18 x = _div(e, sUd);
        UD60x18 expPos = x.unwrap() >= MAX_EXP_X ? exp(ud(MAX_EXP_X)) : exp(x);
        UD60x18 num = _mul(sUd, expPos);
        return _div(num, ud(K_SUPPLY)).unwrap();
    }

    /// @notice ETH owed to a seller burning `vultIn` tokens, given current curve position
    ///         `currentTotal` (the canonical fair-curve circulating supply).
    /// @param currentTotal Current fair-curve circulating supply (= totalMinted at curve position).
    /// @param vultIn Amount of VULT being sold (burned from circulation).
    /// @return ETH owed to the seller (1e18 scaled).
    /// @dev    ethOut = S * ln((K - currentTotal + vultIn) / (K - currentTotal)).
    function burnFor(uint256 currentTotal, uint256 vultIn) internal pure returns (uint256) {
        if (vultIn == 0) return 0;
        if (vultIn > currentTotal) revert SellExceedsSupply();
        uint256 k = K_SUPPLY;
        uint256 denomU = k - currentTotal;
        if (denomU == 0) revert InverseDomainError();
        uint256 numU = denomU + vultIn;
        UD60x18 ratio = _div(ud(numU), ud(denomU));
        UD60x18 lnR = ln(ratio);
        return _mul(ud(S), lnR).unwrap();
    }

    /// @notice ETH that would have been paid to mint `currentTotal` tokens via the forward curve.
    /// @param currentTotal Fair-curve circulating supply.
    /// @return ETH (1e18 scaled).
    /// @dev    ethAt(total) = -S * ln(1 - total/K) = S * ln(K / (K - total)).
    function ethAt(uint256 currentTotal) internal pure returns (uint256) {
        if (currentTotal == 0) return 0;
        uint256 k = K_SUPPLY;
        if (currentTotal >= k) revert InverseDomainError();
        UD60x18 ratio = _div(ud(k), ud(k - currentTotal));
        UD60x18 lnR = ln(ratio);
        return _mul(ud(S), lnR).unwrap();
    }

    // ------- thin UD60x18 helpers -------

    function _add(UD60x18 a, UD60x18 b) private pure returns (UD60x18) {
        return UD60x18.wrap(a.unwrap() + b.unwrap());
    }

    function _sub(UD60x18 a, UD60x18 b) private pure returns (UD60x18) {
        return UD60x18.wrap(a.unwrap() - b.unwrap());
    }

    function _mul(UD60x18 a, UD60x18 b) private pure returns (UD60x18) {
        return UD60x18.wrap((a.unwrap() * b.unwrap()) / 1e18);
    }

    function _div(UD60x18 a, UD60x18 b) private pure returns (UD60x18) {
        return UD60x18.wrap((a.unwrap() * 1e18) / b.unwrap());
    }
}
