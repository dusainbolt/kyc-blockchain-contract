//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Verify.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract KYCPlatform is Ownable, Verify, ReentrancyGuard {
    // Setting KYC of contract
    SettingKYC private settingsKyc;
    // Setting Project of contract
    SettingProject private settingsProject;
    // List project register in system
    Project[] private projects;

    mapping(string => bool) private isExistProject;
    mapping(address => bool) private isExistKYC;

    mapping(address => KycInfo) private users;

    struct SettingKYC {
        uint8 version; // Version of KYC
        uint32 renewExpireTime; // duration that user must reset kyc
        uint32 durationUpdateVersion; // Duration update version when user must change KYC
    }

    struct SettingProject {
        uint32 expireEachProject; // Expire for each business using platform
        uint256 serviceFee; // The service fee witch business must payment when create project
        uint32 durationPaymentFee; // Duration payment to service fee since second time
    }

    struct Project {
        string projectId;
        uint256 projectExpireTime;
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

    event ProjectCreated(
        uint256 indexed projectIndex,
        string projectId,
        address creator,
        uint256 projectExpireTime
    );

    event KycCreated(string uid, address userAddress, uint256 kycExpireTime);

    /**
     * @notice Validate pool by project iD
     * @param _projectIndex id of the pool
     */
    modifier validateProject(uint256 _projectIndex) {
        require(
            _projectIndex < projects.length,
            "KYCPlatform: Project is not exist"
        );
        _;
    }

    /**
     * @notice set the setting kyc of contract
     * @param _version Version of KYC
     * @param  _durationUpdateVersion Duration update version when user must change KYC
     * @param _renewExpireTime  duration that user must reset kyc
     */
    function setSettingKYC(
        uint8 _version,
        uint32 _durationUpdateVersion,
        uint32 _renewExpireTime
    ) external onlyOwner {
        settingsKyc.version = _version;
        settingsKyc.durationUpdateVersion = _durationUpdateVersion;
        settingsKyc.renewExpireTime = _renewExpireTime;
    }

    /**
     * @notice set the setting project of contract
     * @param _expireEachProject expire for each business using platform
     * @param _serviceFee  the service fee witch business must payment when create project
     * @param  _durationPaymentFee  duration payment to service fee since second time
     */
    function setSettingProject(
        uint32 _expireEachProject,
        uint256 _serviceFee,
        uint32 _durationPaymentFee
    ) external onlyOwner {
        settingsProject.expireEachProject = _expireEachProject;
        settingsProject.serviceFee = _serviceFee;
        settingsProject.durationPaymentFee = _durationPaymentFee;
    }

    function getSettingKYC() public view onlyOwner returns (SettingKYC memory) {
        return settingsKyc;
    }

    function getSettingProject()
        public
        view
        onlyOwner
        returns (SettingProject memory)
    {
        return settingsProject;
    }

    /**
     * @notice create kyc member to contract
     * @param _projectId the project id
     * @param _signature the signature of admin approve
     */
    function createProject(string memory _projectId, bytes memory _signature)
        external
        payable
        nonReentrant
    {
        require(
            isExistProject[_projectId] == false,
            "KYCPlatform: Project is exist"
        );

        require(
            verifyCreateProject(owner(), _projectId, _msgSender(), _signature),
            "KYCPlatform: Invalid Signature"
        );

        require(
            msg.value == settingsProject.serviceFee,
            "KYCPlatform: Not enough service fee"
        );

        address payable creator = payable(_msgSender());

        _forwardFunds(msg.value);

        uint256 projectExpireTime = block.timestamp +
            settingsProject.expireEachProject;

        projects.push(
            Project({
                projectId: _projectId,
                projectExpireTime: projectExpireTime,
                createdAt: block.timestamp,
                creator: creator
            })
        );

        isExistProject[_projectId] = true;

        emit ProjectCreated(
            projects.length - 1,
            _projectId,
            creator,
            projectExpireTime
        );
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds(uint256 _value) internal {
        address payable wallet = payable(owner());
        (bool sent, ) = wallet.call{value: _value}("");
        require(sent, "KYCPlatform: WALLET_TRANSFER_FAILED");
    }

    /**
     * @notice get kyc info of user by project
     * @param _projectIndex the project id
     * @param _userAddress the address of user
     */
    function getKYCByProject(uint256 _projectIndex, address _userAddress)
        public
        view
        onlyOwner
        validateProject(_projectIndex)
        returns (KycInfo memory)
    {
        require(
            projects[_projectIndex].projectExpireTime >
                block.timestamp + settingsProject.durationPaymentFee,
            "KYCPlatform: Project is expire"
        );
        return getKYCInfo(_userAddress);
    }

    /**
     * @notice create kyc member to contract
     * @param _uid the uid of kyc info in ifps
     * @param _signature the signature of admin approve
     */
    function createKYCMember(string memory _uid, bytes memory _signature)
        external
        nonReentrant
    {
        require(isExistKYC[_msgSender()] == false, "KYCPlatform: KYC is exist");
        require(
            verifyCreateKYC(owner(), _uid, _msgSender(), _signature),
            "KYCPlatform: Invalid Signature"
        );
        users[_msgSender()].version = settingsKyc.version;
        users[_msgSender()].userAddress = _msgSender();
        users[_msgSender()].uid = _uid;
        users[_msgSender()].createdAt = block.timestamp;
        users[_msgSender()].kycExpireTime =
            block.timestamp +
            settingsKyc.renewExpireTime;

        isExistKYC[_msgSender()] = true;

        emit KycCreated(_uid, _msgSender(), users[_msgSender()].kycExpireTime);
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
            kyc.version == settingsKyc.version,
            "KYCPlatform: Version KYC of user not correct"
        );

        require(
            kyc.kycExpireTime > block.timestamp,
            "KYCPlatform: KYC is expire"
        );

        return kyc;
    }
}
