const { network } = require("hardhat")
// const { developmentChains } = require("../helper-hardhat-config")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    log("__________________ deploying simple NFT __________________")

    const args = []
    const simpleNFT = await deploy("SimpleNFT", {
        from: deployer,
        args: args,
        log: true,
        waitConformations: network.config.blockConformations || 1,
    })

    log("__________________**simple NFT deployed**__________________")
    log("")
}

module.exports.tags = ["all", "simple"]
