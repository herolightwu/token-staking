// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Azuki helper
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC4907A.sol";

// enums
import "../utils/enums.sol";
import "../utils/Errors.sol";

/// @title Common Glasses
/// @author @n4beel & @nabeelimran852
/// @notice Contract for Script TV Glasses
contract ScriptGlasses is ERC721AQueryable, ERC4907A {
  // Address of the owner of ScriptTV
  address public scriptTV;

  // rentable status 
  bool public isRentingAllowed;

  // token URI
  string private baseTokenURI;

  // mapping for containing type of a glass for each token ID
  // 0 - Common
  // 1 - Rare
  // 2 - Superscript
  // 3 - Free
  mapping(uint256 => ScriptNFTType) private glassesType;

  /**
   * @notice Emitted when the ScriptTV address is set
   * @param previousAddress older address of ScriptTV
   * @param newAddress new address of ScriptTV
   */
  event ScriptTVSet(
    address indexed previousAddress,
    address indexed newAddress
  );

  /**
   * @notice Emitted when the baseURI is updated
   * @param oldURI old URI
   * @param newURI new URI
   */
  event URIUpdated(
    string oldURI,
    string newURI
  );

  /**
   * @notice Constructor
   * @dev inherits ERC721 with name and symbol
   */
  constructor() ERC721A("ScriptGlasses", "SGLS") {
    scriptTV = msg.sender;
  }

  /**
   * @dev Throws error if called by any address other than the Script TV.
   */
  modifier onlyScriptTV() {
    if (scriptTV != msg.sender) {
      revert NotScriptTV();
    }
    _;
  }

  /**
   * @notice start the token Ids with 1.
   */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
   * @dev Returns next available token ID
   * @return next token ID
   */
  function getNextTokenId() external view returns (uint256) {
    return _nextTokenId();
  }

  /**
   * @dev Returns type of the glasses of the provided token ID
   * @param tokenID token ID of the glasses
   * @return type of the token ID
   */
  function glassType(uint256 tokenID) external view returns (ScriptNFTType) {
    return glassesType[tokenID];
  }

  /**
   * @notice Transfers ownership of the contract to a new account.
   * @param newAddress new address of the Script TV contract
   * @dev Can only be called by the scriptTV.
   */
  function setScriptTV(address newAddress) external onlyScriptTV {
    address prevAddress = scriptTV;
    if (newAddress == address(0)) {
      revert ZeroAddress();
    }
    scriptTV = newAddress;
    emit ScriptTVSet(prevAddress, newAddress);
  }

  /**
   * @notice Mints NFT
   * @param to address of the recipient
   * @param _type type of Glasses NFT to be minted
   * @dev Only callable by Owner
   */
  function safeMint(address to, ScriptNFTType _type)
    external
    onlyScriptTV
    returns (uint256)
  {
    uint256 tokenID = _nextTokenId();
    _safeMint(to, 1);
    glassesType[tokenID] = _type;
    return tokenID;
  }

  /**
   * @notice Returns base URI
   * @param _newURI new base URI
   */
  function updateBaseURI(string calldata _newURI) external onlyScriptTV {
    string memory oldUri = baseTokenURI;
    baseTokenURI = _newURI;

    emit URIUpdated(oldUri, baseTokenURI);
  }

  /**
   * @notice Returns base URI
   * @return string containing the uri
   */
  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  /**
   * @notice Returns base URI
   * @return string containing the uri
   */
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A, IERC721A)
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
        : "";
  }

  /**
   * @notice Flip the state of Renting to ON/OFF
   */
  function flipRentableState() external onlyScriptTV {
    isRentingAllowed = !isRentingAllowed;
  }

  /**
   * @dev Sets the `user` and `expires` for `tokenId`.
   * The zero address indicates there is no user.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function setUser(
    uint256 tokenId,
    address user,
    uint64 expires
  ) public virtual override {
    // Require the rentable functionality to be turned on.
    if (!isRentingAllowed) {
      revert RentingNotAllowed();
    }
    super.setUser(tokenId, user, expires);
  }

  /**
   * @dev Override of {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, IERC721A, ERC4907A)
    returns (bool)
  {
    // The interface ID for ERC4907 is `0xad092b5c`,
    // as defined in [ERC4907](https://eips.ethereum.org/EIPS/eip-4907).
    return super.supportsInterface(interfaceId) || interfaceId == 0xad092b5c;
  }
}
