const { ethers, network, deployments, getNamedAccounts } = require("hardhat")

const { developmentChains, networkConfig } = require("../helper-hardhat-config")

const fs = require("fs")

const { verify } = require("../utils/verify")

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    let ethUsdPriceFeedAddress

    if (developmentChains.includes(network.name)) {
        const EthUsdAggregator = await ethers.getContract("MockV3Aggregator")
        ethUsdPriceFeedAddress = EthUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig["chainId"]["ethUsdPriceFeed"]
    }

    const btcSvg = fs.readFileSync("./images/dynamicSVG/btc.svg", {
        encoding: "utf8",
    })
    const ethSvg = fs.readFileSync("./images/dynamicSVG/eth.svg", {
        encoding: "utf8",
    })
    const args = [ethUsdPriceFeedAddress, btcSvg, ethSvg]
    log("deploying DynamicSvgNFT .... ")
    const dynamicSvgNft = await deploy("DynamicSvgNFT", {
        from: deployer,
        log: true,
        args: args,
        waitConformations: network.config.blockConformations || 1,
    })
    log("deploying is finished ")

    // add verfication code here
}

module.exports.tags = ["all", "dynamicSvgNFT", "main"]
