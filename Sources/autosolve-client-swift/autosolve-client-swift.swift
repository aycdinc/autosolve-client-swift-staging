import Foundation

public class AutoSolve {

    private let clientKey: String
    private var accessToken: String
    private var apiKey: String
    private let debug: Bool
    private let shouldAlertOnCancel: Bool

    private lazy var accountId: String = self.parseAccountId()
    private lazy var apiRoutingKey: String =  self.apiKey.components(separatedBy: "-").joined(separator: "")
    private lazy var accessTokenRoutingKey: String = self.accessToken.components(separatedBy: "-").joined(separator: "")

    private lazy var tokenSendRoutingKey: String = self.buildRoutingWithAccessToken(prefix: AutoSolveConstants.TokenSendRoutingKey)
    private lazy var cancelSendRoutingKey: String = self.buildRoutingWithAccessToken(prefix: AutoSolveConstants.CancelSendRoutingKey)

    internal lazy var tokenResponseRoutingKey: String = self.buildWithRoutingKey(prefix: AutoSolveConstants.TokenResponseRoutingKey)
    internal lazy var cancelResponseRoutingKey: String = self.buildWithRoutingKey(prefix: AutoSolveConstants.CancelResponseRoutingKey)

    private lazy var directExchangeName: String = self.buildRoutingWithAccountId(prefix: AutoSolveConstants.DirectExchange)
    private lazy var fanoutExchangeName: String = self.buildRoutingWithAccountId(prefix: AutoSolveConstants.FanoutExchange)

    private lazy var responseQueueName: String = self.buildWithRoutingKey(prefix: AutoSolveConstants.TokenResponseQueuePrefix)

    internal var connection: RMQConnection?
    internal var directChannel : RMQChannel?
    internal var fanoutChannel : RMQChannel?

    public var responseEmitter: Signal<AutoSolveTokenResponse>
    public var cancelEmitter: Signal<AutoSolveCancelResponse>
    public var errorEmitter: Signal<AutoSolveError>
    public var connectionEmitter: Signal<AutoSolveConnectionEvent>

    internal var connectionAttempts: Int
    internal var connected: Bool
    internal var attemptingReconnect: Bool
    internal var backlog: [AutoSolveRequest]

    public init(clientKey: String, debug: Bool, shouldAlertOnCancel: Bool) {
        self.clientKey = clientKey
        self.accessToken = ""
        self.apiKey = ""
        self.debug = debug
        self.shouldAlertOnCancel = shouldAlertOnCancel
        self.connectionAttempts = 0
        self.connected = false
        self.attemptingReconnect = false
        self.backlog = [AutoSolveRequest]()

        self.responseEmitter = Signal<AutoSolveTokenResponse>()
        self.cancelEmitter = Signal<AutoSolveCancelResponse>()
        self.errorEmitter = Signal<AutoSolveError>()
        self.connectionEmitter = Signal<AutoSolveConnectionEvent>()
    }

    public func createConnection(accessToken: String, apiKey: String) {
        return DispatchQueue.global(qos: .utility).async {
            self.debugLogger(message: "Creating AutoSolve Connection")
            self.accessToken = accessToken
            self.apiKey = apiKey

            self.closeConnection()
            self.buildRoutingKeys()
            self.attemptConnection()
        }
    }

    public func closeConnection() {
        if(self.connection != nil) {
            self.connection!.blockingClose()
        }
    }

    /************************/
    /*      CONNECTIONS     */
    /************************/

    private func attemptConnection() {
        self.debugLogger(message: "Validating Credentials")
        Validator.validateCredentials(accessToken: self.accessToken, apiKey: self.apiKey, clientKey: self.clientKey, completionHandler: self.connectAfterValidation)
    }

    private func connectAfterValidation(statusCode: Int?, autoSolveError: AutoSolveError?) {
        if(autoSolveError != nil) {
            self.errorEmitter.emit(autoSolveError!)
        } else {
            if(statusCode == 200) {
                return beginConnection()
            } else {
                self.connectionAttempts += 1
                self.reconnect()
            }
        }
    }

