import { Router } from 'express';
import { WishlistController } from '../controllers/wishlist.controller';
import { authenticateJwt } from '../middlewares/auth.middleware';

const router = Router();

router.get('/', authenticateJwt, WishlistController.getItems);
router.post('/', authenticateJwt, WishlistController.createItem);
router.put('/:id', authenticateJwt, WishlistController.updateItem);
router.delete('/:id', authenticateJwt, WishlistController.deleteItem);

export default router;
