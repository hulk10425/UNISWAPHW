// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '../libraries/Math.sol';

contract SimpleSwap is ISimpleSwap, ERC20 {
    // Implement core logic here
    address private immutable owner;
    address private immutable addressA;
    address private immutable addressB;

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

        if (amountA <= 0) {
            revert("SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        }
        if (amountB <= 0) {
            revert("SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        }

        // uint liquidity = sqrt(amountA.mul(amountB));
        // event AddLiquidity(address indexed sender, uint256 amountA, uint256 amountB, uint256 liquidity);
        // emit AddLiquidity(sender, amountA, amountB, liquidity);


                //             await expect(simpleSwap.connect(maker).addLiquidity(amountA, amountB)).to.revertedWith(
                //     "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT",
                // )
            return (1,2,3);
    }


    function removeLiquidity(uint256 liquidity) external virtual returns (uint256 amountA, uint256 amountB) {
        return (1,2);
    }


    function getReserves() external view override returns (uint256 reserveA, uint256 reserveB) {
        return(0,0);
    }   

    function getTokenA() external view override returns (address tokenA) {
        return addressA;
    }

    function getTokenB() external view override returns (address tokenB) {
        return addressB;
    }
}
