import multer from "multer";
import { AppError } from "../middlewares/errorMiddleware";

// Configure multer
const upload = multer({
    storage: multer.memoryStorage(), // Store files in memory as buffers
    limits: {
        fileSize: 5 * 1024 * 1024, // 5MB limit per file
        files: 5, // Max 5 files
    },
    fileFilter: (req, file, cb) => {
        if (!file.mimetype.startsWith('image/')) {
            cb(new AppError('Network Error', 400));
        } else {
            cb(null, true);
        }
    },
});
export const uploadImages = upload.array('images', 5); // Fie