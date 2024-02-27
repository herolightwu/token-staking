import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "@nomicfoundation/hardhat-chai-matchers";
import "hardhat-abi-exporter";

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
module.exports = {
  defaultNetwork: 'hardhat',
  gasReporter: {
    enabled: process.env.IS_GAS_REPORTED_ENABLED === 'true',
    currency: 'USD',
  },
  abiExporter: [
    {
      path: './abi/flat',
      runOnCompile: true,
      clear: true,
      flat: true,
    },
    {
      path: './abi/raw',
      runOnCompile: true,
      clear: true,
      flat: false,
    },
  ],
  namedAccounts: {
    deployer: {
      default: 0,
    },
    dev: {
      default: 1,
    },
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      forking: {
        enabled: process.env.FORKING === 'true',
        url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.MUMBAI_API_KEY}`,
      },
      live: false,
      saveDeployments: true,
      tags: ['test', 'local'],
    }, 
    bsctest: {
      url: process.env.BSC_URL || "",
      chainId: 97,
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  watcher: {
    compilation: {
      tasks: ['compile'],
      files: ['./contracts'],
      verbose: true,
    },
    ci: {
      tasks: [
        'clean',
        { command: 'compile', params: { quiet: true } },
        {
          command: 'test',
          params: { noCompile: true, testFiles: ['*.test.ts'] },
        },
      ],
    },
  },
  paths: {
    sources: './contracts',
    deploy: './scripts',
    deployments: 'deployments',
    imports: 'imports',
    tests: 'test',
  },
  solidity: {
    compilers: [
      {
        version: '0.8.17',
      },
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 800,
      },
    },
  },
  etherscan: {
    apiKey: process.env.BSCSCAN_API_KEY,
  },
  spdxLicenseIdentifier: {
    overwrite: true,
    runOnCompile: true,
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: false,
    disambiguatePaths: false,
  },
  mocha: {
    timeout: 180000,
  },
};

// const config: HardhatUserConfig = {
//   solidity: {
//     version: "0.8.17",
//     settings: {
//       optimizer: {
//         enabled: true,
//         runs: 200
//       }
//     }
//   },
//   paths: {
//     sources: './contracts',
//     tests: './test',
//   },
//   networks: {
//     ropsten: {
//       url: process.env.ROPSTEN_URL || "",
//       accounts:
//         process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
//     },
//     bsctest: {
//       url: process.env.BSC_URL || "",
//       chainId: 97,
//       accounts:
//         process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
//     },
//   },
//   gasReporter: {
//     enabled: process.env.REPORT_GAS !== undefined,
//     currency: "USD",
//   },
//   etherscan: {
//     apiKey: process.env.BSCSCAN_API_KEY,
//   },
// };

// export default config;
