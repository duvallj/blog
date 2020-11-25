--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
module Hakyll.Contrib.BetterPages
  ( PostNumber
  , PostData (..)
  , buildPagesWith
  , pageRules
  , pageContext
  ) where


--------------------------------------------------------------------------------
import           Control.Applicative (empty)
import           Control.Monad       (forM_, forM)
import qualified Data.Map            as M
import qualified Data.Set            as S


--------------------------------------------------------------------------------
import           Hakyll.Core.Compiler
import           Hakyll.Core.Identifier
import           Hakyll.Core.Identifier.Pattern
import           Hakyll.Core.Item
import           Hakyll.Core.Metadata
import           Hakyll.Core.Rules
import           Hakyll.Web.Html
import           Hakyll.Web.Template.Context


--------------------------------------------------------------------------------
type PostNumber = Int


--------------------------------------------------------------------------------
-- | Data about pages.
-- pageMap assigns numeric ids to each page
-- pageDependency is needed to work well with Hakyll's Compiler
data PostData = PostData
  { pageMap :: M.Map PostNumber Identifier
  , pageDependency :: M.Map PostNumber Dependency
  }


--------------------------------------------------------------------------------
-- | Returns the total number of pages present in a set of pages
numPages :: PostData -> Int
numPages = M.size . pageMap


--------------------------------------------------------------------------------
-- | From a Pattern and a way to sort the resulting Identifiers, create a
-- PostData object
buildPagesWith
  :: (MonadMetadata m)
  => Pattern
  -> ([Identifier] -> m [Identifier])
  -> m PostData
buildPagesWith pattern sorter = do
  ids                    <- getMatches pattern
  sortedIds              <- sorter ids
  let sortedDependencies = map IdentifierDependency sortedIds
  return PostData
    { pageMap = M.fromList (zip [1 ..] sortedIds)
    , pageDependency = M.fromList (zip [1 ..] sortedDependencies)
    }


--------------------------------------------------------------------------------
-- | Create a Rules () from a PostData and a continuation that takes in the
-- PostNumber and Identifier to create the rules
pageRules :: PostData -> (PostNumber -> Identifier -> Rules ()) -> Rules ()
pageRules pagedata rules =
  forM_ (M.toList $ pageMap pagedata) $ \(index, identifier) ->
    rulesExtraDependencies [pageDependency pagedata M.! index] $
      create [identifier] (rules index identifier)


--------------------------------------------------------------------------------
-- | Perform a page lookup in the PostData map
getPageByNumber :: PostData -> PostNumber -> Maybe Identifier
getPageByNumber pagedata index
  | index < 1                   = Nothing
  | index > (numPages pagedata) = Nothing
  | otherwise                   = M.lookup index (pageMap pagedata)


--------------------------------------------------------------------------------
-- | A good default page context (lifted from Hakyll source) which adds the 
-- following keys:
--
-- * @firstPageNum@
-- * @firstPageUrl@
-- * @previousPageNum@
-- * @previousPageUrl@
-- * @nextPageNum@
-- * @nextPageUrl@
-- * @lastPageNum@
-- * @lastPageUrl@
-- * @currentPageNum@
-- * @currentPageUrl@
-- * @numPages@
-- * @allPages@
--
-- For convenience, it also includes the following optionally-defined keys:
-- * @firstPageTitle@
-- * @previousPageTitle@
-- * @nextPageTitle@
-- * @lastPageTitle@
pageContext :: PostData -> PostNumber -> Context a
pageContext pag currentPage = mconcat
    [ field "firstPageNum"      $ \_ -> otherPage 1                 >>= num
    , field "firstPageUrl"      $ \_ -> otherPage 1                 >>= url
    , field "firstPageTitle"    $ \_ -> otherPage 1                 >>= title
    , field "previousPageNum"   $ \_ -> otherPage (currentPage - 1) >>= num
    , field "previousPageUrl"   $ \_ -> otherPage (currentPage - 1) >>= url
    , field "previousPageTitle" $ \_ -> otherPage (currentPage - 1) >>= title
    , field "nextPageNum"       $ \_ -> otherPage (currentPage + 1) >>= num
    , field "nextPageUrl"       $ \_ -> otherPage (currentPage + 1) >>= url
    , field "nextPageTitle"     $ \_ -> otherPage (currentPage + 1) >>= title
    , field "lastPageNum"       $ \_ -> otherPage lastPage          >>= num
    , field "lastPageUrl"       $ \_ -> otherPage lastPage          >>= url
    , field "lastPageTitle"     $ \_ -> otherPage lastPage          >>= title
    , field "currentPageNum"    $ \i -> thisPage i                  >>= num
    , field "currentPageUrl"    $ \i -> thisPage i                  >>= url
    , constField "numPages"     $ show $ numPages pag
    , Context $ \k _ i -> case k of
        "allPages" -> do
            let ctx =
                    field "isCurrent" (\n -> if fst (itemBody n) == currentPage then return "true" else empty) `mappend`
                    field "num" (num . itemBody) `mappend`
                    field "url" (url . itemBody)

            list <- forM [1 .. lastPage] $
                \n -> if n == currentPage then thisPage i else otherPage n
            items <- mapM makeItem list
            return $ ListField ctx items
        _          -> do
            empty

    ]
  where
    lastPage = numPages pag

    thisPage i = return (currentPage, itemIdentifier i)
    otherPage n
        | n == currentPage = fail $ "This is the current page: " ++ show n
        | otherwise        = case getPageByNumber pag n of
            Nothing -> fail $ "No such page: " ++ show n
            Just i  -> return (n, i)

    num :: (Int, Identifier) -> Compiler String
    num = return . show . fst

    url :: (Int, Identifier) -> Compiler String
    url (n, i) = getRoute i >>= \mbR -> case mbR of
        Just r  -> return $ toUrl r
        Nothing -> fail $ "No URL for page: " ++ show n

    title :: (Int, Identifier) -> Compiler String
    title (_, i) = do
      metadata <- getMetadata i
      let maybeTitle = lookupString "title" metadata
      case maybeTitle of
        Nothing -> fail "Untitled"
        Just t  -> return t
