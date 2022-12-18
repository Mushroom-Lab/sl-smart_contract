// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Base.t.sol";
import "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/console2.sol";

import "../src/contracts/Soulink.sol";
import "../src/contracts/SoulinkFactory.sol";

contract FactoryTest is BaseSetup {
    using stdStorage for StdStorage;

    function testImpl() public {
        assert (slFactory.impl() != address(0));
    }

    function testCreateSoulink() public 
    {
        vm.prank(alice);
        string memory description = "Test Series";
        bytes32 uid = keccak256(abi.encode(description));
        uint256 prev_length = slFactory.SoulinkLength();
        address instance = slFactory.createSoulink(description);
        uint256 aft_length = slFactory.SoulinkLength();
        vm.stopPrank();
        assert ((prev_length + 1) == aft_length);
        assert(slFactory.soulinkDesc(uid) == instance);
    }

    function testSetImpl() public 
    {
        SL = new Soulink(address(slFactory));
        string memory _newVersion = "1.1.0";
        vm.prank(FACTORY_ADMIN);
        slFactory.upgradeSoulinkImpl(address(SL), _newVersion);
        vm.stopPrank();
        bytes32 _result = keccak256(abi.encodePacked(slFactory.implVersion()));
        assert(_result == keccak256(abi.encodePacked(_newVersion)));

    }

    function testCreateSLSameUID() public 
    {
        string memory description = "Test Series";
        bytes32 uid = keccak256(abi.encode(description));
        address instance1 = slFactory.createSoulink(description);

        vm.expectRevert('SOULINK DESCRIPTION ALREADY EXISTED');
        slFactory.createSoulink(description);
    }

}