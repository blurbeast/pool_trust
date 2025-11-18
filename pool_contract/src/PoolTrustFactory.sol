
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

import {PoolTrustFactoryState} from "./PoolFactoryState.sol";
import {Checkers} from "./objects/Checkers.sol";

contract PoolTrustFactory is PoolTrustFactoryState {
    

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