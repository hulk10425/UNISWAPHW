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
        uint liquidity;
        if (amountAIn <= 0) {
            revert("SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        }
        if (amountBIn <= 0) {
            revert("SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        }
      


        if (reserve0 == 0 || reserve1 == 0) {
            actualTransferA(amountAIn);
            actualTransferB(amountBIn);

            reserve0 += reserve0 + amountAIn;
            reserve1 += amountBIn;
            liquidity = Math.sqrt( amountAIn* amountBIn );
            emit AddLiquidity(msg.sender, amountAIn, amountBIn, liquidity);
            return (amountAIn,amountBIn,liquidity);
        }
        
        // uint adjustReserve0 = reserve0 / 10 ** ERC20(addressA).decimals();
        // uint adjustReserve1 = reserve1 / 10 ** ERC20(addressB).decimals();

        uint adjustAmountAIn = amountAIn / 10 ** ERC20(addressA).decimals();
        uint adjustAmountBIn = amountBIn / 10 ** ERC20(addressB).decimals();
        
        if ((reserve0 * adjustAmountBIn) > (reserve1 * adjustAmountAIn)){
        //等於B多給，算正確可以算入的B

            uint actualAmountB = amountAIn * reserve1 / reserve0;
            
            actualTransferA(amountAIn);
            actualTransferB(actualAmountB);

            liquidity = Math.sqrt( amountAIn* actualAmountB );
            reserve0 += amountAIn;
            reserve1 += actualAmountB;

            emit AddLiquidity(msg.sender, amountAIn, actualAmountB, liquidity);
            return (amountAIn,actualAmountB,liquidity);

        } else if ((reserve0 * amountBIn) < (reserve1 * amountAIn)) {
        //等於A多給，算正確可以算入的A
            console.log("A more");
            uint actualAmountA = amountBIn * (reserve0 * reserve1);

            actualTransferA(actualAmountA);
            actualTransferB(amountBIn);

            liquidity = Math.sqrt( actualAmountA* amountBIn );
            reserve0 += actualAmountA;
            reserve1 += amountBIn;
            emit AddLiquidity(msg.sender, actualAmountA, amountBIn, liquidity);
            return (actualAmountA,amountBIn,liquidity);
        } else {
            actualTransferA(amountAIn);
            actualTransferB(amountBIn);
            
            liquidity = Math.sqrt( amountAIn* amountBIn );
            reserve0 += amountAIn;
            reserve1 += amountBIn;
            emit AddLiquidity(msg.sender, amountAIn, amountBIn, liquidity);
            return (amountAIn,amountBIn,liquidity);
        }
    }

    function actualTransferA(uint amount) internal {
        ERC20(addressA).approve(address(this),amount);
        ERC20(addressA).transferFrom(msg.sender, address(this),amount);
    }

    function actualTransferB(uint amount) internal {
        ERC20(addressB).approve(address(this),amount);
        ERC20(addressB).transferFrom(msg.sender, address(this),amount);
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
