import { cloudinary } from "../config/cloudinary";
import { ForbiddenError } from "../errors/application-error";
import { CloudService } from "../utils/cloud.service";


export class CloudImageService implements CloudService {

    uploadImage = async (fileBuffer: Buffer, path: string): Promise<string> => {
        return new Promise((resolve, reject) => {
            const stream = cloudinary.uploader.upload_stream(
                { folder: path, resource_type: 'image', },
                (error, result) => {
                    if (error) reject(error);
                    else resolve(result?.secure_url || '');
                }
            );
            stream.end(fileBuffer);

        });


    }

    updateImage = async (fileBuffer: Buffer, path: string, expectedUserId: string, expectedUuid: string): Promise<string> => {

        const parts = path.split('/');
        const publicIdPart = parts[parts.length - 1].split('.')[0];

        const [folder, userId, uuid] = publicIdPart.split('/');

        if (userId !== expectedUserId || uuid !== expectedUuid) {
            new ForbiddenError();
        }

        return new Promise((resolve, reject) => {
            const stream = cloudinary.uploader.upload_stream(
                { folder: path, resource_type: 'image', },
                (error, result) => {
                    if (error) reject(error);
                    else resolve(result?.secure_url || '');
                }
            );
            stream.end(fileBuffer);

        });

    }
    deleteImage = async (url: string, expectedUserId: string, expectedUuid: string): Promise<void> => {

        const parts = url.split('/');
        const publicIdPart = parts[parts.length - 1].split('.')[0];

        const [folder, userId, uuid] = publicIdPart.split('/');

        if (userId !== expectedUserId || uuid !== expectedUuid) {
            new ForbiddenError();
        }

        return new Promise((resolve, reject) => {
            cloudinary.uploader.destroy(publicIdPart, (error, result) => {
                if (error) reject(error);
                else resolve();
            });
        });

    }


}
