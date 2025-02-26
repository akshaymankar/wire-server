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

module Brig.Data.Blacklist
  ( -- * UserKey blacklisting
    insert,
    exists,
    delete,

    -- * PhonePrefix excluding
    insertPrefix,
    deletePrefix,
    existsAnyPrefix,
    getAllPrefixes,
  )
where

import Brig.Data.UserKey
import Brig.Types.Common
import Cassandra
import Imports
import Wire.API.User.Identity

--------------------------------------------------------------------------------
-- UserKey blacklisting

insert :: MonadClient m => UserKey -> m ()
insert uk = retry x5 $ write keyInsert (params LocalQuorum (Identity $ keyText uk))

exists :: MonadClient m => UserKey -> m Bool
exists uk =
  (pure . isJust) . fmap runIdentity
    =<< retry x1 (query1 keySelect (params LocalQuorum (Identity $ keyText uk)))

delete :: MonadClient m => UserKey -> m ()
delete uk = retry x5 $ write keyDelete (params LocalQuorum (Identity $ keyText uk))

keyInsert :: PrepQuery W (Identity Text) ()
keyInsert = "INSERT INTO blacklist (key) VALUES (?)"

keySelect :: PrepQuery R (Identity Text) (Identity Text)
keySelect = "SELECT key FROM blacklist WHERE key = ?"

keyDelete :: PrepQuery W (Identity Text) ()
keyDelete = "DELETE FROM blacklist WHERE key = ?"

--------------------------------------------------------------------------------
-- Excluded phone prefixes

insertPrefix :: MonadClient m => ExcludedPrefix -> m ()
insertPrefix prefix = retry x5 $ write ins (params LocalQuorum (phonePrefix prefix, comment prefix))
  where
    ins :: PrepQuery W (PhonePrefix, Text) ()
    ins = "INSERT INTO excluded_phones (prefix, comment) VALUES (?, ?)"

deletePrefix :: MonadClient m => PhonePrefix -> m ()
deletePrefix prefix = retry x5 $ write del (params LocalQuorum (Identity prefix))
  where
    del :: PrepQuery W (Identity PhonePrefix) ()
    del = "DELETE FROM excluded_phones WHERE prefix = ?"

getAllPrefixes :: MonadClient m => PhonePrefix -> m [ExcludedPrefix]
getAllPrefixes prefix = do
  let prefixes = fromPhonePrefix <$> allPrefixes (fromPhonePrefix prefix)
  selectPrefixes prefixes

existsAnyPrefix :: MonadClient m => Phone -> m Bool
existsAnyPrefix phone = do
  let prefixes = fromPhonePrefix <$> allPrefixes (fromPhone phone)
  not . null <$> selectPrefixes prefixes

selectPrefixes :: MonadClient m => [Text] -> m [ExcludedPrefix]
selectPrefixes prefixes = do
  results <- retry x1 (query sel (params LocalQuorum (Identity $ prefixes)))
  pure $ uncurry ExcludedPrefix <$> results
  where
    sel :: PrepQuery R (Identity [Text]) (PhonePrefix, Text)
    sel = "SELECT prefix, comment FROM excluded_phones WHERE prefix IN ?"
