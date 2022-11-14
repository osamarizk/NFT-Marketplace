const hre = require("hardhat");

async function main() {
  // We get the contract to deploy
  const NFTMarketplace = await hre.ethers.getContractFactory("NFTMarketplace");
  const nftmrketplace = await NFTMarketplace.deploy();

  await nftmrketplace.deployed();

  console.log("NFT Marketplace deployed to:", nftmrketplace.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
