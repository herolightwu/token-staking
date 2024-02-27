// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title Glass Pass
/// @author @nabeelimran852
/// @notice Interface for Script Glass Pass
interface IGlassPass is  IERC721Enumerable{
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     * @param tokenId token ID of the glasses
     */
    function burn(uint256 tokenId) external;
}
