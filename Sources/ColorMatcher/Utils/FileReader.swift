
import Foundation

final class File {

    static func read<T: Codable>(from path: String) -> T {
        do {
            let fileUrl = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: fileUrl)
            let decoder = JSONDecoder()

            return try decoder.decode(T.self, from: data)
        } catch {
            print("Unable to read the specified file. Path: \(path)")
            exit(1)
        }
    }

    static func createFolder(with path: String) {
        let directory = URL(fileURLWithPath: path)
        do
        {
            try FileManager.default.createDirectory(atPath: directory.path,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            print("Unable to create directory.\nPath: \(path)\nError: \(error)")
        }
    }
}
