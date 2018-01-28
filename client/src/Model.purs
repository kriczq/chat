module Model where

import Prelude

import Control.Alt ((<|>))
import Control.Bind ((=<<))
import Control.Monad.Aff (Aff(), launchAff, runAff)
import Control.Monad.Aff.AVar (AVar(), AVAR(), makeVar, putVar, takeVar)
import Control.Monad.Eff (Eff())
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console (CONSOLE(), log)

import Data.Array (replicate,snoc)
import Data.Function (Fn1(),runFn1)
import Data.Maybe (Maybe(..), isJust, isNothing)
import Data.String (joinWith)

import DOM (DOM())

import Halogen

import WebSocket

-- the state of the component
type State = { messages :: Array ChatMessage
             , buffer :: String
             , user :: String
             , socket :: Maybe Connection
             , chatServerUrl :: String
             , queryChan :: AVar (Query Unit)
             }
 -- basic type for message, we can evaluate it in future
type ChatMessage = { content :: String}

-- Type connected with HalogenEffects from Halogen Framework
type AppEffects eff = HalogenEffects ( console :: CONSOLE
                                     , ws :: WEBSOCKET
                                     | eff
                                     )

-- Query type for native effects on our site
data Query a
  = RecMsg String a
  | SendMsg String a
  | SetBuf String a
  | SetUrl String a
  | SetUserName String a
  | ConnectButton a
  | Connect Connection a
  | Disconnect a

-- Type to implement site driver
type AppDriver = Query Unit -> Aff (AppEffects ()) Unit
