// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // replace the ERC721 to use _setTokenURI function
import "@openzeppelin/contracts/access/Ownable.sol";

/* ____________ Errors ____________*/

error RandomIpfsNFT__OutOfRange();
error RandomIpfsNFT__MintFee_sendMoreETH();
error RandomIpfsNFT__TransactionFailed();
error RandomIpfsNft__AlreadyInitialized();

/**
 * @title RandomIpfsNFT
 * @author mehrdadr01 at github
 * @dev creating a random IPFS NFT contract using chain link && open zeppelin
 * genrate a random number then use it to create a random nft
 * we give rarity functionality to our dogs
 * and user s have to pay a fee to mint a NFT and owner can withdraw the ETH after
 */
contract RandomIpfsNFT is VRFConsumerBaseV2, ERC721URIStorage, Ownable {
    /*____________ Type Declaration ____________*/

    enum Breed {
        PUG,
        SHIBA_INU,
        GAMAL
    }

    /*____________ NFT variables ____________*/
    uint256 private s_tokenCounterId;
    uint256 private constant MAX_CHANCE_VALUE = 100;
    string[] internal s_dogTokenURIs; // a list of URI for any dog type we have (we could hardcoded but param way is better )
    uint256 private immutable i_mintFee;
    bool private s_initialized;

    /*____________ VRF variables ____________*/
    VRFCoordinatorV2Interface private immutable i_VRFCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFORMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    /*____________ VRF helper ____________*/
    mapping(uint256 => address) private requestIdToOwner;

    /* ____________ Events ____________*/
    event nftRequested(uint256 indexed _requestId, address _requester);
    event nftMinted(Breed _degBreed, address _minter);

    constructor(
        address _VRFCoordinator,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        string[3] memory _dogTokenURIs,
        uint256 _mintFee
    ) VRFConsumerBaseV2(_VRFCoordinator) ERC721("randomIpfsNft", "RIN") {
        i_VRFCoordinator = VRFCoordinatorV2Interface(_VRFCoordinator);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_dogTokenURIs = _dogTokenURIs;
        i_mintFee = _mintFee;
        _initializeContract(_dogTokenURIs);
    }

    /*____________ Functions ____________*/

    function requestNft() public payable returns (uint256 requestId) {
        if (msg.value < i_mintFee) {
            revert RandomIpfsNFT__MintFee_sendMoreETH();
        }
        requestId = i_VRFCoordinator.requestRandomWords( // from vrfcoordinatorV2
            i_gasLane, //
            i_subscriptionId,
            REQUEST_CONFORMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        requestIdToOwner[requestId] = msg.sender;
        emit nftRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(
        //from VRFConsumerBaseV2
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        address nftOwner = requestIdToOwner[requestId];
        uint256 newTokenId = s_tokenCounterId;
        uint256 moddedRNG = randomWords[0] % MAX_CHANCE_VALUE;
        Breed dogBreed = getBreedFromModdedRNG(moddedRNG);
        s_tokenCounterId += s_tokenCounterId;
        _safeMint(nftOwner, newTokenId);
        _setTokenURI(newTokenId, s_dogTokenURIs[uint256(dogBreed)]);
        // emit an event
        emit nftMinted(dogBreed, nftOwner);
    }

    function getChanceArray() public pure returns (uint256[3] memory) {
        return [10, 30, MAX_CHANCE_VALUE];
    }

    function _initializeContract(string[3] memory dogTokenUris) private {
        if (s_initialized) {
            revert RandomIpfsNft__AlreadyInitialized();
        }
        s_dogTokenURIs = dogTokenUris;
        s_initialized = true;
    }

    function getBreedFromModdedRNG(
        uint256 _moddedRNG
    ) public pure returns (Breed dogBreed) {
        uint256 accumSum = 0;
        uint256[3] memory chanceArray = getChanceArray();
        for (uint16 i = 0; i < chanceArray.length; i++) {
            if (
                _moddedRNG > accumSum && _moddedRNG < accumSum + chanceArray[i]
            ) {
                return Breed(i);
            }
            accumSum += chanceArray[i];
        }
        revert RandomIpfsNFT__OutOfRange();
    }

    function withdraw() public payable onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert RandomIpfsNFT__TransactionFailed();
        }
    }

    /* ____________ Getter functions ____________ */
    function get_tokenCounterId() public view returns (uint256) {
        return s_tokenCounterId;
    }

    function get_requestIdToOwner(
        uint256 _reqId
    ) public view returns (address) {
        return requestIdToOwner[_reqId];
    }

    function get_mintFee() public view returns (uint256) {
        return i_mintFee;
    }

    function get_dogTokenURIs(
        uint256 _index
    ) public view returns (string memory) {
        return s_dogTokenURIs[_index];
    }

    function get_initialized() public view returns (bool) {
        return s_initialized;
    }
}
