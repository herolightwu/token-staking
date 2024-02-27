// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Script Pay
/// @author @n4beel & @nabeelimran852
/// @notice Interface for SPAY - native token of Script TV
interface IScriptPay is IERC20 {
    /**
     * @notice Mints SPAY
     * @param to address of the recipient
     * @param amount amount of SPAY to be minted
     * @dev Only callable by Owner, will be called by low level call function
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;
}
