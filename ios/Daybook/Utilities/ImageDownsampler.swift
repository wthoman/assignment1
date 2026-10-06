import ImageIO
import UIKit

enum ImageDownsampler {
    /// Decodes image data at a reduced size (memory friendly) and re-encodes it as JPEG.
    static func jpegData(from data: Data, maxDimension: CGFloat, quality: CGFloat = 0.8) -> Data? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options) else { return nil }
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: quality)
    }
}
