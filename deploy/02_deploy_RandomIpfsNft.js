const { network, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const { storeImages, storeTokenUriMetadata } = require("../utils/up")

const dir = "./images/randomNFT"
const metaDataTemplate = {
    name: "",
    description: "",
    image: "",
}

const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther("5")
let VRFCoordinatorV2Mock

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    let VRFCoordinatorAddress, subscriptionId, tokenUris

    // we run the code once and we get the URIs so we can hard code them here
    tokenUris = [
        "ipfs://QmSqCSaTiSKvp3X8cCSC9sBoM9TwjnnBkWSTNrk8BfR51F",
        "ipfs://Qmeb2vwbvFmNLhvJkVodXuUoTuZX65u5fdLovpnV4w4Yyz",
        "ipfs://QmXrq76oRqcU5VQcxTEUTRnBMudkj1HQQrNZhTdyjfzRv2",
    ]
    if (process.env.UPLOAD_TO_PINATA == "true") {
        tokenUris = await handleTokenURIs()
    }

    /* 
        Get the IPFS hashes of our images 
        1. with our IPFS node (manually) https://docs.ipfs.tech/
        2. Pinata https://www.pinata.cloud/ (centralized)
        3. NFT Storage https://nft.storage/ (best way)
    
    */

    if (chainId == 31337) {
        const vrfCoordinatorV2 = await ethers.getContract(
            "VRFCoordinatorV2Mock"
        )
        VRFCoordinatorAddress = vrfCoordinatorV2.address
        const txResponse = await vrfCoordinatorV2.createSubscription()
        const txReceipt = await txResponse.wait(1)
        subscriptionId = txReceipt.events[0].args.subId
        await vrfCoordinatorV2.fundSubscription(
            subscriptionId,
            VRF_SUB_FUND_AMOUNT
        )
    } else {
        VRFCoordinatorAddress = networkConfig[chainId]["vrfCoordinatorV2"]
        subscriptionId = networkConfig[chainId]["subscriptionId"]
    }
    const gasLane = networkConfig[chainId]["gasLane"]
    const callbackGasLimit = networkConfig[chainId]["callbackGasLimit"]
    const mintFee = networkConfig[chainId]["mintFee"]
    // tokenUris = [
    //     "ipfs://QmSsYRx3LpDAb1GZQm7zZ1AuHZjfbPkD6J7s9r41xu1mf8",
    //     "ipfs://QmYx6GsYAKnNzZ9A6NvEKV9nf1VaDzJrqDR23Y8YSkebLU",
    //     "ipfs://QmUPjADFGEKmfohdTaNcWhp7VGk26h5jXDA7v3VtTnTLcW",
    // ]
    // const imageUris = [
    //     "ipfs://QmSsYRx3LpDAb1GZQm7zZ1AuHZjfbPkD6J7s9r41xu1mf8",
    //     "ipfs://QmYx6GsYAKnNzZ9A6NvEKV9nf1VaDzJrqDR23Y8YSkebLU",
    //     "ipfs://QmUPjADFGEKmfohdTaNcWhp7VGk26h5jXDA7v3VtTnTLcW",
    // ]
    const arguments = [
        VRFCoordinatorAddress,
        gasLane,
        subscriptionId,
        callbackGasLimit,
        tokenUris,
        mintFee,
    ]
    log("__________________ deploying Random NFT __________________")
    await deploy("RandomIpfsNFT", {
        from: deployer,
        args: arguments,
        log: true,
        waitConformations: network.config.blockConformations,
    })
    log("__________________**Random NFT Deployed**__________________")
    log("")
}

const handleTokenURIs = async () => {
    tokenUris = []
    // store images in IPFS
    // store metaData in IPFS
    const { responses: imageUploadResponses, files } = await storeImages(dir)
    for (index in imageUploadResponses) {
        //create metadata
        // upload metadata
        let tokenUriMetadata = { ...metaDataTemplate }

        tokenUriMetadata.name = files[index].replace(".png", "")
        tokenUriMetadata.description = `a cute ${tokenUriMetadata.name}`
        tokenUriMetadata.image = `ipfs://${imageUploadResponses[index].IpfsHash}`
        console.log(`Uploading ${tokenUriMetadata.name}... `)
        // store JSON to pinata
        const metadataUploadResponse = await storeTokenUriMetadata(
            tokenUriMetadata
        )
        tokenUris.push(`ipfs://${metadataUploadResponse.IpfsHash}`)
    }
    console.log("token URI uploaded :: ")
    console.log(tokenUris)
    return tokenUris
}

module.exports.tags = ["all", "randomIPFS", "main"]
