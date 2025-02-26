{-# LANGUAGE TemplateHaskell #-}

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

module Spar.Sem.BrigAccess
  ( BrigAccess (..),
    createSAML,
    createNoSAML,
    updateEmail,
    getAccount,
    getByHandle,
    getByEmail,
    setName,
    setHandle,
    setManagedBy,
    setVeid,
    setRichInfo,
    getRichInfo,
    checkHandleAvailable,
    delete,
    ensureReAuthorised,
    ssoLogin,
    getStatus,
    getStatusMaybe,
    setStatus,
  )
where

import Brig.Types.Intra
import Brig.Types.User
import Data.Code as Code
import Data.Handle (Handle)
import Data.Id (TeamId, UserId)
import Data.Misc (PlainTextPassword)
import Imports
import Polysemy
import qualified SAML2.WebSSO as SAML
import Web.Cookie
import Wire.API.User (VerificationAction)
import Wire.API.User.Identity
import Wire.API.User.Profile
import Wire.API.User.RichInfo as RichInfo
import Wire.API.User.Scim (ValidExternalId (..))

data BrigAccess m a where
  CreateSAML :: SAML.UserRef -> UserId -> TeamId -> Name -> ManagedBy -> BrigAccess m UserId
  CreateNoSAML :: Email -> TeamId -> Name -> Maybe Locale -> BrigAccess m UserId
  UpdateEmail :: UserId -> Email -> BrigAccess m ()
  GetAccount :: HavePendingInvitations -> UserId -> BrigAccess m (Maybe UserAccount)
  GetByHandle :: Handle -> BrigAccess m (Maybe UserAccount)
  GetByEmail :: Email -> BrigAccess m (Maybe UserAccount)
  SetName :: UserId -> Name -> BrigAccess m ()
  SetHandle :: UserId -> Handle {- not 'HandleUpdate'! -} -> BrigAccess m ()
  SetManagedBy :: UserId -> ManagedBy -> BrigAccess m ()
  SetVeid :: UserId -> ValidExternalId -> BrigAccess m ()
  SetRichInfo :: UserId -> RichInfo -> BrigAccess m ()
  GetRichInfo :: UserId -> BrigAccess m RichInfo
  CheckHandleAvailable :: Handle -> BrigAccess m Bool
  Delete :: UserId -> BrigAccess m ()
  EnsureReAuthorised :: Maybe UserId -> Maybe PlainTextPassword -> Maybe Code.Value -> Maybe VerificationAction -> BrigAccess m ()
  SsoLogin :: UserId -> BrigAccess m SetCookie
  GetStatus :: UserId -> BrigAccess m AccountStatus
  GetStatusMaybe :: UserId -> BrigAccess m (Maybe AccountStatus)
  SetStatus :: UserId -> AccountStatus -> BrigAccess m ()

makeSem ''BrigAccess
