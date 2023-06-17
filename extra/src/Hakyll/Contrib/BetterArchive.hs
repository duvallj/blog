--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
module Hakyll.Contrib.BetterArchive
  ( ArchiveDate
  , ArchiveDateData
  , buildArchivePaginateWith
  , archiveExtractYear
  , archivePagesGetDates
  , archivePageMaker
  , archivePageStrategy
  , archiveContext
  ) where


--------------------------------------------------------------------------------
import           Hakyll.Core.Compiler
import           Hakyll.Core.Identifier
import           Hakyll.Core.Identifier.Pattern
import           Hakyll.Core.Metadata
import           Hakyll.Core.Rules
import           Hakyll.Web.Paginate
import           Hakyll.Web.Template.Context
import           Control.Monad                        (forM)
import qualified Data.Map as M
import qualified Data.Set as S
import           Data.Time.Clock
import           Data.Time.Format


--------------------------------------------------------------------------------
type ArchiveDate = UTCTime
type ArchiveDateData = M.Map Identifier ArchiveDate


--------------------------------------------------------------------------------
-- | From a Pattern and a way to sort the resulting Identifiers, create a
-- Paginate object while also keeping track of archive-specific data
buildArchivePaginateWith
  :: (MonadMetadata m, MonadFail m)
  => (ArchiveDateData -> m [[Identifier]])  -- ^ Group items into pages
  -> Pattern                                -- ^ Select items to paginate
  -> (ArchiveDate -> Identifier)            -- ^ Identifiers for the pages
  -> m (Paginate, ArchiveDateData)
buildArchivePaginateWith grouper pattern makeId = do
    ids          <- getMatches pattern
    let idsSet   =  S.fromList ids
    datedata     <- archivePagesGetDates ids
    idGroups     <- grouper datedata
    let pageMap  =  M.fromList (zip [1 ..] idGroups)
    return ( Paginate
              { paginateMap        = pageMap
              , paginateMakeId     = \index -> makeId (datedata M.! head (pageMap M.! index))
              , paginateDependency = PatternDependency pattern idsSet
              }
           , datedata
           )


--------------------------------------------------------------------------------
 -- Given a UTCTime, extract the year
archiveExtractYear :: ArchiveDate -> String
archiveExtractYear = formatTime defaultTimeLocale "%Y"

--------------------------------------------------------------------------------
 -- Given a year, return the URL to render the page at
archivePageMaker :: ArchiveDate -> Identifier
archivePageMaker date =
  (fromFilePath . concat) ["archive/", archiveExtractYear date, ".html"]

-- Given a list of identifiers, create a map of pages to dates
archivePagesGetDates
  :: (MonadMetadata m, MonadFail m)
  => [Identifier]
  -> m ArchiveDateData
archivePagesGetDates ids = do
  dates <- forM ids getDate
  return $ M.fromList (zip ids dates)
  where
    getDate = getItemUTC defaultTimeLocale

-- Given a page number, get the first identifier in that page group
-- Requires that the page number is valid, i.e. in the paginateMap
archiveGetFirstPage
  :: Paginate
  -> PageNumber
  -> Identifier
archiveGetFirstPage pag =
  head . (paginateMap pag M.!)

-- | Groups pages by their common year
archivePageStrategy :: ArchiveDateData -> Rules [[Identifier]]
archivePageStrategy dates =
  let
    grouped = M.foldrWithKey groupByYear M.empty dates
  in
    return $ map snd $ M.toDescList grouped
  where
    groupByYear id' date groups =
      let
        year = archiveExtractYear date
      in
        M.insertWith (++) year [id'] groups

archiveTitleMaker :: 
  ArchiveDateData
  -> (ArchiveDate -> String)
  -> Paginate
  -> PageNumber
  -> Maybe String
archiveTitleMaker dates f pag index
  | index < 1                    = Nothing
  | index > paginateNumPages pag = Nothing
  | otherwise                    = Just $ f (dates M.! archiveGetFirstPage pag index)

archiveContext ::
  Paginate
  -> ArchiveDateData
  -> (ArchiveDate -> String)
  -> PageNumber
  -> Context a
archiveContext pag years f currentPage = 
  mconcat
    [ field "title"             $ \_ -> title currentPage
    , field "firstPageTitle"    $ \_ -> title 1
    , field "previousPageTitle" $ \_ -> title (currentPage - 1)
    , field "nextPageTitle"     $ \_ -> title (currentPage + 1)
    , field "lastPageTitle"     $ \_ -> title (paginateNumPages pag)
    , field "archiveYear"       $ \_ -> return $ 
        archiveExtractYear (years M.! archiveGetFirstPage pag currentPage)
    ]
  `mappend` paginateContext pag currentPage

  where
    title :: PageNumber -> Compiler String
    title i =
      case archiveTitleMaker years f pag i of
        Nothing -> fail ("archives page " ++ show i ++ " out of range")
        Just t  -> return t

--------------------------------------------------------------------------------
-- | Get the total number of pages in a Paginate
-- Re-writing as public because it's useful
paginateNumPages :: Paginate -> Int
paginateNumPages = M.size . paginateMap