    private func beginConnection() {
        self.debugLogger(message: "Validation Successful")
        self.connection = connect()
        let completed =
                createChannels() &&
                        bindQueues() &&
                        subscribeQueues()

        if (completed) {
            self.connectionAttempts = 0
            self.connected = true
            self.attemptingReconnect = false
            self.processBacklog()
            self.debugLogger(message: "AutoSolve Connected")
        } else {
            self.connectionAttempts += 1
            self.debugLogger(message: "Error occurred during the connection process")
            self.reconnect()
        }
    }

    private func connect() -> RMQConnection {
        let connectionDelegate = AutoSolveDelegate.init(autoSolve: self)
        let c = RMQConnection(uri: "amqp://\(self.accountId):\(self.accessToken)@\(AutoSolveConstants.Hostname):5672/\(AutoSolveConstants.Vhost)",
                userProvidedConnectionName: "autosolve-connection",
                delegate: connectionDelegate,
                recoverAfter: 1000,
                recoveryAttempts: 1,
                recoverFromConnectionClose: true)
        c.start()

        self.debugLogger(message: "Connection succeeded")
        return c
    }

    private func createChannels() -> Bool {
        self.directChannel = createChannel()!
        self.fanoutChannel = createChannel()!
        return self.directChannel != nil && self.fanoutChannel != nil
    }

    private func createChannel() -> RMQChannel? {
        if(connection != nil) {
            return connection!.createChannel()
        } else {
            return nil
        }
    }

    private func bindQueues() -> Bool{
        self.directChannel!.queueBind(self.responseQueueName, exchange: self.directExchangeName, routingKey: self.tokenResponseRoutingKey)
        self.directChannel!.queueBind(self.responseQueueName, exchange: self.directExchangeName, routingKey: self.cancelResponseRoutingKey)

        return true
    }

    private func subscribeQueues() -> Bool {
        let handler = AutoSolveDeliveryHandler.init(channel: self.directChannel!, queueName: self.responseQueueName, options: RMQBasicConsumeOptions())
        handler?.autoSolve = self
        self.directChannel!.basicConsume(self.responseQueueName, acknowledgementMode: RMQBasicConsumeAcknowledgementMode.auto,
                handler: AutoSolveDeliveryHandler.consume(handler!))

        self.debugLogger(message: "Subscribed queues")
        return true
    }

