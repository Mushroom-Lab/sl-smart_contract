// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Base.t.sol";
import "./profile.t.sol";
import "lib/forge-std/src/console2.sol";
import "../src/interfaces/ISoulink.sol";



contract SoulinkTest is BaseSetup {
    using stdStorage for StdStorage;

    string description = "Let's RnR";
    bytes32 uid = keccak256(abi.encode(description));
    address soulink;
    ISoulink s;

    function setUp() public virtual override {
        // override setup
        super.setUp();
        bytes32 uid = keccak256(abi.encode(description));
        uint256 prev_length = slFactory.SoulinkLength();
        soulink = slFactory.createSoulink(description);
        s = ISoulink(soulink);
        uint256 aft_length = slFactory.SoulinkLength();
        assert ((prev_length + 1) == aft_length);
        assert(slFactory.soulinkDesc(uid) == soulink);
    }

    function testInitNFT() public
    {
        vm.prank(user1);
        uint256 prevCounter = s.tokenIdCounter();
        (bytes memory _signatures, address[] memory _owners, string memory _tokenCid) = genInitOutput();
        s.initilizeNFT(_signatures, _owners, _tokenCid);
        vm.stopPrank();
        uint256 postCounter = s.tokenIdCounter();
        assert(prevCounter+1 == postCounter);

        assert(s.p2pWhitelist(prevCounter,user1));
        assert(s.p2pWhitelist(prevCounter,user2));
        assert(s.p2pWhitelist(prevCounter,user3));

        bytes32 messageHash = s.getMessageHash(_owners, _tokenCid);
        assert(s.isHashUsed(messageHash, user1));
        assert(s.isHashUsed(messageHash, user2));
        assert(s.isHashUsed(messageHash, user3));

        bytes32 CidHash = keccak256(abi.encode(s.tokenToCid(prevCounter)));
        assert(CidHash == keccak256(abi.encode(_tokenCid)));
    }

    function testRepeatedInitNFT() public 
    {  
        vm.prank(user1);
        uint256 prevCounter = s.tokenIdCounter();
        (bytes memory _signatures, address[] memory _owners, string memory _tokenCid) = genInitOutput();
        s.initilizeNFT(_signatures, _owners, _tokenCid);
        vm.expectRevert();
        s.initilizeNFT(_signatures, _owners, _tokenCid);
    }

    function testMint() public 
    {
        vm.prank(user1);
        uint256 prevCounter = s.tokenIdCounter();
        (bytes memory _signatures, address[] memory _owners, string memory _tokenCid) = genInitOutput();
        s.initilizeNFT(_signatures, _owners, _tokenCid);
        s.mint(prevCounter, user1);
        vm.stopPrank();
        assert(s.balanceOf(user1, prevCounter) == 1);
    }

    function testBurn() public 
    {
        vm.prank(user1);
        uint256 prevCounter = s.tokenIdCounter();
        (bytes memory _signatures, address[] memory _owners, string memory _tokenCid) = genInitOutput();
        s.initilizeNFT(_signatures, _owners, _tokenCid);
        s.mint(prevCounter, user1);
        vm.prank(user1);
        s.burn(prevCounter);
        vm.stopPrank();
        assert(s.balanceOf(user1, prevCounter) == 0);
    }

    function testRepeatedMint() public 
    {
        vm.prank(user1);
        uint256 prevCounter = s.tokenIdCounter();
        (bytes memory _signatures, address[] memory _owners, string memory _tokenCid) = genInitOutput();
        s.initilizeNFT(_signatures, _owners, _tokenCid);
        s.mint(prevCounter, user1);
        vm.expectRevert();
        s.mint(prevCounter, user1);
        vm.stopPrank();
    }

    function testRepeatedBurn() public 
    {
        uint256 prevCounter = s.tokenIdCounter();
        (bytes memory _signatures, address[] memory _owners, string memory _tokenCid) = genInitOutput();
        s.initilizeNFT(_signatures, _owners, _tokenCid);
        s.mint(prevCounter, user1);
        vm.prank(user1);
        s.burn(prevCounter);
        vm.expectRevert();
        s.burn(prevCounter);
        vm.stopPrank();
    }

    // test consensual mint with CA + EOA
    function testInitializeNFT_CA_EOA() public 
    {
        uint256 prevCounter = s.tokenIdCounter();
        (bytes memory _signatures, address[] memory _owners, string memory _tokenCid) = genInitOutputWithCA();
        s.initilizeNFT(_signatures, _owners, _tokenCid);
        uint256 postCounter = s.tokenIdCounter();
        assert(prevCounter+1 == postCounter);

        assert(s.p2pWhitelist(prevCounter,address(profile)));
        assert(s.p2pWhitelist(prevCounter,user2));
        assert(s.p2pWhitelist(prevCounter,user3));

        bytes32 messageHash = s.getMessageHash(_owners, _tokenCid);
        assert(s.isHashUsed(messageHash, address(profile)));
        assert(s.isHashUsed(messageHash, user2));
        assert(s.isHashUsed(messageHash, user3));

        bytes32 CidHash = keccak256(abi.encode(s.tokenToCid(prevCounter)));
        assert(CidHash == keccak256(abi.encode(_tokenCid)));
    }

    function testInitializeNFT_CAs() public 
    {
        uint256 prevCounter = s.tokenIdCounter();
        (bytes memory _signatures, address[] memory _owners, string memory _tokenCid) = genInitOutputWith2CA();
        s.initilizeNFT(_signatures, _owners, _tokenCid);
        uint256 postCounter = s.tokenIdCounter();
        assert(prevCounter+1 == postCounter);

        assert(s.p2pWhitelist(prevCounter,address(profile)));
        assert(s.p2pWhitelist(prevCounter,address(profile2)));

        bytes32 messageHash = s.getMessageHash(_owners, _tokenCid);
        assert(s.isHashUsed(messageHash, address(profile)));
        assert(s.isHashUsed(messageHash, address(profile2)));

        bytes32 CidHash = keccak256(abi.encode(s.tokenToCid(prevCounter)));
        assert(CidHash == keccak256(abi.encode(_tokenCid)));

    }

    // helper function
    function genInitOutput() public returns(bytes memory, address[] memory, string memory)
    {
        string memory tokenCid = "MocktokenCid1";
        bytes memory _signatures;
        address[] memory _owners = new address[](3);
        uint8 v;
        bytes32 r;
        bytes32 s;
        _owners[0] = user1;
        _owners[1] = user2;
        _owners[2] = user3;

        bytes32 messageHash = ISoulink(soulink).getMessageHash(_owners, tokenCid);

        // return order (8 - v ,32 - r,32 - s)
        (v,r,s) = vm.sign(user1PrivateKey, messageHash);
        // bytes-level order (32 - r, s - 32, v - 8)
        bytes memory signature1 = abi.encodePacked(r, s, v);
        
        (v,r,s) = vm.sign(user2PrivateKey, messageHash);
        bytes memory signature2 = abi.encodePacked(r, s, v);

        (v,r,s) = vm.sign(user3PrivateKey, messageHash);
        bytes memory signature3 = abi.encodePacked(r, s, v);

        _signatures = abi.encodePacked(signature1, signature2, signature3);
        assert(_signatures.length == 195);
        assert(_owners.length == 3);
        return (_signatures, _owners, tokenCid);
    }

    function genInitOutputWithCA() public returns(bytes memory, address[] memory, string memory)
    {
        string memory tokenCid = "MocktokenCid2";
        bytes memory _signatures;
        address[] memory _owners = new address[](3);
        uint8 v;
        bytes32 r;
        bytes32 s;
        address profileAddr = address(profile);
        _owners[0] = profileAddr;
        _owners[1] = user2;
        _owners[2] = user3;

        bytes32 messageHash = ISoulink(soulink).getMessageHash(_owners, tokenCid);

        // return order (8 - v ,32 - r,32 - s)
        (v,r,s) = vm.sign(profileOwnerPrivateKey, messageHash);
        // bytes-level order (32 - r, s - 32, v - 8)
        bytes memory signature1 = abi.encodePacked(r, s, v);
        
        (v,r,s) = vm.sign(user2PrivateKey, messageHash);
        bytes memory signature2 = abi.encodePacked(r, s, v);

        (v,r,s) = vm.sign(user3PrivateKey, messageHash);
        bytes memory signature3 = abi.encodePacked(r, s, v);

        _signatures = abi.encodePacked(signature1, signature2, signature3);
        assert(_signatures.length == 195);
        assert(_owners.length == 3);
        return (_signatures, _owners, tokenCid);
    }

    function genInitOutputWith2CA() public returns(bytes memory, address[] memory, string memory)
    {
        string memory tokenCid = "MocktokenCid3";
        bytes memory _signatures;

        address[] memory _owners = new address[](2);
        uint8 v;
        bytes32 r;
        bytes32 s;
        _owners[0] = address(profile);
        _owners[1] = address(profile2);

        bytes32 messageHash = ISoulink(soulink).getMessageHash(_owners, tokenCid);

        // return order (8 - v ,32 - r,32 - s)
        (v,r,s) = vm.sign(profileOwnerPrivateKey, messageHash);
        // bytes-level order (32 - r, s - 32, v - 8)
        bytes memory signature1 = abi.encodePacked(r, s, v);
        
        (v,r,s) = vm.sign(profile2OwnerPrivateKey, messageHash);
        bytes memory signature2 = abi.encodePacked(r, s, v);

        _signatures = abi.encodePacked(signature1, signature2);
        assert(_signatures.length == 130);
        assert(_owners.length == 2);
        return (_signatures, _owners, tokenCid);
    }
}