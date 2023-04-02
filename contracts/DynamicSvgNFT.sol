// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "base64-sol/base64.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";

/////////////// errors ///////////////

error ERC721Metadata__URI_QueryFor_NonExistentToken();

contract DynamicSvgNFT is ERC721 {
    /* Vars */
    uint256 private s_tokenCounter;
    string private s_btcImageURI;
    string private s_ethImageURI;

    mapping(uint256 => int256) private s_tokenIdToHighValue;
    AggregatorV3Interface internal immutable i_priceFeed;

    /* Events*/
    event CteateNFT(uint256 indexed _tokenId, int256 indexed _highValue);

    constructor(
        address _priceFeddAdd,
        string memory _btcSvg,
        string memory _ethSvg
    ) ERC721("DynamicSvgNFT", "DSN") {
        s_tokenCounter = 0;
        i_priceFeed = AggregatorV3Interface(_priceFeddAdd);
        s_btcImageURI = svgToImageURI(_btcSvg);
        s_ethImageURI = svgToImageURI(_ethSvg);
    }

    /////////////////* Functions *//////////////////////

    function mintNft(int256 _highValue) public {
        s_tokenIdToHighValue[s_tokenCounter] = _highValue;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    function svgToImageURI(
        string memory _svg
    ) public pure returns (string memory) {
        string memory base64EncodedSvgPrefix = "data:image/svg+xml;base64";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(_svg)))
        );
        return (
            string(abi.encodePacked(base64EncodedSvgPrefix, svgBase64Encoded))
        );
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert ERC721Metadata__URI_QueryFor_NonExistentToken();
        }
        (, int256 price, , , ) = i_priceFeed.latestRoundData();
        string memory imageURI = s_btcImageURI;
        if (price >= s_tokenIdToHighValue[_tokenId]) {
            imageURI = s_ethImageURI;
        }

        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(), // You can add whatever name here
                                '", "description":"An NFT that changes based on the Chainlink Feed", ',
                                '"attributes": [{"trait_type": "coolness", "value": 100}], "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    ////////////////////* Geeter Dunctions *//////////////////////////

    function get_btcSvg() public view returns (string memory) {
        return s_btcImageURI;
    }

    function get_ethSvg() public view returns (string memory) {
        return s_ethImageURI;
    }

    function get_tokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function get_priceFeed() public view returns (AggregatorV3Interface) {
        return i_priceFeed;
    }
}
