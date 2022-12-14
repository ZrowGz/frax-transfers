// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import {FraxUnifiedFarm_ERC20} from "../src/FraxFarmERC20Transferrable.sol";
import {StakingProxyConvex as Vault} from "../src/ConvexVaultTransferrable.sol";
import {FRAXStablecoin} from "@frax/../Frax/Frax.sol";
import {IFraxFarmTransfers, IFraxFarmERC20} from "@interfaces/IFraxFarm.sol";
import "@frax_testing/gauges/Curve/IFraxGaugeController.sol";

interface IDeposits {
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function deposit(uint256 _amount) external;
    function deposit(uint256 _amount, address _to) external;
    function depositAll(uint256 poolId, bool andStake) external;
}

contract FraxFarmERC20TransfersTest is Test {
    FraxUnifiedFarm_ERC20 public frxEthFarm;
    Vault public cvxVault;

    address public alice;
    address public bob;
    
    address public frxEth = 0x5E8422345238F34275888049021821E8E08CAa1f;
    address public frxETHCRV = 0xf43211935C781D5ca1a41d2041F397B8A7366C7A; // frxeth/eth crv LP token
    address public cvxfrxEthFrxEth = address(0xC07e540DbFecCF7431EA2478Eb28A03918c1C30E);
    address public cvxStkFrxEthLp = 0x4659d5fF63A1E1EDD6D5DD9CC315e063c95947d0; // convex wrapped curve lp token STAKING TOKEN
    FraxUnifiedFarm_ERC20 public frxFarm = FraxUnifiedFarm_ERC20(0xa537d64881b84faffb9Ae43c951EEbF368b71cdA); // frxEthFraxFarm
    address public curveLpMinter = address(0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577);
    address public vaultRewardsAddress = address(0x3465B8211278505ae9C6b5ba08ECD9af951A6896);
    address public frxEthMinter = address(0xbAFA44EFE7901E04E39Dad13167D089C559c1138);
    address public convexOperator = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    address public eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // address public convexRegistry = address(0x7413bFC877B5573E29f964d572f421554d8EDF86); // not being used
    // address public convexPoolRegistry = 0x41a5881c17185383e19Df6FA4EC158a6F4851A69; // This one is being used
    // PID is 36 at convexPoolRegistry
    address public convexBooster = address(0x569f5B842B5006eC17Be02B8b94510BA8e79FbCa); // VAULT DEPLOYER
    address public convexPoolRegistry = address(0x41a5881c17185383e19Df6FA4EC158a6F4851A69); // The deployed vaults use this, not the hardcoded address

    Vault public senderVault = Vault(0x6f82cD44e8A757C0BaA7e841F4bE7506B529ce41);
    address public senderOwner = address(0x712cABaE569B54222BfB8E02A83AD98cc6D2Fb30);
    Vault public receiverVault = Vault(0x7e39FacaC567c8B48b0Ea88E7a5021391Eb848D0);
    address public receiverOwner = address(0xaf0FDd39e5D92499B0eD9F68693DA99C0ec1e92e);
    Vault public myVault;

    address public fraxToken = 0x853d955aCEf822Db058eb8505911ED77F175b99e; // FRAX
    address public fxsToken = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0); // FXS
    address public cvxToken = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
     address public distributor = 0x278dC748edA1d8eFEf1aDFB518542612b49Fcd34; // Gauge Reward Distro
    // address public vefxsToken = address(0xc8418aF6358FFddA74e09Ca9CC3Fe03Ca6aDC5b0); // veFXS
    // address public fraxAdmin = address(0xB1748C79709f4Ba2Dd82834B8c82D4a505003f27); // Frax Admin
    // address public controller = address(0x3669C421b77340B2979d1A00a792CC2ee0FcE737); // Sets Gauge Params

    // Local values
    address[] private _rewardTokens;
    address[] private _rewardManagers;
    uint256[] private _rewardRates;
    address[] private _gaugeControllers;
    address[] private _rewardDistributors;

    function setUp() public {
        // create two users
        alice = vm.addr(0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef);
        vm.deal(alice, 1e10 ether);
        //cvxStkFrxEthLp.mint(alice, 2000 ether);
        vm.label(alice, "Alice");

        bob = vm.addr(0xeeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef);
        vm.deal(bob, 1e10 ether);
        vm.label(bob, "Bob");
        // Set the rewards parameters
        _rewardManagers.push(address(this));
        _rewardManagers.push(address(this));
        _rewardRates.push(12345); // half as much fxs as pitch
        _rewardRates.push(24690); // twice as many pitch as fxs
        _rewardDistributors.push(address(distributor));
        _rewardTokens.push(address(fxsToken));
        _rewardTokens.push(address(cvxToken));


        // Give the vault owners some ETH
        vm.deal(senderOwner, 1e10 ether);
        vm.deal(receiverOwner, 1e10 ether);
        vm.deal(address(this), 1e10 ether);

        // Deploy the logic for the transferrable fraxfarm
        frxEthFarm = new FraxUnifiedFarm_ERC20(address(this), _rewardTokens, _rewardManagers, _rewardRates, _gaugeControllers, _rewardDistributors, cvxStkFrxEthLp);
        vm.etch(address(frxFarm), address(frxEthFarm).code); 
        frxEthFarm = FraxUnifiedFarm_ERC20(frxFarm);

        // Deploy the logic for the transferrable vault
        cvxVault = new Vault();
        cvxVault.initialize(address(this), address(frxFarm), cvxStkFrxEthLp, vaultRewardsAddress);//, convexPoolRegistry, 36);
        // overwrite the deployed vault code with the transferrable
        vm.etch(address(senderVault), address(cvxVault).code);
        vm.etch(address(receiverVault), address(cvxVault).code);

        // deploy our own convex vault 
        (bool success, bytes memory retBytes) = convexBooster.call(abi.encodeWithSignature("createVault(uint256)", 36)); 
        require(success, "createVault failed");
        myVault = Vault(abi.decode(retBytes, (address)));
        console2.log("MyVault", address(myVault));

    }

    // to prevent stack too deep errors, store informational values here
    struct TestState {
        bytes retval;
        uint256 retbal;
        uint256 senderPreAdd;
        uint256 senderPostAdd;
        uint256 senderPostTransfer1;
        uint256 senderPostTransfer2;
        uint256 receiverPreTransfer1;
        uint256 receiverPostTransfer1;
        uint256 receiverPostTransfer2;
        bytes32 senderKek;
        bytes32 destKek1;
        bytes32 destKek2;
    }

    function testDepositAndSendToExsitingVaults() public {
        TestState memory t;
        // check that we're using the correct vaults/staking address
        assertEq(senderVault.stakingAddress(), address(frxFarm), "invalid staking address");
        
        ///// Let the testing begin! /////
        vm.startPrank(senderOwner);

        /// obtain some frxEth
        frxEthMinter.call{value: 1000*1e18}(abi.encodeWithSignature("submit()"));
        (,t.retval) = frxEth.call(abi.encodeWithSignature("balanceOf(address)", senderOwner));
        t.retbal = abi.decode(t.retval, (uint256));
        assertEq(t.retbal, 1000 ether, "invalid mint amount frxETH");
        console2.log("frxEth balance", t.retbal);

        /// deposit it as LP into the curve pool
        IDeposits(address(frxEth)).approve(curveLpMinter, type(uint256).max);
        IDeposits(curveLpMinter).add_liquidity([uint256(0), uint256(1000 ether)], 990 ether);
        t.retbal = IDeposits(frxETHCRV).balanceOf(senderOwner);
        console2.log("frxETHCRV balance", t.retbal);
        assertGt(t.retbal, 990 ether, "invalid minimum mint amount frxETHCRV");

        /// Since the `etch` completely overwrites the existing contract storage, pull these values to double check at each step
        t.senderPreAdd = frxFarm.lockedStakesOfLength(address(senderVault));
        console2.log("pre-add # locks", t.senderPreAdd);

        /// create a known kekId
        t.senderKek = senderVault.stakeLockedCurveLp(990 ether, (60*60*24*300));
        console2.log("lockKek");
        console2.logBytes32(t.senderKek);
        t.senderPostAdd = frxFarm.lockedStakesOfLength(address(senderVault));
        console2.log("post-add # locks", t.senderPostAdd);
        assertEq(t.senderPostAdd, t.senderPreAdd + 1, "invalid # of locks");

        ///// transfer the lockKek to receiverVault /////
        skip(1 days);

        /// get receiver's pre-transfer number of locks
        t.receiverPreTransfer1 = frxFarm.lockedStakesOfLength(address(receiverVault));
        console2.log("PreTransfer1 RE # locks", t.receiverPreTransfer1);

        ///// transfer the lockKek to receiverVault /////
        /// TODO might need to overwrite their address to have onReceived & onTransferred 
        (, t.destKek1) = senderVault.transferLocked(address(receiverVault), t.senderKek, 10 ether, bytes32(0));
        
        /// Double check that this stake exists now
        t.senderPostTransfer1 = frxFarm.lockedStakesOfLength(address(senderVault));
        console2.log("PostTransfer1SE # locks", t.senderPostTransfer1);
        assertEq(t.senderPostTransfer1, t.senderPostAdd, "sender should have same # locks");        
        t.receiverPostTransfer1 = frxFarm.lockedStakesOfLength(address(receiverVault));
        console2.log("PostTransfer1RE # locks", t.receiverPostTransfer1);
        assertEq(t.receiverPostTransfer1, (t.receiverPreTransfer1 + 1), "receiver should have 1 more lock");
        
        /** TODO TODO TODO
        * All the logic between the first `getStake` and the update balances plus the event emit are not happening. 
        */


        //// NOTE: Commented out until able to get receiver locked stake to update.
        // ///// Try sending to a kekId (69420) that receiver doesn't have - SHOULD FAIL /////
        // vm.expectRevert();
        // senderVault.transferLocked(address(receiverVault), t.senderKek, 10 ether, 0x0000000000000000000000000000000000000000000000000000000000010f2c);

        // ///// Send more to same kek_id /////
        // skip(1 days);
        // /// TODO Commented out due to stack too deep with all the placeholders above while troubleshooting.
        // /// transfer to a specific receiver lockKek (the same as was created last time)
        // assertEq(frxFarm.lockedStakesOfLength(address(receiverVault)), t.receiverPostTransfer1, "receiver should still have same number locks");
        // assertEq(frxFarm.lockedStakesOfLength(address(senderVault)), t.senderPostTransfer1, "sender should still have same number locks");

        // //// transfer to the previous added kekId
        // (, t.destKek2) = senderVault.transferLocked(address(receiverVault), t.senderKek, 10 ether, t.destKek1);

        // //// check that the number of locks for both sender & receiver are unchanged
        // console2.log("Both kekIds");
        // console2.logBytes32(t.destKek1);
        // console2.logBytes32(t.destKek2);
        // assertEq(t.destKek1, t.destKek2, "failed to send to same kekId");
        // t.receiverPostTransfer2 = frxFarm.lockedStakesOfLength(address(receiverVault));
        // console2.log("PostTransfer1RE # locks", t.receiverPostTransfer2);
        // assertEq(t.receiverPostTransfer2, t.receiverPreTransfer1, "receiver should have same num locks");

        vm.stopPrank();    
    }

    // /// TODO To be used for next test
    // function testDepositAndSendToUnusedVault() public {
        // vm.startPrank(senderOwner);
        // frxEthMinter.call{value: 1000*1e18}(abi.encodeWithSignature("submit()"));
        // (,bytes memory retval) = frxEth.call(abi.encodeWithSignature("balanceOf(address)", senderOwner));
        // uint256 retbal = abi.decode(retval, (uint256));
        // assertEq(retbal, 1000 ether, "invalid mint amount frxETH");
        // console2.log("frxEth balance", retbal);
        // // deposit it as LP into the curve pool
        // IDeposits(address(frxEth)).approve(curveLpMinter, type(uint256).max);
        // IDeposits(curveLpMinter).add_liquidity([uint256(0), uint256(1000 ether)], 990 ether);
        // retbal = IDeposits(frxETHCRV).balanceOf(senderOwner);
        // console2.log("frxETHCRV balance", retbal);
        // assertGt(retbal, 990 ether, "invalid minimum mint amount frxETHCRV");
        // // create a known kekId
        // bytes32 lockKek = senderVault.stakeLockedCurveLp(990 ether, (60*60*24*300));
        // console2.log("lockKek");
        // console2.logBytes32(lockKek);

        // skip(30 days);
        // vm.expectRevert();
        // senderVault.transferLocked(address(myVault), lockKek, 10 ether, 0x0000000000000000000000000000000000000000000000000000000000010f2c);

        // // transfer the lockKek to receiverVault
        // (,bytes32 destKek1) = senderVault.transferLocked(address(myVault), lockKek, 10 ether, bytes32(0));

        // vm.stopPrank();    
    // }
}
