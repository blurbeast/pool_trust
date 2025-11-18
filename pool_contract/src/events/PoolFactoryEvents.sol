// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;


library FactoryEvents {

    event PoolCreated(
        uint256 indexed poolId,
        address indexed poolAddress,
        address indexed creator,
        string name,
        uint256 target,
        string category,
        address tokenAddress
    );
}