

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;
import {PoolTrustObj} from "./objects/PoolTrustObj.sol";
import {Checkers} from "./objects/Checkers.sol";

abstract contract PoolTrustFactoryState {
    
    address private owner;
    address private pendingOwner;
    uint256 internal infoCounter;
    mapping (uint256 => PoolTrustObj.PoolInfo) internal poolInfo;

    constructor() {
        owner = msg.sender;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getPendingOwner() external view returns(address) {
        return pendingOwner;
    }

    function setNewOwner(address newOwner) external returns(bool) {
        Checkers.revertIfAddressNotSame(msg.sender, owner);
        pendingOwner = newOwner;
        return true;
    }

    function confirmNewOwner() external returns(bool) {
        Checkers.revertIfAddressNotSame(msg.sender, pendingOwner);
        owner = msg.sender;
        pendingOwner = address(0);
        return true;
    }
}