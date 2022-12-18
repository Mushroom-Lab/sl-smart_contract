pragma solidity ^0.8.13;
import "lib/openzeppelin-contracts/contracts//token/ERC1155/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "../interfaces/IProfile.sol";

// ____   ___  _   _ _     ___ _   _ _  __
// / ___| / _ \| | | | |   |_ _| \ | | |/ /
// \___ \| | | | | | | |    | ||  \| | ' / 
//  ___) | |_| | |_| | |___ | || |\  | . \ 
// |____/ \___/ \___/|_____|___|_| \_|_|\_\


///     ###############################################
///     Core Soulink Specification
///
///     ###############################################
///
error WrongResolvedAddress(address resolved, address targeted);
error HashAlreadyMinted(bytes32 _rawMessageHash, address signer);

contract Soulink is ERC1155 {
    using Counters
    for Counters.Counter;

    address public immutable factory;
    
    // assigned during initialize
    string public description;
    // unique identifier from dscription to identify eacch P2PNFT in factory.
    bytes32 public uid;
    
    Counters.Counter public tokenIdCounter;
    // a mapping that map each token => address => canMint
    mapping (uint256 => mapping (address => bool)) public p2pWhitelist;
    // a mapping that map each Hash to address => is consumed to avoid replay
    mapping (bytes32 => mapping (address => bool)) public isHashUsed;
    
    // Mapping from token ID to the ipfs cid
    mapping(uint256 => string) public tokenToCid;

    event InitializeTokenAddress(uint256 indexed token_Id, address _address);

    event InitializeToken(uint256 indexed token_Id, string tokenCid);

    // factory would deploy this 
    constructor(address _factory) ERC1155("") {
        factory = _factory;
    }

    // this function is called only once upon deployment
    function initialize(string memory _description) external {
        require(msg.sender == factory, 'FORBIDDEN'); 
        description = _description;
        uid = keccak256(abi.encode(_description));
    }

    // anyone can mint any soulink as long as they have all the signature from particpiant
    // signature => ETHSign(_rawMessageHash) = > hash(addresses + uid + tokenCid)
    function initilizeNFT(bytes memory _signatures, address[] memory _owners, string memory _tokenCid) external returns(bool) {
        bytes32 messageHash = getMessageHash(_owners, _tokenCid);
        // number of signatures has to match number of participants
        uint256 _noParticipants = _owners.length;
        require(_signatures.length == _noParticipants * 65, "NOT ENOUGH SIGS");
        uint256 tokenId = tokenIdCounter.current();
        address p;
        address owner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        for (uint256 i = 0; i < _noParticipants; ++i) {
            p = _recover(_signatures, i,  _owners, _tokenCid);
            owner = _owners[i];

            // this check does not cover CA that is under construction; 
            // refer to https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L20
            if (Address.isContract(owner)) {
                // check if p is either the owner or delegatee of the owner(CA) 
                (v,r,s) = sigsSplit(_signatures, i);
                require(IProfile(owner).isValidSignature(messageHash, v, r, s), "CA SIGNATURE INVALID");
            }
            else {
                // if the resolved address from signature does not match the delegatee
                require(p == owner, "WRONG RESOLVED OWNER");
            }
            
            // if the owner has already minted this hash
            if (isHashUsed[messageHash][owner]) {
                revert HashAlreadyMinted(messageHash, owner);
            }
            isHashUsed[messageHash][owner] = true;
            p2pWhitelist[tokenId][owner] = true;
            emit InitializeTokenAddress(tokenId, owner);
        }
        _setTokenCid(tokenId, _tokenCid);
        tokenIdCounter.increment();
        emit InitializeToken(tokenId, _tokenCid);
        return true;
    }

    function mint(uint256 tokenId, address to) external {
        require(p2pWhitelist[tokenId][to], "not whitelist");
        require(balanceOf(to,tokenId) == 0, "already minted");
        super._mint(to, tokenId, 1, "");
    }

    function burn(uint256 tokenId) external {
        require(balanceOf(msg.sender,tokenId) > 0, "USER BALANCE NOT ENOUGH");
        super._burn(msg.sender, tokenId, 1);
    }

    
    /*//////////////////////////////////////////////////////////////
                        PURE HELPER FUNCTION 
    //////////////////////////////////////////////////////////////*/
    function sigsSplit(bytes memory signatures, uint256 pos)
        private
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    function EthSign(bytes32 _rawMessage)
        private
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _rawMessage)
            );
    }


    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

    function getMessageHash(address[] memory _owners, string memory _tokenCid) 
        public 
        view 
        returns (bytes32) 
    {
        // embed soulink-specific uid into the hash
        bytes32 rawMessageHash = keccak256(abi.encode(_owners, uid, _tokenCid));
        bytes32 ethSig = EthSign(rawMessageHash);
        return ethSig;
    }

    function uri(uint256 tokenId) 
        public 
        view 
        override 
        returns (string memory) 
    {
        require(tokenId < tokenIdCounter.current(), "TOKENID DOES NOT EXIST");
        return string(
            abi.encodePacked(
                "ipfs://",
                tokenToCid[tokenId],
                "/metadata.json"
            )
        );
    }


    /*//////////////////////////////////////////////////////////////
                        PRIVATE FUNCTION 
    //////////////////////////////////////////////////////////////*/
    function _setTokenCid(uint256 tokenId, string memory tokenCid) private {
         tokenToCid[tokenId] = tokenCid; 
    }


        // recall signature => ETHSign(_rawMessageHash) = > hash(addresses + uid + tokenCid)
    function _recover(bytes memory _signatures,  uint256 i, address[] memory owners, string memory tokenCid) private view returns (address) {
        bytes32 _ethSignedMessageHash = getMessageHash(owners, tokenCid);
        (uint8 v, bytes32 r, bytes32 s) = sigsSplit(_signatures, i);
        address p = ecrecover(_ethSignedMessageHash, v, r, s);
        return p;
    }

    /*//////////////////////////////////////////////////////////////
                        SOULBOOUND LIMITATION
    //////////////////////////////////////////////////////////////*/
    // function _afterTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    // internal
    // override(ERC1155) {
    //     super._afterTokenTransfer(operator, address(0), to, ids, amounts, data);
    // }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155) {
        require(from == address(0) || to == address(0), "TOKEN is SOUL-BOUND");
        super._beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
    }
    
}