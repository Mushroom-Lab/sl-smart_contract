// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Base.t.sol";
import "lib/forge-std/src/console2.sol";
import "../src/contracts/Profile.sol";

contract ProfileTest is BaseSetup {
    using stdStorage for StdStorage;


    function testIsValidSignature() public 
    {
        bytes memory message = bytes("0xABC");
        bytes32 digest = keccak256(message);
        // signer is the owner of profile
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(profileOwnerPrivateKey, digest);
        // user's signature is validated on the profile level
        assert(profile.isValidSignature(digest, v, r, s));
    }

    function testIsValidSignatureWithDelegateeSig() public 
    {
        vm.prank(profileOwner);
        profile.setDelegatee(user2);
        vm.stopPrank();
        bytes memory message = bytes("0xABC");
        bytes32 digest = keccak256(message);
        // signer is the delegatee of profile
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user2PrivateKey, digest);
        // user's signature is validated on the profile level
        assert(profile.isValidSignature(digest, v, r, s));


    }

    function testIsInvalidSignature() public 
    {
        bytes memory message = bytes("0xABC");
        bytes32 digest = keccak256(message);
        // signer is the delegatee of profile
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user3PrivateKey, digest);
        // user's signature is validated on the profile level
        assert(!profile.isValidSignature(digest, v, r, s));
    }

    function testTransferOwner() public 
    {
        vm.prank(profileOwner);
        profile.transferOwnership(user3);
        vm.stopPrank();
        assert(profile.owner() == user3);
    }

    function testTransferOwnerInvalid() public 
    {
        vm.prank(user3);
        vm.expectRevert("Ownable: caller is not the owner");
        profile.transferOwnership(user3);
        vm.stopPrank();
        
    }

    function testSetDelegatee() public 
    {
        vm.prank(profileOwner);
        profile.setDelegatee(user2);
        vm.stopPrank();
        assert(profile.delegatee() == user2);
    }

    function testUpdateDelegatee() public
    {
        vm.prank(profileOwner);
        profile.setDelegatee(user2);
        vm.prank(profileOwner);
        profile.setDelegatee(user3);
        vm.stopPrank();
        assert(profile.delegatee() == user3);
    }

    function testSetDelegateeInValidSig() public 
    {
        vm.prank(profileOwner);
        profile.setDelegatee(user2);

        bytes memory message = bytes("0xABC");
        bytes32 digest = keccak256(message);
        // signer is not owner nor delegatee of profile
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user3PrivateKey, digest);
        // user's signature is validated on the profile level
        assert(!profile.isValidSignature(digest, v, r, s));
    }

    function testInValidSetDelegatee() public 
    {
        vm.prank(user3);
        vm.expectRevert("Ownable: caller is not the owner");
        profile.setDelegatee(user3);
        vm.stopPrank();
    }

    function testPermit() public 
    {
        address newDelegatee = user3;
        bytes32 PERMIT_TYPEHASH = profile.PERMIT_TYPEHASH();
        bytes32 DOMAIN_SEPARATOR = profile.DOMAIN_SEPARATOR();
        uint256 nonce = profile.nonces(profileOwner);

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, profileOwner, newDelegatee, nonce))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(profileOwnerPrivateKey, digest);
        profile.permit(profileOwner, newDelegatee, v, r, s);
        assert (profile.delegatee() == newDelegatee);
    }   

    function testPermitInvalidSig() public 
    {
        address newDelegatee = user3;
        bytes32 PERMIT_TYPEHASH = profile.PERMIT_TYPEHASH();
        bytes32 DOMAIN_SEPARATOR = profile.DOMAIN_SEPARATOR();
        uint256 nonce = profile.nonces(profileOwner);

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, profileOwner, newDelegatee, nonce))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(profile2OwnerPrivateKey, digest);
        vm.expectRevert();
        profile.permit(profileOwner, newDelegatee, v, r, s);
    }

    function testRepeatedPermit() public 
    {
        address newDelegatee = user3;
        bytes32 PERMIT_TYPEHASH = profile.PERMIT_TYPEHASH();
        bytes32 DOMAIN_SEPARATOR = profile.DOMAIN_SEPARATOR();
        uint256 nonce = profile.nonces(profileOwner);

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, profileOwner, newDelegatee, nonce))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(profileOwnerPrivateKey, digest);
        profile.permit(profileOwner, newDelegatee, v, r, s);
        assert (profile.delegatee() == newDelegatee);
        // nonce is consumed.
        vm.expectRevert();
        profile.permit(profileOwner, newDelegatee, v, r, s);
        
    }

    function testCancelPermit() public 
    {
        address newDelegatee = user3;
        bytes32 PERMIT_TYPEHASH = profile.PERMIT_TYPEHASH();
        bytes32 DOMAIN_SEPARATOR = profile.DOMAIN_SEPARATOR();
        uint256 nonce = profile.nonces(profileOwner);

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, profileOwner, newDelegatee, nonce))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(profileOwnerPrivateKey, digest);
        profile.permit(profileOwner, newDelegatee, v, r, s);
        assert (profile.delegatee() == newDelegatee);

        //cancel delegateec
        newDelegatee = address(0);
        nonce = profile.nonces(profileOwner);

        digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, profileOwner, newDelegatee, nonce))
            )
        );
        (v, r, s) = vm.sign(profileOwnerPrivateKey, digest);
        profile.permit(profileOwner, newDelegatee, v, r, s);
        assert (profile.delegatee() == newDelegatee);

    }

    function testCancelPermitInvalidUser() public 
    {
        address newDelegatee = user3;
        bytes32 PERMIT_TYPEHASH = profile.PERMIT_TYPEHASH();
        bytes32 DOMAIN_SEPARATOR = profile.DOMAIN_SEPARATOR();
        uint256 nonce = profile.nonces(profileOwner);

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, profileOwner, newDelegatee, nonce))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(profileOwnerPrivateKey, digest);
        profile.permit(profileOwner, newDelegatee, v, r, s);
        assert (profile.delegatee() == newDelegatee);

        //cancel delegateec
        newDelegatee = address(0);
        nonce = profile.nonces(profileOwner);

        digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, profileOwner, newDelegatee, nonce))
            )
        );
        (v, r, s) = vm.sign(profile2OwnerPrivateKey, digest);
        vm.expectRevert();
        profile.permit(profileOwner, newDelegatee, v, r, s);
        

    }

    function testReAddPermit() public 
    {
        address newDelegatee = user3;
        bytes32 PERMIT_TYPEHASH = profile.PERMIT_TYPEHASH();
        bytes32 DOMAIN_SEPARATOR = profile.DOMAIN_SEPARATOR();
        uint256 nonce = profile.nonces(profileOwner);

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, profileOwner, newDelegatee, nonce))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(profileOwnerPrivateKey, digest);
        profile.permit(profileOwner, newDelegatee, v, r, s);
        assert (profile.delegatee() == newDelegatee);

        //cancel delegateec
        newDelegatee = address(0);
        nonce = profile.nonces(profileOwner);

        digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, profileOwner, newDelegatee, nonce))
            )
        );
        (v, r, s) = vm.sign(profileOwnerPrivateKey, digest);
        profile.permit(profileOwner, newDelegatee, v, r, s);
        assert (profile.delegatee() == newDelegatee);

        newDelegatee = user5;
        nonce = profile.nonces(profileOwner);

        digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, profileOwner, newDelegatee, nonce))
            )
        );
        (v, r, s) = vm.sign(profileOwnerPrivateKey, digest);
        profile.permit(profileOwner, newDelegatee, v, r, s);
        assert (profile.delegatee() == newDelegatee);

    }

}