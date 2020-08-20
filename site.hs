--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Maybe  (fromMaybe)
import           Data.Monoid (mappend)
import           Data.List   (concat)
import           Hakyll
import qualified Data.Map        as M
import qualified GHC.IO.Encoding as E
import qualified Data.Text       as T

import           Utils
import           TagFormat
import           BetterPages


--------------------------------------------------------------------------------
main :: IO ()
main = 
  E.setLocaleEncoding E.utf8 >>
  (hakyll $ do
    match "uploads/**" $ do
      route   idRoute
      compile copyFileCompiler

    match "uploads/favicon.ico" $ do
      route $ constRoute "favicon.ico"
      compile copyFileCompiler

    match "css/*.css" $ do
      route   idRoute
      compile compressCssCompiler

    match (fromList ["about.md", "contact.md", "privacy-policy.md"]) $ do
      route   $ setExtension "html"
      compile $ pandocCompiler
        >>= loadAndApplyTemplate "templates/page.html"    defaultContext
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

    tags <- buildTags "posts/*" (fromCapture "tags/*.html")
    let postCtxWithTags = tagsField "tags" tags `mappend` postCtx

    pages <- buildPagesWith "posts/*" sortChronological  

    pageRules pages $ \index _ -> do
      route $ pageIndexRoute index
      compile $ do
        let fullPostCtx = pageContext pages index `mappend` postCtxWithTags

        pandocCompiler
          >>= loadAndApplyTemplate "templates/post.html"    fullPostCtx
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    tagsRules tags $ \tag pattern -> do
      route $ tagRoute tag
      let title = "tag \"" ++ tag ++ "\""
      compile $ do
        posts <- recentFirst =<< loadAll pattern
        let tagCtx =
              constField "title" title                         `mappend`
              listField "posts" postCtxWithTags (return posts) `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/tag.html"     tagCtx
          >>= loadAndApplyTemplate "templates/page.html"    defaultContext
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    archivePages <- buildPaginateWith archivePageStrategy "posts/*" archivePageMaker

    paginateRules archivePages $ \pagenumber pattern -> do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll pattern
        let archiveCtx = archiveContext archivePages pagenumber `mappend` 
              listField "posts" postCtx (return posts)          `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
          >>= loadAndApplyTemplate "templates/page.html"    archiveCtx
          >>= loadAndApplyTemplate "templates/default.html" defaultContext
          >>= relativizeUrls

    create ["tags.html"] $ do
      route idRoute
      compile $ do
        let allTagsCtx = 
              field "tags" (return (betterRenderTags tags)) `mappend`
              constField "title" "Tags"      `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/tag-list.html" allTagsCtx
          >>= loadAndApplyTemplate "templates/page.html"     defaultContext
          >>= loadAndApplyTemplate "templates/default.html"  defaultContext
          >>= relativizeUrls

    match "index.html" $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll "posts/*"
        let indexCtx =
              listField "posts" postCtx (return (firstn 5 posts)) `mappend`
              defaultContext

        getResourceBody
          >>= applyAsTemplate indexCtx
          >>= loadAndApplyTemplate "templates/page.html"    defaultContext
          >>= loadAndApplyTemplate "templates/default.html" indexCtx
          >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler
  )

--------------------------------------------------------------------------------
-- | Add a date field to the default context
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

-- | From a tag, create a 
tagRoute :: String -> Routes
tagRoute =
  constRoute . T.unpack . (T.append "tags/") . (`T.append` ".html") . toSlug . T.pack

betterRenderTags :: Tags -> Compiler String
betterRenderTags =
  renderTags formatTagItem formatJoinTags

pageIndexRoute :: PostNumber -> Routes
pageIndexRoute index = 
  (constRoute . concat) ["posts/", show index, ".html"]

archivePageMaker :: PageNumber -> Identifier
archivePageMaker index
  | index <= 1 = fromFilePath "archive/index.html"
  | otherwise  = (fromFilePath . concat) ["archive/", show index, ".html"]

archiveTitleMaker :: Paginate -> PageNumber -> Maybe String
archiveTitleMaker pag index
  | index < 1                      = Nothing
  | index > (paginateNumPages pag) = Nothing
  | index == 1                     = Just "archives"
  | otherwise                      = (Just . concat) ["archives page", show index]

-- | TODO: make this sort by year and/or month instead of naively
archivePageStrategy :: [Identifier] -> Rules [[Identifier]]
archivePageStrategy = return . (paginateEvery 50)

archiveContext :: Paginate -> PageNumber -> Context a
archiveContext pag currentPage = 
  mconcat
    [ constField "title"        currentTitle
    , field "firstPageTitle"    $ \_ -> title 1
    , field "previousPageTitle" $ \_ -> title (currentPage - 1)
    , field "nextPageTitle"     $ \_ -> title (currentPage + 1)
    , field "lastPageTitle"     $ \_ -> title (paginateNumPages pag)
    ]
    `mappend` 
  paginateContext pag currentPage
  where
    currentTitle = fromMaybe "archives page ??" $ archiveTitleMaker pag currentPage

    title :: PageNumber -> Compiler String
    title i =
      case archiveTitleMaker pag i of
        Nothing -> fail ("archives page " ++ show i ++ " out of range")
        Just t  -> return t

titleRoute :: Metadata -> Routes
titleRoute = fieldRoute "Untitled" "title"

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

--------------------------------------------------------------------------------
-- | Get the total number of pages in a Paginate
-- Re-writing as public because it's useful
paginateNumPages :: Paginate -> Int
paginateNumPages = M.size . paginateMap
