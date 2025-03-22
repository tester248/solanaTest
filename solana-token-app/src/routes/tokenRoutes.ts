import { Router } from 'express';
import { transferToken } from '../controllers/tokenController';
import { buyEquinoxToken } from '../buyEquinoxToken'
import { getEquinoxBalance } from '../controllers/tokenController'; // Import the new controller
import { transferEquinox } from '../transferEquinox'; // Import the new controller
import { createEquinoxWallet } from '../controllers/tokenController';


const router = Router();

router.post('/transfer', transferToken);
router.post('/buyequinox', buyEquinoxToken);
router.post('/transferequinox', transferEquinox); // New route for token transfer
router.get('/equinoxbalance/:walletAddress', getEquinoxBalance); // New route for balance retrieval
router.get('/createwallet', createEquinoxWallet); // New route for creating wallets


export default router;