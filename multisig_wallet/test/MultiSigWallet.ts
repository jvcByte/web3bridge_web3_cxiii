import { expect } from "chai";
import { ethers } from "hardhat";
import { MultiSigWallet, TestContract } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";


describe("⚗️.🔎 MultiSigWallet Testing :", function () {
  let AddressZero: string;
  let multiSigWallet: MultiSigWallet;
  let testContract: TestContract;
  let owner1: SignerWithAddress;
  let owner2: SignerWithAddress;
  let owner3: SignerWithAddress;
  let nonOwner: SignerWithAddress;
  let owners: string[];
  const requiredConfirmations = 2;

  beforeEach(async function () {
    AddressZero = "0x0000000000000000000000000000000000000000";
    [owner1, owner2, owner3, nonOwner] = await ethers.getSigners();
    owners = [owner1.address, owner2.address, owner3.address];

    // Deploy MultiSigWallet
    const MultiSigWalletFactory = await ethers.getContractFactory("MultiSigWallet");
    multiSigWallet = await MultiSigWalletFactory.deploy(owners, requiredConfirmations);

    // Deploy TestContract for testing contract interactions
    const TestContractFactory = await ethers.getContractFactory("TestContract");
    testContract = await TestContractFactory.deploy();

    // Fund the wallet
    await owner1.sendTransaction({
      to: await multiSigWallet.getAddress(),
      value: ethers.parseEther("10")
    });
  });

  describe("Constructor", function () {
    it("Should set the right owners and required confirmations", async function () {
      expect(await multiSigWallet.requiredConfirmations()).to.equal(requiredConfirmations);

      const deployedOwners = await multiSigWallet.getOwners();
      expect(deployedOwners).to.deep.equal(owners);

      expect(await multiSigWallet.isOwner(owner1.address)).to.be.true;
      expect(await multiSigWallet.isOwner(owner2.address)).to.be.true;
      expect(await multiSigWallet.isOwner(owner3.address)).to.be.true;
      expect(await multiSigWallet.isOwner(nonOwner.address)).to.be.false;
    });

    it("Should revert with empty owners array", async function () {
      const MultiSigWalletFactory = await ethers.getContractFactory("MultiSigWallet");
      await expect(
        MultiSigWalletFactory.deploy([], 1)
      ).to.be.revertedWithCustomError(multiSigWallet, "InvalidOwner");
    });

    it("Should revert with zero required confirmations", async function () {
      const MultiSigWalletFactory = await ethers.getContractFactory("MultiSigWallet");
      await expect(
        MultiSigWalletFactory.deploy(owners, 0)
      ).to.be.revertedWithCustomError(multiSigWallet, "InvalidRequiredConfirmations");
    });

    it("Should revert with too many required confirmations", async function () {
      const MultiSigWalletFactory = await ethers.getContractFactory("MultiSigWallet");
      await expect(
        MultiSigWalletFactory.deploy(owners, 4)
      ).to.be.revertedWithCustomError(multiSigWallet, "InvalidRequiredConfirmations");
    });

    it("Should revert with zero address owner", async function () {
      const MultiSigWalletFactory = await ethers.getContractFactory("MultiSigWallet");
      const invalidOwners = [owner1.address, AddressZero];
      await expect(
        MultiSigWalletFactory.deploy(invalidOwners, 1)
      ).to.be.revertedWithCustomError(multiSigWallet, "ZeroAddress");
    });

    it("Should revert with duplicate owners", async function () {
      const MultiSigWalletFactory = await ethers.getContractFactory("MultiSigWallet");
      const duplicateOwners = [owner1.address, owner1.address];
      await expect(
        MultiSigWalletFactory.deploy(duplicateOwners, 1)
      ).to.be.revertedWithCustomError(multiSigWallet, "DuplicateOwner");
    });
  });

  describe(" Deposits", function () {
    it("Should receive ETH and emit Deposit event", async function () {
      const depositAmount = ethers.parseEther("1");

      await expect(
        nonOwner.sendTransaction({
          to: await multiSigWallet.getAddress(),
          value: depositAmount
        })
      ).to.emit(multiSigWallet, "Deposit")
        .withArgs(nonOwner.address, depositAmount);

      expect(await multiSigWallet.getBalance()).to.equal(ethers.parseEther("11"));
    });
  });

  describe("Submit Transaction", function () {
    it("Should submit transaction and emit event", async function () {
      const to = owner2.address;
      const value = ethers.parseEther("1");
      const data = "0x";

      await expect(
        multiSigWallet.connect(owner1).submitTransaction(to, value, data)
      ).to.emit(multiSigWallet, "TransactionSubmitted")
        .withArgs(0, to, value);

      expect(await multiSigWallet.getTransactionCount()).to.equal(1);

      const transaction = await multiSigWallet.getTransaction(0);
      expect(transaction.to).to.equal(to);
      expect(transaction.value).to.equal(value);
      expect(transaction.data).to.equal(data);
      expect(transaction.executed).to.be.false;
      expect(transaction.confirmationCount).to.equal(0);
    });

    it("Should submit transaction with data", async function () {
      const data = testContract.interface.encodeFunctionData("setValue", [42]);

      await multiSigWallet
        .connect(owner1)
        .submitTransaction(await testContract.getAddress(), 0, data);

      const transaction = await multiSigWallet.getTransaction(0);
      expect(transaction.to).to.equal(await testContract.getAddress());
      expect(transaction.value).to.equal(0);
      expect(transaction.data).to.equal(data);
    });

    it("Should revert if not owner", async function () {
      await expect(
        multiSigWallet.connect(nonOwner).submitTransaction(owner2.address, ethers.parseEther("1"), "0x")
      ).to.be.revertedWithCustomError(multiSigWallet, "NotOwner");
    });
  });

  describe("Confirm Transaction", function () {
    let txId: number;

    beforeEach(async function () {
      await multiSigWallet.connect(owner1).submitTransaction(owner2.address, ethers.parseEther("1"), "0x");
      txId = 0;
    });

    it("Should confirm transaction and emit event", async function () {
      await expect(
        multiSigWallet.connect(owner1).confirmTransaction(txId)
      ).to.emit(multiSigWallet, "TransactionConfirmed")
        .withArgs(txId, owner1.address);

      expect(await multiSigWallet.isConfirmedBy(txId, owner1.address)).to.be.true;
      expect(await multiSigWallet.getConfirmationCount(txId)).to.equal(1);
    });

    it("Should revert if not owner", async function () {
      await expect(
        multiSigWallet.connect(nonOwner).confirmTransaction(txId)
      ).to.be.revertedWithCustomError(multiSigWallet, "NotOwner");
    });

    it("Should revert if transaction doesn't exist", async function () {
      await expect(
        multiSigWallet.connect(owner1).confirmTransaction(999)
      ).to.be.revertedWithCustomError(multiSigWallet, "TransactionNotExists");
    });

    it("Should revert if already confirmed by same owner", async function () {
      await multiSigWallet.connect(owner1).confirmTransaction(txId);

      await expect(
        multiSigWallet.connect(owner1).confirmTransaction(txId)
      ).to.be.revertedWithCustomError(multiSigWallet, "TransactionAlreadyConfirmed");
    });

    it("Should revert if transaction already executed", async function () {
      await multiSigWallet.connect(owner1).confirmTransaction(txId);
      await multiSigWallet.connect(owner2).confirmTransaction(txId);
      await multiSigWallet.connect(owner1).executeTransaction(txId);

      await expect(
        multiSigWallet.connect(owner3).confirmTransaction(txId)
      ).to.be.revertedWithCustomError(multiSigWallet, "TransactionAlreadyExecuted");
    });
  });

  describe("Revoke Confirmation", function () {
    let txId: number;

    beforeEach(async function () {
      await multiSigWallet.connect(owner1).submitTransaction(owner2.address, ethers.parseEther("1"), "0x");
      txId = 0;
      await multiSigWallet.connect(owner1).confirmTransaction(txId);
    });

    it("Should revoke confirmation and emit event", async function () {
      await expect(
        multiSigWallet.connect(owner1).revokeConfirmation(txId)
      ).to.emit(multiSigWallet, "TransactionRevoked")
        .withArgs(txId, owner1.address);

      expect(await multiSigWallet.isConfirmedBy(txId, owner1.address)).to.be.false;
      expect(await multiSigWallet.getConfirmationCount(txId)).to.equal(0);
    });

    it("Should revert if not owner", async function () {
      await expect(
        multiSigWallet.connect(nonOwner).revokeConfirmation(txId)
      ).to.be.revertedWithCustomError(multiSigWallet, "NotOwner");
    });

    it("Should revert if not confirmed by owner", async function () {
      await expect(
        multiSigWallet.connect(owner2).revokeConfirmation(txId)
      ).to.be.revertedWithCustomError(multiSigWallet, "TransactionNotConfirmed");
    });

    it("Should revert if transaction already executed", async function () {
      await multiSigWallet.connect(owner2).confirmTransaction(txId);
      await multiSigWallet.connect(owner1).executeTransaction(txId);

      await expect(
        multiSigWallet.connect(owner1).revokeConfirmation(txId)
      ).to.be.revertedWithCustomError(multiSigWallet, "TransactionAlreadyExecuted");
    });
  });

  describe("Execute Transaction", function () {
    let txId: number;

    beforeEach(async function () {
      await multiSigWallet.connect(owner1).submitTransaction(owner2.address, ethers.parseEther("1"), "0x");
      txId = 0;
    });

    it("Should execute transaction when enough confirmations", async function () {
      await multiSigWallet.connect(owner1).confirmTransaction(txId);
      await multiSigWallet.connect(owner2).confirmTransaction(txId);

      const balanceBefore = await ethers.provider.getBalance(owner2.address);

      await expect(
        multiSigWallet.connect(owner1).executeTransaction(txId)
      ).to.emit(multiSigWallet, "TransactionExecuted")
        .withArgs(txId);

      const balanceAfter = await ethers.provider.getBalance(owner2.address);
      expect(balanceAfter - balanceBefore).to.equal(ethers.parseEther("1"));

      const transaction = await multiSigWallet.getTransaction(txId);
      expect(transaction.executed).to.be.true;
    });

    it("Should execute transaction with data", async function () {
      const data = testContract.interface.encodeFunctionData("setValue", [42]);
      await multiSigWallet.connect(owner1).submitTransaction(await testContract.getAddress(), 0, data);

      const newTxId = 1;
      await multiSigWallet.connect(owner1).confirmTransaction(newTxId);
      await multiSigWallet.connect(owner2).confirmTransaction(newTxId);
      await multiSigWallet.connect(owner1).executeTransaction(newTxId);

      expect(await testContract.value()).to.equal(42);
    });

    it("Should revert with insufficient confirmations", async function () {
      await multiSigWallet.connect(owner1).confirmTransaction(txId);

      await expect(
        multiSigWallet.connect(owner1).executeTransaction(txId)
      ).to.be.revertedWithCustomError(multiSigWallet, "InsufficientConfirmations");
    });

    it("Should revert if not owner", async function () {
      await multiSigWallet.connect(owner1).confirmTransaction(txId);
      await multiSigWallet.connect(owner2).confirmTransaction(txId);

      await expect(
        multiSigWallet.connect(nonOwner).executeTransaction(txId)
      ).to.be.revertedWithCustomError(multiSigWallet, "NotOwner");
    });

    it("Should revert if already executed", async function () {
      await multiSigWallet.connect(owner1).confirmTransaction(txId);
      await multiSigWallet.connect(owner2).confirmTransaction(txId);
      await multiSigWallet.connect(owner1).executeTransaction(txId);

      await expect(
        multiSigWallet.connect(owner1).executeTransaction(txId)
      ).to.be.revertedWithCustomError(multiSigWallet, "TransactionAlreadyExecuted");
    });

    it("Should revert if external call fails", async function () {
      const data = testContract.interface.encodeFunctionData("revertFunction");
      await multiSigWallet.connect(owner1).submitTransaction(await testContract.getAddress(), 0, data);

      const newTxId = 1;
      await multiSigWallet.connect(owner1).confirmTransaction(newTxId);
      await multiSigWallet.connect(owner2).confirmTransaction(newTxId);

      await expect(
        multiSigWallet.connect(owner1).executeTransaction(newTxId)
      ).to.be.revertedWithCustomError(multiSigWallet, "TransactionFailed");
    });
  });

  describe("Complex Workflows", function () {
    it("Should handle multiple transactions workflow", async function () {
      // Submit multiple transactions
      await multiSigWallet.connect(owner1).submitTransaction(owner2.address, ethers.parseEther("1"), "0x");
      await multiSigWallet.connect(owner2).submitTransaction(owner3.address, ethers.parseEther("2"), "0x");

      expect(await multiSigWallet.getTransactionCount()).to.equal(2);

      // Confirm first transaction
      await multiSigWallet.connect(owner1).confirmTransaction(0);
      await multiSigWallet.connect(owner2).confirmTransaction(0);

      // Partially confirm second transaction
      await multiSigWallet.connect(owner1).confirmTransaction(1);

      // Execute first transaction
      await multiSigWallet.connect(owner1).executeTransaction(0);

      // Complete and execute second transaction
      await multiSigWallet.connect(owner3).confirmTransaction(1);
      await multiSigWallet.connect(owner2).executeTransaction(1);

      const tx1 = await multiSigWallet.getTransaction(0);
      const tx2 = await multiSigWallet.getTransaction(1);

      expect(tx1.executed).to.be.true;
      expect(tx2.executed).to.be.true;
    });

    it("Should handle confirm and revoke cycles", async function () {
      await multiSigWallet.connect(owner1).submitTransaction(owner2.address, ethers.parseEther("1"), "0x");
      const txId = 0;

      // Confirm, revoke, confirm again
      await multiSigWallet.connect(owner1).confirmTransaction(txId);
      expect(await multiSigWallet.getConfirmationCount(txId)).to.equal(1);

      await multiSigWallet.connect(owner1).revokeConfirmation(txId);
      expect(await multiSigWallet.getConfirmationCount(txId)).to.equal(0);

      await multiSigWallet.connect(owner1).confirmTransaction(txId);
      expect(await multiSigWallet.getConfirmationCount(txId)).to.equal(1);

      // Should still be able to execute
      await multiSigWallet.connect(owner2).confirmTransaction(txId);
      await multiSigWallet.connect(owner1).executeTransaction(txId);

      const transaction = await multiSigWallet.getTransaction(txId);
      expect(transaction.executed).to.be.true;
    });
  });

  describe("View Functions", function () {
    it("Should return correct owners", async function () {
      const returnedOwners = await multiSigWallet.getOwners();
      expect(returnedOwners).to.deep.equal(owners);
    });

    it("Should return correct balance", async function () {
      expect(await multiSigWallet.getBalance()).to.equal(ethers.parseEther("10"));
    });

    it("Should return correct transaction count", async function () {
      expect(await multiSigWallet.getTransactionCount()).to.equal(0);

      await multiSigWallet.connect(owner1).submitTransaction(owner2.address, ethers.parseEther("1"), "0x");
      expect(await multiSigWallet.getTransactionCount()).to.equal(1);
    });

    it("Should return correct confirmation status", async function () {
      await multiSigWallet.connect(owner1).submitTransaction(owner2.address, ethers.parseEther("1"), "0x");
      const txId = 0;

      expect(await multiSigWallet.isConfirmedBy(txId, owner1.address)).to.be.false;

      await multiSigWallet.connect(owner1).confirmTransaction(txId);
      expect(await multiSigWallet.isConfirmedBy(txId, owner1.address)).to.be.true;
    });
  });
});