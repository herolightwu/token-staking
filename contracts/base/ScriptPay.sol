// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Openzeppelin helper
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../utils/Errors.sol";

/// @title Script Pay
/// @author @n4beel & @nabeelimran852
/// @notice Contract for SPAY - native token of Script TV
contract ScriptPay is ERC20Burnable {
    // Address of the owner of ScriptTV
    address public scriptTV;

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
     * @notice Constructor
     * @dev inherits ERC20 with name and symbol
     */
    constructor() ERC20("ScriptPay", "SPAY") {
        ////////// to be reviewed ///////////
        _mint(msg.sender, 10000000000e18);
        /////////////////////////////////////
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * @param newAddress new address of the Script TV contract
     * Can only be called by the current owner.
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
     * @notice Mints SPAY
     * @param to address of the recipient
     * @param amount amount of SPAY to be minted
     * @dev Only callable by Owner, will be called by low level call function
     */
    function mint(address to, uint256 amount) external onlyScriptTV {
        _mint(to, amount);
    }
}
