// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/Vm.sol";

import "../src/contracts/Soulink.sol";
import "../src/contracts/Profile.sol";
import "../src/contracts/SoulinkFactory.sol";

contract BaseSetup is Test {
    using stdStorage for StdStorage;

    address constant FACTORY_ADMIN = address(0x93532A9318182042D014491DA1F1A49B4254F043);

    Soulink SL;
    SoulinkFactory slFactory;
    Profile profile;
    Profile profile2;

    address internal alice;

    
    uint256 public constant user1PrivateKey = 0xA11CE;
    uint256 public constant user2PrivateKey = 0xB1380;
    uint256 public constant user3PrivateKey = 0xA169;
    uint256 public constant user4PrivateKey = 0xA169999;
    uint256 public constant user5PrivateKey = 0xA169999123;
        
    address user1 = vm.addr(user1PrivateKey);
    address user2 = vm.addr(user2PrivateKey);
    address user3 = vm.addr(user3PrivateKey);
    address user4 = vm.addr(user4PrivateKey);
    address user5 = vm.addr(user5PrivateKey);

    address profileOwner = user4;
    address profile2Owner = user5;

    uint256 public constant profileOwnerPrivateKey = user4PrivateKey;
    uint256 public constant profile2OwnerPrivateKey = user5PrivateKey;

    function findStorage(
        address _user,
        bytes4 _selector,
        address _contract
    ) public returns (uint256) {
        uint256 slot = stdstore
            .target(_contract)
            .sig(_selector)
            .with_key(_user)
            .find();
        bytes32 data = vm.load(_contract, bytes32(slot));
        return uint256(data);
    }

    function setStorage(
        address _user,
        bytes4 _selector,
        address _contract,
        uint256 value
    ) public {
        uint256 slot = stdstore
            .target(_contract)
            .sig(_selector)
            .with_key(_user)
            .find();
        vm.store(_contract, bytes32(slot), bytes32(value));
    }

    function setUp() public virtual {


        vm.startPrank(FACTORY_ADMIN);
        slFactory = new SoulinkFactory();
        SL = new Soulink(address(slFactory));
        slFactory.upgradeSoulinkImpl(address(SL), "1.0.0");
        vm.stopPrank();
        
        vm.prank(profileOwner);
        profile = new Profile();
        vm.stopPrank();
        assert(profile.owner() == profileOwner);   

        vm.prank(profile2Owner);
        profile2 = new Profile();
        vm.stopPrank();
        assert(profile2.owner() == profile2Owner);
    }
}