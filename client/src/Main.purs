module Main where

import Prelude

import Control.Monad.Rec.Class (forever)
import Control.Monad.Aff (Aff(), runAff)
import Control.Monad.Aff.AVar (AVar(), AVAR(), makeVar, putVar, takeVar)
import Control.Monad.Eff (Eff())
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console (CONSOLE(), log)
import Control.Monad.Eff.Exception (throwException)
import Control.Monad.Eff.Console.Unsafe (logAny)
import Control.Monad.Eff.Var (($=))
import Data.Array (snoc)
import Data.Function (Fn1(),runFn1)
import Data.Maybe (Maybe(..),isNothing)
import Data.String (joinWith)

import DOM (DOM())

import Halogen
import Halogen.HTML.Indexed as H
import Halogen.HTML.Events.Indexed as E
import Halogen.HTML.Properties.Indexed as P
import Halogen.Util (appendToBody, onLoad)

import WebSocket

import Model

-- concatenates array of string to display in chatbox
concatenate :: Array String -> String
concatenate = joinWith "\n"

-- Function responsible for rendering site components
ui :: Component State Query (Aff (AppEffects ()))
ui = component render eval
  where -- render site components
    render :: State -> ComponentHTML Query
    render st =
        if (isNothing st.socket) then
            H.div_
                [ H.h1_ [ H.text "PF - Chat Project"]
                , H.p_
                    [ H.input
                        [ P.inputType P.InputText
                        , P.placeholder "Type your username here"
                        , P.value st.user
                        , E.onValueChange (E.input SetUserName)
                        ]
                    , H.button
                        [ E.onClick (E.input_ ConnectButton)]
                        [ H.text "Connect"]
                    ]
                ]
        else
            H.div_
                [ H.h1_ [ H.text "PF - Chat Project" ]
                , H.p_
                    [ H.pre
                        [ P.class_ $ H.className "msgbox"
                        , P.id_ "msgbox" ]
                        [ H.text $ concatenate $ map _.content st.messages ]
                    ]
                , H.p_
                    [ H.input
                        [ P.inputType P.InputText
                        , P.class_ $ H.className "sendbuffer"
                        , P.placeholder "Type a message to send"
                        , P.value st.buffer
                        , E.onValueChange (E.input SetBuf)
                        ]
                    , H.button
                        [ P.disabled (isNothing st.socket)
                        , E.onClick (E.input_ (SendMsg st.buffer ))
                        ]
                        [ H.text "Send it" ]
                    ]
                ]
    -- evaluates queries on the site
    eval :: Natural Query (ComponentDSL State Query (Aff (AppEffects ())))
    eval (ConnectButton next) = do
        driver <- makeDriver <$> get
        url <- URL <$> gets _.chatServerUrl
        liftAff' $ makeSocket driver url
        pure next
    eval (Connect conn next) = do
        modify _ { socket = Just conn }
        liftAff' $ log' "got a connection!"
        st <- get
        send' st.user st.socket
        pure next
    eval (Disconnect next) = do
        modify _ { socket = Nothing }
        liftAff' $ log' "lost the connection."
        pure next
    eval (RecMsg content next) = do
        modify \st -> st { messages = st.messages `snoc` {content: content}}
        liftEff' $ scrollAtBottom "box"
        pure next
    eval (SendMsg content next) = do
        modify _ { buffer = "" }
        gets _.socket >>= send' content
        pure next
    eval (SetBuf content next) = do
        modify _ { buffer = content }
        pure next
    eval (SetUrl content next) = do
        modify _ { chatServerUrl = content }
        pure next
    eval (SetUserName user next) = do
        modify _ { user = user }
        pure next

-- Function responsible for scrolling at bottom of chat after receiving message
foreign import scrollBottomImpl :: forall e. Fn1 String (Eff (dom :: DOM | e) Unit)
scrollAtBottom :: forall e. String -> Eff (dom :: DOM | e) Unit
scrollAtBottom = runFn1 scrollBottomImpl

-- Function responsible for sending messages
send :: forall eff. String -> Maybe Connection -> Aff (ws :: WEBSOCKET | eff) Unit
send _ Nothing                    = pure unit
send s (Just (Connection socket)) = liftEff $ socket.send $ Message s

-- Improved send, able to work asynchronously
send' :: forall eff. String -> Maybe Connection -> ComponentDSL State Query (Aff (ws :: WEBSOCKET | eff)) Unit
send' s c = liftAff' $ send s c

-- As above, improved log function, able to work asynchronously
log' :: forall eff. String -> Aff (console :: CONSOLE | eff) Unit
log' = liftEff <<< log

-- Asynchronous driver for our Chat
makeDriver :: forall r. {queryChan :: AVar (Query Unit) | r} -> AppDriver
makeDriver {queryChan=chan} = putVar chan

-- Open socket connection
makeSocket :: forall eff. AppDriver -> URL -> Aff (avar :: AVAR, ws :: WEBSOCKET | eff) Unit
makeSocket driver url = do
    liftEff do
        conn@(Connection socket) <- newWebSocket url []
        socket.onopen $= \event -> do
            logAny event
            log "onopen: Connection is opened"
            quietLaunchAff $ driver $ action $ Connect conn

        socket.onmessage $= \event -> do
            logAny event
            let received = runMessage (runMessageEvent event)
            log $ "onmessage: Received '" ++ received ++ "'"
            quietLaunchAff $ driver $ action $ RecMsg received

        socket.onclose $= \event -> do
            logAny event
            log "onclose: Connection is closed"
            quietLaunchAff $ driver $ action $ Disconnect

    pure unit

-- Launch quietly asynchronous effects on site
quietLaunchAff :: forall eff a. Aff eff a -> Eff eff Unit
quietLaunchAff = runAff (const (pure unit)) (const (pure unit))

-- Main function in our client
main :: Eff (AppEffects ()) Unit
main = do
    runAff throwException (const (pure unit)) $ do
        chan <- makeVar
        app <- runUI ui { messages: []
                        , buffer: ""
                        , user: ""
                        , chatServerUrl: "ws://172.20.10.5:9160"
                        , socket: Nothing
                        , queryChan: chan
                        }
        onLoad $ appendToBody app.node
        forever (takeVar chan >>= app.driver)
