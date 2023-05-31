require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
// require("dotenv").config();
const fs = require('fs');
// const infuraId = fs.readFileSync(".infuraid").toString().trim() || "";

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 1337
    },
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/trumkf6XsP2SHNMAamST_D8Hf6mJRM5P",
      accounts: ["bbc2d08bf6bcaa2676e77c3a9d599d050ab3ec9c53c7d93cd2e5fac641d6056b"]

    }

  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
};