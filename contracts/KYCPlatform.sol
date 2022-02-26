//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Verify.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract KYCPlatform is Ownable, Verify {
    // Setting of contract
    Setting private settings;
    // List project register in system
    Project[] private projects;

    mapping(uint256 => mapping(address => KycInfo)) private projectUsers;

    mapping(address => KycInfo) private users;

    struct Setting {
        uint8 version; // Version of KYC
        uint32 renewExpireTime;
        uint32 durationUpdateVersion; // Duration update version when user must change KYC
        uint32 expireEachProject; // Expire for each business using platform
        uint256 serviceFee; // The service fee witch business must payment when create project
        uint32 durationPaymentFee; // Duration payment to service fee since second time
    }

    struct Project {
        uint256 projectId;
        string secretKey;
        string projectName;
        string projectType;
        uint256 endExpireTime;
        uint256 createdAt;
        address payable creator;
    }

    struct KycInfo {
        string uid;
        address userAddress;
        uint8 version;
        uint256 createdAt;
        uint256 kycExpireTime;
    }

    function setSetting(
        uint8 _version, // Version of KYC
        uint32 _durationUpdateVersion, // Duration update version when user must change KYC
        uint32 _renewExpireTime,
        uint32 _expireEachProject, // Expire for each business using platform
        uint256 _serviceFee, // The service fee witch business must payment when create project
        uint32 _durationPaymentFee // Duration payment to service fee since second time
    ) external onlyOwner {
        settings.version = _version;
        settings.durationUpdateVersion = _durationUpdateVersion;
        settings.renewExpireTime = _renewExpireTime;
        settings.expireEachProject = _expireEachProject;
        settings.serviceFee = _serviceFee;
        settings.durationPaymentFee = _durationPaymentFee;
    }

    function getSetting() public view onlyOwner returns (Setting memory) {
        return settings;
    }

    /**
     * @notice create kyc member to contract
     * @param _userAdress the address of user
     */
    function getKYCInfo(address _userAdress)
        public
        view
        onlyOwner
        returns (KycInfo memory)
    {
        KycInfo memory kyc = users[_userAdress];

        require(
            kyc.version == settings.version,
            "KYCPlatform: Version KYC of user not correct"
        );

        return kyc;
    }

    /**
     * @notice create kyc member to contract
     * @param _uid the uid of kyc info in ifps
     * @param _signature the signature of admin approve
     */
    function createKYCMember(string memory _uid, bytes memory _signature)
        external
    {
        require(
            verifyCreateKYC(owner(), _uid, _msgSender(), _signature),
            "KYCPlatform: Invalid Signature"
        );
        users[_msgSender()].version = settings.version;
        users[_msgSender()].userAddress = _msgSender();
        users[_msgSender()].uid = _uid;
        users[_msgSender()].createdAt = block.timestamp;
        users[_msgSender()].kycExpireTime =
            block.timestamp +
            settings.renewExpireTime;
    }
}
