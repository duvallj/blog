--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
module Hakyll.Contrib.BetterArchive
  ( archivePageMaker
  , archivePageStrategy
  , archiveContext
  ) where


--------------------------------------------------------------------------------
import           Hakyll.Core.Compiler
import           Hakyll.Core.Identifier
import           Hakyll.Core.Rules
import           Hakyll.Web.Paginate
import           Hakyll.Web.Template.Context
import qualified Data.Map as M


--------------------------------------------------------------------------------
archivePageMaker :: PageNumber -> Identifier
archivePageMaker index
  | index <= 1 = fromFilePath "archive/index.html"
  | otherwise  = (fromFilePath . concat) ["archive/", show index, ".html"]

-- | TODO: make this sort by year and/or month instead of naively
archivePageStrategy :: [Identifier] -> Rules [[Identifier]]
archivePageStrategy = return . (paginateEvery 50)

archiveTitleMaker :: 
  (PageNumber -> String)
  -> Paginate
  -> PageNumber
  -> Maybe String
archiveTitleMaker f pag index
  | index < 1                      = Nothing
  | index > (paginateNumPages pag) = Nothing
  | otherwise                      = Just $ f index

archiveContext ::
  Paginate -> 
  (PageNumber -> String) ->
  PageNumber -> 
  Context a
archiveContext pag f currentPage = 
  mconcat
    [ field "title"             $ \_ -> title currentPage
    , field "firstPageTitle"    $ \_ -> title 1
    , field "previousPageTitle" $ \_ -> title (currentPage - 1)
    , field "nextPageTitle"     $ \_ -> title (currentPage + 1)
    , field "lastPageTitle"     $ \_ -> title (paginateNumPages pag)
    ]
  `mappend` paginateContext pag currentPage

  where
    title :: PageNumber -> Compiler String
    title i =
      case archiveTitleMaker f pag i of
        Nothing -> fail ("archives page " ++ show i ++ " out of range")
        Just t  -> return t

--------------------------------------------------------------------------------
-- | Get the total number of pages in a Paginate
-- Re-writing as public because it's useful
paginateNumPages :: Paginate -> Int
paginateNumPages = M.size . paginateMap
