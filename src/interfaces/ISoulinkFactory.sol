pragma solidity ^0.8.13;
interface ISoulinkFactory {    

    function createSoulink(string memory _description) external returns (address);

    function upgradeSoulinkImpl(address _newImpl, string memory _version) external returns (address);

    function getSoulink(string memory _description) external view returns(address);

    event AddSoulink(bytes32 indexed uid, address nftAddress, uint id, address impl);

    event SetSoulinkImpl(address _newSLImpl);

    event SetAdmin(address _newAdmin);

}