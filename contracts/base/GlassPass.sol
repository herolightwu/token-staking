// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Azuki helper
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @title Glass Pass
/// @author 
/// @notice contract for Script Glass Pass
contract GlassPass is  ERC721Enumerable{
  // Address of the owner of ScriptTV
  address public scriptTV;
  uint tokenCount;
  /**
   * @notice Constructor
   * @dev inherits ERC721 with name and symbol
   */
  constructor() ERC721("GlassPass", "GPAS") {
    scriptTV = msg.sender;
    tokenCount = 1;
  }

  function burn(uint256 tokenId) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
    _burn(tokenId);
  }

  function safeMint(address  to) external {
    _safeMint(to, tokenCount);
    tokenCount = tokenCount + 1;
  }

}
