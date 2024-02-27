// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import {
  ScriptToken__factory,
  ScriptPay__factory,
  ScriptStaking__factory,
  GlassPass__factory
} from "../typechain";
import { sleep } from "./utils";
import { run } from "hardhat";


/**
 * @usage yarn hardhat deploy --network bsctest
 */

const ONE_DAY = 24 * 3600;
const TWO_DAY = 2 * 24 * 3600;
const ONE_WEEK = 7 * 24 * 3600;
const THREE_WEEK = 21 * 24 * 3600;
const YEAR = 365 * 24 * 3600;

const tokens = (n: string) => ethers.utils.parseUnits(n);

async function main() {
  const [owner] = await ethers.getSigners();

  const scriptPay = await new ScriptPay__factory(owner).deploy();
  await scriptPay.deployed();

  console.log("1. ScriptPay deployed to:", scriptPay.address);

  const scpToken = await new ScriptToken__factory(owner).deploy();
  await scpToken.deployed();

  console.log("2. ScriptToken deployed to:", scpToken.address);

  const glassPass = await new GlassPass__factory(owner).deploy()
  await glassPass.deployed();

  console.log("3. GlassPass deployed to:", glassPass.address);

  // getting timestamp
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);
  const timestampBefore = blockBefore.timestamp;

  const staking = await new ScriptStaking__factory(owner).deploy(
      scpToken.address,
      scriptPay.address,
      glassPass.address,
      timestampBefore + ONE_DAY,
      timestampBefore + THREE_WEEK,
      timestampBefore + YEAR ,
      tokens("100000000"),
      tokens("200000")
  );
  await staking.deployed();

  console.log("4. ScriptStaking deployed to:", staking.address);

  // Transfer 1000000 scpt to staking: 1000000 -> 1000000 * 10**18
  await scpToken.connect(owner).transfer(staking.address, tokens("100000000"));
  // Transfer 1000000 spay to staking: 1000000 -> 1000000 * 10**18
  await scriptPay.connect(owner).transfer(staking.address, tokens("100000000"));

  //verify
  await sleep(60000 * 1);

  await run("verify:verify", {
      address: staking.address,
      constructorArguments: [scpToken.address,
        scriptPay.address,
        glassPass.address,
        timestampBefore + ONE_DAY,
        timestampBefore + THREE_WEEK,
        timestampBefore + YEAR ,
        tokens("100000000"),
        tokens("200000")],
  });
  
  await sleep(60000 * 1);

  await run("verify:verify", {
      address: scriptPay.address,
      //constructorArguments: [contract.address, deployer.address],
  });

  await sleep(60000 * 1);

  await run("verify:verify", {
      address: scpToken.address,
  });

  await sleep(60000 * 1);

  await run("verify:verify", {
      address: glassPass.address,
  });  
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
