// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view / pure functions

pragma solidity ^0.8.18;

/*
* @title DSCEngine
* @author @Ali Talal
* The system is designed to be as minimal as posible, 
  and have the tokens maintain a 1 token == $1 peg..
* This stablecoin has the properties:
* - Exogenous collateral
* - Algorithmic stablecoin minting
* - Relative Stability: Pegged to USD
*
*Our DSC system should always be "overcollateralized". 
At no point, should the value of all colateral <= the $ backed value of all the DSC.
*
* It is similar to DAI if DAI had no governance, no fees, and was only backed by WETH and WBTC.
* @notice This contract is the core of the DSC System. It handles all the logic for
*minting and redeeming DSC, as well as depositing & withdrawing colateral.
*
*@notice This contract is VERY loosely based on the MakerDAO DSS (DAI) system
*/

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DSCEngine is ReentrancyGuard {

    //////////////
    // Errors   //
    //////////////
    error DSCEngine__NeedMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesLengthsMustBeTheSame();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TransferFailed();


    ///////////////////////
    // State Variables   //
    ///////////////////////
    mapping(address token => address priceFeed) private s_priceFeeds; //tokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    DecentralizedStableCoin private immutable i_dsc;



    //////////////
    // Events   //
    //////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    //////////////
    // Modifiers//
    //////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__TokenNotAllowed();
        }
        _;
    }
    

    //////////////
    // Functions//
    //////////////

    constructor(
        adress[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dscAddress
    ) {
        // USD price feeds
        if (tokenAddresses.length != priceFeddAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesLengthsMustBeTheSame();
        }
        // for example ETH/USD, BTC/USD, etc.
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    ///////////////////////
    // External Functions//
    ///////////////////////
    function depositCollateralAndMintDSC() external {}

    /*
    * @notice follows CEI pattern
    * @param tokenCollateralAddress The address of the token to deposit as collateral
    * @param amountCollateral The amount of collateral to deposit
    */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) 
        external 
        moreThanZero(amountCollateral) 
        isAllowedToken(tokenCollateralAddress) 
        nonReentrant()
        {
            s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
            emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
            bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
            if (!success) {
                revert DSCEngine__TransferFailed();
            }
        }

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}


    function mintDSC() external {}


    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}

}