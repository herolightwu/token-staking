// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Openzeppelin helper
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ScriptToken is ERC20,Ownable{

    uint256 _totalSupply = 1000 * 10**6 * 10**18;
    uint8 _decimal=18;
    string _name='ScriptToken';
    string _symbol='SCPT';

    constructor () ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    }
    function decimals() public view override returns (uint8) {
        return _decimal;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
}