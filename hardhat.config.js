require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
const dotenv = require("dotenv");


dotenv.config();


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.18",
 
  networks: {

    calypso: {
            url: process.env.CALYPSO_ENDPOINT,
           
            accounts: [process.env.PRIVATE_KEY]
          },
      
  },
  etherscan: { 
    apiKey: {
      calypso: process.env.ETHERSCAN_API_KEY,
    },
    customChains: [
      {
        network: "calypso",
        chainId: parseInt(process.env.CHAIN_ID),
        urls: {
          apiURL: process.env.API_URL,
          browserURL: process.env.BLOCKEXPLORER_URL,
        },
      }
    ]
  }
};
