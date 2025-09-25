// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "security/access/AccessControl.sol";
import "./brevis/BrevisProofApp.sol";

contract BrevisKaito is AccessControl, BrevisProofApp {
    uint64 public constant SCALE = 100; // so multiplier 1.5 becomes 150

    event CampaignAdded(uint64 indexed campId, uint64 multiplier);
    event MappingAdded(uint64 indexed campId, address kaitoAddr, bytes32 aHash);
    event MappingDeleted(
        uint64 indexed campId,
        address kaitoAddr,
        bytes32 aHash
    );

    struct Campaign {
        uint64 multiplier;
        mapping(address => bytes32) kAddrToHash;
        mapping(bytes32 => address) hashTokAddr;
        // mapping(address => uint64) mOverride;
    }

    mapping(uint64 => Campaign) public campaigns;

    bytes32 vkHash;

    // d2618ddac653714fc88be7cbbf2131886e3f5749adaad9b80fd4d696df11648e
    bytes32 public constant REWARD_UPDATER_ROLE =
        keccak256("kaddr_map_updater");

    function addCampaign(uint64 campId, uint64 multiplier) external onlyOwner {
        require(multiplier > 100, "multiplier must be greater than 100");
        campaigns[campId].multiplier = multiplier;
        emit CampaignAdded(campId, multiplier);
    }

    function delMapping(uint64 campId, address kaitoAddr) external onlyOwner {
        bytes32 h = campaigns[campId].kAddrToHash[kaitoAddr];
        delete campaigns[campId].kAddrToHash[kaitoAddr];
        delete campaigns[campId].hashTokAddr[h];
        emit MappingDeleted(campId, kaitoAddr, h);
    }

    function getMultipliersBatch(
        address[] calldata kaitoAddresses,
        uint64 campaignId
    ) external view returns (uint64[] memory) {
        uint64[] memory ret = new uint64[](kaitoAddresses.length);
        for (uint256 i = 0; i < kaitoAddresses.length; i++) {
            if (
                campaigns[campaignId].kAddrToHash[kaitoAddresses[i]] !=
                bytes32(0)
            ) {
                ret[i] = campaigns[campaignId].multiplier;
            } else {
                ret[i] = SCALE;
            }
        }
        return ret;
    }

    // parse zk output and update
    function addkAddrMapping(
        bytes calldata proof,
        bytes calldata appOutput
    ) external onlyRole(REWARD_UPDATER_ROLE) {
        _checkBrevisProof(_getDataChainId(), proof, appOutput, vkHash);
        uint64 campId = uint64(bytes8(appOutput[0:8]));
        address kAddr = address(bytes20(appOutput[8:28]));
        bytes32 aHash = bytes32(appOutput[28:60]);
        _addkAddrMapping(campId, kAddr, aHash);
    }

    function _addkAddrMapping(
        uint64 campId,
        address kAddr,
        bytes32 aHash
    ) internal {
        require(
            campaigns[campId].kAddrToHash[kAddr] == bytes32(0),
            "addr mapping already exists"
        );
        require(
            campaigns[campId].hashTokAddr[aHash] == address(0),
            "hash mapping already exists"
        );
        campaigns[campId].kAddrToHash[kAddr] = aHash;
        campaigns[campId].hashTokAddr[aHash] = kAddr;
        emit MappingAdded(campId, kAddr, aHash);
    }

    function _getDataChainId() internal view virtual returns (uint64) {}
}
