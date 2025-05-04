const { ethers } = require("ethers");

// Connect to an Ethereum provider (e.g., Infura, Alchemy, or local node)
const provider = new ethers.JsonRpcProvider("https://devnet.dplabs-internal.com"); // e.g., https://mainnet.infura.io/v3/YOUR_PROJECT_ID

// Your wallet (signer)
const privateKey = "a73f439105df962fa7af1a273c400e562f1065977926c423762d1c48c7432aac"; // Never hardcode in production!
const wallet = new ethers.Wallet(privateKey, provider);

// Contract details
const contractAddress = "0xA22E754485D37EbC662141d06fEf3119ddd9Ec53"; // Replace with the deployed contract address
const contractABI = [
  // ABI for the mint function
  "function mint(address to, uint256 amount) external"
];

// Connect to the contract
const tokenContract = new ethers.Contract(contractAddress, contractABI, wallet);

// Call the mint function
async function mintTokens(toAddress:string, amount:number) {
  try {
    // Convert amount to the correct units (assuming 18 decimals, like most ERC20 tokens)
    const tx = await tokenContract.mint(toAddress, ethers.parseUnits(amount.toString(), 18));
    console.log("Transaction hash:", tx.hash);

    // Wait for the transaction to be mined
    await tx.wait();
    console.log("Tokens minted successfully!");
  } catch (error) {
    console.error("Error minting tokens:", error);
  }
}

// Example usage
const recipient = "0x1029BBd9B780f449EBD6C74A615Fe0c04B61679c"; // Replace with the target address
const amount = 100; // Mint 100 tokens
mintTokens(recipient, amount);