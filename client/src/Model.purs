module Model where
  
import Prelude

import Control.Alt ((<|>))
import Control.Bind ((=<<))
import Control.Monad (when)
import Control.Monad.Rec.Class (forever)
import Control.Monad.Aff (Aff(), launchAff, runAff)
import Control.Monad.Aff.AVar (AVar(), AVAR(), makeVar, putVar, takeVar)
import Control.Monad.Eff (Eff())
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console (CONSOLE(), log)
import Control.Monad.Eff.Exception (throwException)
import Control.Monad.Eff.Console.Unsafe (logAny)
import Control.Monad.Eff.Var (($=))

import Data.Array (replicate,snoc)
import Data.Function (Fn1(),runFn1)
import Data.Maybe (Maybe(..), isJust, isNothing)
import Data.String (joinWith)

import DOM (DOM())

import Halogen
import Halogen.HTML.Indexed as H
import Halogen.HTML.Events.Indexed as E
import Halogen.HTML.Properties.Indexed as P
import Halogen.Util (appendToBody, onLoad)

import WebSocket

-- | The state of the component.
type State = { messages :: Array ChatMessage
             , buffer :: String
             , user :: User
             , socket :: Maybe Connection
             , chatServerUrl :: String
             , queryChan :: AVar (Query Unit)
             }

type ChatMessage = { content :: String
                   -- a real app would probably store other stuff here
                   }
type User = String

-- | The effeUnitcts used in the app.
type AppEffects eff = HalogenEffects ( console :: CONSOLE
                                     , ws :: WEBSOCKET
                                     | eff
                                     )

-- | The component query algebra.
data Query a
  = ReceivedMessage String a
  | SendMessage String a
  | SetBuffer String a
  | SetUrl String a
  | SetUserName String a
  | ConnectButton a
  | Connect Connection a
  | Disconnect a

-- for some reason this first def for AppDriver won't typecheck
-- type AppDriver = Driver Query (AppEffects ())
type AppDriver = Query Unit -> Aff (AppEffects ()) Unit