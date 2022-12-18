

pragma solidity ^0.8.13;
interface ISoulink {
    // description is hashed into uid to form a unique soulink in factory
    function description() external returns (string memory);
    // uid is a hash of description
    function uid() external returns (bytes32);

    function getMessageHash(address[] memory, string memory) external view returns (bytes32);

    function tokenIdCounter() external view returns (uint256);

    function isHashUsed(bytes32, address) external view returns(bool);

    function p2pWhitelist(uint256, address) external view returns(bool);

    function tokenToCid(uint256) external view returns (string memory);

    function initialize(string memory) external;

    function initilizeNFT(bytes memory, address[] memory, string memory) external returns(bool);
    
    // ERC1155
    function balanceOf(address account, uint256 id) external view returns (uint256);
    // Owners can mint and burn the NFT back and fro as they wish
    function mint(uint256, address) external;

    function burn(uint256) external;

    event InitializeTokenAddress(uint256 indexed _tokenId, address _address);

    event InitializeToken(uint256 indexed _tokenId, string tokenCid);

    event NewDelegation(address _owner, address _delegatee);
}