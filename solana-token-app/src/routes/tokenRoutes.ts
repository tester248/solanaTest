import { Router } from 'express';
import { transferToken } from '../controllers/tokenController';

const router = Router();

router.post('/transfer', transferToken);

export default router;