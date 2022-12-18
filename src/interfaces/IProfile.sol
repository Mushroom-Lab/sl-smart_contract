pragma solidity ^0.8.13;
interface IProfile {    

    function isValidSignature(bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) external returns (bool);

    function setDelegatee(address) external returns(address);

    function delegatee() external view returns(address);

    // compatible for EOA and Contract Address
    // A variant based on EIP2612 delegation on setDelegatee
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);
    //owner may change so nonces for permit are recorded per owner address
    function nonces(address) external view returns (uint);
    
    function permit(address, address, uint8 v, bytes32 r, bytes32 s) external;
}