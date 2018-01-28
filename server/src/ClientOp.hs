module ClientOp (newServerState, numClients, clientExists, addClient, removeClient) where

import Model

-- | generate empty state of server
newServerState :: ServerState
newServerState = []

-- | returns number of connections based on server state
numClients :: ServerState -> Int
numClients = length

-- | checks if the client appepar on server state list
clientExists :: Client -> ServerState -> Bool
clientExists client = any ((== fst client) . fst)

-- | adds client to server state
addClient :: Client -> ServerState -> ServerState
addClient client clients = client : clients

-- | removes clients from server state
removeClient :: Client -> ServerState -> ServerState
removeClient client = filter ((/= fst client) . fst)
