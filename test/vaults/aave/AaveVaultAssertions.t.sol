// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../VaultAssertions.t.sol";

/**
 * @title IAaveToken
 * @notice Interface for Aave token specific functions
 */
interface IAaveToken {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function scaledBalanceOf(address user) external view returns (uint256);
    function getScaledUserBalanceAndSupply(
        address user
    ) external view returns (uint256, uint256);
}

/**
 * @title IAaveLendingPool
 * @notice Interface for Aave lending pool functions
 */
interface IAaveLendingPool {
    function getReserveNormalizedIncome(
        address asset
    ) external view returns (uint256);
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

/**
 * @title AaveVaultAssertions
 * @notice Custom assertions for Aave vault testing
 */
contract AaveVaultAssertions is VaultAssertions {
    IAaveToken public aaveToken;
    IAaveLendingPool public lendingPool;
    address constant LENDING_POOL_ADDRESS =
        0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    /**
     * @notice Constructor for AaveVaultAssertions
     * @param _vaultAddress Address of the Aave vault
     * @param _forkBlock Block number to fork from
     */
    constructor(
        address _vaultAddress,
        uint256 _forkBlock
    ) VaultAssertions(_vaultAddress, _forkBlock) {
        aaveToken = IAaveToken(_vaultAddress);
        lendingPool = IAaveLendingPool(LENDING_POOL_ADDRESS);

        address underlyingAsset = aaveToken.UNDERLYING_ASSET_ADDRESS();
        setAsset(underlyingAsset);
    }

    /**
     * @notice Assert that total assets match expected value
     */

    function assertTotalAssetsMatchExpected() public view override {
        uint256 normalizedIncome = lendingPool.getReserveNormalizedIncome(
            address(asset)
        );
        (, uint256 scaledTotalSupply) = aaveToken.getScaledUserBalanceAndSupply(
            address(aaveToken)
        );
        uint256 expectedTotalAssets = (scaledTotalSupply * normalizedIncome) /
            1e27;
        uint256 actualTotalAssets = aaveToken.totalSupply();

        assertApproxEqRel(
            actualTotalAssets,
            expectedTotalAssets,
            0.01e18,
            "Total assets should approximately match expected assets based on scaled total supply and normalized income"
        );
    }

    /**
     * @notice Assert deposit-withdraw round trip returns close to initial balance
     * @param amount Amount to deposit and withdraw
     */
    function assertDepositWithdrawRoundTrip(uint256 amount) public override {
        address user = address(0x1111);
        deal(address(asset), user, amount);

        vm.startPrank(user);
        asset.approve(address(lendingPool), amount);

        uint256 initialBalance = asset.balanceOf(user);
        uint256 initialShares = aaveToken.balanceOf(user);

        lendingPool.deposit(address(asset), amount, user, 0);
        uint256 sharesAfterDeposit = aaveToken.balanceOf(user);

        lendingPool.withdraw(
            address(asset),
            sharesAfterDeposit - initialShares,
            user
        );
        uint256 finalBalance = asset.balanceOf(user);

        vm.stopPrank();

        assertApproxEqRel(
            finalBalance,
            initialBalance,
            0.01e18,
            "Deposit-withdraw round trip should return close to initial balance"
        );
    }

    /**
     * @notice Assert that share price never decreases
     */
    function assertSharePriceNeverDecreases() public override {
        uint256 oldNormalizedIncome = lendingPool.getReserveNormalizedIncome(
            address(asset)
        );

        vm.roll(block.number + 1000);
        vm.warp(block.timestamp + 1 weeks);

        uint256 newNormalizedIncome = lendingPool.getReserveNormalizedIncome(
            address(asset)
        );
        assertGe(
            newNormalizedIncome,
            oldNormalizedIncome,
            "Normalized income should never decrease"
        );
    }

    /**
     * @notice Assert that no significant arbitrage opportunities exist
     */
    function assertNoArbitrage() public view override {
        uint256 amount = 1e18; // 1 token
        uint256 normalizedIncome = lendingPool.getReserveNormalizedIncome(
            address(asset)
        );
        uint256 shares = (amount * 1e27) / normalizedIncome;
        uint256 assets = (shares * normalizedIncome) / 1e27;
        assertApproxEqRel(
            assets,
            amount,
            0.0001e18,
            "No significant arbitrage opportunity should exist between shares and assets"
        );
    }
}
