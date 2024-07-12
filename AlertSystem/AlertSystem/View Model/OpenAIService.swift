import Foundation
import Combine

enum Constants {
    static let OpenAIAPIKey = "sk-proj-9eM7jgvBozJTRNxxx4AiT3BlbkFJa8PVECQzDwHJf5AUxeK1"
}

struct OpenAIParameters: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let functions: [Function]
    let function_call: String
    let max_tokens: Int
}

struct Function: Codable {
    let name: String
    let description: String
    let parameters: Parameters
}

struct Parameters: Codable {
    let type: String
    let properties: [String: Property]
    let required: [String]
}

struct Property: Codable {
    let type: String
    let description: String?
}

struct OpenAIResponse: Decodable {
    let id: String
    let choices: [OpenAIResponseChoice]
}

struct OpenAIResponseChoice: Decodable {
    let index: Int
    let message: OpenAIMessage
    let finish_reason: String
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String?
    let function_call: FunctionCall?
    let name: String?

    init(role: String, content: String?, function_call: FunctionCall? = nil, name: String? = nil) {
        self.role = role
        self.content = content
        self.function_call = function_call
        self.name = name
    }
}

struct FunctionCall: Codable {
    let name: String
    let arguments: String
}

let getCurrentWeatherFunction = Function(
    name: "get_current_weather",
    description: "Get the current weather in a given location",
    parameters: Parameters(
        type: "object",
        properties: [
            "location": Property(type: "string", description: "The city and state, e.g. San Francisco, CA"),
            "unit": Property(type: "string", description: "The unit of measurement, e.g. fahrenheit or celsius")
        ],
        required: ["location"]
    )
)

let callFriendFunction = Function(
    name: "call_friend",
    description: "Call an emergency number for help",
    parameters: Parameters(
        type: "object",
        properties: [:],
        required: []
    )
)

class OpenAIService {
    let baseUrl = "https://api.openai.com/v1/chat/completions"
    
    var isLoading: Bool = false
    var messages: [OpenAIMessage] = []
    
    let systemMessage = OpenAIMessage(role: "system", content: "You are assisting an unknown individual from Indonesia (Tangerang, Banten) that is in an emergency. Act like a 911 dispatcher, be helpful, but keep communication clear and concise.")
    
    func makeRequest(message: OpenAIMessage) -> AnyPublisher<OpenAIResponse, Error> {
        if !messages.contains(where: { $0.role == "system" }) {
            messages.append(systemMessage)
        }
        messages.append(message)
        
        let functions: [Function] = [getCurrentWeatherFunction, callFriendFunction]
        let parameters = OpenAIParameters(
            model: "gpt-4o",
            messages: messages,
            functions: functions,
            function_call: "auto",
            max_tokens: 256
        )
        
        return Future { [weak self] promise in
            self?.performNetworkRequest(with: parameters, promise: promise)
        }
        .eraseToAnyPublisher()
    }
    
    private func performNetworkRequest(with parameters: OpenAIParameters,
                                       promise: @escaping (Result<OpenAIResponse, Error>) -> Void) {
        guard let url = URL(string: baseUrl) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            promise(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Constants.OpenAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(parameters)
            request.httpBody = jsonData
        } catch {
            promise(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                promise(.failure(error))
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                promise(.failure(error))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                promise(.success(result))
            } catch {
                promise(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func handleFunctionCall(functionCall: FunctionCall, completion: @escaping (Result<String, Error>) -> Void) {
        self.messages.append(OpenAIMessage(role: "assistant", content: "", function_call: functionCall))
        
        let availableFunctions: [String: () -> String] = [
            "get_current_weather": { getCurrentWeather(location: "", unit: nil) },
            "call_friend": callFriend
        ]
        
        print("Received function call: \(functionCall.name)")
        
        if let functionToCall = availableFunctions[functionCall.name] {
            let functionResponse = functionToCall()
            completion(.success(functionResponse))
        } else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Function not found or supported."])
            completion(.failure(error))
        }
    }
}

func getCurrentWeather(location: String, unit: String?) -> String {
    let weatherInfo: [String: Any] = [
        "location": location,
        "temperature": "72",
        "unit": unit ?? "fahrenheit",
        "forecast": ["sunny", "windy"],
    ]
    let jsonData = try? JSONSerialization.data(withJSONObject: weatherInfo, options: .prettyPrinted)
    return String(data: jsonData!, encoding: .utf8)!
}

func callFriend() -> String {
    print("Help is on the way")
    return "{\"status\": \"success\", \"message\": \"Help is on the way\"}"
}
