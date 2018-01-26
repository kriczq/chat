{-# LANGUAGE OverloadedStrings #-}
module Server (run) where

import Data.Char (isPunctuation, isSpace)
import Data.Monoid (mappend)
import Data.Text (Text)
import Data.List (find)
import Control.Exception (finally)
import Control.Monad (forM_, forever)
import Control.Concurrent (MVar, newMVar, modifyMVar_, modifyMVar, readMVar)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import qualified Network.WebSockets as WS

type Client = (Text, WS.Connection)
type ServerState = [Client]

-- | generate empty state of server
newServerState :: ServerState
newServerState = []

-- | returns number of connections based on server state
numClients :: ServerState -> Int
numClients = length

-- | 
clientExists :: Client -> ServerState -> Bool
clientExists client = any ((== fst client) . fst)

-- | adds client to server state
addClient :: Client -> ServerState -> ServerState
addClient client clients = client : clients

-- | removes clients from server state
removeClient :: Client -> ServerState -> ServerState
removeClient client = filter ((/= fst client) . fst)

-- | send message to all connected clients
broadcast :: Text -> ServerState -> IO ()
broadcast message clients = do
    T.putStrLn message
    forM_ clients $ \(_, conn) -> WS.sendTextData conn message

-- | just runs server
run :: IO ()
run = do
    state <- newMVar newServerState
    WS.runServer "127.0.0.1" 9160 $ application state


application :: MVar ServerState -> WS.ServerApp
application state pending = do
    conn <- WS.acceptRequest pending
    WS.forkPingThread conn 10

    msg <- WS.receiveData conn
    clients <- readMVar state
    case msg of
        _
            | any ($ fst client)
                [T.null, T.any isPunctuation, T.any isSpace] ->
                    WS.sendTextData conn ("err:Name cannot " `mappend`
                        "contain punctuation or whitespace, and " `mappend`
                        "cannot be empty" :: Text)
            | clientExists client clients ->
                WS.sendTextData conn ("err:User already exists" :: Text)
            | otherwise -> flip finally disconnect $ do
               modifyMVar_ state $ \s -> do
                   let s' = addClient client s
                   WS.sendTextData conn $
                       T.intercalate "," (map fst s)
                   broadcast (fst client `mappend` " joined") s'
                   return s'
               receive conn state client
          where
            client     = (msg, conn)
            disconnect = do
                -- Remove client and return new state
                s <- modifyMVar state $ \s ->
                    let s' = removeClient client s in return (s', s')
                broadcast (fst client `mappend` " disconnected") s

-- | 
receive :: WS.Connection -> MVar ServerState -> Client -> IO ()
receive conn state (user, _) = forever $ do
    msg <- WS.receiveData conn
    clients <- readMVar state
    case msg of
        _   | T.toLower msg == ("!users" :: Text) -> WS.sendTextData conn $ "Active users: " `mappend` T.intercalate ", " (map fst clients)
            | ("@" `T.isPrefixOf` msg) -> do
                let who = T.drop 1 (T.takeWhile (/= ' ') msg)
                readMVar state >>= sendDirectMessage (user, conn) who (T.drop (T.length who + 1) msg)
            | otherwise -> readMVar state >>= broadcast
                (user `mappend` ": " `mappend` msg)

-- | send direct message to client based on his name
sendDirectMessage :: Client -> Text -> Text -> ServerState -> IO ()
sendDirectMessage (user, conn) who msg state = do
    let client = find (\(user, _) -> user == who) state
    
    case client of
        Nothing ->
            WS.sendTextData conn $ "shiet: user " `mappend` who `mappend` " doesnt exist"
        Just (_, who_conn) ->
            if T.length msg == 0 then
                WS.sendTextData who_conn (user `mappend` " is pinging you")
            else
                WS.sendTextData who_conn (user `mappend` " to you: " `mappend` msg)
                