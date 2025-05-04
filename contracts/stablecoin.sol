// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SimplePharosStable
 * @dev A simplified stablecoin implementation for Pharos chain with fixed pricing
 */
contract SimplePharosStable is ERC20, ERC20Burnable, AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    
    // Collateral token (e.g., ETH equivalent on Pharos)
    address public immutable collateralToken;
    
    // Fixed collateral ratio (150% = 15000)
    uint256 public collateralRatio = 15000;
    uint256 public constant RATIO_PRECISION = 10000;
    
    // Fixed price for collateral token in USD (with 18 decimals)
    uint256 public collateralPrice;
    
    // Fee configuration
    uint256 public mintFee = 50; // 0.5%
    uint256 public burnFee = 20;  // 0.2%
    uint256 public constant FEE_PRECISION = 10000;
    
    // Vaults to track user collateral
    struct Vault {
        uint256 collateralAmount;
        uint256 stableAmount;
    }
    mapping(address => Vault) public vaults;
    
    // Total system stats
    uint256 public totalCollateral;
    uint256 public totalStable;
    
    // Events
    event VaultCreated(address indexed user);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event StableMinted(address indexed user, uint256 amount);
    event StableBurned(address indexed user, uint256 amount);
    event VaultLiquidated(address indexed user, address liquidator, uint256 collateralSeized, uint256 stableBurned);
    event CollateralPriceUpdated(uint256 newPrice);
    event CollateralRatioUpdated(uint256 newRatio);
    
    /**
     * @dev Constructor
     * @param _name Stablecoin name
     * @param _symbol Stablecoin symbol
     * @param _collateralToken Address of the collateral token
     * @param _initialCollateralPrice Initial price of collateral in USD (with 18 decimals)
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _collateralToken,
        uint256 _initialCollateralPrice
    ) ERC20(_name, _symbol) {
        require(_collateralToken != address(0), "Invalid collateral address");
        require(_initialCollateralPrice > 0, "Invalid price");
        
        collateralToken = _collateralToken;
        collateralPrice = _initialCollateralPrice;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(GOVERNANCE_ROLE, msg.sender);
    }
    
    /**
     * @dev Pauses all token transfers
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
    
    /**
     * @dev Updates the collateral price
     * @param _newPrice New price with 18 decimals
     */
    function updateCollateralPrice(uint256 _newPrice) external onlyRole(GOVERNANCE_ROLE) {
        require(_newPrice > 0, "Invalid price");
        collateralPrice = _newPrice;
        emit CollateralPriceUpdated(_newPrice);
    }
    
    /**
     * @dev Updates the collateralization ratio
     * @param _newRatio New collateralization ratio
     */
    function updateCollateralRatio(uint256 _newRatio) external onlyRole(GOVERNANCE_ROLE) {
        require(_newRatio >= 10000, "Ratio too low");
        collateralRatio = _newRatio;
        emit CollateralRatioUpdated(_newRatio);
    }
    
    /**
     * @dev Deposit collateral to vault
     * @param _amount Amount of collateral to deposit
     */
    function depositCollateral(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Amount must be > 0");
        
        // Create vault if it doesn't exist
        if (vaults[msg.sender].collateralAmount == 0 && vaults[msg.sender].stableAmount == 0) {
            emit VaultCreated(msg.sender);
        }
        
        // Transfer collateral from user
        require(IERC20(collateralToken).transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        // Update vault
        vaults[msg.sender].collateralAmount += _amount;
        totalCollateral += _amount;
        
        emit CollateralDeposited(msg.sender, _amount);
    }
    
    /**
     * @dev Withdraw collateral from vault
     * @param _amount Amount of collateral to withdraw
     */
    function withdrawCollateral(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Amount must be > 0");
        Vault storage vault = vaults[msg.sender];
        require(vault.collateralAmount >= _amount, "Insufficient collateral");
        
        // Check if remaining collateral is sufficient for issued stablecoins
        uint256 remainingCollateral = vault.collateralAmount - _amount;
        if (vault.stableAmount > 0) {
            require(
                _isCollateralSufficient(remainingCollateral, vault.stableAmount),
                "Undercollateralized"
            );
        }
        
        // Update vault
        vault.collateralAmount = remainingCollateral;
        totalCollateral -= _amount;
        
        // Transfer collateral to user
        require(IERC20(collateralToken).transfer(msg.sender, _amount), "Transfer failed");
        
        emit CollateralWithdrawn(msg.sender, _amount);
    }
    
    /**
     * @dev Mint stablecoins
     * @param _amount Amount of stablecoins to mint
     */
    function mintStable(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Amount must be > 0");
        Vault storage vault = vaults[msg.sender];
        
        // Apply mint fee
        uint256 feeAmount = (_amount * mintFee) / FEE_PRECISION;
        uint256 totalAmount = _amount + feeAmount;
        
        // Check collateral
        require(
            _isCollateralSufficient(vault.collateralAmount, vault.stableAmount + totalAmount),
            "Insufficient collateral"
        );
        
        // Update vault
        vault.stableAmount += totalAmount;
        totalStable += totalAmount;
        
        // Mint tokens
        _mint(msg.sender, _amount);
        if (feeAmount > 0) {
            _mint(address(this), feeAmount); // Fee goes to protocol
        }
        
        emit StableMinted(msg.sender, _amount);
    }
    
    /**
     * @dev Burn stablecoins to release collateral
     * @param _amount Amount of stablecoins to burn
     */
    function burnStable(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Amount must be > 0");
        Vault storage vault = vaults[msg.sender];
        require(vault.stableAmount >= _amount, "Insufficient stable balance in vault");
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        
        // Apply burn fee
        uint256 feeAmount = (_amount * burnFee) / FEE_PRECISION;
        uint256 burnAmount = _amount - feeAmount;
        
        // Update vault
        vault.stableAmount -= _amount;
        totalStable -= _amount;
        
        // Burn tokens
        _burn(msg.sender, burnAmount);
        if (feeAmount > 0) {
            _transfer(msg.sender, address(this), feeAmount); // Fee goes to protocol
        }
        
        emit StableBurned(msg.sender, _amount);
    }
    
    /**
     * @dev Liquidate an undercollateralized vault
     * @param _user Address of the vault owner
     */
    function liquidateVault(address _user) external nonReentrant whenNotPaused {
        Vault storage vault = vaults[_user];
        require(vault.stableAmount > 0, "No debt to liquidate");
        
        // Check if vault is undercollateralized
        require(
            !_isCollateralSufficient(vault.collateralAmount, vault.stableAmount),
            "Vault is sufficiently collateralized"
        );
        
        uint256 collateralToSeize = vault.collateralAmount;
        uint256 stableToBurn = vault.stableAmount;
        
        // Check if liquidator has enough stablecoin
        require(balanceOf(msg.sender) >= stableToBurn, "Insufficient balance to liquidate");
        
        // Clear the vault
        totalCollateral -= collateralToSeize;
        totalStable -= stableToBurn;
        vault.collateralAmount = 0;
        vault.stableAmount = 0;
        
        // Burn stablecoins from liquidator
        _burn(msg.sender, stableToBurn);
        
        // Transfer collateral to liquidator
        require(IERC20(collateralToken).transfer(msg.sender, collateralToSeize), "Transfer failed");
        
        emit VaultLiquidated(_user, msg.sender, collateralToSeize, stableToBurn);
    }
    
    /**
     * @dev Get current price of collateral token in USD
     * @return price Current price with 18 decimals
     */
    function getCollateralPrice() public view returns (uint256) {
        return collateralPrice;
    }
    
    /**
     * @dev Check if collateral is sufficient for the stable amount
     * @param _collateralAmount Amount of collateral
     * @param _stableAmount Amount of stablecoin
     * @return Whether collateral is sufficient
     */
    function _isCollateralSufficient(
        uint256 _collateralAmount, 
        uint256 _stableAmount
    ) internal view returns (bool) {
        if (_stableAmount == 0) return true;
        
        uint256 collateralValue = (_collateralAmount * getCollateralPrice()) / 1e18;
        uint256 requiredCollateral = (_stableAmount * collateralRatio) / RATIO_PRECISION;
        
        return collateralValue >= requiredCollateral;
    }
    
    /**
     * @dev Get vault information
     * @param _user Address of the vault owner
     * @return collateralAmount Amount of collateral in the vault
     * @return stableAmount Amount of stablecoin debt in the vault
     * @return collateralRatioPercent Current collateralization ratio as a percentage
     */
    function getVaultInfo(address _user) external view returns (
        uint256 collateralAmount,
        uint256 stableAmount,
        uint256 collateralRatioPercent
    ) {
        Vault storage vault = vaults[_user];
        collateralAmount = vault.collateralAmount;
        stableAmount = vault.stableAmount;
        
        if (stableAmount == 0) return (collateralAmount, stableAmount, type(uint256).max);
        
        uint256 collateralValue = (collateralAmount * getCollateralPrice()) / 1e18;
        collateralRatioPercent = (collateralValue * RATIO_PRECISION) / stableAmount;
        
        return (collateralAmount, stableAmount, collateralRatioPercent);
    }
   
}