import Foundation

struct SearchResponse {
    let results: [WordResult]
    let raw: Data
}

struct TDKAPIClient {
    private static let baseURL = "https://sozluk.gov.tr"

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 20
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    private static func makeRequest(for word: String, timeout: TimeInterval) throws -> URLRequest {
        guard var components = URLComponents(string: "\(baseURL)/gts") else {
            throw APIError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "ara", value: word)]
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("https://sozluk.gov.tr/", forHTTPHeaderField: "Referer")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private static func executeFetch(word: String, timeout: TimeInterval) async throws -> SearchResponse {
        let request = try makeRequest(for: word, timeout: timeout)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        guard !data.isEmpty else {
            throw APIError.emptyResponse
        }
        
        let decoder = JSONDecoder()
        do {
            let results = try decoder.decode([WordResult].self, from: data)
            return SearchResponse(results: results, raw: data)
        } catch let decodingError as DecodingError {
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let dict = jsonObject as? [String: Any] {
                if let message = dict["error"] as? String, !message.isEmpty {
                    return SearchResponse(results: [], raw: data)
                }
                if let message = dict["message"] as? String, !message.isEmpty {
                    return SearchResponse(results: [], raw: data)
                }
            }
            throw APIError.decodingError(decodingError)
        }
    }

    private static func isFatalError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidWord, .invalidURL:
                return true
            default:
                break
            }
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .cannotFindHost, .dnsLookupFailed, .internationalRoamingOff, .callIsActive, .dataNotAllowed:
                return true
            default:
                break
            }
        }
        return false
    }

    /// Kelimeyi TDK API üzerinden arar. TDK sunucularındaki ani gecikme ve takılmalara (tail latency)
    /// karşı "hedged request" yaklaşımı kullanır: 2.5 saniye içinde yanıt gelmezse ikinci bir eşzamanlı
    /// istek başlatılır ve ilk dönen geçerli yanıt kabul edilir.
    static func searchWord(_ word: String) async throws -> SearchResponse {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw APIError.invalidWord
        }

        let attemptTimeout: TimeInterval = 8.0
        let hedgeDelays: [UInt64] = [
            0,
            2_500_000_000, // 2.5 saniye
            5_000_000_000  // 5.0 saniye
        ]

        return try await withThrowingTaskGroup(of: SearchResponse.self) { group in
            for delay in hedgeDelays {
                group.addTask {
                    if delay > 0 {
                        try await Task.sleep(nanoseconds: delay)
                    }
                    try Task.checkCancellation()
                    return try await executeFetch(word: trimmed, timeout: attemptTimeout)
                }
            }

            var lastError: Error?
            while let result = await group.nextResult() {
                switch result {
                case .success(let response):
                    // İlk başarılı yanıt geldiğinde diğer tüm istekleri iptal et
                    group.cancelAll()
                    return response
                case .failure(let error):
                    if error is CancellationError {
                        continue
                    }
                    lastError = error
                    // Çevrimdışı olma veya geçersiz URL gibi telafisi olmayan hatalarda diğer denemeleri bekleme
                    if isFatalError(error) {
                        group.cancelAll()
                        throw error
                    }
                }
            }

            throw lastError ?? APIError.unexpectedResponse
        }
    }
}

// MARK: - Models

struct WordResult: Codable {
    let madde_id: String
    let kelime_no: String
    let madde: String
    let lisan: String
    let birlesikler: String
    let anlamlarListe: [Meaning]
    
    enum CodingKeys: String, CodingKey {
        case madde_id
        case kelime_no
        case madde
        case lisan
        case birlesikler
        case anlamlarListe
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        madde_id = try container.decode(String.self, forKey: .madde_id)
        kelime_no = try container.decode(String.self, forKey: .kelime_no)
        madde = try container.decode(String.self, forKey: .madde)
        lisan = try container.decodeIfPresent(String.self, forKey: .lisan) ?? ""
        birlesikler = try container.decodeIfPresent(String.self, forKey: .birlesikler) ?? ""
        anlamlarListe = try container.decode([Meaning].self, forKey: .anlamlarListe)
    }
}

struct Meaning: Codable {
    let anlam_id: String
    let anlam: String
    let anlam_sira: String
    let ozelliklerListe: [Property]?
    let orneklerListe: [Example]?
    
    enum CodingKeys: String, CodingKey {
        case anlam_id
        case anlam
        case anlam_sira
        case ozelliklerListe
        case orneklerListe
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        anlam_id = try container.decode(String.self, forKey: .anlam_id)
        anlam = try container.decode(String.self, forKey: .anlam)
        anlam_sira = try container.decode(String.self, forKey: .anlam_sira)
        ozelliklerListe = try container.decodeIfPresent([Property].self, forKey: .ozelliklerListe)
        orneklerListe = try container.decodeIfPresent([Example].self, forKey: .orneklerListe)
    }
}

struct Property: Codable {
    let ozellik_id: String
    let tam_adi: String
    let kisa_adi: String
    
    enum CodingKeys: String, CodingKey {
        case ozellik_id
        case tam_adi
        case kisa_adi
    }
}

struct Example: Codable {
    let ornek_id: String
    let ornek: String
    
    enum CodingKeys: String, CodingKey {
        case ornek_id
        case ornek
    }
}

// MARK: - Error Handling

enum APIError: LocalizedError {
    case invalidWord
    case invalidURL
    case invalidResponse
    case emptyResponse
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)
    case unexpectedResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidWord:
            return "Geçersiz kelime"
        case .invalidURL:
            return "Geçersiz URL"
        case .invalidResponse:
            return "Geçersiz sunucu yanıtı"
        case .emptyResponse:
            return "Sunucu boş yanıt döndürdü"
        case .serverError(let code):
            return "Sunucu hatası: \(code)"
        case .decodingError(let error):
            return "Veri işleme hatası: \(error.localizedDescription)"
        case .networkError(let error):
            return "Ağ hatası: \(error.localizedDescription)"
        case .unexpectedResponse:
            return "Beklenmeyen yanıt"
        }
    }
}
