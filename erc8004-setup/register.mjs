import { signTransaction, getAddress } from '@buildersgarden/siwa/keystore';
import { ethers } from 'ethers';
import fs from 'fs';

// Set env vars for SDK
process.env.KEYRING_PROXY_URL = 'http://localhost:3100';
process.env.KEYRING_PROXY_SECRET = 'aea42180ccae5be98aa10a54aaf18f73b651816760b930c612cb1c480c47cc78';

// Base mainnet config
const RPC_URL = 'https://mainnet.base.org';
const CHAIN_ID = 8453;
const IDENTITY_REGISTRY = '0x8004A169FB4a3325136EB29fA0ceB6D2e539a432';

const IDENTITY_REGISTRY_ABI = [
  'function register(string agentURI) external returns (uint256 agentId)',
  'event Registered(uint256 indexed agentId, string agentURI, address indexed owner)'
];

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const address = await getAddress();
  
  console.log('Agent wallet:', address);
  
  // Check balance
  const balance = await provider.getBalance(address);
  console.log('Balance:', ethers.formatEther(balance), 'ETH');
  
  if (balance === 0n) {
    console.log('\n⚠️  Wallet has no ETH. Please fund it first:');
    console.log(`   Address: ${address}`);
    console.log('   Chain: Base Sepolia (chainId 84532)');
    console.log('   Faucet: https://www.alchemy.com/faucets/base-sepolia');
    process.exit(1);
  }
  
  // Build data URI from registration.json
  const regFile = JSON.parse(fs.readFileSync('./registration.json', 'utf8'));
  const encoded = Buffer.from(JSON.stringify(regFile)).toString('base64');
  const agentURI = `data:application/json;base64,${encoded}`;
  
  console.log('\nRegistration metadata:');
  console.log('  Name:', regFile.name);
  console.log('  URI length:', agentURI.length, 'chars');
  
  // Build transaction
  const iface = new ethers.Interface(IDENTITY_REGISTRY_ABI);
  const data = iface.encodeFunctionData('register', [agentURI]);
  const nonce = await provider.getTransactionCount(address);
  const feeData = await provider.getFeeData();
  
  const gasEstimate = await provider.estimateGas({
    to: IDENTITY_REGISTRY,
    data,
    from: address
  });
  
  console.log('\nTransaction details:');
  console.log('  To:', IDENTITY_REGISTRY);
  console.log('  Nonce:', nonce);
  console.log('  Gas estimate:', gasEstimate.toString());
  
  const txReq = {
    to: IDENTITY_REGISTRY,
    data,
    nonce,
    chainId: CHAIN_ID,
    type: 2,
    maxFeePerGas: feeData.maxFeePerGas,
    maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
    gasLimit: gasEstimate * 120n / 100n, // 20% buffer
  };
  
  console.log('\nSigning transaction via keyring proxy...');
  const { signedTx } = await signTransaction(txReq);
  
  console.log('Broadcasting transaction...');
  const txResponse = await provider.broadcastTransaction(signedTx);
  console.log('TX hash:', txResponse.hash);
  
  console.log('Waiting for confirmation...');
  const receipt = await txResponse.wait();
  console.log('Confirmed in block:', receipt.blockNumber);
  
  // Parse event for agentId
  for (const log of receipt.logs) {
    try {
      const parsed = iface.parseLog({ topics: log.topics, data: log.data });
      if (parsed?.name === 'Registered') {
        const agentId = parsed.args.agentId.toString();
        console.log('\n✅ Registration successful!');
        console.log('  Agent ID:', agentId);
        console.log('  Agent Registry: eip155:84532:' + IDENTITY_REGISTRY);
        console.log('  View on 8004scan: https://www.8004scan.io/agent/' + agentId);
      }
    } catch { /* skip non-matching logs */ }
  }
}

main().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