    private func reconnect() {
        let seconds = getDelay(attempts: self.connectionAttempts)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.attemptConnection()
        }
    }

    private let Sequence: [Double] = [2.0, 3.0, 5.0, 8.0, 13.0, 21.0, 34.0];

    private func getDelay(attempts: Int) -> Double {
        let index = attempts >= Sequence.count ? Sequence.count - 1 : attempts;
        return Sequence[index];
    }

    internal func handlerConnectionEvent(connectionEvent: AutoSolveConnectionEvent) {
        self.debugLogger(message: "Connection Event occurred :: \(connectionEvent)")
        if(connectionEvent == AutoSolveConnectionEvent.FailedConnection && self.attemptingReconnect) {
            self.debugLogger(message: "Failed connection. Attempting retry")
        } else if (connectionEvent == AutoSolveConnectionEvent.Disconnected && self.attemptingReconnect) {
            self.debugLogger(message: "Disconnected from AutoSolve service")
        } else {
            if(!self.attemptingReconnect) {
                self.attemptingReconnect = true
                self.connected = false
                self.reconnect()
            }
        }
    }

    /************************/
    /*  AUTOSOLVE REQUESTS  */
    /************************/

    public func sendTokenRequest(message: AutoSolveTokenRequest) {
        message.apiKey = self.apiKey
        let json = Encoding.encode(message: message)

        if(self.directChannel != nil && self.connected) {
            if(self.directChannel!.isOpen()) {
                self.debugLogger(message: "Sending request for task ID :: \(message.taskId)")
                self.directChannel!.basicPublish(json.data(using: .utf8)!, routingKey: self.tokenSendRoutingKey, exchange: self.directExchangeName, properties: [])
            } else {
                self.addToBacklog(message: message)
            }
        } else {
            self.addToBacklog(message: message)
        }
    }

    public func cancelTokenRequest(taskId: String) {
        let cancelMessage = AutoSolveCancelRequest(taskId: taskId, apiKey: self.apiKey, responseRequired: self.shouldAlertOnCancel)
        let json = Encoding.encode(message: cancelMessage)

        if(self.fanoutChannel != nil && self.connected) {
            if(self.fanoutChannel!.isOpen()) {
                self.debugLogger(message: "Cancelling request for task ID :: \(taskId)")
                self.fanoutChannel!.basicPublish(json.data(using: .utf8)!, routingKey: self.cancelSendRoutingKey, exchange: self.fanoutExchangeName, properties: [])
            } else {
                self.addToBacklog(message: cancelMessage)
            }
        } else {
            self.addToBacklog(message: cancelMessage)
        }
    }

    public func cancelAllRequests() {
        let cancelMessage = AutoSolveCancelRequest(apiKey: self.apiKey, responseRequired: self.shouldAlertOnCancel)
        let json = Encoding.encode(message: cancelMessage)

        if(self.fanoutChannel != nil && self.connected) {
            if(self.fanoutChannel!.isOpen()) {
                self.debugLogger(message: "Cancelling requests for api key :: \(self.apiKey)")
                self.fanoutChannel!.basicPublish(json.data(using: .utf8)!, routingKey: self.cancelSendRoutingKey, exchange: self.fanoutExchangeName, properties: [])
            } else {
                self.addToBacklog(message: cancelMessage)
            }
        } else {
            self.addToBacklog(message: cancelMessage)
        }
    }

    private func addToBacklog(message: AutoSolveRequest) {
        self.debugLogger(message: "Could not send message. Adding to Backlog")
        self.errorEmitter.emit(AutoSolveError.MessageSendError)
        self.backlog.append(message)
    }

    private func processBacklog() {
        let backlog = self.backlog
        self.backlog.removeAll()
        for message in backlog {
            if(message.type() == AutoSolveConstants.TokenRequest) {
                self.sendTokenRequest(message: message as! AutoSolveTokenRequest)
            } else {
                if(message.taskId == "") {
                    self.cancelAllRequests()
                } else {
                    self.cancelTokenRequest(taskId: message.taskId)
                }
            }
        }
    }

    /************************/
    /*   STRING FUNCTIONS   */
    /************************/

    private func buildRoutingKeys() {
        let apiKeyComponents = self.accessToken.components(separatedBy: "-")
        self.accountId = apiKeyComponents[0]
        self.apiRoutingKey = self.apiKey.components(separatedBy: "-").joined(separator: "")
        self.accessTokenRoutingKey = self.accessToken.components(separatedBy: "-").joined(separator: "")
        self.tokenSendRoutingKey = self.buildRoutingWithAccessToken(prefix: AutoSolveConstants.TokenSendRoutingKey)
        self.cancelSendRoutingKey = self.buildRoutingWithAccessToken(prefix: AutoSolveConstants.CancelSendRoutingKey)
        self.tokenResponseRoutingKey = self.buildWithRoutingKey(prefix: AutoSolveConstants.TokenResponseRoutingKey)
        self.cancelResponseRoutingKey = self.buildWithRoutingKey(prefix: AutoSolveConstants.CancelResponseRoutingKey)
        self.directExchangeName = self.buildRoutingWithAccountId(prefix: AutoSolveConstants.DirectExchange)
        self.fanoutExchangeName = self.buildRoutingWithAccountId(prefix: AutoSolveConstants.FanoutExchange)
        self.responseQueueName = self.buildWithRoutingKey(prefix: AutoSolveConstants.TokenResponseQueuePrefix)

        self.debugLogger(message: "Built routing keys")
    }

    private func parseAccountId() -> String {
        let apiKeyComponents = self.accessToken.components(separatedBy: "-")
        return apiKeyComponents[0]
    }

    internal func debugLogger(message: String) {
        if(self.debug) {
            print(message)
        }
    }

    private func buildWithRoutingKey(prefix: String) -> String{
        return "\(prefix).\(self.accountId).\(self.apiRoutingKey)"
    }

    private func buildRoutingWithAccountId(prefix: String) -> String{
        return "\(prefix).\(self.accountId)"
    }

    private func buildRoutingWithAccessToken(prefix: String) -> String{
        return "\(prefix).\(self.accessTokenRoutingKey)"
    }

    /************************/
}
