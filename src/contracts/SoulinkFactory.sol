pragma solidity ^0.8.13;

import '../interfaces/ISoulinkFactory.sol';
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/proxy/Clones.sol";
import './Soulink.sol';

// ____   ___  _   _ _     ___ _   _ _  __
// / ___| / _ \| | | | |   |_ _| \ | | |/ /
// \___ \| | | | | | | |    | ||  \| | ' / 
//  ___) | |_| | |_| | |___ | || |\  | . \ 
// |____/ \___/ \___/|_____|___|_| \_|_|\_\

/// @title SoulinkFactory
/// @notice Create a proxy that is a ERC1155 NFT series for consensual mint
///     ###############################################
///     SoulinkFactory Specification
///
///     ###############################################
///
contract SoulinkFactory is Ownable {

    address public impl;

    string public implVersion;

    // hash of description (uid) to contract address 
    mapping(bytes32 => address) public soulinkDesc;

    address[] public soulinks;

    uint256 public soulinkLength;

    event AddSoulink(bytes32 indexed uid, address nftAddress, uint id, address impl);

    event SetSoulinkImpl(address _newSLImpl, string _version);

    constructor() Ownable() {
    }

    function upgradeSoulinkImpl(address _newImpl, string memory _version) external onlyOwner returns (address) {
        require(_newImpl != address(0));
        impl = _newImpl;
        implVersion = _version;
        emit SetSoulinkImpl(_newImpl, _version);
        return _newImpl;
    }
        

    function getSoulink(string memory _description) public view returns(address) {
        bytes32 uid = keccak256(abi.encode(_description));
        return soulinkDesc[uid];
    }

    function createSoulink(string memory _description) payable external returns (address) {
        bytes32 uid = keccak256(abi.encode(_description));
        require(soulinkDesc[uid] == address(0), 'SOULINK DESCRIPTION ALREADY EXISTED');
        address instance = Clones.cloneDeterministic(impl, uid);
        require(instance != address(0));
        soulinkLength += 1;
        soulinks.push(instance);
        soulinkDesc[uid] = instance;
        bytes memory _dataPayload = abi.encodeWithSignature("initialize(string)", _description);
        bool success;
        (success, ) = instance.call{value: msg.value}(_dataPayload);
        require(success, "SOULINK INITIALIZE FAILS");
        emit AddSoulink(uid, instance, SoulinkLength, impl);
        return instance;
    }

    
}