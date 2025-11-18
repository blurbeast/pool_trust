

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

library Checkers {

    function revertIfAddressNotSame(address left, address right) internal pure {
        if(left != right) revert();
    }
}