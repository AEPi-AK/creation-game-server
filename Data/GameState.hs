module Data.GameState where

import Import.NoFoundation
import Data.Time.Clock

data GameState = GameState { currentPhase :: GamePhase
                           , timeSincePhaseStart :: NominalDiffTime
                           , player1 :: Player
                           , player2 :: Player
                           , location :: Location
                        } deriving (Show, Eq)

instance ToJSON GameState where
    toJSON state = 
        let pTime = show $ phaseTime (currentPhase state) in
        let sinceStart = show $ timeSincePhaseStart state in
        (object 
            [ "currentPhase"        .= (show $ currentPhase state)
            , "phaseTime"           .= (take (length pTime - 1) pTime)
            , "timeSincePhaseStart" .= (take (length sinceStart - 1) sinceStart)
            , "player1"               .= (toJSON $ player1 state)
            , "player2"               .= (toJSON $ player2 state)
            , "location"               .= (show $ location state)
            ])

data GamePhase = GameJoining | GameWaiting | GameInProgress | GameOver
    deriving(Show, Read, Eq)

data Location = Desert | Tundra
    deriving(Show, Read, Eq)

phaseStart :: GamePhase -> NominalDiffTime
phaseStart GameWaiting = 55
phaseStart GameOver = 40
phaseStart GameJoining = 0
phaseStart GameInProgress = 10

phaseTime :: GamePhase -> NominalDiffTime
phaseTime GameWaiting = 0
phaseTime GameJoining = (phaseStart GameInProgress)
phaseTime GameInProgress = (phaseStart GameOver) - (phaseStart GameInProgress)
phaseTime GameOver = (phaseStart GameWaiting) - 
                     (phaseStart GameOver) - (phaseStart GameInProgress)

phaseForTimeDiff :: NominalDiffTime -> GamePhase
phaseForTimeDiff diff | diff > (phaseStart GameWaiting) = GameWaiting
                      | diff > (phaseStart GameOver) = GameOver
                      | diff > (phaseStart GameInProgress) = GameInProgress
                      | diff >= (phaseStart GameJoining) = GameJoining
phaseForTimeDiff _ = error "Invalid time diff!"

timeInPhase :: NominalDiffTime -> GamePhase -> NominalDiffTime
timeInPhase time phase = time - (phaseStart phase)
                        
phaseAndTimeForStartTime :: UTCTime -> IO (GamePhase, NominalDiffTime)
phaseAndTimeForStartTime time = do
    currTime <- getCurrentTime
    let remSecs = diffUTCTime currTime time
    let phase = phaseForTimeDiff remSecs
    return (phase, timeInPhase remSecs phase)
