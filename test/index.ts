/* eslint-disable node/no-extraneous-import */
/* eslint-disable node/no-missing-import */
/* eslint-disable camelcase */
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ContractTransaction } from "ethers";
import { ethers } from "hardhat";
import { VaccinePassport } from "../typechain/VaccinePassport";

let vaccinePassport: VaccinePassport;
let owner: SignerWithAddress;
let addr1: SignerWithAddress;
let tx: ContractTransaction;

describe("Initialization", async () => {
  it("Should have owner and user", async () => {
    [owner, addr1] = await ethers.getSigners();
    expect(owner).to.be.an.instanceOf(SignerWithAddress);
    expect(addr1).to.be.an.instanceOf(SignerWithAddress);
  });
});

describe("Deployment", function () {
  it("Should deploy success", async function () {
    const VaccinePassportFactory = await ethers.getContractFactory(
      "VaccinePassport"
    );
    vaccinePassport = await VaccinePassportFactory.deploy();
    await vaccinePassport.connect(owner).deployed();
    expect(vaccinePassport.address).to.be.a("string");
  });
});

describe("VaccinePassport Execute", function () {
  it("Should owner add record", async () => {
    await vaccinePassport
      .connect(owner)
      .addVaccineRecord(addr1.address, "user1", "AAA", "HK");
  });
  it("Should user create read record", async () => {
    tx = await vaccinePassport.connect(addr1).createReadVaccineRecord();
    expect(tx.hash).to.be.a("string");
  });
  it("Should user confirm read record", async () => {
    const transaction = await vaccinePassport
      .connect(addr1)
      .confirmReadVaccineRecord(tx.value);
    const confirmNumber = await vaccinePassport
      .connect(addr1)
      .getConfirmNumber(tx.value);
    expect(transaction.hash).to.be.a("string");
    expect(confirmNumber).to.equal(1);
  });
  it("Should owner confirm read record", async () => {
    const transaction = await vaccinePassport
      .connect(owner)
      .confirmReadVaccineRecord(tx.value);
    const confirmNumber = await vaccinePassport
      .connect(owner)
      .getConfirmNumber(tx.value);
    expect(transaction.hash).to.be.a("string");
    expect(confirmNumber).to.equal(2);
  });
  it("Should owner get record", async () => {
    const record = await vaccinePassport
      .connect(owner)
      .executeReadVaccineRecord(tx.value);
    const rc = await record.wait();
    const event = rc.events?.find((e) => e.event === "VaccineRecordAdded");
    expect(event?.args?._userAddress).to.equal(addr1.address);
    expect(event?.args?._username).to.equal("user1");
    expect(event?.args?._vaccineName).to.equal("AAA");
    expect(event?.args?._location).to.equal("HK");
    expect(event?.args?._timestamp.toNumber()).to.be.a("number");
  });
});
