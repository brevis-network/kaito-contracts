// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {BrevisKaito} from "../src/BrevisKaito.sol";

contract Deploy is Script {
    function run() public {
        vm.startBroadcast();
        BrevisKaito c = new BrevisKaito(0xe1c0D379629601Ee0a84e80428EB2a73b6C2e460, 0x03dD17C6B16F391e1efB199725609bFbDc9C7442);
        console.log("BrevisKaito contract deployed at ", address(c));
        vm.stopBroadcast();
    }
}