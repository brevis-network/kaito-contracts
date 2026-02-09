# Brevis Campaign for Kaito Leaderboard

Privacy-preserving ZK attestation for Kaito leaderboard using Brevis proof verification.

## Overview

This project implements a Brevis-based campaign system for the Kaito leaderboard that enables:

- **Zero-knowledge address mapping**: Map Kaito wallet addresses to attestation hashes without exposing sensitive data on-chain
- **Campaign multipliers**: Support configurable multipliers for leaderboard rankings
- **Privacy preservation**: Validate mappings through ZK proofs while maintaining user privacy

## Architecture

### Core Components

| Component | Description |
|-----------|-------------|
| `BrevisKaito.sol` | Main contract handling campaigns and address mappings |
| `BrevisProofApp.sol` | Abstract base contract for Brevis proof verification |
| `IBrevisProof.sol` | Interface for Brevis proof contract |

### Key Concepts

- **Campaigns**: Each campaign has a unique ID and a configurable multiplier (minimum 101, representing 1.01x)
- **Address Mappings**: Bidirectional mappings between Kaito addresses and attestation hashes
- **ZK Proof Verification**: Validates address mappings through Brevis ZK proofs before updating state

## Contract Interface

### Owner Functions

```solidity
// Create a new campaign with a specific multiplier
function addCampaign(uint64 campId, uint64 multiplier) external onlyOwner

// Delete an existing address mapping
function delMapping(uint64 campId, address kaitoAddr) external onlyOwner
```

### External Functions

```solidity
// Submit address mapping via ZK proof verification
function addkAddrMapping(bytes calldata proof, bytes calldata appOutput) external

// Batch query multipliers for multiple addresses
function getMultipliersBatch(address[] calldata kaitoAddresses, uint64 campaignId) external view returns (uint64[] memory)
```

### Data Structures

```solidity
struct Campaign {
    uint64 multiplier;
    mapping(address => bytes32) kAddrToHash;      // address -> hash mapping
    mapping(bytes32 => address) hashTokAddr;      // hash -> address mapping
}
```

## Building

```bash
# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test
```

## Technology Stack

- **Framework**: [Foundry](https://book.getfoundry.sh/)
- **Language**: Solidity ^0.8.26
- **ZKP Integration**: [Brevis](https://www.brevis.network/)
- **Access Control**: OpenZeppelin AccessControl

## License

MIT