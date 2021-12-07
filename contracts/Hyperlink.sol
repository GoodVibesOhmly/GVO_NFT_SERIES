// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";



contract Hyperlink is Initializable, ReentrancyGuardUpgradeable, ERC721Upgradeable {
    // ========= USING DECLARATIONS =========
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address payable;

    uint256 internal constant BASIS_POINTS = 10000; // denominator for calculating percentages


    // ============== VARIABLES ==============

    // METADATA
    string internal tokenMetadata;
    string internal contractMetadata;

    // MONETARY
    address payable internal primaryRecipient;
    uint256 internal quantityForSale;
    uint256 internal salePrice;

    address payable internal platform;
    uint256 internal platformFeeBasisPoints; // IN ETH (not a percentage)

    // HYPERLINK
    address internal hyperlink;

    // SALES STATE
    uint256 internal numberSold;



    // ============= INITIALIZER =============
    function initialize(
        string calldata _tokenMetadata,
        string calldata _contractMetadata,
        address payable _primaryRecipient,
        uint256 _quantityForSale,
        uint256 _salePrice,
        address payable _platform,
        uint256 _platformFeeBasisPoints,
        address _hyperlink
    ) initializer external {
        __ERC721_init("Hyperlink", "HYPERLINK");
        tokenMetadata = _tokenMetadata;
        contractMetadata = _contractMetadata;

        primaryRecipient = _primaryRecipient;
        quantityForSale = _quantityForSale;
        salePrice = _salePrice;

        platform = _platform;
        platformFeeBasisPoints = _platformFeeBasisPoints;

        hyperlink = _hyperlink;
    }

    // ============ CORE FUNCTIONS ============
    function mint() public payable {
        // Check that there are still tokens available to purchase.
        require(
            numberSold < quantityForSale,
            "Hyperlink: all editions have already been sold"
        );
        // Check that the sender is paying the correct amount.
        require(
            msg.value == salePrice,
            "Hyperlink: must send enough to purchase the edition"
        );

        if (hyperlink != address(0)) {
            require(
                IERC721Upgradeable(hyperlink).balanceOf(msg.sender) > 0,
                "Hyperlink: must own the linked edition to mint"
            );
        }


        numberSold++; // first edition starts at index 1 (more humanly understood)
        _mint(msg.sender, numberSold);
    }

    function withdraw() public nonReentrant {
        uint256 contractBalance = address(this).balance;

        require(
            contractBalance > 0,
            "Hyperlink: contract balance must be greater than zero"
        );

        uint256 platformFee = contractBalance.mul(platformFeeBasisPoints) / BASIS_POINTS;
        primaryRecipient.sendValue(contractBalance.sub(platformFee)); // the rest goes to the fund recipient 
        if (platformFee > 0) {
            platform.sendValue(platformFee);
        }
    }

    

    // ============ URI FUNCTIONS ============

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(ownerOf(_tokenId) != address(0), "Hyperlink: token has not been sold or does not exist");
        return tokenMetadata;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadata;
    }

    function editionURI() public view returns (string memory) {
        return tokenMetadata;
    }

    function getHyperlink() public view returns (address) {
        return hyperlink;
    }

    // receive any royalties 

    receive() external payable {}

    fallback() external payable {}

}
