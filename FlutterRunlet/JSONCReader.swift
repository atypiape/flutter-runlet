import Foundation

enum JSONCReader {
    static func decode(_ data: Data, file: String) throws -> Any {
        var bytes = Array(data)
        if bytes.starts(with: [0xef, 0xbb, 0xbf]) {
            bytes.replaceSubrange(0..<3, with: [32, 32, 32])
        }
        guard String(bytes: bytes, encoding: .utf8) != nil else {
            throw SessionIssue("\(file) 必须使用 UTF-8 编码")
        }

        var index = 0
        var insideString = false
        var previous: UInt8?
        var trailingComma: Int?
        while index < bytes.count {
            let byte = bytes[index]
            if insideString {
                if byte == 92 { index += 2; continue }
                if byte == 34 { insideString = false }
            } else if byte == 47 && index + 1 < bytes.count && [42, 47].contains(bytes[index + 1]) {
                let start = index
                let lineComment = bytes[index + 1] == 47
                index += 2
                if lineComment {
                    while index < bytes.count && ![10, 13].contains(bytes[index]) { index += 1 }
                } else {
                    while index + 1 < bytes.count && !(bytes[index] == 42 && bytes[index + 1] == 47) {
                        index += 1
                    }
                    guard index + 1 < bytes.count else {
                        throw issue(file, source: data, offset: start, reason: "块注释未闭合")
                    }
                    index += 2
                }
                for offset in start..<index where ![10, 13].contains(bytes[offset]) { bytes[offset] = 32 }
                continue
            } else if ![9, 10, 13, 32].contains(byte) {
                if [93, 125].contains(byte), let trailingComma { bytes[trailingComma] = 32 }
                trailingComma = byte == 44 && previous.map({ ![44, 58, 91, 123].contains($0) }) == true ? index : nil
                previous = byte
                insideString = byte == 34
            }
            index += 1
        }

        do {
            return try JSONSerialization.jsonObject(with: Data(bytes), options: [.fragmentsAllowed])
        } catch {
            let offset = (error as NSError).userInfo["NSJSONSerializationErrorIndex"] as? Int ?? data.count
            throw issue(file, source: data, offset: offset, reason: "JSONC 语法错误")
        }
    }

    private static func issue(_ file: String, source: Data, offset: Int, reason: String) -> SessionIssue {
        var prefix = String(decoding: source.prefix(max(0, offset)), as: UTF8.self)
        if prefix.first == "\u{feff}" { prefix.removeFirst() }
        let lines = prefix.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n").components(separatedBy: "\n")
        return SessionIssue("\(file) 第 \(lines.count) 行第 \((lines.last?.unicodeScalars.count ?? 0) + 1) 列：\(reason)")
    }
}
