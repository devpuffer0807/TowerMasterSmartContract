// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Coupons is ERC721Enumerable, Ownable(msg.sender) {
    using Counters for Counters.Counter;

    // token counter
    Counters.Counter private _tokenIds;

    // NFT Name
    string public constant TOKEN_NAME = "Coupons";
    // NFT Symbol
    string public constant TOKEN_SYMBOL = "Coupons";

    // NFT toke `baseURI`
    string public baseURI;

    address public usdt;

    /**
     * @dev token price
     **/
    uint256 public tokenPrice;

    /**
     * @dev token price
     **/
    uint256 public tokenPriceDecimal;

    /**
     *  Emitted when `_tokenBaseURI` updated
     */
    event BaseURI(string bseURI);

    event SetTokenPrice(uint256 tokenPrice, uint256 tokenPriceDecimal);

    event MintDiamond(address indexed to, uint256 amount);

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

    constructor(address _usdt) ERC721(TOKEN_NAME, TOKEN_SYMBOL) {
        require(
            _usdt != address(0),
            "Coupons: address should not be the zero address"
        );

        usdt = _usdt;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mintCoupons(uint256 amount) external {
        require(amount > 0, "Coupons: amount should be greater than the zero");
        require(
            tokenPrice > 0,
            "Coupons: token price should be greater than the zero"
        );

        uint256 usdtAMount = ((amount * 10**18 * tokenPrice)) /
            tokenPriceDecimal;

        require(
            IERC20(usdt).allowance(msg.sender, address(this)) >= usdtAMount,
            "Coupons: usdt allowance error"
        );

        IERC20(usdt).transferFrom(msg.sender, address(this), usdtAMount);

        for (uint256 i; i < amount; i++) {
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }

        emit MintDiamond(msg.sender, amount);
    }

    /**
     *  set `baseURI`
     */
    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
        emit BaseURI(uri);
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
            "Coupons: token price should be geater than the zero"
        );
        require(
            _tokenPriceDecimal > 0,
            "Coupons: token price decimal should be geater than the zero"
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
            "Coupons: The zero address should not be the fee address"
        );

        require(amount > 0, "Coupons: amount should be greater than the zero");

        uint256 balance = address(this).balance;

        require(amount <= balance, "Coupons: No balance to withdraw");

        (bool success, ) = toAddress.call{value: balance}("");
        require(success, "Coupons: Withdraw failed");

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
            "Coupons: token address should not be the zero address"
        );
        require(
            toAddress != address(0),
            "Coupons: to address should not be the zero address"
        );
        require(amount > 0, "Coupons: amount should be greater than the zero");

        uint256 balance = IERC20(token).balanceOf(address(this));

        require(amount <= balance, "Coupons: No balance to withdraw");

        IERC20(token).transfer(toAddress, amount);

        emit Withdraw(token, toAddress, amount);
    }
}
