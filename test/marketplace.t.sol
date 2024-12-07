// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ModelListingContract
 * @notice Stores information about AI models listed on the marketplace.
 */
contract ModelListingContract {
    struct Model {
        uint256 id;
        string name;
        string description;
        string mediaLink; // Link to video/photo demo
        address payable developer;
        uint256 price; // Price for accessing the model
    }

    mapping(uint256 => Model) public models;
    uint256 public nextModelId;

    event ModelListed(uint256 id, string name, address developer, uint256 price);

    function listModel(
        string calldata name,
        string calldata description,
        string calldata mediaLink,
        uint256 price
    ) external {
        require(price > 0, "Price must be greater than zero");
        
        models[nextModelId] = Model({
            id: nextModelId,
            name: name,
            description: description,
            mediaLink: mediaLink,
            developer: payable(msg.sender),
            price: price
        });

        emit ModelListed(nextModelId, name, msg.sender, price);
        nextModelId++;
    }

    function getModel(uint256 modelId)
        external
        view
        returns (
            uint256 id,
            string memory name,
            string memory description,
            string memory mediaLink,
            address payable developer,
            uint256 price
        )
    {
        Model memory model = models[modelId];
        return (
            model.id,
            model.name,
            model.description,
            model.mediaLink,
            model.developer,
            model.price
        );
    }
}

/**
 * @title MarketplaceContract
 * @notice Manages payments for accessing AI models.
 */
contract MarketplaceContract {
    ModelListingContract public listingContract;

    event ModelAccessed(uint256 modelId, address buyer, uint256 price);

    constructor(address listingContractAddress) {
        listingContract = ModelListingContract(listingContractAddress);
    }

    function accessModel(uint256 modelId) external payable {
        (
            ,
            ,
            ,
            ,
            address payable developer,
            uint256 price
        ) = listingContract.getModel(modelId);

        require(msg.value == price, "Incorrect payment amount");

        developer.transfer(msg.value);

        emit ModelAccessed(modelId, msg.sender, price);
    }
}

/**
 * @title ContributionContract
 * @notice Allows users to contribute tokens to developers.
 */
contract ContributionContract {
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public developerBalances;

    event ContributionMade(address contributor, address developer, uint256 amount);
    event Withdrawal(address developer, uint256 amount);

    function contribute(address developer) external payable {
        require(msg.value > 0, "Contribution must be greater than zero");
        
        contributions[msg.sender] += msg.value;
        developerBalances[developer] += msg.value;

        emit ContributionMade(msg.sender, developer, msg.value);
    }

    function withdraw() external {
        uint256 balance = developerBalances[msg.sender];
        require(balance > 0, "No funds to withdraw");

        developerBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);

        emit Withdrawal(msg.sender, balance);
    }
}

/**
 * @title AccessControlContract
 * @notice Manages access permissions for AI models after payment.
 */
contract AccessControlContract {
    struct Access {
        bool granted;
        uint256 expiry;
    }

    mapping(uint256 => mapping(address => Access)) public accessPermissions;

    event AccessGranted(uint256 modelId, address user, uint256 expiry);

    function grantAccess(uint256 modelId, address user, uint256 duration) external {
        require(duration > 0, "Duration must be greater than zero");

        accessPermissions[modelId][user] = Access({
            granted: true,
            expiry: block.timestamp + duration
        });

        emit AccessGranted(modelId, user, block.timestamp + duration);
    }

    function checkAccess(uint256 modelId, address user) external view returns (bool) {
        Access memory access = accessPermissions[modelId][user];
        return access.granted && block.timestamp <= access.expiry;
    }
}
