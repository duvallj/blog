--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
module Hakyll.Contrib.Web.CustomRoutes 
  ( tagRoute
  , pageIndexRoute
  , titleRoute
  , fieldRoute
  ) where

import           Data.Maybe                   (fromMaybe)
import           Data.List                    (concat)
import           Hakyll.Core.Routes
import           Hakyll.Core.Metadata
import           Hakyll.Contrib.BetterPages
import           Hakyll.Contrib.Web.TextUtils (toSlug)
import qualified Data.Text  as T


--------------------------------------------------------------------------------

tagRoute :: String -> Routes
tagRoute =
  constRoute . 
    T.unpack . 
      (T.append "tags/") . (`T.append` ".html") . toSlug . 
    T.pack

pageIndexRoute :: PostNumber -> Routes
pageIndexRoute index = 
  (constRoute . concat) ["posts/", show index, ".html"]

titleRoute :: Metadata -> Routes
titleRoute = fieldRoute "untitled" "title"

fieldRoute :: String -> String -> Metadata -> Routes
fieldRoute placeholder fieldName =
  constRoute . (fileNameFromMeta placeholder fieldName)

fileNameFromMeta :: String -> String -> Metadata -> FilePath
fileNameFromMeta placeholder fieldName =
  T.unpack . (`T.append` ".html") . toSlug . T.pack 
           . (getFieldFromMeta placeholder fieldName)

getFieldFromMeta :: String -> String -> Metadata -> String
getFieldFromMeta placeholder fieldName =
  fromMaybe placeholder . lookupString fieldName
