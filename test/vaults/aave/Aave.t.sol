// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AaveVaultAssertions.t.sol";

/**
 * @title AaveTest
 * @notice Test contract for Aave vault assertions
 */
contract AaveTest is AaveVaultAssertions {
    /**
     * @notice Constructor for AaveTest
     * @dev Initializes the test contract with Aave USDC aToken address and a specific fork block
     */
    constructor()
        AaveVaultAssertions(
            address(0xBcca60bB61934080951369a648Fb03DF4F96263C), // Aave USDC aToken address
            17_853_400 // Fork block number
        )
    {}

    /**
     * @notice Set up function for each test
     * @dev Logs key information about the Aave vault state
     */
    function setUp() public view {
        uint256 totalSupply = aaveToken.totalSupply();
        address underlyingAsset = aaveToken.UNDERLYING_ASSET_ADDRESS();
        uint256 normalizedIncome = lendingPool.getReserveNormalizedIncome(
            address(asset)
        );

        if (
            totalSupply == 0 ||
            underlyingAsset == address(0) ||
            normalizedIncome == 0
        ) {
            console.log("Warning: Unexpected initial state");
            console.log("Total Supply:", totalSupply);
            console.log("Underlying Asset:", underlyingAsset);
            console.log("Normalized Income:", normalizedIncome);
        }
    }

    /**
     * @notice Test to verify if total assets match expected value
     */
    function testTotalAssetsMatchExpected() public view {
        assertTotalAssetsMatchExpected();
    }

    /**
     * @notice Test to verify if share price never decreases
     */
    function testSharePriceNeverDecreases() public {
        assertSharePriceNeverDecreases();
    }

    /**
     * @notice Test to verify deposit and withdraw round trip
     */
    function testDepositWithdrawRoundTrip() public {
        assertDepositWithdrawRoundTrip(1000000); // 1 USDC (6 decimals)
    }

    /**
     * @notice Test to verify no arbitrage opportunities exist
     */
    function testNoArbitrage() public view {
        assertNoArbitrage();
    }
}
