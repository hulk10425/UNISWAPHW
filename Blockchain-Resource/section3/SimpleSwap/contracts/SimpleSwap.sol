// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    // Implement core logic here
    address private immutable owner;


    // constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    //     owner = msg.sender;
    // }
    constructor(address _addressA, address _addressB) ERC20("HulkToken","Hulk") {
        if (_addressA == address(0x0)) {
            revert("SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        }
        
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
            return (1,2,3);
    }


    function removeLiquidity(uint256 liquidity) external virtual returns (uint256 amountA, uint256 amountB) {
        return (1,2);
    }


    function getReserves() external view override returns (uint256 reserveA, uint256 reserveB) {
        return(1,2);
    }   

    function getTokenA() external view override returns (address tokenA) {
        return address(this);
    }

    function getTokenB() external view override returns (address tokenB) {
        return address(this);
    }
}
