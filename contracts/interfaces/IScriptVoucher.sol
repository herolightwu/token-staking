// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../utils/enums.sol";

// interface for discount vouchers
interface IScriptVoucher is IERC1155 {
  // Add the mint function that is only callable by the owner
  function mint(address to, VoucherType tokenType) external;

  // Add the updateSupply function that is only callable by the owner
  function updateSupply(VoucherType tokenType, uint256 newSupply) external;

  // Add the updateMintPrice function that is only callable by the owner
  function updateMintPrice(VoucherType tokenType, uint256 newPrice) external;

  // return the discount percent of given voucher type
  function getDiscountPercentage(uint8 voucherType) external view returns (uint256);
}