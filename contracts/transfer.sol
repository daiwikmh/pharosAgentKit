// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title PharosSwap
 * @dev Automated Market Maker (AMM) for Pharos Chain using a constant product formula
 */
contract PharosSwap is ReentrancyGuard {
    // Token addresses
    address public immutable tokenA;
    address public immutable tokenB;
    
    // Reserves
    uint256 public reserveA;
    uint256 public reserveB;
    
    // LP token tracking
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    // Fee configuration (0.3% by default)
    uint256 public constant FEE_DENOMINATOR = 1000;
    uint256 public feeRate = 3;
    
    // Events
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokens);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokens);
    event Swap(address indexed user, uint256 amountIn, uint256 amountOut, bool isAtoB);
    
    /**
     * @dev Contract constructor
     * @param _tokenA Address of the first token
     * @param _tokenB Address of the second token
     */
    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != address(0) && _tokenB != address(0), "Zero address");
        require(_tokenA != _tokenB, "Same token");
        
        tokenA = _tokenA;
        tokenB = _tokenB;
    }
    
    /**
     * @dev Add liquidity to the pool
     * @param amountADesired Amount of tokenA desired to deposit
     * @param amountBDesired Amount of tokenB desired to deposit
     * @param amountAMin Minimum amount of tokenA to deposit
     * @param amountBMin Minimum amount of tokenB to deposit
     * @return amountA Amount of tokenA actually deposited
     * @return amountB Amount of tokenB actually deposited
     * @return liquidity Amount of LP tokens minted
     */
    function addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) external nonReentrant returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        // Calculate optimal amounts
        if (reserveA == 0 && reserveB == 0) {
            // First liquidity provision
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            // Calculate desired amounts based on current ratio
            uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;
            
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Insufficient B amount");
                amountA = amountADesired;
                amountB = amountBOptimal;
            } else {
                uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
                require(amountAOptimal >= amountAMin, "Insufficient A amount");
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
        }
        
        // Transfer tokens
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "Transfer A failed");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB), "Transfer B failed");
        
        // Calculate LP tokens to mint
        if (totalSupply == 0) {
            // For first liquidity, use geometric mean of amounts
            liquidity = Math.sqrt(amountA * amountB);
        } else {
            // Mint tokens proportional to contribution
            uint256 liquidityA = (amountA * totalSupply) / reserveA;
            uint256 liquidityB = (amountB * totalSupply) / reserveB;
            liquidity = Math.min(liquidityA, liquidityB);
        }
        
        require(liquidity > 0, "Insufficient liquidity minted");
        
        // Update state
        reserveA += amountA;
        reserveB += amountB;
        balanceOf[msg.sender] += liquidity;
        totalSupply += liquidity;
        
        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
        return (amountA, amountB, liquidity);
    }
    
    /**
     * @dev Remove liquidity from the pool
     * @param liquidity Amount of LP tokens to burn
     * @param amountAMin Minimum amount of tokenA to receive
     * @param amountBMin Minimum amount of tokenB to receive
     * @return amountA Amount of tokenA received
     * @return amountB Amount of tokenB received
     */
    function removeLiquidity(
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin
    ) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        require(balanceOf[msg.sender] >= liquidity, "Insufficient LP tokens");
        
        // Calculate token amounts to return
        amountA = (liquidity * reserveA) / totalSupply;
        amountB = (liquidity * reserveB) / totalSupply;
        
        require(amountA >= amountAMin, "Insufficient A amount");
        require(amountB >= amountBMin, "Insufficient B amount");
        
        // Update state before transfers to prevent reentrancy
        balanceOf[msg.sender] -= liquidity;
        totalSupply -= liquidity;
        reserveA -= amountA;
        reserveB -= amountB;
        
        // Transfer tokens
        require(IERC20(tokenA).transfer(msg.sender, amountA), "Transfer A failed");
        require(IERC20(tokenB).transfer(msg.sender, amountB), "Transfer B failed");
        
        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidity);
        return (amountA, amountB);
    }
    
    /**
     * @dev Calculate output amount based on constant product formula
     * @param amountIn Input amount
     * @param reserveIn Input reserve
     * @param reserveOut Output reserve
     * @return amountOut Output amount
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public view returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");
        
        // Calculate fee
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - feeRate);
        
        // Apply constant product formula: (x + Δx) * (y - Δy) = x * y
        // => Δy = y * Δx / (x + Δx)
        amountOut = (reserveOut * amountInWithFee) / (reserveIn * FEE_DENOMINATOR + amountInWithFee);
        
        return amountOut;
    }
    
    /**
     * @dev Swap tokenA for tokenB
     * @param amountIn Amount of tokenA to swap
     * @param amountOutMin Minimum amount of tokenB to receive
     * @return amountOut Amount of tokenB received
     */
    function swapAForB(
        uint256 amountIn,
        uint256 amountOutMin
    ) external nonReentrant returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input");
        
        // Calculate output amount
        amountOut = getAmountOut(amountIn, reserveA, reserveB);
        require(amountOut >= amountOutMin, "Insufficient output");
        
        // Transfer input token from sender
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");
        
        // Update reserves
        reserveA += amountIn;
        reserveB -= amountOut;
        
        // Transfer output token to sender
        require(IERC20(tokenB).transfer(msg.sender, amountOut), "Transfer failed");
        
        emit Swap(msg.sender, amountIn, amountOut, true);
        return amountOut;
    }
    
    /**
     * @dev Swap tokenB for tokenA
     * @param amountIn Amount of tokenB to swap
     * @param amountOutMin Minimum amount of tokenA to receive
     * @return amountOut Amount of tokenA received
     */
    function swapBForA(
        uint256 amountIn,
        uint256 amountOutMin
    ) external nonReentrant returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input");
        
        // Calculate output amount
        amountOut = getAmountOut(amountIn, reserveB, reserveA);
        require(amountOut >= amountOutMin, "Insufficient output");
        
        // Transfer input token from sender
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");
        
        // Update reserves
        reserveB += amountIn;
        reserveA -= amountOut;
        
        // Transfer output token to sender
        require(IERC20(tokenA).transfer(msg.sender, amountOut), "Transfer failed");
        
        emit Swap(msg.sender, amountIn, amountOut, false);
        return amountOut;
    }
    
    /**
     * @dev Get current price (tokenB per tokenA)
     * @return price Current exchange rate
     */
    function getCurrentPrice() external view returns (uint256 price) {
        require(reserveA > 0 && reserveB > 0, "Empty reserves");
        // Price is expressed as tokenB per tokenA with 18 decimal precision
        return (reserveB * 1e18) / reserveA;
    }
    
    /**
     * @dev Get current reserves
     * @return _reserveA Current reserve of tokenA
     * @return _reserveB Current reserve of tokenB
     */
    function getReserves() external view returns (uint256 _reserveA, uint256 _reserveB) {
        return (reserveA, reserveB);
    }
}