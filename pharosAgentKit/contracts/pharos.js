import { ethers } from "ethers"; // Change require to import

// Configuration
const provider = new ethers.JsonRpcProvider("https://devnet.dplabs-internal.com");
const privateKey = "a73f439105df962fa7af1a273c400e562f1065977926c423762d1c48c7432aac";
const wallet = new ethers.Wallet(privateKey, provider);

// Addresses
const pharosSwapAddress = "0x65B4Ae254B2B172eb5F4D495aBfF9A39Ac376d87";
const tokenAAddress = "0xA22E754485D37EbC662141d06fEf3119ddd9Ec53";
const tokenBAddress = "0xb0b2d1e56328EB6f7e5c9139e7BA4b47A02C7acD";

// ABIs
const pharosSwapABI = [
  "function addLiquidity(uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin) external returns (uint256 amountA, uint256 amountB, uint256 liquidity)",
  "function removeLiquidity(uint256 liquidity, uint256 amountAMin, uint256 amountBMin) external returns (uint256 amountA, uint256 amountB)",
  "function swapAForB(uint256 amountIn, uint256 amountOutMin) external returns (uint256 amountOut)",
  "function swapBForA(uint256 amountIn, uint256 amountOutMin) external returns (uint256 amountOut)",
  "function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountOut)",
  "function getCurrentPrice() external view returns (uint256 price)",
  "function getReserves() external view returns (uint256 _reserveA, uint256 _reserveB)",
  "event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokens)",
  "event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokens)",
  "event Swap(address indexed user, uint256 amountIn, uint256 amountOut, bool isAtoB)"
];

const erc20ABI = [
  "function approve(address spender, uint256 amount) external returns (bool)",
  "function allowance(address owner, address spender) external view returns (uint256)",
  "event Approval(address indexed owner, address indexed spender, uint256 value)"
];

// Contracts
const pharosSwapContract = new ethers.Contract(pharosSwapAddress, pharosSwapABI, wallet);
const tokenAContract = new ethers.Contract(tokenAAddress, erc20ABI, wallet);
const tokenBContract = new ethers.Contract(tokenBAddress, erc20ABI, wallet);

// Functions
async function approveTokens(tokenAddress, amount, tokenName) {
  try {
    const tokenContract = new ethers.Contract(tokenAddress, erc20ABI, wallet);
    const amountWei = ethers.parseUnits(amount, 18);
    const approveTx = await tokenContract.approve(pharosSwapAddress, amountWei, { gasLimit: 100000 });
    const receipt = await approveTx.wait();
    console.log(`${tokenName} Approval successful:`, receipt.transactionHash);
  } catch (error) {
    console.error(`Error approving ${tokenName}:`, error.message || error);
    throw error;
  }
}

async function addLiquidity(amountADesired, amountBDesired, amountAMin, amountBMin) {
  try {
    const amountAWei = ethers.parseUnits(amountADesired, 18);
    const amountBWei = ethers.parseUnits(amountBDesired, 18);
    const amountAMinWei = ethers.parseUnits(amountAMin, 18);
    const amountBMinWei = ethers.parseUnits(amountBMin, 18);
    const tx = await pharosSwapContract.addLiquidity(amountAWei, amountBWei, amountAMinWei, amountBMinWei);
    await tx.wait();
    console.log("Liquidity added:", tx.hash);
  } catch (error) {
    console.error("Error adding liquidity:", error.message || error);
    throw error;
  }
}

async function removeLiquidity(liquidity, amountAMin, amountBMin) {
  try {
    const liquidityWei = ethers.parseUnits(liquidity, 18);
    const amountAMinWei = ethers.parseUnits(amountAMin, 18);
    const amountBMinWei = ethers.parseUnits(amountBMin, 18);
    const tx = await pharosSwapContract.removeLiquidity(liquidityWei, amountAMinWei, amountBMinWei, { gasLimit: 300000 });
    const receipt = await tx.wait();
    console.log("Liquidity removed:", receipt.transactionHash);
  } catch (error) {
    console.error("Error removing liquidity:", error.message || error);
    throw error;
  }
}

async function swapAForB(amountIn, amountOutMin) {
  try {
    await approveTokens(tokenAAddress, amountIn, "TokenA");
    const amountInWei = ethers.parseUnits(amountIn, 18);
    const amountOutMinWei = ethers.parseUnits(amountOutMin, 18);
    const tx = await pharosSwapContract.swapAForB(amountInWei, amountOutMinWei, { gasLimit: 200000 });
    const receipt = await tx.wait();
    console.log("Swap A for B successful:", receipt.transactionHash);
  } catch (error) {
    console.error("Error swapping A for B:", error.message || error);
    throw error;
  }
}

async function swapBForA(amountIn, amountOutMin) {
  try {
    await approveTokens(tokenBAddress, amountIn, "TokenB");
    const amountInWei = ethers.parseUnits(amountIn, 18);
    const amountOutMinWei = ethers.parseUnits(amountOutMin, 18);
    const tx = await pharosSwapContract.swapBForA(amountInWei, amountOutMinWei, { gasLimit: 200000 });
    const receipt = await tx.wait();
    console.log("Swap B for A successful:", receipt.transactionHash);
  } catch (error) {
    console.error("Error swapping B for A:", error.message || error);
    throw error;
  }
}

async function getAmountOut(amountIn, isAtoB) {
  try {
    const amountInWei = ethers.parseUnits(amountIn, 18);
    const reserves = await pharosSwapContract.getReserves();
    const [reserveIn, reserveOut] = isAtoB ? [reserves[0], reserves[1]] : [reserves[1], reserves[0]];
    const amountOut = await pharosSwapContract.getAmountOut(amountInWei, reserveIn, reserveOut);
    return ethers.formatUnits(amountOut, 18);
  } catch (error) {
    console.error("Error getting amount out:", error.message || error);
    throw error;
  }
}

async function getCurrentPrice() {
  try {
    const price = await pharosSwapContract.getCurrentPrice();
    return ethers.formatUnits(price, 18);
  } catch (error) {
    console.error("Error getting price:", error.message || error);
    throw error;
  }
}

async function getReserves() {
  try {
    const [reserveA, reserveB] = await pharosSwapContract.getReserves();
    return {
      reserveA: ethers.formatUnits(reserveA, 18),
      reserveB: ethers.formatUnits(reserveB, 18)
    };
  } catch (error) {
    console.error("Error getting reserves:", error.message || error);
    throw error;
  }
}

// Export functions
export {
  approveTokens,
  addLiquidity,
  removeLiquidity,
  swapAForB,
  swapBForA,
  getAmountOut,
  getCurrentPrice,
  getReserves
};
