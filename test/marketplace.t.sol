// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ModelListingContract.sol";
import "../src/MarketplaceContract.sol";
import "../src/ContributionContract.sol";
import "../src/AccessControlContract.sol";

contract AITest is Test {
    ModelListingContract private modelListing;
    MarketplaceContract private marketplace;
    ContributionContract private contribution;
    AccessControlContract private accessControl;

    address private developer = address(1);
    address private user = address(2);
    address private otherUser = address(3);

    function setUp() public {
        vm.deal(developer, 10 ether);
        vm.deal(user, 5 ether);
        vm.deal(otherUser, 5 ether);

        modelListing = new ModelListingContract();
        marketplace = new MarketplaceContract(address(modelListing));
        contribution = new ContributionContract();
        accessControl = new AccessControlContract();
    }

    function testListModel() public {
        vm.prank(developer);
        modelListing.listModel("Model1", "Description1", "http://media1.com", 1 ether);

        (uint256 id, string memory name, , , address dev, uint256 price) = modelListing.getModel(0);
        
        assertEq(id, 0);
        assertEq(name, "Model1");
        assertEq(dev, developer);
        assertEq(price, 1 ether);
    }

    function testAccessModel() public {
        vm.prank(developer);
        modelListing.listModel("Model1", "Description1", "http://media1.com", 1 ether);

        vm.prank(user);
        vm.deal(user, 2 ether);
        marketplace.accessModel{value: 1 ether}(0);

        assertEq(developer.balance, 11 ether);
        assertEq(user.balance, 4 ether);
    }

    function testContribute() public {
        vm.prank(user);
        contribution.contribute{value: 1 ether}(developer);

        assertEq(contribution.developerBalances(developer), 1 ether);
    }

    function testWithdraw() public {
        vm.prank(user);
        contribution.contribute{value: 1 ether}(developer);

        vm.prank(developer);
        contribution.withdraw();

        assertEq(developer.balance, 11 ether);
        assertEq(contribution.developerBalances(developer), 0);
    }

    function testGrantAccess() public {
        vm.prank(developer);
        accessControl.grantAccess(0, user, 3600);

        (bool granted, uint256 expiry) = accessControl.accessPermissions(0, user);
        assertEq(granted, true);
        assertTrue(block.timestamp <= expiry);
    }

    function testCheckAccess() public {
        vm.prank(developer);
        accessControl.grantAccess(0, user, 3600);

        bool hasAccess = accessControl.checkAccess(0, user);
        assertTrue(hasAccess);

        vm.warp(block.timestamp + 3601);

        hasAccess = accessControl.checkAccess(0, user);
        assertFalse(hasAccess);
    }
}
