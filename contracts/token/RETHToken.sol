pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../StafiBase.sol";
import "../interfaces/token/IRETHToken.sol";
import "../interfaces/network/IStafiNetworkBalances.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";

// rETH is backed by ETH (subject to liquidity) at a variable exchange rate
contract RETHToken is StafiBase, ERC20, IRETHToken {

    // Libs
    using SafeMath for uint256;

    // Events
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event TokensMinted(address indexed to, uint256 amount, uint256 ethAmount, uint256 time);
    event TokensBurned(address indexed from, uint256 amount, uint256 ethAmount, uint256 time);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) ERC20("StaFi", "rETH") public {
        version = 1;
        setBurnEnabled(false);
    }

    // Calculate the amount of ETH backing an amount of rETH
    function getEthValue(uint256 _rethAmount) override public view returns (uint256) {
        // Get network balances
        IStafiNetworkBalances stafiNetworkBalances = IStafiNetworkBalances(getContractAddress("stafiNetworkBalances"));
        uint256 totalEthBalance = stafiNetworkBalances.getTotalETHBalance();
        uint256 rethSupply = stafiNetworkBalances.getTotalRETHSupply();
        // Use 1:1 ratio if no rETH is minted
        if (rethSupply == 0) { return _rethAmount; }
        // Calculate and return
        return _rethAmount.mul(totalEthBalance).div(rethSupply);
    }

    // Calculate the amount of rETH backed by an amount of ETH
    function getRethValue(uint256 _ethAmount) override public view returns (uint256) {
        // Get network balances
        IStafiNetworkBalances stafiNetworkBalances = IStafiNetworkBalances(getContractAddress("stafiNetworkBalances"));
        uint256 totalEthBalance = stafiNetworkBalances.getTotalETHBalance();
        uint256 rethSupply = stafiNetworkBalances.getTotalRETHSupply();
        // Use 1:1 ratio if no rETH is minted
        if (rethSupply == 0) { return _ethAmount; }
        // Check network ETH balance
        require(totalEthBalance > 0, "Cannot calculate rETH token amount while total network balance is zero");
        // Calculate and return
        return _ethAmount.mul(rethSupply).div(totalEthBalance);
    }

    // Get the current ETH : rETH exchange rate
    // Returns the amount of ETH backing 1 rETH
    function getExchangeRate() override public view returns (uint256) {
        return getEthValue(1 ether);
    }

    // Get the total amount of collateral available
    // Includes rETH contract balance & excess deposit pool balance
    function getTotalCollateral() override public view returns (uint256) {
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        return stafiUserDeposit.getExcessBalance().add(address(this).balance);
    }

    // Get the current ETH collateral rate
    // Returns the portion of rETH backed by ETH in the contract as a fraction of 1 ether
    function getCollateralRate() override public view returns (uint256) {
        uint256 calcBase = 1 ether;
        uint256 totalEthValue = getEthValue(totalSupply());
        if (totalEthValue == 0) { return calcBase; }
        return calcBase.mul(address(this).balance).div(totalEthValue);
    }

    // Deposit ETH rewards
    // Only accepts calls from the StafiNetworkWithdrawal contract
    function depositRewards() override external payable onlyLatestContract("stafiNetworkWithdrawal", msg.sender) {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, now);
    }

    // Deposit excess ETH from deposit pool
    // Only accepts calls from the StafiUserDeposit contract
    function depositExcess() override external payable onlyLatestContract("stafiUserDeposit", msg.sender) {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, now);
    }

    // Mint rETH
    // Only accepts calls from the StafiUserDeposit contract
    function mint(uint256 _ethAmount, address _to) override external onlyLatestContract("stafiUserDeposit", msg.sender) {
        // Get rETH amount
        uint256 rethAmount = getRethValue(_ethAmount);
        // Check rETH amount
        require(rethAmount > 0, "Invalid token mint amount");

        // Update balance & supply
        _mint(_to, rethAmount);
        // Emit tokens minted event
        emit TokensMinted(_to, rethAmount, _ethAmount, now);
    }

    // Burn rETH for ETH
    function burn(uint256 _rethAmount) override external {
        // Check deposit settings
        require(getBurnEnabled(), "Burn is currently disabled");
        // Check rETH amount
        require(_rethAmount > 0, "Invalid token burn amount");
        require(balanceOf(msg.sender) >= _rethAmount, "Insufficient rETH balance");
        // Get ETH amount
        uint256 ethAmount = getEthValue(_rethAmount);
        // Get & check ETH balance
        uint256 ethBalance = getTotalCollateral();
        require(ethBalance >= ethAmount, "Insufficient ETH balance for exchange");
        // Update balance & supply
        _burn(msg.sender, _rethAmount);
        // Withdraw ETH from deposit pool if required
        withdrawDepositCollateral(ethAmount);
        // Transfer ETH to sender
        msg.sender.transfer(ethAmount);
        // Emit tokens burned event
        emit TokensBurned(msg.sender, _rethAmount, ethAmount, now);
    }

    // Withdraw ETH from the deposit pool for collateral if required
    function withdrawDepositCollateral(uint256 _ethRequired) private {
        // Check rETH contract balance
        uint256 ethBalance = address(this).balance;
        if (ethBalance >= _ethRequired) { return; }
        // Withdraw
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        stafiUserDeposit.withdrawExcessBalance(_ethRequired.sub(ethBalance));
    }

    // Burn currently enabled
    function getBurnEnabled() public view returns (bool) {
        return getBoolS("settings.reth.burn.enabled");
    }
    
    function setBurnEnabled(bool _value) public onlySuperUser {
        setBoolS("settings.reth.burn.enabled", _value);
    }

}
