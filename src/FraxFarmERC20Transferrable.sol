// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================= FraxUnifiedFarm_ERC20 ======================
// ====================================================================
// For ERC20 Tokens
// Uses FraxUnifiedFarmTemplate.sol

import "forge-std/console2.sol";

import "@frax/FraxUnifiedFarmTemplate.sol";
import "@interfaces/ILockReceiver.sol";

import "@frax/../Oracle/AggregatorV3Interface.sol";
// import "./FraxFarmERC20Transferrable.sol";
import "@frax/../Curve/ICurvefrxETHETHPool.sol";
import "@frax/../Misc_AMOs/convex/IConvexStakingWrapperFrax.sol";
import "@frax/../Misc_AMOs/convex/IDepositToken.sol";
import "@frax/../Misc_AMOs/curve/I2pool.sol";
import "@frax/../Misc_AMOs/curve/I2poolToken.sol";
// -------------------- VARIES --------------------

// Convex wrappers
// import "../Misc_AMOs/convex/IConvexStakingWrapperFrax.sol";
// import "../Misc_AMOs/convex/IDepositToken.sol";
// import "../Misc_AMOs/curve/I2pool.sol";
// import "../Misc_AMOs/curve/I2poolToken.sol";

// Fraxswap
import '@frax/../Fraxswap/core/interfaces/IFraxswapPair.sol';

// G-UNI
// import "../Misc_AMOs/gelato/IGUniPool.sol";

// mStable
// import '../Misc_AMOs/mstable/IFeederPool.sol';

// StakeDAO sdETH-FraxPut
// import '../Misc_AMOs/stakedao/IOpynPerpVault.sol';

// StakeDAO Vault
// import '../Misc_AMOs/stakedao/IStakeDaoVault.sol';

// Uniswap V2
// import '../Uniswap/Interfaces/IUniswapV2Pair.sol';

// Vesper
// import '../Misc_AMOs/vesper/IVPool.sol';

// ------------------------------------------------

