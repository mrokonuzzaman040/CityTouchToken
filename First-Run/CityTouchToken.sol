// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Import ERC20 and Ownable from the same directory
import "./ERC20.sol";
import "./Ownable.sol";

contract CityTouchToken is ERC20, Ownable {
    uint256 private _initialSupply = 25_000_000 * 10 ** decimals(); // 25 million tokens with decimals
    address public treasury;  // Treasury wallet
    uint256 public halvingInterval = 365 days; // Time interval for halving (1 year)
    uint256 public nextHalving;
    uint256 public halvingFactor = 2; // Halving factor (reduce rewards by half)
    uint256 public reward = 1000 * 10 ** decimals(); // Initial reward
    address public swapToken;  // Address of the token used for swapping

    event MessageSent(address indexed from, address indexed to, uint256 amount, string message);
    event Swap(address indexed from, address indexed to, uint256 amountIn, uint256 amountOut);

    constructor(address _treasury) ERC20("CityTouch", "CTT") {
        treasury = _treasury;
        nextHalving = block.timestamp + halvingInterval;

        // Mint the initial supply to the contract deployer (owner)
        _mint(msg.sender, _initialSupply);
    }

    // Owner-only function to mint new tokens
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Send tokens with a message
    function transferWithMessage(address recipient, uint256 amount, string memory message) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        emit MessageSent(msg.sender, recipient, amount, message);
        return true;
    }

    // Treasury system: Transfer with treasury deduction
    function transferWithTreasury(address recipient, uint256 amount) public returns (bool) {
        uint256 treasuryAmount = (amount * 2) / 100; // 2% to treasury
        uint256 transferAmount = amount - treasuryAmount;
        _transfer(msg.sender, recipient, transferAmount);
        _transfer(msg.sender, treasury, treasuryAmount);  // Send 2% to treasury
        return true;
    }

    // Halving system: Reduce reward by half at each halving event
    function checkHalving() public onlyOwner {
        if (block.timestamp >= nextHalving) {
            reward = reward / halvingFactor;  // Halve the reward
            nextHalving = block.timestamp + halvingInterval;  // Set next halving time
        }
    }

    // Set swap token address
    function setSwapToken(address _swapToken) public onlyOwner {
        swapToken = _swapToken;
    }

    // Simple swap function
    function swapTokens(address to, uint256 amount) public returns (bool) {
        require(swapToken != address(0), "Swap token not set");
        uint256 swapAmount = getSwapRate(amount); // Calculate the swap rate
        ERC20(swapToken).transferFrom(msg.sender, address(this), amount);  // Transfer swap token from sender
        _transfer(address(this), to, swapAmount);  // Send CityTouch tokens to recipient
        emit Swap(msg.sender, to, amount, swapAmount);
        return true;
    }

    // Placeholder for calculating swap rate (1:1 for simplicity, can be modified)
    function getSwapRate(uint256 amount) public pure returns (uint256) {
        return amount;  // 1:1 rate for simplicity
    }

    // Function to transfer tokens to users
    function transferTokensToUser(address recipient, uint256 amount) public onlyOwner {
        _transfer(msg.sender, recipient, amount);
    }

    // Function for the owner to check their own balance
    function checkOwnerBalance() public view onlyOwner returns (uint256) {
        return balanceOf(msg.sender);
    }
}
