# Solana Token App

This project is a Node.js application that allows you to create and manage custom tokens on the Solana devnet. It provides functionality to create a new token, mint it to a distributor wallet, and transfer tokens to recipient wallets.

## Project Structure

```
solana-token-app
├── .env                        # Environment variables
├── info.txt                    # Example curl command for testing
├── package.json                # NPM dependencies and scripts
├── tsconfig.json               # TypeScript configuration
├── README.md                   # Project documentation
├── src
│   ├── app.ts                  # Express app setup
│   ├── createToken.ts          # Logic for creating a new token on Solana devnet
│   ├── transferToken.ts        # HTTP endpoint for transferring tokens
│   ├── transferEquinoxToken.ts # Script for transferring Equinox tokens
│   ├── standaloneTransfer.js   # Standalone script for transferring tokens
│   ├── controllers
│   │   └── tokenController.ts  # Controller for token operations
│   ├── routes
│   │   └── tokenRoutes.ts      # Routes for token operations
│   └── types
│       └── index.ts            # Type definitions for requests
```

## Installation

1. Clone the repository:
   ```sh
   git clone <repository-url>
   cd solana-token-app
   ```

2. Install the dependencies:
   ```sh
   npm install
   ```

## Usage

### Creating a Token

To create a new token, run the following command:
```sh
npm start
```
This will generate a mint address and a distributor wallet, and mint tokens into the distributor wallet. The details will be saved in the `.env` file.

### Transferring Tokens

To transfer tokens, you can use the HTTP endpoint defined in `tokenRoutes.ts`. Start the server by running:
```sh
npm run dev
```
Then, make a POST request to `http://localhost:3000/api/transfer` with the following JSON body:
```json
{
  "multiplier": 2
}
```

### Transferring Equinox Tokens

To transfer Equinox tokens, run the following command:
```sh
npx ts-node src/transferEquinoxToken.ts
```

### Standalone Token Transfer

You can also use the standalone script for transferring tokens. Start the standalone server by running:
```sh
node src/standaloneTransfer.js
```
Then, make a POST request to `http://localhost:3030/transfer-tokens` with the following JSON body:
```json
{
  "wallet": "recipient-wallet-address",
  "multiplyingFactor": 2
}
```

## Running the Application

To start the application, run:
```sh
npm start
```
or define env vars in `solana-token-app/.env` and run:
```sh
npm run dev
```

## License

This project is licensed under the MIT License.