{-# LANGUAGE OverloadedLists #-}

-- This file is part of the Wire Server implementation.
--
-- Copyright (C) 2022 Wire Swiss GmbH <opensource@wire.com>
--
-- This program is free software: you can redistribute it and/or modify it under
-- the terms of the GNU Affero General Public License as published by the Free
-- Software Foundation, either version 3 of the License, or (at your option) any
-- later version.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
-- details.
--
-- You should have received a copy of the GNU Affero General Public License along
-- with this program. If not, see <https://www.gnu.org/licenses/>.

module Test.Wire.API.Golden.Generated.WithStatus_team where

import Data.Domain
import Imports
import Wire.API.Team.Feature

testObject_WithStatus_team_1 :: WithStatus AppLockConfig
testObject_WithStatus_team_1 = withStatus FeatureStatusEnabled LockStatusUnlocked (AppLockConfig (EnforceAppLock False) (-98))

testObject_WithStatus_team_2 :: WithStatus AppLockConfig
testObject_WithStatus_team_2 = withStatus FeatureStatusEnabled LockStatusUnlocked (AppLockConfig (EnforceAppLock True) 0)

testObject_WithStatus_team_3 :: WithStatus AppLockConfig
testObject_WithStatus_team_3 = withStatus FeatureStatusEnabled LockStatusLocked (AppLockConfig (EnforceAppLock True) 111)

testObject_WithStatus_team_4 :: WithStatus SelfDeletingMessagesConfig
testObject_WithStatus_team_4 = withStatus FeatureStatusEnabled LockStatusUnlocked (SelfDeletingMessagesConfig (-97))

testObject_WithStatus_team_5 :: WithStatus SelfDeletingMessagesConfig
testObject_WithStatus_team_5 = withStatus FeatureStatusEnabled LockStatusUnlocked (SelfDeletingMessagesConfig 0)

testObject_WithStatus_team_6 :: WithStatus SelfDeletingMessagesConfig
testObject_WithStatus_team_6 = withStatus FeatureStatusEnabled LockStatusLocked (SelfDeletingMessagesConfig 77)

testObject_WithStatus_team_7 :: WithStatus ClassifiedDomainsConfig
testObject_WithStatus_team_7 = withStatus FeatureStatusEnabled LockStatusLocked (ClassifiedDomainsConfig [])

testObject_WithStatus_team_8 :: WithStatus ClassifiedDomainsConfig
testObject_WithStatus_team_8 = withStatus FeatureStatusEnabled LockStatusLocked (ClassifiedDomainsConfig [Domain "example.com", Domain "test.foobar"])

testObject_WithStatus_team_9 :: WithStatus ClassifiedDomainsConfig
testObject_WithStatus_team_9 = withStatus FeatureStatusEnabled LockStatusUnlocked (ClassifiedDomainsConfig [Domain "test.foobar"])

testObject_WithStatus_team_10 :: WithStatus SSOConfig
testObject_WithStatus_team_10 = withStatus FeatureStatusDisabled LockStatusLocked SSOConfig

testObject_WithStatus_team_11 :: WithStatus SearchVisibilityAvailableConfig
testObject_WithStatus_team_11 = withStatus FeatureStatusEnabled LockStatusLocked SearchVisibilityAvailableConfig

testObject_WithStatus_team_12 :: WithStatus ValidateSAMLEmailsConfig
testObject_WithStatus_team_12 = withStatus FeatureStatusDisabled LockStatusLocked ValidateSAMLEmailsConfig

testObject_WithStatus_team_13 :: WithStatus DigitalSignaturesConfig
testObject_WithStatus_team_13 = withStatus FeatureStatusEnabled LockStatusLocked DigitalSignaturesConfig

testObject_WithStatus_team_14 :: WithStatus ConferenceCallingConfig
testObject_WithStatus_team_14 = withStatus FeatureStatusDisabled LockStatusUnlocked ConferenceCallingConfig

testObject_WithStatus_team_15 :: WithStatus GuestLinksConfig
testObject_WithStatus_team_15 = withStatus FeatureStatusEnabled LockStatusUnlocked GuestLinksConfig

testObject_WithStatus_team_16 :: WithStatus SndFactorPasswordChallengeConfig
testObject_WithStatus_team_16 = withStatus FeatureStatusDisabled LockStatusUnlocked SndFactorPasswordChallengeConfig

testObject_WithStatus_team_17 :: WithStatus SearchVisibilityInboundConfig
testObject_WithStatus_team_17 = withStatus FeatureStatusEnabled LockStatusUnlocked SearchVisibilityInboundConfig
