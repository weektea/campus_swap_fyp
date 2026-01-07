import { register, login, updateProfile, deleteAccount, changePassword, forgotPassword } from '../controllers/authController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.post('/change-password', authenticateToken, changePassword);
router.patch('/user/:id', authenticateToken, updateProfile);
router.delete('/user/:id', authenticateToken, deleteAccount);

export default router;
