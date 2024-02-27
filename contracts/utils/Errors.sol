// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./enums.sol";

/// Amount cannot be zero
error ZeroAmount();

/// Balance cannot be zero
error ZeroBalance();

/// Provided address is a zero address
error ZeroAddress();

/// new supply can't be less than previous
error SameOrLessSupply();

/// Caller is not ScriptTV
error NotScriptTV();

/// User has already claimed free glasses or Collateral
error AlreadyClaimed();

/// User does not own asset
error AssetNotOwned();

/// The provided signature is invalid
error InvalidSignature();

/// Transaction has already been executed
error TransactionAlreadyExecuted();

/// Insufficient asset supply
error InsufficientSupply();

/// User has insufficient balance, Needed `required` but has `balance`
error InsufficientFunds();

/// Provided type is out of range
error TypeOutOfRange(ScriptNFTType _type);

/// given voucher is not compatible with glass
error VoucherNotCompatible();

/// voucher not equipped with given glass
error VoucherNotEquipped();

/// voucher is already equipped with given glass
error VoucherAlreadyEquipped();

/// Provided percentage is out of range
error PercentageOutOfRange();

/// Provided value is same as the old one
error SameAsOld();

/// recharge limit of three times a day has already consumed
error DailyRechargeLimitExceeds();

/// recharge limit can't be less then 1
error LimitIsInvalid();

/// Percentages must add up to 100%
error PercentagesAreInvalid();

/// Renting is not allowed
error RentingNotAllowed();