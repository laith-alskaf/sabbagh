import { Request} from 'express';
import { CloudImageService } from '../services/cloud-image.service';
import { BadRequestError } from '../errors/application-error';

interface ExtractImageInterfas {
    req: Request,
    uuid: string,
    userId: string,
    folderName: string,
    uploadToCloudinary: CloudImageService
}

export const handlerExtractImage = async (
    { req,
        uuid,
        userId,
        folderName,
        uploadToCloudinary }: ExtractImageInterfas
): Promise<string[] | null> => {

    try {

        var imageFiles: Express.Multer.File[] | undefined = req.files as Express.Multer.File[] | undefined;
        const imageFile = req.file as Express.Multer.File | undefined;
        if ((!imageFiles || imageFiles.length === 0) && !imageFile) {
            throw new BadRequestError('No Images');
        }
        if (imageFile) {
            imageFiles = [];
            imageFiles.push(imageFile);
        }

        const cloudinaryImagesUrls: string[] = [];

        // Process each image
        for (const imageFile of imageFiles!) {
            const fileBuffer = imageFile.buffer;
            // const fileName = imageFile.originalname.split(".")[0] || `image-${Date.now()}`;

            // Upload to Cloudinary
            const path = `${folderName}/${userId}/${uuid}`;
            const cloudinaryUrl = await uploadToCloudinary.uploadImage(fileBuffer, path);
            cloudinaryImagesUrls.push(cloudinaryUrl);
        }

        return cloudinaryImagesUrls;
    } catch (error) {
        console.error('Error processing images:', error);
        throw error instanceof BadRequestError
            ? error
            : new BadRequestError('Error images');
    }
}

