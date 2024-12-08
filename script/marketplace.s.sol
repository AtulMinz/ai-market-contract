// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {ModelListingContract} from "../src/marketplace.sol";
import {MarketplaceContract} from "../src/marketplace.sol";
import {ContributionContract} from "../src/marketplace.sol";
import {AccessControlContract} from "../src/marketplace.sol";

contract DeployMarketplace is Script {
    function run() external returns (
        ModelListingContract modelListing,
        MarketplaceContract marketplace,
        ContributionContract contribution,
        AccessControlContract accessControl
    ) {
        vm.startBroadcast();

        // Deploy the ModelListingContract
        modelListing = new ModelListingContract();

        // Deploy the MarketplaceContract and link it to the ModelListingContract
        marketplace = new MarketplaceContract(address(modelListing));

        // Deploy the ContributionContract
        contribution = new ContributionContract();

        // Deploy the AccessControlContract
        accessControl = new AccessControlContract();

        vm.stopBroadcast();

        // Return all deployed contract instances
        return (modelListing, marketplace, contribution, accessControl);
    }
}