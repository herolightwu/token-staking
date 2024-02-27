// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Azuki helper
import "erc721a/contracts/extensions/IERC721AQueryable.sol";
import "erc721a/contracts/extensions/IERC4907A.sol";

// enums
import "../utils/enums.sol";

/// @title Common Glasses
/// @author @n4beel & @nabeelimran852
/// @notice Interface for Script TV Glasses
interface IScriptGlasses is IERC721AQueryable, IERC4907A {
    /**
     * @dev Returns type of the glasses of the provided token ID
     * @param tokenID token ID of the glasses
     * @return type of the token ID
     */
    function glassType(uint256 tokenID) external view returns (ScriptNFTType);

    /**
     * @notice Mints NFT
     * @param to address of the recipient
     * @param _type type of Glasses NFT to be minted
     * @dev Only callable by Owner, will be called by low level call function
     */
    function safeMint(address to, ScriptNFTType _type)
        external
        returns (uint256);
}
