import { Request } from 'express';
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
  {
    req,
    uuid,
    userId,
    folderName,
    uploadToCloudinary
  }: ExtractImageInterfas
): Promise<string[] | null> => {
  try {
    let imageFiles: Express.Multer.File[] | undefined = req.files as Express.Multer.File[] | undefined;
    const imageFile = req.file as Express.Multer.File | undefined;

    // If no images provided, return null (do not throw)
    if ((!imageFiles || imageFiles.length === 0) && !imageFile) {
      return null;
    }

    // Normalize to an array
    if (imageFile) {
      imageFiles = [imageFile];
    }

    const cloudinaryImagesUrls: string[] = [];

    // Process each image
    for (const file of imageFiles!) {
      const fileBuffer = file.buffer;
      const path = `${folderName}/${userId}/${uuid}`;
      const cloudinaryUrl = await uploadToCloudinary.uploadImage(fileBuffer, path);
      cloudinaryImagesUrls.push(cloudinaryUrl);
    }

    return cloudinaryImagesUrls;
  } catch (error) {
    console.error('Error processing images:', error);
    throw error instanceof BadRequestError ? error : new BadRequestError('Error images');
  }
}

