extension String {
    var decodedHTML: String {
        var result = self
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"),
            ("&nbsp;", " "), ("&#x27;", "'"), ("&rdquo;", "\""),
            ("&ldquo;", "\""), ("&#8217;", "'"), ("&mdash;", "—"),
            ("&ndash;", "–")
        ]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }

        let hexPattern = "&#[xX]([0-9a-fA-F]+);"
        if let regex = try? NSRegularExpression(pattern: hexPattern) {
            let nsString = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsString.length))
            for match in matches.reversed() {
                let hexStr = nsString.substring(with: match.range(at: 1))
                if let val = Int(hexStr, radix: 16), let scalar = Unicode.Scalar(val) {
                    result = result.replacingOccurrences(of: nsString.substring(with: match.range), with: String(scalar))
                }
            }
        }

        let decPattern = "&#(\\d+);"
        if let regex = try? NSRegularExpression(pattern: decPattern) {
            let nsString = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsString.length))
            for match in matches.reversed() {
                let numStr = nsString.substring(with: match.range(at: 1))
                if let val = Int(numStr), let scalar = Unicode.Scalar(val) {
                    result = result.replacingOccurrences(of: nsString.substring(with: match.range), with: String(scalar))
                }
            }
        }

        return result
    }
}
