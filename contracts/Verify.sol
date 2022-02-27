// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Verify {
    // Using Openzeppelin ECDSA cryptography library
    function getCreateKYCMessageHash(string memory _uid, address _userAddress)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_uid, _userAddress));
    }

    function getCreateProjectMessageHash(
        string memory _projectId,
        address _userAddress
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_projectId, _userAddress));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(_messageHash);
    }

    function getSingerAdderss(bytes32 _messageHash, bytes memory _singature)
        public
        pure
        returns (address singer)
    {
        return ECDSA.recover(_messageHash, _singature);
    }

    function verifyCreateKYC(
        address _singer,
        string memory _uid,
        address _userAddress,
        bytes memory _signature
    ) public pure returns (bool) {
        bytes32 messageHash = getCreateKYCMessageHash(_uid, _userAddress);
        bytes32 ethSignMessagehash = getEthSignedMessageHash(messageHash);
        return getSingerAdderss(ethSignMessagehash, _signature) == _singer;
    }

    function verifyCreateProject(
        address _singer,
        string memory _projectId,
        address _userAddress,
        bytes memory _signature
    ) public pure returns (bool) {
        bytes32 messageHash = getCreateKYCMessageHash(_projectId, _userAddress);
        bytes32 ethSignMessagehash = getEthSignedMessageHash(messageHash);
        return getSingerAdderss(ethSignMessagehash, _signature) == _singer;
    }
}
