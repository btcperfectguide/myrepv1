// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.9;

import "../BaseComponentUpgradeable.sol";
import "../../errors/GeneralErrors.sol";

contract ChainSettingsRegistry is BaseComponentUpgradeable {
    string public constant version = "0.1.0";
    uint256 constant MAX_CHAIN_IDS_PER_UPDATE = 5;

    uint256 private _supportedChainIdsAmount;
    mapping(uint256 => bool) private _chainIdSupported;
    mapping(uint256 => string) private _chainIdMetadata;
    // chainId => metadata => uniqueness
    mapping(uint256 => mapping(bytes32 => bool)) private _chainIdMetadataUniqueness;

    error ChainIdsAmountExceeded(uint256 exceedingAmount);
    error ChainIdAlreadySupported(uint256 chainId);
    error ChainIdUnsupported(uint256 chainId);
    error MetadataNotUnique(bytes32 hash);

    event ChainSettingsUpdated(uint256 chainId, string metadata);
    event ChainIdSupported(uint256 chainId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address forwarder) initializer ForwardedContext(forwarder) {}

    /**
     * @notice Initializer method, access point to initialize inheritance tree.
     * @param __manager address of AccessManager.
     */
    function initialize(
        address __manager
    ) public initializer {
        __BaseComponentUpgradeable_init(__manager);
    }

    /**
     * @notice Method to update which chains are supported by the network.
     * @dev Method implements a cap to how many chain ids can be updated
     * at once, to prevent looping through too many chain ids.
     * The cap is also a lower number, since it is expected that the
     * supported chains will not change often.
     * @param chainIds Array of chain ids that are to be supported.
     * @param metadata IPFS pointer to chain id's metadata JSON.
     */
    function updateSupportedChains(uint256[] calldata chainIds, string calldata metadata) external onlyRole(CHAIN_SETTINGS_ROLE) {
        if (chainIds.length == 0) revert EmptyArray("chainIds");
        if (chainIds.length > MAX_CHAIN_IDS_PER_UPDATE) revert ChainIdsAmountExceeded(chainIds.length - MAX_CHAIN_IDS_PER_UPDATE);

        for(uint256 i = 0; i < chainIds.length; i++) {
            if (_chainIdSupported[chainIds[i]]) revert ChainIdAlreadySupported(chainIds[i]);
            _updateSupportedChainIds(chainIds[i]);
            _chainSettingsUpdate(chainIds[i], metadata);
        }

        _supportedChainIdsAmount += chainIds.length;
    }

    /**
     * @notice Method to update a chain's settings/metadata.
     * @dev Checks to confirm there aren't more chains attempting to be updated
     * than there are supported chains. Also checks to confirm that the chains
     * attempting to be updated are supported.
     * @param chainIds Array of chain ids that are to have their settings updated.
     * @param metadata IPFS pointer to chain id's metadata JSON.
     */
    function updateChainSettings(uint256[] calldata chainIds, string calldata metadata) external onlyRole(CHAIN_SETTINGS_ROLE) {
        if (chainIds.length == 0) revert EmptyArray("chainIds");
        if (chainIds.length > _supportedChainIdsAmount) revert ChainIdsAmountExceeded(chainIds.length - _supportedChainIdsAmount);

        for(uint256 i = 0; i < chainIds.length; i++) {
            if (!_chainIdSupported[chainIds[i]]) revert ChainIdUnsupported(chainIds[i]);
            _chainSettingsUpdate(chainIds[i], metadata);
        }
    }

    /**
     * @notice Logic for chain metadata update.
     * @dev Checks chain id's metadata uniqueness and updates chain's metadata.
     * @param chainId Chain id that is to have its settings updated.
     * @param metadata IPFS pointer to chain id's metadata JSON.
     */
    function _chainSettingsUpdate(uint256 chainId, string calldata metadata) private {
        bytes32 newHash = keccak256(bytes(metadata));
        if (_chainIdMetadataUniqueness[chainId][newHash]) revert MetadataNotUnique(newHash);
        bytes32 oldHash = keccak256(bytes(_chainIdMetadata[chainId]));
        _chainIdMetadataUniqueness[chainId][newHash] = true;
        _chainIdMetadataUniqueness[chainId][oldHash] = false;

        _chainIdMetadata[chainId] = metadata;
        emit ChainSettingsUpdated(chainId, metadata);
    }

    function _updateSupportedChainIds(uint256 chainId) private {
        _chainIdSupported[chainId] = true;
        emit ChainIdSupported(chainId);
    }

    /**
     * @notice Getter for metadata for the `chainId`.
     */
    function getChainIdSettings(uint256 chainId) public view returns (string memory) {
        return _chainIdMetadata[chainId];
    }

    /**
     * @notice Getter for the current amount of supported chains.
     */
    function getSupportedChainIdsAmount() public view returns (uint256) {
        return _supportedChainIdsAmount;
    }

    /**
     * @notice Checks if chainId is currently supported.
     * @param chainId Chain id of the specific chain.
     * @return true if chain is supported, false otherwise.
     */
    function isChainIdSupported(uint256 chainId) public view returns (bool) {
        return _chainIdSupported[chainId];
    }

    /**
     *  50
     * - 1 _supportedChainIdsAmount;
     * - 1 _chainIdSupported;
     * - 1 _chainIdMetadata;
     * - 1 _chainIdMetadataUniqueness;
     * --------------------------
     *  46 __gap
     */
    uint256[46] private __gap;
}