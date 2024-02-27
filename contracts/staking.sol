// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract ScriptStaking is Ownable2Step, ReentrancyGuard, IERC721Receiver {
    IERC20 public immutable scpt;           //SCPT address
    IERC20 public immutable spay;           //SPAY address
    IERC721 public immutable glasspass;     //GlassPass NFT address

    uint256 public depositStart;
    uint256 public depositEnd;
    uint256 public stakingEnd;
    uint256 public lockedAmount;            //amount in SCPT token
    uint256 public depositLimit;            //amount in SCPT token
    uint256 public totalAmount = 0;         //amount in SCPT token

    uint256 public rateScpt = 223 * (10 ** 16);                // rate value for SPAY/SCPT (with decimal 18) for 1e18 SCPT    2.228956545242153...

    enum StakingPeriod { OneWeek, ThreeWeeks, TwoMonths, ThreeMonths, FourMonths, SixMonths, OneYear }

    mapping(uint256 => uint256) public nftPrices;     //price of Glasspass id in SCPT token

    mapping(StakingPeriod => uint256) public lockData; //lockAmount per staking period

    struct StakingData {
        uint256 scptAmount;                 // staked SCPT amount for every user
        uint256 stakeTime;
        StakingPeriod    lockPeriod;
        uint256 timeSinceLastReward;
        uint256 previousReward;
    }
    mapping(address => StakingData) public stakingData; 

    struct StakingNFTData {
        uint256[] nfts;                     // staked nft data for every user
        uint256 nftCnt;                     // nft count
        uint256 nftBalance;                 // total balance of all nfts in SCPT token
        uint256 stakeTime;
        StakingPeriod    lockPeriod;
        uint256 timeSinceLastReward;
        uint256 previousReward;
    }
    mapping(address => StakingNFTData) public stakingNftData; 

    struct StakingOption {
        uint256 duration;
        uint256 rewardPercentage;
        uint256 total;
        uint256 nftCnt;
    }
    mapping(StakingPeriod => StakingOption) public stakingOptions;
    

    event Stake(address indexed participant, uint256 amount);
    event StakeRewards(address indexed participant, uint256 amount);
    event Stake_Nft(address indexed participant, uint256[] ids);
    event Unstake(address indexed participant, uint256 amount);
    event RewordClaim(address indexed participant, uint256 amount);
    event Withdraw();

    constructor(
        IERC20 _scpt,
        IERC20 _spay,
        IERC721 _glasspass,
        uint256 _depositStart,
        uint256 _depositEnd,
        uint256 _stakingEnd,
        uint256 _lockedAmount,
        uint256 _depositLimit
    ) {
        require(
            address(_scpt) != address(0),
            "Staking: invalid SCPT token address"
        );
        require(
            address(_spay) != address(0),
            "Staking: invalid SPAY token address"
        );
        require(
            address(_glasspass) != address(0),
            "Staking: invalid GlassPass Nft address"
        );
        require(_depositStart > block.timestamp, 
            "Staking: start time must be bigger than current time"
        );
        require(
            _depositEnd > _depositStart,
            "Staking: end time must be bigger than start time"
        );
        require(
            _stakingEnd > _depositEnd,
            "Staking: unstaking time must be bigger than deposite time"
        );
        require(_lockedAmount > 0, 
            "Staking: amount must be bigger than zero"
        );
        require(_depositLimit > 0, 
            "Staking: deposit limit must be bigger than zero"
        );

        scpt = _scpt;
        spay = _spay;
        glasspass = _glasspass;
        depositStart = _depositStart;
        depositEnd = _depositEnd;
        stakingEnd = _stakingEnd;
        lockedAmount = _lockedAmount;       // init lock balance
        depositLimit = _depositLimit;

        stakingOptions[StakingPeriod.OneWeek] = StakingOption(1 weeks, 1, 0, 0);
        stakingOptions[StakingPeriod.ThreeWeeks] = StakingOption(3 weeks, 3, 0, 0);
        stakingOptions[StakingPeriod.TwoMonths] = StakingOption(60 days, 7, 0, 0);
        stakingOptions[StakingPeriod.ThreeMonths] = StakingOption(90 days, 9, 0, 0);
        stakingOptions[StakingPeriod.FourMonths] = StakingOption(120 days, 15, 0, 0);
        stakingOptions[StakingPeriod.SixMonths] = StakingOption(180 days, 17, 0, 0);
        stakingOptions[StakingPeriod.OneYear] = StakingOption(365 days, 28, 0, 0);

        lockData[StakingPeriod.OneWeek] = lockedAmount / 40;
        lockData[StakingPeriod.ThreeWeeks] = lockedAmount * 3 / 40;
        lockData[StakingPeriod.TwoMonths] = lockedAmount * 7 / 40;
        lockData[StakingPeriod.ThreeMonths] = lockedAmount * 9 / 40;
        lockData[StakingPeriod.FourMonths] = lockedAmount / 8;
        lockData[StakingPeriod.SixMonths] = lockedAmount / 8;
        lockData[StakingPeriod.OneYear] = lockedAmount / 4;

    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external view override returns (bytes4) {
    
        return IERC721Receiver.onERC721Received.selector;
    }

    function calculateUnlockTime(StakingPeriod stakingPeriod) internal view returns (uint256) {
        return stakingOptions[stakingPeriod].duration;
    }
    
    // stake SCPT
    function stake(StakingPeriod stakingPeriod, uint256 amount) external nonReentrant returns(bool) {
        require(block.timestamp >= depositStart , "Staking: Unable to stake before deposit start!");
        require(block.timestamp <= depositEnd , "Staking: Unable to stake after deposit end!");
        
        uint256 allowance = IERC20(scpt).allowance(_msgSender(), address(this));
        require(allowance >= amount, "Staking: Insufficient allowance");

        uint256 newTotalAmount = stakingOptions[stakingPeriod].total + amount;
        require(newTotalAmount <= lockData[stakingPeriod], "Staking: Amount exceeds total lock amount");

        uint256 newBalance = stakingData[_msgSender()].scptAmount + amount;
        require(newBalance + stakingNftData[_msgSender()].nftBalance <= depositLimit, "Staking: Amount exceeds deposit limit");
        if (stakingData[_msgSender()].scptAmount > 0) {
            stakingData[_msgSender()].previousReward = calculateEarnedAmount(_msgSender());
        }
        
        stakingData[_msgSender()].scptAmount = newBalance;
        stakingData[_msgSender()].stakeTime = block.timestamp;
        stakingData[_msgSender()].lockPeriod = stakingPeriod;
        stakingData[_msgSender()].timeSinceLastReward = block.timestamp;

        stakingOptions[stakingPeriod].total = newTotalAmount;

        totalAmount += amount;

        SafeERC20.safeTransferFrom(scpt, _msgSender(), address(this), amount);

        emit Stake(_msgSender(), amount);

        return true;
    }

    // set nft prices
    function setnft_price(uint256[] calldata ids, uint256[] calldata prices) external onlyOwner() returns(bool) {
        require(ids.length == prices.length, "Staking: arrays must have same length");
        for (uint256 i = 0; i < ids.length; i++) {
            require(prices[i] > 0, "Staking: price must be bigger than zero");
            nftPrices[ids[i]] = prices[i];
        }
        return true;
    }

    // stake Glasspass NFT
    function stake_nft(StakingPeriod stakingPeriod, uint256[] calldata ids) external nonReentrant returns(bool) {
        require(block.timestamp >= depositStart , "Staking: Unable to stake before deposit start!");
        require(block.timestamp <= depositEnd , "Staking: Unable to stake after deposit end!");

        uint256 amount = 0;
        for (uint256 i = 0; i < ids.length; i++ ){
            require(nftPrices[ids[i]] > 0, "Staking: price is undefined yet");
            amount = amount + nftPrices[ids[i]];
        }
        
        uint256 newTotalAmount = stakingOptions[stakingPeriod].total + amount;
        require(newTotalAmount <= lockData[stakingPeriod], "Staking: Amount exceeds total lock amount");

        uint256 newBalance = stakingNftData[_msgSender()].nftBalance + amount;
        require(newBalance + stakingData[_msgSender()].scptAmount <= depositLimit, "Staking: Amount exceeds deposit limit");
        
        if (stakingNftData[_msgSender()].nftBalance > 0) {
            stakingNftData[_msgSender()].previousReward = calculateEarnedAmountForNft(_msgSender());
        }

        stakingNftData[_msgSender()].nftBalance = newBalance;

        totalAmount += amount;
        
        uint256 count = stakingNftData[_msgSender()].nftCnt;
        for (uint256 i = 0; i < ids.length; i++ ){
            stakingNftData[_msgSender()].nfts.push(ids[i]);
            count = count + 1;
            IERC721(glasspass).safeTransferFrom( _msgSender(), address(this), ids[i]);
        }
        stakingNftData[_msgSender()].nftCnt = count;
        stakingNftData[_msgSender()].stakeTime = block.timestamp;
        stakingNftData[_msgSender()].lockPeriod = stakingPeriod;
        stakingNftData[_msgSender()].timeSinceLastReward = block.timestamp;

        stakingOptions[stakingPeriod].nftCnt = stakingOptions[stakingPeriod].nftCnt + count;
        stakingOptions[stakingPeriod].total = newTotalAmount;

        emit Stake_Nft(_msgSender(), ids);

        return true;
    }

    // stake rewards SCPT
    function stakeRewards() external nonReentrant returns(bool) {
        require(block.timestamp >= depositStart , "Staking: Unable to stake before deposit start!");
        uint256 amount = calculateEarnedAmount(_msgSender());
        StakingPeriod stakingPeriod = stakingData[_msgSender()].lockPeriod;
        require(amount > 0, "Staking: Insufficient rewards");
        
        uint256 allowance = IERC20(scpt).allowance(_msgSender(), address(this));
        require(allowance >= amount, "Staking: Insufficient allowance");

        uint256 newTotalAmount = stakingOptions[stakingPeriod].total + amount;
        require(newTotalAmount <= lockData[stakingPeriod], "Staking: Amount exceeds total lock amount");

        uint256 newBalance = stakingData[_msgSender()].scptAmount + amount;
        require(newBalance + stakingNftData[_msgSender()].nftBalance <= depositLimit, "Staking: Amount exceeds deposit limit");
        stakingData[_msgSender()].previousReward = 0;
        
        stakingData[_msgSender()].scptAmount = newBalance;
        stakingData[_msgSender()].stakeTime = block.timestamp;
        stakingData[_msgSender()].timeSinceLastReward = block.timestamp;

        stakingOptions[stakingPeriod].total = newTotalAmount;

        totalAmount += amount;
        
        emit StakeRewards(_msgSender(), amount);

        return true;
    }

    function increaseStakingPeriod(StakingPeriod periodOption) external  returns (bool){
        require(stakingOptions[periodOption].duration > 0, "Invalid staking duration");
        require(stakingData[_msgSender()].lockPeriod < periodOption, "New unlock time must be in the future");

        StakingPeriod previousPeriod = stakingData[_msgSender()].lockPeriod;
        stakingOptions[previousPeriod].total = stakingOptions[previousPeriod].total - stakingData[_msgSender()].scptAmount;
        stakingData[_msgSender()].lockPeriod =  periodOption;
        stakingOptions[periodOption].total = stakingOptions[periodOption].total + stakingData[_msgSender()].scptAmount;

        return  true;
    }

    function increaseStakingPeriodNft(StakingPeriod periodOption) external  returns (bool){
        require(stakingOptions[periodOption].duration > 0, "Invalid staking duration");
        require(stakingNftData[_msgSender()].lockPeriod < periodOption, "New unlock time must be in the future");

        StakingPeriod previousPeriod = stakingNftData[_msgSender()].lockPeriod;
        stakingOptions[previousPeriod].total = stakingOptions[previousPeriod].total - stakingNftData[_msgSender()].nftBalance;
        stakingOptions[previousPeriod].nftCnt = stakingOptions[previousPeriod].nftCnt - stakingNftData[_msgSender()].nftCnt;
        stakingNftData[_msgSender()].lockPeriod =  periodOption;
        stakingOptions[periodOption].total = stakingOptions[periodOption].total + stakingNftData[_msgSender()].nftBalance;
        stakingOptions[periodOption].nftCnt = stakingOptions[periodOption].nftCnt + stakingNftData[_msgSender()].nftCnt;

        return  true;
    } 

    function unstake() external returns(bool) {
        require(block.timestamp >= stakingEnd , "Staking: Unable to unstake before stakingEnd!");

        uint256 balance = stakingData[_msgSender()].scptAmount;

        require(balance > 0, "Staking: Insufficient balance");

        uint256 lockedPeriod = stakingData[_msgSender()].stakeTime + calculateUnlockTime(stakingData[_msgSender()].lockPeriod);
        require(lockedPeriod <= block.timestamp,"Staking: Your locking period is not yet over.");

        claimReward(_msgSender());

        StakingPeriod previousPeriod = stakingData[_msgSender()].lockPeriod;
        stakingOptions[previousPeriod].total = stakingOptions[previousPeriod].total - stakingData[_msgSender()].scptAmount;

        stakingData[_msgSender()].scptAmount = 0;     
        stakingData[_msgSender()].stakeTime = 0;
        SafeERC20.safeTransfer(scpt, _msgSender(), balance);

        totalAmount -= balance;
        emit Unstake(_msgSender(), balance);

        return true;
    }

    function unstakeNft() external returns(bool) {
        require(block.timestamp >= stakingEnd , "Staking: Unable to unstake before stakingEnd!");

        uint256 balance = stakingNftData[_msgSender()].nftBalance;

        require(balance > 0, "Staking: Insufficient balance");

        uint256 lockedPeriod = stakingNftData[_msgSender()].stakeTime + calculateUnlockTime(stakingNftData[_msgSender()].lockPeriod);
        require(lockedPeriod <= block.timestamp,"Staking: Your locking period is not yet over.");

        claimRewardNft(_msgSender());

        StakingPeriod previousPeriod = stakingNftData[_msgSender()].lockPeriod;
        stakingOptions[previousPeriod].total = stakingOptions[previousPeriod].total - stakingNftData[_msgSender()].nftBalance;
        stakingOptions[previousPeriod].nftCnt = stakingOptions[previousPeriod].nftCnt - stakingNftData[_msgSender()].nftCnt;

        stakingNftData[_msgSender()].nftBalance = 0;        
        stakingNftData[_msgSender()].stakeTime = 0;
        SafeERC20.safeTransfer(scpt, _msgSender(), balance);
        for(uint256 i = 0; i < stakingNftData[_msgSender()].nftCnt; i++){
            IERC721(glasspass).safeTransferFrom( address(this), _msgSender(), stakingNftData[_msgSender()].nfts[i]);
        }

        stakingNftData[_msgSender()].nftCnt = 0;
        // Clear the staked NFTs array
        delete stakingNftData[_msgSender()].nfts;

        totalAmount -= balance;
        emit Unstake(_msgSender(), balance);

        return true;
    }

    // claim reward as SCPT
    function claimReward(address account) public nonReentrant returns (bool){
        uint256 balance = stakingData[account].scptAmount;

        require(balance > 0, "Staking: Insufficient balance");
        uint256 earnedAmount = calculateEarnedAmount(account) + stakingData[account].previousReward;

        if (earnedAmount > 0) {
            SafeERC20.safeTransfer(scpt, account, earnedAmount);
            stakingData[account].previousReward = 0;
            stakingData[account].timeSinceLastReward = block.timestamp;
        }

        emit RewordClaim(account, earnedAmount);

        return  true;
    }

    // claim reward as SCPT
    function claimRewardNft(address account) public nonReentrant returns (bool){
        uint256 balance = stakingNftData[account].nftBalance;

        require(balance > 0, "Staking: Insufficient balance");
        uint256 earnedAmount = calculateEarnedAmountForNft(account) + stakingNftData[account].previousReward;

        if (earnedAmount > 0) {
            SafeERC20.safeTransfer(scpt, account, earnedAmount);
            stakingNftData[account].previousReward = 0;
            stakingNftData[account].timeSinceLastReward = block.timestamp;
        }

        emit RewordClaim(account, earnedAmount);

        return  true;
    }

    // claim reward as SPAY
    function claimRewardSpay() public nonReentrant returns (bool){
        uint256 balance = stakingData[_msgSender()].scptAmount;

        require(balance > 0, "Staking: Insufficient balance");
        uint256 earnedAmount = calculateEarnedAmount(_msgSender()) + stakingData[_msgSender()].previousReward;
        if (earnedAmount > 0) {
            uint256 spayAmount = earnedAmount * rateScpt / 1e18;
            SafeERC20.safeTransfer(spay, _msgSender(), spayAmount);
            stakingData[_msgSender()].previousReward = 0;
            stakingData[_msgSender()].timeSinceLastReward = block.timestamp;
        }

        emit RewordClaim(_msgSender(),earnedAmount);

        return  true;
    }

    // claim reward as SPAY
    function claimRewardNftSpay() public nonReentrant returns (bool){
        uint256 balance = stakingNftData[_msgSender()].nftBalance;

        require(balance > 0, "Staking: Insufficient balance");
        uint256 earnedAmount = calculateEarnedAmountForNft(_msgSender()) + stakingNftData[_msgSender()].previousReward;
        if (earnedAmount > 0) {
            uint256 spayAmount = earnedAmount * rateScpt / 1e18;
            SafeERC20.safeTransfer(spay, _msgSender(), spayAmount);
            stakingNftData[_msgSender()].previousReward = 0;
            stakingNftData[_msgSender()].timeSinceLastReward = block.timestamp;
        }

        emit RewordClaim(_msgSender(),earnedAmount);

        return  true;
    }

    function getLockingPeriod(address account) public view returns (uint256) {
        uint256 lockedPeriod = stakingData[account].stakeTime + calculateUnlockTime(stakingData[account].lockPeriod);
        require(lockedPeriod !=0, "Staking: UnLocked period does not exist for the this user.");
        return lockedPeriod;
    }

    function getNftLockingPeriod(address account) public view returns (uint256) {
        uint256 lockedPeriod = stakingNftData[account].stakeTime + calculateUnlockTime(stakingNftData[account].lockPeriod);
        require(lockedPeriod !=0, "Staking: UnLocked period does not exist for the this user.");
        return lockedPeriod;
    }

    function calculateEarnedAmount(address account) public view returns(uint256) {
        uint256 balance = stakingData[account].scptAmount;
        uint256 lockedPeriodTimestamp = stakingData[account].timeSinceLastReward;
        require(lockedPeriodTimestamp !=0, "Staking: UnLocked period does not exist for the this user.");

        uint256 stakingDuration = block.timestamp - lockedPeriodTimestamp;

        uint256 duration = calculateUnlockTime(stakingData[account].lockPeriod);
        uint256 annualReward= stakingOptions[stakingData[account].lockPeriod].rewardPercentage;
        if (stakingDuration >= duration) {
            return (balance * annualReward * stakingDuration) / (100 * duration);
        } else {
            return 0;
        }
    }

    function calculateEarnedAmountForNft(address account) public view returns(uint256) {
        uint256 balance = stakingNftData[account].nftBalance;
        uint256 lockedPeriodTimestamp = stakingNftData[account].timeSinceLastReward;
        require(lockedPeriodTimestamp !=0, "Staking: UnLocked period does not exist for the this user.");

        uint256 stakingDuration = block.timestamp - lockedPeriodTimestamp;

        uint256 duration = calculateUnlockTime(stakingNftData[account].lockPeriod);
        uint256 annualReward= stakingOptions[stakingNftData[account].lockPeriod].rewardPercentage;
        if (stakingDuration >= duration) {
            return (balance * annualReward * stakingDuration) / (100 * duration);
        } else {
            return 0;
        }
    }

    function setRateScpt(uint256 _rateScpt) public onlyOwner() returns(bool) {
        require(_rateScpt > 0, "Staking: Rating must be bigger than zero");
        rateScpt = _rateScpt;
        return true;
    }

    function withdraw() public onlyOwner() returns (bool) {
        require(totalAmount <= 0 || block.timestamp > stakingEnd + 1460 days, "Staking: all users needs to unstake the tokens or allow withdraw later than 4 years");

        uint256 scpt_balance = IERC20(scpt).balanceOf(address(this));
        require(scpt_balance > 0, "Staking: Insufficient balance");
        SafeERC20.safeTransfer(scpt, _msgSender(), scpt_balance);

        uint256 spay_balance = IERC20(spay).balanceOf(address(this));
        require(spay_balance > 0, "Staking: Insufficient balance");
        SafeERC20.safeTransfer(spay, _msgSender(), spay_balance);
        emit Withdraw();
        return true;
    }
}