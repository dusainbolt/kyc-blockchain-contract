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

  const _uid: string = "du@devProVjp";

  before(async () => {
    KycPlatformFactory = await ethers.getContractFactory("KYCPlatform");
    [owner, account1] = await ethers.getSigners();
  });

  beforeEach(async () => {
    kycPlatform = await KycPlatformFactory.deploy();
    kycPlatform.deployed();

    await kycPlatform.setSetting(
      _version,
      _durationUpdateVersion,
      _renewExpireTime,
      _serviceFee
    );
  });

  it("Should return the correct owner", async () => {
    expect(owner.address).equal(await kycPlatform.owner());
  });

  it("Should return the correct setting", async () => {
    const settings = await kycPlatform.getSetting();
    expect(settings.version).equal(_version);
    expect(settings.durationUpdateVersion).equal(_durationUpdateVersion);
    expect(settings.renewExpireTime).equal(_renewExpireTime);
    expect(settings.serviceFee).equal(_serviceFee);
  });

  it("Should revert flow setting with wrong owner", async () => {
    await expect(
      kycPlatform
        .connect(account1)
        .setSetting(
          _version,
          _durationUpdateVersion,
          _renewExpireTime,
          _serviceFee
        )
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
