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

        if (tokenIn == address(0x0)) {
            revert("SimpleSwap: INVALID_TOKEN_IN");
        }
        if (tokenOut == address(0x0)) {
            revert("SimpleSwap: INVALID_TOKEN_OUT");
        }

        if (tokenIn == tokenOut) {
            revert("SimpleSwap: IDENTICAL_ADDRESS");
        }

        if (amountIn == 0) {
            revert("SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        }

        if (amountIn == 1) {
            revert("SimpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");
        }

        uint k = reserve0 * reserve1;
        if (tokenIn == addressA) {
            uint newReserve0 = reserve0 + amountIn;
            uint newReserve1 = k / newReserve0;
            uint diffReserve1 = reserve1 - newReserve1;
            if (diffReserve1 == 0) {
                revert("SimpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");
            }

            reserve0 = newReserve0;
            reserve1 = newReserve1;
            actualTransferA(amountIn);
            _safeTransfer(addressB, msg.sender, diffReserve1);

            emit Swap(msg.sender,addressA, addressB, amountIn,diffReserve1);
            return diffReserve1;
        } else {
            uint newReserve1 = reserve1 + amountIn;
            uint newReserve0 = k / newReserve1;
            uint diffReserve0 = reserve0 - newReserve0;
            if (diffReserve0 == 0) {
                revert("SimpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");
            }
            reserve0 = newReserve0;
            reserve1 = newReserve1;
            actualTransferB(amountIn);
            _safeTransfer(addressA, msg.sender, diffReserve0);

             emit Swap(msg.sender,addressB, addressA, amountIn,diffReserve0);

            return diffReserve0;
        }

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

            _mint(msg.sender, liquidity);
            emit AddLiquidity(msg.sender, amountAIn, amountBIn, liquidity);
            emit Transfer(address(0x0),msg.sender,liquidity);
            return (amountAIn,amountBIn,liquidity);
        }

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
            _mint(msg.sender, liquidity);
            emit Transfer(address(0x0),msg.sender,liquidity);
            emit AddLiquidity(msg.sender, amountAIn, actualAmountB, liquidity);
            return (amountAIn,actualAmountB,liquidity);

        } else if ((reserve0 * adjustAmountBIn) < (reserve1 * adjustAmountAIn)) {
        //等於A多給，算正確可以算入的A
            uint actualAmountA = amountBIn * (reserve0) / (reserve1);

            actualTransferA(actualAmountA);
            actualTransferB(amountBIn);

            liquidity = Math.sqrt( actualAmountA* amountBIn );
            reserve0 += actualAmountA;
            reserve1 += amountBIn;
            _mint(msg.sender, liquidity);
            emit Transfer(address(0x0),msg.sender,liquidity);
            emit AddLiquidity(msg.sender, actualAmountA, amountBIn, liquidity);
            return (actualAmountA,amountBIn,liquidity);
        } else {

            actualTransferA(amountAIn);
            actualTransferB(amountBIn);
            
            liquidity = Math.sqrt( amountAIn* amountBIn );
            reserve0 += amountAIn;
            reserve1 += amountBIn;
            _mint(msg.sender, liquidity);
            emit Transfer(address(0x0),msg.sender,liquidity);
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
        if (liquidity <= 0) {
            revert("SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");
        }

        uint totalLP = totalSupply();

        uint removeReserve0 = liquidity * reserve0 / totalLP;
        uint removeReserve1 = liquidity * reserve1 / totalLP;


        reserve0 -= removeReserve0;
        reserve1 -= removeReserve1;

        _safeTransfer(addressA, msg.sender, removeReserve0);
        _safeTransfer(addressB, msg.sender, removeReserve1);
        _burn(msg.sender,liquidity);
        emit Transfer(address(this),address(0x0),liquidity);
        emit RemoveLiquidity(msg.sender, removeReserve0,removeReserve1,liquidity);
        return (removeReserve0,removeReserve1);
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
