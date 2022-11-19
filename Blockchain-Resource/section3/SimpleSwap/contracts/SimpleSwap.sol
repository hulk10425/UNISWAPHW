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
        //檢查 _addressA 是否為空地址
        if (_addressA == address(0x0)) {
            revert("SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        }
        //檢查 _addressB 是否為空地址
        if (_addressB == address(0x0)) {
            revert("SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        }
        //檢查 _addressA 和 _addressB 是否為相同地址
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
        // 檢查 tokenIn 是否為空地址
        if (tokenIn == address(0x0)) {
            revert("SimpleSwap: INVALID_TOKEN_IN");
        }
        // 檢查 tokenOut 是否為空地址
        if (tokenOut == address(0x0)) {
            revert("SimpleSwap: INVALID_TOKEN_OUT");
        }
        // 檢查 tokenIn 和 tokenOut 是否為相同地址
        if (tokenIn == tokenOut) {
            revert("SimpleSwap: IDENTICAL_ADDRESS");
        }
        // 檢查 amountIn 是否為 0
        if (amountIn == 0) {
            revert("SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        }
        // 檢查 amountIn 是否 過於小
        if (amountIn <= 1) {
            revert("SimpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");
        }

        uint k = reserve0 * reserve1;

        // 輸入AToken 想兌換BToken
        if (tokenIn == addressA) {
            // 透過 x * y = k ，算出新的 A、B Token
            uint newReserve0 = reserve0 + amountIn;
            uint newReserve1 = k / newReserve0;
            uint diffReserve1 = reserve1 - newReserve1;
            
            reserve0 = newReserve0;
            reserve1 = newReserve1;
            // msg.sender 轉入 A Token to this address
            actualTransferA(amountIn);
            // this address 轉出 B Token to msg.sender
            _safeTransfer(addressB, msg.sender, diffReserve1);
            //紀錄 swap 事件
            emit Swap(msg.sender,addressA, addressB, amountIn,diffReserve1);
            return diffReserve1;
        } else {
            uint newReserve1 = reserve1 + amountIn;
            uint newReserve0 = k / newReserve1;
            uint diffReserve0 = reserve0 - newReserve0;

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
        //檢查 amountAIn 的數量
        if (amountAIn <= 0) {
            revert("SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        }
        //檢查 amountBIn 的數量
        if (amountBIn <= 0) {
            revert("SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        }
    
        // 如果是 完全沒有流動性時，初次加入流動性
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
        
        // 不是第一次加入流動性，且B Token 多給的狀況
        if ((reserve0 * adjustAmountBIn) > (reserve1 * adjustAmountAIn)){
            // 計算出真正能被計入流動性的 B Token 數量
            uint actualAmountB = amountAIn * reserve1 / reserve0;
            // msg.sender 轉入 AToken
            actualTransferA(amountAIn);
            // msg.sender 轉入 BToken
            actualTransferB(actualAmountB);
            // 算出 新增的流動性
            liquidity = Math.sqrt( amountAIn* actualAmountB );
            reserve0 += amountAIn;
            reserve1 += actualAmountB;
            _mint(msg.sender, liquidity);
            emit Transfer(address(0x0),msg.sender,liquidity);
            emit AddLiquidity(msg.sender, amountAIn, actualAmountB, liquidity);
            return (amountAIn,actualAmountB,liquidity);

        // 不是第一次加入流動性，且A Token 多給的狀況
        } else if ((reserve0 * adjustAmountBIn) < (reserve1 * adjustAmountAIn)) {
       
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
            // 不是第一次加入流動性，且A 、B Token 比例合乎池內比例
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
