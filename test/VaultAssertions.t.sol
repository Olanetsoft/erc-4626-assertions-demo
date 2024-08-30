// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IGenericVault
 * @notice Interface for interacting with ERC4626-compliant vaults
 */
interface IGenericVault {
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function asset() external view returns (address);
    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);
}

/**
 * @title VaultAssertions
 * @notice A contract for testing ERC4626-compliant vaults using Forge
 */
contract VaultAssertions is Test {
    address public vaultAddress;
    IERC20 public asset;
    uint256 public forkBlock;

    constructor(address _vaultAddress, uint256 _forkBlock) {
        vaultAddress = _vaultAddress;
        forkBlock = _forkBlock;
        vm.createSelectFork(vm.rpcUrl("mainnet"), forkBlock);
    }

    /**
     * @notice Set the asset for the vault
     * @param _assetAddress The address of the asset token
     */
    function setAsset(address _assetAddress) internal {
        asset = IERC20(_assetAddress);
    }

    /**
     * @notice Assert that the total assets match the expected value
     */
    function assertTotalAssetsMatchExpected() public virtual {
        IGenericVault vault = IGenericVault(vaultAddress);
        uint256 reportedTotalAssets = vault.totalAssets();
        uint256 actualBalance = asset.balanceOf(vaultAddress);
        assertApproxEqRel(
            reportedTotalAssets,
            actualBalance,
            0.01e18,
            "Total assets should approximately match actual balance"
        );
    }

    /**
     * @notice Assert that the share price never decreases
     * @dev This function should be implemented by specific vault types
     */
    function assertSharePriceNeverDecreases() public virtual {
        revert("Not implemented");
    }

    /**
     * @notice Assert that a deposit-withdraw round trip returns close to the initial balance
     * @param amount The amount to deposit and withdraw
     */
    function assertDepositWithdrawRoundTrip(uint256 amount) public virtual {
        IGenericVault vault = IGenericVault(vaultAddress);
        address user = address(0x1111);
        deal(address(asset), user, amount);

        vm.startPrank(user);
        asset.approve(vaultAddress, amount);
        uint256 initialBalance = asset.balanceOf(user);
        vault.deposit(amount, user);
        vault.withdraw(amount, user, user);
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
     * @notice Assert that there are no arbitrage opportunities
     * @dev This function should be implemented by specific vault types
     */
    function assertNoArbitrage() public virtual {
        revert("Not implemented");
    }
}
