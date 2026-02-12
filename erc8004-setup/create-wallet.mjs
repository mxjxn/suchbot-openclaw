import { createWallet, getAddress, hasWallet } from '@buildersgarden/siwa/keystore';

// Set env vars for SDK
process.env.KEYRING_PROXY_URL = 'http://localhost:3100';
process.env.KEYRING_PROXY_SECRET = 'aea42180ccae5be98aa10a54aaf18f73b651816760b930c612cb1c480c47cc78';

async function main() {
  // Check if wallet already exists
  const exists = await hasWallet();
  console.log('Wallet exists:', exists);
  
  if (!exists) {
    console.log('Creating new wallet...');
    const info = await createWallet();
    console.log('Wallet created!');
    console.log('Address:', info.address);
    console.log('Backend:', info.backend);
  } else {
    const address = await getAddress();
    console.log('Existing wallet address:', address);
  }
}

main().catch(console.error);
