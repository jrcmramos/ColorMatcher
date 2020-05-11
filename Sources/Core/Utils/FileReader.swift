
import Foundation

public final class File {

    public static func read<T: Codable>(from path: String) -> T {
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

    public static func write<T: Codable>(to path: String, content: T) {
        do {
            let fileUrl = URL(fileURLWithPath: path)
            let encoder = JSONEncoder()
            let data = try encoder.encode(content)

            try data.write(to: fileUrl)
        } catch {
            print("Unable to read the specified file. Path: \(path)")
            exit(1)
        }
    }

    public static func create(folderPath: String) {
        let directory = URL(fileURLWithPath: folderPath)
        do
        {
            try FileManager.default.createDirectory(atPath: directory.path,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            print("Unable to create directory.\nPath: \(folderPath)\nError: \(error)")
        }
    }
}