contract FraxUnifiedFarm_ERC20 is FraxUnifiedFarmTemplate {

    /* ========== STATE VARIABLES ========== */

    // -------------------- COMMON -------------------- 
    bool internal frax_is_token0;

    // -------------------- VARIES --------------------

    // Convex stkcvxFPIFRAX, stkcvxFRAXBP, etc
    // IConvexStakingWrapperFrax public stakingToken;
    // I2poolToken public curveToken;
    // I2pool public curvePool;

    // Fraxswap
    IConvexStakingWrapperFrax public stakingToken = IConvexStakingWrapperFrax(0x4659d5fF63A1E1EDD6D5DD9CC315e063c95947d0);

    // G-UNI
    // IGUniPool public stakingToken;
    
    // mStable
    // IFeederPool public stakingToken;

    // sdETH-FraxPut Vault
    // IOpynPerpVault public stakingToken;

    // StakeDAO Vault
    // IStakeDaoVault public stakingToken;

    // Uniswap V2
    // IUniswapV2Pair public stakingToken;

    // Vesper
    // IVPool public stakingToken;

    // ------------------------------------------------

    // Stake tracking
    mapping(address => LockedStake[]) public lockedStakes;

    /* ========== STRUCTS ========== */

    // Struct for the stake
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    I2poolToken public curveToken = I2poolToken(0xf43211935C781D5ca1a41d2041F397B8A7366C7A);
    ICurvefrxETHETHPool public curvePool = ICurvefrxETHETHPool(0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577); 
    AggregatorV3Interface public priceFeedETHUSD = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /* ========== CONSTRUCTOR ========== */

    constructor (
        address _owner,
        address[] memory _rewardTokens,
        address[] memory _rewardManagers,
        uint256[] memory _rewardRatesManual,
        address[] memory _gaugeControllers,
        address[] memory _rewardDistributors,
        address _stakingToken
    ) 
    FraxUnifiedFarmTemplate(_owner, _rewardTokens, _rewardManagers, _rewardRatesManual, _gaugeControllers, _rewardDistributors)
    {

        // -------------------- VARIES --------------------

        // Fraxswap
        // stakingToken = IFraxswapPair(_stakingToken);
        // address token0 = stakingToken.token0();
        // frax_is_token0 = (token0 == frax_address);

        // G-UNI
        // stakingToken = IGUniPool(_stakingToken);
        // address token0 = address(stakingToken.token0());
        // frax_is_token0 = (token0 == frax_address);

        // mStable
        // stakingToken = IFeederPool(_stakingToken);

        // StakeDAO sdETH-FraxPut Vault
        // stakingToken = IOpynPerpVault(_stakingToken);

        // StakeDAO Vault
        // stakingToken = IStakeDaoVault(_stakingToken);

        // Uniswap V2
        // stakingToken = IUniswapV2Pair(_stakingToken);
        // address token0 = stakingToken.token0();
        // if (token0 == frax_address) frax_is_token0 = true;
        // else frax_is_token0 = false;

        // Vesper
        // stakingToken = IVPool(_stakingToken);
                // COMMENTED OUT SO COMPILER DOESNT COMPLAIN. UNCOMMENT WHEN DEPLOYING

        // Convex frxETHETH only
        // stakingToken = IConvexStakingWrapperFrax(_stakingToken);
        // //curveToken = I2poolToken(stakingToken.curveToken());
        // curveToken = I2poolToken(0xf43211935C781D5ca1a41d2041F397B8A7366C7A);
        // //curvePool = ICurvefrxETHETHPool(curveToken.minter());
        // curvePool = ICurvefrxETHETHPool(0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577);
        // address token0 = curvePool.coins(0);
        // frax_is_token0 = false; // Doesn't matter for frxETH
    }

    /* ============= VIEWS ============= */

    // ------ FRAX RELATED ------

    function fraxPerLPToken() public virtual view override returns (uint256) {
        // Get the amount of FRAX 'inside' of the lp tokens
        uint256 frax_per_lp_token;

        // Convex stkcvxFPIFRAX and stkcvxFRAXBP only
        // ============================================
        // {
        //     // Half of the LP is FRAXBP
        //     // Using 0.5 * virtual price for gas savings
        //     frax_per_lp_token = curvePool.get_virtual_price() / 2; 
        // }

        // Convex Stable/FRAXBP
        // ============================================
        // {
        //     // Half of the LP is FRAXBP. Half of that should be FRAX.
        //     // Using 0.25 * virtual price for gas savings
        //     frax_per_lp_token = curvePool.get_virtual_price() / 4; 
        // }

        // Convex Volatile/FRAXBP
        // ============================================
        // {
        //     // Half of the LP is FRAXBP. Half of that should be FRAX.
        //     // Using 0.25 * lp price for gas savings
        //     frax_per_lp_token = curvePool.lp_price() / 4; 
        // }

        // Fraxswap
        // ============================================
        // {
        //     uint256 total_frax_reserves;
        //     (uint256 _reserve0, uint256 _reserve1, , ,) = (stakingToken.getReserveAfterTwamm(block.timestamp));
        //     if (frax_is_token0) total_frax_reserves = _reserve0;
        //     else total_frax_reserves = _reserve1;

        //     frax_per_lp_token = (total_frax_reserves * 1e18) / stakingToken.totalSupply();
        // }

        // G-UNI
        // ============================================
        // {
        //     (uint256 reserve0, uint256 reserve1) = stakingToken.getUnderlyingBalances();
        //     uint256 total_frax_reserves = frax_is_token0 ? reserve0 : reserve1;

        //     frax_per_lp_token = (total_frax_reserves * 1e18) / stakingToken.totalSupply();
        // }

        // mStable
        // ============================================
        // {
        //     uint256 total_frax_reserves;
        //     (, IFeederPool.BassetData memory vaultData) = (stakingToken.getBasset(frax_address));
        //     total_frax_reserves = uint256(vaultData.vaultBalance);
        //     frax_per_lp_token = (total_frax_reserves * 1e18) / stakingToken.totalSupply();
        // }

        // StakeDAO sdETH-FraxPut Vault
        // ============================================
        // {
        //    uint256 frax3crv_held = stakingToken.totalUnderlyingControlled();
        
        //    // Optimistically assume 50/50 FRAX/3CRV ratio in the metapool to save gas
        //    frax_per_lp_token = ((frax3crv_held * 1e18) / stakingToken.totalSupply()) / 2;
        // }

        // StakeDAO Vault
        // ============================================
        // {
        //    uint256 frax3crv_held = stakingToken.balance();
        
        //    // Optimistically assume 50/50 FRAX/3CRV ratio in the metapool to save gas
        //    frax_per_lp_token = ((frax3crv_held * 1e18) / stakingToken.totalSupply()) / 2;
        // }

        // Uniswap V2
        // ============================================
        // {
        //     uint256 total_frax_reserves;
        //     (uint256 reserve0, uint256 reserve1, ) = (stakingToken.getReserves());
        //     if (frax_is_token0) total_frax_reserves = reserve0;
        //     else total_frax_reserves = reserve1;

        //     frax_per_lp_token = (total_frax_reserves * 1e18) / stakingToken.totalSupply();
        // }

        // Vesper
        // ============================================
        // frax_per_lp_token = stakingToken.pricePerShare();

        // Convex frxETH/ETH
        // ============================================
        {
            // Assume frxETH = ETH for pricing purposes
            // Get the USD value of the frxETH per LP token
            uint256 frxETH_in_pool = IERC20(0x5E8422345238F34275888049021821E8E08CAa1f).balanceOf(address(0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577));
            uint256 frxETH_usd_val_per_lp_e8 = (frxETH_in_pool * uint256(getLatestETHPriceE8())) / I2poolToken(0xf43211935C781D5ca1a41d2041F397B8A7366C7A).totalSupply();// = I2poolToken(0xf43211935C781D5ca1a41d2041F397B8A7366C7A);//curveToken.totalSupply();
            frax_per_lp_token = frxETH_usd_val_per_lp_e8 * (1e10); // We use USD as "Frax" here
        }
        return frax_per_lp_token;
    }

    function getLatestETHPriceE8() public view returns (int) {
        // Returns in E8
        (uint80 roundID, int price, , uint256 updatedAt, uint80 answeredInRound) = priceFeedETHUSD.latestRoundData();
        require(price >= 0 && updatedAt!= 0 && answeredInRound >= roundID, "Invalid chainlink price");
        
        return price;
    }

    function setETHUSDOracle(address _eth_usd_oracle_address) public onlyByOwnGov {
        require(_eth_usd_oracle_address != address(0), "Zero address detected");

        priceFeedETHUSD = AggregatorV3Interface(_eth_usd_oracle_address);
    }
    // ------ LIQUIDITY AND WEIGHTS ------

    function calcCurrLockMultiplier(address account, uint256 stake_idx) public view returns (uint256 midpoint_lock_multiplier) {
        // Get the stake
        LockedStake memory thisStake = lockedStakes[account][stake_idx];

        // Handles corner case where user never claims for a new stake
        // Don't want the multiplier going above the max
        uint256 accrue_start_time;
        if (lastRewardClaimTime[account] < thisStake.start_timestamp) {
            accrue_start_time = thisStake.start_timestamp;
        }
        else {
            accrue_start_time = lastRewardClaimTime[account];
        }
        
        // If the lock is expired
        if (thisStake.ending_timestamp <= block.timestamp) {
            // If the lock expired in the time since the last claim, the weight needs to be proportionately averaged this time
            if (lastRewardClaimTime[account] < thisStake.ending_timestamp){
                uint256 time_before_expiry = thisStake.ending_timestamp - accrue_start_time;
                uint256 time_after_expiry = block.timestamp - thisStake.ending_timestamp;

                // Average the pre-expiry lock multiplier
                uint256 pre_expiry_avg_multiplier = lockMultiplier(time_before_expiry / 2);

                // Get the weighted-average lock_multiplier
                // uint256 numerator = (pre_expiry_avg_multiplier * time_before_expiry) + (MULTIPLIER_PRECISION * time_after_expiry);
                uint256 numerator = (pre_expiry_avg_multiplier * time_before_expiry) + (0 * time_after_expiry);
                midpoint_lock_multiplier = numerator / (time_before_expiry + time_after_expiry);
            }
            else {
                // Otherwise, it needs to just be 1x
                // midpoint_lock_multiplier = MULTIPLIER_PRECISION;

                // Otherwise, it needs to just be 0x
                midpoint_lock_multiplier = 0;
            }
        }
        // If the lock is not expired
        else {
            // Decay the lock multiplier based on the time left
            uint256 avg_time_left;
            {
                uint256 time_left_p1 = thisStake.ending_timestamp - accrue_start_time;
                uint256 time_left_p2 = thisStake.ending_timestamp - block.timestamp;
                avg_time_left = (time_left_p1 + time_left_p2) / 2;
            }
            midpoint_lock_multiplier = lockMultiplier(avg_time_left);
        }

        // Sanity check: make sure it never goes above the initial multiplier
        if (midpoint_lock_multiplier > thisStake.lock_multiplier) midpoint_lock_multiplier = thisStake.lock_multiplier;
    }

    // Calculate the combined weight for an account
    function calcCurCombinedWeight(address account) public override view
        returns (
            uint256 old_combined_weight,
            uint256 new_vefxs_multiplier,
            uint256 new_combined_weight
        )
    {
        // Get the old combined weight
        old_combined_weight = _combined_weights[account];

        // Get the veFXS multipliers
        // For the calculations, use the midpoint (analogous to midpoint Riemann sum)
        new_vefxs_multiplier = veFXSMultiplier(account);

        uint256 midpoint_vefxs_multiplier;
        if (
            (_locked_liquidity[account] == 0 && _combined_weights[account] == 0) || 
            (new_vefxs_multiplier >= _vefxsMultiplierStored[account])
        ) {
            // This is only called for the first stake to make sure the veFXS multiplier is not cut in half
            // Also used if the user increased or maintained their position
            midpoint_vefxs_multiplier = new_vefxs_multiplier;
        }
        else {
            // Handles natural decay with a non-increased veFXS position
            midpoint_vefxs_multiplier = (new_vefxs_multiplier + _vefxsMultiplierStored[account]) / 2;
        }

        // Loop through the locked stakes, first by getting the liquidity * lock_multiplier portion
        new_combined_weight = 0;
        for (uint256 i = 0; i < lockedStakes[account].length; i++) {
            LockedStake memory thisStake = lockedStakes[account][i];

            // Calculate the midpoint lock multiplier
            uint256 midpoint_lock_multiplier = calcCurrLockMultiplier(account, i);

            // Calculate the combined boost
            uint256 liquidity = thisStake.liquidity;
            uint256 combined_boosted_amount = liquidity + ((liquidity * (midpoint_lock_multiplier + midpoint_vefxs_multiplier)) / MULTIPLIER_PRECISION);
            new_combined_weight += combined_boosted_amount;
        }
    }

    // ------ LOCK RELATED ------

    // All the locked stakes for a given account
    function lockedStakesOf(address account) external view returns (LockedStake[] memory) {
        return lockedStakes[account];
    }

    // Returns the length of the locked stakes for a given account
    function lockedStakesOfLength(address account) external view returns (uint256) {
        return lockedStakes[account].length;
    }

    function getStake(address staker_address, bytes32 kek_id) external view returns (uint256 arr_idx) {
        (,arr_idx) = _getStake(staker_address, kek_id);
    }

    // // All the locked stakes for a given account [old-school method]
    // function lockedStakesOfMultiArr(address account) external view returns (
    //     bytes32[] memory kek_ids,
    //     uint256[] memory start_timestamps,
    //     uint256[] memory liquidities,
    //     uint256[] memory ending_timestamps,
    //     uint256[] memory lock_multipliers
    // ) {
    //     for (uint256 i = 0; i < lockedStakes[account].length; i++){ 
    //         LockedStake memory thisStake = lockedStakes[account][i];
    //         kek_ids[i] = thisStake.kek_id;
    //         start_timestamps[i] = thisStake.start_timestamp;
    //         liquidities[i] = thisStake.liquidity;
    //         ending_timestamps[i] = thisStake.ending_timestamp;
    //         lock_multipliers[i] = thisStake.lock_multiplier;
    //     }
    // }

    /* =============== MUTATIVE FUNCTIONS =============== */

    // ------ STAKING ------

    function _getStake(address staker_address, bytes32 kek_id) internal view returns (LockedStake memory locked_stake, uint256 arr_idx) {
        console2.log("getting stake", staker_address);
        console2.logBytes32(kek_id);
        for (uint256 i; i < lockedStakes[staker_address].length; i++){ 
            console2.log("looping", i);
            if (kek_id == lockedStakes[staker_address][i].kek_id){
                console2.log("found kek_id", i);
                console2.logBytes32(lockedStakes[staker_address][i].kek_id);
                console2.logBytes32(kek_id);
                locked_stake = lockedStakes[staker_address][i];
                arr_idx = i;
                console2.logBytes32(locked_stake.kek_id);
                console2.log("The winning number is!:", arr_idx);
                break;
            } //else {
            //     console2.log("not found", i);
            //     console2.logBytes32(lockedStakes[staker_address][i].kek_id);
            //     console2.logBytes32(kek_id);
            //     revert StakerNotFound();
            // }
        }
        console2.log("before Require");
        console2.logBytes32(locked_stake.kek_id);
        require(locked_stake.kek_id == kek_id, "StakerNotFound:(");
        console2.log("require passed");
        // if (locked_stake.kek_id != kek_id) revert StakerNotFound();
    } 
        //if (locked_stake.kek_id != kek_id) revert StakerNotFound();
        
    //}

    // Add additional LPs to an existing locked stake
    function lockAdditional(bytes32 kek_id, uint256 addl_liq) nonReentrant updateRewardAndBalanceMdf(msg.sender, true) public {
        // Get the stake and its index
        (LockedStake memory thisStake, uint256 theArrayIndex) = _getStake(msg.sender, kek_id);

        // Calculate the new amount
        uint256 new_amt = thisStake.liquidity + addl_liq;

        // Checks
        if (addl_liq <= 0) revert MustBePositive();

        // Pull the tokens from the sender
        TransferHelper.safeTransferFrom(address(stakingToken), msg.sender, address(this), addl_liq);

        // Update the stake
        lockedStakes[msg.sender][theArrayIndex] = LockedStake(
            kek_id,
            thisStake.start_timestamp,
            new_amt,
            thisStake.ending_timestamp,
            thisStake.lock_multiplier
        );

        // Update liquidities
        _total_liquidity_locked += addl_liq;
        _locked_liquidity[msg.sender] += addl_liq;
        {
            address the_proxy = getProxyFor(msg.sender);
            if (the_proxy != address(0)) proxy_lp_balances[the_proxy] += addl_liq;
        }

        // Need to call to update the combined weights
        updateRewardAndBalance(msg.sender, false);

        emit LockedAdditional(msg.sender, kek_id, addl_liq);
    }

    // Extends the lock of an existing stake
    function lockLonger(bytes32 kek_id, uint256 new_ending_ts) nonReentrant updateRewardAndBalanceMdf(msg.sender, true) public {
        // Get the stake and its index
        (LockedStake memory thisStake, uint256 theArrayIndex) = _getStake(msg.sender, kek_id);

        // Check
        // require(new_ending_ts > block.timestamp, "Must be in the future");
        if (new_ending_ts <= block.timestamp) revert MustBeInTheFuture();

        // Calculate some times
        uint256 time_left = (thisStake.ending_timestamp > block.timestamp) ? thisStake.ending_timestamp - block.timestamp : 0;
        uint256 new_secs = new_ending_ts - block.timestamp;

        // Checks
        // require(time_left > 0, "Already expired");
        if (new_secs <= time_left) revert CannotShortenLockTime();
        if (new_secs < lock_time_min) revert MinimumStakeTimeNotMet();
        if (new_secs > lock_time_for_max_multiplier) revert TryingToLockForTooLong();

        // Update the stake
        lockedStakes[msg.sender][theArrayIndex] = LockedStake(
            kek_id,
            block.timestamp,
            thisStake.liquidity,
            new_ending_ts,
            lockMultiplier(new_secs)
        );

        // Need to call to update the combined weights
        updateRewardAndBalance(msg.sender, false);

        emit LockedLonger(msg.sender, kek_id, new_secs, block.timestamp, new_ending_ts);
    }

    

    // Two different stake functions are needed because of delegateCall and msg.sender issues (important for proxies)
    function stakeLocked(uint256 liquidity, uint256 secs) nonReentrant external returns (bytes32) {
        return _stakeLocked(msg.sender, msg.sender, liquidity, secs, block.timestamp);
    }

    // If this were not internal, and source_address had an infinite approve, this could be exploitable
    // (pull funds from source_address and stake for an arbitrary staker_address)
    function _stakeLocked(
        address staker_address,
        address source_address,
        uint256 liquidity,
        uint256 secs,
        uint256 start_timestamp
    ) internal updateRewardAndBalanceMdf(staker_address, true) returns (bytes32) {
        if (stakingPaused) revert StakingPaused();
        if (secs < lock_time_min) revert MinimumStakeTimeNotMet();
        if (secs > lock_time_for_max_multiplier) revert TryingToLockForTooLong();

        // Pull in the required token(s)
        // Varies per farm
        TransferHelper.safeTransferFrom(address(stakingToken), source_address, address(this), liquidity);
        // Get the lock multiplier and kek_id
        uint256 lock_multiplier = lockMultiplier(secs);

        bytes32 kek_id = _createNewKekId(staker_address, start_timestamp, liquidity, (start_timestamp + secs), lock_multiplier);

        // Update liquidities
        _total_liquidity_locked += liquidity;
        _locked_liquidity[staker_address] += liquidity;
        {
            address the_proxy = getProxyFor(staker_address);
            if (the_proxy != address(0)) proxy_lp_balances[the_proxy] += liquidity;
        }
        
        // Need to call again to make sure everything is correct
        updateRewardAndBalance(staker_address, false);

        emit StakeLocked(staker_address, liquidity, secs, kek_id, source_address);

        return kek_id;
    }

    // ------ WITHDRAWING ------

    // Two different withdrawLocked functions are needed because of delegateCall and msg.sender issues (important for proxies)
    function withdrawLocked(bytes32 kek_id, address destination_address) nonReentrant external returns (uint256) {
        if (withdrawalsPaused == true) revert WithdrawalsPaused();
        return _withdrawLocked(msg.sender, destination_address, kek_id);
    }

    // No withdrawer == msg.sender check needed since this is only internally callable and the checks are done in the wrapper
    function _withdrawLocked(
        address staker_address,
        address destination_address,
        bytes32 kek_id
    ) internal returns (uint256) {
        // Collect rewards first and then update the balances
        _getReward(staker_address, destination_address, true);

        // Get the stake and its index
        (LockedStake memory thisStake, uint256 theArrayIndex) = _getStake(staker_address, kek_id);
        // require(block.timestamp >= thisStake.ending_timestamp || stakesUnlocked == true, "Stake is still locked!");
        // the stake must still be locked to transfer
        if (block.timestamp >= thisStake.ending_timestamp || stakesUnlocked == true) {
            revert StakesUnlocked();
        }
        uint256 liquidity = thisStake.liquidity;

        if (liquidity > 0) {

            // Give the tokens to the destination_address
            // Should throw if insufficient balance
            TransferHelper.safeTransfer(address(stakingToken), destination_address, liquidity);

            // Update liquidities
            _total_liquidity_locked -= liquidity;
            _locked_liquidity[staker_address] -= liquidity;
            {
                address the_proxy = getProxyFor(staker_address);
                if (the_proxy != address(0)) proxy_lp_balances[the_proxy] -= liquidity;
            }

            // Remove the stake from the array
            delete lockedStakes[staker_address][theArrayIndex];

            // Need to call again to make sure everything is correct
            updateRewardAndBalance(staker_address, false);

            emit WithdrawLocked(staker_address, liquidity, kek_id, destination_address);
        }

        return liquidity;
    }

    function _getRewardExtraLogic(address rewardee, address destination_address) internal override {
        // Do nothing
    }

    /* ========== LOCK TRANSFER & AUTHORIZATIONS - Approvals, Functions, Errors, & Events ========== */

    // storage vars for lock transfer approvals
    // staker => kek_id => spender => uint256 (amount of lock that spender is approved for)
    mapping(address => mapping(bytes32 => mapping(address => uint256))) public kekAllowance;
    // staker => spender => bool (true if approved)
    mapping(address => mapping(address => bool)) public spenderApprovalForAllLocks;

    // use custom errors to reduce contract size
    error TransferLockNotAllowed(address spender, bytes32 kek_id);
    error StakesUnlocked();
    error InvalidReceiver();
    error InvalidAmount();
    error InsufficientAllowance();

    // custom errors for other preexisting functions to reduce contract size
    error WithdrawalsPaused();
    error StakingPaused();
    error MinimumStakeTimeNotMet();
    error TryingToLockForTooLong();
    error CannotShortenLockTime();
    error MustBeInTheFuture();
    error MustBePositive();
    error StakerNotFound();

    event TransferLocked(address indexed sender_address, address indexed destination_address, uint256 amount_transferred, bytes32 source_kek_id, bytes32 destination_kek_id);
    event Approval(address indexed staker, address indexed spender, bytes32 indexed kek_id, uint256 amount);
    event ApprovalForAll(address indexed owner, address indexed spender, bool approved);

    // Approve `spender` to transfer `kek_id` on behalf of `owner`
    function setAllowance(address spender, bytes32 kek_id, uint256 amount) external {
        kekAllowance[msg.sender][kek_id][spender] = amount;
        emit Approval(msg.sender, spender, kek_id, amount);
    }

    // Revoke approval for a single kek_id
    function removeAllowance(address spender, bytes32 kek_id) external {
        kekAllowance[msg.sender][kek_id][spender] = 0;
        emit Approval(msg.sender, spender, kek_id, 0);
    }

    // Approve or revoke `spender` to transfer any/all locks on behalf of the owner
    function setApprovalForAll(address spender, bool approved) external {
        spenderApprovalForAllLocks[msg.sender][spender] = approved; 
        emit ApprovalForAll(msg.sender, spender, approved);
    }

    // internal approval check and allowance manager
    function isApproved(address staker, bytes32 kek_id, uint256 amount) public view returns (bool) {
        // check if spender is approved for all `staker` locks
        if (spenderApprovalForAllLocks[staker][msg.sender]) {
            return true;
        } else if (kekAllowance[staker][kek_id][msg.sender] >= amount) {
            return true;
        } else {
            // for any other possibility, return false
            return false;
        }
    }

    function _spendAllowance(address staker, bytes32 kek_id, uint256 amount) internal {//returns (uint256 spendable_amount) {
            if (kekAllowance[staker][kek_id][msg.sender] == amount) {
                kekAllowance[staker][kek_id][msg.sender] = 0;
                //return amount;
            } else if (kekAllowance[staker][kek_id][msg.sender] > amount) {
                kekAllowance[staker][kek_id][msg.sender] -= amount;
                //return amount;
            // } else if (kekAllowance[staker][kek_id][msg.sender] < amount && kekAllowance[staker][kek_id][msg.sender] > 0) {
            //     spendable_amount = kekAllowance[staker][kek_id][msg.sender];
            //     kekAllowance[staker][kek_id][msg.sender] = 0;
            } else {
                revert InsufficientAllowance();
            }
    }

    ///// Transfer Locks
    /// @dev called by the spender to transfer a lock position on behalf of the staker
    /// @notice Transfer's `sender_address`'s lock with `kek_id` to `destination_address` by authorized spender
    function transferLockedFrom(
        address sender_address,
        address receiver_address,
        bytes32 source_kek_id,
        uint256 transfer_amount,
        bytes32 destination_kek_id
    ) external nonReentrant returns (bytes32, bytes32) {
        // check approvals
        if (!isApproved(sender_address, source_kek_id, transfer_amount)) revert TransferLockNotAllowed(msg.sender, source_kek_id);

        // adjust the allowance down
        _spendAllowance(sender_address, source_kek_id, transfer_amount);

        // do the transfer
        /// @dev the approval check is done in modifier, so to reach here caller is permitted, thus OK 
        //       to supply both staker & receiver here (no msg.sender)
        return(_safeTransferLocked(sender_address, receiver_address, source_kek_id, transfer_amount, destination_kek_id));
    }

    // called by the staker to transfer a lock position to another address
    /// @notice Transfer's `amount` of `sender_address`'s lock with `kek_id` to `destination_address`
    function transferLocked(
        address receiver_address,
        bytes32 source_kek_id,
        uint256 transfer_amount,
        bytes32 destination_kek_id
    ) external nonReentrant returns (bytes32, bytes32) {
        // do the transfer
        /// @dev approval/owner check not needed here as msg.sender is the staker
        return(_safeTransferLocked(msg.sender, receiver_address, source_kek_id, transfer_amount, destination_kek_id));
    }

    /**
    TODO
    @dev double check whether calling the updateRewardAndBalanceMdf would cause a transaction to revert if 
        the receiver address doesn't previously have any lockedStakes.
     */
    // executes the transfer
    function _safeTransferLocked(
        address sender_address,
        address receiver_address,
        bytes32 source_kek_id,
        uint256 transfer_amount,
        bytes32 destination_kek_id
    ) internal updateRewardAndBalanceMdf(sender_address, true) updateRewardAndBalanceMdf(receiver_address, true) returns (bytes32, bytes32) { // TODO should this also update receiver? updateRewardAndBalanceMdf(receiver_address, true)
        // on transfer, call sender_address to verify sending is ok
        if (sender_address.code.length > 0) {
            require(
                ILockTransfers(sender_address).beforeLockTransfer(sender_address, receiver_address, source_kek_id, "") 
                == 
                ILockReceiver.beforeLockTransfer.selector //0x7ebbbcb3//bytes4(keccak256("beforeLockTransfer(address,address,bytes32,bytes)"))//ILockTransfers(sender_address).beforeLockTransfer.selector // 0x4fb07105
            );
        }

        // Get the stake and its index
        //// TODO THIS IS BEING RAN
        (LockedStake memory senderStake, uint256 senderArrayIndex) = _getStake(
            sender_address,
            source_kek_id
        );

        /// TODO NOTHING BELOW HERE IS RUNNING OTHER THAN THE CONSOLE LOGS & THE ONRECEIVED & EVENT EMITTING

        // perform checks
        if (receiver_address == address(0) || receiver_address == sender_address) {
            console2.log("INVALID RECEIVER ERROR", receiver_address, sender_address);
            revert InvalidReceiver();
        }
        if (block.timestamp >= senderStake.ending_timestamp || stakesUnlocked == true) {
            console2.log("INVALID TIME ERROR", block.timestamp, senderStake.ending_timestamp, stakesUnlocked);
            revert StakesUnlocked();
        }
        if (transfer_amount > senderStake.liquidity || transfer_amount <= 0) {
            console2.log("INVALID AMOUNT ERROR", transfer_amount, senderStake.liquidity);
            revert InvalidAmount();
        }

        // Update the liquidities
        _locked_liquidity[sender_address] -= transfer_amount;
        _locked_liquidity[receiver_address] += transfer_amount;
        
            //address the_proxy = getProxyFor(sender_address);
        if (getProxyFor(sender_address) != address(0)) {
            console2.log("Staker address proxy CHECK", getProxyFor(sender_address));
                proxy_lp_balances[getProxyFor(sender_address)] -= transfer_amount;
        }
        
            //address the_proxy = getProxyFor(receiver_address);
        if (getProxyFor(receiver_address) != address(0)) {
                proxy_lp_balances[getProxyFor(receiver_address)] += transfer_amount;
        }

        // if sent amount was all the liquidity, delete the stake, otherwise decrease the balance
        console2.log("Before accounting", senderStake.liquidity, transfer_amount);
        if (transfer_amount == senderStake.liquidity) {
            console2.log("DELETE");
            delete lockedStakes[sender_address][senderArrayIndex];
        } else {
            console2.log("DEDUCT");
            lockedStakes[sender_address][senderArrayIndex].liquidity -= transfer_amount;
            console2.log("After accounting", senderStake.liquidity, transfer_amount);
        }

        // if destination kek is 0, create a new kek_id, otherwise update the balances & ending timestamp (longer of the two)
        if (destination_kek_id == bytes32(0)) {
            console2.log("CREATE NEW");
            // create the new kek_id
            console2.log("before create new kek");
            console2.logBytes32(destination_kek_id);
            destination_kek_id = _createNewKekId(receiver_address, senderStake.start_timestamp, transfer_amount, senderStake.ending_timestamp, senderStake.lock_multiplier);
            console2.log("after create new kek");
            console2.logBytes32(destination_kek_id);
            
        } else {
            console2.log("UPDATE EXISTING");
            // get the target 
            (LockedStake memory receiverStake, uint256 receiverArrayIndex) = _getStake(
                receiver_address,
                destination_kek_id
            );
            console2.log("AfterUpdateExistingDestStake", receiverStake.liquidity, receiverStake.ending_timestamp, receiverArrayIndex);
            /**
            TODO
            _getStake reverts if it doesn't find a stake of that kek_id, so checking if liquidity is 0 on it is unnecessary
            When a user withdraws their entire stake, the kek_id is deleted, so it's not possible to have a kek_id with 0 liquidity
            @dev double check me on this logic - commented out check below
             */
            // if (lockedStakes[receiver_address][receiverArrayIndex].liquidity == 0) {
            //     destination_kek_id = _createNewKekId(sender_address, thisStake.start_timestamp, transfer_amount, thisStake.ending_timestamp, thisStake.lock_multiplier);

            // } else {
            // Otherwise, it exists & has liquidity, so we can use that to keep stakes consolidated 
            // Update the existing staker's stake
            console2.log("BeforeUpdateReceiverStakeLiquidity", lockedStakes[receiver_address][receiverArrayIndex].liquidity);
            lockedStakes[receiver_address][receiverArrayIndex].liquidity += transfer_amount;
            console2.log("AfterUpdateReceiverStakeLiquidity", lockedStakes[receiver_address][receiverArrayIndex].liquidity);

            // check & update ending timestamp to whichever is farthest out
            console2.log("BeforeUpdateReceiverStakeTimestamp", receiverStake.ending_timestamp < senderStake.ending_timestamp);
            console2.log("BeforeUpdateReceiverStakeTimestamp", receiverStake.ending_timestamp, senderStake.ending_timestamp);
            if (receiverStake.ending_timestamp < senderStake.ending_timestamp) {
                console2.log("EXTEND TIMESTAMP");
                console2.log("WithinUpdateReceiverStakeTimestamp", receiverStake.ending_timestamp < senderStake.ending_timestamp);
                console2.log("WithinUpdateReceiverStakeTimestamp", receiverStake.ending_timestamp, senderStake.ending_timestamp);
                // update the lock expiration to the later timestamp
                lockedStakes[receiver_address][receiverArrayIndex].ending_timestamp = senderStake.ending_timestamp;
                // update the lock multiplier since we are effectively extending the lock
                lockedStakes[receiver_address][receiverArrayIndex].lock_multiplier = lockMultiplier(senderStake.ending_timestamp - block.timestamp);
            }
            console2.log("AfterUpdateReceiverStakeTimestamp", receiverStake.ending_timestamp < senderStake.ending_timestamp);
            console2.log("AfterUpdateReceiverStakeTimestamp", receiverStake.ending_timestamp, senderStake.ending_timestamp);
            //}
        }
        console2.log("UPDATE REWARDS AND BALANCES");
        // Need to call again to make sure everything is correct
        updateRewardAndBalance(sender_address, true); 
        updateRewardAndBalance(receiver_address, true);

        emit TransferLocked(
            sender_address,
            receiver_address,
            transfer_amount,
            source_kek_id,
            destination_kek_id
        );
        console2.log("sender, receiver", sender_address, receiver_address);
        console2.log("CALL ONLOCKRECEIVED");
        // call the receiver with the destination kek_id to verify receiving is ok
        require(_checkOnLockReceived(sender_address, receiver_address, destination_kek_id, ""));
        console2.log("sender, receiver", sender_address, receiver_address);
        // if (ILockTransfers(receiver_address).onLockReceived(
        //     sender_address, 
        //     receiver_address, 
        //     destination_kek_id, 
        //     ""
        // ) != ILockReceiver.onLockReceived.selector) revert InvalidReceiver(); //0xc42d8b95) revert InvalidReceiver();

        console2.log("Very nice, I like, great success!!!");
        return (source_kek_id, destination_kek_id);
    }

    function _createNewKekId(
        address staker_address,
        uint256 start_timestamp,
        uint256 liquidity,
        uint256 ending_timestamp,
        uint256 lock_multiplier
    ) internal returns (bytes32 kek_id) {
        console2.log("CREATE NEW KEKID");
        kek_id = keccak256(abi.encodePacked(staker_address, start_timestamp, liquidity, _locked_liquidity[staker_address]));
        console2.logBytes32(kek_id);
        // Create the locked stake
        lockedStakes[staker_address].push(LockedStake(
            kek_id,
            start_timestamp,
            liquidity,
            ending_timestamp,
            lock_multiplier
        ));
        console2.log("CREATE NEW KEKID - PUSHED");
    }

    function _checkOnLockReceived(address from, address to, bytes32 kek_id, bytes memory data)
        internal returns (bool)
    {
        console2.log("Checking onLockReceived", from, to);
        if (to.code.length > 0) {
            console2.log("receiver has code");
            try ILockTransfers(to).onLockReceived(from, to, kek_id, data) returns (bytes4 retval) {
                console2.log("trying");
                return retval == 0xc42d8b95;//bytes4(keccak256("onLockReceived(address,address,bytes32,bytes)")); //ILockTransfers(to).onLockReceived.selector;
            } catch (bytes memory reason) {
                console2.log("failed");
                if (reason.length == 0) {
                    revert InvalidReceiver();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            console2.log("receiver has no code");
            return true;
        }
    }

    /* ========== RESTRICTED FUNCTIONS - Owner or timelock only ========== */

    // Inherited...

    /* ========== EVENTS ========== */
    event LockedAdditional(address indexed user, bytes32 kek_id, uint256 amount);
    event LockedLonger(address indexed user, bytes32 kek_id, uint256 new_secs, uint256 new_start_ts, uint256 new_end_ts);
    event StakeLocked(address indexed user, uint256 amount, uint256 secs, bytes32 kek_id, address source_address);
    event WithdrawLocked(address indexed user, uint256 liquidity, bytes32 kek_id, address destination_address);
}

interface ILockTransfers {
    function beforeLockTransfer(address operator, address from, bytes32 kek_id, bytes calldata data) external returns (bytes4);
    function onLockReceived(address operator, address from, bytes32 kek_id, bytes memory data) external returns (bytes4);
}