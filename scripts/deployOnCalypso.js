const hre = require("hardhat");

async function main() {


  const KNFTCollectible = await hre.ethers.getContractFactory("KNFTCollectible");
  const contract = await KNFTCollectible.deploy('ipfs://QmWr4YtQZT9yXHgLhmqosYZLqSDxkKnzV1WAW5U1SMGnft', {gasLimit: 500000000, gasPrice: 1000000});

  await contract.deployed();

  console.log("KNFTCollectible.sol deployed to:", contract.address);
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
