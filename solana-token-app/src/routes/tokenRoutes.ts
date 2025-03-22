import { Router } from 'express';
import { transferToken } from '../controllers/tokenController';
import { transferEquinoxToken } from '../transferEquinoxToken'

const router = Router();

router.post('/transfer', transferToken);
router.post('/equinoxtransfer', transferEquinoxToken);

export default router;