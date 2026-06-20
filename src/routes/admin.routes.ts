import { Router, RequestHandler } from 'express';
import { authMiddleware, roleMiddleware } from '../middlewares/auth.middleware';
import { uploadAvatar, uploadImage, handleMulterError } from '../middlewares/upload.middleware';

import * as adminStatsController from '../controllers/admin/adminStats.controller';
import * as adminDoctorController from '../controllers/admin/adminDoctor.controller';
import * as adminMenuItemController from '../controllers/admin/adminMenuItem.controller';
import * as adminCategoryController from '../controllers/admin/adminCategory.controller';
import * as adminBannerController from '../controllers/admin/adminBanner.controller';
import * as adminUserController from '../controllers/admin/adminUser.controller';
import * as adminOrderController from '../controllers/admin/adminOrder.controller';
import * as adminAppointmentController from '../controllers/admin/adminAppointment.controller';

const router = Router();

// Wrap route handlers for compatibility if required
const h = (fn: any): RequestHandler => fn;

// Secure all admin routes
router.use(h(authMiddleware), h(roleMiddleware(['admin'])));

// Stats
router.get('/stats', h(adminStatsController.getAdminStats));

// Doctors CRUD
router.get('/doctors', h(adminDoctorController.getAdminDoctors));
router.post('/doctors', h(adminDoctorController.createDoctor));
router.put('/doctors/:id', h(adminDoctorController.updateDoctor));
router.delete('/doctors/:id', h(adminDoctorController.deleteDoctor));
router.patch('/doctors/:id/toggle', h(adminDoctorController.toggleDoctorActive));
router.post(
  '/doctors/:id/avatar',
  h(uploadAvatar),
  h(handleMulterError),
  h(adminDoctorController.uploadDoctorAvatar)
);

// Menu Items CRUD
router.get('/menu-items', h(adminMenuItemController.getAdminMenuItems));
router.post('/menu-items', h(adminMenuItemController.createMenuItem));
router.put('/menu-items/:id', h(adminMenuItemController.updateMenuItem));
router.delete('/menu-items/:id', h(adminMenuItemController.deleteMenuItem));
router.post(
  '/menu-items/:id/image',
  h(uploadImage),
  h(handleMulterError),
  h(adminMenuItemController.uploadMenuItemImage)
);

// Categories CRUD
router.get('/categories', h(adminCategoryController.getAdminCategories));
router.post('/categories', h(adminCategoryController.createCategory));
router.put('/categories/:id', h(adminCategoryController.updateCategory));
router.delete('/categories/:id', h(adminCategoryController.deleteCategory));

// Banners CRUD
router.get('/banners', h(adminBannerController.getAdminBanners));
router.post('/banners', h(adminBannerController.createBanner));
router.put('/banners/:id', h(adminBannerController.updateBanner));
router.delete('/banners/:id', h(adminBannerController.deleteBanner));
router.post(
  '/banners/:id/image',
  h(uploadImage),
  h(handleMulterError),
  h(adminBannerController.uploadBannerImage)
);

// Users Management
router.get('/users', h(adminUserController.getAdminUsers));
router.patch('/users/:id/role', h(adminUserController.updateUserRole));
router.patch('/users/:id/toggle', h(adminUserController.toggleUserActive));

// Orders
router.get('/orders', h(adminOrderController.getAdminOrders));
router.patch('/orders/:id/status', h(adminOrderController.updateOrderStatus));

// Appointments
router.get('/appointments', h(adminAppointmentController.getAdminAppointments));
router.patch('/appointments/:id/status', h(adminAppointmentController.updateAppointmentStatus));

export default router;
