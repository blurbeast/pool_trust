


// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;


library PoolTrustObj {

    struct PoolInfo {
        address creator;
        bytes32 poolName;
        address token;
        address poolContractAddress;
    }
}