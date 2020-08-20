--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

module Hakyll.Contrib.Web.TextUtils
  ( firstn
  , toSlug
  ) where

import           Data.Char (isAlphaNum)
import qualified Data.Text as T


--------------------------------------------------------------------------------

firstn          :: Integer -> [a] -> [a]
firstn _ []     = []
firstn n (x:xs)
  | n <= 0      = []
  | otherwise   = x:(firstn (n-1) xs)

--------------------------------------------------------------------------------

keepAlphaNum :: Char -> Char
keepAlphaNum x
  | isAlphaNum x = x
  | otherwise    = ' '

clean :: T.Text -> T.Text
clean = T.map keepAlphaNum . T.replace "'" "" . T.replace "&" "and"

toSlug :: T.Text -> T.Text
toSlug = T.intercalate (T.singleton '-') . T.words . T.toLower . clean
