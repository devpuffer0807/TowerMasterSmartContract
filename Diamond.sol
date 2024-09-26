// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Diamond is ERC20, Ownable(msg.sender) {
    address public usdt;
    /**
     * @dev token price
     **/
    uint256 public tokenPrice;

    /**
     * @dev token price
     **/
    uint256 public tokenPriceDecimal;

    event MintDiamond(address indexed to, uint256 amount);
    event SwapDiamondToUsdt(
        address indexed user,
        uint256 diamondAmount,
        uint256 usdtAmount
    );
    event BurnDiamond(uint256 amount);
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

    constructor(address _usdt) ERC20("Diamond", "Diamond") {
        require(
            _usdt != address(0),
            "Coupon:  usdt address should not be the zero address"
        );
        usdt = _usdt;
    }

    function mintDiamond(uint256 amount) external {
        require(amount > 0, "Diamond: amount should be breather than the zero");
        require(
            IERC20(usdt).allowance(msg.sender, address(this)) >= amount,
            "Diamond: usdt allowance error"
        );

        IERC20(usdt).transferFrom(msg.sender, address(this), amount);

        uint256 mintAmount = (amount * tokenPrice) / tokenPriceDecimal;

        _mint(msg.sender, mintAmount);

        emit MintDiamond(msg.sender, mintAmount);
    }

    function burnDiamond(uint256 amount) external {
        require(amount > 0, "Diamond: amount should be breather than the zero");

        _burn(msg.sender, amount);

        emit BurnDiamond(amount);
    }

    function swapDiamondToUsdt(uint256 amount) external {
        require(amount > 0, "Diamond: amount should be greater than the zero");
        require(
            balanceOf(msg.sender) >= amount,
            "Diamond: Insufficient balance of user"
        );
        require(
            IERC20(usdt).balanceOf(address(this)) >= amount,
            "Diamond: Insufficient balance of contact"
        );

        _burn(msg.sender, amount);
        uint256 usdtAmount = (amount * tokenPriceDecimal) / tokenPrice;
        IERC20(usdt).transfer(msg.sender, usdtAmount);

        emit SwapDiamondToUsdt(msg.sender, amount, usdtAmount);
    }

    /**
     * @param _tokenPrice token price
     * @param _tokenPriceDecimal token price
     **/
    function setTokenPrice(
        uint256 _tokenPrice,
        uint256 _tokenPriceDecimal
    ) external onlyOwner {
        require(
            _tokenPrice > 0,
            "Diamond: token price should be geater than the zero"
        );
        require(
            _tokenPriceDecimal > 0,
            "Diamond: token price decimal should be geater than the zero"
        );

        tokenPrice = _tokenPrice;
        tokenPriceDecimal = _tokenPriceDecimal;

        emit SetTokenPrice(_tokenPrice, _tokenPriceDecimal);
    }

    /**
     * @param  toAddress address to receive fee
     * @param amount withdraw native token amount
     **/
    function withdrawNative(
        address payable toAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            toAddress != address(0),
            "Diamond: The zero address should not be the fee address"
        );

        require(amount > 0, "Diamond: amount should be greater than the zero");

        uint256 balance = address(this).balance;

        require(amount <= balance, "Diamond: No balance to withdraw");

        (bool success, ) = toAddress.call{value: balance}("");
        require(success, "Diamond: Withdraw failed");

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
            "Diamond: token address should not be the zero address"
        );
        require(
            toAddress != address(0),
            "Diamond: to address should not be the zero address"
        );
        require(amount > 0, "Diamond: amount should be greater than the zero");

        uint256 balance = IERC20(token).balanceOf(address(this));

        require(amount <= balance, "Diamond: No balance to withdraw");

        IERC20(token).transfer(toAddress, amount);

        emit Withdraw(token, toAddress, amount);
    }
}
