// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '../libraries/Math.sol';
import { IERC20 } from "./interface/IERC20.sol";
import "hardhat/console.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    // Implement core logic here
    address private immutable owner;
    address private immutable addressA;
    address private immutable addressB;

    uint private reserve0;
    uint private reserve1;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    constructor(address _addressA, address _addressB) ERC20("HulkToken","Hulk") {
        if (_addressA == address(0x0)) {
            revert("SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        }

        if (_addressB == address(0x0)) {
            revert("SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        }

        if (_addressA == _addressB) {
            revert("SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");
        }

        addressA = _addressA;
        addressB = _addressB;
        
        owner = msg.sender;
    }
    
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external override returns (uint256 amountOut){
        return 123;
    }

    function addLiquidity(uint256 amountAIn, uint256 amountBIn) external override
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        ) {

        if (amountAIn <= 0) {
            revert("SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        }
        if (amountBIn <= 0) {
            revert("SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        }
      
        ERC20(addressA).approve(address(this),amountAIn);
        ERC20(addressB).approve(address(this),amountBIn);

        ERC20(addressA).transferFrom(msg.sender, address(this),amountAIn);
        ERC20(addressB).transferFrom(msg.sender, address(this),amountBIn);
        

        reserve0 += reserve0 + amountAIn;
        reserve1 += amountBIn;

        uint liquidity = Math.sqrt( amountAIn* amountBIn );

        emit AddLiquidity(msg.sender, amountAIn, amountBIn, liquidity);
        
        return (amountAIn,amountBIn,liquidity);
    }


    function removeLiquidity(uint256 liquidity) external virtual returns (uint256 amountA, uint256 amountB) {
        return (1,2);
    }

    function getReserves() external view override returns (uint256 reserveA, uint256 reserveB) {

        return(reserve0 ,reserve1 );
    }   

    function getTokenA() external view override returns (address tokenA) {
        return addressA;
    }

    function getTokenB() external view override returns (address tokenB) {
        return addressB;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }
}
