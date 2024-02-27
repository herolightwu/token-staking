import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, waffle } from "hardhat";
import {
    ScriptToken,
    ScriptToken__factory,
    ScriptPay,
    ScriptPay__factory,
    ScriptStaking,
    ScriptStaking__factory,
    GlassPass,
    GlassPass__factory
} from "../typechain";
import { expect } from "chai";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { BigNumber } from "ethers";

const tokens = (n: string) => ethers.utils.parseUnits(n);
const number = (n: string) => ethers.utils.formatUnits(n);

const createFixtureLoader = waffle.createFixtureLoader;
let loadFixture: ReturnType<typeof createFixtureLoader>;


const ONE_DAY = 24 * 3600;
const TWO_DAY = 2 * 24 * 3600;
const ONE_WEEK = 7 * 24 * 3600;
const THREE_WEEK = 21 * 24 * 3600;
const YEAR = 365 * 24 * 3600;
enum StakingPeriod { OneWeek, ThreeWeeks, TwoMonths, ThreeMonths, FourMonths, SixMonths, OneYear }

describe("Script Staking", function () {
    async function deployContractsFixture() {
        let [owner, alice, bob] = await ethers.getSigners();

        let spay = await new ScriptPay__factory(owner).deploy();
        await spay.deployed();

        let scpToken = await new ScriptToken__factory(owner).deploy();
        await scpToken.deployed();

        let glassPass = await new GlassPass__factory(owner).deploy()
        await glassPass.deployed();

        // getting timestamp
        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        const timestampBefore = blockBefore.timestamp;

        let staking = await new ScriptStaking__factory(owner).deploy(
            scpToken.address,
            spay.address,
            glassPass.address,
            timestampBefore + ONE_DAY,
            timestampBefore + TWO_DAY,
            timestampBefore + YEAR ,
            tokens("1000000"),
            tokens("20000")
        );
        await staking.deployed();

        // Transfer 1000000 scpt to staking: 1000000 -> 1000000 * 10**18
        await scpToken.connect(owner).transfer(staking.address, tokens("1000000"));
        // Transfer 1000000 spay to staking: 1000000 -> 1000000 * 10**18
        await spay.connect(owner).transfer(staking.address, tokens("1000000"));
        // Transfer 1000000 scpt to alice and bob: 2000000 -> 2000000 * 10**18
        await scpToken.connect(owner).transfer(alice.address, tokens("2000000"));
        await scpToken.connect(owner).transfer(bob.address, tokens("2000000"));
        
        // Fixtures can return anything you consider useful for your tests
        return { spay, scpToken, glassPass, staking, owner, alice, bob };
    }

    before("fixtures deployer", async () => {
        const [owner] = waffle.provider.getWallets();
        loadFixture = createFixtureLoader([owner]);
    });

    it("should initialize the contract correctly", async function () {
        const { scpToken, staking} = await loadFixture(deployContractsFixture);
        expect(await scpToken.balanceOf(staking.address)).to.equal(tokens("1000000"));
        expect(await staking.lockedAmount()).to.equal(tokens("1000000"));
    });

    describe("Staking Process", function () {
        let spay: ScriptPay, scpToken: ScriptToken, glassPass: GlassPass, staking: ScriptStaking, alice: SignerWithAddress, bob: SignerWithAddress, owner: SignerWithAddress;
    
        before(async function () {
          ({ spay, scpToken, glassPass, staking, owner, alice, bob} = await loadFixture(deployContractsFixture));
          await staking.connect(owner).setnft_price([0,1,2,3,4,5], [tokens("1"),tokens("1"),tokens("1"), tokens("1"), tokens("1"), tokens("1")]);
        });
    
        it("alice stakes 100000 with one week", async function () {
            // getting timestamp
            const blockNumBefore = await ethers.provider.getBlockNumber();
            const blockBefore = await ethers.provider.getBlock(blockNumBefore);
            const timestampBefore = blockBefore.timestamp;
            console.log("current time : ", timestampBefore);

            const amount = tokens("10000");
            await scpToken.connect(alice).approve(staking.address, amount);
            await expect(staking.connect(alice).stake(StakingPeriod.OneWeek, amount)).to.be.revertedWith('Staking: Unable to stake before deposit start!');

            // advance time by one day and mine a new block
            await time.increase(ONE_DAY);
            // alice deposit 10000
            let balance = await scpToken.balanceOf(alice.address);
            console.log("alice balance before staking: ", balance);
            
            await staking.connect(alice).stake(StakingPeriod.OneWeek, amount);
            balance = await scpToken.balanceOf(alice.address);
            console.log("alice balance after staking: ", balance);
            expect(balance).to.equal(tokens("1990000"));

            expect(await staking.totalAmount()).to.equal(tokens("10000"));
        });

        it("nft mint and staking", async function () {
            await glassPass.connect(alice).safeMint(alice.address);
            const nft_owner = await glassPass.connect(alice).ownerOf(BigNumber.from(1));
            expect(nft_owner).to.equal(alice.address);
            const tx = await glassPass.setApprovalForAll(staking.address, true); // Approving staking contract to handle NFTs
            await tx.wait();
            await glassPass.connect(alice).approve(staking.address, BigNumber.from(1));

            let balance = await staking.connect(alice).totalAmount();
            console.log("staking total before staking: ", balance);

            await staking.connect(alice).stake_nft(StakingPeriod.OneWeek, [BigNumber.from(1)]);
            balance = await staking.connect(alice).totalAmount();
            console.log("staking total after staking: ", balance);
        });

        it("bob stakes 100000 with three week", async function () {
            // getting timestamp
            const blockNumBefore = await ethers.provider.getBlockNumber();
            const blockBefore = await ethers.provider.getBlock(blockNumBefore);
            const timestampBefore = blockBefore.timestamp;
            console.log("current time : ", timestampBefore);
            
            // bob deposit 10000
            let balance = await scpToken.balanceOf(bob.address);
            console.log("bob balance before staking: ", balance);
            const amount = tokens("10000");
            await scpToken.connect(bob).approve(staking.address, amount);
            await staking.connect(bob).stake(StakingPeriod.ThreeWeeks, amount);
            balance = await scpToken.balanceOf(bob.address);
            console.log("bob balance after staking: ", balance);
            expect(balance).to.equal(tokens("1990000"));

            expect(await staking.totalAmount()).to.equal(tokens("20001")); //add 1 for nft 
        });

        it("claim reward of alice in one week", async function () {
            // getting timestamp
            const blockNumBefore = await ethers.provider.getBlockNumber();
            const blockBefore = await ethers.provider.getBlock(blockNumBefore);
            const timestampBefore = blockBefore.timestamp;
            console.log("current time : ", timestampBefore);
            // advance time by one day and mine a new block
            await time.increase(ONE_WEEK);
                        
            let balance = await scpToken.balanceOf(alice.address);
            console.log("alice balance before claim: ", balance);
            // calculate reward of alice
            const amount = await staking.connect(alice).calculateEarnedAmount(alice.address);
            console.log("alice reward amount: ", amount);
            // claim reward
            await staking.connect(alice).claimReward(alice.address);
            let fbalance = await scpToken.balanceOf(alice.address);
            console.log("alice balance after claim: ", fbalance);
            expect(fbalance).to.greaterThan(balance.add(amount));
        });

        it("claim reward of bob in three week", async function () {
            // getting timestamp
            const blockNumBefore = await ethers.provider.getBlockNumber();
            const blockBefore = await ethers.provider.getBlock(blockNumBefore);
            const timestampBefore = blockBefore.timestamp;
            console.log("current time : ", timestampBefore);
            // advance time by one day and mine a new block
            await time.increase(THREE_WEEK);
                        
            let balance = await scpToken.balanceOf(bob.address);
            console.log("bob balance before claim: ", balance);
            // calculate reward of bob
            const amount = await staking.connect(bob).calculateEarnedAmount(bob.address);
            console.log("bob reward amount: ", amount);
            // claim reward
            await staking.connect(bob).claimReward(bob.address);
            let fbalance = await scpToken.balanceOf(bob.address);
            console.log("bob balance after claim: ", fbalance);
            expect(fbalance).to.greaterThan(balance.add(amount));
        });

        it("staked amounts per staking period", async function () {
            
            expect((await staking.stakingOptions(StakingPeriod.OneWeek)).total).to.equal(tokens("10001")); //add 1 for nft 
            expect((await staking.stakingOptions(StakingPeriod.ThreeWeeks)).total).to.equal(tokens("10000"));
        });

        it("alice can not unstake before stakingEnd", async function () {
            await expect(staking.connect(alice).unstake()).to.be.revertedWith('Staking: Unable to unstake before stakingEnd!');

        });

        it("alice can unstake in stakingEnd", async function () {
            await time.increase(YEAR);
            // await staking.connect(alice).claimReward();
            let fbalance = await scpToken.balanceOf(alice.address);
            console.log("alice balance before unstake: ", fbalance);
            await staking.connect(alice).unstake();
            fbalance = await scpToken.balanceOf(alice.address);
            console.log("alice balance after unstake: ", fbalance);
        });

    });

});