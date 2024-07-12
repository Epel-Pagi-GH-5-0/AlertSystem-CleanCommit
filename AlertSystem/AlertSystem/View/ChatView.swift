import SwiftUI
import Combine

struct ChatMessage {
    let id: String
    let content: String
    let createdAt: Date
    let sender: MessageSender
}

enum MessageSender {
    case user
    case chatGPT
}
class ChatViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    @Published var chatMessages: [ChatMessage] = [ChatMessage(id: UUID().uuidString, content: "Your distress signal has been received by Guardi. Please provide detailed information about your current situation and any assistance you need.", createdAt: Date(), sender: MessageSender.chatGPT)]
    @Published var lastMessageID: String = ""
    @Published var isConnected: Bool = true
    
    let openAIService: OpenAIService
    let networkMonitor: NetworkMonitor // Declare as a constant property
    
    init(openAIService: OpenAIService = OpenAIService()) {
        self.openAIService = openAIService
        self.networkMonitor = NetworkMonitor() // Initialize networkMonitor
        
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: \.isConnected, on: self)
            .store(in: &cancellables)
    }
    
    func sendMessage(message: String) {
        guard message != "" else { return }
        
        let myMessage = ChatMessage(id: UUID().uuidString, content: message, createdAt: Date(), sender: .user)
        chatMessages.append(myMessage)
        lastMessageID = myMessage.id
        
        openAIService.makeRequest(message: OpenAIMessage(role: "user", content: message))
            .sink { completion in
                switch completion {
                case .failure(let error): print(error.localizedDescription)
                case .finished: break
                }
            } receiveValue: { response in
                self.handleResponse(response: response)
            }
            .store(in: &cancellables)
    }
    
    func handleResponse(response: OpenAIResponse) {
        guard let message = response.choices.first?.message else { return }
        if let functionCall = message.function_call {
            handleFunctionCall(functionCall: functionCall)
            chatMessages.append(ChatMessage(id: response.id, content: "Calling Function \(functionCall.name)", createdAt: Date(), sender: .chatGPT))
        } else if let textResponse = message.content?.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "\""))) {
            chatMessages.append(ChatMessage(id: response.id, content: textResponse, createdAt: Date(), sender: .chatGPT))
            lastMessageID = response.id
        }
    }
    
    func handleFunctionCall(functionCall: FunctionCall) {
        self.openAIService.handleFunctionCall(functionCall: functionCall) { result in
            switch result {
            case .success(let functionResponse):
                self.openAIService.makeRequest(
                    message: OpenAIMessage(
                        role: "function",
                        content: functionResponse,
                        name: functionCall.name
                    )
                )
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error): print("error", error)
                    case .finished: break
                    }
                }, receiveValue: { response in
                    guard let responseMessage = response.choices.first?.message else { return }
                    guard let textResponse = responseMessage.content?
                        .trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "\""))) else { return }
                    
                    let chatGPTMessage = ChatMessage(id: response.id,
                                                     content: textResponse,
                                                     createdAt: Date(),
                                                     sender: .chatGPT
                    )
                    
                    self.chatMessages.append(chatGPTMessage)
                    self.lastMessageID = chatGPTMessage.id
                })
                .store(in: &self.cancellables)
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}


struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel = ChatViewModel()
    @State var message: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    ZStack {
                        Image("Logo")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .padding()
                        
                        Circle()
                            .fill(viewModel.isConnected ? Color.green : Color.orange)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 1)
                            )
                            .offset(x: 15, y: 15)
                    }
                    VStack(alignment: .leading) {
                        Text(viewModel.isConnected ? "Connected to" : "Connection Unstable")
                            .font(.system(size: 15))
                        Text("Emergency Session")
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.bottom, 20) // Add padding to move HStack 20px above the Divider
                
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack {
                            ForEach(viewModel.chatMessages, id: \.id) { message in
                                MessageView(message: message)
                            }
                        }
                    }
                    .onChange(of: viewModel.lastMessageID) { id in
                        withAnimation {
                            proxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
                
                ZStack(alignment: .trailing) {
                    TextEditor(text: $message)
                        .frame(height: 40) // Increase height to give more space
                        .padding(.leading, 16)
                        .padding(.trailing, 40)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .inset(by: 0.75)
                                .stroke(Color(red: 0.71, green: 0.71, blue: 0.71), lineWidth: 1.5)
                        )
                        .font(.system(size: 17))
                        .padding(.vertical, 8) // Adjust padding to balance the text
                    
                    Button {
                        viewModel.sendMessage(message: message)
                        message = ""
                        UIApplication.shared.endEditing() // Dismiss the keyboard
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding(.trailing, 22)
                    .foregroundColor(message.isEmpty ? .gray : .blue) // Change color based on message state
                    .disabled(message.isEmpty) // Disable button when message is empty
                }
                .padding(.horizontal, 22) // Align with the TextBox padding
            }
            .padding()
        }
        .overlay(
            VStack {
                Spacer().frame(height: 102) // Height of the header including padding and additional 20px
                Divider()
                Spacer()
            }
        )
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.endEditing() // Dismiss the keyboard when tapping outside
        }
    }
}

struct MessageView: View {
    var message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            if message.sender == .chatGPT {
                Image("Logo")
                    .resizable()
                    .frame(width: 27, height: 27)
                    .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                    .padding(.top, 2) // Adjust padding to align with the timestamp
                    .padding(.trailing, 5)
            }
            
            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
                Text("\(message.sender == .chatGPT ? "Guardi" : "Me") \(formattedDate(date: message.createdAt))")
                    .font(Font.custom("Inter", size: 10.50922))
                    .foregroundColor(Color(red: 0.4, green: 0.44, blue: 0.52))
                    .frame(height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .font(Font.custom("SF Pro", size: 17))
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.12))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                }
                .background(message.sender == .user ? Color(red: 0.84, green: 0.89, blue: 1) : Color.white)
                .cornerRadius(8.75769)
                .overlay(
                    RoundedRectangle(cornerRadius: 8.75769)
                        .inset(by: 0.44)
                        .stroke(Color(red: 0.89, green: 0.89, blue: 0.89), lineWidth: 0.87577)
                )
                .frame(maxWidth: 258, alignment: message.sender == .user ? .trailing : .leading) // Flexible width with a maximum of 258
            }
            .frame(maxWidth: .infinity, alignment: message.sender == .user ? .trailing : .leading)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: message.sender == .user ? .trailing : .leading)
    }
    
    func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ChatView()
}
