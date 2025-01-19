import { Request, Response } from 'express';
import { Connection, Keypair, PublicKey } from '@solana/web3.js';
import { getOrCreateAssociatedTokenAccount, transfer, getAccount, getMint, TOKEN_2022_PROGRAM_ID } from '@solana/spl-token';
import dotenv from 'dotenv';

dotenv.config();

export const transferToken = async (req: Request, res: Response) => {
  const { multiplier } = req.body;
  const connection = new Connection(process.env.SOLANA_NETWORK!, 'confirmed');
  const mintAddress = new PublicKey(process.env.MINT_ADDRESS!);
  const payerSecretKey = Uint8Array.from(JSON.parse(process.env.PAYER_SECRET_KEY!));
  const payer = Keypair.fromSecretKey(payerSecretKey);
  const distributorWallet = new PublicKey(process.env.DISTRIBUTOR_WALLET!);
  const recipient = Keypair.generate();

  try {
    // Ensure distributor token account is initialized
    const distributorTokenAccount = await getOrCreateAssociatedTokenAccount(
      connection,
      payer,
      mintAddress,
      distributorWallet,
      true,
      undefined,
      undefined,
      TOKEN_2022_PROGRAM_ID
    );

    // Create recipient token account
    const recipientTokenAccount = await getOrCreateAssociatedTokenAccount(
      connection,
      payer,
      mintAddress,
      recipient.publicKey,
      true,
      undefined,
      undefined,
      TOKEN_2022_PROGRAM_ID
    );

    // Log account details
    console.log('Distributor Token Account:', distributorTokenAccount.address.toBase58());
    console.log('Recipient Token Account:', recipientTokenAccount.address.toBase58());

    // Check distributor token balance
    const distributorTokenBalance = await getAccount(connection, distributorTokenAccount.address, undefined, TOKEN_2022_PROGRAM_ID);
    const mint = await getMint(connection, mintAddress, undefined, TOKEN_2022_PROGRAM_ID);
    const balance = Number(distributorTokenBalance.amount) / Math.pow(10, mint.decimals);
    console.log(`Distributor Token Balance: ${balance}`);

    // Transfer tokens to recipient
    await transfer(
      connection,
      payer,
      distributorTokenAccount.address,
      recipientTokenAccount.address,
      payer.publicKey,
      BigInt(1000 * multiplier) * BigInt(Math.pow(10, mint.decimals)),
      [],
      undefined,
      TOKEN_2022_PROGRAM_ID
    );

    res.json({
      recipientWallet: recipient.publicKey.toBase58(),
      recipientTokenAccount: recipientTokenAccount.address.toBase58()
    });
  } catch (error) {
    console.error('Error during token transfer:', error);
    res.status(500).json({ error: (error as any).message });
  }
};