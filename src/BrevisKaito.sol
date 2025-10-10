// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "security/access/AccessControl.sol";
import "./brevis/BrevisProofApp.sol";

contract BrevisKaito is AccessControl, BrevisProofApp {
    uint64 public constant SCALE = 100; // so multiplier 1.5 becomes 150
    // d2618ddac653714fc88be7cbbf2131886e3f5749adaad9b80fd4d696df11648e
    bytes32 public constant KADDR_UPDATER_ROLE = keccak256("kaddr_map_updater");

    event CampaignAdded(uint64 indexed campId, uint64 multiplier);
    event MappingAdded(uint64 indexed campId, address kaitoAddr, bytes32 aHash, uint64 multiplier);
    event MappingDeleted(
        uint64 indexed campId,
        address kaitoAddr,
        bytes32 aHash
    );
    event BrevisProofUpdated(address indexed brvproof);

    struct Campaign {
        uint64 multiplier;
        // kaddr <-> hash must be 1:1
        mapping(address => bytes32) kAddrToHash;
        mapping(bytes32 => address) hashTokAddr;
        // if value is 0, use campaign multiplier
        mapping(address => uint64) kAddrToMultiplier;
    }

    mapping(uint64 => Campaign) public campaigns;

    bytes32 public vkHash;

    constructor(address _brvProof, address _kaddr_updater) {
        brevisProof = IBrevisProof(_brvProof);
        _grantRole(KADDR_UPDATER_ROLE, _kaddr_updater);
    }

    // query campaign multipliers for kaito address. eg. multiplier 1.5 will return 150.
    // if user not eligible, return default 100 meaning multiplier is 1.
    function getMultipliersBatch(
        address[] calldata kaitoAddresses,
        uint64 campaignId
    ) external view returns (uint64[] memory) {
        uint64[] memory ret = new uint64[](kaitoAddresses.length);
        for (uint256 i = 0; i < kaitoAddresses.length; i++) {
            if (campaigns[campaignId].multiplier == 0) {
                // unknown campaignId, default SCALE
                ret[i] = SCALE;
                continue;
            }
            // valid campaign, logic: no mapping, return default 100
            // has mapping but kAddrToMultiplier is 0, return campaign multiplier
            // has non-zero kAddrToMultiplier, return it as is
            if (
                campaigns[campaignId].kAddrToHash[kaitoAddresses[i]] == bytes32(0)
            ) {
                ret[i] = SCALE;
            } else if (campaigns[campaignId].kAddrToMultiplier[kaitoAddresses[i]] == 0) {
                ret[i] = campaigns[campaignId].multiplier;
            } else {
                ret[i] = campaigns[campaignId].kAddrToMultiplier[kaitoAddresses[i]];
            }
        }
        return ret;
    }

    function addCampaign(uint64 campId, uint64 multiplier) external onlyOwner {
        require(multiplier > SCALE, "multiplier must be greater than 100");
        campaigns[campId].multiplier = multiplier;
        emit CampaignAdded(campId, multiplier);
    }

    function setVk(bytes32 _vk) external onlyOwner() {
        vkHash = _vk;
    }

    function delMapping(uint64 campId, address kaitoAddr) external onlyOwner {
        bytes32 h = campaigns[campId].kAddrToHash[kaitoAddr];
        delete campaigns[campId].kAddrToHash[kaitoAddr];
        delete campaigns[campId].hashTokAddr[h];
        delete campaigns[campId].kAddrToMultiplier[kaitoAddr];
        emit MappingDeleted(campId, kaitoAddr, h);
    }

    function setBrevisProof(address _brevisProof) external onlyOwner {
        require(_brevisProof != address(0), "invalid BrevisProof address");
        brevisProof = IBrevisProof(_brevisProof);
        emit BrevisProofUpdated(_brevisProof);
    }

    // parse zk output and update. campId:kAddr:aHash:multiplier 8+20+32+8
    // if multiplier value is 0, use campaign's config
    function addkAddrMapping(
        bytes calldata proof,
        bytes calldata appOutput
    ) external onlyRole(KADDR_UPDATER_ROLE) {
        _checkBrevisProof(uint64(block.chainid), proof, appOutput, vkHash);
        require(appOutput.length == 68, "invalid app output length");
        uint64 campId = uint64(bytes8(appOutput[0:8]));
        require(campaigns[campId].multiplier > 0, "invalid campaign id");
        address kAddr = address(bytes20(appOutput[8:28]));
        bytes32 aHash = bytes32(appOutput[28:60]);
        uint64 multiplier = uint64(bytes8(appOutput[60:68]));
        _addkAddrMapping(campId, kAddr, aHash, multiplier);
    }

    function _addkAddrMapping(
        uint64 campId,
        address kAddr,
        bytes32 aHash,
        uint64 multiplier
    ) internal {
        require(
            campaigns[campId].kAddrToHash[kAddr] == bytes32(0) || campaigns[campId].kAddrToHash[kAddr] == aHash,
            "addr mapping already exists"
        );
        require(
            campaigns[campId].hashTokAddr[aHash] == address(0) || campaigns[campId].hashTokAddr[aHash] == kAddr,
            "hash mapping already exists"
        );
        campaigns[campId].kAddrToHash[kAddr] = aHash;
        campaigns[campId].hashTokAddr[aHash] = kAddr;
        if (multiplier != 0) {
            campaigns[campId].kAddrToMultiplier[kAddr] = multiplier;
            emit MappingAdded(campId, kAddr, aHash, multiplier);
        } else { // if 0, use campaign config
            emit MappingAdded(campId, kAddr, aHash, campaigns[campId].multiplier);
        }
    }
}
