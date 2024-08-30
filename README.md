# ERC-4626 Assertions Demo

This repository contains a set of assertions designed to monitor and validate the behavior of ERC-4626 compliant vaults. These assertions are implemented as Forge fork tests and can be used by the Phylax Monitor to observe the live state of vault-based protocols.


The assertions in this repo are designed to catch potential hacks or inconsistencies in a vault's state that may violate the business logic, even if they are technically protocol-compliant. While the primary implementation is based on the [Aave protocol](https://github.com/aave/Aave-Vault/tree/main), the structure is adaptable to other ERC-4626 compliant vaults.

## Assertions

1. **Total Assets Match Expected**: Ensures the reported total assets match the expected value based on the protocol's internal accounting.
2. **Share Price Never Decreases**: Verifies that the share price (or equivalent metric) never decreases over time, protecting against value extraction attacks.
3. **Deposit-Withdraw Round Trip**: Checks that users can deposit and withdraw funds without unexpected losses.
4. **No Arbitrage Opportunities**: Ensures there are no significant arbitrage opportunities between shares and underlying assets.

## Prerequisite
Install Foundry: https://book.getfoundry.sh/getting-started/installation

## Setup and Execution

1. Clone this repository.

```bash
git clone https://github.com/Olanetsoft/erc-4626-assertions-demo.git
cd erc-4626-assertions-demo
```

2. Install dependencies
   ```bash
   forge install OpenZeppelin/openzeppelin-contracts
   ```
3. Run the tests:
   ```bash
   forge test -vv
   ```

## Rationale for Assertions

1. **Total Assets Match Expected**: Ensures correct reporting of holdings, detecting unauthorized withdrawals or accounting errors.
2. **Share Price Never Decreases**: Protects against value extraction attacks and errors in share price calculation.
3. **Deposit-Withdraw Round Trip**: Verifies reliable deposit and withdrawal functionality, catching potential exploits in these critical operations.
4. **No Arbitrage**: Prevents slow draining of the vault through precision or rounding exploits.

## Implementation Example (Aave-specific)

```solidity
function assertTotalAssetsMatchExpected() public view override {
    uint256 totalSupply = aaveToken.totalSupply();
    uint256 normalizedIncome = lendingPool.getReserveNormalizedIncome(address(asset));
    (uint256 scaledBalance, uint256 scaledTotalSupply) = aaveToken.getScaledUserBalanceAndSupply(address(aaveToken));
    uint256 expectedTotalAssets = (scaledTotalSupply * normalizedIncome) / 1e27;
    uint256 actualTotalAssets = aaveToken.totalSupply();
    assertApproxEqRel(actualTotalAssets, expectedTotalAssets, 0.01e18, "Total assets should approximately match expected assets");
}
```

## Adapting for Other Vaults

To adapt these assertions for other ERC-4626 compliant vaults:

1. Replace protocol-specific function calls with equivalent functions in the target protocol.
2. Adjust calculations based on the protocol's implementation of share price and total assets.
3. Modify the interface used to interact with the vault.

## Challenges and Considerations

1. **Protocol-Specific Implementations**: Different protocols may calculate share prices or handle deposits/withdrawals uniquely.
2. **Precision and Rounding**: Account for different decimal precisions to avoid false positives.
3. **State Changes**: Ensure state changes in assertions don't interfere with other tests or monitoring processes.

## Generalizability

These assertions are designed to work with any ERC-4626 compliant vault, including but not limited to:

1. Compound v3
2. Maple Finance
3. Yearn Finance
4. Frax Finance
5. Idle Finance Yield vaults

## Using with Phylax Monitor

To use these assertions with Phylax Monitor:

- Integrate the assertion contracts into your Phylax Monitor setup.
- Configure the monitor to run these tests at regular intervals or after specific blockchain events.
- Set up alerting based on the test results, e.g., send notifications when any assertion fails.
