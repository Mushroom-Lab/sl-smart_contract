pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

// ____   ___  _   _ _     ___ _   _ _  __
// / ___| / _ \| | | | |   |_ _| \ | | |/ /
// \___ \| | | | | | | |    | ||  \| | ' / 
//  ___) | |_| | |_| | |___ | || |\  | . \ 
// |____/ \___/ \___/|_____|___|_| \_|_|\_\


///     ###############################################
///     Soulink Profile Specification
///
///     ###############################################
///

contract Profile is Ownable {
    string public constant name = "SoulinkProfile";
    // keccak256("Permit(address owner,address delegatee,uint256 nonce)");
    bytes32 public constant PERMIT_TYPEHASH = 0xb386f97c45a5e4526fa8514e4421b36a232e2dfcf252547ffc9d886063bd3842;

    bytes32 public immutable DOMAIN_SEPARATOR;
    // nonces to avoid replay on permit (profile can transfer ownership)
    mapping(address => uint) public nonces;

    address public delegatee;

    event NewDelegation(address _newDelegatee);

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function setDelegatee(address _delegatee) onlyOwner external returns(address) 
    {
        delegatee = _delegatee;
        emit NewDelegation(_delegatee);
        return _delegatee;
    }

        // allow change of this mapping using off-chain signature similar to EIP2612
    function permit(address _owner, address _delegatee, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, _owner, _delegatee, nonces[_owner]++))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner(), "INVALID_SIGNATURE");
        delegatee = _delegatee;
    }

    // returns true if owner OR delegatee sign
    function isValidSignature(bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        return 
        ecrecover(messageHash, v, r, s) == owner() || 
        ecrecover(messageHash, v, r, s) == delegatee;
    }

}