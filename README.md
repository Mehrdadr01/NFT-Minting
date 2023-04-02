# NFT 

## simple NFT

- inherit from open zeppelin ERC721 contract 
```
1. constructor 
    - just a pug dog 
2. minNFT
    - trigger _safeMint to mint a NFT
3. tokenURI 
    - override the function to just return the tokenURI that we hard coded 

```
- deploy and test 
    - using hardhat-deploy plugin 

## Random IPFS NFT 

1. we want to mint a NFT but using chainLink VRF to generate a random number 
2. then use that number to create a random NFT
3. we have 3 dog breed 
- PUG : rare --> [0-10]
- SHIBA_INU : less rare --> [10-30] 
- GAMAL : common --> [30-100 ]
4. user have to pay fee to mint a NFT 
5. owner can withdraw ETH 

### implementation

- imports : 

```
- chain link VRF so :
    - VRFConsumerBaseV2
    - VRFCoordinatorV2Interface
- open zeppelin :
    - ERC721
    - ERC721URIStorage
    - Ownable 

```
- functions :
    - requestNFT() 
    - requestRandomWords()  
    - fulfillRandomWords()  
    - getChanceArray()
    - getBreedFromModdedRNG()

- Details :
```
- we create requestNFT and requestRandomWords to fulfillRandomWords (cause VRF is 2 step process)
- then create a mapping to link our requestId for our random number and generated NFT (set value in requestNFT and use in fulfillRandomWords)
- and after that implement the rarity functionality by getChanceArray && getBreedForModdedRNG functions and added to fulfillRandomWords function 
- then change ERC721 to ERC721URIStorage contract to have _setTokenURI and (tokenId, tokenURIs ) --> tokenURIs : array of diff dog breed in IPFS 
- and then using Ownable for withdraw and implement mintFee in requestNFT function 
- lastly we add our getter functions and have 2 event at requesting NFT and minting NFT 
```

### deploy 

- so far we didn't use IPFS || add any image , metaData to IPFS 

fist things first : 
- cause we use chain link VRF we have use mocks for local development 
- deploy our randomIpfsNft contract : 
same old ame old but : 
    - for the contract args with need the tokenURIs : 
    - so we have to save our data to IPFS (I. images II. metadata )
- getting our hashes from IPFS 
- using IPFS :
1. run our IPFS node 
2. Pinata 
3. Storage.nft 

## Dynamic svg NFT