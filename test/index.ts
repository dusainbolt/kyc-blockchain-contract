/* eslint-disable node/no-extraneous-import */
/* eslint-disable camelcase */
/* eslint-disable node/no-missing-import */
import { expect } from "chai";
import { ethers, web3 } from "hardhat";
import { BigNumber } from "@ethersproject/bignumber";

import type { KYCPlatform, KYCPlatform__factory } from "../typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const { time } = require("@openzeppelin/test-helpers");

const utils = ethers.utils;

describe("KYCPlatform", () => {
  // asset
  let kycPlatform: KYCPlatform;
  let KycPlatformFactory: KYCPlatform__factory;

  // account
  let owner: SignerWithAddress, account1: SignerWithAddress;

  // const
  const _version: number = 1;
  const _durationUpdateVersion: number = time.duration.days("30").toNumber();
  const _renewExpireTime: number = time.duration.years("2").toNumber();
  const _serviceFee: BigNumber = utils.parseUnits("0.002");
  const _expireEachProject: BigNumber = time.duration.years("1").toNumber();
  const _durationPaymentFee: number = time.duration.days("15").toNumber();

  // kyc
  const _uid: string = "du@devProVjp";

  before(async () => {
    KycPlatformFactory = await ethers.getContractFactory("KYCPlatform");
    [owner, account1] = await ethers.getSigners();
  });

  beforeEach(async () => {
    kycPlatform = await KycPlatformFactory.deploy();
    kycPlatform.deployed();

    await kycPlatform.setSettingKYC(
      _version,
      _durationUpdateVersion,
      _renewExpireTime
    );

    await kycPlatform.setSettingProject(
      _expireEachProject,
      _serviceFee,
      _durationPaymentFee
    );
  });

  it("Should return the correct owner", async () => {
    expect(owner.address).equal(await kycPlatform.owner());
  });

  it("Should return the correct setting", async () => {
    const settingsKyc = await kycPlatform.getSettingKYC();
    expect(settingsKyc.version).equal(_version);
    expect(settingsKyc.durationUpdateVersion).equal(_durationUpdateVersion);
    expect(settingsKyc.renewExpireTime).equal(_renewExpireTime);

    const settingsProject = await kycPlatform.getSettingProject();
    expect(settingsProject.expireEachProject).equal(_expireEachProject);
    expect(settingsProject.serviceFee).equal(_serviceFee);
    expect(settingsProject.durationPaymentFee).equal(_durationPaymentFee);
  });

  it("Should revert flow setting with wrong owner", async () => {
    await expect(
      kycPlatform
        .connect(account1)
        .setSettingKYC(_version, _durationUpdateVersion, _renewExpireTime)
    ).to.revertedWith("Ownable: caller is not the owner");
  });

  it("Should return the correct kyc member", async () => {
    const signature: string = await getCreateKYCSignature(
      _uid,
      account1.address,
      owner
    );
    await kycPlatform.connect(account1).createKYCMember(_uid, signature);
    const kycInfo = await kycPlatform.getKYCInfo(account1.address);

    expect(kycInfo.uid).equal(_uid);
    expect(kycInfo.userAddress).equal(account1.address);
    expect(kycInfo.version).equal(_version);
  });

  it("Should revert the wrong signature", async () => {
    const signature: string = await getCreateKYCSignature(
      _uid,
      account1.address,
      account1
    );
    await expect(
      kycPlatform.connect(account1).createKYCMember(_uid, signature)
    ).revertedWith("KYCPlatform: Invalid Signature");
  });

  it("Should revert duplicate kyc", async () => {
    const signature: string = await getCreateKYCSignature(
      _uid,
      account1.address,
      owner
    );
    await kycPlatform.connect(account1).createKYCMember(_uid, signature);
    await expect(
      kycPlatform.connect(account1).createKYCMember(_uid, signature)
    ).revertedWith("KYCPlatform: KYC is exist");
  });

  it("Should revert the get KYC info by expire", async () => {
    const signature: string = await getCreateKYCSignature(
      _uid,
      account1.address,
      owner
    );

    await kycPlatform.connect(account1).createKYCMember(_uid, signature);

    await time.increase(_renewExpireTime);
    await expect(kycPlatform.getKYCInfo(account1.address)).revertedWith(
      "KYCPlatform: KYC is expire"
    );
  });

  it("Should revert the get KYC info by version", async () => {
    const signature: string = await getCreateKYCSignature(
      _uid,
      account1.address,
      owner
    );

    await kycPlatform.connect(account1).createKYCMember(_uid, signature);

    await kycPlatform.setSettingKYC(
      _version + 1,
      _durationUpdateVersion,
      _renewExpireTime
    );
    await expect(kycPlatform.getKYCInfo(account1.address)).revertedWith(
      "KYCPlatform: Version KYC of user not correct"
    );
  });

  async function getCreateKYCSignature(
    _uid: string,
    _address: string,
    _singer: SignerWithAddress
  ) {
    // call to contract with parameters
    const hash = await kycPlatform.getCreateKYCMessageHash(_uid, _address);
    // Sign this message hash with private key and account address
    const signature = await web3.eth.sign(hash, _singer.address);
    return signature;
  }
});
