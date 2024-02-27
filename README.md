# Script TV Smart Contracts
This project is a Watch 2 Earn platform, which pays the user when they watch content on the platform.

## Description
Script TV is a decentralized video delivery network that furnishes an expansive range of blockchain-enabled solutions to the problems related to the traditional video-streaming sector. The platform offers high-quality video streaming as well as multiple incentive mechanisms for decentralized bandwidth and content-sharing at a reduced cost as compared to conventional service providers.

## Getting Started

### Installation
Use npm to install the dependencies as follows

```bash
npm install
```

### Run tests
Tests can be run with Hardhat as follows
```
npx hardhat test 
```

### Directory
```
contracts
├── ScriptGem
│   ├── IScriptGem.sol
│   └── ScriptGem.sol
├── ScriptGlasses
│   ├── IScriptGlasses.sol
│   └── ScriptGlasses.sol
├── ScriptPay
│   ├── IScriptPay.sol
│   └── ScriptPay.sol
├── ScriptTV.sol
└── enums
    └── ScriptNFTType.sol
scripts
└── deploy.ts
test
└── index.ts
```

## License
[MIT](https://choosealicense.com/licenses/mit/)
