// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Credit is ERC20, Ownable(msg.sender) {
    address public usdt;
    /**
     * @dev token price
     **/
    uint256 public tokenPrice;

    /**
     * @dev token price
     **/
    uint256 public tokenPriceDecimal;

    event MintCredit(address indexed to, uint256 amount);
    event BurnCredit(uint256 amount);
    event SetTokenPrice(uint256 tokenPrice, uint256 tokenPriceDecimal);
    /**
     * @param toAddress to address
     * @param amount withdraw amount
     **/
    event WithdrawNative(address indexed toAddress, uint256 amount);

    /**
     * @param token token address
     * @param toAddress destination address
     * @param amount withdraw amount
     **/
    event Withdraw(
        address indexed token,
        address indexed toAddress,
        uint256 amount
    );

    constructor(address _usdt) ERC20("Credit", "Credit") {
        require(
            _usdt != address(0),
            "Coupon:  usdt address should not be the zero address"
        );
        usdt = _usdt;
    }

    function mintCredit(uint256 amount) external {
        require(amount > 0, "Credit: amount should be breather than the zero");
        require(
            IERC20(usdt).allowance(msg.sender, address(this)) >= amount,
            "Credit: usdt allowance error"
        );

        IERC20(usdt).transferFrom(msg.sender, address(this), amount);

        uint256 mintAmount = (amount * tokenPrice) / tokenPriceDecimal;

        _mint(msg.sender, mintAmount);

        emit MintCredit(msg.sender, mintAmount);
    }

    function burnCredit(uint256 amount) external {
        require(amount > 0, "Credit: amount should be breather than the zero");

        _burn(msg.sender, amount);

        emit BurnCredit(amount);
    }

    /**
     * @param _tokenPrice token price
     * @param _tokenPriceDecimal token price
     **/
    function setTokenPrice(uint256 _tokenPrice, uint256 _tokenPriceDecimal)
        external
        onlyOwner
    {
        require(
            _tokenPrice > 0,
            "Credit: token price should be geater than the zero"
        );
        require(
            _tokenPriceDecimal > 0,
            "Credit: token price decimal should be geater than the zero"
        );

        tokenPrice = _tokenPrice;
        tokenPriceDecimal = _tokenPriceDecimal;

        emit SetTokenPrice(_tokenPrice, _tokenPriceDecimal);
    }

    /**
     * @param  toAddress address to receive fee
     * @param amount withdraw native token amount
     **/
    function withdrawNative(address payable toAddress, uint256 amount)
        external
        onlyOwner
    {
        require(
            toAddress != address(0),
            "Credit: The zero address should not be the fee address"
        );

        require(amount > 0, "Credit: amount should be greater than the zero");

        uint256 balance = address(this).balance;

        require(amount <= balance, "Credit: No balance to withdraw");

        (bool success, ) = toAddress.call{value: balance}("");
        require(success, "Credit: Withdraw failed");

        emit WithdrawNative(toAddress, balance);
    }

    /**
     * @param token token address
     * @param toAddress to address
     * @param amount withdraw amount
     **/
    function withdraw(
        address token,
        address payable toAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            token != address(0),
            "Credit: token address should not be the zero address"
        );
        require(
            toAddress != address(0),
            "Credit: to address should not be the zero address"
        );
        require(amount > 0, "Credit: amount should be greater than the zero");

        uint256 balance = IERC20(token).balanceOf(address(this));

        require(amount <= balance, "Credit: No balance to withdraw");

        IERC20(token).transfer(toAddress, amount);

        emit Withdraw(token, toAddress, amount);
    }
}
