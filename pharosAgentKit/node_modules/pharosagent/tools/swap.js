import { DynamicStructuredTool } from "@langchain/core/tools";
import { z } from "zod";
import {
  approveTokens,
  addLiquidity,
  removeLiquidity,
  swapAForB,
  swapBForA,
  getAmountOut,
  getCurrentPrice,
  getReserves
} from "../contracts/pharos.js"; // adjust path as needed

// Approve Tool
export const approveTokenTool = new DynamicStructuredTool({
  name: "approve_token",
  description: "Approve a token for spending by the PharosSwap contract.",
  schema: z.object({
    tokenAddress: z.string().describe("ERC20 token address to approve"),
    amount: z.string().describe("Amount in decimal format"),
    tokenName: z.string().describe("Readable name of the token")
  }),
  func: async ({ tokenAddress, amount, tokenName }) => {
    await approveTokens(tokenAddress, amount, tokenName);
    return `${tokenName} approved successfully.`;
  }
});

// Add Liquidity Tool
export const addLiquidityTool = new DynamicStructuredTool({
  name: "add_liquidity",
  description: "Add liquidity to PharosSwap pool.",
  schema: z.object({
    amountADesired: z.string(),
    amountBDesired: z.string(),
    amountAMin: z.string(),
    amountBMin: z.string()
  }),
  func: async (input) => {
    await addLiquidity(input.amountADesired, input.amountBDesired, input.amountAMin, input.amountBMin);
    return "Liquidity added successfully.";
  }
});

// Remove Liquidity Tool
export const removeLiquidityTool = new DynamicStructuredTool({
  name: "remove_liquidity",
  description: "Remove liquidity from PharosSwap pool.",
  schema: z.object({
    liquidity: z.string(),
    amountAMin: z.string(),
    amountBMin: z.string()
  }),
  func: async (input) => {
    await removeLiquidity(input.liquidity, input.amountAMin, input.amountBMin);
    return "Liquidity removed successfully.";
  }
});

// Swap A for B Tool
export const swapAForBTool = new DynamicStructuredTool({
  name: "swap_tokenA_for_tokenB",
  description: "Swap Token A for Token B.",
  schema: z.object({
    amountIn: z.string(),
    amountOutMin: z.string()
  }),
  func: async (input) => {
    await swapAForB(input.amountIn, input.amountOutMin);
    return "Token A swapped for Token B successfully.";
  }
});

// Swap B for A Tool
export const swapBForATool = new DynamicStructuredTool({
  name: "swap_tokenB_for_tokenA",
  description: "Swap Token B for Token A.",
  schema: z.object({
    amountIn: z.string(),
    amountOutMin: z.string()
  }),
  func: async (input) => {
    await swapBForA(input.amountIn, input.amountOutMin);
    return "Token B swapped for Token A successfully.";
  }
});

// Get Amount Out Tool
export const getAmountOutTool = new DynamicStructuredTool({
  name: "get_swap_amount_out",
  description: "Calculate expected output amount for a swap.",
  schema: z.object({
    amountIn: z.string(),
    isAtoB: z.boolean()
  }),
  func: async (input) => {
    const amountOut = await getAmountOut(input.amountIn, input.isAtoB);
    return `Expected output: ${amountOut}`;
  }
});

// Get Current Price Tool
export const getCurrentPriceTool = new DynamicStructuredTool({
  name: "get_current_price",
  description: "Get current price of TokenB per TokenA.",
  schema: z.object({}),
  func: async () => {
    const price = await getCurrentPrice();
    return `Current price (TokenB per TokenA): ${price}`;
  }
});

// Get Reserves Tool
export const getReservesTool = new DynamicStructuredTool({
  name: "get_pool_reserves",
  description: "Get current reserves of Token A and Token B.",
  schema: z.object({}),
  func: async () => {
    const { reserveA, reserveB } = await getReserves();
    return `Reserve A: ${reserveA}, Reserve B: ${reserveB}`;
  }
});

// Export all tools in an array
export const pharosTools = [
  approveTokenTool,
  addLiquidityTool,
  removeLiquidityTool,
  swapAForBTool,
  swapBForATool,
  getAmountOutTool,
  getCurrentPriceTool,
  getReservesTool
];
