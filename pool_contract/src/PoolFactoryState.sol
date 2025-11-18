

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;
import {PoolTrustObj} from "./objects/PoolTrustObj.sol";

abstract contract PoolTrustFactoryState {
    
    address internal owner;
    address internal pendingOwner;
    uint256 internal infoCounter;
    mapping (uint256 => PoolTrustObj.PoolInfo) internal poolInfo;
    uint128 internal acceptedTokenCounter;
    mapping (uint128 => address) internal acceptedTokenAddress;

    constructor() {
        owner = msg.sender;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getInfoCounter() external view returns(uint256) {
        return infoCounter;
    }

    function getAcceptedTokenCounter() external view returns(uint128) {
        return acceptedTokenCounter;
    }

    function getPendingOwner() external view returns(address) {
        return pendingOwner;
    }

    function getPoolInfo(uint256 _poolInfoId) external view returns(PoolTrustObj.PoolInfo memory _poolInfo) {
        _poolInfo = poolInfo[_poolInfoId];
        _poolInfo;
    }

    function getAcceptedToken(uint128 _tokenId) external view returns(address ) {
        return acceptedTokenAddress[_tokenId];
    }
}