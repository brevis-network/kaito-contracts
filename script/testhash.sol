// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";

contract Deploy is Script {
    function run() public {
        bytes memory m = hex"68d62345b88f061d0c5ae50cd45bc62b893b7eafd6471d884e0f61b490646729c4cfedc4ed26c778785a7de2550c00c40e31e6e2a706d40e";
        console.logBytes32(keccak256(m));
    }
}