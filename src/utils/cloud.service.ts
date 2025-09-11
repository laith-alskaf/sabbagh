export interface CloudService {
  uploadImage(fileBuffer: Buffer, path: string): Promise<string>;
  updateImage(fileBuffer: Buffer, path: string, expectedUserId: string, expectedUuid: string): Promise<string>;
  deleteImage(url: string, expectedUserId: string, expectedUuid: string): Promise<void>;
}
