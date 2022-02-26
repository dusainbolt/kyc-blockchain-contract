//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Verify.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KYCPlatform is Ownable, Verify {
    // Setting of contract
    Setting private settings;
    // List project register in system
    Project[] private projects;

    // mapping(uint256 => mapping(address => KycInfo)) private projectUsers;

    mapping(address => KycInfo) private users;

    // Spirnt 2 durationPaymentFee, expireEachProject
    struct Setting {
        uint8 version; // Version of KYC
        uint32 renewExpireTime; // duration that user must reset kyc
        uint32 durationUpdateVersion; // Duration update version when user must change KYC
        // uint32 expireEachProject; // Expire for each business using platform
        uint256 serviceFee; // The service fee witch business must payment when create project
        // uint32 durationPaymentFee; // Duration payment to service fee since second time
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

    /**
     * @notice Validate pool by project iD
     * @param _projectId id of the pool
     */

    modifier validateProject(uint256 _projectId) {
        require(
            _projectId < projects.length,
            "KYCPlatform: Project is not exist"
        );
        _;
    }

    /**
     * @notice set the setting of contract
     * @param _version Version of KYC
     * @param  _durationUpdateVersion Duration update version when user must change KYC
     * @param _renewExpireTime  duration that user must reset kyc
     * @param _serviceFee  The service fee witch business must payment when create project
     */
    function setSetting(
        uint8 _version,
        uint32 _durationUpdateVersion,
        uint32 _renewExpireTime,
        // uint32 _expireEachProject,
        uint256 _serviceFee
    )
        external
        // uint32 _durationPaymentFee // Duration payment to service fee since second time
        onlyOwner
    {
        settings.version = _version;
        settings.durationUpdateVersion = _durationUpdateVersion;
        settings.renewExpireTime = _renewExpireTime;
        // settings.expireEachProject = _expireEachProject;
        settings.serviceFee = _serviceFee;
        // settings.durationPaymentFee = _durationPaymentFee;
    }

    function getSetting() public view onlyOwner returns (Setting memory) {
        return settings;
    }

    /**
     * @notice get kyc info of user
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
     * @notice get kyc info of user by project
     * @param _projectId the project id
     * @param _userAddress the address of user
     */
    function getKYCByProject(uint256 _projectId, address _userAddress)
        public
        view
        onlyOwner
        validateProject(_projectId)
        returns (KycInfo memory)
    {
        return getKYCInfo(_userAddress);
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
