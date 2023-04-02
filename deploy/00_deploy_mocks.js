const { network, ethers } = require("hardhat")
// const { networkConfig, developmentChains } = require("../helper-hardhat-config")

const BASE_FEE = "250000000000000000" //ethers.utils.parseEther("0.25") // 0.25 is the premium . It cost 0.25 LINK per request
const GAS_PRICE_LINK = 1e9 //calculated value  base on gas price on chain (LINK per gas)

const DECIMALS = 18
const INITIAL_PRICE = ethers.utils.parseEther("2000", "ether")
module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    if (chainId == 31337) {
        log("______ deploying mocks _______ ")
        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            args: [BASE_FEE, GAS_PRICE_LINK],
            log: true,
        })
        await deploy("MockV3Aggregator", {
            from: deployer,
            args: [DECIMALS, INITIAL_PRICE],
            log: true,
        })

        log("_______**mocks deployed**_______")
        log("")
    }
}
module.exports.tags = ["all", "mocks"]
