import { Router } from 'express';
import { transferToken } from '../controllers/tokenController';
import { transferEquinoxToken } from '../transferEquinoxToken'
import { getEquinoxBalance } from '../controllers/tokenController'; // Import the new controller



const router = Router();

router.post('/transfer', transferToken);
router.post('/equinoxtransfer', transferEquinoxToken);
router.get('/equinoxbalance/:walletAddress', getEquinoxBalance); // New route for balance retrieval


export default router;